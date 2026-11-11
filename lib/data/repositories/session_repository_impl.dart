import '../../domain/entities/parking_session.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/repositories/session_repository.dart';

/// Guarda la estancia activa en la tabla de preferencias (SQLite).
///
/// Se reutiliza [HistoryRepository] en lugar de crear otra tabla: sólo hay
/// una estancia activa a la vez, así que bastan tres claves.
class PrefsSessionRepository implements SessionRepository {
  PrefsSessionRepository(this._prefs);
  final HistoryRepository _prefs;

  static const _lot = 'session_lot_id';
  static const _zone = 'session_zone_id';
  static const _start = 'session_started_at';

  @override
  Future<ParkingSession?> getActive() async {
    final lot = await _prefs.getPreference(_lot);
    final zone = await _prefs.getPreference(_zone);
    final start = int.tryParse(await _prefs.getPreference(_start) ?? '');
    if (lot == null || lot.isEmpty || zone == null || start == null) return null;
    return ParkingSession(
      lotId: lot,
      zoneId: zone,
      startedAt: DateTime.fromMillisecondsSinceEpoch(start),
    );
  }

  @override
  Future<void> save(ParkingSession session) async {
    await _prefs.setPreference(_lot, session.lotId);
    await _prefs.setPreference(_zone, session.zoneId);
    await _prefs.setPreference(
      _start,
      session.startedAt.millisecondsSinceEpoch.toString(),
    );
  }

  @override
  Future<void> clear() async {
    // Valor vacío = sin estancia (la interfaz de preferencias no borra claves).
    await _prefs.setPreference(_lot, '');
  }
}
