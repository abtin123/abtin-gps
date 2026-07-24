import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../../../shared/widgets/glass_notice.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/thumb_back_button.dart';
import '../data/iran_provinces.dart';
import '../data/offline_maps_service.dart';
import 'offline_maps_providers.dart';

class MapSettingsScreen extends ConsumerStatefulWidget {
  const MapSettingsScreen({super.key});

  @override
  ConsumerState<MapSettingsScreen> createState() => _MapSettingsScreenState();
}

class _MapSettingsScreenState extends ConsumerState<MapSettingsScreen> {
  // پیشرفت دانلود هر استان (province.id -> 0..1)
  final Map<String, double> _progress = {};

  /// 🔧 تغیر: فقط نقشه دانلود می‌شود (بدون گراف)
  Future<void> _download(Province province) async {
    final service = ref.read(offlineMapsServiceProvider);
    final quality = ref.read(selectedMapQualityProvider);
    setState(() => _progress[province.id] = 0);
    try {
      await service.downloadProvince(
        province,
        quality,
        onProgress: (p) {
          if (mounted) setState(() => _progress[province.id] = p);
        },
      );
      if (!mounted) return;
      setState(() => _progress.remove(province.id));
      ref.invalidate(offlineRegionsProvider);
      _snack('نقشه‌ی «${province.name}» با موفقیت دانلود شد ✅');
    } catch (e) {
      if (!mounted) return;
      setState(() => _progress.remove(province.id));
      _snack('خطا در دانلود نقشه‌ی «${province.name}»: $e', error: true);
    }
  }

  Future<void> _delete(Province province) async {
    final service = ref.read(offlineMapsServiceProvider);
    await service.deleteProvince(province.id);
    if (!mounted) return;
    ref.invalidate(offlineRegionsProvider);
    _snack('نقشه‌ی «${province.name}» حذف شد');
  }

  Future<void> _update(Province province) async {
    final service = ref.read(offlineMapsServiceProvider);
    final quality = ref.read(selectedMapQualityProvider);
    await service.deleteProvince(province.id);
    await _download(province);
  }

  void _snack(String msg, {bool error = false}) {
    showGlassNotice(
      context,
      msg,
      icon: error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
      colors: error
          ? const [Color(0xFFFF7A7A), Color(0xFFE5544B)]
          : const [AppColors.subAccentA, AppColors.subAccentB],
      showAboveBottomNav: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final regionsAsync = ref.watch(offlineRegionsProvider);
    final quality = ref.watch(selectedMapQualityProvider);
    final service = ref.read(offlineMapsServiceProvider);

    final downloaded = <String, OfflineRegion>{};
    regionsAsync.whenData((regions) {
      for (final r in regions) {
        final pid = r.metadata['province'];
        if (pid is String) downloaded[pid] = r;
      }
    });

    return Scaffold(
      appBar: const PageHeader(title: 'تنظیمات نقشه'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [Color(0xFF1E1B42), Color(0xFF0B0A1E)],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _QualitySelector(
                      selected: quality,
                      onChanged: (q) =>
                          ref.read(selectedMapQualityProvider.notifier).state = q,
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'نقشه را استان‌به‌استان دانلود کنید.\n\n💡 نکته: گراف مسیریابی جدا‌جا در تنظیمات > دانلود گراف دانلود می‌شود.',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GlassPanel(
                        child: ListView.separated(
                          itemCount: kIranProvinces.length,
                          separatorBuilder: (_, __) =>
                              Divider(color: Colors.white.withOpacity(.06), height: 1),
                          itemBuilder: (context, i) {
                            final p = kIranProvinces[i];
                            return _ProvinceRow(
                              province: p,
                              isDownloaded: downloaded.containsKey(p.id),
                              progress: _progress[p.id],
                              sizeMb: service.estimateSizeMb(p, quality),
                              onDownload: () => _download(p),
                              onDelete: () => _delete(p),
                              onUpdate: () => _update(p),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const ThumbBackButton(backRoute: '/settings'),
          ],
        ),
      ),
    );
  }
}

class _QualitySelector extends StatelessWidget {
  final MapQuality selected;
  final ValueChanged<MapQuality> onChanged;
  const _QualitySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: MapQuality.values.map((q) {
        final active = q == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(q),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.subAccentB.withOpacity(.22)
                    : AppColors.subGlassBgSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active ? AppColors.subAccentB : AppColors.subGlassBorder,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    q.label,
                    style: TextStyle(
                      color: active ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    q.desc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ProvinceRow extends StatelessWidget {
  final Province province;
  final bool isDownloaded;
  final double? progress;
  final double sizeMb;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;

  const _ProvinceRow({
    required this.province,
    required this.isDownloaded,
    required this.progress,
    required this.sizeMb,
    required this.onDownload,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final isDownloading = progress != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              if (isDownloading)
                SizedBox(
                  width: 40,
                  child: Text(
                    '${((progress ?? 0) * 100).round()}٪',
                    style: const TextStyle(
                        color: AppColors.subAccentA,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                )
              else if (isDownloaded) ...[]
              else
                const SizedBox(width: 40),
              const Spacer(),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      province.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDownloaded
                          ? 'دانلود شده · آفلاین'
                          : '≈ ${sizeMb.toStringAsFixed(sizeMb < 10 ? 1 : 0)} مگابایت',
                      style: TextStyle(
                        color: isDownloaded
                            ? AppColors.homeAccent
                            : AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                isDownloaded ? Icons.offline_pin_rounded : Icons.public_rounded,
                color: isDownloaded ? AppColors.homeAccent : AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
          if (isDownloading) ...[]
          else if (isDownloaded) ...[]
          else ...[],
          if (!isDownloading)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isDownloaded) ...[]
                  else
                    GestureDetector(
                      onTap: onDownload,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.subAccentA, AppColors.subAccentB],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'دانلود',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (isDownloaded) ...[]
                  else
                    const SizedBox(width: 8),
                  if (isDownloaded)
                    GestureDetector(
                      onTap: onUpdate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.subAccentA.withOpacity(.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.subAccentA,
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'به‌روزرسانی',
                          style: TextStyle(
                            color: AppColors.subAccentA,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (isDownloaded) const SizedBox(width: 8),
                  if (isDownloaded)
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B81).withOpacity(.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFF6B81),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'حذف',
                          style: TextStyle(
                            color: Color(0xFFFF6B81),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (isDownloading) ...[]
          else if (isDownloaded) ...[]
          else ...[],
        ],
      ),
    );
  }
}
