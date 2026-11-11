import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/parking_session.dart';
import '../../domain/usecases/parking_session_usecases.dart';
import 'parking_providers.dart';

/// Estancia activa del usuario (o `null` si no está estacionado).
///
/// Se carga desde SQLite al abrir la app, así que si el usuario cerró la app
/// con el auto estacionado, al volver ve el aviso "Estás en E10".
class SessionController extends AsyncNotifier<ParkingSession?> {
  @override
  Future<ParkingSession?> build() =>
      ref.watch(sessionRepositoryProvider).getActive();

  /// "Estacioné con éxito".
  Future<StartSessionResult> start({
    required String lotId,
    required String zoneId,
  }) async {
    final result = await ref.read(startParkingSessionProvider)(
      lotId: lotId,
      zoneId: zoneId,
    );
    if (ref.mounted) state = AsyncData(result.session);
    return result;
  }

  /// "Ya me fui".
  Future<EndSessionResult> end() async {
    final result = await ref.read(endParkingSessionProvider)();
    if (ref.mounted) state = const AsyncData(null);
    return result;
  }
}

final activeSessionProvider =
    AsyncNotifierProvider<SessionController, ParkingSession?>(
  SessionController.new,
);
