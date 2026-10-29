import 'package:flutter/material.dart';

import '../../../core/format/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../checkout_pricing.dart';

const _shape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
);

/// Модалка «Похоже, цена изменилась». Закрывается только кнопкой «Отлично»
/// или системной кнопкой «назад».
Future<void> showPriceChangedSheet(
  BuildContext context, {
  required int oldPrice,
  required int newPrice,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: AppColors.surface,
    shape: _shape,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Похоже, цена изменилась',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            const Text(
              'Такое иногда бывает, но у нас хорошая новость - цена стала '
              'ниже. Сегодня, однозначно, ваш день!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17),
            ),
            const SizedBox(height: 28),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _PriceTile(
                      title: 'Старая цена',
                      value: formatPrice(oldPrice),
                      titleColor: AppColors.textSecondary,
                      valueStyle: const TextStyle(
                        fontSize: 28,
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PriceTile(
                      title: 'Новая цена',
                      value: formatPrice(newPrice),
                      titleColor: AppColors.ratingGreen,
                      valueStyle: const TextStyle(
                        fontSize: 28,
                        color: AppColors.ratingGreen,
                      ),
                      badge: '−${formatPrice(oldPrice - newPrice)}',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Builder(
              builder: (context) => FilledButton(
                key: const Key('price_changed_ok'),
                onPressed: () => Navigator.pop(context),
                child: const Text('Отлично'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PriceTile extends StatelessWidget {
  const _PriceTile({
    required this.title,
    required this.value,
    required this.titleColor,
    required this.valueStyle,
    this.badge,
  });

  final String title;
  final String value;
  final Color titleColor;
  final TextStyle valueStyle;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      constraints: const BoxConstraints(minHeight: 130),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, color: titleColor)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: valueStyle),
          ),
          if (badge != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.ratingGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge!,
                style: const TextStyle(fontSize: 15, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<String?> showPromoSheet(BuildContext context, {String initial = ''}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: _shape,
    builder: (_) => _PromoSheet(initial: initial),
  );
}

class _PromoSheet extends StatefulWidget {
  const _PromoSheet({required this.initial});

  final String initial;

  @override
  State<_PromoSheet> createState() => _PromoSheetState();
}

class _PromoSheetState extends State<_PromoSheet> {
  late final _controller = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final code = _controller.text.trim().toUpperCase();
    if (promoPercentFor(code) == null) {
      setState(() => _error = 'Промокод не найден');
      return;
    }
    Navigator.pop(context, code);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Введите промокод',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),
              TextField(
                key: const Key('promo_field'),
                controller: _controller,
                autofocus: true,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) {
                  if (_controller.text.trim().isNotEmpty) _apply();
                },
                style: const TextStyle(fontSize: 30),
                decoration: InputDecoration(
                  hintText: 'Промокод',
                  hintStyle: const TextStyle(
                    fontSize: 30,
                    color: AppColors.textSecondary,
                  ),
                  errorText: _error,
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('promo_apply'),
                onPressed: _controller.text.trim().isEmpty ? null : _apply,
                style: FilledButton.styleFrom(
                  disabledBackgroundColor: AppColors.background,
                  disabledForegroundColor: AppColors.textSecondary,
                ),
                child: const Text('Применить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
