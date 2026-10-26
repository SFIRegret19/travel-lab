import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/widgets/placeholder_screen.dart';

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Подтверждение',
      description: 'Бронирование оформлено (в оригинале экран не снят, рисуем сами).',
      actions: [
        FilledButton(
          onPressed: () => context.go(Routes.home),
          child: const Text('На главный'),
        ),
      ],
    );
  }
}
