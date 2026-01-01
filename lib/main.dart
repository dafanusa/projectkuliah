import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';

void main() {
  runApp(const ProjectKuliahApp());
}

class ProjectKuliahApp extends StatelessWidget {
  const ProjectKuliahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Manajemen Kegiatan Kuliah',
      theme: AppTheme.light,
      initialRoute: Routes.main,
      getPages: AppPages.routes,
    );
  }
}
