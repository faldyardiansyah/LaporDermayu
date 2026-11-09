import 'package:get/get.dart';
import 'package:lapordermayu/modules/onboarding/controllers/onboarding_controller.dart';
import 'package:lapordermayu/modules/onboarding/views/onboarding_view.dart';
import 'package:lapordermayu/modules/splash/controllers/splash_controller.dart';
import 'package:lapordermayu/modules/splash/views/splash_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SplashController>(() => SplashController());
      }),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<OnboardingController>(() => OnboardingController());
      }),
    ),
  ];
}
