import 'package:flutter/material.dart';

import '../../../core/format/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/edge_fade.dart';
import '../../hotel/widgets/section_card.dart';
import '../checkout_pricing.dart';

enum PayMode { full, split }

class PayMethod {
  const PayMethod(this.title, this.caption, this.label, this.icon);

  final String title;
  final String caption;
  final String label;
  final IconData icon;
}

const payMethods = [
  PayMethod(
    'Mastercard',
    '•• 4821',
    'Mastercard •• 4821',
    Icons.credit_card_rounded,
  ),
  PayMethod('СБП', 'Без карты', 'СБП', Icons.qr_code_2_rounded),
  PayMethod('Мир', '•• 7305', 'Мир •• 7305', Icons.credit_card_rounded),
];

class PaymentCard extends StatelessWidget {
  const PaymentCard({
    super.key,
    required this.mode,
    required this.onMode,
    required this.splitPart,
    required this.method,
    required this.onMethod,
  });

  final PayMode mode;
  final ValueChanged<PayMode> onMode;
  final int splitPart;
  final int method;
  final ValueChanged<int> onMethod;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Способы оплаты',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ModeRow(
            key: const Key('pay_mode_full'),
            selected: mode == PayMode.full,
            title: 'Оплатить всю сумму сейчас',
            onTap: () => onMode(PayMode.full),
          ),
          const SizedBox(height: 20),
          _ModeRow(
            key: const Key('pay_mode_split'),
            selected: mode == PayMode.split,
            title: 'Частями в Сплит',
            subtitle: '${formatPrice(splitPart)} × 4 платежа',
            onTap: () => onMode(PayMode.split),
          ),
          const Divider(height: 36),
          EdgeFade(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < payMethods.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        right: i == payMethods.length - 1 ? 0 : 10,
                      ),
                      child: _MethodTile(
                        key: Key('pay_method_$i'),
                        method: payMethods[i],
                        selected: i == method,
                        onTap: () => onMethod(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    super.key,
    required this.selected,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.textPrimary : AppColors.surfaceHigh,
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18)),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    super.key,
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PayMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: 150,
          height: 112,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppColors.textPrimary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(method.icon, size: 28),
              const Spacer(),
              Text(
                method.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                method.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PriceSummaryCard extends StatelessWidget {
  const PriceSummaryCard({
    super.key,
    required this.price,
    required this.nights,
    required this.promo,
    required this.onPromo,
    required this.onRemovePromo,
  });

  final CheckoutPrice price;
  final int nights;
  final String? promo;
  final VoidCallback onPromo;
  final VoidCallback onRemovePromo;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Ваше бронирование',
      child: Column(
        children: [
          _Line(formatNights(nights), formatPrice(price.gross)),
          if (price.discount > 0)
            _Line('Скидка', '− ${formatPrice(price.discount)}'),
          if (price.late > 0)
            _Line('Поздний выезд', '+ ${formatPrice(price.late)}'),
          if (promo != null)
            _Line(
              'Промокод $promo',
              '− ${formatPrice(price.promo)}',
              key: const Key('summary_promo'),
            ),
          const Divider(height: 28),
          InkWell(
            key: const Key('promo_row'),
            onTap: onPromo,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_outlined, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      promo ?? 'Промокод',
                      style: const TextStyle(fontSize: 19),
                    ),
                  ),
                  if (promo != null)
                    IconButton(
                      key: const Key('promo_remove'),
                      onPressed: onRemovePromo,
                      icon: const Icon(Icons.close_rounded),
                    )
                  else
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Expanded(
                child: Text('К оплате', style: TextStyle(fontSize: 20)),
              ),
              Text(
                formatPrice(price.total),
                key: const Key('checkout_total'),
                style: const TextStyle(fontSize: 34),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.title, this.value, {super.key});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 19))),
          Text(value, style: const TextStyle(fontSize: 19)),
        ],
      ),
    );
  }
}
