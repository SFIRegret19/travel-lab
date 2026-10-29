import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/formatters.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/edge_fade.dart';
import '../../core/widgets/photo_placeholder.dart';
import '../../data/hotel_details.dart';
import '../../data/hotel_reviews.dart';
import '../../data/hotels_catalog.dart';
import '../../data/models/hotel.dart';
import '../results/results_state.dart';
import '../results/widgets/price_info_sheet.dart';
import '../search/search_params.dart';
import '../search/search_provider.dart';
import 'widgets/category_bars.dart';
import 'widgets/review_card.dart';
import 'widgets/section_card.dart';

class HotelScreen extends ConsumerWidget {
  const HotelScreen({super.key, required this.hotelId});

  final String hotelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotel = hotelById(hotelId);
    if (hotel == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Отель не найден', key: Key('hotel_not_found')),
        ),
      );
    }

    final params = ref.watch(searchProvider);
    final nights = params.nights;
    final details = detailsFor(hotel);
    final reviews = reviewsFor(hotel);
    final favorite = ref.watch(favoritesProvider).contains(hotel.id);
    final total = hotel.price * nights;
    final subtitle =
        '${formatRangeShort(params.checkIn, params.checkOut)} · '
        'Гостей: ${params.guests}';

    void openReviews() => context.push(Routes.reviewsPath(hotel.id));
    void openRooms() => context.push(Routes.roomsPath(hotel.id));
    void editSearch() => context.push(Routes.search, extra: true);

    return Scaffold(
      bottomNavigationBar: _SelectBar(
        label: 'Выбрать от ${formatPrice(total)}',
        onTap: openRooms,
      ),
      body: CustomScrollView(
        key: const Key('hotel_scroll'),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            toolbarHeight: 64,
            leadingWidth: 64,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            leading: _CircleButton(
              key: const Key('hotel_back'),
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
            ),
            actions: [
              _CircleButton(
                key: const Key('hotel_share'),
                icon: Icons.ios_share_rounded,
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: 'https://travel-lab.example/hotel/${hotel.id}',
                    ),
                  );
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('Ссылка скопирована'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                },
              ),
              const SizedBox(width: 8),
              _CircleButton(
                key: const Key('hotel_favorite'),
                icon: favorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: favorite ? Colors.redAccent : Colors.white,
                onTap: () =>
                    ref.read(favoritesProvider.notifier).toggle(hotel.id),
              ),
              const SizedBox(width: 12),
            ],
            flexibleSpace: _HeaderSpace(
              hotel: hotel,
              title: hotel.name,
              subtitle: subtitle,
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),
              _TitleCard(hotel: hotel, details: details, onRating: openReviews),
              _WhereCard(
                hotel: hotel,
                details: details,
                city: params.displayCity,
              ),
              if (hotel.discountPercent != null)
                _BonusCard(
                  percent: hotel.discountPercent!,
                  onLink: () => showPriceInfoSheet(context, hotel, nights),
                ),
              _OffersCard(
                params: params,
                label: 'Выбрать от ${formatPrice(total)}',
                onEdit: editSearch,
                onSelect: openRooms,
              ),
              _AboutCard(text: details.description),
              _RulesCard(details: details),
              _AmenitiesCard(amenities: details.amenities),
              _ReviewsCard(
                hotel: hotel,
                details: details,
                reviews: reviews,
                onOpen: openReviews,
              ),
              _ObjectCard(facts: details.facts),
              const SizedBox(height: 8),
            ]),
          ),
        ],
      ),
    );
  }
}

class _SelectBar extends StatelessWidget {
  const _SelectBar({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: FilledButton(
            key: const Key('hotel_select'),
            onPressed: onTap,
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Material(
          color: Colors.black38,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, color: color, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

/// Раскрытая шапка: галерея. Свёрнутая: название отеля и даты.
class _HeaderSpace extends StatelessWidget {
  const _HeaderSpace({
    required this.hotel,
    required this.title,
    required this.subtitle,
  });

  final Hotel hotel;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final settings = context
        .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    final range = settings == null
        ? 0.0
        : settings.maxExtent - settings.minExtent;
    final collapsed = settings == null || range <= 0
        ? 0.0
        : (1 - (settings.currentExtent - settings.minExtent) / range).clamp(
            0.0,
            1.0,
          );

    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: 1 - collapsed,
          child: _Gallery(hotel: hotel),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top,
          left: 64,
          right: 112,
          height: 64,
          child: Opacity(
            opacity: collapsed,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.hotel});

  final Hotel hotel;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  static const _count = 5;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          key: const Key('hotel_gallery'),
          itemCount: _count,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (context, i) =>
              PhotoPlaceholder(hue: (widget.hotel.imageHue + i * 25) % 360),
        ),
        Positioned(
          bottom: 14,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _count; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: i == _page ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: i == _page ? 1 : .5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TitleCard extends StatelessWidget {
  const _TitleCard({
    required this.hotel,
    required this.details,
    required this.onRating,
  });

  final Hotel hotel;
  final HotelDetails details;
  final VoidCallback onRating;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hotel.recommended) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 13,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.thumb_up_rounded,
                    size: 15,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Рекомендуем',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary.withValues(alpha: .9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Text(
            hotel.name,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          _RatingTile(
            key: const Key('hotel_rating_tile'),
            rating: hotel.rating,
            reviews: hotel.reviews,
            onTap: onRating,
          ),
          const SizedBox(height: 16),
          for (final amenity in details.topAmenities)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(amenity.icon, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      amenity.label,
                      style: const TextStyle(fontSize: 15),
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

class _BigRating extends StatelessWidget {
  const _BigRating(this.rating);

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.ratingGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        rating.toStringAsFixed(1),
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _RatingTile extends StatelessWidget {
  const _RatingTile({
    super.key,
    required this.rating,
    required this.reviews,
    required this.onTap,
  });

  final double rating;
  final int reviews;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _BigRating(rating),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  formatReviews(reviews),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhereCard extends StatelessWidget {
  const _WhereCard({
    required this.hotel,
    required this.details,
    required this.city,
  });

  final Hotel hotel;
  final HotelDetails details;
  final String city;

  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );

    return SectionCard(
      title: 'Где находится',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 132,
            width: double.infinity,
            child: PhotoPlaceholder(
              hue: 215,
              icon: Icons.location_on_rounded,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          row(Icons.location_on_outlined, '$city, ${hotel.street}'),
          row(Icons.near_me_outlined, formatDistance(hotel.distanceKm)),
          row(Icons.subway_outlined, details.metro),
        ],
      ),
    );
  }
}

class _BonusCard extends StatelessWidget {
  const _BonusCard({required this.percent, required this.onLink});

  final int percent;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      titleWidget: Text.rich(
        const TextSpan(
          children: [
            TextSpan(text: 'Бонусы '),
            TextSpan(
              text: 'для вас',
              style: TextStyle(color: AppColors.discountPurple),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.percent_rounded,
                  color: AppColors.discountPurple,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$percent% скидка',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Text(
                    'На некоторые варианты размещения',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Данный объект предоставляет '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    key: const Key('hotel_bonus_link'),
                    onTap: onLink,
                    child: const Text(
                      'приветственную скидку',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.discountPurple,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _OffersCard extends StatelessWidget {
  const _OffersCard({
    required this.params,
    required this.label,
    required this.onEdit,
    required this.onSelect,
  });

  final SearchParams params;
  final String label;
  final VoidCallback onEdit;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final dates = params.hasFullRange
        ? formatRangeLong(params.checkIn!, params.checkOut!)
        : 'Заезд — выезд';

    Widget row(Key key, IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(16),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 12),
                Text(text, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );

    return SectionCard(
      title: 'Предложения на ваши даты',
      child: Column(
        children: [
          row(
            const Key('hotel_dates_row'),
            Icons.calendar_today_outlined,
            dates,
          ),
          row(
            const Key('hotel_guests_row'),
            Icons.person_outline,
            formatGuests(params.guests),
          ),
          FilledButton(
            key: const Key('hotel_offers_select'),
            onPressed: onSelect,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.surfaceHigh,
              foregroundColor: AppColors.textPrimary,
              minimumSize: const Size.fromHeight(48),
              textStyle: const TextStyle(fontSize: 15),
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatefulWidget {
  const _AboutCard({required this.text});

  final String text;

  @override
  State<_AboutCard> createState() => _AboutCardState();
}

class _AboutCardState extends State<_AboutCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Об этом месте',
      child: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: double.infinity,
              child: Text(
                widget.text,
                maxLines: _expanded ? null : 4,
                overflow: _expanded ? null : TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.35),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SoftButton(
            key: const Key('hotel_read_more'),
            label: _expanded ? 'Свернуть' : 'Читать всё',
            onTap: () => setState(() => _expanded = !_expanded),
          ),
        ],
      ),
    );
  }
}

class _SoftButton extends StatelessWidget {
  const _SoftButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.surfaceHigh,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontSize: 15),
        ),
        child: Text(label),
      ),
    );
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard({required this.details});

  final HotelDetails details;

  @override
  Widget build(BuildContext context) {
    Widget tile(String time, String caption) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(time, style: const TextStyle(fontSize: 17, height: 1.25)),
            const SizedBox(height: 8),
            Text(
              caption,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );

    return SectionCard(
      title: 'Правила проживания',
      child: Column(
        children: [
          Row(
            children: [
              tile(details.checkIn, 'Заезд'),
              const SizedBox(width: 8),
              tile(details.checkOut, 'Выезд'),
            ],
          ),
          const SizedBox(height: 8),
          for (final (title, note) in details.rules)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 15)),
                        if (note != null)
                          Text(
                            note,
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
        ],
      ),
    );
  }
}

class _AmenitiesCard extends StatefulWidget {
  const _AmenitiesCard({required this.amenities});

  final List<Amenity> amenities;

  @override
  State<_AmenitiesCard> createState() => _AmenitiesCardState();
}

class _AmenitiesCardState extends State<_AmenitiesCard> {
  static const _collapsedCount = 4;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final shown = _expanded
        ? widget.amenities
        : widget.amenities.take(_collapsedCount).toList();
    final canToggle = widget.amenities.length > _collapsedCount;

    return SectionCard(
      title: 'Удобства и услуги',
      child: Column(
        children: [
          for (final a in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Icon(a.icon, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(a.label, style: const TextStyle(fontSize: 15)),
                  ),
                ],
              ),
            ),
          if (canToggle)
            _SoftButton(
              key: const Key('hotel_amenities_toggle'),
              label: _expanded ? 'Свернуть' : 'Все удобства',
              onTap: () => setState(() => _expanded = !_expanded),
            ),
        ],
      ),
    );
  }
}

class _ReviewsCard extends StatelessWidget {
  const _ReviewsCard({
    required this.hotel,
    required this.details,
    required this.reviews,
    required this.onOpen,
  });

  final Hotel hotel;
  final HotelDetails details;
  final List<Review> reviews;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      titleWidget: Row(
        children: [
          _BigRating(hotel.rating),
          const SizedBox(width: 12),
          Text(
            formatReviews(hotel.reviews),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryBars(scores: details.scores),
          const SizedBox(height: 16),
          EdgeFade(
            child: SizedBox(
              height: 270,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: reviews.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) => SizedBox(
                  width: 290,
                  child: ReviewCard(review: reviews[i], compact: true),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SoftButton(
            key: const Key('reviews_read_all'),
            label: 'Читать все отзывы',
            onTap: onOpen,
          ),
        ],
      ),
    );
  }
}

class _ObjectCard extends StatelessWidget {
  const _ObjectCard({required this.facts});

  final List<Fact> facts;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Об объекте',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (value, caption) in facts)
            Container(
              width: (MediaQuery.sizeOf(context).width - 16 - 32 - 8) / 2,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    caption,
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
    );
  }
}
