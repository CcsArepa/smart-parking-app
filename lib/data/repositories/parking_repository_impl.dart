import '../../domain/entities/parking_event.dart';
import '../../domain/entities/parking_lot.dart';
import '../../domain/entities/zone.dart';
import '../../domain/repositories/parking_repository.dart';
import '../datasources/mock/mock_parking_source.dart';
import '../models/parking_lot_model.dart';
import '../models/zone_model.dart';

/// Implementación de [ParkingRepository] respaldada por [MockParkingSource].
///
/// Su única responsabilidad es traducir: mapas de la fuente → modelos →
/// entidades del dominio.
class ParkingRepositoryImpl implements ParkingRepository {
  ParkingRepositoryImpl(this._source);
  final MockParkingSource _source;

  @override
  Future<List<Zone>> getZones() async {
    final raw = await _source.fetchZones();
    return raw.map((m) => ZoneModel.fromMap(m).toEntity()).toList();
  }

  @override
  Stream<Map<String, ParkingLot>> watchLots() {
    return _source.watchLots().map(
          (list) => {
            for (final m in list)
              m['id'] as String: ParkingLotModel.fromMap(m).toEntity(),
          },
        );
  }

  @override
  Future<ParkingLot> getLot(String lotId) async =>
      ParkingLotModel.fromMap(await _source.fetchLot(lotId)).toEntity();

  @override
  Future<ParkingLot> applyEvent(ParkingEvent event) async {
    final raw = await _source.applyReport(
      lotId: event.lotId,
      type: event.type.name,
    );
    return ParkingLotModel.fromMap(raw).toEntity();
  }
}
