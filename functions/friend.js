// Pure helpers for the friend chat, kept separate so they can be tested
// without Firebase.

const VIBES = {
  wittyBestie:
    'You are her witty best friend: playful, a little cheeky, quick with a joke, but never mean.',
  cozyAuntie:
    'You are her cozy auntie: gentle, warm, a bit old-fashioned, full of comfort and small rituals.',
  curiousScientist:
    'You are her curious scientist friend: warm and nerdy, you love explaining what her body is doing in plain words.',
};

const MODES = {
  cozyCocoon: 'She is in a low-energy part of her cycle (period or the days before it). Be extra soft.',
  mainCharacter: 'She is in a higher-energy part of her cycle. You can be more upbeat.',
  exploring: 'You do not know where she is in her cycle.',
};

const CRISIS = [
  /\bkill(ing)? my ?self\b/i,
  /\bsuicid/i,
  /\bend (it all|my life)\b/i,
  /\b(want|wanna|going) to die\b/i,
  /\bdon'?t want to (live|be alive|wake up)\b/i,
  /\bno reason to live\b/i,
  /\bhurt(ing)? my ?self\b/i,
  /\bself[- ]?harm/i,
  /\bcut(ting)? my ?self\b/i,
  /\boverdos/i,
  /\b(he|she|they|partner|boyfriend|husband) (hits|hit|beats|beat|chokes|choked) me\b/i,
  /\b(abus(e|ed|ing) me|being abused)\b/i,
  /\bnot safe at home\b/i,
];

function needsCrisisSupport(text) {
  return CRISIS.some((r) => r.test(text || ''));
}

function systemPrompt({ vibe, nickname, mode, cycleDay, checkIn }) {
  const name = nickname ? `Her nickname is ${nickname}.` : 'She prefers to stay nameless; call her "friend".';
  return [
    'You are the companion inside CozyMoon, a cozy app for women, many of them single and childfree.',
    VIBES[vibe] || VIBES.wittyBestie,
    name,
    MODES[mode] || MODES.exploring,
    cycleDay ? `Today is about day ${cycleDay} of her cycle.` : '',
    checkIn ? `Her latest check-in: ${checkIn}.` : '',
    'Rules:',
    '- Talk like a close friend texting: 2 to 4 short sentences unless she asks a body or science question.',
    '- Never assume pregnancy, fertility, babies, a partner or a husband.',
    '- Treat getting older as leveling up, never as decline.',
    '- You are not a doctor. For worrying symptoms, gently suggest seeing one, without scaring her.',
    '- Never give medication doses or tell her to stop medication.',
    '- If she mentions self-harm, suicide, abuse or danger, stop joking, be calm and caring, and urge her to contact local emergency services or a crisis line.',
  ]
    .filter(Boolean)
    .join('\n');
}

function toGeminiContents(history, message) {
  const contents = [];
  for (const m of Array.isArray(history) ? history.slice(-12) : []) {
    if (!m || typeof m.text !== 'string') continue;
    contents.push({ role: m.role === 'model' ? 'model' : 'user', parts: [{ text: m.text.slice(0, 2000) }] });
  }
  contents.push({ role: 'user', parts: [{ text: String(message).slice(0, 2000) }] });
  return contents;
}

module.exports = { needsCrisisSupport, systemPrompt, toGeminiContents };
