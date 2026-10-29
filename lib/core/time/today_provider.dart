import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Вынесено в провайдер, чтобы тесты могли подставить день.
final todayProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});
