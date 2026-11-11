<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Laporan;
use App\Models\RiwayatStatusLaporan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use LogicException;
use Pdo\Sqlite;

class HomeController extends Controller
{
    // SESUAIKAN dengan nilai status yang dipakai dashboard admin.
    private const STATUS_MENUNGGU = ['menunggu'];

    // Laporan yang sudah lolos verifikasi (termasuk yang sudah ditangani)
    private const STATUS_TERVERIFIKASI = ['terverifikasi', 'diproses', 'diperbaiki', 'selesai'];

    private const STATUS_SELESAI = ['diperbaiki', 'selesai'];

    // Laporan yang boleh tampil di "Kondisi Saat Ini": sudah diverifikasi, belum selesai
    private const STATUS_TAMPIL_SEKITAR = ['terverifikasi', 'diproses'];

    private const NEARBY_RADIUS_KM = 2;

    private const NEARBY_LIMIT = 10;

    public function index(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        $lat = $request->query('lat');
        $lon = $request->query('lon');

        // STATISTIK LAPORAN PENGGUNA (satu query)
        $counts = Laporan::where('user_id', $userId)
            ->selectRaw('status, COUNT(*) as total')
            ->groupBy('status')
            ->pluck('total', 'status');

        $sum = fn (array $statuses) => (int) $counts->only($statuses)->sum();

        // LAPORAN TERKINI MILIK PENGGUNA (semua status, supaya user lihat progresnya)
        $recentReports = Laporan::where('user_id', $userId)
            ->latest()
            ->limit(5)
            ->get()
            ->map(fn (Laporan $laporan) => [
                'id' => $laporan->id,
                'judul' => $laporan->judul,
                'alamat' => $laporan->alamat_lokasi,
                'kategori' => $laporan->kategori,
                'status' => $laporan->status,
                'foto' => $this->fotoUrl($request, $laporan->foto),
                'tanggal' => $laporan->created_at?->format('d M Y'),
            ])
            ->values();

        // KONDISI SEKITAR (semua pengguna, hanya yang sudah diverifikasi)
        $nearby = collect();

        if (is_numeric($lat) && is_numeric($lon)) {
            $lat = (float) $lat;
            $lon = (float) $lon;

            if ($lat >= -90 && $lat <= 90 && $lon >= -180 && $lon <= 180) {
                $distance = $this->nearbyDistance($lat, $lon);
                $nearbyQuery = Laporan::query()
                    ->withinIndramayu()
                    ->whereIn('status', self::STATUS_TAMPIL_SEKITAR)
                    ->whereNotNull('latitude')
                    ->whereNotNull('longitude')
                    ->select([
                        'id',
                        'judul',
                        'alamat_lokasi',
                        'kategori',
                        'status',
                        'foto',
                    ])
                    ->selectRaw($distance['expression'].' AS jarak_km', $distance['bindings']);

                $nearby = Laporan::query()
                    ->fromSub($nearbyQuery, 'nearby_reports')
                    ->where('jarak_km', '<=', self::NEARBY_RADIUS_KM)
                    ->orderBy('jarak_km')
                    ->orderBy('id')
                    ->limit(self::NEARBY_LIMIT)
                    ->get()
                    ->map(fn (Laporan $laporan) => [
                        'id' => $laporan->id,
                        'judul' => $laporan->judul,
                        'alamat' => $laporan->alamat_lokasi,
                        'kategori' => $laporan->kategori,
                        'status' => $laporan->status,
                        'foto' => $this->fotoUrl($request, $laporan->foto),
                        'jarak_km' => round((float) $laporan->jarak_km, 2),
                    ])
                    ->values();
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Data Home berhasil diambil',

            'stats' => [
                'total' => (int) $counts->sum(),
                'terverifikasi' => $sum(self::STATUS_TERVERIFIKASI),
                'diperbaiki' => $sum(self::STATUS_SELESAI),
                'menunggu' => $sum(self::STATUS_MENUNGGU),
            ],

            'recent_reports' => $recentReports,
            'nearby' => $nearby,
        ]);
    }

    /**
     * SQLite pada sebagian distribusi PHP tidak menyediakan fungsi trigonometri SQL.
     *
     * @return array{expression: string, bindings: list<float>}
     */
    private function nearbyDistance(float $latitude, float $longitude): array
    {
        $connection = (new Laporan)->getConnection();

        if ($connection->getDriverName() !== 'sqlite') {
            return [
                'expression' => '(6371 * ACOS(LEAST(1, GREATEST(-1,
                    COS(RADIANS(?)) * COS(RADIANS(latitude)) * COS(RADIANS(longitude) - RADIANS(?))
                    + SIN(RADIANS(?)) * SIN(RADIANS(latitude))
                ))))',
                'bindings' => [$latitude, $longitude, $latitude],
            ];
        }

        $pdo = $connection->getReadPdo();

        if (! $pdo instanceof Sqlite || ! $pdo->createFunction(
            'lapordermayu_distance_km',
            static fn (float $latitudeA, float $longitudeA, float $latitudeB, float $longitudeB): float => 6371 * acos(min(1, max(-1,
                cos(deg2rad($latitudeA)) * cos(deg2rad($latitudeB)) * cos(deg2rad($longitudeB) - deg2rad($longitudeA))
                + sin(deg2rad($latitudeA)) * sin(deg2rad($latitudeB))
            ))),
            4,
            Sqlite::DETERMINISTIC,
        )) {
            throw new LogicException('Fungsi perhitungan jarak SQLite tidak dapat didaftarkan.');
        }

        return [
            'expression' => 'lapordermayu_distance_km(?, ?, latitude, longitude)',
            'bindings' => [$latitude, $longitude],
        ];
    }

    public function notifications(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        // 1. Notifikasi perubahan status laporan oleh Admin Instansi
        $statusUpdates = RiwayatStatusLaporan::with('laporan:id,user_id,judul,kategori,foto_penyelesaian')
            ->whereHas('laporan', fn ($q) => $q->where('user_id', $userId))
            ->latest()
            ->limit(15)
            ->get()
            ->map(fn (RiwayatStatusLaporan $item) => [
                'id' => 'status-'.$item->id,
                'laporan_id' => $item->laporan?->id,
                'judul' => 'Status Laporan: '.ucfirst($item->status_baru),
                'pesan' => $item->catatan
                    ? "{$item->laporan?->judul} — {$item->catatan}"
                    : "Laporan \"{$item->laporan?->judul}\" kini berstatus {$item->status_baru}.",
                'tipe' => $item->status_baru,
                'foto_penyelesaian' => $item->status_baru === 'selesai' && $item->laporan?->foto_penyelesaian
                    ? route('api.laporan.foto-penyelesaian', $item->laporan->id)
                    : null,
                'tanggal_penyelesaian' => $item->status_baru === 'selesai'
                    ? $item->created_at?->toIso8601String()
                    : null,
                'waktu' => $item->created_at?->diffForHumans() ?? 'Baru saja',
                'created_at' => $item->created_at?->toIso8601String(),
            ]);

        // 2. Notifikasi laporan yang dikirim pengguna
        $submitted = Laporan::where('user_id', $userId)
            ->latest()
            ->limit(10)
            ->get()
            ->map(fn (Laporan $laporan) => [
                'id' => 'laporan-'.$laporan->id,
                'judul' => 'Laporan Terkirim',
                'pesan' => "Laporan \"{$laporan->judul}\" berhasil tercatat dengan status {$laporan->status}.",
                'tipe' => $laporan->status,
                'waktu' => $laporan->created_at?->diffForHumans() ?? 'Baru saja',
                'created_at' => $laporan->created_at?->toIso8601String(),
            ]);

        $notifications = $statusUpdates
            ->concat($submitted)
            ->sortByDesc('created_at')
            ->take(15)
            ->values();

        return response()->json([
            'success' => true,
            'total' => $notifications->count(),
            'data' => $notifications,
        ]);
    }

    private function fotoUrl(Request $request, ?string $foto): ?string
    {
        if (! $foto) {
            return null;
        }

        return $request->getSchemeAndHttpHost().'/storage/'.ltrim($foto, '/');
    }
}
