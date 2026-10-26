import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/formatters.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/photo_placeholder.dart';
import '../../core/widgets/rating_badge.dart';
import '../../data/mock_data.dart';
import '../../data/models/hotel.dart';
import '../search/search_params.dart';
import '../search/search_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentSearchesProvider);

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Banner(onSearch: () => context.push(Routes.search)),
          _ServicesRow(onHotels: () => context.push(Routes.search)),
          const _SectionTitle('Продолжить поиск'),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: recent.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _RecentSearchCard(
                params: recent[i],
                onTap: () {
                  ref.read(searchProvider.notifier).apply(recent[i]);
                  context.push(Routes.results);
                },
              ),
            ),
          ),
          const _SectionTitle('Недавно смотрели', trailing: 'Все'),
          SizedBox(
            height: 300,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: recentlyViewed.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _HotelCard(
                hotel: recentlyViewed[i],
                onTap: () =>
                    context.push(Routes.hotelPath(recentlyViewed[i].id)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 470,
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF5BA4D6), Color(0xFFF2B26B)],
                ),
              ),
            ),
          ),
          Positioned(
            top: top + 12,
            left: 16,
            right: 16,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RoundIcon(Icons.person_rounded),
                _RoundIcon(Icons.favorite_border_rounded),
              ],
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            top: 190,
            child: Column(
              children: [
                Text(
                  'Ещё больше отдыха',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'ОТДЫХ\nРЯДОМ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 48,
            child: Material(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                key: const Key('home_search_pill'),
                borderRadius: BorderRadius.circular(30),
                onTap: onSearch,
                child: const SizedBox(
                  height: 60,
                  child: Row(
                    children: [
                      SizedBox(width: 10),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFF6A4DF5),
                        child: Icon(Icons.public, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          'Найти жильё или билет',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward, color: Colors.black),
                      SizedBox(width: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 30,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.black26,
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _ServicesRow extends StatelessWidget {
  const _ServicesRow({required this.onHotels});

  final VoidCallback onHotels;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Отели', Icons.room_service_rounded, onHotels),
      ('Квартиры\nи дома', Icons.vpn_key_rounded, onHotels),
      ('Авиа', Icons.flight_rounded, null),
      ('Поезда', Icons.train_rounded, null),
      ('Выходные', Icons.luggage_rounded, null),
    ];
    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final (label, icon, onTap) = items[i];
          return GestureDetector(
            onTap: onTap,
            child: SizedBox(
              width: 76,
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(icon, color: const Color(0xFFB9A8FF), size: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentSearchCard extends StatelessWidget {
  const _RecentSearchCard({required this.params, required this.onTap});

  final SearchParams params;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const secondary = TextStyle(fontSize: 13, color: AppColors.textSecondary);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.bed_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    params.city ?? 'Куда угодно',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatRangeShort(params.checkIn, params.checkOut),
                        style: secondary,
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      Text('${params.guests}', style: secondary),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _HotelCard extends StatelessWidget {
  const _HotelCard({required this.hotel, required this.onTap});

  final Hotel hotel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 272,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 164,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PhotoPlaceholder(
                    hue: hotel.imageHue,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  const Positioned(
                    top: 10,
                    right: 10,
                    child: Icon(Icons.favorite_border_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              hotel.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                RatingBadge(hotel.rating),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Москва, ${hotel.street} · ${hotel.type}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  formatPrice(hotel.price),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (hotel.oldPrice != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    formatPrice(hotel.oldPrice!),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
