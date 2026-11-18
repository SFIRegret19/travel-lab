import 'package:flutter/material.dart';

import '../../api/api_exception.dart';
import '../theme/app_colors.dart';

/// Заголовок и подсказка для ошибки загрузки: по ним пользователь понимает,
/// проблема в сети, на сервере или в самом запросе.
(String title, String hint) describeError(Object error) {
  if (error is ApiException) {
    if (error.isNetwork) {
      return ('Нет соединения', 'Проверьте интернет и повторите попытку');
    }
    if (error.isNotFound) return ('Ничего не найдено', error.message);
    if ((error.status ?? 0) >= 500) {
      return (
        'Сервис недоступен',
        'Что-то пошло не так на нашей стороне. Попробуйте ещё раз',
      );
    }
    return ('Не удалось загрузить', error.message);
  }
  return ('Не удалось загрузить', 'Попробуйте ещё раз');
}

/// Состояние «ошибка» с кнопкой «Повторить»: общее для всех экранов,
/// которые грузят данные с сервера.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.error,
    required this.onRetry,
    this.onBack,
  });

  final Object error;
  final VoidCallback onRetry;

  /// Для ошибок «не найдено», когда повтор не поможет, остаётся «Назад».
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final (title, hint) = describeError(error);
    final e = error;
    final retryable = !(e is ApiException && e.isNotFound);
    return Padding(
      key: const Key('error_state'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceHigh,
            ),
            child: Icon(
              e is ApiException && e.isNetwork
                  ? Icons.wifi_off_rounded
                  : Icons.error_outline_rounded,
              size: 44,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            key: const Key('error_hint'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          if (retryable)
            FilledButton(
              key: const Key('error_retry'),
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          if (onBack != null)
            Padding(
              padding: EdgeInsets.only(top: retryable ? 12 : 0),
              child: TextButton(
                key: const Key('error_back'),
                onPressed: onBack,
                child: const Text('Назад'),
              ),
            ),
        ],
      ),
    );
  }
}
