// Pure helpers for the Tea Table, testable without Firebase.

const TAGS = ['period', 'aging', 'solo', 'venting'];
const FIRST = ['Cozy', 'Quiet', 'Sleepy', 'Warm', 'Minty', 'Gentle', 'Soft', 'Sunny',
  'Velvet', 'Misty', 'Honey', 'Little', 'Brave', 'Calm', 'Rosy', 'Lazy'];
const SECOND = ['Matcha', 'Fern', 'Plum', 'Ginger', 'Owl', 'Biscuit', 'Moth', 'Cloud',
  'Peach', 'Sparrow', 'Mochi', 'Lantern', 'Willow', 'Otter', 'Chai', 'Clover'];

function alias(rand = Math.random) {
  const pick = (a) => a[Math.floor(rand() * a.length)];
  return `${pick(FIRST)} ${pick(SECOND)} #${Math.floor(rand() * 90) + 10}`;
}

const PII = [
  [/[\w.+-]+@[\w-]+\.[\w.]+/, 'This looks like an email address. Remove it to stay anonymous.'],
  [/(\+?\d[\d\s().-]{7,}\d)/, 'This looks like a phone number. Remove it to stay anonymous.'],
  [/(^|\s)@\w{3,}/, 'This looks like a social media handle. Remove it to stay anonymous.'],
  [/https?:\/\/|www\./i, 'Links are not allowed at the Tea Table.'],
];

const UNKIND = [
  /\b(stupid|idiot|dumb|pathetic|loser|ugly|fat|disgusting|worthless)\b.*\b(you|u|ur|your)\b/i,
  /\b(you|u|ur|you.re|youre)\b.*\b(stupid|idiot|dumb|pathetic|loser|ugly|fat|disgusting|worthless|crazy)\b/i,
  /\bshut up\b/i,
  /\bkill yourself\b|\bkys\b/i,
  /\bno one (cares|likes you)\b/i,
  /\bstop (taking )?(your )?(meds|medication|pills)\b/i,
];

/** Quick rule check. Returns null when fine, or a gentle reason. */
function quickCheck(text) {
  const t = String(text || '').trim();
  if (t.length < 3) return 'Write a little more first.';
  if (t.length > 1000) return 'Please keep it under 1000 characters.';
  for (const [re, msg] of PII) if (re.test(t)) return msg;
  if (UNKIND.some((re) => re.test(t))) {
    return 'This might land as hurtful. The Tea Table is a kind place, could you soften it?';
  }
  return null;
}

const MODERATION_PROMPT = [
  'You review posts for an anonymous, kind support board for women about periods, aging and solo life.',
  'Reply with JSON only: {"allow": true|false, "crisis": true|false, "reason": "<one gentle sentence if not allowed>"}.',
  'Block: harassment, insults, shaming of bodies or life choices, victim-blaming, hate, sexual content,',
  'spam or promotion, personal details that identify someone, and medical orders such as telling someone',
  'to stop medication. Honest venting, swearing about a situation, and sad feelings are allowed.',
  'Set crisis true if the writer seems at risk of suicide, self-harm, or abuse; then allow is false.',
].join(' ');

function parseModeration(raw) {
  try {
    const m = JSON.parse(String(raw).replace(/^```(json)?|```$/g, '').trim());
    return {
      allow: m.allow === true && m.crisis !== true,
      crisis: m.crisis === true,
      reason: typeof m.reason === 'string' && m.reason ? m.reason : null,
    };
  } catch (_) {
    // If the AI answer is unreadable, fail closed.
    return { allow: false, crisis: false, reason: 'I could not check this just now. Please try again.' };
  }
}

function firstAnswerPrompt({ vibe, nickname, tag }) {
  const vibes = {
    wittyBestie: 'a witty, warm best friend',
    cozyAuntie: 'a gentle, cozy auntie',
    curiousScientist: 'a warm, curious scientist friend',
  };
  return [
    `You are ${vibes[vibe] || vibes.wittyBestie} inside CozyMoon, an app for women, many single and childfree.`,
    nickname ? `Her nickname is ${nickname}.` : '',
    `She wrote an anonymous post tagged "${TAGS.includes(tag) ? tag : 'venting'}" and only she will see your answer.`,
    'Give her a private first answer: validate her feelings, then share accurate, calm body or life context.',
    'Keep it to 3 to 5 short sentences. Never assume pregnancy, babies or a partner.',
    'You are not a doctor: for worrying symptoms, gently suggest seeing one. Never give medication doses.',
    'If she seems at risk of self-harm, suicide or abuse, be calm and caring and urge her to contact a crisis line.',
  ].filter(Boolean).join('\n');
}

/** Firestore doc -> what the app expects. */
function toClientPost(id, d) {
  const iso = (v) => (v && typeof v.toDate === 'function' ? v.toDate() : new Date(v || Date.now())).toISOString();
  return {
    id,
    alias: d.alias,
    tag: d.tag,
    text: d.text,
    createdAt: iso(d.createdAt),
    hugs: d.hugs || 0,
    replies: (d.replies || []).map((r) => ({ id: r.id, alias: r.alias, text: r.text, createdAt: iso(r.createdAt), hugs: r.hugs || 0 })),
  };
}

module.exports = { TAGS, alias, quickCheck, MODERATION_PROMPT, parseModeration, firstAnswerPrompt, toClientPost };
