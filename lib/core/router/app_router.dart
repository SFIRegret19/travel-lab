import 'package:go_router/go_router.dart';

import '../../features/checkout/checkout_screen.dart';
import '../../features/confirmation/confirmation_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/hotel/hotel_screen.dart';
import '../../features/hotel/reviews_screen.dart';
import '../../features/results/results_screen.dart';
import '../../features/rooms/rooms_screen.dart';
import '../../features/search/city_suggest_screen.dart';
import '../../features/search/search_screen.dart';
import 'routes.dart';

final appRouter = GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: Routes.search,
      builder: (_, state) => SearchScreen(editMode: state.extra == true),
    ),
    GoRoute(
      path: Routes.citySuggest,
      builder: (_, _) => const CitySuggestScreen(),
    ),
    GoRoute(
      path: Routes.results,
      builder: (_, state) => ResultsScreen(fromSearch: state.extra == true),
    ),
    GoRoute(
      path: Routes.hotel,
      builder: (_, state) => HotelScreen(hotelId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: Routes.reviews,
      builder: (_, state) =>
          ReviewsScreen(hotelId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: Routes.rooms,
      builder: (_, state) => RoomsScreen(hotelId: state.pathParameters['id']!),
    ),
    GoRoute(path: Routes.checkout, builder: (_, _) => const CheckoutScreen()),
    GoRoute(
      path: Routes.confirmation,
      builder: (_, _) => const ConfirmationScreen(),
    ),
  ],
);
