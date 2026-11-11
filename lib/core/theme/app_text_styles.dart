import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografía de la app (dos familias, cada una con un propósito):
///
/// - **Marcellus** (serif clásica, como en los bocetos) → sólo títulos y la
///   marca. Le da personalidad institucional.
/// - **Nunito** (sans-serif redondeada) → textos, botones y **números**.
///   En Marcellus el "0" se confunde con la "O" y el "1" con la "I"
///   ("E10" se leía "E1O"), un problema serio de legibilidad para una app
///   cuyo dato principal es un número. Nunito tiene dígitos inequívocos.
///
/// Si [useGoogleFonts] es `false` (pruebas sin internet) se usan las fuentes
/// del sistema con los mismos tamaños y pesos.
abstract final class AppTextStyles {
  static TextTheme textTheme({bool useGoogleFonts = true}) {
    const base = TextTheme(
      // "¿Dónde deseas estacionar?" / nombre de la zona
      headlineSmall: TextStyle(fontSize: 26, color: AppColors.black),
      // Títulos secundarios
      titleLarge: TextStyle(fontSize: 22, color: AppColors.black),
      // Subtítulos de sección: "Estacionamientos principales:"
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.black,
      ),
      // Etiquetas de tarjetas
      bodyLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.black,
      ),
      bodyMedium: TextStyle(fontSize: 15, color: AppColors.black),
      // Texto de botones gigantes
      labelLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.black,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        color: AppColors.black,
        letterSpacing: 0.3,
      ),
    );
    if (!useGoogleFonts) return base;

    final serif = GoogleFonts.marcellusTextTheme(base);
    final sans = GoogleFonts.nunitoTextTheme(base);
    return sans.copyWith(
      headlineSmall: serif.headlineSmall,
      titleLarge: serif.titleLarge,
    );
  }

  /// Estilo para cifras (plazas, nombres como "E10"): Nunito con dígitos
  /// tabulares para que el número no "baile" de ancho al animarse.
  static TextStyle numbers(
    BuildContext context, {
    double size = 18,
    Color color = AppColors.black,
    FontWeight weight = FontWeight.w800,
  }) {
    final base = Theme.of(context).textTheme.bodyLarge!;
    return base.copyWith(
      fontSize: size,
      color: color,
      fontWeight: weight,
      fontFeatures: const [FontFeature.tabularFigures()],
      height: 1.1,
    );
  }
}
