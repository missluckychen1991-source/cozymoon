import 'package:flutter/material.dart';

import '../models/tea.dart';
import '../services/tea_service.dart';
import '../widgets/crisis_banner.dart';

class TeaPostScreen extends StatefulWidget {
  const TeaPostScreen({super.key, required this.post, required this.service});
  final TeaPost post;
  final TeaService service;

  @override
  State<TeaPostScreen> createState() => _TeaPostScreenState();
}

class _TeaPostScreenState extends State<TeaPostScreen> {
  final _reply = TextEditingController();
  final Set<String> _hugged = {};
  bool _sending = false;
  String? _blocked;
  bool _crisis = false;

  TeaPost get post => widget.post;

  @override
  void initState() {
    super.initState();
    _loadHugs();
  }

  Future<void> _loadHugs() async {
    final ids = [post.id, for (final r in post.replies) r.id];
    for (final id in ids) {
      if (await widget.service.hasHugged(id)) _hugged.add(id);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _hug({TeaReply? reply}) async {
    final id = reply?.id ?? post.id;
    if (_hugged.contains(id)) return;
    setState(() => _hugged.add(id));
    await widget.service.hug(post, reply: reply);
    if (mounted) setState(() {});
  }

  Future<void> _send() async {
    if (_reply.text.trim().isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _blocked = null;
    });
    final result = await widget.service.reply(post, _reply.text);
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (result.ok) {
        _reply.clear();
      } else {
        _blocked = result.reason;
        _crisis = result.crisis;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('The Tea Table')),
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                  '${post.tag.emoji} ${post.alias} · ${timeAgo(post.createdAt)}',
                  style: t.labelLarge),
              const SizedBox(height: 8),
              Text(post.text, style: t.titleMedium),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: _HugButton(
                  key: const Key('hug-post'),
                  count: post.hugs,
                  hugged: _hugged.contains(post.id),
                  onTap: () => _hug(),
                ),
              ),
              const Divider(height: 24),
              Text(
                  post.replies.isEmpty
                      ? 'No replies yet. Kind words only 💛'
                      : 'Replies',
                  style: t.titleSmall),
              const SizedBox(height: 8),
              for (final r in post.replies)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${r.alias} · ${timeAgo(r.createdAt)}',
                                style: t.labelMedium),
                            const SizedBox(height: 6),
                            Text(r.text),
                            _HugButton(
                                count: r.hugs,
                                hugged: _hugged.contains(r.id),
                                onTap: () => _hug(reply: r)),
                          ]),
                    ),
                  ),
                ),
              if (_crisis) const CrisisBanner(),
            ],
          ),
        ),
        if (_blocked != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_blocked!,
                key: const Key('reply-blocked'),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  key: const Key('reply-input'),
                  controller: _reply,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration:
                      const InputDecoration(hintText: 'Write a kind reply…'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const Key('reply-send'),
                onPressed: _sending ? null : _send,
                icon: const Icon(Icons.send),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _HugButton extends StatelessWidget {
  const _HugButton(
      {super.key,
      required this.count,
      required this.hugged,
      required this.onTap});
  final int count;
  final bool hugged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: hugged ? null : onTap,
        child: Text(hugged ? '💛 Hug sent · $count' : '💛 Send Hug · $count'),
      );
}
