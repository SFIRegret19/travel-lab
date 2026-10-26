import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../data/mock_data.dart';
import 'search_provider.dart';
import 'widgets/search_tabs.dart';

/// Выбор города: поле ввода, недавние поиски и список регионов.
/// Закрывается с `true`, если пользователь что-то выбрал.
class CitySuggestScreen extends ConsumerStatefulWidget {
  const CitySuggestScreen({super.key});

  @override
  ConsumerState<CitySuggestScreen> createState() => _CitySuggestScreenState();
}

class _CitySuggestScreenState extends ConsumerState<CitySuggestScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pickCity(String city) {
    ref.read(searchProvider.notifier).setCity(city);
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final recent = ref.watch(recentSearchesProvider);
    final query = _query.trim().toLowerCase();
    final cities = [
      for (final c in mockCities)
        if (query.isEmpty || c.toLowerCase().contains(query)) c,
    ];

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const SearchTabs(),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TextField(
            key: const Key('city_field'),
            controller: _controller,
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Город или название',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surfaceHigh,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (query.isEmpty) ...[
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.near_me_outlined, size: 18),
                SizedBox(width: 8),
                Text('Искать жильё рядом со мной'),
              ],
            ),
            const _Header('Продолжить поиск'),
            for (final r in recent)
              _SuggestTile(
                icon: Icons.history_rounded,
                title: r.city ?? '',
                subtitle:
                    '${formatRangeLong(r.checkIn!, r.checkOut!)}'
                    ' · ${formatGuests(r.guests)}',
                onTap: () {
                  ref.read(searchProvider.notifier).apply(r);
                  context.pop(true);
                },
              ),
            const _Header('Регион'),
          ] else
            const SizedBox(height: 16),
          for (final city in cities)
            _SuggestTile(
              icon: Icons.location_on_rounded,
              title: city,
              onTap: () => _pickCity(city),
            ),
          if (cities.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Ничего не найдено',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _SuggestTile extends StatelessWidget {
  const _SuggestTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.textPrimary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16)),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
