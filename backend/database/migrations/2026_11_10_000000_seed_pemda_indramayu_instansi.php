<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('instansi')) {
            return;
        }

        DB::table('instansi')->updateOrInsert(
            ['nama_instansi' => 'Pemerintah Daerah Indramayu'],
            [
                'alamat' => 'Indramayu, Jawa Barat',
                'updated_at' => now(),
                'created_at' => now(),
            ],
        );
    }

    public function down(): void
    {
        DB::table('instansi')
            ->where('nama_instansi', 'Pemerintah Daerah Indramayu')
            ->delete();
    }
};
