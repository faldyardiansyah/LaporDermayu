<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Laporan;
use App\Models\RiwayatStatusLaporan;
use App\Support\IndramayuBoundary;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;
use RuntimeException;

class LaporanController extends Controller
{
    private const KATEGORI_LAPORAN = ['Kerusakan Jalan', 'Kerusakan Rambu'];

    public function index(Request $request, IndramayuBoundary $boundary): View
    {
        $instansiId = $request->user()->instansi_id;
        $kategoriList = collect(self::KATEGORI_LAPORAN)
            ->merge(Laporan::query()->forInstansi($instansiId)
                ->whereNotNull('kategori')->where('kategori', '!=', '')
                ->distinct()->pluck('kategori'))
            ->unique()->sort()->values()->all();
        $filters = $request->validate([
            'cari' => ['nullable', 'string', 'max:100'],
            'status' => ['nullable', 'in:menunggu,diproses,selesai,ditolak'],
            'kategori' => ['nullable', Rule::in($kategoriList)],
        ]);

        $query = DB::table('laporan')
            ->leftJoin('users', 'laporan.user_id', '=', 'users.id')
            ->whereIn('laporan.id', Laporan::query()->forInstansi($instansiId)->select('id'))
            ->select(
                'laporan.id',
                'laporan.judul',
                'laporan.deskripsi',
                'laporan.kategori',
                'laporan.alamat_lokasi',
                'laporan.status',
                'laporan.latitude',
                'laporan.longitude',
                'laporan.foto',
                'laporan.created_at',
                'users.name as nama_pelapor',
                'users.email as email_pelapor'
            );

        if (! empty($filters['cari'])) {
            $search = trim($filters['cari']);

            $query->where(function ($builder) use ($search): void {
                $builder->where('laporan.judul', 'like', "%{$search}%")
                    ->orWhere('laporan.kategori', 'like', "%{$search}%")
                    ->orWhere('laporan.alamat_lokasi', 'like', "%{$search}%")
                    ->orWhere('users.name', 'like', "%{$search}%");

                if (ctype_digit($search)) {
                    $builder->orWhere('laporan.id', (int) $search);
                }
            });
        }

        if (! empty($filters['status'])) {
            $query->where('laporan.status', $filters['status']);
        }

        if (! empty($filters['kategori'])) {
            $query->where('laporan.kategori', $filters['kategori']);
        }

        $laporan = $query
            ->orderByDesc('laporan.created_at')
            ->orderByDesc('laporan.id')
            ->paginate(10)
            ->withQueryString();

        $laporanPeta = $laporan->getCollection()
            ->map(fn (object $item): array => [
                'id' => $item->id,
                'judul' => $item->judul,
                'kategori' => $item->kategori,
                'status' => $item->status,
                'alamat' => $item->alamat_lokasi,
                'latitude' => is_numeric($item->latitude) ? (float) $item->latitude : null,
                'longitude' => is_numeric($item->longitude) ? (float) $item->longitude : null,
                'url' => route('admin.laporan.show', $item->id),
            ]);

        $jumlahStatus = DB::table('laporan')
            ->whereIn('id', Laporan::query()->forInstansi($instansiId)->select('id'))
            ->select('status', DB::raw('COUNT(*) as jumlah'))
            ->groupBy('status')
            ->pluck('jumlah', 'status');

        $totalLaporan = (int) $jumlahStatus->sum();
        $menunggu = (int) ($jumlahStatus['menunggu'] ?? 0);
        $diproses = (int) ($jumlahStatus['diproses'] ?? 0);
        $selesai = (int) ($jumlahStatus['selesai'] ?? 0);
        $ditolak = (int) ($jumlahStatus['ditolak'] ?? 0);

        $regionBounds = $boundary->bounds();

        return view('admin.laporan.index', compact(
            'laporan',
            'laporanPeta',
            'regionBounds',
            'totalLaporan',
            'menunggu',
            'diproses',
            'selesai',
            'ditolak',
            'kategoriList'
        ));
    }

    public function show(Request $request, int $id): View
    {
        $laporan = Laporan::query()
            ->with([
                'pelapor:id,name,email',
                'riwayatStatus' => fn ($query) => $query
                    ->with('pengguna:id,name')
                    ->latest(),
            ])
            ->forInstansi($request->user()->instansi_id)
            ->findOrFail($id);

        return view('admin.laporan.detail', compact('laporan'));
    }

    public function updateStatus(Request $request, int $id): RedirectResponse
    {
        $validated = $request->validate([
            'status' => ['required', 'in:diproses,selesai,ditolak'],
            'catatan' => ['required_if:status,ditolak', 'nullable', 'string', 'max:1000'],
            'foto_penyelesaian' => ['required_if:status,selesai', 'nullable', 'image', 'mimes:jpg,jpeg,png', 'max:5120'],
        ]);

        $fotoPenyelesaian = null;
        if ($validated['status'] === 'selesai') {
            $fotoPenyelesaian = $request->file('foto_penyelesaian')->store('bukti-penyelesaian', 'local');
            if (! $fotoPenyelesaian) {
                return back()->withErrors(['foto_penyelesaian' => 'Foto bukti penyelesaian gagal disimpan. Silakan coba lagi.'])->withInput();
            }
        }

        $admin = $request->user();
        try {
            $changed = DB::transaction(function () use ($admin, $id, $validated, $fotoPenyelesaian): bool {
                $laporan = Laporan::query()
                    ->forInstansi($admin->instansi_id)
                    ->lockForUpdate()
                    ->findOrFail($id);

                if ($laporan->status === $validated['status']) {
                    return false;
                }

                $nextStatuses = match ($laporan->status) {
                    'menunggu' => ['diproses', 'ditolak'],
                    'diproses' => ['selesai'],
                    default => [],
                };

                if (! in_array($validated['status'], $nextStatuses, true)) {
                    throw ValidationException::withMessages([
                        'status' => 'Perubahan status tidak sesuai alur penanganan laporan.',
                    ]);
                }

                RiwayatStatusLaporan::query()->create([
                    'laporan_id' => $laporan->id,
                    'user_id' => $admin->id,
                    'status_sebelumnya' => $laporan->status,
                    'status_baru' => $validated['status'],
                    'catatan' => $validated['catatan'] ?? null,
                ]);

                if (! $laporan->update([
                    'status' => $validated['status'],
                    'foto_penyelesaian' => $fotoPenyelesaian ?? $laporan->foto_penyelesaian,
                ])) {
                    throw new RuntimeException('Status laporan gagal disimpan.');
                }

                return true;
            });
        } catch (\Throwable $exception) {
            if ($fotoPenyelesaian) {
                Storage::disk('local')->delete($fotoPenyelesaian);
            }

            throw $exception;
        }

        if (! $changed && $fotoPenyelesaian) {
            Storage::disk('local')->delete($fotoPenyelesaian);
        }

        return back()->with(
            'success',
            $changed ? 'Status laporan berhasil diperbarui.' : 'Status laporan tidak berubah.'
        );
    }
}
