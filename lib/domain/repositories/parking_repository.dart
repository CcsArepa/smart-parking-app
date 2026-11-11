import '../entities/parking_event.dart';
import '../entities/parking_lot.dart';
import '../entities/zone.dart';

/// Contrato para obtener zonas y estacionamientos.
///
/// La capa de dominio sólo conoce esta interfaz; hoy la implementa un
/// repositorio *mock*, y mañana podría ser Firebase o una API REST sin tocar
/// ni la lógica de negocio ni las pantallas.
abstract interface class ParkingRepository {
  /// Zonas del campus.
  Future<List<Zone>> getZones();

  /// Flujo en tiempo real con el estado de **todos** los estacionamientos,
  /// indexados por id. Emite el estado actual en cuanto alguien se suscribe.
  Stream<Map<String, ParkingLot>> watchLots();

  /// Estado actual de un estacionamiento.
  Future<ParkingLot> getLot(String lotId);

  /// Aplica el reporte de un usuario y devuelve el estacionamiento
  /// actualizado.
  Future<ParkingLot> applyEvent(ParkingEvent event);
}
