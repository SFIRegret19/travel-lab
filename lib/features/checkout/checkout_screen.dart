import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/widgets/placeholder_screen.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Оформление',
      description: 'Гость, контакты, способ оплаты, промокод.',
      actions: [
        FilledButton(
          onPressed: () => context.go(Routes.confirmation),
          child: const Text('Оплатить'),
        ),
      ],
    );
  }
}
