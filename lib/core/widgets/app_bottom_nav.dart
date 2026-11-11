import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'bounce_button.dart';

/// Pestañas de la barra inferior.
enum AppTab { home, map }

/// Barra de navegación inferior naranja con Inicio y Mapa.
///
/// Retroalimentación al tocar (todas a la vez, en < 100 ms):
/// - El icono **salta** con un arco y crece un poco.
/// - Onda de luz desde el dedo + sonido + vibración.
/// - La pestaña activa muestra una **pastilla** con su nombre, que aparece
///   con un rebote: el usuario siempre sabe dónde está.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.current});

  /// Pestaña a la que pertenece la pantalla actual.
  final AppTab current;

  void _onSelect(BuildContext context, AppTab tab) {
    final navigator = Navigator.of(context);
    switch (tab) {
      case AppTab.home:
        // Regresa a la raíz (Home) sin apilar pantallas duplicadas.
        navigator.popUntil((route) => route.isFirst);
      case AppTab.map:
        if (current == AppTab.map) return;
        navigator.pushNamed(AppRoutes.map);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.orange,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Inicio',
                selected: current == AppTab.home,
                onTap: () => _onSelect(context, AppTab.home),
              ),
              _NavItem(
                icon: Icons.map_rounded,
                label: 'Mapa',
                selected: current == AppTab.map,
                onTap: () => _onSelect(context, AppTab.map),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  /// Salto del icono (0 → 1).
  late final AnimationController _jump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void dispose() {
    _jump.dispose();
    super.dispose();
  }

  void _handleTap() {
    // El salto empieza de inmediato; la navegación espera un instante para
    // que el usuario alcance a verlo.
    _jump.forward(from: 0);
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted) widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;

    // Icono con salto: sube y crece siguiendo un arco (seno).
    final icon = AnimatedBuilder(
      animation: _jump,
      builder: (context, child) {
        final arc = math.sin(math.pi * _jump.value);
        return Transform.translate(
          offset: Offset(0, -10 * arc),
          child: Transform.scale(scale: 1 + 0.25 * arc, child: child),
        );
      },
      child: Icon(
        widget.icon,
        size: 34,
        // Atenuar con el color (no con Opacity) evita una capa extra.
        color: selected
            ? AppColors.green
            : AppColors.greenNav.withValues(alpha: 0.75),
      ),
    );

    final Widget content = selected
        // La pastilla aparece con un rebote elástico al llegar a la pantalla.
        ? TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, s, child) => Transform.scale(scale: s, child: child),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 18, 6),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.black, width: 2),
                boxShadow: AppTheme.shadow(blur: 6, dy: 3, alpha: 0.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: AppTextStyles.numbers(context, size: 16),
                  ),
                ],
              ),
            ),
          )
        : icon;

    return Expanded(
      child: BounceButton(
        onPressed: _handleTap,
        semanticLabel: selected ? '${widget.label}, seleccionado' : widget.label,
        pressedScale: 0.85,
        rippleRadius: BorderRadius.circular(999),
        // FittedBox: en teléfonos muy angostos la pastilla se reduce en vez
        // de desbordarse.
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: FittedBox(fit: BoxFit.scaleDown, child: content),
          ),
        ),
      ),
    );
  }
}
