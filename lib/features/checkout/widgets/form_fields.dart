import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

/// Поле формы с подчёркиванием и кнопкой очистки справа. [name] входит
/// в ключи: `field_<name>` и `clear_<name>`.
class ClearableField extends StatelessWidget {
  const ClearableField({
    super.key,
    required this.name,
    required this.label,
    required this.controller,
    required this.focusNode,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
  });

  final String name;
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: Key('field_$name'),
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: (_) => onChanged?.call(),
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        errorText: errorText,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.textPrimary),
        ),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  key: Key('clear_$name'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    controller.clear();
                    onChanged?.call();
                  },
                  child: const SizedBox(
                    width: 40,
                    height: 36,
                    child: Icon(Icons.close_rounded, size: 20),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
