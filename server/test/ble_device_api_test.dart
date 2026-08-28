import 'dart:convert';

import 'package:pdam_ble_api/pdam_ble_api.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  late _FakeBleDeviceRepository repository;
  late BleDeviceApi api;

  setUp(() {
    repository = _FakeBleDeviceRepository();
    api = BleDeviceApi(repository: repository, apiToken: 'test-token');
  });

  test('GET /api/ble-devices returns DB records', () async {
    repository.devices.add(
      const BleDeviceRecord(
        blueNo: '101',
        macAddress: 'AA:BB:CC:DD:EE:FF',
        createDate: '2026-08-27 15:00:00',
      ),
    );

    final response = await api(
      Request(
        'GET',
        Uri.parse('http://localhost/api/ble-devices?page=2&size=20'),
        headers: {'Authorization': 'Bearer test-token'},
      ),
    );
    final body = jsonDecode(await response.readAsString()) as Map;

    expect(response.statusCode, 200);
    expect((body['data'] as List).single['blueNo'], '101');
    expect((body['pagination'] as Map)['page'], 2);
    expect((body['pagination'] as Map)['size'], 20);
    expect((body['pagination'] as Map)['totalCount'], 1);
    expect(repository.lastRequestedPage, 2);
    expect(repository.lastRequestedPageSize, 20);
  });

  test('POST /api/ble-devices validates and inserts a device', () async {
    final response = await api(
      Request(
        'POST',
        Uri.parse('http://localhost/api/ble-devices'),
        headers: {
          'Authorization': 'Bearer test-token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'blueNo': '102', 'macAddress': '11:22:33:44:55:66'}),
      ),
    );

    expect(response.statusCode, 201);
    expect(repository.devices.single.blueNo, '102');
    expect(repository.devices.single.macAddress, '11:22:33:44:55:66');
  });

  test('API token is enforced', () async {
    final response = await api(
      Request('GET', Uri.parse('http://localhost/api/ble-devices')),
    );

    expect(response.statusCode, 401);
  });

  test('invalid MAC address is rejected', () async {
    final response = await api(
      Request(
        'POST',
        Uri.parse('http://localhost/api/ble-devices'),
        headers: {'Authorization': 'Bearer test-token'},
        body: jsonEncode({'blueNo': '1', 'macAddress': 'invalid'}),
      ),
    );

    expect(response.statusCode, 400);
    expect(repository.devices, isEmpty);
  });
}

class _FakeBleDeviceRepository implements BleDeviceRepository {
  final List<BleDeviceRecord> devices = [];
  int? lastRequestedPage;
  int? lastRequestedPageSize;

  @override
  Future<void> checkConnection() async {}

  @override
  Future<BleDevicePage> fetchPage({
    required int page,
    required int pageSize,
  }) async {
    lastRequestedPage = page;
    lastRequestedPageSize = pageSize;
    return BleDevicePage(
      devices: List.unmodifiable(devices),
      totalCount: devices.length,
    );
  }

  @override
  Future<BleDeviceRecord> insert({
    required String blueNo,
    required String macAddress,
  }) async {
    final device = BleDeviceRecord(
      blueNo: blueNo,
      macAddress: macAddress,
      createDate: '2026-08-27 15:00:00',
    );
    devices.add(device);
    return device;
  }
}
