import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/bounce_button.dart';
import '../../../core/widgets/hero_widgets.dart';
import '../../../domain/entities/parking_event.dart';
import '../../providers/report_controller.dart';
import '../../providers/parking_providers.dart';
import '../../providers/session_controller.dart';
import '../home/widgets/zone_tile.dart' show ZoneKindIcon;
import '../zone_detail/widgets/parking_lot_card.dart';
import 'widgets/alternatives_sheet.dart';

/// Pantalla de acción (crowdsourcing): dos botones gigantes para reportar
/// "Estacioné con éxito" o "No hay lugares disponibles".
///
/// Decisiones de UX:
/// - Botones enormes (ley de Fitts): se pueden tocar sin precisión, incluso
///   caminando o con prisa.
/// - Rebote + sonido + vibración: confirmación inmediata del toque.
/// - Mientras se envía, el botón tocado muestra un indicador y el otro se
///   atenúa: evita reportes dobles y comunica el estado del sistema.
/// - "Estacioné con éxito" → se abre la pantalla de estancia, donde después
///   se marca "Ya me fui" (cierra el ciclo y libera el lugar).
/// - "No hay lugares" → se sugieren estacionamientos cercanos con lugar
///   (el usuario no se queda sin saber qué hacer).
class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key, required this.args});
  final ReportArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final lot = ref.watch(parkingLotProvider(args.lotId));
    final report = ref.watch(reportControllerProvider);
    final controller = ref.read(reportControllerProvider.notifier);
    final session = ref.watch(activeSessionProvider).value;
    final parkedHere = session?.lotId == args.lotId;

    void send(ParkingEventType type) => controller.report(
          lotId: args.lotId,
          zoneId: args.zone.id,
          type: type,
        );

    // Efectos secundarios (sonido, navegación, mensajes) al cambiar el
    // estado. Se usa `listen` para no repetirlos en cada reconstrucción.
    ref.listen(reportControllerProvider, (prev, next) {
      if (prev?.status == next.status) return;
      _onStatusChanged(context, next, onRetry: () => send(next.lastType!));
    });

    return AppScaffold(
      tab: AppTab.home,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mismo encabezado que en la pantalla de la zona (icono +
                // nombre): el icono del edificio "viaja" con la animación
                // Hero y el usuario no pierde la referencia de dónde está.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 30,
                      child: HeroIcon(
                        tag: HeroTags.zoneIcon(args.zone.id),
                        icon: args.zone.kind.icon,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: HeroText(
                          tag: HeroTags.zoneTitle(args.zone.id),
                          text: args.zone.name,
                          style: textTheme.headlineSmall,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    HeroText(
                      tag: HeroTags.lotName(args.lotId),
                      text: args.lotId,
                      style: AppTextStyles.numbers(context, size: 30),
                    ),
                    const Spacer(),
                    // Contador en vivo: confirma el efecto del reporte y
                    // muestra cambios hechos por otros usuarios.
                    if (lot != null) AvailabilityBadge(lot: lot, compact: true),
                  ],
                ),
                if (lot != null)
                  // Mostrar la antigüedad del dato genera confianza en la
                  // información colaborativa.
                  TickingElapsed(
                    since: lot.lastUpdated,
                    interval: const Duration(seconds: 15),
                    builder: (context, elapsed) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Actualizado hace ${formatElapsed(elapsed)} por la comunidad',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
      fillRemaining: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          children: [
            Expanded(
              child: parkedHere
                  ? BigActionButton(
                      label: 'Ya estás aquí\nVer mi estancia',
                      color: AppColors.success,
                      icon: Icons.directions_car_rounded,
                      type: ParkingEventType.parked,
                      state: const ReportState(),
                      onPressed: () =>
                          Navigator.of(context).pushNamed(AppRoutes.session),
                    )
                  : BigActionButton(
                      label: 'Estacioné con éxito',
                      color: AppColors.success,
                      icon: Icons.check_circle_rounded,
                      type: ParkingEventType.parked,
                      state: report,
                      onPressed: report.isSending
                          ? null
                          : () => send(ParkingEventType.parked),
                    ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: BigActionButton(
                label: 'No hay lugares disponibles',
                color: AppColors.danger,
                icon: Icons.block_rounded,
                type: ParkingEventType.full,
                state: report,
                onPressed:
                    report.isSending ? null : () => send(ParkingEventType.full),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onStatusChanged(
    BuildContext context,
    ReportState state, {
    required VoidCallback onRetry,
  }) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final lot = state.lot;

    switch (state.status) {
      case ReportStatus.success when state.lastType == ParkingEventType.parked:
        AppFeedback.instance.play(UiSound.success, haptic: HapticStrength.heavy);
        if (state.releasedLotId != null) {
          messenger.showSnackBar(SnackBar(
            content: Text(
              'Liberamos tu lugar anterior en ${state.releasedLotId}.',
            ),
          ));
        }
        // Pausa breve para que el usuario vea la palomita de "¡Registrado!"
        // antes de cambiar de pantalla.
        Future<void>.delayed(const Duration(milliseconds: 650), () {
          // Si el usuario ya navegó por su cuenta (p. ej. tocó Inicio), se
          // respeta su decisión y no se le "jala" a otra pantalla.
          if (!context.mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) {
            return;
          }
          // Primero se regresa a Inicio y luego se abre la estancia, en lugar
          // de `pushNamedAndRemoveUntil`. Ese método elimina pantallas que
          // tienen animaciones Hero y, si el usuario toca "Regresar" durante
          // la transición, Flutter deja ocultos el icono y el nombre de la
          // zona en Inicio (error del framework: `_HeroFlight.divert`).
          // Así la pila queda igual (Inicio → Estancia) sin ese problema.
          Navigator.of(context)
            ..popUntil((route) => route.isFirst)
            ..pushNamed(AppRoutes.session, arguments: !state.alreadyActive);
        });

      case ReportStatus.success when lot != null:
        AppFeedback.instance.play(UiSound.alert, haptic: HapticStrength.medium);
        Future<void>.delayed(const Duration(milliseconds: 400), () {
          if (!context.mounted) return;
          showAlternativesSheet(
            context,
            zone: args.zone,
            fullLotId: lot.id,
          );
        });

      case ReportStatus.error:
        AppFeedback.instance.play(UiSound.alert, haptic: HapticStrength.heavy);
        messenger.showSnackBar(SnackBar(
          content: Text(state.errorMessage ?? 'Ocurrió un error.'),
          action: SnackBarAction(
            label: 'Reintentar',
            onPressed: () {
              AppFeedback.instance.play(UiSound.tap);
              onRetry();
            },
          ),
        ));

      default:
        break;
    }
  }
}

/// Botón masivo de la pantalla de reporte.
///
/// Su contenido cambia con una transición según el estado:
/// texto → indicador de carga → palomita de éxito.
class BigActionButton extends StatelessWidget {
  const BigActionButton({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    required this.type,
    required this.state,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final IconData icon;
  final ParkingEventType type;
  final ReportState state;
  final VoidCallback? onPressed;

  /// Altura mínima: en pantallas muy bajas la sección se vuelve desplazable
  /// en vez de aplastar los botones.
  static const double minHeight = 120;

  @override
  Widget build(BuildContext context) {
    final isMine = state.lastType == type;
    final sending = isMine && state.status == ReportStatus.sending;
    final done = isMine && state.status == ReportStatus.success;
    final textStyle = Theme.of(context).textTheme.labelLarge!;

    final Widget content;
    if (sending) {
      content = const SizedBox.square(
        key: ValueKey('sending'),
        dimension: 44,
        child: CircularProgressIndicator(strokeWidth: 4),
      );
    } else if (done) {
      content = Column(
        key: const ValueKey('done'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 60, color: AppColors.black),
          const SizedBox(height: 6),
          Text('¡Registrado!', style: textStyle),
        ],
      );
    } else {
      content = Column(
        key: const ValueKey('label'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.black.withValues(alpha: 0.75)),
          const SizedBox(height: 8),
          Text(label, style: textStyle, textAlign: TextAlign.center),
        ],
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: minHeight),
      child: BounceButton(
        onPressed: onPressed,
        pressedScale: 0.95,
        haptic: HapticStrength.medium,
        rippleRadius: BorderRadius.circular(AppTheme.radius + 6),
        semanticLabel: label.replaceAll('\n', ', '),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppTheme.radius + 6),
            border: Border.fromBorderSide(AppTheme.outline),
            boxShadow: AppTheme.shadow(
              blur: done ? 18 : 10,
              dy: done ? 7 : 5,
              alpha: done ? 0.35 : 0.22,
            ),
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutBack,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(scale: anim, child: child),
            ),
            child: FittedBox(fit: BoxFit.scaleDown, child: content),
          ),
        ),
      ),
    );
  }
}
