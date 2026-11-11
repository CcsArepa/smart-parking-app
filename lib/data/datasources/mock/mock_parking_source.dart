import 'dart:async';
import 'dart:math';

/// Fuente de datos **simulada** que se comporta como un backend en tiempo real.
///
/// - Devuelve mapas (como si fueran JSON de una API).
/// - Cada [tickInterval] simula que *otros* estudiantes entran o salen de un
///   estacionamiento al azar, para que los contadores cambien solos y se
///   pueda observar la sincronización en vivo de la UI.
/// - [latency] simula el tiempo de respuesta de la red al enviar un reporte,
///   lo que permite mostrar estados de "enviando…".
///
/// Para conectar un backend real basta con crear otra fuente con la misma
/// forma y cambiarla en el provider `parkingRepositoryProvider`.
class MockParkingSource {
  MockParkingSource({
    this.simulateTraffic = true,
    this.tickInterval = const Duration(seconds: 4),
    this.latency = const Duration(milliseconds: 450),
    Random? random,
  }) : _random = random ?? Random() {
    if (simulateTraffic) {
      _timer = Timer.periodic(tickInterval, (_) => _simulateTraffic());
    }
  }

  final bool simulateTraffic;
  final Duration tickInterval;
  final Duration latency;
  final Random _random;
  Timer? _timer;

  /// Emite el estado completo cada vez que algo cambia.
  final _controller =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  // ---------------------------------------------------------------------------
  // Datos semilla. Los de Ingeniería coinciden con el boceto
  // (E1: 0, E2: 2, E10: 17, E11: 23, E12: 35).
  // ---------------------------------------------------------------------------

  static final List<Map<String, dynamic>> _zones = [
    {
      'id': 'ingenieria',
      'name': 'Ingeniería',
      'kind': 'engineering',
      'primary': ['E1', 'E2', 'E10'],
      'nearby': ['E11', 'E12'],
    },
    {
      'id': 'negocios',
      'name': 'Negocios',
      'kind': 'business',
      'primary': ['E3', 'E4', 'E5'],
      'nearby': ['E2', 'E6'],
    },
    {
      'id': 'humanidades',
      'name': 'Humanidades',
      'kind': 'humanities',
      'primary': ['E6', 'E7'],
      'nearby': ['E8', 'E5'],
    },
    {
      'id': 'salud',
      'name': 'Salud',
      'kind': 'health',
      'primary': ['E8', 'E9'],
      'nearby': ['E7', 'E12'],
    },
  ];

  /// Centro aproximado del campus UDLAP (San Andrés Cholula, Puebla).
  static const double campusLat = 19.0543;
  static const double campusLng = -98.2837;

  // ⚠️ Las coordenadas de cada estacionamiento son APROXIMADAS (no hay un
  // mapa oficial público de estacionamientos). Ajústalas aquí con los puntos
  // reales tomados de Google Maps (clic derecho → copiar coordenadas).
  late final Map<String, Map<String, dynamic>> _lots = {
    for (final (id, capacity, available, lat, lng) in const [
      ('E1', 120, 0, 19.0556, -98.2852),
      ('E2', 80, 2, 19.0561, -98.2840),
      ('E3', 100, 41, 19.0530, -98.2829),
      ('E4', 60, 8, 19.0524, -98.2841),
      ('E5', 90, 0, 19.0536, -98.2816),
      ('E6', 70, 16, 19.0545, -98.2808),
      ('E7', 110, 4, 19.0556, -98.2812),
      ('E8', 50, 27, 19.0568, -98.2822),
      ('E9', 140, 63, 19.0577, -98.2831),
      ('E10', 150, 17, 19.0566, -98.2858),
      ('E11', 60, 23, 19.0573, -98.2846),
      ('E12', 90, 35, 19.0549, -98.2866),
    ])
      id: {
        'id': id,
        'name': id,
        'capacity': capacity,
        'available': available,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'lat': lat,
        'lng': lng,
      },
  };

  // ---------------------------------------------------------------------------
  // API pública
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchZones() async =>
      _zones.map((z) => Map<String, dynamic>.from(z)).toList();

  /// Emite el estado actual inmediatamente y luego cada actualización.
  Stream<List<Map<String, dynamic>>> watchLots() async* {
    yield _snapshot();
    yield* _controller.stream;
  }

  /// Aplica un reporte de usuario y devuelve el estacionamiento actualizado.
  ///
  /// - `parked`: se ocupa una plaza (mínimo 0).
  /// - `full`: el usuario confirma que no hay lugar → 0 plazas.
  /// - `left`: el usuario se fue → se libera una plaza (máximo la capacidad).
  Future<Map<String, dynamic>> applyReport({
    required String lotId,
    required String type,
  }) async {
    await Future<void>.delayed(latency);
    final lot = _lotOrThrow(lotId);
    final current = lot['available'] as int;
    final capacity = lot['capacity'] as int;
    lot['available'] = switch (type) {
      'parked' => max(0, current - 1),
      'full' => 0,
      'left' => min(capacity, current + 1),
      _ => throw ArgumentError.value(type, 'type'),
    };
    lot['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    _emit();
    return Map<String, dynamic>.from(lot);
  }

  Future<Map<String, dynamic>> fetchLot(String lotId) async =>
      Map<String, dynamic>.from(_lotOrThrow(lotId));

  Map<String, dynamic> _lotOrThrow(String lotId) {
    final lot = _lots[lotId];
    if (lot == null) {
      throw ArgumentError.value(lotId, 'lotId', 'Estacionamiento desconocido');
    }
    return lot;
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }

  // ---------------------------------------------------------------------------
  // Internos
  // ---------------------------------------------------------------------------

  /// Simula la llegada o salida de 1 a 3 autos en un estacionamiento al azar.
  void _simulateTraffic() {
    final ids = _lots.keys.toList();
    final lot = _lots[ids[_random.nextInt(ids.length)]]!;
    final capacity = lot['capacity'] as int;
    final current = lot['available'] as int;
    final delta = (_random.nextInt(3) + 1) * (_random.nextBool() ? 1 : -1);
    final next = (current + delta).clamp(0, capacity);
    if (next == current) return;
    lot['available'] = next;
    lot['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    _emit();
  }

  List<Map<String, dynamic>> _snapshot() =>
      _lots.values.map((l) => Map<String, dynamic>.from(l)).toList();

  void _emit() {
    if (!_controller.isClosed) _controller.add(_snapshot());
  }
}
