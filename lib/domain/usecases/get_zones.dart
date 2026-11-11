import '../entities/zone.dart';
import '../repositories/parking_repository.dart';

/// Caso de uso: obtener las zonas del campus para la pantalla de inicio.
class GetZones {
  const GetZones(this._repository);
  final ParkingRepository _repository;

  Future<List<Zone>> call() => _repository.getZones();
}
