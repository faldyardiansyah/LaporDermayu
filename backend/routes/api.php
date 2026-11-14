<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\HomeController;
use App\Http\Controllers\Api\LaporanController;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware(['auth:sanctum', 'account.active'])->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::get('/home', [HomeController::class, 'index']);
    Route::get('/notifications', [HomeController::class, 'notifications']);
    Route::get('/laporan', [LaporanController::class, 'index']);
    Route::post('/laporan', [LaporanController::class, 'store']);
    Route::get('/laporan-peta', [LaporanController::class, 'peta']);
    Route::get('/laporan/{id}/foto-penyelesaian', [LaporanController::class, 'fotoPenyelesaian'])->whereNumber('id')->name('api.laporan.foto-penyelesaian');
    Route::get('/laporan/{id}', [LaporanController::class, 'show'])->whereNumber('id');
    Route::post('/logout', [AuthController::class, 'logout']);
});