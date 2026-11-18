import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/mock/mock_settings.dart';
import '../../core/theme/app_colors.dart';

/// Демо-панель: что «ответит» сервер-заглушка. Открывается долгим нажатием на
/// заголовок главного экрана и нужна, чтобы показать состояния загрузки и
/// ошибок без правки кода.
Future<void> showDemoSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _DemoSheet(),
  );
}

class _DemoSheet extends ConsumerWidget {
  const _DemoSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(mockSettingsProvider);
    final notifier = ref.read(mockSettingsProvider.notifier);

    Widget toggle(
      String name,
      String title,
      String subtitle,
      bool value,
      MockSettings Function(MockSettings s, bool on) change,
    ) {
      return SwitchListTile(
        key: Key('demo_switch_$name'),
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(fontSize: 17)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        value: value,
        onChanged: (on) => notifier.update((cur) => change(cur, on)),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Режим демонстрации',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            const Text(
              'Что ответит сервер-заглушка на следующие запросы',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            const Text('Задержка ответа', style: TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              key: const Key('demo_latency'),
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.accent,
                selectedForegroundColor: AppColors.onAccent,
              ),
              segments: const [
                ButtonSegment(value: 0, label: Text('0 с')),
                ButtonSegment(value: 900, label: Text('0,9 с')),
                ButtonSegment(value: 3000, label: Text('3 с')),
              ],
              selected: {_nearest(s.latency.inMilliseconds)},
              onSelectionChanged: (v) => notifier.update(
                (cur) => cur.copyWith(latency: Duration(milliseconds: v.first)),
              ),
            ),
            const SizedBox(height: 12),
            toggle(
              'offline',
              'Нет сети',
              'Запрос не доходит до сервера',
              s.offline,
              (cur, on) => cur.copyWith(offline: on),
            ),
            toggle(
              'serverError',
              'Ошибка сервера',
              'Любой запрос заканчивается кодом 500',
              s.serverError,
              (cur, on) => cur.copyWith(serverError: on),
            ),
            toggle(
              'noResults',
              'Пустая выдача',
              '200 и пустой список отелей',
              s.noResults,
              (cur, on) => cur.copyWith(noResults: on),
            ),
            toggle(
              'noRooms',
              'Нет свободных номеров',
              '200 и пустой список номеров',
              s.noRooms,
              (cur, on) => cur.copyWith(noRooms: on),
            ),
            toggle(
              'soldOut',
              'Номер раскуплен',
              'Оформление отклоняется: 409 OFFER_UNAVAILABLE',
              s.soldOut,
              (cur, on) => cur.copyWith(soldOut: on),
            ),
            toggle(
              'priceChanged',
              'Цена изменилась',
              'Оформление отклоняется: 409 PRICE_CHANGED',
              s.priceChanged,
              (cur, on) => cur.copyWith(priceChanged: on),
            ),
            toggle(
              'validationError',
              'Ошибка проверки полей',
              'Оформление отклоняется: 422 VALIDATION_FAILED',
              s.validationError,
              (cur, on) => cur.copyWith(validationError: on),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  key: const Key('demo_reset'),
                  onPressed: notifier.reset,
                  child: const Text('Сбросить всё'),
                ),
                const Spacer(),
                FilledButton(
                  key: const Key('demo_close'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(120, 48),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Готово'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Ближайшее из трёх значений задержки для подсветки сегмента.
  int _nearest(int ms) {
    const options = [0, 900, 3000];
    return options.reduce((a, b) => (a - ms).abs() <= (b - ms).abs() ? a : b);
  }
}
