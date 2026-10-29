import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/edge_fade.dart';
import '../filters/filters_sheet.dart';
import '../results_state.dart';
import 'sort_sheet.dart';

class FilterChipsBar extends ConsumerWidget {
  const FilterChipsBar({super.key});

  static const height = 64.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(sortProvider);
    final filters = ref.watch(filtersProvider);
    final filtersNotifier = ref.read(filtersProvider.notifier);

    return EdgeFade(
      child: SizedBox(
        height: height,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          children: [
            _Chip(
              key: const Key('chip_filters'),
              icon: Icons.tune_rounded,
              onTap: () => showFiltersSheet(context),
            ),
            _Chip(
              key: const Key('chip_sort'),
              label: sort.label,
              dropdown: true,
              onTap: () async {
                final picked = await showSortSheet(context, sort);
                if (picked != null) ref.read(sortProvider.notifier).set(picked);
              },
            ),
            _Chip(
              key: const Key('chip_price'),
              label: 'Цена',
              dropdown: true,
              selected: filters.hasPrice,
              onTap: () =>
                  showFiltersSheet(context, section: FilterSection.price),
            ),
            _Chip(
              key: const Key('chip_discounts'),
              label: 'Все скидки и бонусы',
              dropdown: true,
              selected: filters.anyDiscount,
              onTap: () =>
                  showFiltersSheet(context, section: FilterSection.discounts),
            ),
            _Chip(
              key: const Key('chip_free_cancel'),
              label: 'Бесплатная отмена',
              selected: filters.freeCancellation,
              onTap: filtersNotifier.toggleFreeCancellation,
            ),
            _Chip(
              key: const Key('chip_breakfast'),
              label: 'С завтраком',
              selected: filters.breakfast,
              onTap: filtersNotifier.toggleBreakfast,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    this.label,
    this.icon,
    this.dropdown = false,
    this.selected = false,
    this.onTap,
  });

  final String? label;
  final IconData? icon;
  final bool dropdown;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.black : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.textPrimary : AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) Icon(icon, size: 20, color: foreground),
                if (label != null)
                  Text(
                    label!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: foreground,
                    ),
                  ),
                if (dropdown)
                  Icon(Icons.arrow_drop_down, size: 22, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
