import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:get_storage/get_storage.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/mapbox_config.dart';
import '../../../utils/widgets/mega_mendung.dart';
import '../controllers/report_detail_controller.dart';
import '../models/report_detail_model.dart';

class _Step {
  final String title;
  final String note;
  const _Step(this.title, this.note);
}

class ReportDetailView extends StatelessWidget {
  final ReportDetailModel preview;
  final ReportDetailController controller;

  ReportDetailView({super.key, required this.preview})
    : controller = Get.put(
        ReportDetailController(preview),
        tag: 'detail_${identityHashCode(preview)}',
      );

  // satu pintu buat buka detail dari home, riwayat, dan peta
  static void open(ReportDetailModel preview) {
    Get.to(
      () => ReportDetailView(preview: preview),
      transition: Transition.rightToLeft,
    );
  }

  TextStyle get jakarta => GoogleFonts.plusJakartaSans();

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.slate100,
        body: RefreshIndicator(
          onRefresh: controller.load,
          color: AppColors.homeBlue,
          backgroundColor: Colors.white,
          edgeOffset: topInset + 60,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            padding: EdgeInsets.only(bottom: bottomInset + 28),
            child: Column(
              children: [
                _buildHeader(topInset),
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Obx(() {
                      final r = controller.report.value;
                      final err = controller.error.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            [
                                  _buildPhoto(r),
                                  if (err.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    _buildErrorCard(err),
                                  ],
                                  const SizedBox(height: 14),
                                  _buildInfoCard(r),
                                  const SizedBox(height: 14),
                                  _buildDescription(r),
                                  if (_hasReply(r)) ...[
                                    const SizedBox(height: 14),
                                    _buildAdminReply(r),
                                  ],
                                  const SizedBox(height: 14),
                                  _buildProgress(r),
                                  const SizedBox(height: 14),
                                  _buildLocation(r),
                                ]
                                .animate(interval: 70.ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(
                                  begin: 0.06,
                                  end: 0,
                                  curve: Curves.easeOutCubic,
                                ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double topInset) {
    return Container(
      height: topInset + 165,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.homeBlue, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          // Ornamen Mega Mendung kanan atas
          Positioned(
            top: topInset - 42,
            right: -105,
            child: MegaMendung(
              width: 310,
              color: Colors.white.withValues(alpha: 0.17),
            ),
          ),

          // Ornamen Mega Mendung kiri bawah
          Positioned(
            left: -145,
            bottom: -75,
            child: MegaMendung(
              width: 290,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),

          // Ornamen tambahan
          Positioned(
            right: 15,
            bottom: -105,
            child: MegaMendung(
              width: 185,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(20, topInset + 18, 20, 0),
            child: Row(
              children: [
                Material(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(15),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => Get.back(),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detail Laporan',
                        style: jakarta.copyWith(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        preview.id != null
                            ? 'Informasi laporan #${preview.id}'
                            : 'Informasi lengkap laporan',
                        style: jakarta.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.assignment_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto(ReportDetailModel r) {
    final url = r.foto;

    return Container(
      height: 225,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: url == null
          ? _photoPlaceholder()
          : Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: () => _openPhoto(url),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.homeBlue,
                          strokeWidth: 2.5,
                        ),
                      );
                    },
                    errorBuilder: (_, _, _) => _photoPlaceholder(),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.photo_camera_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Foto Bukti Laporan',
                          style: jakarta.copyWith(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.zoom_in_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Perbesar foto',
                          style: jakarta.copyWith(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _photoPlaceholder() {
    return Stack(
      children: [
        Positioned(
          right: -24,
          bottom: -16,
          child: MegaMendung(
            width: 220,
            color: AppColors.homeBlue.withValues(alpha: 0.14),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.photo_camera_outlined,
                size: 34,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 8),
              Text(
                'Foto tidak tersedia',
                style: jakarta.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.dangerRed.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dangerRed.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.dangerRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: jakarta.copyWith(
                color: AppColors.dangerRed,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: controller.load,
            child: Text(
              'Coba Lagi',
              style: jakarta.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ReportDetailModel r) {
    final status = ReportStatusInfo.from(r.status);
    final kind = ReportKindInfo.from(r.kategori);
    final waktu = r.waktu ?? r.tanggal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kind.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(kind.icon, size: 14, color: kind.color),
                    const SizedBox(width: 5),
                    Text(
                      kind.label,
                      style: jakarta.copyWith(
                        color: kind.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: status.tint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.icon, size: 13, color: status.color),
                    const SizedBox(width: 4),
                    Text(
                      status.label,
                      style: jakarta.copyWith(
                        color: status.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            r.judul ?? 'Laporan',
            style: jakarta.copyWith(
              color: AppColors.slate900,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.slate100),
          if (waktu != null) _metaRow(Icons.schedule_rounded, waktu),
          if (r.alamat != null) _metaRow(Icons.location_on_outlined, r.alamat!),
          if (r.isOwner)
            _metaRow(Icons.person_outline_rounded, 'Laporan milik Anda'),
        ],
      ),
    );
  }

  Map<String, String> get _authHeaders {
    final token = GetStorage().read('token');
    return {if (token != null) 'Authorization': 'Bearer $token'};
  }

  bool _hasReply(ReportDetailModel r) {
    final key = ReportStatusInfo.from(r.status).key;
    return key == 'selesai' || key == 'ditolak';
  }

  Widget _buildAdminReply(ReportDetailModel r) {
    final done = ReportStatusInfo.from(r.status).key == 'selesai';
    final color = done ? AppColors.emerald600 : AppColors.dangerRed;

    final note = done
        ? (r.catatanPenyelesaian ??
              'Laporan telah ditangani oleh pihak terkait.')
        : (r.catatanPenolakan ?? 'Laporan belum memenuhi syarat verifikasi.');
    final photo = done ? r.fotoPenyelesaian : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration().copyWith(
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  done ? Icons.verified_rounded : Icons.cancel_rounded,
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      done ? 'Balasan Petugas' : 'Alasan Penolakan',
                      style: jakarta.copyWith(
                        color: AppColors.slate900,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (done && r.waktuPenyelesaian != null)
                      Text(
                        'Selesai ${r.waktuPenyelesaian}',
                        style: jakarta.copyWith(
                          color: AppColors.slate500,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            note,
            style: jakarta.copyWith(
              color: AppColors.slate700,
              fontSize: 12.5,
              height: 1.6,
            ),
          ),
          if (photo != null) ...[
            const SizedBox(height: 14),
            Text(
              'Bukti penyelesaian',
              style: jakarta.copyWith(
                color: AppColors.slate500,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _openPhoto(photo, headers: _authHeaders),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Image.network(
                    photo,
                    headers: _authHeaders,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.slate100,
                      alignment: Alignment.center,
                      child: Text(
                        'Bukti tidak dapat dimuat',
                        style: jakarta.copyWith(
                          color: AppColors.slate500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.slate400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: jakarta.copyWith(
                color: AppColors.slate600,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(ReportDetailModel r) {
    final loading = controller.isLoading.value && r.deskripsi == null;
    final text =
        r.deskripsi ??
        (loading
            ? 'Deskripsi laporan sedang dimuat dari server, mohon tunggu sebentar ya.'
            : 'Belum ada deskripsi untuk laporan ini.');

    return _section(
      title: 'Deskripsi',
      child: Skeletonizer(
        enabled: loading,
        child: Text(
          text,
          style: jakarta.copyWith(
            color: r.deskripsi == null && !loading
                ? AppColors.slate400
                : AppColors.slate700,
            fontSize: 12.5,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(ReportDetailModel r) {
    final status = ReportStatusInfo.from(r.status);
    final rejected = status.key == 'ditolak';
    final allDone = status.key == 'selesai';
    final firstNote = r.waktu ?? r.tanggal ?? 'Diterima sistem LaporDermayu';

    final steps = rejected
        ? [
            _Step('Laporan dikirim', firstNote),
            const _Step(
              'Ditolak',
              'Laporan belum memenuhi syarat verifikasi petugas',
            ),
          ]
        : [
            _Step('Laporan dikirim', firstNote),
            const _Step(
              'Diverifikasi petugas',
              'Petugas memeriksa foto dan lokasi',
            ),
            const _Step(
              'Sedang ditangani',
              'Perbaikan dijadwalkan dan dikerjakan',
            ),
            const _Step('Selesai', 'Laporan sudah ditindaklanjuti'),
          ];

    final current = rejected ? 1 : status.step;

    return _section(
      title: 'Progres Laporan',
      child: Column(
        children: List.generate(steps.length, (i) {
          final isLast = i == steps.length - 1;
          final isRejectedStep = rejected && i == 1;
          final done = !isRejectedStep && (allDone || i < current);
          final isCurrent = !allDone && i == current;

          return _stepItem(
            step: steps[i],
            isLast: isLast,
            done: done,
            current: isCurrent,
            rejected: isRejectedStep,
            color: status.color,
            lineDone: allDone || i < current,
          );
        }),
      ),
    );
  }

  Widget _stepItem({
    required _Step step,
    required bool isLast,
    required bool done,
    required bool current,
    required bool rejected,
    required Color color,
    required bool lineDone,
  }) {
    Widget dot;
    if (rejected) {
      dot = Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.dangerRed,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
      );
    } else if (done) {
      dot = Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.emerald500,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 15, color: Colors.white),
      );
    } else if (current) {
      dot = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      );
    } else {
      dot = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.slate100,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.slate200, width: 2),
        ),
      );
    }

    final pending = !done && !current && !rejected;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              dot,
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: lineDone ? AppColors.emerald500 : AppColors.slate200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: jakarta.copyWith(
                      color: pending ? AppColors.slate400 : AppColors.slate900,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.note,
                    style: jakarta.copyWith(
                      color: pending ? AppColors.slate400 : AppColors.slate500,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocation(ReportDetailModel r) {
    final point = r.point;
    final kind = ReportKindInfo.from(r.kategori);

    return _section(
      title: 'Lokasi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 170,
              child: point == null
                  ? Container(
                      color: AppColors.slate100,
                      alignment: Alignment.center,
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.homeBlue,
                              ),
                            )
                          : Text(
                              'Titik lokasi belum tersedia',
                              style: jakarta.copyWith(
                                color: AppColors.slate500,
                                fontSize: 12,
                              ),
                            ),
                    )
                  : FlutterMap(
                      key: ValueKey('${point.latitude},${point.longitude}'),
                      options: MapOptions(
                        initialCenter: point,
                        initialZoom: 17,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: MapboxConfig.tileUrl(false),
                          tileSize: 512,
                          zoomOffset: -1,
                          userAgentPackageName: 'com.lapordermayu.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: point,
                              width: 42,
                              height: 48,
                              alignment: Alignment.topCenter,
                              child: Icon(
                                Icons.location_on_rounded,
                                size: 42,
                                color: kind.color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.alamat ?? 'Alamat belum tersedia',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: jakarta.copyWith(
                        color: r.alamat != null
                            ? AppColors.slate800
                            : AppColors.slate400,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    if (point != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.slate500,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (point != null)
                GestureDetector(
                  onTap: controller.copyCoordinates,
                  child: Container(
                    width: 38,
                    height: 38,
                    margin: const EdgeInsets.only(left: 10),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.copy_rounded,
                      size: 17,
                      color: AppColors.homeBlue,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: jakarta.copyWith(
              color: AppColors.slate900,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: AppColors.slate200.withValues(alpha: 0.75)),
      boxShadow: [
        BoxShadow(
          color: AppColors.slate900.withValues(alpha: 0.035),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  void _openPhoto(String url, {Map<String, String>? headers}) {
    Get.to(
      () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Foto Laporan',
            style: jakarta.copyWith(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: PhotoView(
          imageProvider: NetworkImage(url, headers: headers),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3.5,
          loadingBuilder: (context, event) => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ),
      transition: Transition.fadeIn,
    );
  }
}
