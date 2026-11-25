import 'dart:math';
import 'dart:typed_data';

/// Makes soft, copyright-free sounds in code, so nothing depends on audio
/// files or links that might break. Output is a mono 16-bit WAV.
class SoundSynth {
  static const sampleRate = 22050;

  /// Gentle rain: filtered noise with a few soft droplets.
  static Uint8List rain({double seconds = 8, int seed = 1}) {
    final r = Random(seed);
    double lp1 = 0, lp2 = 0;
    return _loop(seconds, (i) {
      final white = r.nextDouble() * 2 - 1;
      lp1 += 0.12 * (white - lp1);
      lp2 += 0.03 * (white - lp2);
      var s = lp1 * 0.7 + lp2 * 1.6;
      if (r.nextDouble() < 0.0006) s += (r.nextDouble() - 0.5) * 0.5;
      return s * 0.55;
    });
  }

  /// Warm, slow piano-like pad: a soft chord that breathes in and out.
  static Uint8List warmPad({double seconds = 12}) {
    const notes = [110.0, 164.81, 261.63, 329.63, 392.0]; // A2 E3 C4 E4 G4
    return _loop(seconds, (i) {
      final t = i / sampleRate;
      var s = 0.0;
      for (var n = 0; n < notes.length; n++) {
        final f = notes[n];
        final swell =
            0.6 + 0.4 * sin(2 * pi * t / seconds * (n.isEven ? 1 : 2) + n);
        s += swell *
            (sin(2 * pi * f * t) + 0.25 * sin(4 * pi * f * t)) /
            (n + 2);
      }
      return s * 0.35;
    });
  }

  /// Fireplace: low rumble plus random crackles.
  static Uint8List fireplace({double seconds = 8, int seed = 7}) {
    final r = Random(seed);
    double lp = 0, crackle = 0;
    return _loop(seconds, (i) {
      final white = r.nextDouble() * 2 - 1;
      lp += 0.02 * (white - lp);
      if (r.nextDouble() < 0.0012) {
        crackle = (r.nextDouble() * 0.8 + 0.2) * (r.nextBool() ? 1 : -1);
      }
      crackle *= 0.93;
      final pop = crackle * (r.nextDouble() * 2 - 1);
      return lp * 2.2 + pop * 0.6;
    });
  }

  /// A short, soft "pop" for the rocks game.
  static Uint8List pop({int seed = 3}) {
    final r = Random(seed);
    const n = sampleRate ~/ 6;
    final samples = Float64List(n);
    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      final env = exp(-t * 28);
      final freq = 520 + 380 * exp(-t * 18);
      samples[i] = env *
          (sin(2 * pi * freq * t) * 0.6 +
              (r.nextDouble() - 0.5) * 0.15 * exp(-t * 60));
    }
    return _wav(samples);
  }

  /// Builds [seconds] of audio and cross-fades the ends so it loops without a click.
  static Uint8List _loop(double seconds, double Function(int i) gen) {
    final n = (seconds * sampleRate).round();
    const fade = sampleRate ~/ 2;
    final raw = Float64List(n + fade);
    for (var i = 0; i < raw.length; i++) {
      raw[i] = gen(i);
    }
    final out = Float64List(n);
    for (var i = 0; i < n; i++) {
      if (i < fade) {
        final w = i / fade;
        out[i] = raw[i] * w + raw[n + i] * (1 - w);
      } else {
        out[i] = raw[i];
      }
    }
    return _wav(out);
  }

  static Uint8List _wav(Float64List samples) {
    var peak = 0.0;
    for (final s in samples) {
      peak = max(peak, s.abs());
    }
    final gain = peak > 0.9 ? 0.9 / peak : 1.0;
    final dataLen = samples.length * 2;
    final b = ByteData(44 + dataLen);
    void str(int o, String s) {
      for (var i = 0; i < s.length; i++) {
        b.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    b.setUint32(4, 36 + dataLen, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    b.setUint32(16, 16, Endian.little);
    b.setUint16(20, 1, Endian.little); // PCM
    b.setUint16(22, 1, Endian.little); // mono
    b.setUint32(24, sampleRate, Endian.little);
    b.setUint32(28, sampleRate * 2, Endian.little);
    b.setUint16(32, 2, Endian.little);
    b.setUint16(34, 16, Endian.little);
    str(36, 'data');
    b.setUint32(40, dataLen, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      b.setInt16(
          44 + i * 2,
          (samples[i] * gain * 32767).round().clamp(-32768, 32767),
          Endian.little);
    }
    return b.buffer.asUint8List();
  }
}
