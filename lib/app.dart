import 'package:ble_scanner/core/theme/app_theme.dart';
import 'package:ble_scanner/home_page.dart';
import 'package:flutter/material.dart';

class BleScannerApp extends StatelessWidget {
  const BleScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '우리기술 BLE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomePage(),
    );
  }
}
