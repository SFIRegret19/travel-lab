import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/widgets/placeholder_screen.dart';

class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key, required this.hotelId});

  final String hotelId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Выбор номера',
      description: 'Список номеров и тарифов, условия отмены. Отель №$hotelId.',
      actions: [
        FilledButton(
          onPressed: () => context.push(Routes.checkout),
          child: const Text('Выбрать'),
        ),
      ],
    );
  }
}
