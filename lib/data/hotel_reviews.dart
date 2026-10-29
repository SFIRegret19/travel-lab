import 'models/hotel.dart';

class Review {
  const Review({
    required this.author,
    required this.date,
    required this.rating,
    required this.liked,
    required this.stay,
    this.regular = false,
    this.reply,
  });

  final String author;
  final DateTime date;
  final int rating;
  final String liked;

  final String stay;

  final bool regular;

  final String? reply;
}

final _pool = <Review>[
  Review(
    author: 'Анна К.',
    date: DateTime(2026, 9, 9),
    rating: 5,
    liked: 'Чисто, тихо и очень удобно добираться от вокзала.',
    stay: 'сентябрь 2026 · 1 ночь',
    regular: true,
    reply: 'Спасибо, что выбрали нас! Будем рады видеть вас снова.',
  ),
  Review(
    author: 'Михаил',
    date: DateTime(2026, 8, 21),
    rating: 4,
    liked: 'Приветливый персонал, быстрый заезд. Кофе в холле порадовал.',
    stay: 'август 2026 · 2 ночи',
  ),
  Review(
    author: 'Елена С.',
    date: DateTime(2026, 8, 2),
    rating: 5,
    liked: 'Хорошая цена за такое расположение, всё соответствует фото.',
    stay: 'август 2026 · 3 ночи',
    regular: true,
  ),
  Review(
    author: 'Дмитрий',
    date: DateTime(2026, 7, 14),
    rating: 4,
    liked: 'Удобная кровать, быстрый интернет, рядом много кафе.',
    stay: 'июль 2026 · 1 ночь',
    reply: 'Благодарим за отзыв, нам важно ваше мнение.',
  ),
  Review(
    author: 'Ольга',
    date: DateTime(2026, 6, 30),
    rating: 5,
    liked: 'Отличный сервис и вежливые сотрудники. Рекомендую.',
    stay: 'июнь 2026 · 2 ночи',
  ),
  Review(
    author: 'Сергей П.',
    date: DateTime(2026, 6, 5),
    rating: 3,
    liked: 'В целом неплохо, но хотелось бы тише по вечерам.',
    stay: 'июнь 2026 · 1 ночь',
  ),
];

/// Порядок зависит от id, чтобы у разных отелей отзывы не совпадали.
List<Review> reviewsFor(Hotel h) {
  final seed = int.tryParse(h.id) ?? h.id.hashCode.abs();
  final shift = seed % _pool.length;
  return [..._pool.skip(shift), ..._pool.take(shift)];
}
