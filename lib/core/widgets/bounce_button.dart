import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../feedback/app_feedback.dart';

export '../feedback/app_feedback.dart' show HapticStrength, UiSound;

/// Envuelve cualquier widget y le da un efecto de "rebote" táctil, con sonido
/// y vibración.
///
/// Comportamiento (micro-interacción):
/// 1. **Al tocar** (`onTapDown`) el widget se encoge a [pressedScale] de
///    inmediato, sin esperar a que el dedo se levante. Esto es lo que da la
///    sensación de respuesta instantánea.
/// 2. **Al soltar** (`onTapUp`) regresa a su tamaño con una curva elástica
///    (un pequeño "rebote"), suena [sound] y vibra.
/// 3. **Onda de luz** (si se indica [rippleRadius]): un círculo de luz se
///    expande desde el punto exacto del toque, como confirmación visual de
///    "¡lo tocaste aquí!" (el mismo lenguaje que el botón de registro).
/// 4. [onPressed] se ejecuta de inmediato o, si se indica [actionDelay],
///    un instante después, para que el usuario alcance a ver la onda antes
///    de cambiar de pantalla.
/// 5. **Si el gesto se cancela** (el usuario arrastra el dedo fuera) regresa
///    al tamaño normal sin ejecutar la acción ni sonar.
///
/// Además se anuncia como botón a los lectores de pantalla ([Semantics]).
class BounceButton extends StatefulWidget {
  const BounceButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.pressedScale = 0.94,
    this.semanticLabel,
    this.haptic = HapticStrength.light,
    this.sound = UiSound.tap,
    this.rippleRadius,
    this.rippleColor = Colors.white,
    this.actionDelay = Duration.zero,
  });

  final Widget child;

  /// Acción a ejecutar. Si es `null`, el botón queda deshabilitado (no se
  /// anima y se muestra semitransparente).
  final VoidCallback? onPressed;

  /// Escala mínima mientras el dedo está presionando (1.0 = sin cambio).
  final double pressedScale;

  /// Texto que leerán TalkBack / VoiceOver.
  final String? semanticLabel;

  final HapticStrength haptic;

  /// Sonido al tocar; `null` para silencio (p. ej. si la acción reproducirá
  /// su propio sonido de resultado).
  final UiSound? sound;

  /// Si no es `null`, activa la onda de luz recortada a este redondeo (debe
  /// coincidir con las esquinas del hijo).
  final BorderRadius? rippleRadius;
  final Color rippleColor;

  /// Pausa antes de ejecutar [onPressed] (p. ej. 160 ms antes de navegar).
  final Duration actionDelay;

  @override
  State<BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<BounceButton>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    // Bajada rápida: el feedback debe sentirse inmediato (< 100 ms).
    duration: const Duration(milliseconds: 90),
    // Subida más lenta para que el rebote elástico se aprecie.
    reverseDuration: const Duration(milliseconds: 420),
  );

  /// Onda de luz (0 → 1).
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  late Animation<double> _scale = _buildScale();
  Offset _tapPoint = Offset.zero;
  Timer? _delayed;

  Animation<double> _buildScale() => Tween<double>(
        begin: 1.0,
        end: widget.pressedScale,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        // Al revertir, la curva elástica produce el "bounce".
        reverseCurve: Curves.elasticIn,
      ));

  bool get _enabled => widget.onPressed != null;
  bool get _hasRipple => widget.rippleRadius != null;

  @override
  void didUpdateWidget(covariant BounceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pressedScale != widget.pressedScale) {
      _scale = _buildScale();
    }
  }

  @override
  void dispose() {
    _delayed?.cancel();
    _controller.dispose();
    _ripple.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_enabled) return;
    _tapPoint = details.localPosition;
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (!_enabled) return;
    // Aseguramos que la animación de bajada se vea aunque el tap sea muy
    // corto, y luego regresamos con rebote.
    _controller.forward().then((_) {
      if (mounted) _controller.reverse();
    });
    if (_hasRipple) _ripple.forward(from: 0);

    // El sonido y la vibración van SIEMPRE de inmediato, dentro del toque
    // (iOS bloquea el audio que no se inicia en el gesto).
    final sound = widget.sound;
    if (sound != null) {
      AppFeedback.instance.play(sound, haptic: widget.haptic);
    } else {
      AppFeedback.instance.vibrate(widget.haptic);
    }

    final action = widget.onPressed!;
    if (widget.actionDelay == Duration.zero) {
      action();
    } else {
      _delayed?.cancel();
      _delayed = Timer(widget.actionDelay, () {
        if (mounted) action();
      });
    }
  }

  void _handleTapCancel() {
    if (!_enabled) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = widget.child;
    if (_hasRipple) {
      content = Stack(
        fit: StackFit.passthrough,
        children: [
          content,
          // La onda sólo existe mientras se anima: en reposo no cuesta nada.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _ripple,
                builder: (context, _) {
                  if (!_ripple.isAnimating) return const SizedBox.shrink();
                  // El recorte se hace dentro del pintor (canvas.clipRRect)
                  // en lugar de con un widget ClipRRect: evita crear una
                  // capa extra en cada cuadro.
                  return CustomPaint(
                    painter: _RipplePainter(
                      center: _tapPoint,
                      progress: _ripple.value,
                      color: widget.rippleColor,
                      borderRadius: widget.rippleRadius!,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      onTap: widget.onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _enabled ? 1 : 0.55,
          child: ScaleTransition(scale: _scale, child: content),
        ),
      ),
    );
  }
}

/// Círculo de luz que crece desde el punto del toque y se desvanece.
///
/// Se pinta con un color cuya transparencia cambia (no con `Opacity`), así
/// no crea capas extra: es barato incluso en la versión web.
class _RipplePainter extends CustomPainter {
  _RipplePainter({
    required this.center,
    required this.progress,
    required this.color,
    required this.borderRadius,
  });

  final Offset center;
  final double progress;
  final Color color;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRRect(borderRadius.toRRect(Offset.zero & size));
    // Radio necesario para cubrir la esquina más lejana del toque.
    final maxRadius = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((c) => (c - center).distance).reduce(math.max);

    final t = Curves.easeOutCubic.transform(progress);
    final alpha = 0.45 * (1 - progress);
    canvas.drawCircle(
      center,
      maxRadius * t,
      Paint()..color = color.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.progress != progress || old.center != center;
}
