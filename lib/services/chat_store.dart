import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'friend_service.dart';

/// Saves chat on this phone only, and only when "Burn After Venting" is off.
class ChatStore {
  static const _key = 'cozymoon.chat.v1';
  static const _max = 60;

  Future<List<ChatMessage>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      return [
        for (final m in jsonDecode(raw) as List)
          ChatMessage(fromFriend: m['f'] == true, text: m['t'] as String),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final recent = messages.length > _max
        ? messages.sublist(messages.length - _max)
        : messages;
    await prefs.setString(
        _key,
        jsonEncode([
          for (final m in recent) {'f': m.fromFriend, 't': m.text}
        ]));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
