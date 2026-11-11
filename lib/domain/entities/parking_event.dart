/// Tipo de reporte que puede enviar un usuario (crowdsourcing).
enum ParkingEventType {
  /// "Estacioné con éxito": se ocupó una plaza.
  parked,

  /// "No hay lugares disponibles": el estacionamiento está lleno.
  full,

  /// "Ya me fui": el usuario salió y liberó su plaza.
  left,
}

/// Reporte hecho por el usuario sobre un estacionamiento.
class ParkingEvent {
  const ParkingEvent({
    this.id,
    required this.lotId,
    required this.type,
    required this.timestamp,
  });

  /// Identificador en la base de datos local (`null` si aún no se guarda).
  final int? id;
  final String lotId;
  final ParkingEventType type;
  final DateTime timestamp;

  ParkingEvent copyWith({int? id}) => ParkingEvent(
        id: id ?? this.id,
        lotId: lotId,
        type: type,
        timestamp: timestamp,
      );

  @override
  String toString() => 'ParkingEvent($lotId, ${type.name}, $timestamp)';
}
