import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../utils/app_colors.dart';

class ReportStatusInfo {
  final String key;
  final String label;
  final Color color;
  final IconData icon;
  final int step;

  const ReportStatusInfo(
    this.key,
    this.label,
    this.color,
    this.icon,
    this.step,
  );

  Color get tint => color.withValues(alpha: 0.12);

  static final _menunggu = ReportStatusInfo(
    'menunggu',
    'Menunggu',
    AppColors.amber500,
    Icons.schedule_rounded,
    0,
  );
  static final _terverifikasi = ReportStatusInfo(
    'terverifikasi',
    'Terverifikasi',
    AppColors.homeBlue,
    Icons.verified_rounded,
    1,
  );
  static final _diproses = ReportStatusInfo(
    'diproses',
    'Diproses',
    AppColors.teal,
    Icons.build_circle_rounded,
    2,
  );
  static final _selesai = ReportStatusInfo(
    'selesai',
    'Selesai',
    AppColors.emerald600,
    Icons.check_circle_rounded,
    3,
  );
  static final _ditolak = ReportStatusInfo(
    'ditolak',
    'Ditolak',
    AppColors.dangerRed,
    Icons.cancel_rounded,
    1,
  );

  // dibikin longgar biar label home ("Menunggu Validasi") dan enum riwayat tetap kebaca
  static ReportStatusInfo from(String? raw) {
    final s = (raw ?? '').toLowerCase();
    if (s.contains('tolak')) return _ditolak;
    if (s.contains('tunggu')) return _menunggu;
    if (s.contains('selesai') || s.contains('perbaiki')) return _selesai;
    if (s.contains('proses')) return _diproses;
    if (s.contains('verifikasi') || s.contains('valid')) return _terverifikasi;
    return _menunggu;
  }
}

class ReportKindInfo {
  final String label;
  final IconData icon;
  final Color color;

  const ReportKindInfo(this.label, this.icon, this.color);

  static final _jalan = ReportKindInfo(
    'Jalan Rusak',
    Icons.add_road_rounded,
    AppColors.dangerRed,
  );
  static final _fasilitas = ReportKindInfo(
    'Fasilitas Umum',
    Icons.lightbulb_outline_rounded,
    AppColors.amber500,
  );

  static ReportKindInfo from(String? raw) {
    final s = (raw ?? '').toLowerCase();
    if (s.contains('fasil') || s.contains('lampu') || s.contains('light')) {
      return _fasilitas;
    }
    return _jalan;
  }
}

String? _pick(Map m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v != null && '$v'.trim().isNotEmpty) return '$v'.trim();
  }
  return null;
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse('$v');
}

class ReportDetailModel {
  final int? id;
  final String? judul;
  final String? deskripsi;
  final String? kategori;
  final String? status;
  final String? foto;
  final String? alamat;
  final String? tanggal;
  final String? waktu;
  final double? latitude;
  final double? longitude;
  final String? fotoPenyelesaian;
  final String? catatanPenyelesaian;
  final String? catatanPenolakan;
  final String? waktuPenyelesaian;
  final bool isOwner;

  const ReportDetailModel({
    this.id,
    this.judul,
    this.deskripsi,
    this.kategori,
    this.status,
    this.foto,
    this.alamat,
    this.tanggal,
    this.waktu,
    this.fotoPenyelesaian,
    this.catatanPenyelesaian,
    this.catatanPenolakan,
    this.waktuPenyelesaian,
    this.latitude,
    this.longitude,
    this.isOwner = false,
  });

  LatLng? get point => (latitude != null && longitude != null)
      ? LatLng(latitude!, longitude!)
      : null;

  // bisa dipakai buat map dari home, peta, atau response detail
  factory ReportDetailModel.fromMap(Map m) {
    final rawId = m['id'];
    return ReportDetailModel(
      id: rawId == null ? null : int.tryParse('$rawId'),
      judul: _pick(m, ['judul', 'title']),
      deskripsi: _pick(m, ['deskripsi', 'description']),
      kategori: _pick(m, ['kategori', 'category']),
      status: _pick(m, ['status']),
      foto: _pick(m, ['foto', 'image']),
      alamat: _pick(m, ['alamat', 'alamat_lokasi', 'location']),
      tanggal: _pick(m, ['tanggal']),
      waktu: _pick(m, ['waktu']),
      fotoPenyelesaian: _pick(m, ['foto_penyelesaian']),
      catatanPenyelesaian: _pick(m, ['catatan_penyelesaian']),
      catatanPenolakan: _pick(m, ['catatan_penolakan']),
      waktuPenyelesaian: _pick(m, ['waktu_penyelesaian']),
      latitude: _toDouble(m['latitude'] ?? m['lat']),
      longitude: _toDouble(m['longitude'] ?? m['lng'] ?? m['lon']),
      isOwner: m['is_owner'] == true,
    );
  }

  // data baru dari server menang, yang kosong diisi data awal
  ReportDetailModel mergedWith(ReportDetailModel f) {
    return ReportDetailModel(
      id: f.id ?? id,
      judul: f.judul ?? judul,
      deskripsi: f.deskripsi ?? deskripsi,
      kategori: f.kategori ?? kategori,
      status: f.status ?? status,
      foto: f.foto ?? foto,
      alamat: f.alamat ?? alamat,
      tanggal: f.tanggal ?? tanggal,
      waktu: f.waktu ?? waktu,
      fotoPenyelesaian: f.fotoPenyelesaian ?? fotoPenyelesaian,
      catatanPenyelesaian: f.catatanPenyelesaian ?? catatanPenyelesaian,
      catatanPenolakan: f.catatanPenolakan ?? catatanPenolakan,
      waktuPenyelesaian: f.waktuPenyelesaian ?? waktuPenyelesaian,
      latitude: f.latitude ?? latitude,
      longitude: f.longitude ?? longitude,
      isOwner: f.isOwner || isOwner,
    );
  }
}
