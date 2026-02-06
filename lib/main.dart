import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/routes/app_pages.dart';
import 'app/helpers/database_init.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app/bin/app_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // تهيئة قاعدة البيانات وبدء خدمات النظام
  await DatabaseInitializer.initializeDatabase();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "Application",
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      initialBinding: AppBinding(),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        cardColor: Colors.white,
        // fontFamily: 'NotoNaskhArabic',
      ),
      locale: const Locale("ar", "SA"),
      debugShowCheckedModeBanner: false,
    );
  }
}
