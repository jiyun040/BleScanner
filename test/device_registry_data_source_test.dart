import 'dart:convert';

import 'package:ble_scanner/features/device_registry/data/datasources/device_registry_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('PDAM API 등록 목록 응답을 앱 모델로 변환한다', () async {
    final source = HttpDeviceRegistryDataSource(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/ble-devices');
        expect(request.url.queryParameters, {'page': '2', 'size': '20'});
        return http.Response(
          jsonEncode({
            'data': [
              {
                'blueNo': '101',
                'macAddress': 'AA:BB:CC:DD:EE:FF',
                'createDate': '2026-08-27 15:00:00',
              },
            ],
            'pagination': {
              'page': 2,
              'size': 20,
              'totalCount': 41,
              'totalPages': 3,
            },
          }),
          200,
        );
      }),
      baseUrl: 'http://pdam-api:8080/',
    );

    final result = await source.fetchDevices(page: 2);

    expect(result.devices.single.blueNo, '101');
    expect(result.devices.single.macAddress, 'AA:BB:CC:DD:EE:FF');
    expect(result.page, 2);
    expect(result.totalCount, 41);
    expect(result.totalPages, 3);
  });

  test('기기 등록 요청은 DB 필드명으로 전송한다', () async {
    final source = HttpDeviceRegistryDataSource(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(jsonDecode(request.body), {
          'blueNo': '102',
          'macAddress': '11:22:33:44:55:66',
        });
        return http.Response(jsonEncode({'data': {}}), 201);
      }),
      baseUrl: 'http://pdam-api:8080',
    );

    await source.insertDevice(blueNo: '102', macAddress: '11:22:33:44:55:66');
  });

  test('서버 오류 메시지를 앱 오류로 전달한다', () async {
    final source = HttpDeviceRegistryDataSource(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'message': '이미 등록된 기기입니다.'}),
          409,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
      baseUrl: 'http://pdam-api:8080',
    );

    expect(
      source.insertDevice(blueNo: '1', macAddress: 'AA:BB:CC:DD:EE:FF'),
      throwsA(
        isA<DeviceRegistryDataException>().having(
          (error) => error.message,
          'message',
          '이미 등록된 기기입니다.',
        ),
      ),
    );
  });
}
