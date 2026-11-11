import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udlap_parking/app.dart';
import 'package:udlap_parking/data/datasources/mock/mock_parking_source.dart';
import 'package:udlap_parking/data/repositories/history_repository_impl.dart';
import 'package:udlap_parking/presentation/providers/parking_providers.dart';

/// Monta la app con datos deterministas (sin tráfico simulado ni latencia).
Future<void> pumpApp(WidgetTester tester, {Size size = const Size(390, 844)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final source = MockParkingSource(simulateTraffic: false, latency: Duration.zero);
  addTearDown(source.dispose);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      mockParkingSourceProvider.overrideWithValue(source),
      historyRepositoryProvider.overrideWithValue(InMemoryHistoryRepository()),
    ],
    child: const UdlapParkingApp(useGoogleFonts: false),
  ));
  await settle(tester);
}

/// Avanza ~1.6 s de animaciones.
///
/// No se usa `pumpAndSettle` en todas partes porque algunas pantallas tienen
/// relojes que se actualizan cada segundo (cronómetro de estancia) y nunca
/// "se asientan".
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> openE10(WidgetTester tester) async {
  await tester.tap(find.text('Ingeniería'));
  await settle(tester);
  await tester.tap(find.text('E10'));
  await settle(tester);
}

void main() {
  testWidgets('Inicio muestra las cuatro zonas con sus plazas libres',
      (tester) async {
    await pumpApp(tester);
    expect(find.text('¿Dónde deseas estacionar?'), findsOneWidget);
    for (final name in ['Ingeniería', 'Negocios', 'Humanidades', 'Salud']) {
      expect(find.text(name), findsOneWidget);
    }
    // Ingeniería: E1 (0) + E2 (2) + E10 (17) = 19
    expect(find.text('19 plazas libres'), findsOneWidget);
  });

  testWidgets('Estacionarse → estancia activa → "Ya me fui" libera el lugar',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Ingeniería'));
    await settle(tester);
    expect(find.text('Estacionamientos principales:'), findsOneWidget);
    expect(find.text('17'), findsOneWidget); // plazas de E10

    await tester.tap(find.text('E10'));
    await settle(tester);
    await tester.tap(find.text('Estacioné con éxito'));
    await settle(tester);

    // Pantalla de estancia
    expect(find.text('Estás estacionado en'), findsOneWidget);
    expect(find.text('16'), findsOneWidget); // ya ocupó una plaza
    expect(find.text('Ya me fui'), findsOneWidget);

    await tester.tap(find.text('Ya me fui'));
    await settle(tester);

    // De vuelta en Inicio, sin aviso de estancia y con la plaza liberada.
    expect(find.text('¿Dónde deseas estacionar?'), findsOneWidget);
    expect(find.textContaining('Liberaste un lugar en E10'), findsOneWidget);
    expect(find.text('19 plazas libres'), findsOneWidget);
  });

  testWidgets('Con estancia activa, Inicio muestra el aviso "Estás en E10"',
      (tester) async {
    await pumpApp(tester);
    await openE10(tester);
    await tester.tap(find.text('Estacioné con éxito'));
    await settle(tester);
    await tester.tap(find.byTooltip('Regresar'));
    await settle(tester);
    expect(find.textContaining('toca para liberar'), findsOneWidget);
  });

  testWidgets('"No hay lugares" sugiere estacionamientos con lugar',
      (tester) async {
    await pumpApp(tester);
    await openE10(tester);
    await tester.tap(find.text('No hay lugares disponibles'));
    await settle(tester);
    expect(find.text('Gracias por avisar'), findsOneWidget);
    // La mejor alternativa en Ingeniería es E12 (35 plazas).
    expect(find.text('E12'), findsOneWidget);

    await tester.tap(find.text('E12'));
    await settle(tester);
    expect(find.text('Estacioné con éxito'), findsOneWidget);
    expect(find.text('35'), findsOneWidget);
  });

  testWidgets('Sin desbordamientos en un teléfono pequeño', (tester) async {
    await pumpApp(tester, size: const Size(320, 568));
    await openE10(tester);
    await tester.tap(find.text('Estacioné con éxito'));
    await settle(tester);
    // Si hubiera un overflow, Flutter lanzaría una excepción aquí.
    expect(tester.takeException(), isNull);
  });

  testWidgets('La barra inferior abre el mapa y regresa al inicio',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.map_rounded));
    await settle(tester);
    expect(find.byTooltip('Centrar en el campus'), findsOneWidget);
    expect(find.text('Con lugar'), findsOneWidget); // leyenda
    await tester.tap(find.byIcon(Icons.home_rounded));
    await settle(tester);
    expect(find.text('¿Dónde deseas estacionar?'), findsOneWidget);
  });
}
