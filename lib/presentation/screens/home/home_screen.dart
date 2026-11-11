import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/performance.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../domain/entities/zone.dart';
import '../../providers/parking_providers.dart';
import '../../providers/session_controller.dart';
import '../../widgets/status_views.dart';
import 'widgets/active_session_banner.dart';
import 'widgets/zone_tile.dart';

/// Pantalla de inicio: "¿Dónde deseas estacionar? Cerca de:" + 4 zonas.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final zones = ref.watch(zonesProvider);
    final session = ref.watch(activeSessionProvider).value;

    return AppScaffold(
      tab: AppTab.home,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // El aviso de estancia activa aparece/desaparece animando su
                // altura, sin "saltos" bruscos del resto del contenido.
                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  child: session == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: ActiveSessionBanner(
                            session: session,
                            onTap: () => Navigator.of(context)
                                .pushNamed(AppRoutes.session),
                          ),
                        ),
                ),
                Center(
                  child: Text(
                    '¿Dónde deseas estacionar?',
                    style: textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 14),
                Text('Cerca de:', style: textTheme.titleMedium),
              ],
            ),
          ),
        ),
        ...zones.when(
          data: (_) => const <Widget>[],
          loading: () => const [SliverLoading()],
          error: (e, _) => [
            SliverError(onRetry: () => ref.invalidate(zonesProvider)),
          ],
        ),
      ],
      fillRemaining: zones.hasValue ? _ZoneGrid(zones: zones.value!) : null,
    );
  }
}

/// Grid de zonas que **llena el alto disponible**: las tarjetas son
/// rectángulos que se estiran hasta la barra inferior (sin espacio vacío).
///
/// - 2 columnas en teléfono, 4 en tableta u horizontal.
/// - Altura mínima de 150 px por tarjeta: en pantallas pequeñas la página se
///   desplaza en lugar de aplastar las tarjetas.
/// - No usa LayoutBuilder a propósito: `SliverFillRemaining` necesita medir
///   la altura intrínseca de su hijo, y LayoutBuilder no la soporta.
class _ZoneGrid extends StatelessWidget {
  const _ZoneGrid({required this.zones});
  final List<Zone> zones;

  static const double _gap = 14;
  static const double _minTileHeight = 150;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 600 ? 4 : 2;
    final rows = <List<Zone>>[
      for (var i = 0; i < zones.length; i += columns)
        zones.sublist(i, (i + columns).clamp(0, zones.length)),
    ];

    var index = 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          for (final (r, row) in rows.indexed) ...[
            if (r > 0) const SizedBox(height: _gap),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: _minTileHeight),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (c, zone) in row.indexed) ...[
                      if (c > 0) const SizedBox(width: _gap),
                      Expanded(
                        child: _StaggeredEntrance(
                          index: index++,
                          child: ZoneTile(
                            zone: zone,
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.zone,
                              arguments: zone,
                            ),
                          ),
                        ),
                      ),
                    ],
                    // Rellena columnas vacías de la última fila.
                    for (var k = row.length; k < columns; k++) ...[
                      const SizedBox(width: _gap),
                      const Expanded(child: SizedBox()),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Animación de entrada escalonada: cada tarjeta aparece un poco después de
/// la anterior (fundido + desplazamiento hacia arriba). Guía la mirada del
/// usuario en orden de lectura y hace que la app se sienta "viva".
class _StaggeredEntrance extends StatelessWidget {
  const _StaggeredEntrance({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 90),
      curve: Curves.easeOutCubic,
      child: child,
      // RepaintBoundary: cada tarjeta se dibuja en su propia capa, así
      // animar una no obliga a redibujar las demás.
      builder: (context, t, child) {
        final moved = Transform.translate(
          offset: Offset(0, (1 - t) * 24),
          child: RepaintBoundary(child: child),
        );
        // En la web, sólo movimiento (la transparencia es costosa).
        return kLightAnimations ? moved : Opacity(opacity: t, child: moved);
      },
    );
  }
}
