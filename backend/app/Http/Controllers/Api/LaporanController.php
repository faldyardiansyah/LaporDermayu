<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Instansi;
use App\Models\Laporan;
use App\Support\IndramayuBoundary;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\BinaryFileResponse;
use Throwable;

class LaporanController extends Controller
{
    private const KATEGORI = ['jalan_rusak', 'fasilitas'];

    private const DUPLICATE_RADIUS_METER = 20;

    private const DUPLICATE_WINDOW_MENIT = 10;

    private const STATUS_PUBLIK = ['terverifikasi', 'diproses', 'diperbaiki', 'selesai'];

    private const STATUS_PETA = ['terverifikasi', 'diproses'];

    public function index(Request $request): JsonResponse
    {
        $paginator = Laporan::with('riwayatStatus')
            ->where('user_id', $request->user()->id)
            ->latest()
            ->paginate(10);

        $data = collect($paginator->items())
            ->map(fn (Laporan $laporan) => $this->transform($request, $laporan))
            ->values();

        return response()->json([
            'success' => true,
            'message' => 'Daftar laporan berhasil diambil',
            'data' => $data,
            'meta' => [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
            ],
        ]);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $laporan = Laporan::with('riwayatStatus')->find($id);
        
        $milikSendiri = $laporan && (int) $laporan->user_id === (int) $request->user()->id;
        $boleh = $milikSendiri || ($laporan && in_array($laporan->status, self::STATUS_PUBLIK, true));

        if (! $laporan || ! $boleh) {
            return response()->json([
                'success' => false,
                'message' => 'Laporan tidak ditemukan atau belum dapat dilihat.',
            ], 404);
        }

        $waktu = $laporan->created_at
            ?->timezone('Asia/Jakarta')
            ->locale('id')
            ->isoFormat('D MMM YYYY, HH:mm');

        return response()->json([
            'success' => true,
            'message' => 'Detail laporan berhasil diambil',
            'data' => array_merge($this->transform($request, $laporan), [
                'waktu' => $waktu,
                'is_owner' => $milikSendiri,
            ]),
        ]);
    }

    public function peta(Request $request): JsonResponse
    {
        $data = Laporan::whereIn('status', self::STATUS_PETA)
            ->whereNotNull('latitude')
            ->whereNotNull('longitude')
            ->latest()
            ->limit(300)
            ->get(['id', 'judul', 'deskripsi', 'kategori', 'status', 'latitude', 'longitude', 'alamat_lokasi', 'foto'])
            ->map(fn (Laporan $l) => [
                'id' => $l->id,
                'judul' => $l->judul,
                'kategori' => $l->kategori,
                'status' => $l->status,
                'type' => $this->hazardType($l),
                'latitude' => (float) $l->latitude,
                'longitude' => (float) $l->longitude,
                'alamat' => $l->alamat_lokasi,
                'foto' => $this->fotoUrl($request, $l->foto),
            ])
            ->values();

        return response()->json([
            'success' => true,
            'message' => 'Data peta berhasil diambil',
            'data' => $data,
        ]);
    }

    public function fotoPenyelesaian(Request $request, int $id): BinaryFileResponse|JsonResponse
    {
        $laporan = Laporan::query()->find($id);

        if (! $laporan || (int) $laporan->user_id !== (int) $request->user()->id || ! $laporan->foto_penyelesaian) {
            return response()->json([
                'success' => false,
                'message' => 'Bukti penyelesaian tidak ditemukan.',
            ], 404);
        }

        $disk = Storage::disk('local');
        if (! $disk->exists($laporan->foto_penyelesaian)) {
            return response()->json([
                'success' => false,
                'message' => 'Bukti penyelesaian tidak ditemukan.',
            ], 404);
        }

        $response = response()->file($disk->path($laporan->foto_penyelesaian));
        $response->headers->set('Cache-Control', 'private, no-store');
        $response->headers->set('X-Content-Type-Options', 'nosniff');

        return $response;
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'judul' => ['required', 'string', 'max:150'],
            'deskripsi' => ['required', 'string', 'max:2000'],
            'kategori' => ['required', 'in:'.implode(',', self::KATEGORI)],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'alamat_lokasi' => ['nullable', 'string', 'max:255'],
            'foto' => ['required', 'file', 'image', 'mimes:jpg,jpeg,png', 'max:5120'],
        ], $this->messages(), $this->attributes());

        $user = $request->user();
        $lat = (float) $validated['latitude'];
        $lng = (float) $validated['longitude'];
        $instansiId = Instansi::query()
            ->where('nama_instansi', Instansi::NAMA_PEMDA_INDRAMAYU)
            ->value('id');

        if ($instansiId === null) {
            return response()->json([
                'success' => false,
                'message' => 'Instansi penanggung jawab Kabupaten Indramayu belum dikonfigurasi.',
            ], 503);
        }

        try {
            $diDalamIndramayu = app(IndramayuBoundary::class)->contains($lat, $lng);
        } catch (Throwable $e) {
            report($e);

            return response()->json([
                'success' => false,
                'message' => 'Pengecekan wilayah gagal di server. Coba lagi.',
            ], 500);
        }

        if (! $diDalamIndramayu) {
            $pesan = 'Lokasi Anda berada di luar wilayah Kabupaten Indramayu. Laporan hanya dapat dikirim dari dalam Indramayu.';

            return response()->json([
                'success' => false,
                'message' => $pesan,
                'errors' => ['latitude' => [$pesan]],
            ], 422);
        }

        if ($this->isDuplicate($user->id, $validated['kategori'], $lat, $lng)) {
            $pesan = 'Anda sudah mengirim laporan serupa di lokasi ini beberapa menit lalu. Mohon tunggu sebelum mengirim lagi.';

            return response()->json([
                'success' => false,
                'message' => $pesan,
                'errors' => ['laporan' => [$pesan]],
            ], 422);
        }

        $path = $request->file('foto')->store('laporan', 'public');

        if (! $path) {
            return response()->json([
                'success' => false,
                'message' => 'Foto gagal disimpan. Silakan coba lagi.',
            ], 500);
        }

        try {
            $laporan = Laporan::create([
                'user_id' => $user->id,
                'instansi_id' => (int) $instansiId,
                'judul' => trim($validated['judul']),
                'deskripsi' => trim($validated['deskripsi']),
                'kategori' => $validated['kategori'],
                'foto' => $path,
                'latitude' => $lat,
                'longitude' => $lng,
                'alamat_lokasi' => $validated['alamat_lokasi'] ?? null,
                'status' => 'menunggu',
            ]);
        } catch (Throwable $e) {
            Storage::disk('public')->delete($path);
            report($e);

            return response()->json([
                'success' => false,
                'message' => 'Laporan gagal disimpan. Silakan coba lagi.',
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'Laporan berhasil dikirim',
            'data' => $this->transform($request, $laporan),
        ], 201);
    }

    private function hazardType(Laporan $laporan): string
    {
        if ($laporan->kategori === 'jalan_rusak') {
            return 'jalan_rusak';
        }

        $teks = ($laporan->judul ?? '').' '.($laporan->deskripsi ?? '');

        return preg_match('/lampu|pju|penerangan|gelap/i', $teks)
            ? 'lampu_mati'
            : 'fasilitas';
    }

    private function isDuplicate(int $userId, string $kategori, float $lat, float $lng): bool
    {
        $kandidat = Laporan::where('user_id', $userId)
            ->where('kategori', $kategori)
            ->where('created_at', '>=', now()->subMinutes(self::DUPLICATE_WINDOW_MENIT))
            ->get(['latitude', 'longitude']);

        foreach ($kandidat as $item) {
            $jarak = $this->jarakMeter($lat, $lng, (float) $item->latitude, (float) $item->longitude);

            if ($jarak < self::DUPLICATE_RADIUS_METER) {
                return true;
            }
        }

        return false;
    }

    private function jarakMeter(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $r = 6371000;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);

        $a = sin($dLat / 2) ** 2
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;

        return 2 * $r * asin(min(1, sqrt($a)));
    }

    private function transform(Request $request, Laporan $laporan): array
    {
        $waktuPenyelesaian = $laporan->relationLoaded('riwayatStatus')
            ? $laporan->riwayatStatus->firstWhere('status_baru', 'selesai')?->created_at
            : null;
        $milik = (int) $laporan->user_id === (int) $request->user()->id;

        $riwayatSelesai = $laporan->relationLoaded('riwayatStatus')
            ? $laporan->riwayatStatus->firstWhere('status_baru', 'selesai')
            : null;
        $riwayatTolak = $laporan->relationLoaded('riwayatStatus')
            ? $laporan->riwayatStatus->firstWhere('status_baru', 'ditolak')
            : null;

        return [
            'id' => $laporan->id,
            'judul' => $laporan->judul,
            'deskripsi' => $laporan->deskripsi,
            'kategori' => $laporan->kategori,
            'status' => $laporan->status,
            'latitude' => (float) $laporan->latitude,
            'longitude' => (float) $laporan->longitude,
            'foto' => $this->fotoUrl($request, $laporan->foto),
            'catatan_penyelesaian' => $milik ? $riwayatSelesai?->catatan : null,
            'catatan_penolakan' => $milik ? $riwayatTolak?->catatan : null,
            'waktu_penyelesaian' => $waktuPenyelesaian
            ?->timezone('Asia/Jakarta')->locale('id')->isoFormat('D MMM YYYY, HH:mm'),
            'foto_penyelesaian' => (int) $laporan->user_id === (int) $request->user()->id && $laporan->foto_penyelesaian
                ? route('api.laporan.foto-penyelesaian', $laporan->id)
                : null,
            'tanggal_penyelesaian' => $waktuPenyelesaian?->toIso8601String(),
            'informasi_penyelesaian' => $laporan->status === 'selesai' ? 'Laporan telah ditangani oleh pihak terkait.' : null,
            'alamat' => $laporan->alamat_lokasi,
            'tanggal' => $laporan->created_at?->format('d M Y'),
            'created_at' => $laporan->created_at?->toIso8601String(),
            'timeline' => $laporan->relationLoaded('riwayatStatus')
            ? $laporan->riwayatStatus->map(fn ($item) => [
                'status' => $item->status_baru,
                'catatan' => $milik ? $item->catatan : null,
                'waktu' => $item->created_at?->toIso8601String(),
                ])->values()
                : [],
        ];
    }

    private function fotoUrl(Request $request, ?string $foto): ?string
    {
        if (! $foto) {
            return null;
        }

        return $request->getSchemeAndHttpHost().'/storage/'.ltrim($foto, '/');
    }

    private function messages(): array
    {
        return [
            'required' => ':attribute wajib diisi.',
            'string' => ':attribute harus berupa teks.',
            'max' => [
                'string' => ':attribute maksimal :max karakter.',
                'file' => 'Ukuran :attribute maksimal 5 MB.',
            ],
            'in' => ':attribute tidak valid.',
            'numeric' => ':attribute harus berupa angka.',
            'between' => ':attribute di luar rentang yang valid.',
            'image' => ':attribute harus berupa gambar.',
            'mimes' => ':attribute harus berformat JPG, JPEG, atau PNG.',
            'file' => ':attribute harus berupa berkas.',
            'uploaded' => 'Unggah :attribute gagal. Pastikan ukuran maksimal 5 MB.',
        ];
    }

    private function attributes(): array
    {
        return [
            'judul' => 'Judul',
            'deskripsi' => 'Deskripsi',
            'kategori' => 'Kategori',
            'latitude' => 'Latitude',
            'longitude' => 'Longitude',
            'alamat_lokasi' => 'Alamat lokasi',
            'foto' => 'Foto',
        ];
    }
}
