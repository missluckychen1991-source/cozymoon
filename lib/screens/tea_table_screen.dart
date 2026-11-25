import 'package:flutter/material.dart';

import '../models/tea.dart';
import '../services/tea_service.dart';
import 'tea_compose_screen.dart';
import 'tea_post_screen.dart';

class TeaTableScreen extends StatefulWidget {
  const TeaTableScreen({super.key, this.service});
  final TeaService? service;

  @override
  State<TeaTableScreen> createState() => _TeaTableScreenState();
}

class _TeaTableScreenState extends State<TeaTableScreen> {
  late final TeaService _service = widget.service ?? TeaService();
  List<TeaPost> _posts = [];
  TeaTag? _filter;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final posts = await _service.feed();
    if (!mounted) return;
    setState(() {
      _posts = posts;
      _loading = false;
    });
  }

  Future<void> _compose() async {
    final posted = await Navigator.of(context).push<TeaPost>(
      MaterialPageRoute(builder: (_) => TeaComposeScreen(service: _service)),
    );
    if (posted != null) {
      await _refresh();
      if (mounted) _open(posted);
    }
  }

  Future<void> _open(TeaPost post) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => TeaPostScreen(post: post, service: _service)),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final shown = _filter == null
        ? _posts
        : _posts.where((p) => p.tag == _filter).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('The Tea Table 🍵')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('tea-ask'),
        onPressed: _compose,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Ask / Confide'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          children: [
            Text(
              'Anonymous and kind. No profiles, no DMs, a new name every time.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                ),
                for (final t in TeaTag.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${t.emoji} ${t.label}'),
                      selected: _filter == t,
                      onSelected: (_) => setState(() => _filter = t),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()))
            else if (shown.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('Nothing here yet. Be the first to pour the tea ☕',
                    textAlign: TextAlign.center),
              )
            else
              for (final p in shown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TeaPostCard(post: p, onTap: () => _open(p)),
                ),
          ],
        ),
      ),
    );
  }
}

class TeaPostCard extends StatelessWidget {
  const TeaPostCard({super.key, required this.post, this.onTap});
  final TeaPost post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(
                    '${post.tag.emoji} ${post.alias} · ${timeAgo(post.createdAt)}',
                    style: t.labelLarge,
                    overflow: TextOverflow.ellipsis),
              ),
              if (post.mine)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text('you', style: t.labelSmall),
                ),
            ]),
            const SizedBox(height: 8),
            Text(post.text,
                style: t.bodyLarge,
                maxLines: 5,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Text('💛 ${post.hugs} hugs   💬 ${post.replies.length} replies',
                style: t.bodySmall),
          ]),
        ),
      ),
    );
  }
}
