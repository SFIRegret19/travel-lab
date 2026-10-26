import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Блок страницы отеля: тёмная карточка со скруглением и необязательным
/// заголовком.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.titleWidget,
    required this.child,
  });

  final String? title;
  final Widget? titleWidget;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final heading =
        titleWidget ??
        (title == null
            ? null
            : Text(
                title!,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (heading != null) ...[heading, const SizedBox(height: 14)],
          child,
        ],
      ),
    );
  }
}
