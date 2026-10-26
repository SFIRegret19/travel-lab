import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/geo.dart';
import '../../map/map_tiles.dart';
import '../../search/search_provider.dart';

/// Баннер «На карте»: статичная карта выбранного города и кнопка,
/// которая открывает полноэкранную карту выдачи.
class MapBanner extends ConsumerWidget {
  const MapBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final center = cityCenter(ref.watch(searchProvider).displayCity);
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 184,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Карта без жестов, чтобы не мешать прокрутке списка.
              FlutterMap(
                key: const Key('map_banner_map'),
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 11,
                  backgroundColor: const Color(0xFF1A1B1F),
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  buildTileLayer(context, ref.watch(tileProviderProvider)),
                ],
              ),
              Align(
                alignment: const Alignment(0, .62),
                child: Material(
                  color: const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    key: const Key('map_banner'),
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => context.push(Routes.map),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map_outlined, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            'На карте',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
