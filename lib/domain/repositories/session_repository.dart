import '../entities/parking_session.dart';

/// Contrato para guardar la estancia activa del usuario (sólo puede haber una:
/// un auto no puede estar en dos estacionamientos a la vez).
abstract interface class SessionRepository {
  Future<ParkingSession?> getActive();
  Future<void> save(ParkingSession session);
  Future<void> clear();
}
