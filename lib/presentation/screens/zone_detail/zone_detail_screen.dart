import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/performance.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/hero_widgets.dart';
import '../../../domain/entities/zone.dart';
import '../../../domain/repositories/history_repository.dart';
import '../../providers/parking_providers.dart';
import '../home/widgets/zone_tile.dart';
import 'widgets/parking_lot_card.dart';

/// Pantalla de una zona: "Estacionamientos principales" y
/// "Otros estacionamientos cercanos".
class ZoneDetailScreen extends ConsumerStatefulWidget {
  const ZoneDetailScreen({super.key, required this.zone});
  final Zone zone;

  @override
  ConsumerState<ZoneDetailScreen> createState() => _ZoneDetailScreenState();
}

class _ZoneDetailScreenState extends ConsumerState<ZoneDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Recordamos la última zona consultada (persistencia local). No se espera
    // el resultado: guardar no debe retrasar la pantalla.
    ref
        .read(historyRepositoryProvider)
        .setPreference(PreferenceKeys.lastZoneId, widget.zone.id)
        .ignore();
  }

  void _openLot(String lotId) {
    Navigator.of(context).pushNamed(
      AppRoutes.report,
      arguments: ReportArgs(zone: widget.zone, lotId: lotId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zone = widget.zone;
    final textTheme = Theme.of(context).textTheme;
    // Si el stream falla, lo mostramos en lugar de dejar tarjetas cargando.
    final lotsError = ref.watch(parkingLotsProvider.select((a) => a.hasError));

    return AppScaffold(
      tab: AppTab.home,
      slivers: [
        // --- Título de la zona (destino del Hero) -----------------------------
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox.square(
                  dimension: 30,
                  child: HeroIcon(
                    tag: HeroTags.zoneIcon(zone.id),
                    icon: zone.kind.icon,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: HeroText(
                      tag: HeroTags.zoneTitle(zone.id),
                      text: zone.name,
                      style: textTheme.headlineSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (lotsError)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No se pudieron actualizar las plazas.'),
            ),
          ),
      ],
      // Las secciones ocupan todo el alto restante: las tarjetas se estiran
      // hasta la barra inferior, sin espacio vacío abajo.
      fillRemaining: _Sections(zone: zone, onTapLot: _openLot),
    );
  }
}

/// Las dos secciones ("principales" y "cercanos") repartidas en el alto
/// disponible.
///
/// - Cada sección recibe espacio proporcional a sus filas de tarjetas.
/// - Las tarjetas se estiran a lo alto (con un mínimo para que en pantallas
///   pequeñas la página se desplace en lugar de aplastarlas).
/// - El ancho se calcula con `MediaQuery` y no con `LayoutBuilder` porque
///   `SliverFillRemaining` necesita medir la altura intrínseca del contenido,
///   algo que `LayoutBuilder` no soporta.
class _Sections extends StatelessWidget {
  const _Sections({required this.zone, required this.onTapLot});

  final Zone zone;
  final ValueChanged<String> onTapLot;

  static const double _gap = 12;
  static const double _hPadding = 16;

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width - _hPadding * 2;
    // 3 tarjetas por fila en teléfono; más en tabletas.
    final perRow = math.max(3, (maxW / 170).floor());
    final cardW = ((maxW - _gap * (perRow - 1)) / perRow).clamp(84.0, 170.0);

    final sections = [
      ('Estacionamientos principales:', zone.primaryLotIds),
      ('Otros estacionamientos cercanos:', zone.nearbyLotIds),
    ].where((s) => s.$2.isNotEmpty).toList();

    var delay = 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPadding, 8, _hPadding, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, (title, ids)) in sections.indexed) ...[
            if (i > 0) const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            for (final (r, row) in _chunk(ids, perRow).indexed) ...[
              if (r > 0) const SizedBox(height: _gap),
              Expanded(
                child: ConstrainedBox(
                  // Mínimo ≈ proporción del boceto, para no aplastar.
                  constraints: BoxConstraints(minHeight: cardW * 1.45),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (c, id) in row.indexed) ...[
                        if (c > 0) const SizedBox(width: _gap),
                        _PopIn(
                          delay: delay++,
                          child: ParkingLotCard(
                            lotId: id,
                            width: cardW,
                            onTap: () => onTapLot(id),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  static List<List<String>> _chunk(List<String> ids, int size) => [
        for (var i = 0; i < ids.length; i += size)
          ids.sublist(i, math.min(i + size, ids.length)),
      ];
}

/// Entrada con escala + fundido escalonado para las tarjetas.
class _PopIn extends StatelessWidget {
  const _PopIn({required this.delay, required this.child});
  final int delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + delay * 80),
      curve: Curves.easeOutBack,
      child: child,
      builder: (context, t, child) {
        final scaled = Transform.scale(
          scale: 0.85 + 0.15 * t,
          // Capa propia por tarjeta: el contador en vivo de una no repinta
          // las demás.
          child: RepaintBoundary(child: child),
        );
        // En la web, sólo escala (la transparencia es costosa).
        return kLightAnimations
            ? scaled
            : Opacity(opacity: t.clamp(0.0, 1.0), child: scaled);
      },
    );
  }
}
