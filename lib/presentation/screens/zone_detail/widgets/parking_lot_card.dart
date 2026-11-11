import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bounce_button.dart';
import '../../../../core/widgets/hero_widgets.dart';
import '../../../../domain/entities/parking_lot.dart';
import '../../../providers/parking_providers.dart';

/// Tarjeta vertical de un estacionamiento (E1, E2, E10…): pin + nombre,
/// icono de auto y la insignia de disponibilidad en tiempo real.
///
/// Escucha **sólo** su propio estacionamiento (`parkingLotProvider(lotId)`),
/// por lo que se reconstruye únicamente cuando cambian sus plazas.
class ParkingLotCard extends ConsumerWidget {
  const ParkingLotCard({
    super.key,
    required this.lotId,
    required this.width,
    required this.onTap,
  });

  final String lotId;

  /// Ancho calculado por la pantalla según el espacio disponible.
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lot = ref.watch(parkingLotProvider(lotId));

    // Sin alto fijo: la tarjeta toma el alto que le da su fila, así llena la
    // pantalla. El auto absorbe el espacio extra.
    return SizedBox(
      width: width,
      child: BounceButton(
        onPressed: lot == null ? null : onTap,
        // Onda de luz desde el dedo + breve pausa para verla antes de
        // cambiar de pantalla.
        rippleRadius: BorderRadius.circular(AppTheme.radius),
        actionDelay: const Duration(milliseconds: 160),
        pressedScale: 0.92,
        semanticLabel: lot == null
            ? 'Estacionamiento $lotId, cargando'
            : 'Estacionamiento ${lot.name}, ${AvailabilityBadge.spokenText(lot)}',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.fromBorderSide(AppTheme.outline),
            boxShadow: AppTheme.shadow(blur: 6, dy: 3, alpha: 0.2),
          ),
          child: Padding(
            padding: EdgeInsets.all(width * 0.07),
            child: Column(
              children: [
                // --- Pin + nombre -------------------------------------------
                SizedBox(
                  height: width * 0.34,
                  child: Row(
                    children: [
                      const Expanded(
                        flex: 4,
                        child: FittedBox(
                          // El "agujero" del pin deja ver el naranja de fondo,
                          // igual que en el boceto.
                          child: Icon(Icons.location_on, color: AppColors.white),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: 6,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: HeroText(
                            tag: HeroTags.lotName(lotId),
                            text: lotId,
                            style: AppTextStyles.numbers(context, size: 30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // --- Auto ---------------------------------------------------
                // Ocupa el espacio sobrante; el icono crece hasta un tope
                // (scaleDown) para no verse desproporcionado en tarjetas altas.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Icon(
                        Icons.directions_car_outlined,
                        color: AppColors.carIcon,
                        size: width * 0.8,
                      ),
                    ),
                  ),
                ),
                // --- Disponibilidad -----------------------------------------
                SizedBox(
                  width: double.infinity,
                  height: width * 0.46,
                  child: lot == null
                      ? const Center(
                          child: SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : AvailabilityBadge(lot: lot),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Insignia blanca con el número de plazas en grande y en negritas.
///
/// - Fondo blanco → máximo contraste (antes: verde sobre naranja, difícil de
///   leer al sol).
/// - Color de semáforo + **texto** ("LLENO", "pocas") para no depender sólo
///   del color (accesibilidad para daltonismo).
/// - El número se anima al cambiar para que el usuario note la actualización.
class AvailabilityBadge extends StatelessWidget {
  const AvailabilityBadge({super.key, required this.lot, this.compact = false});

  final ParkingLot lot;

  /// Versión horizontal de una línea ("15 plazas"), para la pantalla de
  /// reporte.
  final bool compact;

  static Color colorFor(ParkingLot lot) => switch (lot.availability) {
        Availability.full => AppColors.fullText,
        Availability.low => AppColors.lowText,
        Availability.available => AppColors.availableText,
      };

  static String labelFor(ParkingLot lot) => switch (lot.availability) {
        Availability.full => 'LLENO',
        // "Pocas" lo comunica el color ámbar de la insignia.
        Availability.low ||
        Availability.available =>
          lot.availableSpots == 1 ? 'plaza' : 'plazas',
      };

  static String spokenText(ParkingLot lot) => lot.availability == Availability.full
      ? 'lleno'
      : '${lot.availableSpots} ${lot.availableSpots == 1 ? 'plaza disponible' : 'plazas disponibles'}';

  @override
  Widget build(BuildContext context) {
    final color = colorFor(lot);
    final full = lot.availability == Availability.full;

    final number = AnimatedNumber(
      value: lot.availableSpots,
      style: AppTextStyles.numbers(context, size: compact ? 20 : 26, color: color),
    );
    final label = Text(
      labelFor(lot),
      maxLines: 1,
      style: AppTextStyles.numbers(
        context,
        size: full ? (compact ? 18 : 20) : (compact ? 15 : 13),
        color: color,
        weight: full ? FontWeight.w900 : FontWeight.w700,
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 4, vertical: compact ? 6 : 2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(compact ? 999 : 12),
        border: Border.all(color: color, width: 2),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: compact
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!full) ...[number, const SizedBox(width: 6)],
                  label,
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: full ? [label] : [number, label],
              ),
      ),
    );
  }
}

/// Número que, al cambiar, hace salir el valor anterior hacia arriba y
/// entrar el nuevo desde abajo con un pequeño "pop" de escala.
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({super.key, required this.value, required this.style});

  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        final isIncoming = child.key == ValueKey<int>(value);
        final offset = Tween<Offset>(
          begin: Offset(0, isIncoming ? 0.6 : -0.6),
          end: Offset.zero,
        ).animate(animation);
        return ClipRect(
          child: SlideTransition(
            position: offset,
            child: FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
          ),
        );
      },
      child: Text('$value', key: ValueKey<int>(value), style: style),
    );
  }
}
