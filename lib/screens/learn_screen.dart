import 'package:flutter/material.dart';

import '../content/lessons.dart';
import '../services/learning_store.dart';

/// "Today's 3 Gentle Steps": a short quiz, one idea, one small action.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key, this.store});
  final LearningStore? store;

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  late final LearningStore _store = widget.store ?? LearningStore();
  int? _today;
  Set<String> _done = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final today = await _store.todayIndex();
    final done = await _store.done();
    if (!mounted) return;
    setState(() {
      _today = today;
      _done = done;
    });
  }

  Future<void> _open(int day, StepKind kind, {bool preview = false}) async {
    final finished = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) =>
          LessonStepScreen(day: lessonDays[day], kind: kind, preview: preview),
    ));
    if (finished == true && !preview) {
      await _store.markDone(day, kind);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final today = _today;
    if (today == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final day = lessonDays[today];
    final count = StepKind.values
        .where((k) => _done.contains(LearningStore.key(today, k)))
        .length;
    final hasTomorrow = today + 1 < lessonDays.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Learn ✨')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Text("Today's 3 Gentle Steps", style: t.headlineSmall),
          const SizedBox(height: 4),
          Text('Day ${today + 1} · ${day.emoji} ${day.theme}',
              style: t.titleMedium),
          const SizedBox(height: 12),
          LinearProgressIndicator(
              value: count / 3,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8)),
          const SizedBox(height: 6),
          Text(
            count == 3
                ? "All done for today! See you tomorrow 💛"
                : '$count of 3 done · about 5 minutes in total',
            key: const Key('learn-progress'),
          ),
          const SizedBox(height: 16),
          for (final (i, kind) in StepKind.values.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StepCard(
                key: Key('step-${kind.name}'),
                number: i + 1,
                kind: kind,
                day: day,
                done: _done.contains(LearningStore.key(today, kind)),
                onTap: () => _open(today, kind),
              ),
            ),
          const SizedBox(height: 12),
          if (hasTomorrow)
            ExpansionTile(
              key: const Key('preview-tomorrow'),
              tilePadding: EdgeInsets.zero,
              title: const Text('👀 Preview tomorrow'),
              subtitle: Text(
                  '${lessonDays[today + 1].emoji} ${lessonDays[today + 1].theme}'),
              children: [
                for (final kind in StepKind.values)
                  ListTile(
                    title: Text(_title(lessonDays[today + 1], kind)),
                    subtitle: Text(_kindLabel(kind)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(today + 1, kind, preview: true),
                  ),
              ],
            )
          else
            const Text(
                '🌱 More lessons are growing. Revisit any day below while you wait.'),
          if (today > 0) ...[
            const Divider(height: 32),
            Text('Earlier days', style: t.titleSmall),
            for (var d = 0; d < today; d++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(lessonDays[d].emoji,
                    style: const TextStyle(fontSize: 22)),
                title: Text('Day ${d + 1} · ${lessonDays[d].theme}'),
                onTap: () => _open(d, StepKind.concept, preview: true),
              ),
          ],
          const SizedBox(height: 16),
          Text('General wellness info, not medical advice.',
              style: t.bodySmall),
        ],
      ),
    );
  }
}

String _kindLabel(StepKind k) => switch (k) {
      StepKind.quiz => '60-second quiz',
      StepKind.concept => 'One big idea',
      StepKind.action => 'Tiny solo action',
    };

String _title(LessonDay d, StepKind k) => switch (k) {
      StepKind.quiz => d.quiz.question,
      StepKind.concept => d.concept.title,
      StepKind.action => '${d.action.snackTitle} + ${d.action.stretchTitle}',
    };

class _StepCard extends StatelessWidget {
  const _StepCard(
      {super.key,
      required this.number,
      required this.kind,
      required this.day,
      required this.done,
      required this.onTap});
  final int number;
  final StepKind kind;
  final LessonDay day;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor:
              done ? scheme.secondary : scheme.primary.withValues(alpha: .15),
          child: done
              ? const Icon(Icons.check, color: Colors.white)
              : Text('$number'),
        ),
        title: Text(_kindLabel(kind)),
        subtitle: Text(_title(day, kind),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

/// One step. Pops `true` when she finishes it.
class LessonStepScreen extends StatefulWidget {
  const LessonStepScreen(
      {super.key, required this.day, required this.kind, this.preview = false});
  final LessonDay day;
  final StepKind kind;
  final bool preview;

  @override
  State<LessonStepScreen> createState() => _LessonStepScreenState();
}

class _LessonStepScreenState extends State<LessonStepScreen> {
  int? _picked;

  void _finish() => Navigator.of(context).pop(true);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final d = widget.day;

    final List<Widget> body;
    Widget? button;
    switch (widget.kind) {
      case StepKind.quiz:
        final q = d.quiz;
        body = [
          Text(q.question, style: t.titleLarge),
          const SizedBox(height: 16),
          for (final (i, o) in q.options.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                color: _picked == null
                    ? null
                    : (i == q.answer
                        ? scheme.secondary.withValues(alpha: .25)
                        : (i == _picked
                            ? scheme.error.withValues(alpha: .15)
                            : null)),
                child: ListTile(
                  key: Key('option-$i'),
                  title: Text(o),
                  trailing: _picked == null
                      ? null
                      : (i == q.answer ? const Icon(Icons.check_circle) : null),
                  onTap: _picked == null
                      ? () => setState(() => _picked = i)
                      : null,
                ),
              ),
            ),
          if (_picked != null) ...[
            const SizedBox(height: 8),
            Text(
                _picked == q.answer
                    ? '🎉 Yes!'
                    : '🤓 Close, here\'s the fun part:',
                style: t.titleMedium),
            const SizedBox(height: 6),
            Text(q.explain, key: const Key('quiz-explain'), style: t.bodyLarge),
          ],
        ];
        if (_picked != null) {
          button = FilledButton(
              key: const Key('step-done'),
              onPressed: _finish,
              child: const Text('Nice, done!'));
        }
      case StepKind.concept:
        final c = d.concept;
        body = [
          Text(c.title, style: t.titleLarge),
          const SizedBox(height: 16),
          for (final p in c.points)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('🌿  '),
                Expanded(child: Text(p, style: t.bodyLarge)),
              ]),
            ),
          const SizedBox(height: 8),
          Card(
            color: scheme.tertiary.withValues(alpha: .2),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Why it matters: ${c.whyItMatters}'),
            ),
          ),
        ];
        button = FilledButton(
            key: const Key('step-done'),
            onPressed: _finish,
            child: const Text('Got it'));
      case StepKind.action:
        final a = d.action;
        body = [
          Text('🍵 ${a.snackTitle}', style: t.titleLarge),
          const SizedBox(height: 8),
          for (final s in a.snack)
            Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $s', style: t.bodyLarge)),
          const SizedBox(height: 20),
          Text('🧘 ${a.stretchTitle}', style: t.titleLarge),
          const SizedBox(height: 8),
          for (final (i, s) in a.stretch.indexed)
            Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${i + 1}. $s', style: t.bodyLarge)),
        ];
        button = FilledButton(
            key: const Key('step-done'),
            onPressed: _finish,
            child: const Text('I did it 💪'));
    }

    return Scaffold(
      appBar: AppBar(title: Text('${d.emoji} ${d.theme}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (widget.preview)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('👀 Sneak peek. This counts on its own day.',
                  style: t.bodySmall),
            ),
          ...body,
          if (button != null) ...[
            const SizedBox(height: 24),
            if (widget.preview)
              OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Back'))
            else ...[
              button,
              const SizedBox(height: 8),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Maybe later')),
            ],
          ],
        ],
      ),
    );
  }
}
