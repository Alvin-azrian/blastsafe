// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// external
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 1. TAMBAH IMPORT INI

// internal
import 'data/app_provider.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. PERBAIKAN: Hapus Firebase dan ganti dengan Supabase
  // Masukkan URL dan Anon Key yang kamu dapatkan dari dashboard Supabase tadi
  await Supabase.initialize(
    // URL HARUS BERHENTI DI .co (Tanpa garis miring atau folder tambahan)
    url: 'https://coniuymxbmntkzwxdfez.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvbml1eW14Ym1udGt6d3hkZmV6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgwNDM0NjMsImV4cCI6MjA5MzYxOTQ2M30.4XDhSqlOQRzt0giVdQKA5Ic0EGyAhWLg0fXJ_VsK0m4',
  );

  // Inisialisasi locale data untuk intl (bahasa Indonesia)
  await initializeDateFormatting('id_ID', null);
  await initializeDateFormatting('en_US', null);

  // Inisialisasi layanan notifikasi lokal
  await NotificationService().initialize();

  // Pengaturan UI System
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const BlastSafeApp());
}

class BlastSafeApp extends StatelessWidget {
  const BlastSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'BlastSafe',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('id', 'ID'),
          Locale('en', 'US'),
        ],
        locale: const Locale('id', 'ID'),
        home: const SplashScreen(),
      ),
    );
  }
}
