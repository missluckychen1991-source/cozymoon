/// On-device checks before anything goes to the Tea Table. The server runs
/// a stricter AI check; these catch the obvious things even offline.
class Kindness {
  static final _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');
  static final _phone = RegExp(r'(\+?\d[\d\s().-]{7,}\d)');
  static final _handle = RegExp(r'(^|\s)@\w{3,}');
  static final _url = RegExp(r'https?://|www\.', caseSensitive: false);

  static final _unkind = [
    r'\b(stupid|idiot|dumb|pathetic|loser|ugly|fat|disgusting|worthless)\b.*\b(you|u|ur|your)\b',
    r'\b(you|u|ur|you.re|youre)\b.*\b(stupid|idiot|dumb|pathetic|loser|ugly|fat|disgusting|worthless|crazy)\b',
    r'\bshut up\b',
    r'\bkill yourself\b|\bkys\b',
    r'\bno one (cares|likes you)\b',
    r'\bstop (taking )?(your )?(meds|medication|pills)\b',
  ].map((p) => RegExp(p, caseSensitive: false)).toList();

  /// Personal details that could identify someone.
  static String? personalInfoWarning(String text) {
    if (_email.hasMatch(text)) {
      return 'This looks like an email address. Remove it to stay anonymous.';
    }
    if (_phone.hasMatch(text)) {
      return 'This looks like a phone number. Remove it to stay anonymous.';
    }
    if (_handle.hasMatch(text)) {
      return 'This looks like a social media handle. Remove it to stay anonymous.';
    }
    if (_url.hasMatch(text)) return 'Links are not allowed at the Tea Table.';
    return null;
  }

  static bool isUnkind(String text) => _unkind.any((p) => p.hasMatch(text));

  /// Null when the text can be published, otherwise a gentle reason.
  static String? check(String text) {
    final t = text.trim();
    if (t.length < 3) return 'Write a little more first.';
    if (t.length > 1000) return 'Please keep it under 1000 characters.';
    final pii = personalInfoWarning(t);
    if (pii != null) return pii;
    if (isUnkind(t)) {
      return 'This might land as hurtful. The Tea Table is a kind place, could you soften it?';
    }
    return null;
  }
}
