import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:get_storage/get_storage.dart';

import '../../../core/api_service.dart';
import '../../../utils/widgets/show_awesome_snackbar.dart';
import '../models/report_detail_model.dart';

class ReportDetailController extends GetxController {
  final ReportDetailModel preview;
  final Rx<ReportDetailModel> report;

  ReportDetailController(this.preview) : report = preview.obs;

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final id = preview.id;
    if (id == null || isLoading.value) return;

    try {
      isLoading.value = true;
      error.value = '';

      final res = await ApiService.dio.get(
        '/laporan/$id',
        options: Options(
          headers: {'Accept': 'application/json'},
        ),
      );

      final body = res.data;

      // DEBUG: melihat respons dari Laravel
      debugPrint('========== DETAIL LAPORAN ==========');
      debugPrint('STATUS: ${res.statusCode}');
      debugPrint('BODY: $body');

      if (body is Map && body['data'] is Map) {
        final detail = ReportDetailModel.fromMap(
          body['data'] as Map,
        );

        // DEBUG: melihat hasil pembacaan model Flutter
        debugPrint('ID: ${detail.id}');
        debugPrint('JUDUL: ${detail.judul}');
        debugPrint('DESKRIPSI: ${detail.deskripsi}');
        debugPrint('ALAMAT: ${detail.alamat}');
        debugPrint('LATITUDE: ${detail.latitude}');
        debugPrint('LONGITUDE: ${detail.longitude}');
        debugPrint('FOTO: ${detail.foto}');
        debugPrint('====================================');

        report.value = report.value.mergedWith(detail);
      } else {
        debugPrint('FORMAT RESPONSE DETAIL TIDAK SESUAI');
        error.value = 'Format data detail laporan tidak sesuai.';
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;

      debugPrint('DETAIL API ERROR: ${e.response?.data}');
      debugPrint('DETAIL API STATUS: $status');

      if (status == 401) {
        GetStorage().remove('token');
        Get.offAllNamed('/login');
        return;
      }

      if (status == 404) {
        error.value = 'Laporan tidak ditemukan atau belum bisa dilihat.';
      } else if (status != null && status >= 500) {
        error.value = 'Server sedang bermasalah. Coba lagi sebentar.';
      } else {
        error.value =
            'Tidak bisa terhubung ke server. Tarik ke bawah untuk coba lagi.';
      }
    } catch (e) {
      debugPrint('DETAIL ERROR: $e');
      error.value = 'Gagal memuat detail laporan.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> copyCoordinates() async {
    final p = report.value.point;
    if (p == null) return;

    await Clipboard.setData(
      ClipboardData(text: '${p.latitude}, ${p.longitude}'),
    );

    showAwesomeSnackbar(
      title: 'Tersalin',
      message: 'Koordinat sudah disalin.',
      contentType: ContentType.success,
    );
  }
}