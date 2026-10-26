/// Пути экранов основного сценария.
abstract final class Routes {
  static const home = '/';
  static const search = '/search';
  static const citySuggest = '/search/city';
  static const results = '/results';
  static const hotel = '/hotel/:id';
  static const rooms = '/hotel/:id/rooms';
  static const reviews = '/hotel/:id/reviews';
  static const checkout = '/checkout';
  static const confirmation = '/confirmation';

  static String hotelPath(String id) => '/hotel/$id';
  static String roomsPath(String id) => '/hotel/$id/rooms';
  static String reviewsPath(String id) => '/hotel/$id/reviews';
}
