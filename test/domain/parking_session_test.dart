import 'package:flutter_test/flutter_test.dart';
import 'package:udlap_parking/data/datasources/mock/mock_parking_source.dart';
import 'package:udlap_parking/data/repositories/history_repository_impl.dart';
import 'package:udlap_parking/data/repositories/parking_repository_impl.dart';
import 'package:udlap_parking/data/repositories/session_repository_impl.dart';
import 'package:udlap_parking/domain/usecases/parking_session_usecases.dart';
import 'package:udlap_parking/domain/usecases/report_parking_event.dart';

void main() {
  late MockParkingSource source;
  late ParkingRepositoryImpl parking;
  late PrefsSessionRepository sessions;
  late StartParkingSession start;
  late EndParkingSession end;

  setUp(() {
    source = MockParkingSource(simulateTraffic: false, latency: Duration.zero);
    parking = ParkingRepositoryImpl(source);
    final history = InMemoryHistoryRepository();
    sessions = PrefsSessionRepository(history);
    final report = ReportParkingEvent(
      parkingRepository: parking,
      historyRepository: history,
    );
    start = StartParkingSession(report: report, sessions: sessions, parking: parking);
    end = EndParkingSession(report: report, sessions: sessions);
  });

  tearDown(() => source.dispose());

  test('estacionarse ocupa una plaza y guarda la estancia', () async {
    final r = await start(lotId: 'E10', zoneId: 'ingenieria');
    expect(r.lot.availableSpots, 16);
    expect((await sessions.getActive())?.lotId, 'E10');
  });

  test('"Ya me fui" libera la plaza y borra la estancia', () async {
    await start(lotId: 'E10', zoneId: 'ingenieria');
    final r = await end();
    expect(r.report.lot.availableSpots, 17);
    expect(await sessions.getActive(), isNull);
  });

  test('estacionarse en otro lugar libera el anterior automáticamente',
      () async {
    await start(lotId: 'E10', zoneId: 'ingenieria'); // 17 → 16
    final r = await start(lotId: 'E12', zoneId: 'ingenieria');
    expect(r.releasedLotId, 'E10');
    expect((await parking.getLot('E10')).availableSpots, 17);
    expect(r.lot.availableSpots, 34);
  });

  test('registrarse dos veces en el mismo lugar no descuenta otra plaza',
      () async {
    await start(lotId: 'E10', zoneId: 'ingenieria');
    final r = await start(lotId: 'E10', zoneId: 'ingenieria');
    expect(r.alreadyActive, isTrue);
    expect(r.lot.availableSpots, 16);
  });

  test('no se puede salir sin estar estacionado', () async {
    await expectLater(end(), throwsStateError);
  });
}
