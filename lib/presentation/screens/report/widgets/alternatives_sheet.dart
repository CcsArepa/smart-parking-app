import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bounce_button.dart';
import '../../../../domain/entities/parking_lot.dart';
import '../../../../domain/entities/zone.dart';
import '../../../providers/parking_providers.dart';
import '../../zone_detail/widgets/parking_lot_card.dart';

/// Hoja inferior que aparece tras reportar "No hay lugares disponibles":
/// "E10 está lleno. Prueba con: E12 (35), E11 (23)…".
///
/// Convierte un callejón sin salida en una siguiente acción clara.
Future<void> showAlternativesSheet(
  BuildContext context, {
  required Zone zone,
  required String fullLotId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // Permite que la hoja crezca lo necesario (y se desplace si no cabe).
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _AlternativesSheet(zone: zone, fullLotId: fullLotId),
  );
}

class _AlternativesSheet extends ConsumerWidget {
  const _AlternativesSheet({required this.zone, required this.fullLotId});

  final Zone zone;
  final String fullLotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final lots = ref.watch(parkingLotsProvider).value ?? const {};

    // Candidatos: todos los de la zona menos el lleno, con lugar, ordenados
    // de más a menos plazas. Máximo 3 para no abrumar (ley de Hick).
    final options = <ParkingLot>[
      for (final id in {...zone.primaryLotIds, ...zone.nearbyLotIds})
        if (id != fullLotId && (lots[id]?.availableSpots ?? 0) > 0) lots[id]!,
    ]..sort((a, b) => b.availableSpots.compareTo(a.availableSpots));
    final top = options.take(3).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gracias por avisar', style: textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              top.isEmpty
                  ? '$fullLotId se marcó como lleno. Por ahora no hay otros '
                      'estacionamientos con lugar en ${zone.name}.'
                  : '$fullLotId se marcó como lleno. Estos tienen lugar cerca:',
              style: textTheme.bodyMedium!.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 14),
            for (final lot in top) ...[
              _AlternativeTile(
                lot: lot,
                onTap: () {
                  final navigator = Navigator.of(context);
                  navigator.pop(); // cierra la hoja
                  navigator.pushReplacementNamed(
                    AppRoutes.report,
                    arguments: ReportArgs(zone: zone, lotId: lot.id),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: BounceButton(
                onPressed: () => Navigator.of(context).pop(),
                semanticLabel: 'Cerrar',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Cerrar',
                    style: textTheme.bodyLarge,
                    textAlign: TextAlign.center,
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

class _AlternativeTile extends StatelessWidget {
  const _AlternativeTile({required this.lot, required this.onTap});
  final ParkingLot lot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BounceButton(
      onPressed: onTap,
      pressedScale: 0.97,
      rippleRadius: BorderRadius.circular(AppTheme.radius),
      actionDelay: const Duration(milliseconds: 160),
      semanticLabel: 'Ir a ${lot.name}, ${AvailabilityBadge.spokenText(lot)}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.fromBorderSide(AppTheme.outline),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.white, size: 30),
            const SizedBox(width: 8),
            Text(lot.name, style: AppTextStyles.numbers(context, size: 24)),
            const SizedBox(width: 8),
            const Spacer(),
            Flexible(
              flex: 4,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: AvailabilityBadge(lot: lot, compact: true),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 28),
          ],
        ),
      ),
    );
  }
}
