import '../entities/parking_event.dart';
import '../entities/parking_lot.dart';
import '../repositories/history_repository.dart';
import '../repositories/parking_repository.dart';

/// Resultado de un reporte: el estacionamiento ya actualizado.
class ReportResult {
  const ReportResult({required this.event, required this.lot});
  final ParkingEvent event;
  final ParkingLot lot;
}

/// Caso de uso: el usuario reporta "Estacioné con éxito" o
/// "No hay lugares disponibles".
///
/// Reglas de negocio:
/// 1. Se actualiza el contador compartido (en el repositorio de plazas).
/// 2. Se guarda el reporte en el historial local del usuario.
///
/// Si falla el paso 1 no se guarda nada en el historial, para que el
/// historial nunca muestre reportes que en realidad no se enviaron.
class ReportParkingEvent {
  const ReportParkingEvent({
    required ParkingRepository parkingRepository,
    required HistoryRepository historyRepository,
    DateTime Function()? clock,
  })  : _parking = parkingRepository,
        _history = historyRepository,
        _clock = clock ?? DateTime.now;

  final ParkingRepository _parking;
  final HistoryRepository _history;
  final DateTime Function() _clock;

  Future<ReportResult> call({
    required String lotId,
    required ParkingEventType type,
  }) async {
    final event = ParkingEvent(lotId: lotId, type: type, timestamp: _clock());
    final updatedLot = await _parking.applyEvent(event);
    final saved = await _history.saveEvent(event);
    return ReportResult(event: saved, lot: updatedLot);
  }
}
