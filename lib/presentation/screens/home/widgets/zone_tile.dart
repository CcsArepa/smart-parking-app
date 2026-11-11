import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bounce_button.dart';
import '../../../../core/widgets/hero_widgets.dart';
import '../../../../domain/entities/zone.dart';
import '../../../providers/parking_providers.dart';

/// Traduce la categoría de dominio a un icono de Material.
///
/// Se eligieron los iconos más cercanos a los bocetos (engrane, edificio,
/// libro, maletín médico). Si después tienen iconos propios en PNG/SVG, sólo
/// hay que cambiar este mapeo.
extension ZoneKindIcon on ZoneKind {
  IconData get icon => switch (this) {
        ZoneKind.engineering => Icons.precision_manufacturing_outlined,
        ZoneKind.business => Icons.account_balance_outlined,
        ZoneKind.humanities => Icons.auto_stories_outlined,
        ZoneKind.health => Icons.medical_services_outlined,
      };
}

/// Tarjeta rectangular naranja de la pantalla de inicio (Ingeniería…).
///
/// - Se estira para llenar el alto disponible (sin espacio vacío abajo).
/// - Muestra en vivo el total de plazas libres de la zona: el usuario puede
///   decidir **sin** tener que entrar ("información a la vista").
/// - El icono y el nombre son [Hero]: al tocar "vuelan" hacia el título de la
///   pantalla de la zona, conectando visualmente ambas pantallas.
class ZoneTile extends ConsumerWidget {
  const ZoneTile({super.key, required this.zone, required this.onTap});

  final Zone zone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final free = ref.watch(zoneFreeSpotsProvider(zone));

    return BounceButton(
      onPressed: onTap,
      // Onda de luz desde el dedo + breve pausa para verla antes de
      // cambiar de pantalla.
      rippleRadius: BorderRadius.circular(AppTheme.radius),
      actionDelay: const Duration(milliseconds: 160),
      pressedScale: 0.93,
      semanticLabel: free == null
          ? 'Estacionar cerca de ${zone.name}'
          : 'Estacionar cerca de ${zone.name}, $free plazas libres',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.fromBorderSide(AppTheme.outline),
          boxShadow: AppTheme.shadow(blur: 8, dy: 4, alpha: 0.2),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: HeroIcon(
                    tag: HeroTags.zoneIcon(zone.id),
                    icon: zone.kind.icon,
                    color: AppColors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // FittedBox evita que "Humanidades" se corte en tarjetas angostas.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: HeroText(
                  tag: HeroTags.zoneTitle(zone.id),
                  text: zone.name,
                  style: textTheme.bodyLarge!.copyWith(fontSize: 20),
                ),
              ),
              const SizedBox(height: 6),
              _FreeSpotsPill(free: free),
            ],
          ),
        ),
      ),
    );
  }
}

/// "52 plazas libres" en una pastilla blanca, animada al cambiar.
class _FreeSpotsPill extends StatelessWidget {
  const _FreeSpotsPill({required this.free});
  final int? free;

  @override
  Widget build(BuildContext context) {
    final value = free;
    final color = value == null
        ? AppColors.black
        : value == 0
            ? AppColors.fullText
            : value <= 5
                ? AppColors.lowText
                : AppColors.availableText;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 1.5),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: ScaleTransition(scale: a, child: child),
          ),
          child: Text(
            value == null
                ? 'Cargando…'
                : value == 0
                    ? 'Sin lugares'
                    : '$value plazas libres',
            key: ValueKey(value),
            style: AppTextStyles.numbers(context, size: 14, color: color),
          ),
        ),
      ),
    );
  }
}
