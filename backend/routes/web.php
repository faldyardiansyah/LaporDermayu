<?php


use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\superadmin\DashboardController as SuperAdminDashboardController;
use App\Http\Controllers\superadmin\PetaLaporanController;
use Illuminate\Support\Facades\Route;


Route::get('/', [LoginController::class, 'create'])->name('home');

Route::controller(LoginController::class)->group(function () {
    Route::get('/login', 'create')->name('login');
    Route::post('/login', 'store')->middleware('throttle:5,1');
    Route::post('/logout', 'destroy')->middleware('auth')->name('logout');
});

Route::middleware(['auth', 'super.admin'])
    ->prefix('superadmin')
    ->name('superadmin.')
    ->group(function () {
        Route::get('/dashboard', [SuperAdminDashboardController::class, 'index'])->name('dashboard');
        Route::get('/peta-laporan', PetaLaporanController::class)->name('laporan.peta');
        
        });
