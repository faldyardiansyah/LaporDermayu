<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Auth\LoginController;

Route::controller(LoginController::class)->group(function () {
    Route::get('/login', 'create')->name('login');
    Route::post('/login', 'store')->middleware('throttle:5,1');
    Route::post('/logout', 'destroy')->middleware('auth')->name('logout');
});
