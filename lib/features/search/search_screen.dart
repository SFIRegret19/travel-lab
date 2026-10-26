import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/widgets/placeholder_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Где будете жить?',
      description: 'Город, даты заезда и выезда, гости.',
      actions: [
        FilledButton(
          onPressed: () => context.push(Routes.results),
          child: const Text('Найти'),
        ),
      ],
    );
  }
}
