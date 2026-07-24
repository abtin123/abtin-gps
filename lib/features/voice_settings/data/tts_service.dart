import 'package:flutter_tts/flutter_tts.dart';

/// وضعیت سرویس TTS.
enum TtsState { playing, stopped, paused, waiting }

/// سرویس تبدیل متن به صدا (Text-to-Speech) برای فارسی.
/// از موتور TTS پیش‌فرض سیستم استفاده می‌کند (Android: Google TTS).
class TtsService {
  late FlutterTts _flutterTts;
  TtsState _state = TtsState.stopped;

  double _pitch = 1.0; // 0.5 تا 2.0
  double _rate = 1.0; // 0.0 تا 2.0 (سرعت خواندن)
  double _volume = 1.0; // 0.0 تا 1.0 (بلندی صدا)
  String _language = 'fa-IR'; // فارسی

  TtsService() {
    _flutterTts = FlutterTts();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage(_language);
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setSpeechRate(_rate);
    await _flutterTts.setVolume(_volume);

    // لیسنر برای رویدادهای TTS
    _flutterTts.setStartHandler(() {
      _state = TtsState.playing;
    });

    _flutterTts.setCompletionHandler(() {
      _state = TtsState.stopped;
    });

    _flutterTts.setErrorHandler((msg) {
      _state = TtsState.stopped;
    });
  }

  /// تبدیل متن فارسی به صدا و پخش کن.
  /// [text]: متن فارسی برای خواندن
  /// [rate]: سرعت خواندن (0.5 تا 1.5 توصیه شده)
  /// [pitch]: تن صدا (معمولاً 1.0)
  /// [volume]: بلندی صدا (0 تا 1)
  Future<void> speak(
    String text, {
    double? rate,
    double? pitch,
    double? volume,
  }) async {
    if (text.isEmpty) return;

    if (rate != null) {
      _rate = rate.clamp(0.0, 2.0);
      await _flutterTts.setSpeechRate(_rate);
    }

    if (pitch != null) {
      _pitch = pitch.clamp(0.5, 2.0);
      await _flutterTts.setPitch(_pitch);
    }

    if (volume != null) {
      _volume = volume.clamp(0.0, 1.0);
      await _flutterTts.setVolume(_volume);
    }

    try {
      _state = TtsState.waiting;
      await _flutterTts.speak(text);
    } catch (e) {
      print('خطا در TTS: $e');
      _state = TtsState.stopped;
    }
  }

  /// توقف پخش.
  Future<void> stop() async {
    await _flutterTts.stop();
    _state = TtsState.stopped;
  }

  /// مکث پخش (اگر پشتیبانی شود).
  Future<void> pause() async {
    await _flutterTts.pause();
    _state = TtsState.paused;
  }

  /// ادامه‌ی پخش از جای متوقف.
  Future<void> resume() async {
    await _flutterTts.pause();
    _state = TtsState.playing;
  }

  /// تغییر زبان TTS.
  Future<void> setLanguage(String languageCode) async {
    _language = languageCode;
    await _flutterTts.setLanguage(languageCode);
  }

  /// انتخاب صدا برای سیستم‌های که پشتیبانی می‌کنند.
  /// بر روی Android، بسته به نصب صداهای TTS متفاوت است.
  Future<void> setVoice(String voiceId) async {
    await _flutterTts.setVoice({'name': voiceId, 'locale': _language});
  }

  /// دریافت دسترسی صوتی تخصصی (اگر لازم باشد).
  Future<void> requestAudioFocus() async {
    // برای Android 5.0+
  }

  /// دریافت لیست صداهای دستگاه.
  Future<List> getVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      return voices?.toList() ?? [];
    } catch (e) {
      print('خطا در دریافت صداها: $e');
      return [];
    }
  }

  /// پاک‌کردن منابع هنگام بسته شدن.
  Future<void> dispose() async {
    await _flutterTts.stop();
  }

  TtsState get state => _state;
  double get rate => _rate;
  double get pitch => _pitch;
  double get volume => _volume;
  String get language => _language;
}
