import { initAOS, initPreloader, initSplashScreen } from './aos-preloader.js';

document.addEventListener('DOMContentLoaded', () => {
    initPreloader();

    const splashIsVisible = document.documentElement.classList.contains('show-splash')
        && document.getElementById('app-splash');

    if (splashIsVisible) {
        document.addEventListener('lapordermayu:splash-hidden', initAOS, { once: true });
        initSplashScreen();
        return;
    }

    initAOS();
});
