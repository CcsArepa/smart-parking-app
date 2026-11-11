// Reproductor de efectos de sonido con una implementación por plataforma.
//
// La importación condicional elige el archivo correcto al compilar:
// - Web (Safari/Chrome): `sound_player_web.dart` → Web Audio API.
// - Android/iOS nativo: `sound_player_native.dart` → AudioPool (audioplayers).
// - Otros (pruebas en VM sin plugins): también el nativo, que falla en
//   silencio y deja la app muda.
import 'sound_player_native.dart'
    if (dart.library.js_interop) 'sound_player_web.dart' as impl;

/// Contrato común: precargar sonidos y reproducirlos al instante.
abstract interface class SoundPlayer {
  /// [assets]: id del sonido → ruta del asset (p. ej. `assets/sounds/tap.wav`).
  Future<void> init(Map<String, String> assets);

  /// Reproduce el sonido [id]. Debe ser **síncrono** y llamarse dentro del
  /// manejador del toque: iOS sólo permite audio iniciado por un gesto.
  void play(String id, {double volume = 1});
}

SoundPlayer createSoundPlayer() => impl.createPlatformSoundPlayer();
