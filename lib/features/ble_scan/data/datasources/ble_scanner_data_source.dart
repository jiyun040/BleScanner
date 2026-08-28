import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

abstract interface class BleScannerDataSource {
  Stream<List<ScanResult>> watchScanResults();
  Stream<BluetoothAdapterState> watchAdapterState();
  Stream<bool> watchScanStatus();
  Future<void> ensureBluetoothOn();
  Future<void> startScan();
  Future<void> stopScan();
}

class FlutterBluePlusDataSource implements BleScannerDataSource {
  static const _scanDuration = Duration(seconds: 10);

  @override
  Stream<List<ScanResult>> watchScanResults() => FlutterBluePlus.onScanResults;

  @override
  Stream<BluetoothAdapterState> watchAdapterState() =>
      FlutterBluePlus.adapterState;

  @override
  Stream<bool> watchScanStatus() => FlutterBluePlus.isScanning;

  @override
  Future<void> startScan() async {
    if (!await FlutterBluePlus.isSupported) {
      throw const BleScannerDataException('이 기기는 Bluetooth LE를 지원하지 않아요.');
    }

    await ensureBluetoothOn();

    await FlutterBluePlus.startScan(
      timeout: _scanDuration,
      continuousUpdates: true,
      continuousDivisor: 3,
      androidScanMode: AndroidScanMode.lowLatency,
    );
  }

  @override
  Future<void> stopScan() => FlutterBluePlus.stopScan();

  @override
  Future<void> ensureBluetoothOn() async {
    if (!await FlutterBluePlus.isSupported) {
      throw const BleScannerDataException('이 기기는 Bluetooth LE를 지원하지 않아요.');
    }

    await _requestPermissions();

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState == BluetoothAdapterState.unauthorized) {
      throw const BleScannerDataException('블루투스 권한이 필요해요. 설정에서 권한을 허용해 주세요.');
    }
    if (adapterState == BluetoothAdapterState.on) return;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await FlutterBluePlus.turnOn();
        return;
      } catch (error) {
        throw const BleScannerDataException(
          '블루투스 켜기 요청이 취소되었습니다. 검색하려면 켜기를 허용해 주세요.',
        );
      }
    }

    throw const BleScannerDataException(
      '이 운영체제에서는 앱이 블루투스를 직접 켤 수 없습니다. 시스템 설정에서 켜 주세요.',
    );
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final statuses = await <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final scanStatus = statuses[Permission.bluetoothScan];
    final connectStatus = statuses[Permission.bluetoothConnect];
    final bluetoothDenied =
        scanStatus?.isDenied == true ||
        scanStatus?.isPermanentlyDenied == true ||
        connectStatus?.isDenied == true ||
        connectStatus?.isPermanentlyDenied == true;

    if (bluetoothDenied) {
      throw const BleScannerDataException('주변 기기를 찾으려면 블루투스 권한이 필요해요.');
    }
  }
}

class BleScannerDataException implements Exception {
  const BleScannerDataException(this.message);

  final String message;

  @override
  String toString() => message;
}
