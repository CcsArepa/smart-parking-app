import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_flow_test.dart' show pumpApp, settle;

/// Regresión: tras estacionarse y volver a Inicio, el icono y el nombre de la
/// zona (los elementos con Hero) desaparecían de su tarjeta.
///
/// Causa: `pushNamedAndRemoveUntil` + tocar "Regresar" durante la transición
/// dejaba una animación Hero sin terminar (`_HeroFlight.divert`), y el Hero
/// se quedaba oculto con un `Offstage` para siempre.
void main() {
  /// `true` si algún Hero de la zona quedó oculto (vuelo sin terminar).
  bool zoneHeroesHidden(String zoneId) {
    final heroes = find.byWidgetPredicate(
      (w) => w is Hero && '${w.tag}'.contains(zoneId),
      skipOffstage: false,
    );
    expect(heroes, findsWidgets);
    return heroes.evaluate().any((e) => find
        .descendant(
          of: find.byWidget(e.widget),
          matching: find.byWidgetPredicate(
            (w) => w is Offstage && w.offstage,
            skipOffstage: false,
          ),
          skipOffstage: false,
        )
        .evaluate()
        .isNotEmpty);
  }

  Future<void> toReport(WidgetTester tester) async {
    await tester.tap(find.text('Humanidades'));
    await settle(tester);
    await tester.tap(find.text('E6'));
    await settle(tester);
  }

  final scenarios = <String, Future<void> Function(WidgetTester)>{
    'Regresar desde la estancia': (t) async {
      await t.tap(find.text('Estacioné con éxito'));
      await settle(t);
      await t.tap(find.byTooltip('Regresar'));
    },
    'Regresar DURANTE la transición a la estancia (el caso del error)': (t) async {
      await t.tap(find.text('Estacioné con éxito'));
      await t.pump(const Duration(milliseconds: 700));
      await t.pump(const Duration(milliseconds: 150));
      await t.tap(find.byTooltip('Regresar').last, warnIfMissed: false);
    },
    'Inicio (barra) justo después de Estacioné': (t) async {
      await t.tap(find.text('Estacioné con éxito'));
      await t.pump(const Duration(milliseconds: 200));
      await t.tap(find.byIcon(Icons.home_rounded));
    },
    '"Ya me fui"': (t) async {
      await t.tap(find.text('Estacioné con éxito'));
      await settle(t);
      await t.tap(find.text('Ya me fui'));
    },
    'Aviso de Inicio → estancia → Regresar': (t) async {
      await t.tap(find.text('Estacioné con éxito'));
      await settle(t);
      await t.tap(find.byTooltip('Regresar'));
      await settle(t);
      await t.tap(find.textContaining('toca para liberar'));
      await settle(t);
      await t.tap(find.byTooltip('Regresar'));
    },
  };

  for (final MapEntry(key: name, value: run) in scenarios.entries) {
    testWidgets('La tarjeta de la zona se ve completa tras: $name', (tester) async {
      await pumpApp(tester);
      await toReport(tester);
      await run(tester);
      await settle(tester);
      await settle(tester);

      expect(find.text('¿Dónde deseas estacionar?'), findsOneWidget);
      expect(zoneHeroesHidden('humanidades'), isFalse,
          reason: 'El icono y el nombre de Humanidades no deben quedar ocultos');
      expect(tester.takeException(), isNull);
    });
  }
}
