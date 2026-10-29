import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/time/today_provider.dart';
import '../search_provider.dart';

const _weekendColor = Color(0xFFE8892B);
const _monthsShown = 12;

class RangeCalendar extends ConsumerWidget {
  const RangeCalendar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final params = ref.watch(searchProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _WeekdayHeader(),
        for (var i = 0; i < _monthsShown; i++)
          _Month(
            first: DateTime(today.year, today.month + i),
            today: today,
            checkIn: params.checkIn,
            checkOut: params.checkOut,
            onPick: ref.read(searchProvider.notifier).pickDate,
          ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    const names = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          for (final n in names)
            Expanded(
              child: Center(
                child: Text(
                  n,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Month extends StatelessWidget {
  const _Month({
    required this.first,
    required this.today,
    required this.checkIn,
    required this.checkOut,
    required this.onPick,
  });

  final DateTime first;
  final DateTime today;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(first.year, first.month + 1, 0).day;
    final offset = first.weekday - 1;
    final cells = <DateTime?>[
      for (var i = 0; i < offset; i++) null,
      for (var d = 1; d <= daysInMonth; d++)
        DateTime(first.year, first.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    final title = first.year == today.year
        ? monthNames[first.month - 1]
        : '${monthNames[first.month - 1]} ${first.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 0, 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        for (var row = 0; row < cells.length ~/ 7; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(child: _buildCell(cells[row * 7 + col])),
            ],
          ),
      ],
    );
  }

  Widget _buildCell(DateTime? day) {
    if (day == null) return const SizedBox(height: 46);

    final isPast = day.isBefore(today);
    final isStart = day == checkIn;
    final isEnd = day == checkOut;
    final inRange =
        checkIn != null &&
        checkOut != null &&
        day.isAfter(checkIn!) &&
        day.isBefore(checkOut!);
    final isWeekend = day.weekday >= 6;

    Color? background;
    var textColor = isWeekend ? _weekendColor : AppColors.textPrimary;
    if (isStart || isEnd) {
      background = AppColors.accent;
      textColor = AppColors.onAccent;
    } else if (inRange) {
      background = AppColors.accent.withValues(alpha: .22);
    } else if (day == today) {
      background = AppColors.surfaceHigh;
    }
    if (isPast) textColor = textColor.withValues(alpha: .35);

    return GestureDetector(
      key: Key('day_${day.year}-${day.month}-${day.day}'),
      behavior: HitTestBehavior.opaque,
      onTap: isPast ? null : () => onPick(day),
      child: Container(
        height: 46,
        margin: const EdgeInsets.symmetric(vertical: 1),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(inRange ? 4 : 14),
        ),
        child: Text(
          '${day.day}',
          style: TextStyle(fontSize: 16, color: textColor),
        ),
      ),
    );
  }
}
