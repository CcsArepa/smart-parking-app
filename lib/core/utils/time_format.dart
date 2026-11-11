import 'dart:async';

import 'package:flutter/widgets.dart';

/// Formatea una duración para personas: "menos de 1 min", "12 min",
/// "1 h 05 min".
String formatElapsed(Duration d) {
  if (d.inMinutes < 1) return 'menos de 1 min';
  if (d.inHours < 1) return '${d.inMinutes} min';
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  return '${d.inHours} h $m min';
}

/// Reloj tipo cronómetro: "00:12:07".
String formatClock(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
}

/// Reconstruye [builder] cada [interval] con el tiempo transcurrido desde
/// [since]. Cancela su temporizador al salir de pantalla.
class TickingElapsed extends StatefulWidget {
  const TickingElapsed({
    super.key,
    required this.since,
    required this.builder,
    this.interval = const Duration(seconds: 1),
  });

  final DateTime since;
  final Duration interval;
  final Widget Function(BuildContext context, Duration elapsed) builder;

  @override
  State<TickingElapsed> createState() => _TickingElapsedState();
}

class _TickingElapsedState extends State<TickingElapsed> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.since);
    return widget.builder(context, elapsed.isNegative ? Duration.zero : elapsed);
  }
}
