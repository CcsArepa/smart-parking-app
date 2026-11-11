import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/app_database.dart';
import '../../data/datasources/mock/mock_parking_source.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../data/repositories/parking_repository_impl.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../domain/entities/parking_lot.dart';
import '../../domain/entities/zone.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/repositories/parking_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/usecases/get_zones.dart';
import '../../domain/usecases/parking_session_usecases.dart';
import '../../domain/usecases/report_parking_event.dart';
import '../../domain/usecases/watch_parking_lots.dart';

// =============================================================================
// Inyección de dependencias
// -----------------------------------------------------------------------------
// Cada capa se expone como un Provider. Para cambiar una implementación (p. ej.
// usar un backend real o un repositorio falso en pruebas) sólo hay que
// sobrescribir el provider correspondiente en `ProviderScope(overrides: ...)`.
// =============================================================================

/// Fuente simulada de plazas. Se libera (detiene su Timer) al destruirse.
final mockParkingSourceProvider = Provider<MockParkingSource>((ref) {
  final source = MockParkingSource();
  ref.onDispose(source.dispose);
  return source;
});

final parkingRepositoryProvider = Provider<ParkingRepository>(
  (ref) => ParkingRepositoryImpl(ref.watch(mockParkingSourceProvider)),
);

/// SQLite en móviles/macOS; en memoria en las demás plataformas.
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final supportsSqlite = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);
  if (!supportsSqlite) return InMemoryHistoryRepository();

  final db = AppDatabase();
  ref.onDispose(db.close);
  return SqliteHistoryRepository(db);
});

// --- Casos de uso ------------------------------------------------------------

final getZonesProvider = Provider(
  (ref) => GetZones(ref.watch(parkingRepositoryProvider)),
);

final watchParkingLotsProvider = Provider(
  (ref) => WatchParkingLots(ref.watch(parkingRepositoryProvider)),
);

final reportParkingEventProvider = Provider(
  (ref) => ReportParkingEvent(
    parkingRepository: ref.watch(parkingRepositoryProvider),
    historyRepository: ref.watch(historyRepositoryProvider),
  ),
);

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => PrefsSessionRepository(ref.watch(historyRepositoryProvider)),
);

final startParkingSessionProvider = Provider(
  (ref) => StartParkingSession(
    report: ref.watch(reportParkingEventProvider),
    sessions: ref.watch(sessionRepositoryProvider),
    parking: ref.watch(parkingRepositoryProvider),
  ),
);

final endParkingSessionProvider = Provider(
  (ref) => EndParkingSession(
    report: ref.watch(reportParkingEventProvider),
    sessions: ref.watch(sessionRepositoryProvider),
  ),
);

// =============================================================================
// Estado que consume la UI
// =============================================================================

/// Zonas del campus para la pantalla de inicio.
final zonesProvider = FutureProvider<List<Zone>>(
  (ref) => ref.watch(getZonesProvider)(),
);

/// **Fuente única de verdad** de las plazas en tiempo real.
///
/// Todas las pantallas leen de aquí, así que cuando un contador cambia (por
/// un reporte propio o por la simulación) se actualiza en toda la app al
/// mismo tiempo.
final parkingLotsProvider = StreamProvider<Map<String, ParkingLot>>(
  (ref) => ref.watch(watchParkingLotsProvider)(),
);

/// Un solo estacionamiento por id.
///
/// Al derivar de [parkingLotsProvider] con `select`, cada tarjeta se
/// reconstruye **sólo** cuando cambia *su* estacionamiento, no cuando cambia
/// cualquier otro. Esto mantiene la UI fluida aunque haya muchas tarjetas.
final parkingLotProvider = Provider.family<ParkingLot?, String>((ref, lotId) {
  return ref.watch(
    parkingLotsProvider.select((async) => async.value?[lotId]),
  );
});

/// Total de plazas libres en los estacionamientos **principales** de una
/// zona (se muestra en las tarjetas de Inicio como "52 plazas libres").
final zoneFreeSpotsProvider = Provider.family<int?, Zone>((ref, zone) {
  return ref.watch(parkingLotsProvider.select((async) {
    final lots = async.value;
    if (lots == null) return null;
    return zone.primaryLotIds
        .map((id) => lots[id]?.availableSpots ?? 0)
        .fold<int>(0, (a, b) => a + b);
  }));
});

/// Busca la zona de un estacionamiento (preferentemente donde es principal).
/// La usa el mapa para abrir la pantalla de reporte con su contexto.
final zoneForLotProvider = Provider.family<Zone?, String>((ref, lotId) {
  final zones = ref.watch(zonesProvider).value ?? const <Zone>[];
  for (final z in zones) {
    if (z.primaryLotIds.contains(lotId)) return z;
  }
  for (final z in zones) {
    if (z.nearbyLotIds.contains(lotId)) return z;
  }
  return null;
});
