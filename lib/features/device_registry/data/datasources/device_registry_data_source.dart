import 'dart:async';
import 'dart:convert';

import 'package:ble_scanner/features/device_registry/domain/entities/registered_device_page.dart';
import 'package:http/http.dart' as http;

abstract interface class DeviceRegistryDataSource {
  Future<RegisteredDevicePage> fetchDevices({
    required int page,
    int pageSize = 20,
  });
  Future<void> insertDevice({
    required String blueNo,
    required String macAddress,
  });
}

class HttpDeviceRegistryDataSource implements DeviceRegistryDataSource {
  HttpDeviceRegistryDataSource({
    required this._client,
    String baseUrl = const String.fromEnvironment(
      'PDAM_API_BASE_URL',
      defaultValue: 'http://192.168.0.7:8081',
    ),
    this._apiToken = const String.fromEnvironment('PDAM_API_TOKEN'),
  }) : _baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');

  static const _timeout = Duration(seconds: 5);

  final http.Client _client;
  final String _baseUrl;
  final String _apiToken;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json; charset=utf-8',
    if (_apiToken.isNotEmpty) 'Authorization': 'Bearer $_apiToken',
  };

  @override
  Future<RegisteredDevicePage> fetchDevices({
    required int page,
    int pageSize = 20,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/api/ble-devices',
    ).replace(queryParameters: {'page': '$page', 'size': '$pageSize'});
    final response = await _send(() => _client.get(uri, headers: _headers));

    final body = _decodeObject(response.body);
    try {
      return RegisteredDevicePage.fromJson(body);
    } on Object {
      throw const DeviceRegistryDataException('서버 응답 형식이 올바르지 않습니다.');
    }
  }

  @override
  Future<void> insertDevice({
    required String blueNo,
    required String macAddress,
  }) async {
    await _send(
      () => _client.post(
        Uri.parse('$_baseUrl/api/ble-devices'),
        headers: _headers,
        body: jsonEncode({'blueNo': blueNo, 'macAddress': macAddress}),
      ),
      expectedStatuses: const {201},
    );
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    Set<int> expectedStatuses = const {200},
  }) async {
    try {
      final response = await request().timeout(_timeout);
      if (expectedStatuses.contains(response.statusCode)) return response;

      final body = _tryDecodeObject(response.body);
      final message = body?['message']?.toString();
      throw DeviceRegistryDataException(
        message?.isNotEmpty == true
            ? message!
            : '서버 요청에 실패했습니다. (${response.statusCode})',
      );
    } on DeviceRegistryDataException {
      rethrow;
    } on TimeoutException {
      throw const DeviceRegistryDataException('서버 응답 시간이 초과되었습니다.');
    } on http.ClientException {
      throw const DeviceRegistryDataException(
        'PDAM 서버에 연결할 수 없습니다. API 주소와 네트워크를 확인해 주세요.',
      );
    }
  }

  Map<String, Object?> _decodeObject(String source) {
    final value = _tryDecodeObject(source);
    if (value == null) {
      throw const DeviceRegistryDataException('서버 응답 형식이 올바르지 않습니다.');
    }
    return value;
  }

  Map<String, Object?>? _tryDecodeObject(String source) {
    try {
      final value = jsonDecode(source);
      if (value is Map) return Map<String, Object?>.from(value);
    } on FormatException {
      return null;
    }
    return null;
  }
}

class DeviceRegistryDataException implements Exception {
  const DeviceRegistryDataException(this.message);

  final String message;

  @override
  String toString() => message;
}
