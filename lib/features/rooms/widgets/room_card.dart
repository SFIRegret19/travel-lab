import 'package:flutter/material.dart';

import '../../../core/format/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/edge_fade.dart';
import '../../../core/widgets/photo_placeholder.dart';
import '../../../data/hotel_rooms.dart';
import '../../results/widgets/price_info_sheet.dart';
import 'room_sheets.dart';

class RoomCard extends StatelessWidget {
  const RoomCard({
    super.key,
    required this.room,
    required this.nights,
    required this.cancelUntil,
    required this.onSelect,
  });

  final Room room;
  final int nights;

  final DateTime cancelUntil;
  final ValueChanged<RoomOffer> onSelect;

  @override
  Widget build(BuildContext context) {
    final preview = room.amenities.take(3).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Photos(room: room),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Площадь: ${room.area} м²',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(room.beds, style: const TextStyle(fontSize: 16)),
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Удобства',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      InkWell(
                        key: Key('room_amenities_${room.id}'),
                        onTap: () => showRoomAmenitiesSheet(context, room),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          child: Text('Все', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                  for (final item in preview)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.check_rounded, size: 20),
                          const SizedBox(width: 12),
                          Text(item, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          EdgeFade(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < room.offers.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          right: i == room.offers.length - 1 ? 0 : 8,
                        ),
                        child: _OfferBox(
                          roomId: room.id,
                          index: i,
                          offer: room.offers[i],
                          nights: nights,
                          cancelUntil: cancelUntil,
                          onSelect: () => onSelect(room.offers[i]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Photos extends StatefulWidget {
  const _Photos({required this.room});

  final Room room;

  @override
  State<_Photos> createState() => _PhotosState();
}

class _PhotosState extends State<_Photos> {
  static const _count = 3;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final left = room.left;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          if (left != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    size: 20,
                    color: AppColors.boltYellow,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatRoomsLeft(left),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                PageView.builder(
                  key: Key('room_photos_${room.id}'),
                  itemCount: _count,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => PhotoPlaceholder(
                    hue: (room.imageHue + i * 12) % 360,
                    icon: Icons.bed_outlined,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _count; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: i == _page ? 20 : 12,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: i == _page ? .9 : .4,
                            ),
                            borderRadius: BorderRadius.circular(2),
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

class _OfferBox extends StatelessWidget {
  const _OfferBox({
    required this.roomId,
    required this.index,
    required this.offer,
    required this.nights,
    required this.cancelUntil,
    required this.onSelect,
  });

  final String roomId;
  final int index;
  final RoomOffer offer;
  final int nights;
  final DateTime cancelUntil;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final total = offer.price * nights;
    final percent = offer.discountPercent;
    final before = (offer.oldPrice ?? offer.price) * nights;
    final suffix = '${roomId}_$index';

    return Container(
      width: 290,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                formatPrice(total),
                key: Key('offer_price_$suffix'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (percent != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.discountPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '−$percent%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    formatPrice(before),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.discountPurple,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  key: Key('offer_price_info_$suffix'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => showPriceBreakdownSheet(
                    context,
                    total: total,
                    before: before,
                    percent: percent,
                    nights: nights,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.more_horiz_rounded, size: 18),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(offer.meal.label, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 6),
          InkWell(
            key: Key('offer_cancel_$suffix'),
            onTap: () => showCancellationSheet(
              context,
              refundable: offer.refundable,
              until: cancelUntil,
            ),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    cancelText(offer, cancelUntil),
                    style: TextStyle(
                      fontSize: 16,
                      color: offer.refundable ? AppColors.ratingGreen : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.help_outline_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(height: 20),
          FilledButton(
            key: Key('offer_select_$suffix'),
            onPressed: onSelect,
            child: const Text('Выбрать'),
          ),
        ],
      ),
    );
  }
}
