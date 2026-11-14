import 'dart:io';
import 'dart:typed_data';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:get_storage/get_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:lapordermayu/utils/widgets/lapor_dermayu_loading.dart';
import '../../../core/api_service.dart';
import '../../../core/detection/deepseek/models/deepseek_analysis_result.dart';
import '../../../core/detection/deepseek/services/deepseek_service.dart';
import '../../../core/detection/yolo/services/detection_services.dart';
import '../../../core/detection/yolo/models/detection_result.dart';
import '../../../utils/widgets/show_awesome_snackbar.dart';
import '../../../utils/widgets/success_lottie_dialog.dart';
import '../../home/controllers/home_controller.dart';
import '../models/report_category_model.dart';
import '../models/report_submit_model.dart';

typedef FacilityAnalysis = DeepseekAnalysisResult;

class ReportFormController extends GetxController {
  static const String _loginRoute = '/login';

  // pin cuma boleh geser segini dari titik jepretan
  static const double maxOffsetMeter = 3;
  static const Distance _distance = Distance();

  final Rxn<File> selectedImage = Rxn<File>();

  final Rx<ReportCategoryModel> category = ReportCategoryModel.jalanRusak.obs;

  final RxBool isLoadingLocation = true.obs;
  final Rxn<Position> currentPosition = Rxn<Position>();
  final RxString locationError = ''.obs;
  final RxnString alamatLokasi = RxnString();
  int _geocodeToken = 0;

  // titik jepretan (tetap) dan pin yang boleh digeser
  final Rxn<LatLng> anchorPoint = Rxn<LatLng>();
  final Rxn<LatLng> pinPoint = Rxn<LatLng>();

  final DetectionService _detectionService = DetectionService();
  final RxBool isDetecting = false.obs;
  final RxList<DetectionResult> detections = <DetectionResult>[].obs;
  final Rxn<Uint8List> annotatedImageBytes = Rxn<Uint8List>();
  final RxString detectionError = ''.obs;

  final DeepSeekService _aiService = DeepSeekService();
  final RxBool isAnalyzingAi = false.obs;
  final Rxn<FacilityAnalysis> aiResult = Rxn<FacilityAnalysis>();
  final RxString aiError = ''.obs;

  final TextEditingController judulController = TextEditingController();
  final TextEditingController deskripsiController = TextEditingController();
  final RxBool isSubmitting = false.obs;

  String _lastAutoJudul = '';
  String _lastAutoDeskripsi = '';
  bool _loadingShown = false;

  bool get isProcessing => category.value == ReportCategoryModel.jalanRusak
      ? isDetecting.value
      : isAnalyzingAi.value;

  String get _kategoriApi => category.value == ReportCategoryModel.jalanRusak
      ? 'jalan_rusak'
      : 'fasilitas';

  double get pinOffsetMeter {
    final a = anchorPoint.value;
    final p = pinPoint.value;
    if (a == null || p == null) return 0;
    return _distance.distance(a, p);
  }

  @override
  void onInit() {
    super.onInit();

    final dynamic argument = Get.arguments;

    if (argument is Map) {
      final path = argument['path'];
      if (path is String) selectedImage.value = File(path);
      final cat = argument['category'];
      if (cat is ReportCategoryModel) category.value = cat;
    } else if (argument is String) {
      selectedImage.value = File(argument);
    } else if (argument is XFile) {
      selectedImage.value = File(argument.path);
    }

    getCurrentLocation();

    if (selectedImage.value != null) {
      runAnalysis();
    }
  }

  Future<void> runAnalysis() async {
    if (category.value == ReportCategoryModel.jalanRusak) {
      await runDetection();
    } else {
      await runAiAnalysis();
    }
  }

  void setCategory(ReportCategoryModel value) {
    if (category.value == value) return;
    category.value = value;

    detections.clear();
    annotatedImageBytes.value = null;
    detectionError.value = '';
    aiResult.value = null;
    aiError.value = '';
    _clearAutoText();

    if (selectedImage.value != null) runAnalysis();
  }

  Future<void> runDetection() async {
    final file = selectedImage.value;
    if (file == null || isDetecting.value) return;

    try {
      isDetecting.value = true;
      detectionError.value = '';
      detections.clear();
      annotatedImageBytes.value = null;

      await _detectionService.loadModel();

      final Uint8List bytes = await file.readAsBytes();
      final results = await _detectionService.detect(bytes);
      detections.value = results;

      if (results.isNotEmpty) {
        annotatedImageBytes.value = _detectionService.drawDetections(
          bytes,
          results,
        );
      }

      if (category.value == ReportCategoryModel.jalanRusak &&
          selectedImage.value == file) {
        _autofillFromDetections(results);
      }
    } catch (e) {
      detectionError.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isDetecting.value = false;
    }
  }

  Future<void> runAiAnalysis() async {
    final file = selectedImage.value;
    if (file == null || isAnalyzingAi.value) return;

    try {
      isAnalyzingAi.value = true;
      aiError.value = '';
      aiResult.value = null;

      final bytes = await _compressForUpload(file);
      final result = await _aiService.analyzeImage(bytes);

      if (category.value == ReportCategoryModel.fasilitasUmum &&
          selectedImage.value == file) {
        aiResult.value = result;
        _autofillFromAi(result);
      }
    } catch (e) {
      aiError.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isAnalyzingAi.value = false;
    }
  }

  Future<Uint8List> _compressForUpload(File file) async {
    try {
      final compressed = await FlutterImageCompress.compressWithFile(
        file.path,
        minWidth: 1280,
        minHeight: 1280,
        quality: 80,
        format: CompressFormat.jpeg,
      );
      if (compressed != null) return compressed;
    } catch (_) {}
    return file.readAsBytes();
  }

  void _setAutoText({required String judul, required String deskripsi}) {
    final judulBelumDiedit =
        judulController.text.trim().isEmpty ||
        judulController.text == _lastAutoJudul;
    final deskripsiBelumDiedit =
        deskripsiController.text.trim().isEmpty ||
        deskripsiController.text == _lastAutoDeskripsi;

    if (judulBelumDiedit) {
      judulController.text = judul;
      _lastAutoJudul = judul;
    }
    if (deskripsiBelumDiedit) {
      deskripsiController.text = deskripsi;
      _lastAutoDeskripsi = deskripsi;
    }
  }

  void _clearAutoText() {
    if (judulController.text == _lastAutoJudul) judulController.clear();
    if (deskripsiController.text == _lastAutoDeskripsi) {
      deskripsiController.clear();
    }
    _lastAutoJudul = '';
    _lastAutoDeskripsi = '';
  }

  void _autofillFromDetections(List<DetectionResult> results) {
    if (results.isEmpty) return;

    final Map<String, int> counts = {};
    for (final d in results) {
      counts[d.displayName] = (counts[d.displayName] ?? 0) + 1;
    }

    // tanpa persen, cukup jumlah per jenis
    final ringkas = counts.entries
        .map((e) => '${e.value} ${e.key.toLowerCase()}')
        .join(', ');

    _setAutoText(
      judul: 'Jalan rusak: $ringkas',
      deskripsi:
          'Terdeteksi ${results.length} titik kerusakan jalan ($ringkas). '
          'Mohon segera ditindaklanjuti.',
    );
  }

  void _autofillFromAi(FacilityAnalysis r) {
    if (!r.isPublicFacility) return;

    _setAutoText(
      judul: '${r.facilityType}: ${r.condition}',
      deskripsi: r.description,
    );
  }

  Future<void> getCurrentLocation() async {
    try {
      isLoadingLocation.value = true;
      locationError.value = '';

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationError.value = 'GPS belum diaktifkan.';
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        locationError.value = 'Izin lokasi belum diberikan.';
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        locationError.value =
            'Izin lokasi ditolak permanen. Aktifkan melalui pengaturan HP.';
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      currentPosition.value = pos;

      final point = LatLng(pos.latitude, pos.longitude);
      anchorPoint.value = point;
      pinPoint.value = point;

      _reverseGeocode(pos.latitude, pos.longitude);
    } catch (e) {
      locationError.value = 'Gagal mendapatkan lokasi.';
    } finally {
      isLoadingLocation.value = false;
    }
  }

  // kalau ketukan di luar 3 m, pin ditaruh di tepi lingkaran
  void movePin(LatLng target) {
    final anchor = anchorPoint.value;
    if (anchor == null) return;

    if (_distance.distance(anchor, target) <= maxOffsetMeter) {
      pinPoint.value = target;
      return;
    }

    final bearing = _distance.bearing(anchor, target);
    pinPoint.value = _distance.offset(anchor, maxOffsetMeter, bearing);
  }

  void resetPin() {
    pinPoint.value = anchorPoint.value;
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
    final token = ++_geocodeToken;
    alamatLokasi.value = null;

    try {
      // Dio terpisah biar token Bearer ga ikut ke server luar
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          headers: {
            'User-Agent':
                'LaporDermayu/1.0 (aplikasi pelaporan jalan Indramayu)',
            'Accept-Language': 'id',
          },
        ),
      );

      final res = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': lat,
          'lon': lon,
          'zoom': 18,
          'addressdetails': 1,
        },
      );

      if (token != _geocodeToken) return;

      final data = res.data;
      if (data is Map && data['display_name'] is String) {
        String alamat = (data['display_name'] as String).trim();
        if (alamat.length > 255) alamat = alamat.substring(0, 255);
        alamatLokasi.value = alamat.isEmpty ? null : alamat;
      }
    } catch (_) {
      if (token == _geocodeToken) alamatLokasi.value = null;
    }
  }

  void removeImage() {
    selectedImage.value = null;
    detections.clear();
    annotatedImageBytes.value = null;
    detectionError.value = '';
    aiResult.value = null;
    aiError.value = '';
    _clearAutoText();
  }

  void _showLoading() {
    if (_loadingShown) return;
    _loadingShown = true;
    LaporDermayuLoading.show();
  }

  void _hideLoading() {
    if (!_loadingShown) return;
    _loadingShown = false;
    LaporDermayuLoading.hide();
  }

  Future<void> submitReport() async {
    if (isSubmitting.value) return;

    final file = selectedImage.value;
    final pin = pinPoint.value;
    final judul = judulController.text.trim();
    final deskripsi = deskripsiController.text.trim();

    if (file == null) {
      _snack(
        'Foto belum ada',
        'Ambil foto terlebih dahulu.',
        ContentType.warning,
      );
      return;
    }
    if (isProcessing) {
      _snack(
        'Mohon tunggu',
        'AI sedang menganalisis foto.',
        ContentType.warning,
      );
      return;
    }
    if (pin == null) {
      _snack(
        'Lokasi belum ada',
        'Aktifkan GPS lalu muat ulang lokasi.',
        ContentType.warning,
      );
      return;
    }
    if (judul.isEmpty) {
      _snack('Judul kosong', 'Isi judul laporan.', ContentType.warning);
      return;
    }
    if (deskripsi.isEmpty) {
      _snack('Deskripsi kosong', 'Isi deskripsi laporan.', ContentType.warning);
      return;
    }

    try {
      isSubmitting.value = true;
      _showLoading();

      final minimumLoading = Future.delayed(const Duration(milliseconds: 900));
      final annotated = annotatedImageBytes.value;
      final useAnnotated =
          category.value == ReportCategoryModel.jalanRusak && annotated != null;

      Uint8List bytes;
      if (useAnnotated) {
        try {
          bytes = await FlutterImageCompress.compressWithList(
            annotated,
            minWidth: 1280,
            minHeight: 1280,
            quality: 85,
            format: CompressFormat.jpeg,
          );
        } catch (_) {
          bytes = annotated;
        }
      } else {
        bytes = await _compressForUpload(file);
      }

      final form = FormData.fromMap({
        'judul': judul,
        'deskripsi': deskripsi,
        'kategori': _kategoriApi,
        'latitude': pin.latitude.toStringAsFixed(7),
        'longitude': pin.longitude.toStringAsFixed(7),
        if (alamatLokasi.value != null) 'alamat_lokasi': alamatLokasi.value,
        'foto': MultipartFile.fromBytes(bytes, filename: 'laporan.jpg'),
      });

      final response = await ApiService.dio.post(
        '/laporan',
        data: form,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {'Accept': 'application/json'},
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      debugPrint(
        'SUBMIT OK status=${response.statusCode} body=${response.data}',
      );

      await minimumLoading;
      _hideLoading();

      final body = response.data;
      if (body is Map && body['data'] is Map) {
        ReportSubmitModel.fromJson(Map<String, dynamic>.from(body['data']));
      }

      // lottie sukses dulu, baru balik ke home
      await SuccessLottieDialog.show();

      Get.until((route) => route.isFirst);

      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().refreshHomeData();
      }
    } on DioException catch (e) {
      _hideLoading();
      _handleDioError(e);
    } catch (err, st) {
      debugPrint('SUBMIT CRASH $err\n$st');
      _hideLoading();
      _snack(
        'Gagal mengirim',
        'Terjadi kesalahan di aplikasi. Silakan coba lagi.',
        ContentType.failure,
      );
    } finally {
      _hideLoading();
      isSubmitting.value = false;
    }
  }

  void _handleDioError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    debugPrint('SUBMIT ERROR status=$status type=${e.type} body=$data');

    if (status == 401) {
      GetStorage().remove('token');
      _snack(
        'Sesi berakhir',
        'Silakan masuk kembali untuk melanjutkan.',
        ContentType.warning,
      );
      Get.offAllNamed(_loginRoute);
      return;
    }

    if (status == 422) {
      _snack(
        'Laporan belum bisa dikirim',
        _firstValidationMessage(data),
        ContentType.failure,
      );
      return;
    }

    if (status == 413) {
      _snack(
        'Foto terlalu besar',
        'Ukuran foto melebihi batas server. Coba ambil ulang fotonya.',
        ContentType.failure,
      );
      return;
    }

    if (status != null && status >= 500) {
      _snack(
        'Server sedang bermasalah',
        'Laporan belum tersimpan. Coba lagi beberapa saat lagi.',
        ContentType.failure,
      );
      return;
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        _snack(
          'Koneksi terlalu lambat',
          'Pengiriman memakan waktu terlalu lama. Coba lagi.',
          ContentType.failure,
        );
        return;
      case DioExceptionType.connectionError:
        _snack(
          'Tidak ada koneksi',
          'Periksa internet kamu atau pastikan server menyala.',
          ContentType.failure,
        );
        return;
      default:
        break;
    }

    _snack(
      'Gagal mengirim',
      'Laporan belum terkirim. Silakan coba lagi.',
      ContentType.failure,
    );
  }

  String _firstValidationMessage(dynamic data) {
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        if (first is String) return first;
      }
      if (data['message'] is String) return data['message'] as String;
    }
    return 'Data laporan tidak valid.';
  }

  void _snack(String title, String message, ContentType type) {
    showAwesomeSnackbar(title: title, message: message, contentType: type);
  }

  @override
  void onClose() {
    judulController.dispose();
    deskripsiController.dispose();
    _detectionService.dispose();
    super.onClose();
  }
}
