import '../entities/parking_event.dart';
import '../entities/parking_lot.dart';
import '../entities/parking_session.dart';
import '../repositories/parking_repository.dart';
import '../repositories/session_repository.dart';
import 'report_parking_event.dart';

/// Resultado de iniciar una estancia.
class StartSessionResult {
  const StartSessionResult({
    required this.session,
    required this.lot,
    this.releasedLotId,
    this.alreadyActive = false,
  });

  final ParkingSession session;

  /// Estacionamiento ya actualizado.
  final ParkingLot lot;

  /// `true` si el usuario ya estaba registrado en este mismo lugar.
  final bool alreadyActive;

  /// Si el usuario tenía una estancia en otro estacionamiento, se liberó
  /// automáticamente y aquí se indica cuál (para avisarle).
  final String? releasedLotId;
}

/// Caso de uso: "Estacioné con éxito".
///
/// Reglas:
/// 1. Si ya había una estancia activa en **otro** lugar, se libera primero
///    (un auto no puede ocupar dos plazas). Si es el mismo lugar, no se
///    descuenta otra plaza: se conserva la estancia existente.
/// 2. Se resta una plaza y se registra el evento en el historial.
/// 3. Se guarda la nueva estancia activa.
class StartParkingSession {
  // Parámetros nombrados privados (Dart 3.13): se pasan como `report:`,
  // `sessions:` y `parking:`, pero se guardan en campos privados.
  const StartParkingSession({
    required this._report,
    required this._sessions,
    required this._parking,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ReportParkingEvent _report;
  final SessionRepository _sessions;
  final ParkingRepository _parking;
  final DateTime Function() _clock;

  Future<StartSessionResult> call({
    required String lotId,
    required String zoneId,
  }) async {
    final previous = await _sessions.getActive();
    String? released;

    if (previous != null && previous.lotId != lotId) {
      await _report(lotId: previous.lotId, type: ParkingEventType.left);
      released = previous.lotId;
    }

    if (previous != null && previous.lotId == lotId) {
      // Doble registro en el mismo lugar: no se descuenta otra plaza.
      return StartSessionResult(
        session: previous,
        lot: await _parking.getLot(lotId),
        alreadyActive: true,
      );
    }

    final result = await _report(lotId: lotId, type: ParkingEventType.parked);
    final session = ParkingSession(
      lotId: lotId,
      zoneId: zoneId,
      startedAt: _clock(),
    );
    await _sessions.save(session);
    return StartSessionResult(
      session: session,
      lot: result.lot,
      releasedLotId: released,
    );
  }
}

/// Resultado de terminar una estancia.
class EndSessionResult {
  const EndSessionResult({required this.session, required this.report});
  final ParkingSession session;
  final ReportResult report;

  Duration get duration => report.event.timestamp.difference(session.startedAt);
}

/// Caso de uso: "Ya me fui". Libera la plaza y borra la estancia activa.
class EndParkingSession {
  const EndParkingSession({
    required this._report,
    required this._sessions,
  });

  final ReportParkingEvent _report;
  final SessionRepository _sessions;

  Future<EndSessionResult> call() async {
    final session = await _sessions.getActive();
    if (session == null) {
      throw StateError('No hay una estancia activa que terminar.');
    }
    final result = await _report(lotId: session.lotId, type: ParkingEventType.left);
    await _sessions.clear();
    return EndSessionResult(session: session, report: result);
  }
}
