import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/tea.dart';
import '../services/kindness.dart';
import '../services/tea_service.dart';
import '../widgets/crisis_banner.dart';

/// Write, see a private answer just for you, then choose: keep it private or
/// share it anonymously.
class TeaComposeScreen extends StatefulWidget {
  const TeaComposeScreen({super.key, required this.service});
  final TeaService service;

  @override
  State<TeaComposeScreen> createState() => _TeaComposeScreenState();
}

class _TeaComposeScreenState extends State<TeaComposeScreen> {
  final _text = TextEditingController();
  TeaTag _tag = TeaTag.venting;
  String? _warning;
  bool _busy = false;
  PrivateAnswer? _answer;
  String? _blocked;

  @override
  void initState() {
    super.initState();
    _text.addListener(() {
      final w = Kindness.personalInfoWarning(_text.text);
      if (w != _warning) setState(() => _warning = w);
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _seePrivateAnswer() async {
    if (_text.text.trim().length < 3) return;
    setState(() => _busy = true);
    final answer = await widget.service
        .privateAnswer(_text.text.trim(), _tag, AppScope.of(context).profile);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _answer = answer;
    });
  }

  Future<void> _share() async {
    setState(() {
      _busy = true;
      _blocked = null;
    });
    final result = await widget.service.publish(_text.text, _tag);
    if (!mounted) return;
    if (result.ok) {
      Navigator.of(context).pop(result.post);
    } else {
      setState(() {
        _busy = false;
        _blocked = result.reason;
        if (result.crisis) {
          _answer = PrivateAnswer(
              friendNote: _answer?.friendNote ?? '', crisis: true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final answer = _answer;
    return Scaffold(
      appBar: AppBar(
          title: Text(answer == null ? 'Ask or confide' : 'Just for you 🔒')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: answer == null ? _writing(t) : _privateView(t, answer),
      ),
    );
  }

  List<Widget> _writing(TextTheme t) => [
        Text(
            "Nobody will know it's you. You'll get a private answer first, and then you decide if it goes public.",
            style: t.bodyMedium),
        const SizedBox(height: 16),
        TextField(
          key: const Key('tea-text'),
          controller: _text,
          minLines: 5,
          maxLines: 10,
          maxLength: 1000,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: "What's on your mind?"),
        ),
        if (_warning != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('⚠️ $_warning',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        Text('Pick a topic', style: t.titleSmall),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final tag in TeaTag.values)
            ChoiceChip(
              label: Text('${tag.emoji} ${tag.label}'),
              selected: _tag == tag,
              onSelected: (_) => setState(() => _tag = tag),
            ),
        ]),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('tea-continue'),
          onPressed: _busy ? null : _seePrivateAnswer,
          child: _busy
              ? const Text('Your friend is reading…')
              : const Text('Continue'),
        ),
      ];

  List<Widget> _privateView(TextTheme t, PrivateAnswer answer) => [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('YOU WROTE', style: t.labelSmall),
              const SizedBox(height: 6),
              Text(_text.text.trim(), style: t.bodyLarge),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Text('🔒 Only you can see this. The community hasn\'t seen your post.',
            style: t.bodySmall),
        const SizedBox(height: 12),
        if (answer.crisis) ...[
          const CrisisBanner(),
          const SizedBox(height: 12),
        ],
        if (answer.friendNote.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🐱 Your friend\'s note', style: t.titleSmall),
                    const SizedBox(height: 8),
                    Text(answer.friendNote, key: const Key('tea-friend-note')),
                  ]),
            ),
          ),
        if (answer.echoes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💬 From women who\'ve been there',
                        style: t.titleSmall),
                    const SizedBox(height: 8),
                    for (final e in answer.echoes)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('• "$e"')),
                  ]),
            ),
          ),
        ],
        if (_blocked != null) ...[
          const SizedBox(height: 12),
          Text(_blocked!,
              key: const Key('tea-blocked'),
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('tea-keep-private'),
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('That helped! Keep it private'),
        ),
        if (!answer.crisis) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('tea-share'),
            onPressed: _busy ? null : _share,
            child: Text(
                _busy ? 'Checking it…' : 'Share anonymously to the Tea Table'),
          ),
          TextButton(
            onPressed: _busy ? null : () => setState(() => _answer = null),
            child: const Text('Edit my post'),
          ),
        ],
      ];
}
