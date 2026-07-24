import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/voice_settings/presentation/tts_providers.dart';

enum NavKey { routes, search, home, voice, settings }

/// ترتیب پیش‌فرض [routes, search, home, voice, settings] با home در وسط.
/// وقتی صفحه‌ی فعال چیزی غیر از home باشد، آن آیتم با آیتم وسط جابه‌جا می‌شود.
///
/// بک‌گراند منو دقیقاً از روی پروژه‌ی مرجع HTML (project.zip →
/// js/bottom-nav.js + css/style.css) پیاده‌سازی شده: به‌جای عکس PNG، از دو
/// شکل واقعی ساخته می‌شود — یک نیم‌دایره‌ی پهن در پس‌زمینه (.bottom-semicircle)
/// و یک کپسول شناور روی آن با آیکون‌ها داخلش (.bottom-cylinder). آیتم فعال
/// (وسط) بزرگ‌تر است، کمی بالاتر می‌رود و گرادینت آبی→بنفش دارد.
class BottomNav extends ConsumerStatefulWidget {
  final NavKey currentPage;
  final bool isHomePage; // برای تعیین رنگ تم (سبز صفحه اصلی / آبی‌بنفش بقیه)

  const BottomNav({
    super.key,
    required this.currentPage,
    this.isHomePage = false,
  });

  @override
  ConsumerState<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends ConsumerState<BottomNav> {

  static const List<NavKey> _defaultOrder = [
    NavKey.routes,
    NavKey.search,
    NavKey.home,
    NavKey.voice,
    NavKey.settings,
  ];
  static const int _centerSlot = 2;

  static const double _barHeight = 96;
  static const double _horizontalMargin = 10;

  List<NavKey> _buildOrder(NavKey current) {
    final order = List<NavKey>.from(_defaultOrder);
    if (current != NavKey.home) {
      final idx = order.indexOf(current);
      if (idx != -1) {
        final tmp = order[idx];
        order[idx] = order[_centerSlot];
        order[_centerSlot] = tmp;
      }
    }
    return order;
  }

  IconData _iconFor(NavKey key, bool ttEnabled) {
    switch (key) {
      case NavKey.routes:
        return Icons.alt_route_rounded;
      case NavKey.search:
        return Icons.search_rounded;
      case NavKey.home:
        return Icons.home_rounded;
      case NavKey.voice:
        return ttEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded;
      case NavKey.settings:
        return Icons.settings_rounded;
    }
  }

  void _onTap(NavKey key) {
    if (key == NavKey.voice) {
      // نکته‌ی مهم (بخش دوم رفع باگ «سخنگو کار نمی‌کند»): قبلاً این دکمه فقط
      // یک بولین محلیِ بی‌اثر (voiceMuted) را toggle می‌کرد که به هیچ سرویس
      // واقعی وصل نبود. الان با ttEnabledProvider (همان پرچمی که در
      // home_screen قبل از هر speak() چک می‌شود) واقعاً صدای راهنما را
      // خاموش/روشن می‌کند، و اگر همین لحظه در حال خواندن باشد بلافاصله قطع
      // می‌شود.
      final notifier = ref.read(ttEnabledProvider.notifier);
      final newValue = !ref.read(ttEnabledProvider);
      notifier.state = newValue;
      if (!newValue) {
        ref.read(ttsServiceProvider).stop();
      }
      return;
    }
    // نکته‌ی مهم (رفع باگ «دکمه‌ی برگشت گوشی کلاً از اپ خارج می‌شود»):
    // قبلاً همه‌جا از context.go() استفاده می‌شد. go() کل پشته‌ی ناوبری را پاک
    // کرده و فقط مسیر جدید را جایگزین می‌کند، پس همیشه فقط یک صفحه در پشته
    // باقی می‌ماند. در نتیجه وقتی کاربر دکمه‌ی فیزیکی/سیستمی برگشت گوشی را
    // می‌زد، چیزی برای pop کردن وجود نداشت و کل اپ بسته می‌شد. الان فقط رفتن
    // به «خانه» با go() به ریشه‌ی پشته برمی‌گردد (چون خانه نقطه‌ی شروع منطقی
    // است)، و بقیه‌ی صفحات با push() روی پشته اضافه می‌شوند تا دکمه‌ی برگشت
    // گوشی بتواند یک مرحله واقعی به عقب برگردد، نه این‌که اپ را ببندد.
    switch (key) {
      case NavKey.home:
        context.go('/');
        break;
      case NavKey.routes:
        context.push('/routes');
        break;
      case NavKey.search:
        context.push('/search');
        break;
      case NavKey.settings:
        context.push('/settings');
        break;
      case NavKey.voice:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _buildOrder(widget.currentPage);
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final ttEnabled = ref.watch(ttEnabledProvider);

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: _barHeight + bottomSafe,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // لایه بک‌گراند: دقیقاً طبق پروژه‌ی HTML مرجع (css/style.css) —
            // به‌جای عکس PNG قبلی، حالا از دو شکل واقعی ساخته می‌شود:
            // ۱) نیم‌دایره‌ی تیره‌ی پهن در پس‌زمینه (.bottom-semicircle)
            // ۲) کپسول شناور روی آن با آیکون‌ها داخلش (.bottom-cylinder)
            // این باعث می‌شود ظاهر با نمونه‌ی HTML یکی باشد و به رزولوشن یک
            // عکس ثابت هم وابسته نباشد.
            Positioned(
              left: -MediaQuery.of(context).size.width * 0.25,
              right: -MediaQuery.of(context).size.width * 0.25,
              bottom: bottomSafe,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.elliptical(600, 50),
                  topRight: Radius.elliptical(600, 50),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.subGlassBgSoft,
                      border: const Border(
                        top: BorderSide(color: Color(0x47BEB4FF), width: 1),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x80000000),
                          blurRadius: 24,
                          offset: Offset(0, -8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // کپسول شناور (.bottom-cylinder): پس‌زمینه‌ی گرادینت عمودی تیره،
            // گوشه‌های کاملاً گرد (radius 28) و سایه‌ی نرم — دقیقاً طبق CSS.
            Positioned(
              left: _horizontalMargin + 30,
              right: _horizontalMargin + 30,
              bottom: bottomSafe + 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: AppColors.subGlassBg,
                      border: Border.all(color: AppColors.subGlassBorder, width: 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x8C000000),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // لایه آیکون‌ها — روی ناحیه‌ی صاف نوار می‌نشیند، فقط آیتم وسط به
            // داخل برآمدگی بالا می‌رود. نکته (رفع باگ «نوشته‌های زیر
            // آیکون‌ها اضافه‌اند»): طبق درخواست، برچسب متنی زیر آیکون‌ها
            // کاملاً حذف شد؛ در نتیجه دیگر لازم نیست ارتفاعی برای متن رزرو
            // شود، پس همه‌ی آیکون‌ها (نه فقط متن) روی یک خط وسط‌چین می‌شوند.
            Positioned(
              left: _horizontalMargin + 30,
              right: _horizontalMargin + 30,
              // ردیف آیکون‌ها دقیقاً هم‌ارتفاع با کپسول شناور (که از
              // bottomSafe+20 شروع می‌شود و ۵۶ ارتفاع دارد) قرار می‌گیرد تا
              // آیکون‌های غیرفعال درست وسط کپسول باشند و فقط آیکون فعال از
              // آن بالاتر بزند (transform روی خودش).
              bottom: bottomSafe + 20,
              // نکته مهم (رفع باگ «ترتیب آیکون‌ها برعکس شده»): چون کل اپ با
              // Directionality.rtl کار می‌کند، یک Row معمولی این ردیف را
              // به‌صورت خودکار آینه می‌کند (اولین آیتم لیست سمت راست ظاهر
              // می‌شود، نه چپ) که ترتیب را برخلاف طرح مرجع می‌کرد. اینجا با
              // یک Directionality.ltr مستقل، ترتیب همیشه دقیقاً برابر با
              // ترتیب _defaultOrder (مسیرها → جستجو → خانه → صدا → تنظیمات
              // از چپ به راست) می‌ماند.
              child: SizedBox(
                height: 56,
                child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: order.map((key) {
                    final isActive = order.indexOf(key) == _centerSlot;
                    final isMuted = key == NavKey.voice && !ttEnabled;
                    return GestureDetector(
                      onTap: () => _onTap(key),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 68,
                        height: 68,
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            // نوار بزرگ‌تر شد (طبق درخواست، مورد ۴): آیکون‌ها
                            // هم متناسب با آن بزرگ‌تر شدند — غیرفعال از ۴۴ به
                            // ۵۰. دکمه‌ی وسط (فعال) طبق بازخورد بعدی کاربر
                            // دوباره کوچک‌تر شد (از ۶۸ به ۵۸) تا کمتر از حد
                            // چشمگیر بزرگ به‌نظر برسد.
                            width: isActive ? 58 : 50,
                            height: isActive ? 58 : 50,
                            // نکته (رفع باگ «دکمه‌ی وسط خیلی بالاست»): قبلاً
                            // با حذف برچسب متنی زیر آیکون‌ها، دیگر لازم
                            // نیست دکمه‌ی وسط به‌اندازه‌ی قبل (۲۲px) بالا
                            // برود؛ الان کمتر بالا می‌رود تا دقیقاً داخل
                            // برآمدگی عکس بنشیند، نه بالاتر از آن. عدد کمی
                            // کمتر شد (-۱۰ به‌جای -۱۲) چون خودِ دکمه هم
                            // کوچک‌تر شده.
                            transform: isActive
                                ? (Matrix4.identity()..translate(0.0, -10.0))
                                : Matrix4.identity(),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              // نکته (رفع باگ «رنگ دکمه‌ی وسط بین صفحات فرق
                              // می‌کند» + بازخورد بعدی کاربر برای گرادینت
                              // آبی-بنفش): دکمه‌ی وسط حالا از همان گرادینت
                              // آبی→بنفش استاندارد صفحات داخلی
                              // (subAccentGradient) استفاده می‌کند، به‌جای
                              // گرادینت سبز→آبی قبلی.
                              gradient: isActive ? AppColors.subAccentGradient : null,
                              color: isActive ? null : Colors.transparent,
                              border: isActive
                                  ? Border.all(color: const Color(0xFF0E1219), width: 4)
                                  : null,
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: AppColors.subAccentB,
                                        blurRadius: 16,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              _iconFor(key, ttEnabled),
                              size: isActive ? 28 : 26,
                              color: isMuted
                                  ? AppColors.homeDanger
                                  : (isActive ? Colors.white : const Color(0xFFC7CCD1)),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
