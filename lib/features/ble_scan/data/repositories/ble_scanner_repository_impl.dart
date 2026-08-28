import 'package:ble_scanner/features/ble_scan/data/datasources/ble_scanner_data_source.dart';
import 'package:ble_scanner/features/ble_scan/domain/entities/ble_device.dart';
import 'package:ble_scanner/features/ble_scan/domain/repositories/ble_scanner_repository.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleScannerRepositoryImpl implements BleScannerRepository {
  BleScannerRepositoryImpl(this._dataSource);

  static const targetName = 'ED-BT5';
  final BleScannerDataSource _dataSource;

  @override
  Stream<List<BleDevice>> watchTargetDevices() {
    return _dataSource.watchScanResults().map((results) {
      final devicesByAddress = <String, BleDevice>{};

      for (final result in results) {
        final advertisedName = result.advertisementData.advName.trim();
        final platformName = result.device.platformName.trim();
        final name = advertisedName.isNotEmpty ? advertisedName : platformName;

        if (!name.toUpperCase().contains(targetName)) continue;

        final address = result.device.remoteId.str;
        devicesByAddress[address] = BleDevice(
          name: name.isEmpty ? targetName : name,
          address: address,
          rssi: result.rssi,
        );
      }

      final devices = devicesByAddress.values.toList()
        ..sort((a, b) => b.rssi.compareTo(a.rssi));
      return devices;
    });
  }

  @override
  Stream<BluetoothAvailability> watchAdapterState() {
    return _dataSource.watchAdapterState().map(_mapAdapterState);
  }

  @override
  Stream<bool> watchScanStatus() => _dataSource.watchScanStatus();

  @override
  Future<void> ensureBluetoothOn() => _dataSource.ensureBluetoothOn();

  @override
  Future<void> startTargetScan() => _dataSource.startScan();

  @override
  Future<void> stopScan() => _dataSource.stopScan();

  BluetoothAvailability _mapAdapterState(BluetoothAdapterState state) {
    return switch (state) {
      BluetoothAdapterState.on => BluetoothAvailability.on,
      BluetoothAdapterState.off ||
      BluetoothAdapterState.turningOff ||
      BluetoothAdapterState.turningOn => BluetoothAvailability.off,
      BluetoothAdapterState.unavailable => BluetoothAvailability.unavailable,
      BluetoothAdapterState.unauthorized => BluetoothAvailability.unauthorized,
      BluetoothAdapterState.unknown => BluetoothAvailability.unknown,
    };
  }
}
