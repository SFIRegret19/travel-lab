import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SearchModeIcons extends StatelessWidget {
  const SearchModeIcons({super.key});

  @override
  Widget build(BuildContext context) {
    const icons = [
      Icons.bed_rounded,
      Icons.flight_rounded,
      Icons.train_rounded,
      Icons.celebration_rounded,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < icons.length; i++)
          Container(
            width: 52,
            height: 52,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == 0 ? AppColors.accent : AppColors.surfaceHigh,
            ),
            child: Icon(
              icons[i],
              color: i == 0 ? AppColors.onAccent : AppColors.textPrimary,
            ),
          ),
      ],
    );
  }
}

/// Активна только «Жильё», остальные вне сценария и не нажимаются.
class SearchTabs extends StatelessWidget {
  const SearchTabs({super.key, this.showUnderline = true});

  final bool showUnderline;

  @override
  Widget build(BuildContext context) {
    const tabs = ['Жильё', 'Авиа', 'Поезда', 'Выходные'];
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < tabs.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tabs[i],
                    style: TextStyle(
                      fontSize: 14,
                      color: i == 0
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 18,
                    height: 3,
                    decoration: BoxDecoration(
                      color: i == 0 && showUnderline
                          ? AppColors.accent
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
