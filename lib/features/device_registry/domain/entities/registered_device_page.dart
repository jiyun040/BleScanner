import 'package:ble_scanner/features/device_registry/domain/entities/registered_ble_device.dart';

class RegisteredDevicePage {
  const RegisteredDevicePage({
    required this.devices,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  final List<RegisteredBleDevice> devices;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  factory RegisteredDevicePage.fromJson(Map<String, Object?> json) {
    final data = json['data'];
    final pagination = json['pagination'];
    if (data is! List || pagination is! Map) {
      throw const FormatException('Invalid paginated response');
    }

    final pageValues = Map<String, Object?>.from(pagination);
    return RegisteredDevicePage(
      devices: data
          .map(
            (item) => RegisteredBleDevice.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList(growable: false),
      page: _readInt(pageValues, 'page'),
      pageSize: _readInt(pageValues, 'size'),
      totalCount: _readInt(pageValues, 'totalCount'),
      totalPages: _readInt(pageValues, 'totalPages'),
    );
  }

  static int _readInt(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is int) return value;
    return int.parse(value.toString());
  }
}
