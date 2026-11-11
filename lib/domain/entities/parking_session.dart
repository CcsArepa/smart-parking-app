/// Estancia activa del usuario: desde que reporta "Estacioné con éxito"
/// hasta que reporta "Ya me fui".
///
/// Se guarda localmente para que, aunque el usuario cierre la app, al volver
/// sepa dónde dejó el auto y pueda liberar su lugar.
class ParkingSession {
  const ParkingSession({
    required this.lotId,
    required this.zoneId,
    required this.startedAt,
  });

  final String lotId;

  /// Zona desde la que se registró (para regresar a ella y mostrar contexto).
  final String zoneId;
  final DateTime startedAt;

  Duration elapsed(DateTime now) => now.difference(startedAt);

  @override
  bool operator ==(Object other) =>
      other is ParkingSession &&
      other.lotId == lotId &&
      other.zoneId == zoneId &&
      other.startedAt == startedAt;

  @override
  int get hashCode => Object.hash(lotId, zoneId, startedAt);

  @override
  String toString() => 'ParkingSession($lotId desde $startedAt)';
}
