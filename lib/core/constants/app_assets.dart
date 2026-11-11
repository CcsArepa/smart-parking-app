/// Rutas de los recursos gráficos empaquetados en la app.
abstract final class AppAssets {
  /// Logo con el cuadrado verde y esquinas transparentes.
  static const String logo = 'assets/images/logo_app.png';
}

/// Etiquetas (tags) de las animaciones [Hero].
///
/// Tenerlas en un solo lugar evita errores de escritura: si el tag de origen
/// y el de destino no coinciden exactamente, la animación no ocurre.
abstract final class HeroTags {
  static const String logo = 'hero-app-logo';
  static String zoneIcon(String zoneId) => 'hero-zone-icon-$zoneId';
  static String zoneTitle(String zoneId) => 'hero-zone-title-$zoneId';
  static String lotName(String lotId) => 'hero-lot-name-$lotId';
}
