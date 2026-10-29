import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

const _midGreen = Color(0xFF889A46);

class CategoryBars extends StatelessWidget {
  const CategoryBars({super.key, required this.scores});

  final List<(String, int)> scores;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 14,
      children: [
        for (final (label, value) in scores)
          LayoutBuilder(
            builder: (context, _) => SizedBox(
              width: (MediaQuery.sizeOf(context).width - 32 - 32 - 20) / 2,
              child: _Bar(label: label, value: value),
            ),
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Text('$value %', style: const TextStyle(fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 4,
            backgroundColor: AppColors.surfaceHigh,
            color: value >= 85 ? AppColors.ratingGreen : _midGreen,
          ),
        ),
      ],
    );
  }
}
