const _shortMonths = [
  'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
  'июл', 'авг', 'сен', 'окт', 'ноя', 'дек', //
];

const _genitiveMonths = [
  'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря', //
];

const monthNames = [
  'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
  'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь', //
];

String formatRangeShort(DateTime? from, DateTime? to) {
  if (from == null) return 'Заезд — выезд';
  final start = '${from.day} ${_shortMonths[from.month - 1]}';
  if (to == null) return '$start — выезд';
  if (from.month == to.month) {
    return '${from.day} — ${to.day} ${_shortMonths[to.month - 1]}';
  }
  return '$start — ${to.day} ${_shortMonths[to.month - 1]}';
}

String formatRangeLong(DateTime from, DateTime to) {
  if (from.month == to.month) {
    return '${from.day} - ${to.day} ${_genitiveMonths[to.month - 1]}';
  }
  return '${from.day} ${_genitiveMonths[from.month - 1]} - '
      '${to.day} ${_genitiveMonths[to.month - 1]}';
}

String _plural(int n, String one, String few, String many) {
  final mod100 = n % 100;
  final mod10 = n % 10;
  if (mod100 >= 11 && mod100 <= 14) return many;
  if (mod10 == 1) return one;
  if (mod10 >= 2 && mod10 <= 4) return few;
  return many;
}

String formatNights(int n) => '$n ${_plural(n, 'ночь', 'ночи', 'ночей')}';

String formatReviews(int n) => '$n ${_plural(n, 'отзыв', 'отзыва', 'отзывов')}';

String formatFoundOffers(int n) =>
    'Нашли $n ${_plural(n, 'предложение', 'предложения', 'предложений')}';

String formatRoomsLeft(int n) =>
    'Осталось $n ${_plural(n, 'номер', 'номера', 'номеров')}';

String formatDayMonth(DateTime d) => '${d.day} ${_shortMonths[d.month - 1]}';

const _weekdays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

String formatDayWeekday(DateTime d) =>
    '${formatDayMonth(d)}, ${_weekdays[d.weekday - 1]}';

String formatDays(int n) => '$n ${_plural(n, 'день', 'дня', 'дней')}';

String formatDistance(double km) =>
    '${km.toStringAsFixed(1).replaceAll('.', ',')} км до центра';

String formatGuests(int n) => '$n ${_plural(n, 'гость', 'гостя', 'гостей')}';

/// Цена с неразрывными пробелами: «1 975 ₽».
String formatPrice(int rubles) {
  final digits = rubles.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return '$buffer ₽';
}
