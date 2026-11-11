import 'package:flutter/foundation.dart';

/// `true` en la versión web (Safari/Chrome en el celular).
///
/// En la web, los efectos de **transparencia** (`Opacity`, `FadeTransition`)
/// obligan a dibujar capas extra en cada cuadro de animación y son la
/// principal causa de "tirones" en teléfonos. Con esta bandera las
/// animaciones usan sólo movimiento y escala (baratos para la GPU), que se
/// perciben igual de fluidas.
const bool kLightAnimations = kIsWeb;
