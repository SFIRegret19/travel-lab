import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/hotels_catalog.dart';
import '../../../data/models/hotel.dart';
import '../../search/search_provider.dart';
import '../results_state.dart';

enum FilterSection { top, price, discounts }

/// Шторка «Фильтры». Работает с черновиком: «Применить» сохраняет выбор,
/// крестик или свайп вниз отбрасывают.
Future<void> showFiltersSheet(
  BuildContext context, {
  FilterSection section = FilterSection.top,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _FiltersSheet(section: section),
  );
}

/// Число отелей каталога с данной опцией. Другие фильтры не учитываются.
int _count(bool Function(Hotel) test) => hotelsCatalog.where(test).length;

class _FiltersSheet extends ConsumerStatefulWidget {
  const _FiltersSheet({required this.section});

  final FilterSection section;

  @override
  ConsumerState<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<_FiltersSheet> {
  late HotelFilters _draft;
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  final _priceKey = GlobalKey();
  final _discountsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _draft = ref.read(filtersProvider);
    _syncFields();

    final target = switch (widget.section) {
      FilterSection.top => null,
      FilterSection.price => _priceKey,
      FilterSection.discounts => _discountsKey,
    };
    if (target != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = target.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 250),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _syncFields() {
    _minController.text = _draft.priceMin > 0 ? '${_draft.priceMin}' : '';
    _maxController.text = _draft.priceMax < priceCap
        ? '${_draft.priceMax}'
        : '';
  }

  void _update(HotelFilters next) => setState(() => _draft = next);

  void _onMinTyped(String text) {
    final value = (int.tryParse(text) ?? 0).clamp(0, priceCap);
    _update(_draft.copyWith(priceMin: value));
  }

  void _onMaxTyped(String text) {
    final value = text.isEmpty
        ? priceCap
        : (int.tryParse(text) ?? priceCap).clamp(0, priceCap);
    _update(_draft.copyWith(priceMax: value));
  }

  void _onSlider(RangeValues values) {
    int round(double v) => (v / 100).round() * 100;
    _update(
      _draft.copyWith(
        priceMin: round(values.start),
        priceMax: round(values.end),
      ),
    );
    _syncFields();
  }

  void _apply() {
    ref.read(filtersProvider.notifier).apply(_draft);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final params = ref.watch(searchProvider);
    final sort = ref.watch(sortProvider);
    final found = applyResults(hotelsCatalog, params, _draft, sort).length;

    final start = _draft.priceMin.clamp(0, _draft.priceMax).toDouble();
    final end = _draft.priceMax.toDouble();

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        heightFactor: 1,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Фильтры',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    key: const Key('filters_close'),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceHigh,
                    ),
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const Key('filters_scroll'),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Chips(
                      children: [
                        _OptionChip(
                          key: const Key('quick_discount'),
                          label: 'Все скидки и бонусы',
                          count: _count((h) => h.oldPrice != null),
                          selected: _draft.anyDiscount,
                          onTap: () => _update(
                            _draft.copyWith(anyDiscount: !_draft.anyDiscount),
                          ),
                        ),
                        _OptionChip(
                          key: const Key('quick_breakfast'),
                          label: 'Включён завтрак',
                          count: _count((h) => h.breakfast),
                          selected: _draft.breakfast,
                          onTap: () => _update(
                            _draft.copyWith(breakfast: !_draft.breakfast),
                          ),
                        ),
                        _OptionChip(
                          key: const Key('quick_free_cancel'),
                          label: 'Бесплатная отмена',
                          count: _count((h) => h.freeCancellation),
                          selected: _draft.freeCancellation,
                          onTap: () => _update(
                            _draft.copyWith(
                              freeCancellation: !_draft.freeCancellation,
                            ),
                          ),
                        ),
                        for (final s in const [5, 4])
                          _OptionChip(
                            key: Key('quick_stars_$s'),
                            label: s == 5 ? '5 звёзд' : '4 звезды',
                            count: _count((h) => h.stars == s),
                            selected: _draft.stars.contains(s),
                            onTap: () => _update(_draft.toggleStars(s)),
                          ),
                      ],
                    ),
                    _Section(
                      sectionKey: _priceKey,
                      title: 'Цена за все ночи',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _PriceField(
                                  key: const Key('price_min'),
                                  controller: _minController,
                                  prefix: 'от ',
                                  hint: 'от 0 ₽',
                                  onChanged: _onMinTyped,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _PriceField(
                                  key: const Key('price_max'),
                                  controller: _maxController,
                                  prefix: 'до ',
                                  hint: 'до 60 000+ ₽',
                                  onChanged: _onMaxTyped,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2,
                              activeTrackColor: AppColors.textPrimary,
                              inactiveTrackColor: AppColors.textSecondary,
                              rangeThumbShape: const _RingThumbShape(),
                              overlayColor: AppColors.textPrimary.withValues(
                                alpha: .12,
                              ),
                            ),
                            child: RangeSlider(
                              key: const Key('price_slider'),
                              values: RangeValues(start, end),
                              max: priceCap.toDouble(),
                              divisions: priceCap ~/ 100,
                              onChanged: _onSlider,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Section(
                      sectionKey: _discountsKey,
                      title: 'Скидки и бонусы',
                      child: _Chips(
                        children: [
                          _OptionChip(
                            key: const Key('opt_discount'),
                            label: 'Все скидки и бонусы',
                            count: _count((h) => h.oldPrice != null),
                            selected: _draft.anyDiscount,
                            onTap: () => _update(
                              _draft.copyWith(anyDiscount: !_draft.anyDiscount),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Section(
                      title: 'Тип размещения',
                      child: _Chips(
                        children: [
                          for (final type in const [
                            'Гостиница',
                            'Мини-отель',
                            'Хостел',
                            'Апартаменты',
                          ])
                            _OptionChip(
                              key: Key('opt_type_$type'),
                              label: type,
                              count: _count((h) => h.type == type),
                              selected: _draft.types.contains(type),
                              onTap: () => _update(_draft.toggleType(type)),
                            ),
                        ],
                      ),
                    ),
                    _Section(
                      title: 'Питание',
                      child: _Chips(
                        children: [
                          for (final meal in MealPlan.values)
                            _OptionChip(
                              key: Key('opt_meal_${meal.name}'),
                              label: meal.label,
                              count: _count((h) => h.meal == meal),
                              selected: _draft.meals.contains(meal),
                              onTap: () => _update(_draft.toggleMeal(meal)),
                            ),
                        ],
                      ),
                    ),
                    _Section(
                      title: 'Оплата и бронирование',
                      child: _Chips(
                        children: [
                          _OptionChip(
                            key: const Key('opt_free_cancel'),
                            label: 'Бесплатная отмена',
                            count: _count((h) => h.freeCancellation),
                            selected: _draft.freeCancellation,
                            onTap: () => _update(
                              _draft.copyWith(
                                freeCancellation: !_draft.freeCancellation,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Section(
                      title: 'Рейтинг',
                      child: _Chips(
                        children: [
                          for (final (label, value) in const [
                            ('Очень хорошо (4.5+)', 4.5),
                            ('Хорошо (4+)', 4.0),
                            ('Приемлемо (3+)', 3.0),
                          ])
                            _OptionChip(
                              key: Key('opt_rating_$value'),
                              label: label,
                              count: _count((h) => h.rating >= value),
                              selected: _draft.minRating == value,
                              onTap: () =>
                                  _update(_draft.toggleMinRating(value)),
                            ),
                        ],
                      ),
                    ),
                    _Section(
                      title: 'Звёздность',
                      child: _Chips(
                        children: [
                          for (var s = 0; s <= 5; s++)
                            _OptionChip(
                              key: Key('opt_stars_$s'),
                              label: s == 0 ? 'Без звёзд' : '$s*',
                              count: _count((h) => h.stars == s),
                              selected: _draft.stars.contains(s),
                              onTap: () => _update(_draft.toggleStars(s)),
                            ),
                        ],
                      ),
                    ),
                    _Section(
                      title: 'Общие удобства',
                      child: _Chips(
                        children: [
                          _OptionChip(
                            key: const Key('opt_wifi'),
                            label: 'Wi-Fi',
                            icon: Icons.wifi_rounded,
                            count: _count((h) => h.wifi),
                            selected: _draft.wifi,
                            onTap: () =>
                                _update(_draft.copyWith(wifi: !_draft.wifi)),
                          ),
                          _OptionChip(
                            key: const Key('opt_parking'),
                            label: 'Парковка',
                            icon: Icons.local_parking_rounded,
                            count: _count((h) => h.parking),
                            selected: _draft.parking,
                            onTap: () => _update(
                              _draft.copyWith(parking: !_draft.parking),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatFoundOffers(found),
                      key: const Key('filters_count'),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      key: const Key('filters_apply'),
                      onPressed: _apply,
                      child: const Text('Применить'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatefulWidget {
  const _Section({required this.title, required this.child, this.sectionKey});

  final String title;
  final Widget child;
  final GlobalKey? sectionKey;

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: widget.sectionKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.arrow_drop_up_rounded
                        : Icons.arrow_drop_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) widget.child,
        ],
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: children);
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.black : AppColors.textPrimary;
    final secondary = selected ? Colors.black54 : AppColors.textSecondary;
    return Material(
      color: selected ? AppColors.textPrimary : AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 6),
              ],
              Text(label, style: TextStyle(fontSize: 15, color: foreground)),
              const SizedBox(width: 6),
              Text('$count', style: TextStyle(fontSize: 13, color: secondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingThumbShape extends RangeSliderThumbShape {
  const _RingThumbShape();

  static const _radius = 13.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    Thumb? thumb,
    bool? isPressed,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(center, _radius, Paint()..color = AppColors.surface);
    canvas.drawCircle(
      center,
      _radius - 1,
      Paint()
        ..color = AppColors.textPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}

class _PriceField extends StatelessWidget {
  const _PriceField({
    super.key,
    required this.controller,
    required this.prefix,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String prefix;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    // «от»/«до» и «₽» показываем только при введённом значении: иначе Flutter
    // резервирует под них место и подсказка обрезается.
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => _field(value.text.isNotEmpty),
    );
  }

  Widget _field(bool hasText) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        prefixText: hasText ? prefix : null,
        prefixStyle: const TextStyle(
          fontSize: 18,
          color: AppColors.textSecondary,
        ),
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 18,
          color: AppColors.textSecondary,
        ),
        suffixText: hasText ? ' ₽' : null,
        suffixStyle: const TextStyle(fontSize: 18),
        filled: true,
        fillColor: AppColors.surfaceHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
