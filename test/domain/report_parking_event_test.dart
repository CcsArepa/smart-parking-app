import 'package:flutter_test/flutter_test.dart';
import 'package:udlap_parking/data/datasources/mock/mock_parking_source.dart';
import 'package:udlap_parking/data/repositories/history_repository_impl.dart';
import 'package:udlap_parking/data/repositories/parking_repository_impl.dart';
import 'package:udlap_parking/domain/entities/parking_event.dart';
import 'package:udlap_parking/domain/usecases/report_parking_event.dart';

void main() {
  late MockParkingSource source;
  late ParkingRepositoryImpl parking;
  late InMemoryHistoryRepository history;
  late ReportParkingEvent report;

  setUp(() {
    source = MockParkingSource(simulateTraffic: false, latency: Duration.zero);
    parking = ParkingRepositoryImpl(source);
    history = InMemoryHistoryRepository();
    report = ReportParkingEvent(
      parkingRepository: parking,
      historyRepository: history,
    );
  });

  tearDown(() => source.dispose());

  test('"Estacioné con éxito" resta una plaza y se guarda en el historial',
      () async {
    final result = await report(lotId: 'E10', type: ParkingEventType.parked);

    expect(result.lot.availableSpots, 16); // semilla: 17
    final saved = await history.getHistory();
    expect(saved, hasLength(1));
    expect(saved.single.lotId, 'E10');
    expect(saved.single.id, isNotNull);
  });

  test('"No hay lugares" deja el estacionamiento en 0', () async {
    final result = await report(lotId: 'E12', type: ParkingEventType.full);
    expect(result.lot.availableSpots, 0);
  });

  test('nunca baja de 0 plazas', () async {
    final result = await report(lotId: 'E1', type: ParkingEventType.parked);
    expect(result.lot.availableSpots, 0);
  });

  test('el stream emite el cambio a todos los suscriptores', () async {
    final updates = parking.watchLots().map((m) => m['E2']!.availableSpots);
    final expectation = expectLater(updates, emitsInOrder([2, 1]));
    await report(lotId: 'E2', type: ParkingEventType.parked);
    await expectation;
  });

  test('un estacionamiento inexistente no se guarda en el historial',
      () async {
    await expectLater(
      report(lotId: 'X99', type: ParkingEventType.parked),
      throwsArgumentError,
    );
    expect(await history.getHistory(), isEmpty);
  });
}
