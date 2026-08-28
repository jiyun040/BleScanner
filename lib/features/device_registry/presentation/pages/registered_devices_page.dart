import 'package:ble_scanner/core/theme/app_theme.dart';
import 'package:ble_scanner/features/device_registry/domain/entities/registered_ble_device.dart';
import 'package:ble_scanner/features/device_registry/presentation/providers/device_registry_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisteredDevicesPage extends ConsumerStatefulWidget {
  const RegisteredDevicesPage({super.key});

  @override
  ConsumerState<RegisteredDevicesPage> createState() =>
      _RegisteredDevicesPageState();
}

class _RegisteredDevicesPageState extends ConsumerState<RegisteredDevicesPage> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(registeredDevicesProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 20,
        title: const Text(
          '등록된 기기',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: devices.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _LoadError(
                message: error.toString(),
                onRetry: () =>
                    ref.read(registeredDevicesProvider.notifier).refresh(),
              ),
              data: (pageData) => RefreshIndicator(
                onRefresh: () =>
                    ref.read(registeredDevicesProvider.notifier).refresh(),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
                      sliver: SliverList.list(
                        children: [
                          _RegistrySummary(
                            count: pageData.totalCount,
                            currentPage: pageData.page,
                            totalPages: pageData.totalPages,
                          ),
                          const SizedBox(height: 24),
                          if (pageData.devices.isEmpty)
                            const _EmptyRegistry()
                          else
                            for (
                              var index = 0;
                              index < pageData.devices.length;
                              index++
                            ) ...[
                              _RegisteredDeviceCard(
                                device: pageData.devices[index],
                              ),
                              if (index != pageData.devices.length - 1)
                                const SizedBox(height: 10),
                            ],
                          if (pageData.totalPages > 1) ...[
                            const SizedBox(height: 24),
                            _PaginationBar(
                              currentPage: pageData.page,
                              totalPages: pageData.totalPages,
                              onPageSelected: _selectPage,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectPage(int page) async {
    await ref.read(registeredDevicesProvider.notifier).goToPage(page);
    if (!mounted || !_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }
}

class _RegistrySummary extends StatelessWidget {
  const _RegistrySummary({
    required this.count,
    required this.currentPage,
    required this.totalPages,
  });

  final int count;
  final int currentPage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.surface,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '현재 등록된 블루투스 $count대',
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalPages == 0
                      ? '저장된 블루투스 기기 없음'
                      : '$currentPage / $totalPages 페이지',
                  style: TextStyle(
                    color: AppColors.surface.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    const blockSize = 10;

    final currentBlock = (currentPage - 1) ~/ blockSize;
    final startPage = currentBlock * blockSize + 1;
    var endPage = startPage + blockSize - 1;
    if (endPage > totalPages) {
      endPage = totalPages;
    }

    final prevBlockPage = startPage - 1;
    final nextBlockPage = endPage + 1;

    return Row(
      children: [
        _TextNavButton(
          label: '이전',
          enabled: prevBlockPage >= 1,
          onPressed: () => onPageSelected(prevBlockPage),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Row(
            children: [
              for (int page = startPage; page <= endPage; page++)
                Expanded(
                  child: _PageNumberButton(
                    page: page,
                    isSelected: page == currentPage,
                    onPressed: () => onPageSelected(page),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 2),
        _TextNavButton(
          label: '다음',
          enabled: nextBlockPage <= totalPages,
          onPressed: () => onPageSelected(nextBlockPage),
        ),
      ],
    );
  }
}

class _PageNumberButton extends StatelessWidget {
  const _PageNumberButton({
    required this.page,
    required this.isSelected,
    required this.onPressed,
  });

  final int page;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$page 페이지',
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 18,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$page',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? Colors.black : Colors.black54,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                height: 2.5,
                width: 14,
                color: isSelected ? Colors.black : Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextNavButton extends StatelessWidget {
  const _TextNavButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? Colors.black87 : Colors.black26;

    return SizedBox(
      width: 42,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisteredDeviceCard extends StatelessWidget {
  const _RegisteredDeviceCard({required this.device});

  final RegisteredBleDevice device;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'No. ${device.blueNo}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    const _SavedBadge(),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  device.macAddress,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedBadge extends StatelessWidget {
  const _SavedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        '등록됨',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyRegistry extends StatelessWidget {
  const _EmptyRegistry();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 38),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.devices_other_outlined,
            color: AppColors.primary,
            size: 34,
          ),
          const SizedBox(height: 13),
          Text('등록된 기기가 없습니다', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            '기기 검색 메뉴에서 검색 결과를 눌러 등록해 주세요.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 38),
            const SizedBox(height: 12),
            const Text(
              '등록 목록을 불러오지 못했습니다.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
