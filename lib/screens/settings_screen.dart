import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/profile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = state.profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Friend vibe', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            for (final v in FriendVibe.values)
              ChoiceChip(
                label: Text('${v.emoji} ${v.label}'),
                selected: p.vibe == v,
                onSelected: (_) => state.update(p.copyWith(vibe: v)),
              ),
          ]),
          const SizedBox(height: 16),
          SwitchListTile(
            value: state.nightMode,
            onChanged: (_) => state.toggleNight(),
            title: const Text('Cozy Dark mode'),
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Last period start'),
            subtitle: Text(p.lastPeriodStart == null
                ? 'Not set'
                : '${p.lastPeriodStart!.day}/${p.lastPeriodStart!.month}/${p.lastPeriodStart!.year}'),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: p.lastPeriodStart ?? now,
                firstDate: now.subtract(const Duration(days: 120)),
                lastDate: now,
              );
              if (picked != null) {
                await state.update(p.copyWith(lastPeriodStart: picked));
              }
            },
          ),
          const Divider(height: 32),
          const Text(
            '🔒 Your nickname, check-ins and cycle dates are stored only on this phone.\n\n'
            'CozyMoon is a wellness companion, not a medical service. It does not diagnose '
            'or treat anything. For health concerns, please talk to a doctor. In an emergency, '
            'call your local emergency number.',
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () async {
              await state.reset();
              if (context.mounted) {
                Navigator.of(context).popUntil((r) => r.isFirst);
              }
            },
            child: const Text('Erase my data and start over'),
          ),
        ],
      ),
    );
  }
}
