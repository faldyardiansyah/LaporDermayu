import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lapordermayu/core/api_service.dart';
import 'package:lapordermayu/utils/widgets/lapor_dermayu_loading.dart';
import 'package:lapordermayu/utils/widgets/show_awesome_snackbar.dart';

class ProfileController extends GetxController {
  static const String _emptyPhone = 'Belum ditambahkan';

  final _box = GetStorage();

  final name = 'Pengguna LaporDermayu'.obs;
  final email = 'pengguna@email.com'.obs;
  final phone = _emptyPhone.obs;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCachedUser();
    loadProfile();
  }

  void _loadCachedUser() {
    final cached = _box.read('user');
    if (cached is Map) {
      _applyUserMap(Map<String, dynamic>.from(cached));
    }
  }

  void _applyUserMap(Map<String, dynamic> data) {
    final newName = (data['name'] ?? '').toString().trim();
    final newEmail = (data['email'] ?? '').toString().trim();
    final rawPhone = (data['phone'] ?? _box.read('user_phone') ?? '')
        .toString()
        .trim();

    if (newName.isNotEmpty) name.value = newName;
    if (newEmail.isNotEmpty) email.value = newEmail;
    phone.value = rawPhone.isEmpty ? _emptyPhone : rawPhone;
  }

  Future<void> loadProfile() async {
    isLoading.value = true;

    try {
      final response = await ApiService.dio.get('/me');
      if (response.data is Map) {
        final userMap = Map<String, dynamic>.from(response.data as Map);
        _applyUserMap(userMap);
        await _box.write('user', userMap);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _clearSessionAndRedirect();
        return;
      }
      debugPrint('[PROFILE] Gagal memuat profil: ${e.message}');
    } catch (e) {
      debugPrint('[PROFILE] Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshProfile() async {
    await loadProfile();
  }

  void openEditProfile() {
    nameController.text = name.value;
    phoneController.text = phone.value == _emptyPhone ? '' : phone.value;

    Get.dialog(
      AlertDialog(
        title: const Text('Edit profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Nomor telepon'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          FilledButton(onPressed: saveProfile, child: const Text('Simpan')),
        ],
      ),
    );
  }

  Future<void> saveProfile() async {
    final newName = nameController.text.trim();
    final newPhone = phoneController.text.trim();

    if (newName.isEmpty) {
      showAwesomeSnackbar(
        title: 'Nama belum diisi',
        message: 'Silakan masukkan nama terlebih dahulu.',
        contentType: ContentType.warning,
      );
      return;
    }

    name.value = newName;
    phone.value = newPhone.isEmpty ? _emptyPhone : newPhone;
    await _box.write('user_phone', newPhone);

    final cached = _box.read('user');
    if (cached is Map) {
      await _box.write('user', {...cached, 'name': newName});
    }

    if (Get.isDialogOpen ?? false) Get.back();

    showAwesomeSnackbar(
      title: 'Profil diperbarui',
      message: 'Perubahan profil berhasil diterapkan.',
      contentType: ContentType.success,
    );
  }

  void openComingSoon(String feature) {
    showAwesomeSnackbar(
      title: feature,
      message: 'Fitur ini akan tersedia setelah tahap pengembangan berikutnya.',
      contentType: ContentType.help,
    );
  }

  Future<void> logout() async {
    if (Get.isDialogOpen ?? false) Get.back();
    LaporDermayuLoading.show(message: 'Keluar dari akun...');

    try {
      await ApiService.dio.post('/logout');
    } catch (_) {
    } finally {
      LaporDermayuLoading.hide();
      await _clearSessionAndRedirect();
    }
  }

  Future<void> _clearSessionAndRedirect() async {
    await _box.remove('token');
    await _box.remove('user');
    Get.offAllNamed('/login');
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}