import 'package:ble_scanner/core/theme/app_theme.dart';
import 'package:ble_scanner/features/ble_scan/presentation/pages/ble_scan_page.dart';
import 'package:ble_scanner/features/device_registry/presentation/pages/registered_devices_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [BleScanPage(), RegisteredDevicesPage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.softBlue,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bluetooth_searching_rounded),
            selectedIcon: Icon(
              Icons.bluetooth_searching_rounded,
              color: AppColors.primary,
            ),
            label: '기기 검색',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_other_outlined),
            selectedIcon: Icon(
              Icons.devices_other_rounded,
              color: AppColors.primary,
            ),
            label: '등록 목록',
          ),
        ],
      ),
    );
  }
}
