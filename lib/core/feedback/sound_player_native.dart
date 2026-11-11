import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'sound_player.dart';

SoundPlayer createPlatformSoundPlayer() => NativeSoundPlayer();

/// Android / iOS nativo.
///
/// Usa [AudioPool]: varios reproductores precargados por sonido, pensados
/// para efectos cortos que se repiten rápido (toques seguidos se superponen
/// en lugar de cortarse o perderse).
class NativeSoundPlayer implements SoundPlayer {
  final Map<String, AudioPool> _pools = {};

  @override
  Future<void> init(Map<String, String> assets) async {
    await AudioPlayer.global.setAudioContext(AudioContext(
      // Android: canal de "sonidos de interfaz" → se silencia con el modo
      // silencio/vibración y no interrumpe la música.
      android: const AudioContextAndroid(
        usageType: AndroidUsageType.assistanceSonification,
        contentType: AndroidContentType.sonification,
        audioFocus: AndroidAudioFocus.none,
      ),
      // iOS: categoría "ambient" → respeta el interruptor de silencio.
      iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
    ));

    for (final MapEntry(key: id, value: path) in assets.entries) {
      _pools[id] = await AudioPool.createFromAsset(
        // AssetSource ya antepone "assets/".
        path: path.replaceFirst('assets/', ''),
        maxPlayers: 4,
        minPlayers: 2,
        playerMode: PlayerMode.lowLatency,
      );
    }
  }

  @override
  void play(String id, {double volume = 1}) {
    final pool = _pools[id];
    if (pool == null) return;
    unawaited(pool.start(volume: volume).then<void>((_) {}, onError: (_) {}));
  }
}
