import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/services/auth_service.dart';
import 'app/services/data_service.dart';
import 'app/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gfpkegpnozcoaxljnuch.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdmcGtlZ3Bub3pjb2F4bGpudWNoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcyNzAyNTgsImV4cCI6MjA4Mjg0NjI1OH0.jYoQar-zpfuhPsl_ln6KT_IOC57mBk5QCBnDmJTrOmw',
  );

  Get.put<AuthService>(AuthService(), permanent: true);
  Get.put<DataService>(DataService(), permanent: true);

  runApp(const ProjectKuliahApp());
}

class ProjectKuliahApp extends StatelessWidget {
  const ProjectKuliahApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final initialRoute = Routes.splash;

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PortalNusaAkademi',
      theme: AppTheme.light,
      initialRoute: initialRoute,
      getPages: AppPages.routes,
    );
  }
}
