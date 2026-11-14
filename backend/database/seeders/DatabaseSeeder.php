<?php

namespace Database\Seeders;

use App\Models\Instansi;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use RuntimeException;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        DB::transaction(function (): void {
            $instansi = Instansi::query()
                ->where('nama_instansi', Instansi::NAMA_PEMDA_INDRAMAYU)
                ->orderBy('id')
                ->first(['id']);

            if ($instansi === null) {
                throw new RuntimeException(
                    'Instansi "' . Instansi::NAMA_PEMDA_INDRAMAYU . '" belum tersedia. Seeder akun demo dibatalkan tanpa mengubah data.'
                );
            }

            $accounts = [
                [
                    'name' => 'Super Admin',
                    'email' => 'superadmin@gmail.com',
                    'role' => 'super_admin',
                    'instansi_id' => null,
                ],
                [
                    'name' => 'Admin Instansi',
                    'email' => 'instansi@gmail.com',
                    'role' => 'admin_instansi',
                    'instansi_id' => $instansi->id,
                ],
                [
                    'name' => 'User testing',
                    'email' => 'user@gmail.com',
                    'role' => 'masyarakat',
                    'instansi_id' => null,
                ],
            ];

            foreach ($accounts as $account) {
                User::query()->updateOrCreate(
                    ['email' => $account['email']],
                    [
                        ...$account,
                        'password' => Hash::make('12345678'),
                        'is_active' => true,
                    ],
                );
            }
        });
    }
}
