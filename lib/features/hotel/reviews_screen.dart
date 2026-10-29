import 'package:flutter/material.dart';

import '../../core/format/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../data/hotel_details.dart';
import '../../data/hotel_reviews.dart';
import '../../data/hotels_catalog.dart';
import 'widgets/category_bars.dart';
import 'widgets/review_card.dart';
import 'widgets/section_card.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key, required this.hotelId});

  final String hotelId;

  @override
  Widget build(BuildContext context) {
    final hotel = hotelById(hotelId);
    if (hotel == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Отель не найден', key: Key('reviews_not_found')),
        ),
      );
    }

    final details = detailsFor(hotel);
    final reviews = reviewsFor(hotel);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Отзывы', style: TextStyle(fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          key: const Key('reviews_back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          SectionCard(
            titleWidget: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ratingGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    hotel.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hotel.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatReviews(hotel.reviews),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                CategoryBars(scores: details.scores),
              ],
            ),
          ),
          for (final review in reviews)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: ReviewCard(review: review),
            ),
        ],
      ),
    );
  }
}
