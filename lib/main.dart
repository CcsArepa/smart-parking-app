import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/feedback/app_feedback.dart';

/// Punto de entrada de Smart Parking (UDLAP).
///
/// `ProviderScope` es el contenedor de Riverpod: guarda el estado de todos los
/// providers (plazas en tiempo real, reportes, etc.) para toda la app.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Barra de estado transparente con iconos oscuros sobre el fondo verde.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  // Precarga los sonidos de la interfaz sin retrasar el arranque.
  AppFeedback.instance.init();

  runApp(const ProviderScope(child: UdlapParkingApp()));
}
