import 'package:ble_scanner/app.dart';
import 'package:ble_scanner/features/ble_scan/domain/entities/ble_device.dart';
import 'package:ble_scanner/features/ble_scan/domain/repositories/ble_scanner_repository.dart';
import 'package:ble_scanner/features/ble_scan/presentation/providers/ble_scan_provider.dart';
import 'package:ble_scanner/features/device_registry/domain/entities/registered_ble_device.dart';
import 'package:ble_scanner/features/device_registry/domain/entities/registered_device_page.dart';
import 'package:ble_scanner/features/device_registry/domain/repositories/device_registry_repository.dart';
import 'package:ble_scanner/features/device_registry/presentation/providers/device_registry_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ED-BT5 검색 화면의 초기 상태를 표시한다', (tester) async {
    final registry = _FakeDeviceRegistryRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bleScannerRepositoryProvider.overrideWithValue(
            const _FakeBleScannerRepository(),
          ),
          deviceRegistryRepositoryProvider.overrideWithValue(registry),
        ],
        child: const BleScannerApp(),
      ),
    );
    await tester.pump();

    expect(find.text('블루투스 기기 등록'), findsOneWidget);
    expect(find.text('ED-BT5 기기 찾기'), findsOneWidget);
    expect(find.text('검색된 기기'), findsOneWidget);
    expect(find.text('검색된 기기가 없습니다.'), findsOneWidget);
    expect(find.text('블루투스 켜짐'), findsOneWidget);
    expect(find.text('사용 가능'), findsNothing);
    expect(find.text('FIELDLINK'), findsNothing);
    expect(find.text('LOCAL'), findsNothing);
    expect(find.textContaining('ED-BT5를 연결할 준비가 됐어요'), findsNothing);

    expect(find.text('기기 검색'), findsOneWidget);
    expect(find.text('등록 목록'), findsOneWidget);
  });

  testWidgets('검색 기기를 모달에서 등록하고 등록 목록에서 확인한다', (tester) async {
    final registry = _FakeDeviceRegistryRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bleScannerRepositoryProvider.overrideWithValue(
            const _FakeBleScannerRepository(
              devices: [
                BleDevice(
                  name: 'ED-BT5',
                  address: 'AA:BB:CC:DD:EE:FF',
                  rssi: -55,
                ),
              ],
            ),
          ),
          deviceRegistryRepositoryProvider.overrideWithValue(registry),
        ],
        child: const BleScannerApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ED-BT5'));
    await tester.pumpAndSettle();

    expect(find.text('기기를 추가할까요?'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(registry.devices.single.blueNo, isNotEmpty);
    expect(registry.devices.single.macAddress, 'AA:BB:CC:DD:EE:FF');

    await tester.tap(find.text('등록 목록'));
    await tester.pumpAndSettle();

    expect(find.text('No. ${registry.devices.single.blueNo}'), findsOneWidget);
    expect(find.text('AA:BB:CC:DD:EE:FF'), findsOneWidget);
  });

  testWidgets('서버 연결 실패 시 무한 로딩 대신 재시도 화면을 표시한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bleScannerRepositoryProvider.overrideWithValue(
            const _FakeBleScannerRepository(),
          ),
          deviceRegistryRepositoryProvider.overrideWithValue(
            const _FailingDeviceRegistryRepository(),
          ),
        ],
        child: const BleScannerApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('등록 목록'));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('등록 목록을 불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('PDAM 서버에 연결할 수 없습니다.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('등록 목록을 20개씩 표시하고 숫자 버튼으로 페이지를 이동한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final registry = _FakeDeviceRegistryRepository();
    for (var index = 1; index <= 205; index++) {
      registry.devices.add(
        RegisteredBleDevice(
          blueNo: '$index',
          macAddress:
              'AA:BB:CC:DD:EE:${index.toRadixString(16).padLeft(2, '0')}',
          createDate: DateTime(2026, 8, 27),
        ),
      );
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bleScannerRepositoryProvider.overrideWithValue(
            const _FakeBleScannerRepository(),
          ),
          deviceRegistryRepositoryProvider.overrideWithValue(registry),
        ],
        child: const BleScannerApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('등록 목록'));
    await tester.pumpAndSettle();

    expect(find.text('No. 1'), findsOneWidget);
    expect(find.text('No. 21'), findsNothing);
    expect(registry.lastRequestedPage, 1);
    expect(registry.lastRequestedPageSize, 20);

    await tester.drag(
      find.byType(CustomScrollView).last,
      const Offset(0, -2400),
    );
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();

    expect(registry.lastRequestedPage, 2);
    expect(registry.lastRequestedPageSize, 20);
    expect(find.text('No. 21'), findsOneWidget);
  });

  test('Android MAC 주소와 iOS 식별자를 구분한다', () {
    const androidDevice = BleDevice(
      name: 'ED-BT5',
      address: 'AA:BB:CC:DD:EE:FF',
      rssi: -55,
    );
    const iosDevice = BleDevice(
      name: 'ED-BT5',
      address: 'A1B2C3D4-E5F6-47A8-9012-1234567890AB',
      rssi: -55,
    );

    expect(androidDevice.hasMacAddress, isTrue);
    expect(iosDevice.hasMacAddress, isFalse);
  });
}

class _FakeBleScannerRepository implements BleScannerRepository {
  const _FakeBleScannerRepository({this.devices = const []});

  final List<BleDevice> devices;

  @override
  Stream<BluetoothAvailability> watchAdapterState() =>
      Stream.value(BluetoothAvailability.on);

  @override
  Stream<bool> watchScanStatus() => Stream.value(false);

  @override
  Stream<List<BleDevice>> watchTargetDevices() => Stream.value(devices);

  @override
  Future<void> ensureBluetoothOn() async {}

  @override
  Future<void> startTargetScan() async {}

  @override
  Future<void> stopScan() async {}
}

class _FakeDeviceRegistryRepository implements DeviceRegistryRepository {
  final List<RegisteredBleDevice> devices = [];
  int? lastRequestedPage;
  int? lastRequestedPageSize;

  @override
  Future<RegisteredDevicePage> fetchDevices({
    required int page,
    int pageSize = 20,
  }) async {
    lastRequestedPage = page;
    lastRequestedPageSize = pageSize;
    final start = (page - 1) * pageSize;
    final pageDevices = start >= devices.length
        ? const <RegisteredBleDevice>[]
        : devices.skip(start).take(pageSize).toList(growable: false);
    return RegisteredDevicePage(
      devices: pageDevices,
      page: page,
      pageSize: pageSize,
      totalCount: devices.length,
      totalPages: devices.isEmpty
          ? 0
          : (devices.length + pageSize - 1) ~/ pageSize,
    );
  }

  @override
  Future<void> registerDevice({
    required String blueNo,
    required String macAddress,
  }) async {
    devices.add(
      RegisteredBleDevice(
        blueNo: blueNo,
        macAddress: macAddress,
        createDate: DateTime.now(),
      ),
    );
  }
}

class _FailingDeviceRegistryRepository implements DeviceRegistryRepository {
  const _FailingDeviceRegistryRepository();

  @override
  Future<RegisteredDevicePage> fetchDevices({
    required int page,
    int pageSize = 20,
  }) => throw const DeviceRegistryException('PDAM 서버에 연결할 수 없습니다.');

  @override
  Future<void> registerDevice({
    required String blueNo,
    required String macAddress,
  }) async {}
}
