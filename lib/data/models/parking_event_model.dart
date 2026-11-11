import '../../domain/entities/parking_event.dart';

/// Representación de [ParkingEvent] como fila de la tabla SQLite
/// `parking_events`.
class ParkingEventModel {
  const ParkingEventModel({
    this.id,
    required this.lotId,
    required this.type,
    required this.timestampMillis,
  });

  final int? id;
  final String lotId;
  final String type;
  final int timestampMillis;

  factory ParkingEventModel.fromEntity(ParkingEvent e) => ParkingEventModel(
        id: e.id,
        lotId: e.lotId,
        type: e.type.name,
        timestampMillis: e.timestamp.millisecondsSinceEpoch,
      );

  factory ParkingEventModel.fromRow(Map<String, Object?> row) =>
      ParkingEventModel(
        id: row['id'] as int?,
        lotId: row['lot_id']! as String,
        type: row['type']! as String,
        timestampMillis: row['timestamp']! as int,
      );

  /// Fila para insertar. El `id` se omite para que SQLite lo autogenere.
  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'lot_id': lotId,
        'type': type,
        'timestamp': timestampMillis,
      };

  ParkingEvent toEntity() => ParkingEvent(
        id: id,
        lotId: lotId,
        type: ParkingEventType.values.byName(type),
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMillis),
      );
}
