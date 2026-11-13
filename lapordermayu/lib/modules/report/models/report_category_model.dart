enum ReportCategoryModel { jalanRusak, fasilitasUmum }

extension ReportCategoryModelX on ReportCategoryModel {
  String get label =>
      this == ReportCategoryModel.jalanRusak ? 'Jalan Rusak' : 'Fasilitas Umum';

  String get apiValue =>
      this == ReportCategoryModel.jalanRusak ? 'jalan_rusak' : 'fasilitas_umum';
}