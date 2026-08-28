import 'package:ble_scanner/features/device_registry/data/datasources/device_registry_data_source.dart';
import 'package:ble_scanner/features/device_registry/domain/entities/registered_device_page.dart';
import 'package:ble_scanner/features/device_registry/domain/repositories/device_registry_repository.dart';

class DeviceRegistryRepositoryImpl implements DeviceRegistryRepository {
  const DeviceRegistryRepositoryImpl(this._dataSource);

  final DeviceRegistryDataSource _dataSource;

  @override
  Future<RegisteredDevicePage> fetchDevices({
    required int page,
    int pageSize = 20,
  }) => _dataSource.fetchDevices(page: page, pageSize: pageSize);

  @override
  Future<void> registerDevice({
    required String blueNo,
    required String macAddress,
  }) async {
    final normalizedBlueNo = blueNo.trim();
    if (normalizedBlueNo.isEmpty) {
      throw const DeviceRegistryException('블루투스 번호를 입력해 주세요.');
    }

    try {
      await _dataSource.insertDevice(
        blueNo: normalizedBlueNo,
        macAddress: macAddress.trim().toUpperCase(),
      );
    } on DeviceRegistryDataException catch (error) {
      throw DeviceRegistryException(error.message);
    }
  }
}
