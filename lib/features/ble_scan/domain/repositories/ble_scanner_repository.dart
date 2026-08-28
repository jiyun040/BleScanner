import 'package:ble_scanner/features/ble_scan/domain/entities/ble_device.dart';

enum BluetoothAvailability { unknown, on, off, unavailable, unauthorized }

abstract interface class BleScannerRepository {
  Stream<List<BleDevice>> watchTargetDevices();
  Stream<BluetoothAvailability> watchAdapterState();
  Stream<bool> watchScanStatus();
  Future<void> ensureBluetoothOn();
  Future<void> startTargetScan();
  Future<void> stopScan();
}
