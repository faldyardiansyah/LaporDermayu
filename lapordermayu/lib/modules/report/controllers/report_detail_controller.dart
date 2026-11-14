import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:dio/dio.dart';
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
        options: Options(headers: {'Accept': 'application/json'}),
      );

      final body = res.data;
      if (body is Map && body['data'] is Map) {
        report.value = report.value.mergedWith(
          ReportDetailModel.fromMap(body['data'] as Map),
        );
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;

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
    } catch (_) {
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
