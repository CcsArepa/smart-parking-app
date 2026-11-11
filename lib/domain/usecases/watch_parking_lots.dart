import '../entities/parking_lot.dart';
import '../repositories/parking_repository.dart';

/// Caso de uso: escuchar en tiempo real las plazas de todos los
/// estacionamientos.
class WatchParkingLots {
  const WatchParkingLots(this._repository);
  final ParkingRepository _repository;

  Stream<Map<String, ParkingLot>> call() => _repository.watchLots();
}
