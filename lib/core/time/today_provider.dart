import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Сегодняшняя дата без времени. Вынесена в провайдер, чтобы тесты
/// могли подставить фиксированный день.
final todayProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});
