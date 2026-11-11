/// Categoría visual de una zona. El dominio no conoce iconos de Flutter:
/// la capa de presentación traduce este valor a un `IconData`.
enum ZoneKind { engineering, business, humanities, health }

/// Zona del campus (p. ej. "Ingeniería") con sus estacionamientos asociados.
///
/// Un mismo estacionamiento puede ser "principal" de una zona y "cercano" de
/// otra; por eso la zona guarda sólo los **identificadores** y los datos en
/// vivo de cada estacionamiento se consultan aparte.
class Zone {
  const Zone({
    required this.id,
    required this.name,
    required this.kind,
    required this.primaryLotIds,
    required this.nearbyLotIds,
  });

  final String id;
  final String name;
  final ZoneKind kind;

  /// "Estacionamientos principales" (p. ej. E1, E2, E10).
  final List<String> primaryLotIds;

  /// "Otros estacionamientos cercanos" (p. ej. E11, E12).
  final List<String> nearbyLotIds;

  @override
  bool operator ==(Object other) => other is Zone && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Zone($id, $name)';
}
