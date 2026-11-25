import 'package:flutter/material.dart';

import '../services/ambient_service.dart';

class SoundMixer extends StatelessWidget {
  const SoundMixer({super.key, required this.ambient});
  final AmbientService ambient;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ambient,
      builder: (context, _) => Column(children: [
        for (final a in Ambient.values)
          Row(children: [
            SizedBox(
                width: 36,
                child: Text(a.emoji, style: const TextStyle(fontSize: 22))),
            SizedBox(width: 120, child: Text(a.label)),
            Expanded(
              child: Slider(
                key: Key('mix-${a.name}'),
                value: ambient.volumes[a] ?? 0,
                onChanged: (v) => ambient.setVolume(a, v),
              ),
            ),
          ]),
      ]),
    );
  }
}

/// Small bar above the bottom tabs while any sound is on.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key, required this.ambient});
  final AmbientService ambient;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ambient,
      builder: (context, _) {
        if (!ambient.anyOn) return const SizedBox.shrink();
        final playing = [
          for (final a in Ambient.values)
            if ((ambient.volumes[a] ?? 0) > 0) a.emoji
        ].join(' ');
        return Material(
          key: const Key('mini-player'),
          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text('$playing  ${ambient.paused ? 'Paused' : 'Cozy sounds on'}'),
              const Spacer(),
              IconButton(
                tooltip: ambient.paused ? 'Play' : 'Pause',
                onPressed: ambient.togglePause,
                icon: Icon(ambient.paused ? Icons.play_arrow : Icons.pause),
              ),
              IconButton(
                  tooltip: 'Stop',
                  onPressed: ambient.stopAll,
                  icon: const Icon(Icons.stop)),
            ]),
          ),
        );
      },
    );
  }
}
