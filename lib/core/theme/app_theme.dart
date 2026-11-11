import 'package:flutter/material.dart';

import '../utils/performance.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// [ThemeData] global de la aplicación.
///
/// Centraliza colores, tipografía y formas para que ninguna pantalla tenga
/// que "inventar" estilos: todas leen de `Theme.of(context)`.
abstract final class AppTheme {
  /// Radio de esquina usado en tarjetas y botones (bocetos: ~18 px).
  static const double radius = 18;

  /// Borde negro de 2 px que tienen todas las tarjetas en los bocetos.
  static const BorderSide outline = BorderSide(color: AppColors.black, width: 2);

  /// Sombra de tarjetas y botones.
  ///
  /// - **Android/iOS nativo:** sombra difuminada suave.
  /// - **Web** ([kLightAnimations]): sombra **sólida** desplazada, sin
  ///   difuminado. En el navegador, cada sombra difuminada se recalcula en
  ///   cada cuadro de animación (muy costoso en pantallas de 120 Hz); la
  ///   sólida se dibuja casi gratis y combina con los bordes negros.
  static List<BoxShadow> shadow({
    double blur = 8,
    double dy = 4,
    double alpha = 0.2,
  }) =>
      [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, kLightAnimations ? alpha + 0.05 : alpha),
          blurRadius: kLightAnimations ? 0 : blur,
          offset: Offset(0, kLightAnimations ? (dy * 0.75).roundToDouble() : dy),
        ),
      ];

  static ThemeData light({bool useGoogleFonts = true}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.green,
      primary: AppColors.green,
      onPrimary: AppColors.white,
      secondary: AppColors.orange,
      onSecondary: AppColors.black,
      error: AppColors.danger,
      surface: AppColors.green,
      onSurface: AppColors.black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.green,
      textTheme: AppTextStyles.textTheme(useGoogleFonts: useGoogleFonts),
      splashFactory: InkSparkle.splashFactory,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.black,
        contentTextStyle: TextStyle(color: AppColors.white, fontSize: 15),
        actionTextColor: AppColors.orange,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radius)),
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.orange,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radius)),
          side: outline,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.black,
      ),
    );
  }
}
