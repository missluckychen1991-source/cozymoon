import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../content/stories.dart';
import '../content/videos.dart';
import '../nook/bubble_wrap.dart';
import '../nook/lantern.dart';
import '../nook/rocks_game.dart';
import '../nook/sand_garden.dart';
import '../nook/sound_mixer.dart';
import '../nook/story_reader.dart';
import '../nook/tea_pour.dart';
import '../nook/video_player.dart';
import '../services/story_service.dart';

/// Stress relief for hard days: games, stories, calm videos and soft sounds.
class CozyNookScreen extends StatefulWidget {
  const CozyNookScreen({super.key, this.random, this.storyService});
  final Random? random;
  final StoryService? storyService;

  @override
  State<CozyNookScreen> createState() => _CozyNookScreenState();
}

class _CozyNookScreenState extends State<CozyNookScreen> {
  late final Random _r = widget.random ?? Random();
  late final StoryService _stories =
      widget.storyService ?? StoryService(random: _r);
  String _setting = storySettings.first;
  String _vibe = storyVibes.first;
  bool _writing = false;

  static List<List<Widget>> _pairs(List<Widget> w) => [
        for (var i = 0; i < w.length; i += 2) w.sublist(i, min(i + 2, w.length))
      ];

  void _push(Widget w) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

  void _envelope() {
    final pick = _r.nextInt(3);
    if (pick == 0) {
      _push(StoryReader(story: stories[_r.nextInt(stories.length)]));
    } else if (pick == 1) {
      const games = <Widget>[
        RocksGame(),
        BreathingLantern(),
        BubbleWrapGame(),
        SandGarden(),
        TeaPour(),
      ];
      _push(games[_r.nextInt(games.length)]);
    } else {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('💌 A tiny comfort'),
          content: Text(comfortPrompts[_r.nextInt(comfortPrompts.length)],
              key: const Key('comfort-prompt')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done 💛'))
          ],
        ),
      );
    }
  }

  Future<void> _writeStory() async {
    setState(() => _writing = true);
    final story = await _stories.write(_setting, _vibe);
    if (!mounted) return;
    setState(() => _writing = false);
    _push(StoryReader(story: story));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final ambient = AppScope.of(context).ambient;
    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 10),
          child: Text(title, style: t.titleMedium),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Cozy Nook 🛋️')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          FilledButton.icon(
            key: const Key('envelope'),
            onPressed: _envelope,
            icon: const Text('💌', style: TextStyle(fontSize: 20)),
            label: const Text('Open a Mystery Comfort Envelope'),
          ),
          const SizedBox(height: 6),
          Text('Too tired to choose? Let me pick something for you.',
              style: t.bodySmall, textAlign: TextAlign.center),
          section('Brain-free games'),
          for (final pair in _pairs([
            _Tile(
              key: const Key('game-rocks'),
              emoji: '🪨',
              title: 'Smash Annoyance Rocks',
              subtitle: 'Tap, pop, sparkle',
              onTap: () => _push(const RocksGame()),
            ),
            _Tile(
              key: const Key('game-lantern'),
              emoji: '🏮',
              title: 'Breathing Tea Lantern',
              subtitle: 'Hold and breathe',
              onTap: () => _push(const BreathingLantern()),
            ),
            _Tile(
              key: const Key('game-bubbles'),
              emoji: '🫧',
              title: 'Bubble Wrap Pop',
              subtitle: 'Pop, pop, refill',
              onTap: () => _push(const BubbleWrapGame()),
            ),
            _Tile(
              key: const Key('game-sand'),
              emoji: '🪷',
              title: 'Sand Garden',
              subtitle: 'Rake slow patterns',
              onTap: () => _push(const SandGarden()),
            ),
            _Tile(
              key: const Key('game-tea'),
              emoji: '🫖',
              title: 'Tea Pour',
              subtitle: 'Hold to pour a cup',
              onTap: () => _push(const TeaPour()),
            ),
          ]))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: IntrinsicHeight(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: pair.first),
                      const SizedBox(width: 12),
                      Expanded(
                          child: pair.length > 1 ? pair[1] : const SizedBox()),
                    ]),
              ),
            ),
          section('5-minute stories'),
          for (final s in stories)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading:
                      Text(s.tag.emoji, style: const TextStyle(fontSize: 24)),
                  title: Text(s.title),
                  subtitle: Text('${s.tag.label} · ${s.minutes} min'),
                  onTap: () => _push(StoryReader(story: s)),
                ),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✍️ Write me a 2-min cozy story', style: t.titleSmall),
                    const SizedBox(height: 10),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final s in storySettings)
                        ChoiceChip(
                            label: Text(s),
                            selected: _setting == s,
                            onSelected: (_) => setState(() => _setting = s)),
                    ]),
                    const SizedBox(height: 10),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final v in storyVibes)
                        ChoiceChip(
                            label: Text(v),
                            selected: _vibe == v,
                            onSelected: (_) => setState(() => _vibe = v)),
                    ]),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      key: const Key('write-story'),
                      onPressed: _writing ? null : _writeStory,
                      child: Text(
                          _writing ? 'Writing your story…' : 'Write it for me'),
                    ),
                  ]),
            ),
          ),
          section('No-doomscroll corner'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              for (final v in calmVideos)
                _Tile(
                    emoji: v.emoji,
                    title: v.title,
                    onTap: () => openCalmVideo(context, v)),
            ],
          ),
          section('Soft sounds'),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: SoundMixer(ambient: ambient),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(
      {super.key,
      required this.emoji,
      required this.title,
      this.subtitle,
      required this.onTap});
  final String emoji;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                Text(title,
                    style: t.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (subtitle != null) Text(subtitle!, style: t.bodySmall),
              ]),
        ),
      ),
    );
  }
}
