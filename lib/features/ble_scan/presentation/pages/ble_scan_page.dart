import 'package:ble_scanner/core/theme/app_theme.dart';
import 'package:ble_scanner/features/ble_scan/domain/entities/ble_device.dart';
import 'package:ble_scanner/features/ble_scan/domain/repositories/ble_scanner_repository.dart';
import 'package:ble_scanner/features/ble_scan/presentation/providers/ble_scan_provider.dart';
import 'package:ble_scanner/features/device_registry/presentation/providers/device_registry_provider.dart';
import 'package:ble_scanner/features/device_registry/presentation/widgets/device_registration_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BleScanPage extends ConsumerWidget {
  const BleScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bleScanProvider);
    final notifier = ref.read(bleScanProvider.notifier);
    final registeredAddresses =
        ref
            .watch(registeredDevicesProvider)
            .value
            ?.devices
            .map((device) => device.macAddress.toUpperCase())
            .toSet() ??
        const <String>{};

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 20,
        title: const Text(
          '블루투스 기기 등록',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
                  sliver: SliverList.list(
                    children: [
                      _BluetoothCard(
                        state: state,
                        onAction: notifier.toggleScan,
                      ),
                      if (state.errorMessage case final message?) ...[
                        const SizedBox(height: 12),
                        _ErrorNotice(
                          message: message,
                          onDismiss: notifier.dismissError,
                        ),
                      ],
                      const SizedBox(height: 30),
                      _ResultsSection(
                        state: state,
                        registeredAddresses: registeredAddresses,
                        onDeviceTap: (device) => showDeviceRegistrationDialog(
                          context: context,
                          device: device,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BluetoothCard extends StatelessWidget {
  const _BluetoothCard({required this.state, required this.onAction});

  final BleScanState state;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final title = state.isScanning
        ? '주변 기기를 검색 중입니다.'
        : state.devices.isNotEmpty
        ? 'ED-BT5를 찾앗습니다.'
        : 'ED-BT5 기기 찾기';
    final description = state.isScanning
        ? '검색은 10초 동안 진행됩니다.'
        : state.devices.isNotEmpty
        ? '아래 목록에서 기기를 확인하세요.'
        : '기기의 전원을 켠 후 검색해주세요.';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24026D8F),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Bluetooth',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    _AvailabilityBadge(availability: state.availability),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BluetoothIcon(isScanning: state.isScanning),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Text(
                              title,
                              key: ValueKey(title),
                              style: const TextStyle(
                                color: AppColors.surface,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            description,
                            style: TextStyle(
                              color: AppColors.surface.withValues(alpha: 0.75),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(
                      state.isScanning
                          ? Icons.stop_rounded
                          : Icons.search_rounded,
                      size: 20,
                    ),
                    label: Text(
                      state.isScanning
                          ? '검색 중지'
                          : state.hasScanned
                          ? '다시 검색'
                          : '검색 시작',
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: state.isScanning ? 3 : 0,
            child: state.isScanning
                ? const LinearProgressIndicator(
                    color: AppColors.surface,
                    backgroundColor: Color(0x44000000),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.availability});

  final BluetoothAvailability availability;

  @override
  Widget build(BuildContext context) {
    final label = switch (availability) {
      BluetoothAvailability.on => '블루투스 켜짐',
      BluetoothAvailability.off => '블루투스 꺼짐',
      BluetoothAvailability.unavailable => '지원하지 않음',
      BluetoothAvailability.unauthorized => '권한 필요',
      BluetoothAvailability.unknown => '확인 중',
    };
    final isAvailable = availability == BluetoothAvailability.on;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isAvailable ? const Color(0xFF8FE1F2) : AppColors.surface,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.surface,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BluetoothIcon extends StatelessWidget {
  const _BluetoothIcon({required this.isScanning});

  final bool isScanning;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          if (isScanning)
            const SizedBox.square(
              dimension: 43,
              child: CircularProgressIndicator(
                color: AppColors.surface,
                strokeWidth: 2,
              ),
            ),
          const Icon(
            Icons.bluetooth_rounded,
            color: AppColors.surface,
            size: 25,
          ),
        ],
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEE7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF914426),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded, size: 20),
            color: const Color(0xFF914426),
          ),
        ],
      ),
    );
  }
}

class _ResultsSection extends StatelessWidget {
  const _ResultsSection({
    required this.state,
    required this.registeredAddresses,
    required this.onDeviceTap,
  });

  final BleScanState state;
  final Set<String> registeredAddresses;
  final ValueChanged<BleDevice> onDeviceTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('검색된 기기', style: Theme.of(context).textTheme.headlineSmall),
            const Spacer(),
            Text(
              '${state.devices.length}',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: state.devices.isEmpty
              ? _EmptyResult(
                  key: const ValueKey('empty'),
                  isScanning: state.isScanning,
                  hasScanned: state.hasScanned,
                )
              : Column(
                  key: const ValueKey('devices'),
                  children: [
                    for (
                      var index = 0;
                      index < state.devices.length;
                      index++
                    ) ...[
                      _DeviceCard(
                        device: state.devices[index],
                        isRegistered: registeredAddresses.contains(
                          state.devices[index].address.toUpperCase(),
                        ),
                        onTap: () => onDeviceTap(state.devices[index]),
                      ),
                      if (index != state.devices.length - 1)
                        const SizedBox(height: 10),
                    ],
                    if (state.devices.any(
                      (device) => !device.hasMacAddress,
                    )) ...[
                      const SizedBox(height: 12),
                      const _IosIdentifierNotice(),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({
    super.key,
    required this.isScanning,
    required this.hasScanned,
  });

  final bool isScanning;
  final bool hasScanned;

  @override
  Widget build(BuildContext context) {
    final title = isScanning
        ? '검색 중입니다.'
        : hasScanned
        ? 'ED-BT5를 찾지 못했습니다.'
        : '검색된 기기가 없습니다.';
    final description = isScanning
        ? 'ED-BT5가 가까이 있는지 확인해 주세요.'
        : hasScanned
        ? '기기 전원과 거리를 확인하고 다시 검색해 주세요.'
        : '위의 검색 시작 버튼을 눌러 주세요.';

    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.softBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isScanning
                  ? Icons.bluetooth_searching_rounded
                  : Icons.bluetooth_disabled_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.isRegistered,
    required this.onTap,
  });

  final BleDevice device;
  final bool isRegistered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${device.name}, 주소 ${device.address}, 신호 ${_signalLabel(device.rssi)}',
      button: true,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.softBlue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.bluetooth_rounded,
                    color: AppColors.primary,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              device.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.mutedInk,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isRegistered) ...[
                            const SizedBox(width: 8),
                            const Text(
                              '등록됨',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _SignalBars(rssi: device.rssi),
                    const SizedBox(height: 6),
                    Text(
                      '${device.rssi} dBm',
                      style: const TextStyle(
                        color: AppColors.mutedInk,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _signalLabel(int rssi) {
    if (rssi >= -60) return '매우 가까움';
    if (rssi >= -75) return '가까움';
    return '멀리 있음';
  }
}

class _SignalBars extends StatelessWidget {
  const _SignalBars({required this.rssi});

  final int rssi;

  @override
  Widget build(BuildContext context) {
    final activeBars = rssi >= -60 ? 4 : (rssi >= -75 ? 3 : 2);

    return SizedBox(
      width: 26,
      height: 19,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          return Container(
            width: 4,
            height: 5.0 + (index * 4),
            decoration: BoxDecoration(
              color: index < activeBars ? AppColors.primary : AppColors.line,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}

class _IosIdentifierNotice extends StatelessWidget {
  const _IosIdentifierNotice();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: AppColors.mutedInk,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            'iOS에서는 MAC 주소 대신 앱 전용 식별자가 표시됩니다.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
