import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/widgets/placeholder_screen.dart';

class HotelScreen extends StatelessWidget {
  const HotelScreen({super.key, required this.hotelId});

  final String hotelId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Карточка отеля',
      description: 'Фото, рейтинг, удобства, отзывы, правила. Отель №$hotelId.',
      actions: [
        FilledButton(
          onPressed: () => context.push(Routes.roomsPath(hotelId)),
          child: const Text('Выбрать номер'),
        ),
      ],
    );
  }
}
