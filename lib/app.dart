import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Raíz visual de la app: tema global y rutas.
class UdlapParkingApp extends StatelessWidget {
  const UdlapParkingApp({super.key, this.useGoogleFonts = true});

  /// En pruebas se desactiva para no descargar fuentes de internet.
  final bool useGoogleFonts;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Parking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(useGoogleFonts: useGoogleFonts),
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
