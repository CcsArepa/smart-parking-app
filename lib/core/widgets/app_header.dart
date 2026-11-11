import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'circle_icon_button.dart';

/// Encabezado común a todas las pantallas, en una sola fila:
///
/// `[Volver]  [Logo]  Smart Parking`
/// `                  Estacionamiento universitario`
///
/// - El logo y la marca tienen **el mismo tamaño en todas las pantallas**:
///   el espacio del texto se calcula reservando siempre el lugar del botón
///   Volver. Así, cuando el botón aparece, el logo y el nombre sólo se
///   deslizan a la derecha (animado) sin encogerse, y la fila ocupa todo el
///   ancho de la pantalla.
/// - **Volver** sólo aparece si hay una pantalla anterior ("control y
///   libertad del usuario").
/// - No hay botón de sonido: los sonidos usan el canal de sistema y respetan
///   el modo silencio y el volumen del teléfono.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  static const double _hPadding = 12;
  static const double _backSize = 52;
  static const double _backGap = 10;
  static const double _logoGap = 12;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final screenW = MediaQuery.sizeOf(context).width;

    // Logo proporcional al ancho, con límites para teléfonos pequeños y
    // tabletas.
    final logoSize = (screenW * 0.21).clamp(68.0, 96.0);

    // Ancho del texto = lo que sobra cuando SÍ está el botón Volver. Es fijo
    // para todas las pantallas, por eso el nombre nunca cambia de tamaño.
    final textWidth = screenW -
        _hPadding * 2 -
        (_backSize + _backGap) -
        logoSize -
        _logoGap;

    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPadding, 8, _hPadding, 14),
      child: Row(
        children: [
          // El botón entra y sale animando su ancho: el logo y el nombre se
          // deslizan suavemente en lugar de "saltar".
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: canPop
                ? Padding(
                    padding: const EdgeInsets.only(right: _backGap),
                    child: CircleIconButton(
                      tooltip: 'Regresar',
                      icon: Icons.arrow_back_rounded,
                      size: _backSize,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          // El logo usa Hero con el mismo tag en todas las pantallas: así
          // permanece "fijo" mientras el resto de la UI cambia.
          Hero(
            tag: HeroTags.logo,
            child: Container(
              width: logoSize,
              height: logoSize,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border: Border.fromBorderSide(AppTheme.outline),
                boxShadow: AppTheme.shadow(blur: 6, dy: 3, alpha: 0.2),
              ),
              child: Image.asset(
                AppAssets.logo,
                semanticLabel: 'Logo de Smart Parking',
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          const SizedBox(width: _logoGap),
          // Flexible sólo como red de seguridad (pantallas muy angostas): en
          // condiciones normales el texto recibe exactamente [textWidth].
          Flexible(
            child: SizedBox(
              width: textWidth,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Smart Parking',
                      style: textTheme.titleLarge!.copyWith(
                        fontSize: 32,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Estacionamiento universitario',
                      style: textTheme.bodyMedium!.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
