import 'package:flutter/material.dart';

import '../app_state.dart';
import '../services/chat_store.dart';
import '../services/friend_service.dart';
import '../widgets/crisis_banner.dart';

/// Tab indexes the chat can send the user to.
const tabFor = {
  '🪨 Smash some rocks': 2,
  '🏮 Breathe with the lantern': 2,
  "✨ Today's 3 steps": 3,
};

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.starter, this.service, this.store});
  final String? starter;
  final FriendService? service;
  final ChatStore? store;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final FriendService _service = widget.service ?? FriendService();
  late final ChatStore _store = widget.store ?? ChatStore();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _burn = false;
  bool _sending = false;
  bool _crisis = false;

  @override
  void initState() {
    super.initState();
    _store.load().then((saved) {
      if (!mounted) return;
      setState(() => _messages.insertAll(0, saved));
      if (widget.starter != null) _send(widget.starter!);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Turning Burn on opens a fresh, unsaved page. Turning it off wipes that
  /// page and brings back the saved chat.
  Future<void> _setBurn(bool on) async {
    final saved = on ? <ChatMessage>[] : await _store.load();
    if (!mounted) return;
    setState(() {
      _burn = on;
      _messages
        ..clear()
        ..addAll(saved);
    });
    if (on) return; // the banner at the top already explains it
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(16, 0, 16, 90),
      duration: Duration(seconds: 2),
      content: Text('🔥 Poof. Your venting is gone for good.'),
    ));
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending) return;
    final state = AppScope.of(context);
    final history = List<ChatMessage>.of(_messages);
    setState(() {
      _messages.add(ChatMessage(fromFriend: false, text: trimmed));
      _sending = true;
      _input.clear();
    });
    _scrollDown();

    final reply = await _service.reply(
      message: trimmed,
      history: history,
      profile: state.profile,
      cycle: state.cycle,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (reply.crisis) _crisis = true;
      _messages.add(ChatMessage(
        fromFriend: true,
        text: reply.text,
        suggestions: reply.crisis ? const [] : reply.suggestions,
      ));
    });
    if (!_burn) await _store.save(_messages);
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Burned chats only live in this screen's memory, so leaving wipes them.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your friend'),
        actions: [
          Row(children: [
            const Text('🔥 Burn'),
            Switch(key: const Key('burn'), value: _burn, onChanged: _setBurn),
          ]),
        ],
      ),
      body: Column(children: [
        if (_burn)
          Container(
            width: double.infinity,
            color: scheme.tertiary.withValues(alpha: 0.25),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: const Text(
                'Burn After Venting: nothing here is saved, and it all disappears when you leave.'),
          ),
        if (_crisis)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: CrisisBanner(onClose: () => setState(() => _crisis = false)),
          ),
        Expanded(
          child: _messages.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                        "Tell me anything. Love it, hate it, worried about it. I'm listening. 💛",
                        textAlign: TextAlign.center),
                  ),
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_sending ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == _messages.length) {
                      return const _Bubble(fromFriend: true, text: '…');
                    }
                    final m = _messages[i];
                    return Column(
                      crossAxisAlignment: m.fromFriend
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      children: [
                        _Bubble(fromFriend: m.fromFriend, text: m.text),
                        if (m.suggestions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Wrap(spacing: 8, children: [
                              for (final s in m.suggestions)
                                ActionChip(
                                  label: Text(s),
                                  onPressed: () =>
                                      Navigator.of(context).pop(tabFor[s]),
                                ),
                            ]),
                          ),
                      ],
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  key: const Key('chat-input'),
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Say anything…'),
                  onSubmitted: _send,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const Key('send'),
                onPressed: _sending ? null : () => _send(_input.text),
                icon: const Icon(Icons.send),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.fromFriend, required this.text});
  final bool fromFriend;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints:
          BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
      decoration: BoxDecoration(
        color:
            fromFriend ? scheme.surface : scheme.primary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Text(text,
          style: TextStyle(
              color: fromFriend ? scheme.onSurface : Colors.white,
              fontSize: 15)),
    );
  }
}
