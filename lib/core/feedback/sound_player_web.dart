import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

import 'sound_player.dart';

SoundPlayer createPlatformSoundPlayer() => WebSoundPlayer();

/// Navegador (incluye Safari en iPhone / app agregada a pantalla de inicio).
///
/// Usa la **Web Audio API** con los sonidos ya decodificados en memoria:
/// - Latencia casi nula (no hay que cargar ni decodificar al tocar).
/// - Cada toque crea una fuente nueva, así que los toques rápidos se
///   superponen sin cortarse.
/// - iOS bloquea el audio hasta el primer gesto del usuario: se "desbloquea"
///   el contexto en el primer toque y en cada `play()` (que se llama dentro
///   del manejador del toque).
/// - En iPhone, Web Audio respeta el interruptor de silencio.
class WebSoundPlayer implements SoundPlayer {
  web.AudioContext? _ctx;
  final Map<String, web.AudioBuffer> _buffers = {};

  @override
  Future<void> init(Map<String, String> assets) async {
    final ctx = web.AudioContext();
    _ctx = ctx;

    // Desbloqueo en el primer gesto (y en los siguientes, por si iOS
    // suspende el contexto al pasar la app a segundo plano).
    final unlock = ((web.Event _) => _resume()).toJS;
    for (final type in const ['pointerdown', 'touchstart', 'touchend', 'keydown']) {
      web.document.addEventListener(
        type,
        unlock,
        web.AddEventListenerOptions(passive: true, capture: true),
      );
    }

    await Future.wait(assets.entries.map((entry) async {
      // Resuelve la URL real del asset (respeta el --base-href).
      final url = ui_web.assetManager.getAssetUrl(entry.value);
      final response = await web.window.fetch(url.toJS).toDart;
      final data = await response.arrayBuffer().toDart;
      _buffers[entry.key] = await ctx.decodeAudioData(data).toDart;
    }));
  }

  void _resume() {
    final ctx = _ctx;
    if (ctx != null && ctx.state != 'running') ctx.resume();
  }

  @override
  void play(String id, {double volume = 1}) {
    final ctx = _ctx;
    final buffer = _buffers[id];
    if (ctx == null || buffer == null) return;
    _resume();

    final source = ctx.createBufferSource()..buffer = buffer;
    final gain = ctx.createGain()..gain.value = volume;
    source.connect(gain);
    gain.connect(ctx.destination);
    source.start();
  }
}
