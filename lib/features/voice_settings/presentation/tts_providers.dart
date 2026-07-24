import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/tts_service.dart';

/// سرویس TTS (Text-to-Speech) برای فارسی.
final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(service.dispose);
  return service;
});

/// وضعیت TTS (درحال پخش، توقف، وغیره).
final ttsStateProvider = StateProvider<TtsState>((ref) {
  return TtsState.stopped;
});

/// سرعت خواندن (0.5 تا 1.5 توصیه شده).
final ttsRateProvider = StateProvider<double>((ref) {
  return 1.0;
});

/// تن صدا (pitch) - معمولاً 1.0.
final ttsPitchProvider = StateProvider<double>((ref) {
  return 1.0;
});

/// بلندی صدا (0 تا 1).
final ttsVolumeProvider = StateProvider<double>((ref) {
  return 0.75;
});

/// صدای انتخاب شده (برای سیستم‌های با صداهای متعدد).
final ttsVoiceProvider = StateProvider<String>((ref) {
  return 'default';
});

/// آیا TTS فعال است.
final ttEnabledProvider = StateProvider<bool>((ref) {
  return true;
});
