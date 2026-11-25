import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/cycle.dart';
import '../models/profile.dart';
import '../widgets/companion.dart';
import 'chat_screen.dart';
import 'home_shell.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const starters = [
    'Annoyed at everyone today',
    'Worried about getting older',
    'Period cramps suck',
    'Share a small win',
  ];

  String _greeting(Profile p, CycleStatus c) {
    final name = p.displayName;
    final hour = DateTime.now().hour;
    final hello = hour < 12 ? 'Morning' : (hour < 18 ? 'Hey' : 'Evening');
    return switch (p.checkIn) {
      CheckIn.crampy =>
        '$hello $name. Heating pad on, expectations off. I\'m right here.',
      CheckIn.stressed =>
        '$hello $name. Brain-fog days are real. Let\'s go slow today.',
      CheckIn.prettyGood =>
        '$hello $name! Love that for you. What\'s making today good?',
      CheckIn.exploring => c.mode == Mode.cozyCocoon
          ? '$hello $name. Cocoon season. Be extra soft with yourself.'
          : '$hello $name! Pull up a chair, the tea is warm.',
    };
  }

  Future<void> _openChat(BuildContext context, [String? starter]) async {
    final shell = context.findAncestorStateOfType<HomeShellState>();
    final tab = await Navigator.of(context).push<int>(
        MaterialPageRoute(builder: (_) => ChatScreen(starter: starter)));
    if (tab != null) shell?.goTo(tab);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = state.profile;
    final c = state.cycle;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CozyMoon'),
        actions: [
          IconButton(
            tooltip: state.nightMode ? 'Warm Tea theme' : 'Cozy Dark theme',
            onPressed: state.toggleNight,
            icon: Icon(state.nightMode
                ? Icons.wb_sunny_outlined
                : Icons.nightlight_outlined),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                const Companion(size: 84),
                const SizedBox(width: 16),
                Expanded(child: Text(_greeting(p, c), style: t.titleMedium)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: scheme.primary.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        c.day == null
                            ? '${c.mode.emoji} ${c.mode.label}'
                            : 'Day ${c.day} · ${c.mode.emoji} ${c.mode.label}',
                        key: const Key('phase'),
                        style: t.titleLarge),
                    const SizedBox(height: 6),
                    Text(c.mode.blurb, style: t.bodyMedium),
                  ]),
            ),
          ),
          const SizedBox(height: 20),
          Text('How are you feeling?', style: t.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in CheckIn.values)
              ChoiceChip(
                label: Text('${m.emoji} ${m.label}'),
                selected: p.checkIn == m,
                onSelected: (_) => state.update(p.copyWith(checkIn: m)),
              ),
          ]),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('open-chat'),
            onPressed: () => _openChat(context),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Confide or Ask Me Anything'),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in starters)
              ActionChip(
                  label: Text(s), onPressed: () => _openChat(context, s)),
          ]),
        ],
      ),
    );
  }
}
