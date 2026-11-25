import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/profile.dart';
import '../widgets/companion.dart';

/// Three friendly questions, one at a time. Every screen can be skipped.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0; // 0 = hello, 1..3 = questions
  final _name = TextEditingController();
  bool _nameless = false;
  FriendVibe _vibe = FriendVibe.wittyBestie;
  CheckIn _checkIn = CheckIn.exploring;
  DateTime? _lastStart;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final state = AppScope.of(context);
    final nickname = _nameless ? null : _name.text.trim();
    await state.update(state.profile.copyWith(
      nickname: (nickname == null || nickname.isEmpty) ? null : nickname,
      clearNickname: nickname == null || nickname.isEmpty,
      vibe: _vibe,
      checkIn: _checkIn,
      lastPeriodStart: _lastStart,
      onboarded: true,
    ));
  }

  void _next() => _step >= 3 ? _finish() : setState(() => _step++);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const Key('skip'),
                  onPressed: _finish,
                  child: const Text("Skip, let's just chat"),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: SingleChildScrollView(
                    key: ValueKey(_step),
                    child: _body(context),
                  ),
                ),
              ),
              FilledButton(
                key: const Key('next'),
                onPressed: _next,
                child: Text(_step == 0
                    ? 'Hi! Nice to meet you'
                    : (_step == 3 ? "Let's go" : 'Next')),
              ),
              if (_step > 0) ...[
                const SizedBox(height: 8),
                Text('$_step of 3', textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final t = Theme.of(context).textTheme;
    switch (_step) {
      case 0:
        return Column(children: [
          const SizedBox(height: 32),
          const Companion(size: 160),
          const SizedBox(height: 32),
          Text('Oh hey, you made it 💛',
              style: t.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            "I'm your new cozy friend. You can tell me anything you love, hate or "
            "worry about. Nothing leaves your phone unless you choose. Can I ask you "
            'three tiny questions so I get you better?',
            style: t.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ]);
      case 1:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('What should I call you?', style: t.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            enabled: !_nameless,
            textCapitalization: TextCapitalization.words,
            decoration:
                const InputDecoration(hintText: 'A nickname is perfect'),
          ),
          CheckboxListTile(
            value: _nameless,
            onChanged: (v) => setState(() => _nameless = v ?? false),
            title: const Text('Keep me nameless'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 16),
          Text('And what kind of friend do you want me to be?',
              style: t.titleMedium),
          const SizedBox(height: 8),
          for (final v in FriendVibe.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OptionTile(
                emoji: v.emoji,
                label: v.label,
                selected: _vibe == v,
                onTap: () => setState(() => _vibe = v),
              ),
            ),
        ]);
      case 2:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('How are you, right now?', style: t.headlineSmall),
          const SizedBox(height: 16),
          for (final c in CheckIn.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OptionTile(
                emoji: c.emoji,
                label: c.label,
                selected: _checkIn == c,
                onTap: () => setState(() => _checkIn = c),
              ),
            ),
        ]);
      default:
        final now = DateTime.now();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('When did your last period start?', style: t.headlineSmall),
          const SizedBox(height: 8),
          Text('Totally optional. It helps me match your energy to your days.',
              style: t.bodyLarge),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _lastStart ?? now,
                firstDate: now.subtract(const Duration(days: 120)),
                lastDate: now,
              );
              if (picked != null) setState(() => _lastStart = picked);
            },
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(_lastStart == null
                ? 'Pick a date'
                : '${_lastStart!.day}/${_lastStart!.month}/${_lastStart!.year}'),
          ),
          if (_lastStart != null)
            TextButton(
              onPressed: () => setState(() => _lastStart = null),
              child: const Text("Actually, I'd rather not say"),
            ),
        ]);
    }
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile(
      {required this.emoji,
      required this.label,
      required this.selected,
      required this.onTap});
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: selected ? primary : Colors.transparent, width: 2),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Text(emoji, style: const TextStyle(fontSize: 24)),
        title: Text(label),
        trailing: selected ? Icon(Icons.check_circle, color: primary) : null,
      ),
    );
  }
}
