import 'package:flutter/material.dart';

/// Texto que "vuela" entre pantallas con una animación [Hero].
///
/// Resuelve dos problemas típicos de los Hero de texto:
/// 1. **Subrayado amarillo** durante el vuelo: ocurre porque el texto queda
///    fuera de un `Material`. Se envuelve en `Material.transparency`.
/// 2. **Saltos de línea / overflow** cuando el texto cambia de tamaño (p. ej.
///    18 px en la tarjeta → 24 px en el título). El [flightShuttleBuilder]
///    usa un `FittedBox` para que el texto se **escale** suavemente en lugar
///    de reacomodarse letra por letra.
class HeroText extends StatelessWidget {
  const HeroText({
    super.key,
    required this.tag,
    required this.text,
    this.style,
    this.textAlign,
  });

  final Object tag;
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: scalingShuttle,
      child: Material(
        type: MaterialType.transparency,
        child: Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }
}

/// Hero para iconos: el icono se escala para llenar el área disponible, por lo
/// que crece/encoge de forma continua durante el vuelo.
class HeroIcon extends StatelessWidget {
  const HeroIcon({
    super.key,
    required this.tag,
    required this.icon,
    required this.color,
  });

  final Object tag;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: FittedBox(child: Icon(icon, color: color, size: 96)),
    );
  }
}

/// Durante el vuelo muestra el widget de **destino** (o de origen al regresar)
/// escalado dentro del rectángulo animado.
Widget scalingShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final hero = (direction == HeroFlightDirection.push
      ? toHeroContext.widget
      : fromHeroContext.widget) as Hero;
  return FittedBox(fit: BoxFit.contain, child: hero.child);
}
