/**
 * Custom Native AOS (Animate On Scroll) & Preloader System
 * Designed for LaporDermayu
 */

export function initAOS() {
    const animatedElements = [...document.querySelectorAll('[data-aos]')];
    if (!animatedElements.length) return;

    const animateContainer = (element) => {
        element.classList.add('aos-animate');
    };

    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
        animatedElements.forEach(animateContainer);
        return;
    }

    if (!('IntersectionObserver' in window)) {
        animatedElements.forEach(animateContainer);
        return;
    }

    let nextRevealAt = 0;
    const queuedContainers = new Set();
    const observer = new IntersectionObserver((entries) => {
        entries
            .filter((entry) => entry.isIntersecting)
            .sort((first, second) => first.boundingClientRect.top - second.boundingClientRect.top)
            .forEach((entry) => {
                const container = entry.target;
                observer.unobserve(container);

                if (queuedContainers.has(container)) return;

                queuedContainers.add(container);
                const now = window.performance.now();
                const delay = Math.max(0, nextRevealAt - now);
                nextRevealAt = now + delay + 280;

                window.setTimeout(() => {
                    animateContainer(container);
                    queuedContainers.delete(container);
                }, delay);
            });
    }, {
        threshold: 0.08,
        rootMargin: '0px 0px -20px 0px'
    });

    animatedElements.forEach(el => observer.observe(el));
}

export function initPreloader() {
    const preloader = document.getElementById('app-preloader');
    if (!preloader) return;

    const hidePreloader = () => {
        preloader.classList.add('preloader-hidden');
    };

    document.addEventListener('click', (event) => {
        const link = event.target.closest('a');
        if (!link) return;

        if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) {
            return;
        }

        const href = link.getAttribute('href');
        const target = link.getAttribute('target');

        if (!href || href.startsWith('#') || href.startsWith('javascript:') || href.startsWith('tel:') || href.startsWith('mailto:') || target === '_blank' || link.hasAttribute('download')) {
            return;
        }


        try {
            const url = new URL(link.href, window.location.origin);
            if (url.origin === window.location.origin) {
                if (url.pathname === window.location.pathname && url.search === window.location.search && url.hash) {
                    return;
                }
                showPreloader('Menyiapkan LaporDermayu...');
                Promise.resolve().then(() => {
                    if (event.defaultPrevented) {
                        clearNavigationPending();
                        hidePreloader();
                    }
                });
            }
        } catch {
        }
    });

    document.addEventListener('submit', (event) => {
        const form = event.target;
        if (!form) return;

        if (form.getAttribute('target') === '_blank' || form.hasAttribute('data-no-preloader')) return;

        if (event.defaultPrevented) return;

        try {
            const url = new URL(form.action, window.location.origin);
            if (url.origin === window.location.origin) {
                showPreloader('Menyiapkan LaporDermayu...');
                Promise.resolve().then(() => {
                    if (event.defaultPrevented) {
                        clearNavigationPending();
                        hidePreloader();
                    }
                });
            }
        } catch {
        }
    });

    window.addEventListener('pageshow', (event) => {
        if (event.persisted) {
            hidePreloader();
        }
    });
}

export function initSplashScreen() {
    const splash = document.getElementById('app-splash');
    if (!splash || !document.documentElement.classList.contains('show-splash')) return;

    const hideSplash = () => {
        splash.classList.add('splash-hidden');
        document.documentElement.classList.remove('show-splash');
        window.setTimeout(() => {
            document.dispatchEvent(new Event('lapordermayu:splash-hidden'));
        }, 580);
    };

    window.setTimeout(hideSplash, 950);
}

