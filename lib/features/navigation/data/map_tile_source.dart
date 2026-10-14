enum MapTileStyle {
  positron('positron'),
  bright('osm-bright-smooth');

  const MapTileStyle(this.providerId);
  final String providerId;
}

/// Native @2x tiles keep one request per logical tile. They do not request four
/// neighbouring tiles, as simulated retina rendering would.
class MapTileSource {
  const MapTileSource({
    this.style = MapTileStyle.positron,
    this.retina = false,
  });
  final MapTileStyle style;
  final bool retina;
  String get template =>
      'https://maps.geoapify.com/v1/tile/${style.providerId}/{z}/{x}/{y}${retina ? '@2x' : ''}.png';
  String path(int z, int x, int y) =>
      '/v1/tile/${style.providerId}/$z/$x/$y${retina ? '@2x' : ''}.png';
  @override
  bool operator ==(Object other) =>
      other is MapTileSource && other.style == style && other.retina == retina;
  @override
  int get hashCode => Object.hash(style, retina);
}
