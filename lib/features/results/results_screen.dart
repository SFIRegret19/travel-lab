import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/formatters.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../search/search_provider.dart';
import 'results_state.dart';
import 'widgets/filter_chips_bar.dart';
import 'widgets/hotel_result_card.dart';
import 'widgets/map_banner.dart';
import 'widgets/price_info_sheet.dart';
import 'widgets/results_loading.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key, this.fromSearch = false});

  /// Экран открыт из формы поиска: строка поиска в шапке возвращает назад.
  /// Иначе (например, с главного) она открывает форму в режиме правки.
  final bool fromSearch;

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  Timer? _timer;
  bool _loading = false;
  String _fact = '';

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startLoading() {
    _timer?.cancel();
    final duration = ref.read(resultsLoadDurationProvider);
    _loading = duration > Duration.zero;
    if (!_loading) return;
    _fact = randomLoadingFact();
    _timer = Timer(duration, () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Поиск изменили (правка из шапки): выдача «перезагружается».
    ref.listen(searchProvider, (_, _) => setState(_startLoading));

    final params = ref.watch(searchProvider);
    final hotels = ref.watch(resultsProvider);
    final favorites = ref.watch(favoritesProvider);
    final city = params.city ?? 'Везде';
    final fromSearch = widget.fromSearch;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 72,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            shape: _loading
                ? null
                : const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                  ),
            leading: IconButton(
              key: const Key('results_back'),
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: _SearchPill(
              city: city,
              dates: formatRangeShort(params.checkIn, params.checkOut),
              guests: params.guests,
              onTap: () => fromSearch
                  ? context.pop()
                  : context.push(Routes.search, extra: true),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(FilterChipsBar.height),
              child: _loading
                  ? const LoadingChipsBar()
                  : const FilterChipsBar(),
            ),
          ),
          if (_loading)
            SliverFillRemaining(
              hasScrollBody: false,
              child: ResultsLoading(fact: _fact),
            )
          else ...[
            const SliverToBoxAdapter(child: MapBanner()),
            if (hotels.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )
            else
              SliverList.builder(
                itemCount: hotels.length,
                itemBuilder: (context, i) {
                  final hotel = hotels[i];
                  return HotelResultCard(
                    key: Key('hotel_card_${hotel.id}'),
                    hotel: hotel,
                    city: params.displayCity,
                    nights: params.nights,
                    favorite: favorites.contains(hotel.id),
                    onTap: () => context.push(Routes.hotelPath(hotel.id)),
                    onFavorite: () =>
                        ref.read(favoritesProvider.notifier).toggle(hotel.id),
                    onPriceInfo: () =>
                        showPriceInfoSheet(context, hotel, params.nights),
                  );
                },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ],
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({
    required this.city,
    required this.dates,
    required this.guests,
    required this.onTap,
  });

  final String city;
  final String dates;
  final int guests;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const secondary = TextStyle(fontSize: 14, color: AppColors.textSecondary);
    return Material(
      key: const Key('results_pill'),
      color: AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                city,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(dates, style: secondary),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.person_outline,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  Text('$guests', style: secondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Ничего не найдено',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Попробуйте изменить фильтры',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          FilledButton(
            key: const Key('reset_filters'),
            onPressed: ref.read(filtersProvider.notifier).reset,
            child: const Text('Сбросить фильтры'),
          ),
        ],
      ),
    );
  }
}
