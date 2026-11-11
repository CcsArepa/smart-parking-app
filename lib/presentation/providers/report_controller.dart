import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/parking_event.dart';
import '../../domain/entities/parking_lot.dart';
import 'parking_providers.dart';
import 'session_controller.dart';

/// Fases del envío de un reporte.
enum ReportStatus { idle, sending, success, error }

/// Estado de la pantalla de reporte.
class ReportState {
  const ReportState({
    this.status = ReportStatus.idle,
    this.lastType,
    this.lot,
    this.releasedLotId,
    this.alreadyActive = false,
    this.errorMessage,
  });

  final ReportStatus status;

  /// Botón que originó el envío (para animar sólo ese botón).
  final ParkingEventType? lastType;

  /// Estacionamiento actualizado tras el reporte.
  final ParkingLot? lot;

  /// Si al estacionarse se liberó automáticamente una estancia anterior.
  final String? releasedLotId;

  /// El usuario ya estaba registrado en este mismo lugar.
  final bool alreadyActive;
  final String? errorMessage;

  bool get isSending => status == ReportStatus.sending;
}

/// Controla la acción de reportar desde la pantalla de un estacionamiento.
///
/// Es `autoDispose`: al salir de la pantalla el estado se descarta y la
/// próxima vez empieza limpio.
class ReportController extends Notifier<ReportState> {
  @override
  ReportState build() => const ReportState();

  /// Envía el reporte. Ignora toques repetidos mientras hay uno en curso
  /// (evita reportes duplicados por doble tap).
  Future<void> report({
    required String lotId,
    required String zoneId,
    required ParkingEventType type,
  }) async {
    if (state.isSending) return;

    state = ReportState(status: ReportStatus.sending, lastType: type);
    try {
      if (type == ParkingEventType.parked) {
        // "Estacioné con éxito" inicia una estancia (sesión).
        final result = await ref
            .read(activeSessionProvider.notifier)
            .start(lotId: lotId, zoneId: zoneId);
        if (!ref.mounted) return;
        state = ReportState(
          status: ReportStatus.success,
          lastType: type,
          lot: result.lot,
          releasedLotId: result.releasedLotId,
          alreadyActive: result.alreadyActive,
        );
      } else {
        final result = await ref.read(reportParkingEventProvider)(
          lotId: lotId,
          type: type,
        );
        if (!ref.mounted) return;
        state = ReportState(
          status: ReportStatus.success,
          lastType: type,
          lot: result.lot,
        );
      }
    } catch (e) {
      if (!ref.mounted) return;
      state = ReportState(
        status: ReportStatus.error,
        lastType: type,
        errorMessage: 'No se pudo enviar tu reporte. Intenta de nuevo.',
      );
    }
  }
}

final reportControllerProvider =
    NotifierProvider.autoDispose<ReportController, ReportState>(
  ReportController.new,
);
