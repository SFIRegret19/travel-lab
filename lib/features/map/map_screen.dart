import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/geo.dart';
import '../../data/models/hotel.dart';
import '../results/filters/filters_sheet.dart';
import '../results/results_state.dart';
import '../search/search_provider.dart';
import 'map_tiles.dart';
import 'map_widgets.dart';

/// Карта выдачи: метки с ценой у отелей, прошедших фильтры, и карточка
/// выбранного отеля.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _controller = MapController();
  String? _selectedId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Кадр, в который помещаются все метки; null, если отелей нет.
  CameraFit? _fit(List<LatLng> points) => points.isEmpty
      ? null
      : CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.fromLTRB(70, 140, 70, 200),
          maxZoom: 14,
        );

  @override
  Widget build(BuildContext context) {
    final params = ref.watch(searchProvider);
    final hotels = ref.watch(resultsProvider);
    final city = params.displayCity;
    final nights = params.nights;
    final positions = {for (final h in hotels) h.id: hotelPosition(h, city)};
    final center = cityCenter(city);
    final fit = _fit(positions.values.toList());

    Hotel? selected;
    for (final h in hotels) {
      if (h.id == _selectedId) selected = h;
    }

    // Выбранная метка рисуется последней, чтобы лежать поверх соседних.
    final ordered = [...hotels.where((h) => h != selected), ?selected];
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 11,
              initialCameraFit: fit,
              minZoom: 3,
              maxZoom: 18,
              backgroundColor: const Color(0xFF1A1B1F),
              onTap: (_, _) => setState(() => _selectedId = null),
            ),
            children: [
              buildTileLayer(context, ref.watch(tileProviderProvider)),
              MarkerLayer(
                markers: [
                  for (final h in ordered)
                    Marker(
                      point: positions[h.id]!,
                      width: 150,
                      height: 44,
                      // Center ослабляет жёсткие размеры маркера: метка по содержимому.
                      child: Center(
                        child: PricePin(
                          key: Key('map_pin_${h.id}'),
                          hotel: h,
                          nights: nights,
                          selected: h == selected,
                          onTap: () => setState(() => _selectedId = h.id),
                        ),
                      ),
                    ),
                ],
              ),
              SimpleAttributionWidget(
                source: const Text(
                  mapAttribution,
                  style: TextStyle(fontSize: 11),
                ),
                backgroundColor: Colors.black.withValues(alpha: .6),
              ),
            ],
          ),
          Positioned(
            top: topInset + 12,
            left: 16,
            child: _MapButton(
              key: const Key('map_back'),
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
            ),
          ),
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MapButton(
                    key: const Key('map_filters'),
                    icon: Icons.tune_rounded,
                    onTap: () => showFiltersSheet(context),
                  ),
                  const SizedBox(height: 12),
                  _MapButton(
                    key: const Key('map_locate'),
                    icon: Icons.navigation_outlined,
                    onTap: () {
                      if (fit != null) {
                        _controller.fitCamera(fit);
                      } else {
                        _controller.move(center, 11);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          if (hotels.isEmpty)
            const Center(
              child: _Notice('По выбранным фильтрам ничего не найдено'),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset + 28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: SelectedHotelCard(
                      key: const Key('map_card'),
                      hotel: selected,
                      city: city,
                      nights: nights,
                      onTap: () => context.push(Routes.hotelPath(selected!.id)),
                    ),
                  ),
                Material(
                  color: const Color(0xFF1C1C1F),
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    key: const Key('map_list'),
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => context.pop(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.view_agenda_outlined),
                          SizedBox(width: 10),
                          Text(
                            'Список',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _MapButton extends StatelessWidget {
  const _MapButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1C1C1F),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(width: 56, height: 56, child: Icon(icon, size: 28)),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(fontSize: 16)),
    );
  }
}
