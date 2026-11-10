<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <script>
        try {
            if (!sessionStorage.getItem('lapordermayu-splash-seen')) {
                sessionStorage.setItem('lapordermayu-splash-seen', '1');
                document.documentElement.classList.add('show-splash');
            }
        } catch (error) {
        }
    </script>
    <title>Masuk Admin Instansi | LaporDermayu</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="auth-page">
    @include('partials.preloader')
    <div id="app-splash" role="status" aria-live="polite" aria-label="Memuat LaporDermayu">
        <div class="splash-content">
            <img src="{{ asset('picture/logo.png') }}" alt="Logo LaporDermayu" class="splash-logo">
            <p class="splash-name">LaporDermayu</p>
            <p class="splash-tagline">Bersama menjaga jalan Indramayu.</p>
            <span class="splash-spinner" aria-hidden="true"></span>
        </div>
    </div>
    <main class="auth-card" data-aos="fade-up">
        <section class="auth-art" aria-label="LaporDermayu membantu menjaga perjalanan tetap aman">
            <div class="auth-art-copy">
                <span class="auth-art-kicker">Lapor Dermayu, AMAN BERKENDARA</span>
                <h1>Perjalanan aman<br>dimulai dari sini.</h1>
                <p>Pantau dan tindak lanjuti laporan infrastruktur jalan bersama LaporDermayu.</p>
            </div>
            <div class="auth-animation" id="lapordermayuAnimation" role="img" aria-label="Animasi bersepeda"></div>
            <span class="auth-orb auth-orb-one" aria-hidden="true"></span>
            <span class="auth-orb auth-orb-two" aria-hidden="true"></span>
        </section>

        <section class="auth-panel" aria-labelledby="loginHeading">
            <a href="{{ route('home') }}" class="auth-brand" aria-label="LaporDermayu, beranda">
                <img src="{{ asset('picture/logo.png') }}" alt="Logo LaporDermayu">
                <span>LaporDermayu</span>
            </a>

            <div class="auth-heading">
                <span class="auth-eyebrow">PORTAL ADMINISTRASI</span>
                <h2 id="loginHeading">Masuk ke akun Anda</h2>
                <p>Gunakan akun admin instansi untuk mengelola laporan infrastruktur.</p>
            </div>

            @if ($errors->any())
                <div class="auth-alert" role="alert">
                    {{ $errors->first() }}
                </div>
            @endif

            <form method="POST" action="{{ route('login') }}" class="auth-form">
                @csrf

                <div class="auth-field">
                    <label for="email">Email</label>
                    <input
                        id="email"
                        name="email"
                        type="email"
                        value="{{ old('email') }}"
                        autocomplete="username"
                        required
                        autofocus
                        placeholder="nama@instansi.go.id"
                    >
                </div>

                <div class="auth-field">
                    <label for="password">Kata sandi</label>
                    <div class="auth-password-control">
                        <input
                            id="password"
                            name="password"
                            type="password"
                            autocomplete="current-password"
                            required
                            placeholder="Masukkan kata sandi"
                        >
                        <button type="button" class="password-visibility-toggle" data-password-toggle aria-label="Tampilkan password" aria-controls="password" aria-pressed="false">
                            <svg data-eye-open viewBox="0 0 24 24" aria-hidden="true"><path d="M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/></svg>
                            <svg data-eye-closed viewBox="0 0 24 24" aria-hidden="true" hidden><path d="m3 3 18 18M10.6 10.6a2 2 0 0 0 2.8 2.8M9.9 5.2A10.7 10.7 0 0 1 12 5c6.4 0 10 7 10 7a16 16 0 0 1-3.1 3.8M6.2 6.2C3.5 8 2 12 2 12s3.6 7 10 7a10 10 0 0 0 3-.5"/></svg>
                        </button>
                    </div>
                </div>

                <label class="auth-remember">
                    <input type="checkbox" name="remember" value="1">
                    <span>Ingat saya</span>
                </label>

                <button type="submit" class="auth-submit">Masuk</button>
            </form>

            <p class="auth-footnote">Akses hanya untuk admin instansi LaporDermayu.</p>
        </section>
    </main>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/bodymovin/5.12.2/lottie.min.js" defer></script>
    <script>
        window.addEventListener('load', () => {
            const splash = document.getElementById('app-splash');

            if (splash) {
                window.setTimeout(() => {
                    splash.classList.add('splash-hidden');
                    document.documentElement.classList.remove('show-splash');
                }, 700);
            }

            if (window.lottie) {
                window.lottie.loadAnimation({
                    container: document.getElementById('lapordermayuAnimation'),
                    renderer: 'svg',
                    loop: true,
                    autoplay: true,
                    path: @json(asset('animations/Bike Riding.json')),
                });
            }
        });
    </script>
</body>
</html>
