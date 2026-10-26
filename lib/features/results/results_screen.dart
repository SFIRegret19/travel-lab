import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/widgets/placeholder_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Результаты',
      description: 'Чипы фильтров, сортировка, список отелей.',
      actions: [
        FilledButton(
          onPressed: () => context.push(Routes.hotelPath('1')),
          child: const Text('Открыть отель'),
        ),
      ],
    );
  }
}
