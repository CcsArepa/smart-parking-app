import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/bounce_button.dart';
import '../../../../domain/entities/parking_session.dart';

/// Aviso en Inicio cuando el usuario tiene el auto estacionado:
/// "Estás en E10 · hace 25 min — Toca para liberar tu lugar".
///
/// Recordar el estado del usuario evita que tenga que memorizar dónde dejó
/// el auto (reconocer en lugar de recordar) y le recuerda liberar su lugar.
class ActiveSessionBanner extends StatelessWidget {
  const ActiveSessionBanner({
    super.key,
    required this.session,
    required this.onTap,
  });

  final ParkingSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BounceButton(
      onPressed: onTap,
      pressedScale: 0.97,
      rippleRadius: BorderRadius.circular(AppTheme.radius),
      rippleColor: AppColors.green,
      actionDelay: const Duration(milliseconds: 140),
      semanticLabel: 'Estás estacionado en ${session.lotId}. Abrir para liberar tu lugar',
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.fromBorderSide(AppTheme.outline),
          boxShadow: AppTheme.shadow(blur: 8, dy: 4, alpha: 0.2),
        ),
        child: Row(
          children: [
            // Capa propia: su animación continua no repinta el resto.
            const RepaintBoundary(child: _PulsingDot()),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'Estás en '),
                      TextSpan(
                        text: session.lotId,
                        style: AppTextStyles.numbers(context, size: 18),
                      ),
                    ]),
                    style: textTheme.bodyLarge,
                  ),
                  TickingElapsed(
                    since: session.startedAt,
                    interval: const Duration(seconds: 30),
                    builder: (context, elapsed) => Text(
                      'Hace ${formatElapsed(elapsed)} · toca para liberar',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 32),
          ],
        ),
      ),
    );
  }
}

/// Punto verde que "late" para indicar que la estancia está en curso.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respeta "reducir animaciones" del sistema (accesibilidad).
    if (MediaQuery.disableAnimationsOf(context)) _c.stop();
    return SizedBox.square(
      dimension: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ScaleTransition(
            scale: Tween<double>(begin: 0.6, end: 1).animate(_c),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_car_rounded, size: 16, color: AppColors.white),
          ),
        ],
      ),
    );
  }
}
