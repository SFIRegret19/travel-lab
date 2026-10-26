/// Краткая карточка отеля: то, что видно в списках.
class Hotel {
  const Hotel({
    required this.id,
    required this.name,
    required this.rating,
    required this.address,
    required this.type,
    required this.price,
    this.oldPrice,
    this.imageHue = 30,
  });

  final String id;
  final String name;
  final double rating;
  final String address;
  final String type;
  final int price;
  final int? oldPrice;

  /// Оттенок градиента-заглушки вместо фото (0–360).
  final double imageHue;
}
