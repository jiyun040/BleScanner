import 'package:ble_scanner/features/device_registry/data/datasources/device_registry_data_source.dart';
import 'package:ble_scanner/features/device_registry/data/repositories/device_registry_repository_impl.dart';
import 'package:ble_scanner/features/device_registry/domain/entities/registered_device_page.dart';
import 'package:ble_scanner/features/device_registry/domain/repositories/device_registry_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final deviceRegistryHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final deviceRegistryDataSourceProvider = Provider<DeviceRegistryDataSource>(
  (ref) => HttpDeviceRegistryDataSource(
    client: ref.watch(deviceRegistryHttpClientProvider),
  ),
);

final deviceRegistryRepositoryProvider = Provider<DeviceRegistryRepository>(
  (ref) =>
      DeviceRegistryRepositoryImpl(ref.watch(deviceRegistryDataSourceProvider)),
);

final registeredDevicesProvider =
    AsyncNotifierProvider<RegisteredDevicesNotifier, RegisteredDevicePage>(
      RegisteredDevicesNotifier.new,
      retry: (retryCount, error) => null,
    );

class RegisteredDevicesNotifier extends AsyncNotifier<RegisteredDevicePage> {
  static const pageSize = 20;

  late DeviceRegistryRepository _repository;
  int _currentPage = 1;

  @override
  Future<RegisteredDevicePage> build() async {
    _repository = ref.watch(deviceRegistryRepositoryProvider);
    return _fetchPage(_currentPage);
  }

  Future<void> register({
    required String blueNo,
    required String macAddress,
  }) async {
    await _repository.registerDevice(blueNo: blueNo, macAddress: macAddress);
    state = AsyncData(await _fetchPage(_currentPage));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(_currentPage));
  }

  Future<void> goToPage(int page) async {
    final current = state.value;
    if (page < 1 ||
        page == _currentPage ||
        (current != null && page > current.totalPages)) {
      return;
    }

    _currentPage = page;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(page));
  }

  Future<RegisteredDevicePage> _fetchPage(int page) {
    return _repository.fetchDevices(page: page, pageSize: pageSize);
  }
}
