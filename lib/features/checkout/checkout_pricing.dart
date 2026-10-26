/// Промокоды демо-режима: код в верхнем регистре и скидка в процентах.
const promoCodes = {'LAB10': 10};

/// Процент скидки по промокоду или null, если такого кода нет.
int? promoPercentFor(String code) => promoCodes[code.trim().toUpperCase()];

/// Цена на оформлении после «Похоже, цена изменилась»: на 5 % ниже той,
/// что была на экране номеров (1 089 → 1 035).
int priceAfterChange(int shown) => shown - (shown * 0.05).round();

/// Расчёт блока «Ваше бронирование». Все строки считаются разностями от
/// одной суммы, чтобы они сходились с «К оплате» до рубля.
class CheckoutPrice {
  const CheckoutPrice({
    required this.shownTotal,
    required this.discountPercent,
    this.lateCheckout = false,
    this.lateCheckoutPrice = 0,
    this.promoPercent = 0,
  });

  /// Сумма за весь срок, которую гость видел на экране номеров.
  final int shownTotal;

  /// Скидка тарифа в процентах, null — без скидки.
  final int? discountPercent;
  final bool lateCheckout;
  final int lateCheckoutPrice;
  final int promoPercent;

  /// Новая цена после пересчёта на оформлении.
  int get current => priceAfterChange(shownTotal);

  /// Строка «N ночей»: цена до скидки тарифа.
  int get gross {
    final p = discountPercent;
    return p == null ? current : (current / (1 - p / 100)).round();
  }

  int get discount => gross - current;
  int get promo => (current * promoPercent / 100).round();
  int get late => lateCheckout ? lateCheckoutPrice : 0;

  /// «К оплате».
  int get total => gross - discount - promo + late;

  /// Первый платёж при оплате частями: сумма на 4, с округлением вверх.
  int get splitPart => (total / 4).ceil();
}
