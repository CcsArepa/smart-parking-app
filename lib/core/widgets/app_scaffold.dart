import 'package:flutter/material.dart';

import 'app_bottom_nav.dart';
import 'app_header.dart';

/// Estructura base de cada pantalla: encabezado + contenido + barra inferior.
///
/// Dos modos:
/// - **Desplazable** ([slivers] / [fillRemaining]): el contenido va en un
///   [CustomScrollView]; si la pantalla es pequeña (o el usuario aumenta el
///   tamaño de letra del sistema) se desplaza en lugar de desbordarse.
/// - **Fijo** ([body]): para contenido que maneja sus propios gestos, como el
///   mapa (dentro de un scroll, arrastrar el mapa movería la página).
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.tab,
    this.slivers = const [],
    this.fillRemaining,
    this.body,
  });

  final AppTab tab;

  /// Contenido desplazable de la pantalla.
  final List<Widget> slivers;

  /// Contenido opcional que debe ocupar el espacio restante (p. ej. los dos
  /// botones gigantes de la pantalla de reporte).
  final Widget? fillRemaining;

  /// Contenido fijo (no desplazable) bajo el encabezado.
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final content = body != null
        ? Column(
            children: [
              const AppHeader(),
              Expanded(child: body!),
            ],
          )
        : CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              const SliverToBoxAdapter(child: AppHeader()),
              ...slivers,
              if (fillRemaining != null)
                SliverFillRemaining(hasScrollBody: false, child: fillRemaining),
            ],
          );

    return Scaffold(
      body: SafeArea(bottom: false, child: content),
      bottomNavigationBar: AppBottomNav(current: tab),
    );
  }
}
