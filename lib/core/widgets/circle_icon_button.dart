import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'bounce_button.dart';

/// Botón circular con icono (Volver, Sonido…).
///
/// - Tamaño 52 px: supera el mínimo recomendado de 48 px de área táctil
///   (Material / WCAG 2.5.5), fácil de alcanzar con el pulgar.
/// - Rebote al tocar (más pronunciado que en tarjetas, al ser pequeño).
/// - El icono cambia con una transición de giro + escala cuando [icon] cambia
///   (p. ej. bocina activa → silenciada).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.size = 52,
    this.background = AppColors.orange,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final double size;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: BounceButton(
        onPressed: onPressed,
        pressedScale: 0.82,
        semanticLabel: tooltip,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.fromBorderSide(AppTheme.outline),
            boxShadow: AppTheme.shadow(blur: 6, dy: 3, alpha: 0.2),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => RotationTransition(
              turns: Tween<double>(begin: -0.15, end: 0).animate(anim),
              child: ScaleTransition(scale: anim, child: child),
            ),
            child: Icon(
              icon,
              key: ValueKey(icon),
              size: size * 0.52,
              color: AppColors.black,
            ),
          ),
        ),
      ),
    );
  }
}
