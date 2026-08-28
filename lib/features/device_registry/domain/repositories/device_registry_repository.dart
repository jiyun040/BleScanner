import 'package:ble_scanner/features/device_registry/domain/entities/registered_device_page.dart';

abstract interface class DeviceRegistryRepository {
  Future<RegisteredDevicePage> fetchDevices({
    required int page,
    int pageSize = 20,
  });
  Future<void> registerDevice({
    required String blueNo,
    required String macAddress,
  });
}

class DeviceRegistryException implements Exception {
  const DeviceRegistryException(this.message);

  final String message;

  @override
  String toString() => message;
}
