import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sound_player.dart';

/// Sonidos de la interfaz (archivos en `assets/sounds/`, generados para este
/// proyecto, sin derechos de terceros).
enum UiSound {
  /// "Tic" corto para cualquier toque.
  tap('tap.wav'),

  /// Dos notas ascendentes: acción completada.
  success('success.wav'),

  /// Dos notas descendentes: aviso (estacionamiento lleno, error).
  alert('alert.wav'),

  /// Arpegio ascendente: el usuario liberó su lugar.
  leave('leave.wav');

  const UiSound(this.file);
  final String file;
}

/// Intensidad de la vibración háptica.
enum HapticStrength { none, selection, light, medium, heavy }

/// Retroalimentación multisensorial (sonido + vibración) de toda la app.
///
/// Principio de IHC: cada acción del usuario debe tener una respuesta
/// **inmediata** y perceptible. La vista (animación de rebote) la cubre
/// [BounceButton]; este servicio agrega el oído y el tacto.
///
/// - Los sonidos se precargan en modo de baja latencia (SoundPool en Android)
///   para que suenen en el mismo instante del toque.
/// - Se mezclan con la música del usuario en lugar de pausarla.
/// - Se reproducen como **sonidos de sistema** (no como multimedia): así
///   respetan el modo silencio/vibración del teléfono y el volumen del
///   sistema. Por eso la app no necesita su propio botón para silenciarlos.
class AppFeedback {
  AppFeedback._();

  /// Instancia única usada por los widgets.
  static final AppFeedback instance = AppFeedback._();

  /// Permite apagar los sonidos por código (p. ej. una futura pantalla de
  /// ajustes).
  bool soundEnabled = true;

  final SoundPlayer _player = createSoundPlayer();
  bool _ready = false;

  /// Precarga los sonidos. Se llama una vez en `main()`. Si falla (p. ej. en
  /// pruebas sin plugins nativos) la app sigue funcionando, sólo que muda.
  Future<void> init() async {
    if (_ready) return;
    try {
      await _player.init({
        for (final sound in UiSound.values) sound.name: 'assets/sounds/${sound.file}',
      });
      _ready = true;
    } catch (e) {
      debugPrint('AppFeedback: sonidos deshabilitados ($e)');
    }
  }

  /// Reproduce un sonido y una vibración **de inmediato** (sin esperas
  /// asíncronas: iOS sólo permite audio iniciado dentro del toque). Nunca
  /// lanza excepciones: la retroalimentación jamás debe romper una acción.
  void play(UiSound sound, {HapticStrength haptic = HapticStrength.light}) {
    vibrate(haptic);
    if (!soundEnabled || !_ready) return;
    try {
      _player.play(sound.name, volume: sound == UiSound.tap ? 0.6 : 0.85);
    } catch (_) {/* Ignorado a propósito. */}
  }

  /// Sólo vibración (sin sonido).
  void vibrate(HapticStrength haptic) {
    switch (haptic) {
      case HapticStrength.none:
        break;
      case HapticStrength.selection:
        HapticFeedback.selectionClick();
      case HapticStrength.light:
        HapticFeedback.lightImpact();
      case HapticStrength.medium:
        HapticFeedback.mediumImpact();
      case HapticStrength.heavy:
        HapticFeedback.heavyImpact();
    }
  }
}
