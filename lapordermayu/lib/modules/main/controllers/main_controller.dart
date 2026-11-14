import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:lapordermayu/routes/app_routes.dart';
import 'package:lapordermayu/modules/report/models/report_category_model.dart';

class MainController extends GetxController {
  final currentIndex = 0.obs;

  void changeTab(int index) {
    currentIndex.value = index;
  }

  void openReport() {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Jenis Laporan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.report_problem_rounded,
                  color: Colors.red,
                ),
                title: const Text('Jalan Rusak'),
                subtitle: const Text('Laporkan kerusakan jalan'),
                onTap: () {
                  Get.back();
                  Get.toNamed(
                    AppRoutes.reportCamera,
                    arguments: {
                      'category': ReportCategoryModel.jalanRusak,
                      'reportType': 'jalan_rusak',
                      'title': 'Laporan Jalan Rusak',
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Colors.orange,
                ),
                title: const Text('Fasilitas Umum'),
                subtitle: const Text('Laporkan fasilitas umum bermasalah'),
                onTap: () {
                  Get.back();
                  Get.toNamed(
                    AppRoutes.reportCamera,
                    arguments: {
                      'category': ReportCategoryModel.fasilitasUmum,
                      'reportType': 'fasilitas',
                      'title': 'Laporan Fasilitas Umum',
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
