import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../search_provider.dart';

class GuestsPanel extends ConsumerWidget {
  const GuestsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);

    return Column(
      children: [
        _CounterRow(
          keyPrefix: 'adults',
          title: 'Взрослые',
          subtitle: 'от 18 лет',
          value: params.adults,
          canDecrement: params.adults > 1,
          canIncrement: params.adults < maxAdults,
          onChanged: notifier.setAdults,
        ),
        _CounterRow(
          keyPrefix: 'children',
          title: 'Дети',
          subtitle: 'до 18 лет',
          value: params.children,
          canDecrement: params.children > 0,
          canIncrement: params.children < maxChildren,
          onChanged: notifier.setChildren,
        ),
        _CounterRow(
          keyPrefix: 'rooms',
          title: 'Номера',
          subtitle: 'или комнаты',
          value: params.rooms,
          canDecrement: params.rooms > 1,
          canIncrement: params.rooms < params.adults,
          onChanged: notifier.setRooms,
        ),
        const _DistributeRow(),
      ],
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.keyPrefix,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.canDecrement,
    required this.canIncrement,
    required this.onChanged,
  });

  final String keyPrefix;
  final String title;
  final String subtitle;
  final int value;
  final bool canDecrement;
  final bool canIncrement;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16)),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _StepButton(
            key: Key('${keyPrefix}_minus'),
            icon: Icons.remove,
            enabled: canDecrement,
            onTap: () => onChanged(value - 1),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          _StepButton(
            key: Key('${keyPrefix}_plus'),
            icon: Icons.add,
            enabled: canIncrement,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: AppColors.textPrimary.withValues(alpha: enabled ? 1 : .3),
          ),
        ),
      ),
    );
  }
}

class _DistributeRow extends StatefulWidget {
  const _DistributeRow();

  @override
  State<_DistributeRow> createState() => _DistributeRowState();
}

class _DistributeRowState extends State<_DistributeRow> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Распределить гостей', style: TextStyle(fontSize: 16)),
                Text(
                  'По номерам',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: _value, onChanged: (v) => setState(() => _value = v)),
        ],
      ),
    );
  }
}
