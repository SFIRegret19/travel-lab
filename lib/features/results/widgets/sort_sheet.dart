import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../results_state.dart';

/// Шторка «Сортировать отели». Возвращает выбранный порядок только после
/// «Применить»; закрытие крестиком или свайпом выбор отменяет.
Future<SortOrder?> showSortSheet(BuildContext context, SortOrder current) {
  return showModalBottomSheet<SortOrder>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _SortSheet(initial: current),
  );
}

class _SortSheet extends StatefulWidget {
  const _SortSheet({required this.initial});

  final SortOrder initial;

  @override
  State<_SortSheet> createState() => _SortSheetState();
}

class _SortSheetState extends State<_SortSheet> {
  late SortOrder _pending = widget.initial;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Сортировать отели',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton.filledTonal(
                  key: const Key('sort_close'),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceHigh,
                  ),
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final order in SortOrder.values)
              InkWell(
                key: Key('sort_${order.name}'),
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _pending = order),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      _RadioDot(selected: _pending == order),
                      const SizedBox(width: 14),
                      Text(order.label, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('sort_apply'),
              onPressed: () => Navigator.pop(context, _pending),
              child: const Text('Применить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? null : AppColors.surfaceHigh,
        border: selected
            ? Border.all(color: AppColors.textPrimary, width: 2)
            : null,
      ),
      child: selected
          ? Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textPrimary,
              ),
            )
          : null,
    );
  }
}
