/// A first, on-device safety check that runs before anything is sent to the
/// AI. If it matches, the app shows the help banner instead of a playful reply.
/// The server runs its own check too; this one just makes sure help appears
/// even when the phone is offline.
class Safety {
  static final List<RegExp> _patterns = [
    r'\bkill(ing)? my ?self\b',
    r'\bsuicid',
    r'\bend (it all|my life)\b',
    r"\b(want|wanna|going) to die\b",
    r"\bdon'?t want to (live|be alive|wake up)\b",
    r'\bno reason to live\b',
    r'\bhurt(ing)? my ?self\b',
    r'\bself[- ]?harm',
    r'\bcut(ting)? my ?self\b',
    r'\boverdos',
    r'\b(he|she|they|partner|boyfriend|husband) (hits|hit|beats|beat|chokes|choked) me\b',
    r'\b(abus(e|ed|ing) me|being abused)\b',
    r'\bnot safe at home\b',
  ].map((p) => RegExp(p, caseSensitive: false)).toList();

  static bool needsCrisisSupport(String text) =>
      _patterns.any((p) => p.hasMatch(text));
}
