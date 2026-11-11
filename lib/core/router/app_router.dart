import 'package:flutter/material.dart';

import '../../domain/entities/zone.dart';
import '../utils/performance.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/map/map_screen.dart';
import '../../presentation/screens/report/report_screen.dart';
import '../../presentation/screens/session/active_session_screen.dart';
import '../../presentation/screens/zone_detail/zone_detail_screen.dart';

/// Nombres de las rutas de la app.
abstract final class AppRoutes {
  static const String home = '/';
  static const String zone = '/zone';
  static const String report = '/report';
  static const String session = '/session';
  static const String map = '/map';
}

/// Argumentos de la pantalla de reporte.
class ReportArgs {
  const ReportArgs({required this.zone, required this.lotId});
  final Zone zone;
  final String lotId;
}

/// Construye las rutas y define **cómo** se anima el cambio de pantalla.
abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      AppRoutes.zone => ZoneDetailScreen(zone: settings.arguments! as Zone),
      AppRoutes.report => ReportScreen(args: settings.arguments! as ReportArgs),
      AppRoutes.session => ActiveSessionScreen(
          justParked: settings.arguments as bool? ?? false,
        ),
      AppRoutes.map => const MapScreen(),
      _ => const HomeScreen(),
    };
    return FadeThroughRoute(page: page, settings: settings);
  }
}

/// Transición de ruta suave: la pantalla nueva aparece con un fundido y un
/// leve desplazamiento vertical + escala, mientras la anterior se desvanece.
///
/// ¿Por qué no la transición por defecto?
/// - En Android, la transición por defecto "empuja" toda la pantalla y compite
///   visualmente con las animaciones [Hero]. Con un fundido, la vista del
///   usuario se concentra en los elementos que "vuelan" (iconos y títulos),
///   que es justamente el vínculo entre la pantalla de origen y la de destino.
/// - Dura 380 ms: suficientemente rápida para no sentirse lenta y
///   suficientemente larga para que el ojo siga el movimiento.
///
/// En la web ([kLightAnimations]) se usa un deslizamiento lateral tipo iOS
/// (sólo movimiento, sin transparencia), mucho más barato de dibujar en el
/// navegador del celular.
class FadeThroughRoute<T> extends PageRouteBuilder<T> {
  FadeThroughRoute({required Widget page, super.settings})
      : super(
          transitionDuration:
              Duration(milliseconds: kLightAnimations ? 300 : 380),
          reverseTransitionDuration:
              Duration(milliseconds: kLightAnimations ? 260 : 320),
          pageBuilder: (_, _, _) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            if (kLightAnimations) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              );
            }
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(curved),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
                  child: child,
                ),
              ),
            );
          },
        );
}
