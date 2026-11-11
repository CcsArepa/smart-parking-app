import '../../domain/entities/zone.dart';

/// Representación de [Zone] tal como llega de la fuente de datos (JSON/mapa).
///
/// Separar "modelo" de "entidad" permite que el formato del backend cambie
/// (nombres de campos, tipos) sin afectar al dominio ni a la UI.
class ZoneModel {
  const ZoneModel({
    required this.id,
    required this.name,
    required this.kind,
    required this.primaryLotIds,
    required this.nearbyLotIds,
  });

  final String id;
  final String name;
  final String kind;
  final List<String> primaryLotIds;
  final List<String> nearbyLotIds;

  factory ZoneModel.fromMap(Map<String, dynamic> map) => ZoneModel(
        id: map['id'] as String,
        name: map['name'] as String,
        kind: map['kind'] as String,
        primaryLotIds: List<String>.from(map['primary'] as List),
        nearbyLotIds: List<String>.from(map['nearby'] as List),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'kind': kind,
        'primary': primaryLotIds,
        'nearby': nearbyLotIds,
      };

  Zone toEntity() => Zone(
        id: id,
        name: name,
        kind: ZoneKind.values.byName(kind),
        primaryLotIds: List.unmodifiable(primaryLotIds),
        nearbyLotIds: List.unmodifiable(nearbyLotIds),
      );
}
