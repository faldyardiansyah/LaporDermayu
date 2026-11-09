import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:lapordermayu/core/api_service.dart';
import 'package:lapordermayu/utils/widgets/lapor_dermayu_loading.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../utils/widgets/show_awesome_snackbar.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final formKey = GlobalKey<FormState>();
  final _box = GetStorage();

  final isPasswordHidden = true.obs;
  final rememberMe = true.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    rememberMe.value = _box.read('remember_me') ?? true;

    if (rememberMe.value) {
      emailController.text = _box.read('remember_email') ?? '';
    }
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi';
    }
    if (!GetUtils.isEmail(value.trim())) {
      return 'Masukkan email yang benar';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  Future<void> login() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (isLoading.value) return;
    if (!formKey.currentState!.validate()) return;

    // Wajib centang "Ingat saya"
    if (!rememberMe.value) {
      showAwesomeSnackbar(
        title: 'Centang dulu ya',
        message: 'Aktifkan "Ingat saya" untuk masuk.',
        contentType: ContentType.warning,
      );
      return;
    }

    isLoading.value = true;
    LaporDermayuLoading.show(message: 'Menyiapkan perjalanan aman...');

    try {
      debugPrint('[LOGIN] kirim request...');
      final response = await ApiService.dio.post(
        '/login',
        data: {
          'email': emailController.text.trim(),
          'password': passwordController.text,
        },
      );
      debugPrint('[LOGIN] respon: ${response.statusCode}');

      // Simpan sesi. Kalau gagal, jangan batalkan login.
      try {
        await _box.write('token', response.data['token']);
        await _box.write('user', response.data['user']);
        await _box.write('remember_me', true);
        await _box.write('remember_email', emailController.text.trim());
        debugPrint('[LOGIN] sesi tersimpan');
      } catch (e) {
        debugPrint('[LOGIN] gagal simpan sesi: $e');
      }

      LaporDermayuLoading.hide();
      Get.offAllNamed('/main');
    } on DioException catch (e) {
      debugPrint(
        '[LOGIN] DioException: ${e.type} | ${e.response?.statusCode} | ${e.message}',
      );
      LaporDermayuLoading.hide();

      showAwesomeSnackbar(
        title: 'Login gagal',
        message: ApiService.errorMessage(
          e,
          fallback: 'Terjadi kesalahan saat masuk.',
        ),
        contentType: ContentType.failure,
      );
    } catch (e) {
      debugPrint('[LOGIN] error: $e');
      LaporDermayuLoading.hide();

      showAwesomeSnackbar(
        title: 'Login gagal',
        message: 'Terjadi kesalahan saat masuk.',
        contentType: ContentType.failure,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void forgotPassword() {
    showAwesomeSnackbar(
      title: 'Lupa Password',
      message: 'Fitur pemulihan password belum tersedia.',
      contentType: ContentType.help,
    );
  }

  Future<void> loginWithGoogle() async {
    if (isLoading.value) return;

    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (account == null) return;

      isLoading.value = true;
      LaporDermayuLoading.show(message: 'Menghubungkan akun Google...');

      final response = await ApiService.dio.post(
        '/google-login',
        data: {
          'email': account.email,
          'name': account.displayName ?? account.email.split('@').first,
        },
      );

      await _box.write('token', response.data['token']);
      await _box.write('user', response.data['user']);
      await _box.write('remember_me', true);
      await _box.write('remember_email', account.email);

      LaporDermayuLoading.hide();
      Get.offAllNamed('/main');
    } on DioException catch (e) {
      LaporDermayuLoading.hide();
      showAwesomeSnackbar(
        title: 'Login Google gagal',
        message: ApiService.errorMessage(
          e,
          fallback: 'Tidak dapat masuk dengan akun Google.',
        ),
        contentType: ContentType.failure,
      );
    } catch (_) {
      LaporDermayuLoading.hide();
      showAwesomeSnackbar(
        title: 'Login Google gagal',
        message: 'Tidak dapat terhubung ke akun Google.',
        contentType: ContentType.failure,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void goToRegister() {
    Get.toNamed('/register');
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
