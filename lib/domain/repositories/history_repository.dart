import '../entities/parking_event.dart';

/// Contrato para la persistencia local: historial de reportes del usuario y
/// preferencias simples (clave/valor).
abstract interface class HistoryRepository {
  /// Guarda el reporte y lo devuelve con su `id` asignado.
  Future<ParkingEvent> saveEvent(ParkingEvent event);

  /// Últimos reportes, del más reciente al más antiguo.
  Future<List<ParkingEvent>> getHistory({int limit = 50});

  Future<String?> getPreference(String key);

  Future<void> setPreference(String key, String value);
}

/// Claves de preferencias conocidas.
abstract final class PreferenceKeys {
  /// Última zona que abrió el usuario.
  static const String lastZoneId = 'last_zone_id';
}
