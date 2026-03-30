import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
        path: 'assets/translations/strings.csv',
        assetLoader: CsvAssetLoader(),
        fallbackLocale: const Locale('zh', 'TW'),
        startLocale: const Locale('zh', 'TW'),
        child: const App(),
      ),
    ),
  );
}
