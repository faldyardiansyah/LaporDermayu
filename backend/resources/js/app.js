import { initAOS, initPreloader, initSplashScreen, initPasswordVisibility } from './aos-preloader.js';

document.addEventListener('DOMContentLoaded', () => {
    initPreloader();
    initPasswordVisibility();

    const splashIsVisible = document.documentElement.classList.contains('show-splash')
        && document.getElementById('app-splash');

    if (splashIsVisible) {
        document.addEventListener('lapordermayu:splash-hidden', initAOS, { once: true });
        initSplashScreen();
        return;
    }

    initAOS();
});
