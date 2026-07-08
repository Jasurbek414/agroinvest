import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file before app starts
  await dotenv.load(fileName: '.env');

  // Skeleton for now (PLATFORM_ROADMAP.md Phase 0.5) - only uz.json exists,
  // so this is the mechanism, not full translation coverage (Phase 3 adds
  // ru/en and migrates the rest of the app's hardcoded strings onto keys).
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('uz')],
      path: 'assets/translations',
      fallbackLocale: const Locale('uz'),
      startLocale: const Locale('uz'),
      child: const AgroInvestApp(),
    ),
  );
}
