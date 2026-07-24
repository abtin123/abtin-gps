import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../../../shared/widgets/glass_notice.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/thumb_back_button.dart';
import '../../routing/presentation/routing_providers.dart';
import '../data/iran_provinces.dart';
import 'offline_maps_providers.dart';

class GraphDownloadScreen extends ConsumerStatefulWidget {
  const GraphDownloadScreen({super.key});

  @override
  ConsumerState<GraphDownloadScreen> createState() => _GraphDownloadScreenState();
}

class _GraphDownloadScreenState extends ConsumerState<GraphDownloadScreen> {
  // پیشرفت دانلود هر استان (province.id -> 0..1)
  final Map<String, double> _progress = {};

  Future<void> _download(Province province) async {
    final graphStore = ref.read(offlineGraphStoreProvider);
    setState(() => _progress[province.id] = 0);
    try {
      await graphStore.downloadProvince(
        province,
        onProgress: (p) {
          if (mounted) setState(() => _progress[province.id] = p);
        },
      );
      if (!mounted) return;
      setState(() => _progress.remove(province.id));
      ref.invalidate(downloadedGraphsProvider);
      _snack('گراف «${province.name}» با موفقیت دانلود شد ✅');
    } catch (e) {
      if (!mounted) return;
      setState(() => _progress.remove(province.id));
      _snack('خطا در دانلود گراف «${province.name}»: $e', error: true);
    }
  }

  Future<void> _delete(Province province) async {
    final graphStore = ref.read(offlineGraphStoreProvider);
    await graphStore.deleteProvince(province.id);
    if (!mounted) return;
    ref.invalidate(downloadedGraphsProvider);
    _snack('گراف «${province.name}» حذف شد');
  }

  Future<void> _update(Province province) async {
    final graphStore = ref.read(offlineGraphStoreProvider);
    await graphStore.deleteProvince(province.id);
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
    final graphsAsync = ref.watch(downloadedGraphsProvider);
    final graphStore = ref.read(offlineGraphStoreProvider);

    final downloaded = <String>{};
    graphsAsync.whenData((graphs) {
      downloaded.addAll(graphs);
    });

    return Scaffold(
      appBar: const PageHeader(title: 'دانلود گراف مسیریابی'),
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
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'گراف مسیریابی آفلاین را دانلود کنید تا بدون اینترنت مسیریابی محاسبه شود.\n\nنکته: نقشه و گراف جدا دانلود می‌شوند.',
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
                              isDownloaded: downloaded.contains(p.id),
                              progress: _progress[p.id],
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

class _ProvinceRow extends StatelessWidget {
  final Province province;
  final bool isDownloaded;
  final double? progress;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;

  const _ProvinceRow({
    required this.province,
    required this.isDownloaded,
    required this.progress,
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
                      fontWeight: FontWeight.bold,
                    ),
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDownloaded ? 'گراف دانلود شده ✓' : 'آماده برای دانلود',
                      style: TextStyle(
                        color: isDownloaded
                            ? AppColors.homeAccent
                            : AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (isDownloading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.subAccentA),
                  ),
                )
              else if (isDownloaded) ...[]
              else
                Icon(
                  Icons.cloud_download_outlined,
                  color: AppColors.textMuted,
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
        ],
      ),
    );
  }
}
