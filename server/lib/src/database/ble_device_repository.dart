import '../models/ble_device_record.dart';

abstract interface class BleDeviceRepository {
  Future<BleDevicePage> fetchPage({required int page, required int pageSize});
  Future<BleDeviceRecord> insert({
    required String blueNo,
    required String macAddress,
  });
  Future<void> checkConnection();
}

class BleDevicePage {
  const BleDevicePage({required this.devices, required this.totalCount});

  final List<BleDeviceRecord> devices;
  final int totalCount;
}

class DuplicateBleDeviceException implements Exception {
  const DuplicateBleDeviceException();
}

class BleDatabaseException implements Exception {
  const BleDatabaseException(this.message);

  final String message;

  @override
  String toString() => message;
}
