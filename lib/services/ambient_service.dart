import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'sound_synth.dart';

enum Ambient { rain, piano, fire }

extension AmbientLabel on Ambient {
  String get label => switch (this) {
        Ambient.rain => 'Soft Rain',
        Ambient.piano => 'Warm Piano Pad',
        Ambient.fire => 'Fireplace Crackle',
      };
  String get emoji => switch (this) {
        Ambient.rain => '🌧️',
        Ambient.piano => '🎹',
        Ambient.fire => '🔥',
      };
}

/// The cozy sound mixer. Sounds keep playing while she moves around the app,
/// and a mini player shows at the bottom.
class AmbientService extends ChangeNotifier {
  AmbientService({this.enabled = true});

  /// Tests turn real audio off.
  final bool enabled;

  final Map<Ambient, double> volumes = {for (final a in Ambient.values) a: 0};
  final Map<Ambient, AudioPlayer> _players = {};
  final Map<Ambient, Uint8List> _bytes = {};
  bool paused = false;

  bool get anyOn => volumes.values.any((v) => v > 0);

  Uint8List _sound(Ambient a) => _bytes[a] ??= switch (a) {
        Ambient.rain => SoundSynth.rain(),
        Ambient.piano => SoundSynth.warmPad(),
        Ambient.fire => SoundSynth.fireplace(),
      };

  Future<void> setVolume(Ambient a, double v) async {
    volumes[a] = v.clamp(0, 1);
    if (v > 0) paused = false;
    notifyListeners();
    if (!enabled) return;
    try {
      final player = _players[a];
      if (v <= 0) {
        await player?.pause();
        return;
      }
      if (player == null) {
        final p = AudioPlayer();
        _players[a] = p;
        await p.setReleaseMode(ReleaseMode.loop);
        await p.setVolume(v);
        await p.play(BytesSource(_sound(a), mimeType: 'audio/wav'));
      } else {
        await player.setVolume(v);
        if (player.state != PlayerState.playing && !paused) {
          await player.resume();
        }
      }
    } catch (e) {
      debugPrint('ambient sound failed: $e');
    }
  }

  Future<void> togglePause() async {
    paused = !paused;
    notifyListeners();
    if (!enabled) return;
    for (final entry in _players.entries) {
      try {
        if (paused) {
          await entry.value.pause();
        } else if ((volumes[entry.key] ?? 0) > 0) {
          await entry.value.resume();
        }
      } catch (_) {}
    }
  }

  Future<void> stopAll() async {
    for (final a in Ambient.values) {
      volumes[a] = 0;
    }
    paused = false;
    notifyListeners();
    for (final p in _players.values) {
      try {
        await p.stop();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
    super.dispose();
  }
}

/// Short sound effects such as the rock "pop".
class Sfx {
  Sfx({this.enabled = true});
  final bool enabled;
  final List<AudioPlayer> _pool = [];
  int _next = 0;
  late final Uint8List _pop = SoundSynth.pop();

  Future<void> pop() async {
    if (!enabled) return;
    try {
      if (_pool.length < 4) {
        final p = AudioPlayer();
        await p.setPlayerMode(PlayerMode.lowLatency);
        _pool.add(p);
      }
      final p = _pool[_next++ % _pool.length];
      await p.stop();
      await p.setVolume(0.6);
      await p.play(BytesSource(_pop, mimeType: 'audio/wav'));
    } catch (_) {}
  }

  void dispose() {
    for (final p in _pool) {
      p.dispose();
    }
  }
}
