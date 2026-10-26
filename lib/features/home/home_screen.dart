import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/widgets/placeholder_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Главный',
      description: 'Баннер, строка «Найти жильё или билет», «Продолжить поиск».',
      actions: [
        FilledButton(
          onPressed: () => context.push(Routes.search),
          child: const Text('Найти жильё'),
        ),
      ],
    );
  }
}
