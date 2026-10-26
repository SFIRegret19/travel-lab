import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/formatters.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import 'search_params.dart';
import 'search_provider.dart';
import 'widgets/guests_panel.dart';
import 'widgets/range_calendar.dart';
import 'widgets/search_tabs.dart';

enum _Section { where, when, guests }

/// Форма поиска: три раскрывающиеся секции (где, когда, гости).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.editMode = false});

  /// Форма открыта из выдачи для правки поиска: «Найти» возвращает к ней.
  final bool editMode;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  _Section _open = _Section.where;

  void _openSection(_Section section) => setState(() => _open = section);

  Future<void> _pickCity() async {
    final picked = await context.push<bool>(Routes.citySuggest);
    if (picked == true && mounted) _openSection(_Section.when);
  }

  @override
  Widget build(BuildContext context) {
    final params = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: SearchTabs(showUnderline: _open != _Section.where),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                if (_open == _Section.where) ...[
                  const SearchModeIcons(),
                  const SizedBox(height: 16),
                ],
                _SectionCard(
                  sectionKey: const Key('section_where'),
                  expanded: _open == _Section.where,
                  label: 'Где',
                  summary: _Summary(
                    params.city ?? 'Где будете жить?',
                    params.type.label,
                    placeholder: params.city == null,
                  ),
                  onOpen: () => _openSection(_Section.where),
                  title: 'Где будете жить?',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final t in AccommodationType.values)
                            ChoiceChip(
                              key: Key('type_${t.name}'),
                              label: Text(t.label),
                              selected: params.type == t,
                              showCheckmark: false,
                              onSelected: (_) => notifier.setType(t),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        key: const Key('city_input'),
                        borderRadius: BorderRadius.circular(16),
                        onTap: _pickCity,
                        child: Container(
                          height: 56,
                          width: double.infinity,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            params.city ?? 'Город или название',
                            style: TextStyle(
                              fontSize: 16,
                              color: params.city == null
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _SectionCard(
                  sectionKey: const Key('section_when'),
                  expanded: _open == _Section.when,
                  label: 'Когда',
                  summary: _Summary(
                    formatRangeShort(params.checkIn, params.checkOut),
                    null,
                    placeholder: params.checkIn == null,
                  ),
                  onOpen: () => _openSection(_Section.when),
                  title: 'Когда',
                  child: const RangeCalendar(),
                ),
                const SizedBox(height: 8),
                _SectionCard(
                  sectionKey: const Key('section_guests'),
                  expanded: _open == _Section.guests,
                  label: 'Гости',
                  summary: _Summary(formatGuests(params.guests), null),
                  onOpen: () => _openSection(_Section.guests),
                  title: 'Гости',
                  child: const GuestsPanel(),
                ),
              ],
            ),
          ),
          _BottomBar(
            calendarOpen: _open == _Section.when,
            params: params,
            onNext: () => _openSection(_Section.guests),
            onSearch: () => widget.editMode
                ? context.pop()
                : context.push(Routes.results, extra: true),
          ),
        ],
      ),
    );
  }
}

class _Summary {
  const _Summary(this.primary, this.secondary, {this.placeholder = false});

  final String primary;
  final String? secondary;
  final bool placeholder;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.sectionKey,
    required this.expanded,
    required this.label,
    required this.summary,
    required this.onOpen,
    required this.title,
    required this.child,
  });

  final Key sectionKey;
  final bool expanded;
  final String label;
  final _Summary summary;
  final VoidCallback onOpen;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: sectionKey,
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: expanded
            ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    child,
                  ],
                ),
              )
            : InkWell(
                onTap: onOpen,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: Row(
                    children: [
                      Text(label, style: const TextStyle(fontSize: 16)),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            summary.primary,
                            style: TextStyle(
                              fontSize: 16,
                              color: summary.placeholder
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (summary.secondary != null)
                            Text(
                              summary.secondary!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.calendarOpen,
    required this.params,
    required this.onNext,
    required this.onSearch,
  });

  final bool calendarOpen;
  final SearchParams params;
  final VoidCallback onNext;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final hint = params.checkIn == null
        ? 'Укажите дату заезда'
        : 'Укажите дату выезда';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (calendarOpen && !params.hasFullRange)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            if (calendarOpen)
              FilledButton(
                key: const Key('next_button'),
                onPressed: params.hasFullRange ? onNext : null,
                child: const Text('Дальше'),
              )
            else
              FilledButton(
                key: const Key('search_button'),
                onPressed: onSearch,
                child: const Text('Найти'),
              ),
          ],
        ),
      ),
    );
  }
}
