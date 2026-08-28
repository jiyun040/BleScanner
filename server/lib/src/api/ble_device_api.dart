import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../database/ble_device_repository.dart';

class BleDeviceApi {
  const BleDeviceApi({required this._repository, this._apiToken = ''});

  final BleDeviceRepository _repository;
  final String _apiToken;

  FutureOr<Response> call(Request request) async {
    if (request.method == 'OPTIONS') return _empty(204);

    final path = request.url.path;
    if (path == 'health' && request.method == 'GET') {
      return _health();
    }

    final unauthorized = _authorize(request);
    if (unauthorized != null) return unauthorized;

    if (path == 'api/ble-devices') {
      return switch (request.method) {
        'GET' => _fetchDevices(request),
        'POST' => _registerDevice(request),
        _ => _json(405, {'message': '지원하지 않는 요청 방식입니다.'}),
      };
    }

    return _json(404, {'message': '요청한 API를 찾을 수 없습니다.'});
  }

  Response? _authorize(Request request) {
    if (_apiToken.isEmpty) return null;
    if (request.headers['authorization'] == 'Bearer $_apiToken') return null;
    return _json(401, {'message': 'API 인증에 실패했습니다.'});
  }

  Future<Response> _health() async {
    try {
      await _repository.checkConnection();
      return _json(200, {'status': 'ok', 'database': 'connected'});
    } on Object {
      return _json(503, {'status': 'error', 'database': 'disconnected'});
    }
  }

  Future<Response> _fetchDevices(Request request) async {
    final page = int.tryParse(request.url.queryParameters['page'] ?? '1');
    final pageSize = int.tryParse(request.url.queryParameters['size'] ?? '20');
    if (page == null || page < 1) {
      return _json(400, {'message': 'page는 1 이상의 숫자여야 합니다.'});
    }
    if (pageSize == null || pageSize < 1 || pageSize > 100) {
      return _json(400, {'message': 'size는 1~100 사이의 숫자여야 합니다.'});
    }

    try {
      final result = await _repository.fetchPage(
        page: page,
        pageSize: pageSize,
      );
      final totalPages = result.totalCount == 0
          ? 0
          : (result.totalCount + pageSize - 1) ~/ pageSize;
      return _json(200, {
        'data': result.devices.map((device) => device.toJson()).toList(),
        'pagination': {
          'page': page,
          'size': pageSize,
          'totalCount': result.totalCount,
          'totalPages': totalPages,
        },
      });
    } on BleDatabaseException {
      return _json(503, {'message': '등록 목록을 불러오지 못했습니다.'});
    }
  }

  Future<Response> _registerDevice(Request request) async {
    final body = await _readJson(request);
    if (body == null) {
      return _json(400, {'message': 'JSON 요청 본문이 필요합니다.'});
    }

    final blueNo = body['blueNo']?.toString().trim() ?? '';
    final macAddress =
        body['macAddress']?.toString().trim().toUpperCase() ?? '';

    if (!RegExp(r'^([0-9A-F]{2}:){5}[0-9A-F]{2}$').hasMatch(macAddress)) {
      return _json(400, {'message': '블루투스 주소 형식이 올바르지 않습니다.'});
    }

    try {
      final device = await _repository.insert(
        blueNo: blueNo,
        macAddress: macAddress,
      );
      return _json(201, {'data': device.toJson()});
    } on DuplicateBleDeviceException {
      return _json(409, {'message': '이미 등록된 기기입니다.'});
    } on BleDatabaseException {
      return _json(503, {'message': '기기를 저장하지 못했습니다.'});
    }
  }

  Future<Map<String, Object?>?> _readJson(Request request) async {
    try {
      final decoded = jsonDecode(await request.readAsString());
      if (decoded is Map) return Map<String, Object?>.from(decoded);
    } on FormatException {
      return null;
    }
    return null;
  }

  Response _json(int statusCode, Map<String, Object?> body) {
    return Response(statusCode, body: jsonEncode(body), headers: _headers);
  }

  Response _empty(int statusCode) => Response(statusCode, headers: _headers);

  static const _headers = {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  };
}