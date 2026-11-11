import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/bounce_button.dart';
import '../../providers/parking_providers.dart';
import '../../providers/session_controller.dart';
import '../zone_detail/widgets/parking_lot_card.dart';

/// Pantalla de estancia activa: "Estás estacionado en E10" + cronómetro +
/// botón gigante **"Ya me fui"** que libera el lugar.
///
/// ¿Por qué una pantalla aparte y no un tercer botón en la de reporte?
/// - Las dos acciones ocurren en momentos distintos (llegar / irse, a veces
///   horas después). Mezclarlas en la misma pantalla invita a errores.
/// - Mostrar "Ya me fui" sólo cuando el usuario de verdad está estacionado
///   previene acciones inválidas (prevención de errores).
/// - Al volver a la app, el aviso de Inicio trae al usuario directo aquí.
class ActiveSessionScreen extends ConsumerStatefulWidget {
  const ActiveSessionScreen({super.key, this.justParked = false});

  /// `true` cuando se llega justo después de "Estacioné con éxito" (se
  /// muestra una animación de bienvenida).
  final bool justParked;

  @override
  ConsumerState<ActiveSessionScreen> createState() =>
      _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen> {
  bool _leaving = false;
  bool _left = false;
  String? _lotId;

  Future<void> _leave() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    try {
      final result = await ref.read(activeSessionProvider.notifier).end();
      if (!mounted) return;
      AppFeedback.instance.play(UiSound.leave, haptic: HapticStrength.heavy);
      setState(() => _left = true);
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(
            '¡Buen viaje! Liberaste un lugar en ${result.session.lotId} '
            '(estuviste ${formatElapsed(result.duration)}).',
          ),
        ));
      navigator.popUntil((route) => route.isFirst);
    } catch (_) {
      if (!mounted) return;
      AppFeedback.instance.play(UiSound.alert, haptic: HapticStrength.heavy);
      setState(() => _leaving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No pudimos liberar tu lugar. Intenta de nuevo.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sessionAsync = ref.watch(activeSessionProvider);
    final session = sessionAsync.value;

    // Si no hay estancia (p. ej. se liberó desde otro lado) se informa en
    // lugar de mostrar una pantalla vacía.
    if (session == null && !_left) {
      return AppScaffold(
        tab: AppTab.home,
        fillRemaining: Center(
          child: sessionAsync.isLoading
              ? const CircularProgressIndicator(color: AppColors.white)
              : Text('No tienes un lugar registrado.', style: textTheme.bodyLarge),
        ),
      );
    }

    // Se recuerda el lugar para seguir mostrándolo durante la animación de
    // salida (cuando la estancia ya se borró).
    final lotId = _lotId = session?.lotId ?? _lotId;
    final lot = lotId == null ? null : ref.watch(parkingLotProvider(lotId));

    return AppScaffold(
      tab: AppTab.home,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: _WelcomeCard(
              animate: widget.justParked,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radius + 4),
                  border: Border.fromBorderSide(AppTheme.outline),
                ),
                child: Column(
                  children: [
                    Text(
                      _left ? 'Lugar liberado' : 'Estás estacionado en',
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on, color: AppColors.orange, size: 44),
                        Text(
                          lotId ?? '',
                          style: AppTextStyles.numbers(context, size: 52),
                        ),
                      ],
                    ),
                    if (session != null) ...[
                      const SizedBox(height: 8),
                      Text('Tiempo estacionado', style: textTheme.bodyMedium),
                      TickingElapsed(
                        since: session.startedAt,
                        builder: (context, elapsed) => Text(
                          formatClock(elapsed),
                          style: AppTextStyles.numbers(
                            context,
                            size: 34,
                            color: AppColors.availableText,
                          ),
                        ),
                      ),
                    ],
                    if (lot != null) ...[
                      const SizedBox(height: 10),
                      AvailabilityBadge(lot: lot, compact: true),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
      fillRemaining: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        child: Column(
          children: [
            Text(
              'Cuando salgas, avísanos para que otro estudiante encuentre tu lugar.',
              style: textTheme.bodyMedium!.copyWith(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 130),
                child: BounceButton(
                  onPressed: _leaving ? null : _leave,
                  pressedScale: 0.95,
                  haptic: HapticStrength.medium,
                  rippleRadius: BorderRadius.circular(AppTheme.radius + 6),
                  semanticLabel: 'Ya me fui, liberar mi lugar',
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _left ? AppColors.success : AppColors.orange,
                      borderRadius: BorderRadius.circular(AppTheme.radius + 6),
                      border: Border.fromBorderSide(AppTheme.outline),
                      boxShadow: AppTheme.shadow(blur: 12, dy: 5, alpha: 0.22),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutBack,
                      transitionBuilder: (child, a) => FadeTransition(
                        opacity: a,
                        child: ScaleTransition(scale: a, child: child),
                      ),
                      child: FittedBox(
                        key: ValueKey(_left ? 'left' : _leaving ? 'leaving' : 'idle'),
                        fit: BoxFit.scaleDown,
                        child: _left
                            ? Column(children: [
                                const Icon(Icons.waving_hand_rounded, size: 60),
                                Text('¡Hasta pronto!', style: textTheme.labelLarge),
                              ])
                            : _leaving
                                ? const SizedBox.square(
                                    dimension: 44,
                                    child: CircularProgressIndicator(strokeWidth: 4),
                                  )
                                : Column(children: [
                                    const Icon(Icons.logout_rounded, size: 48),
                                    const SizedBox(height: 6),
                                    Text('Ya me fui', style: textTheme.labelLarge!.copyWith(fontSize: 30)),
                                    Text('Liberar mi lugar', style: textTheme.bodyLarge),
                                  ]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Entrada con "pop" (escala elástica) cuando el usuario acaba de
/// estacionarse: celebra la acción completada.
class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.animate, required this.child});
  final bool animate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      child: child,
      builder: (context, s, child) => Transform.scale(scale: s, child: child),
    );
  }
}
