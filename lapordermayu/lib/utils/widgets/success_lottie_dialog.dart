import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../app_colors.dart';

class SuccessLottieDialog extends StatefulWidget {
  final String message;

  const SuccessLottieDialog({
    super.key,
    this.message = 'Laporan berhasil dikirim',
  });

  // nunggu sampai dialog nutup sendiri
  static Future<void> show({String? message}) async {
    await Get.dialog(
      SuccessLottieDialog(message: message ?? 'Laporan berhasil dikirim'),
      barrierDismissible: false,
      barrierColor: Colors.black54,
    );
  }

  @override
  State<SuccessLottieDialog> createState() => _SuccessLottieDialogState();
}

class _SuccessLottieDialogState extends State<SuccessLottieDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  Timer? _safetyTimer;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this);

    // jaga-jaga kalau file lottie gagal dimuat, dialog tetap nutup
    _safetyTimer = Timer(const Duration(seconds: 4), _close);
  }

  void _close() {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 260,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Lottie.asset(
                    'assets/lotties/success.json',
                    controller: _anim,
                    repeat: false,
                    onLoaded: (composition) {
                      _anim.duration = composition.duration;
                      _anim.forward().whenComplete(() {
                        Future.delayed(
                          const Duration(milliseconds: 500),
                          _close,
                        );
                      });
                    },
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.check_circle_rounded,
                      size: 90,
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Menunggu verifikasi petugas',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}