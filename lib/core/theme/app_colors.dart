import 'package:flutter/material.dart';

/// Paleta de colores de Smart Parking.
///
/// Los valores se muestrearon directamente de los bocetos
/// (`assets/mockups/`) para que la app coincida con el diseño aprobado.
abstract final class AppColors {
  /// Verde institucional: fondo principal de todas las pantallas.
  static const Color green = Color(0xFF1EA270);

  /// Verde más oscuro para textos sobre naranja (p. ej. "Plazas: 17").
  static const Color greenDark = Color(0xFF2E7D3E);

  /// Verde de los iconos de la barra inferior.
  static const Color greenNav = Color(0xFF4CAF5C);

  /// Naranja institucional: tarjetas y barra de navegación.
  static const Color orange = Color(0xFFED8A0F);

  /// Verde claro del botón "Estacioné con éxito".
  static const Color success = Color(0xFF7ED957);

  /// Rojo del botón "No hay lugares disponibles".
  static const Color danger = Color(0xFFFF2828);

  // --- Semáforo de disponibilidad (texto sobre fondo blanco) ----------------
  // Contraste ≥ 4.5:1 sobre blanco (WCAG AA). Siempre van acompañados de
  // texto ("LLENO", "plazas"), nunca se comunica sólo con color.
  static const Color availableText = Color(0xFF1B7A3A);
  static const Color lowText = Color(0xFFB45309);
  static const Color fullText = Color(0xFFC62828);

  static const Color black = Color(0xFF111111);
  static const Color white = Color(0xFFFFFFFF);

  /// Color de los iconos de autos dentro de las tarjetas.
  static const Color carIcon = Color(0xFF6B4A1E);
}
