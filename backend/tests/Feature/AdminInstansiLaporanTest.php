<?php

namespace Tests\Feature;

use App\Models\Instansi;
use App\Models\Laporan;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use PHPUnit\Framework\Attributes\TestWith;
use Tests\TestCase;

class AdminInstansiLaporanTest extends TestCase
{
    use LazilyRefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->withoutVite();
    }

    #[TestWith(['/admin/dashboard'])]
    #[TestWith(['/admin/laporan'])]
    #[TestWith(['/admin/laporan/1'])]
    #[TestWith(['/admin/statistik'])]
    public function test_guests_are_redirected_to_login(string $path): void
    {
        $this->get($path)->assertRedirect(route('login'));
    }

    public function test_guests_cannot_update_report_status(): void
    {
        $this->patch('/admin/laporan/1/status', ['status' => 'diproses'])->assertRedirect(route('login'));
    }

    #[TestWith(['masyarakat'])]
    #[TestWith(['petugas'])]
    #[TestWith(['super_admin'])]
    public function test_other_roles_cannot_read_instansi_reports(string $role): void
    {
        $user = User::factory()->create(['role' => $role]);

        $this->actingAs($user)->get(route('admin.laporan.index'))->assertForbidden();
    }

    #[TestWith(['masyarakat'])]
    #[TestWith(['petugas'])]
    #[TestWith(['super_admin'])]
    public function test_other_roles_cannot_update_report_status(string $role): void
    {
        $user = User::factory()->create(['role' => $role]);
        $report = Laporan::factory()->create();

        $this->actingAs($user)->patch(route('admin.laporan.status.update', $report->id), [
            'status' => 'diproses',
        ])->assertForbidden();

        $this->assertDatabaseHas('laporan', ['id' => $report->id, 'status' => 'menunggu']);
        $this->assertDatabaseCount('riwayat_status_laporan', 0);
    }

    public function test_an_admin_without_an_instansi_cannot_access_reports(): void
    {
        $admin = User::factory()->create(['role' => 'admin_instansi']);

        $this->actingAs($admin)->get(route('admin.laporan.index'))->assertForbidden();
    }

    public function test_inactive_admins_are_logged_out(): void
    {
        $admin = User::factory()->inactive()->for(Instansi::factory(), 'instansi')
            ->create(['role' => 'admin_instansi']);

        $this->actingAs($admin)->get(route('admin.laporan.index'))->assertRedirect(route('login'));

        $this->assertGuest();
    }

    #[TestWith(['admin.dashboard'])]
    #[TestWith(['admin.laporan.index'])]
    #[TestWith(['admin.statistik.index'])]
    public function test_admin_pages_render_empty_data_with_the_new_brand_and_navigation(string $routeName): void
    {
        $admin = User::factory()->for(Instansi::factory(), 'instansi')->create(['role' => 'admin_instansi']);

        $this->actingAs($admin)->get(route($routeName))->assertOk()
            ->assertSee('LaporDermayu')
            ->assertSee(route('admin.laporan.index'))
            ->assertSee(route('admin.statistik.index'))
            ->assertDontSee('Penugasan');
    }

    public function test_report_filters_only_return_matching_reports_for_the_current_instansi(): void
    {
        $instansi = Instansi::factory()->create();
        $admin = User::factory()->for($instansi, 'instansi')->create(['role' => 'admin_instansi']);
        $matchingReport = Laporan::factory()->for($instansi, 'instansi')->create([
            'judul' => 'Jalan berlubang dekat sekolah', 'kategori' => 'jalan_rusak', 'status' => 'diproses',
        ]);
        Laporan::factory()->for($instansi, 'instansi')->create([
            'judul' => 'Jalan berlubang lain', 'kategori' => 'jalan_rusak', 'status' => 'menunggu',
        ]);
        Laporan::factory()->for(Instansi::factory(), 'instansi')->create([
            'judul' => 'Jalan berlubang instansi lain', 'kategori' => 'Kategori instansi lain', 'status' => 'diproses',
        ]);

        $this->actingAs($admin)->get(route('admin.laporan.index', [
            'cari' => 'sekolah', 'kategori' => 'jalan_rusak', 'status' => 'diproses',
        ]))->assertOk()
            ->assertViewHas('laporan', fn ($reports): bool => $reports->pluck('id')->all() === [$matchingReport->id])
            ->assertViewHas('kategoriList', fn (array $categories): bool => in_array('jalan_rusak', $categories, true)
                && ! in_array('Kategori instansi lain', $categories, true))
            ->assertViewHas('totalLaporan', 2);
    }

    public function test_the_dashboard_links_to_reports_from_the_current_instansi(): void
    {
        $instansi = Instansi::factory()->create();
        $admin = User::factory()->for($instansi, 'instansi')->create(['role' => 'admin_instansi']);
        $report = Laporan::factory()->for($instansi, 'instansi')->create();
        $otherReport = Laporan::factory()->for(Instansi::factory(), 'instansi')->create();

        $this->actingAs($admin)->get(route('admin.dashboard'))->assertOk()
            ->assertViewHas('totalLaporan', 1)
            ->assertSee(route('admin.laporan.show', $report->id))
            ->assertDontSee($otherReport->judul);
    }

    public function test_report_details_escape_content_from_the_reporter(): void
    {
        $instansi = Instansi::factory()->create();
        $admin = User::factory()->for($instansi, 'instansi')->create(['role' => 'admin_instansi']);
        $unsafeContent = '<script>alert("report")</script>';
        $owner = User::factory()->create(['name' => $unsafeContent]);
        $report = Laporan::factory()->for($owner, 'pelapor')->for($instansi, 'instansi')->create([
            'judul' => $unsafeContent, 'deskripsi' => $unsafeContent,
            'kategori' => $unsafeContent, 'alamat_lokasi' => $unsafeContent,
        ]);

        $this->actingAs($admin)->get(route('admin.laporan.show', $report->id))->assertOk()
            ->assertSee($unsafeContent)->assertDontSee($unsafeContent, false);
    }

    public function test_reports_from_other_instansi_cannot_be_read_or_updated(): void
    {
        $admin = User::factory()->for(Instansi::factory(), 'instansi')->create(['role' => 'admin_instansi']);
        $report = Laporan::factory()->for(Instansi::factory(), 'instansi')->create();

        $this->actingAs($admin)->get(route('admin.laporan.show', $report->id))->assertNotFound();
        $this->patch(route('admin.laporan.status.update', $report->id), ['status' => 'diproses'])->assertNotFound();

        $this->assertDatabaseHas('laporan', ['id' => $report->id, 'status' => 'menunggu']);
        $this->assertDatabaseCount('riwayat_status_laporan', 0);
    }

    public function test_admins_can_process_reports_and_record_the_status_history(): void
    {
        $instansi = Instansi::factory()->create();
        $admin = User::factory()->for($instansi, 'instansi')->create(['role' => 'admin_instansi']);
        $report = Laporan::factory()->for($instansi, 'instansi')->create();

        $this->actingAs($admin)->patch(route('admin.laporan.status.update', $report->id), [
            'status' => 'diproses', 'catatan' => 'Laporan sudah diverifikasi.',
        ])->assertRedirect()->assertSessionHas('success', 'Status laporan berhasil diperbarui.');

        $this->assertDatabaseHas('laporan', ['id' => $report->id, 'status' => 'diproses']);
        $this->assertDatabaseHas('riwayat_status_laporan', [
            'laporan_id' => $report->id, 'user_id' => $admin->id,
            'status_sebelumnya' => 'menunggu', 'status_baru' => 'diproses',
            'catatan' => 'Laporan sudah diverifikasi.',
        ]);
        $this->assertDatabaseCount('penugasan', 0);
    }

    public function test_rejecting_a_pending_report_requires_a_reason(): void
    {
        $instansi = Instansi::factory()->create();
        $admin = User::factory()->for($instansi, 'instansi')->create(['role' => 'admin_instansi']);
        $report = Laporan::factory()->for($instansi, 'instansi')->create();

        $this->actingAs($admin)->patch(route('admin.laporan.status.update', $report->id), [
            'status' => 'ditolak',
        ])->assertSessionHasErrors('catatan');

        $this->assertDatabaseHas('laporan', ['id' => $report->id, 'status' => 'menunggu']);
        $this->assertDatabaseCount('riwayat_status_laporan', 0);
    }

    public function test_admins_can_reject_a_pending_report_with_a_reason(): void
    {
        $instansi = Instansi::factory()->create();
        $admin = User::factory()->for($instansi, 'instansi')->create(['role' => 'admin_instansi']);
        $report = Laporan::factory()->for($instansi, 'instansi')->create();

        $this->actingAs($admin)->patch(route('admin.laporan.status.update', $report->id), [
            'status' => 'ditolak', 'catatan' => 'Laporan berada di luar wilayah layanan.',
        ])->assertRedirect()->assertSessionHas('success', 'Status laporan berhasil diperbarui.');

        $this->assertDatabaseHas('laporan', ['id' => $report->id, 'status' => 'ditolak']);
        $this->assertDatabaseHas('riwayat_status_laporan', [
            'laporan_id' => $report->id, 'status_baru' => 'ditolak',
            'catatan' => 'Laporan berada di luar wilayah layanan.',
        ]);
    }

    public function test_completing_a_report_requires_evidence(): void
    {
        $instansi = Instansi::factory()->create();
        $admin = User::factory()->for($instansi, 'instansi')->create(['role' => 'admin_instansi']);
        $report = Laporan::factory()->for($instansi, 'instansi')->create(['status' => 'diproses']);

        $this->actingAs($admin)->patch(route('admin.laporan.status.update', $report->id), [
            'status' => 'selesai',
        ])->assertSessionHasErrors('foto_penyelesaian');

        $this->assertDatabaseHas('laporan', ['id' => $report->id, 'status' => 'diproses']);
        $this->assertDatabaseCount('riwayat_status_laporan', 0);
    }

    public function test_completion_evidence_must_be_an_image(): void
    {
        $instansi = Instansi::factory()->create();
        $admin = User::factory()->for($instansi, 'instansi')->create(['role' => 'admin_instansi']);
        $report = Laporan::factory()->for($instansi, 'instansi')->create(['status' => 'diproses']);
        Storage::fake('local');

        $this->actingAs($admin)->patch(route('admin.laporan.status.update', $report->id), [
            'status' => 'selesai', 'foto_penyelesaian' => UploadedFile::fake()->create('bukti.pdf', 10, 'application/pdf'),
        ])->assertSessionHasErrors('foto_penyelesaian');

        $this->assertDatabaseHas('laporan', ['id' => $report->id, 'status' => 'diproses']);
        $this->assertDatabaseCount('riwayat_status_laporan', 0);
        Storage::disk('local')->assertDirectoryEmpty('bukti-penyelesaian');
    }

    public function test_completion_evidence_cannot_exceed_five_megabytes(): void
    {
        $instansi = Instansi::factory()->create();
        $admin = User::factory()->for($instansi, 'instansi')->create(['role' => 'admin_instansi']);
        $report = Laporan::factory()->for($instansi, 'instansi')->create(['status' => 'diproses']);
        Storage::fake('local');

        $this->actingAs($admin)->patch(route('admin.laporan.status.update', $report->id), [
            'status' => 'selesai', 'foto_penyelesaian' => UploadedFile::fake()->image('bukti.png')->size(5121),
        ])->assertSessionHasErrors('foto_penyelesaian');

        $this->assertDatabaseHas('laporan', ['id' => $report->id, 'status' => 'diproses']);
        $this->assertDatabaseCount('riwayat_status_laporan', 0);
        Storage::disk('local')->assertDirectoryEmpty('bukti-penyelesaian');
    }

    public function test_admins_can_complete_reports_with_evidence_without_assigning_an_officer(): void
    {
        $instansi = Instansi::factory()->create();
        $admin = User::factory()->for($instansi, 'instansi')->create(['role' => 'admin_instansi']);
        $report = Laporan::factory()->for($instansi, 'instansi')->create([
            'status' => 'diproses', 'foto' => 'laporan/foto-awal.jpg',
        ]);
        Storage::fake('local');

        $this->actingAs($admin)->patch(route('admin.laporan.status.update', $report->id), [
            'status' => 'selesai', 'foto_penyelesaian' => UploadedFile::fake()->image('bukti.png'),
        ])->assertRedirect()->assertSessionHas('success', 'Status laporan berhasil diperbarui.');

        $report->refresh();
        $this->assertSame('selesai', $report->status);
        $this->assertSame('laporan/foto-awal.jpg', $report->foto);
        Storage::disk('local')->assertExists($report->foto_penyelesaian);
        $this->assertDatabaseHas('riwayat_status_laporan', [
            'laporan_id' => $report->id, 'user_id' => $admin->id,
            'status_sebelumnya' => 'diproses', 'status_baru' => 'selesai',
        ]);
        $this->assertDatabaseCount('penugasan', 0);
    }

    #[TestWith(['menunggu', 'selesai'])]
    #[TestWith(['diproses', 'ditolak'])]
    #[TestWith(['selesai', 'diproses'])]
    #[TestWith(['ditolak', 'diproses'])]
    public function test_status_changes_must_follow_the_report_workflow(string $currentStatus, string $nextStatus): void
    {
        $instansi = Instansi::factory()->create();
        $admin = User::factory()->for($instansi, 'instansi')->create(['role' => 'admin_instansi']);
        $report = Laporan::factory()->for($instansi, 'instansi')->create(['status' => $currentStatus]);
        Storage::fake('local');

        $this->actingAs($admin)->patch(route('admin.laporan.status.update', $report->id), [
            'status' => $nextStatus, 'catatan' => 'Catatan pengujian.',
            'foto_penyelesaian' => UploadedFile::fake()->image('bukti.png'),
        ])->assertSessionHasErrors('status');

        $this->assertDatabaseHas('laporan', ['id' => $report->id, 'status' => $currentStatus]);
        $this->assertDatabaseCount('riwayat_status_laporan', 0);
        Storage::disk('local')->assertDirectoryEmpty('bukti-penyelesaian');
    }

    public function test_repeating_a_status_change_does_not_duplicate_history(): void
    {
        $instansi = Instansi::factory()->create();
        $admin = User::factory()->for($instansi, 'instansi')->create(['role' => 'admin_instansi']);
        $report = Laporan::factory()->for($instansi, 'instansi')->create(['status' => 'diproses']);

        $this->actingAs($admin)->patch(route('admin.laporan.status.update', $report->id), [
            'status' => 'diproses',
        ])->assertRedirect()->assertSessionHas('success', 'Status laporan tidak berubah.');

        $this->assertDatabaseCount('riwayat_status_laporan', 0);
    }

    public function test_failed_status_updates_roll_back_history_and_remove_uploaded_evidence(): void
    {
        $instansi = Instansi::factory()->create();
        $admin = User::factory()->for($instansi, 'instansi')->create(['role' => 'admin_instansi']);
        $report = Laporan::factory()->for($instansi, 'instansi')->create(['status' => 'diproses']);
        Storage::fake('local');
        $dispatcher = Laporan::getEventDispatcher();
        Laporan::setEventDispatcher(clone $dispatcher);

        try {
            Laporan::updating(static fn (): bool => false);

            $this->actingAs($admin)->withHeader('Accept', 'application/json')
                ->patch(route('admin.laporan.status.update', $report->id), [
                    'status' => 'selesai', 'foto_penyelesaian' => UploadedFile::fake()->image('bukti.png'),
                ])->assertServerError();
        } finally {
            Laporan::setEventDispatcher($dispatcher);
        }

        $this->assertDatabaseHas('laporan', ['id' => $report->id, 'status' => 'diproses', 'foto_penyelesaian' => null]);
        $this->assertDatabaseCount('riwayat_status_laporan', 0);
        Storage::disk('local')->assertDirectoryEmpty('bukti-penyelesaian');
    }
}
