import 'dart:async';

import 'package:ble_scanner/features/ble_scan/data/datasources/ble_scanner_data_source.dart';
import 'package:ble_scanner/features/ble_scan/data/repositories/ble_scanner_repository_impl.dart';
import 'package:ble_scanner/features/ble_scan/domain/entities/ble_device.dart';
import 'package:ble_scanner/features/ble_scan/domain/repositories/ble_scanner_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bleScannerDataSourceProvider = Provider<BleScannerDataSource>(
  (ref) => FlutterBluePlusDataSource(),
);
final bleScannerRepositoryProvider = Provider<BleScannerRepository>(
  (ref) => BleScannerRepositoryImpl(ref.watch(bleScannerDataSourceProvider)),
);
final bleScanProvider = NotifierProvider<BleScanNotifier, BleScanState>(
  BleScanNotifier.new,
);

class BleScanNotifier extends Notifier<BleScanState> {
  final _subscriptions = <StreamSubscription<Object?>>[];
  bool _isAlive = true;

  late BleScannerRepository _repository;
  bool _hasRequestedBluetoothEnable = false;

  @override
  BleScanState build() {
    _repository = ref.watch(bleScannerRepositoryProvider);
    scheduleMicrotask(_subscribe);

    ref.onDispose(() {
      _isAlive = false;
      for (final subscription in _subscriptions) {
        unawaited(subscription.cancel());
      }
    });
    return const BleScanState();
  }

  void _subscribe() {
    if (!_isAlive) return;

    _subscriptions.add(
      _repository.watchTargetDevices().listen((devices) {
        if (_isAlive) state = state.copyWith(devices: devices);
      }, onError: _handleStreamError),
    );
    _subscriptions.add(
      _repository.watchAdapterState().listen((availability) {
        if (_isAlive) {
          state = state.copyWith(availability: availability);
          if (availability == BluetoothAvailability.off &&
              !_hasRequestedBluetoothEnable) {
            _hasRequestedBluetoothEnable = true;
            unawaited(_turnBluetoothOn());
          }
        }
      }),
    );
    _subscriptions.add(
      _repository.watchScanStatus().listen((isScanning) {
        if (_isAlive) state = state.copyWith(isScanning: isScanning);
      }),
    );
  }

  Future<void> _turnBluetoothOn() async {
    try {
      await _repository.ensureBluetoothOn();
    } catch (error) {
      if (_isAlive) {
        state = state.copyWith(errorMessage: _messageFor(error));
      }
    }
  }

  Future<void> toggleScan() async {
    if (state.isScanning) {
      await stopScan();
      return;
    }
    await startScan();
  }

  Future<void> startScan() async {
    state = state.copyWith(
      devices: const [],
      hasScanned: true,
      clearError: true,
    );

    try {
      await _repository.startTargetScan();
    } catch (error) {
      if (!_isAlive) return;
      state = state.copyWith(
        isScanning: false,
        errorMessage: _messageFor(error),
      );
    }
  }

  Future<void> stopScan() async {
    try {
      await _repository.stopScan();
    } catch (error) {
      if (_isAlive) {
        state = state.copyWith(errorMessage: _messageFor(error));
      }
    }
  }

  void dismissError() => state = state.copyWith(clearError: true);

  void _handleStreamError(Object error, StackTrace stackTrace) {
    if (_isAlive) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: _messageFor(error),
      );
    }
  }

  String _messageFor(Object error) {
    if (error is BleScannerDataException) return error.message;
    return '기기를 찾는 중 문제가 생겼어요. 잠시 후 다시 시도해 주세요.';
  }
}

class BleScanState {
  const BleScanState({
    this.devices = const [],
    this.availability = BluetoothAvailability.unknown,
    this.isScanning = false,
    this.hasScanned = false,
    this.errorMessage,
  });

  final List<BleDevice> devices;
  final BluetoothAvailability availability;
  final bool isScanning;
  final bool hasScanned;
  final String? errorMessage;

  BleScanState copyWith({
    List<BleDevice>? devices,
    BluetoothAvailability? availability,
    bool? isScanning,
    bool? hasScanned,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BleScanState(
      devices: devices ?? this.devices,
      availability: availability ?? this.availability,
      isScanning: isScanning ?? this.isScanning,
      hasScanned: hasScanned ?? this.hasScanned,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
