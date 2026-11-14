class HomeStats {
  final int total;
  final int terverifikasi;
  final int diperbaiki;
  final int menunggu;

  const HomeStats({
    this.total = 0,
    this.terverifikasi = 0,
    this.diperbaiki = 0,
    this.menunggu = 0,
  });

  factory HomeStats.fromJson(Map<String, dynamic> json) {
    return HomeStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      terverifikasi: (json['terverifikasi'] as num?)?.toInt() ?? 0,
      diperbaiki: (json['diperbaiki'] as num?)?.toInt() ?? 0,
      menunggu: (json['menunggu'] as num?)?.toInt() ?? 0,
    );
  }
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

class HomeReport {
  final int id;
  final String judul;
  final String? deskripsi;
  final String? alamat;
  final String kategori;
  final String status;
  final String? foto;
  final String? tanggal;
  final double? jarakKm;
  final double? latitude;
  final double? longitude;

  const HomeReport({
    required this.id,
    required this.judul,
    required this.kategori,
    required this.status,
    this.deskripsi,
    this.alamat,
    this.foto,
    this.tanggal,
    this.jarakKm,
    this.latitude,
    this.longitude,
  });

  bool get isJalanRusak => kategori == 'jalan_rusak';

  factory HomeReport.fromJson(Map<String, dynamic> json) {
    return HomeReport(
      id: (json['id'] as num?)?.toInt() ?? 0,
      judul: json['judul']?.toString() ?? '',
      deskripsi:
          json['deskripsi']?.toString() ?? json['description']?.toString(),
      alamat: json['alamat']?.toString() ?? json['alamat_lokasi']?.toString(),
      kategori: json['kategori']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      foto: json['foto']?.toString(),
      tanggal: json['tanggal']?.toString(),
      jarakKm: _parseDouble(json['jarak_km']),
      latitude: _parseDouble(json['latitude'] ?? json['lat']),
      longitude: _parseDouble(json['longitude'] ?? json['lng'] ?? json['lon']),
    );
  }
}

class HomeResponse {
  final HomeStats stats;
  final List<HomeReport> recentReports;
  final List<HomeReport> nearby;

  const HomeResponse({
    required this.stats,
    required this.recentReports,
    required this.nearby,
  });

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    return HomeResponse(
      stats: HomeStats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
      recentReports: (json['recent_reports'] as List? ?? [])
          .map((e) => HomeReport.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      nearby: (json['nearby'] as List? ?? [])
          .map((e) => HomeReport.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
