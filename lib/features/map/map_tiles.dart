import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Источник плиток карты. В тестах подменяется заглушкой без сети.
final tileProviderProvider = Provider<TileProvider>(
  (ref) => NetworkTileProvider(),
);

/// Подпись, обязательная для плиток и данных OpenStreetMap. Знак © добавляет
/// сам виджет подписи.
const mapAttribution = 'OpenStreetMap contributors';

/// Плитки OpenStreetMap, затемнённые цветовым фильтром: тёмных плиток без
/// ключа нет (CARTO требует API-ключ). Ошибки загрузки (например, без сети)
/// молча игнорируем: вместо плитки остаётся тёмный фон карты.
TileLayer buildTileLayer(BuildContext context, TileProvider provider) {
  return TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'ru.fspirin.travel_lab',
    tileProvider: provider,
    tileBuilder: darkModeTileBuilder,
    errorTileCallback: (tile, error, stackTrace) {},
  );
}
