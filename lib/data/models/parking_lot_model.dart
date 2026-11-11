import '../../domain/entities/parking_lot.dart';

/// Representación de [ParkingLot] en la fuente de datos.
class ParkingLotModel {
  const ParkingLotModel({
    required this.id,
    required this.name,
    required this.capacity,
    required this.available,
    required this.updatedAtMillis,
    this.lat,
    this.lng,
  });

  final double? lat;
  final double? lng;

  final String id;
  final String name;
  final int capacity;
  final int available;

  /// Marca de tiempo en milisegundos desde epoch (formato típico de APIs).
  final int updatedAtMillis;

  factory ParkingLotModel.fromMap(Map<String, dynamic> map) => ParkingLotModel(
        id: map['id'] as String,
        name: map['name'] as String,
        capacity: map['capacity'] as int,
        available: map['available'] as int,
        updatedAtMillis: map['updated_at'] as int,
        lat: (map['lat'] as num?)?.toDouble(),
        lng: (map['lng'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'capacity': capacity,
        'available': available,
        'updated_at': updatedAtMillis,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };

  ParkingLot toEntity() => ParkingLot(
        id: id,
        name: name,
        capacity: capacity,
        // Protección ante datos inconsistentes del servidor.
        availableSpots: available.clamp(0, capacity),
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(updatedAtMillis),
        latitude: lat,
        longitude: lng,
      );
}
