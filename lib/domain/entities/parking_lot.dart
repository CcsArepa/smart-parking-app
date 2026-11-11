/// Nivel de disponibilidad, usado por la UI para elegir colores y mensajes.
enum Availability { full, low, available }

/// Estacionamiento específico (p. ej. "E10") con su capacidad y las plazas
/// disponibles en este momento.
///
/// Es inmutable: cada actualización produce una nueva instancia con
/// [copyWith]. Así Riverpod detecta los cambios y sólo se reconstruyen los
/// widgets que muestran ese estacionamiento.
class ParkingLot {
  const ParkingLot({
    required this.id,
    required this.name,
    required this.capacity,
    required this.availableSpots,
    required this.lastUpdated,
    this.latitude,
    this.longitude,
  }) : assert(availableSpots >= 0 && availableSpots <= capacity);

  /// Ubicación en el mapa (opcional: si falta, no se muestra en el mapa).
  final double? latitude;
  final double? longitude;

  bool get hasLocation => latitude != null && longitude != null;

  final String id;
  final String name;

  /// Número total de cajones.
  final int capacity;

  /// Plazas libres estimadas a partir de los reportes de los usuarios.
  final int availableSpots;

  /// Momento del último reporte o actualización.
  final DateTime lastUpdated;

  /// Umbral (en plazas) por debajo del cual se considera "casi lleno".
  static const int lowThreshold = 5;

  Availability get availability {
    if (availableSpots == 0) return Availability.full;
    if (availableSpots <= lowThreshold) return Availability.low;
    return Availability.available;
  }

  /// Porcentaje de ocupación entre 0.0 y 1.0.
  double get occupancy =>
      capacity == 0 ? 1 : 1 - (availableSpots / capacity);

  ParkingLot copyWith({int? availableSpots, DateTime? lastUpdated}) {
    return ParkingLot(
      id: id,
      name: name,
      capacity: capacity,
      availableSpots: availableSpots ?? this.availableSpots,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ParkingLot &&
      other.id == id &&
      other.capacity == capacity &&
      other.availableSpots == availableSpots &&
      other.lastUpdated == lastUpdated;

  @override
  int get hashCode => Object.hash(id, capacity, availableSpots, lastUpdated);

  @override
  String toString() => 'ParkingLot($id, $availableSpots/$capacity)';
}
