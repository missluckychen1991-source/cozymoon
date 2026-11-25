// Cloud Function that lets the app talk to Gemini without shipping the API
// key inside the app. Deploy with: firebase deploy --only functions
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { needsCrisisSupport, systemPrompt, toGeminiContents } = require('./friend');
const tea = require('./tea');
const { generate } = require('./gemini');
const seedPosts = require('./seed_posts.json');

initializeApp();
const db = getFirestore();
const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');
const opts = { secrets: [GEMINI_API_KEY], region: 'us-central1', maxInstances: 10 };

exports.friendChat = onCall(
  opts,
  async (request) => {
    const data = request.data || {};
    const message = typeof data.message === 'string' ? data.message.trim() : '';
    if (!message) throw new HttpsError('invalid-argument', 'message is required');

    if (needsCrisisSupport(message)) {
      return {
        crisis: true,
        text:
          "I'm really glad you told me. You deserve real support right now, more than I can give as an app. " +
          "Please reach out to someone who can be with you. I'm still here, and we can keep talking.",
      };
    }

    let text;
    try {
      text = await generate(GEMINI_API_KEY.value(), {
        system: systemPrompt(data),
        contents: toGeminiContents(data.history, message),
      });
    } catch (e) {
      throw new HttpsError('unavailable', e.message);
    }
    return { crisis: false, text };
  },
);

// ---------------- The Tea Table ----------------
// Posts live in the "teaPosts" collection. Nothing links a post to a person:
// no user id, device id or IP is stored, and every post and reply gets a new
// random alias. Only these functions write to Firestore (deny all client
// access in firestore.rules).

const posts = () => db.collection('teaPosts');
const CRISIS_TEXT =
  "This sounds really heavy, so I've kept it private. You deserve support from a real person right now. " +
  'Please reach out to a crisis line or your local emergency number.';

async function seedIfEmpty() {
  const snap = await posts().limit(1).get();
  if (!snap.empty) return;
  const batch = db.batch();
  const now = Date.now();
  for (const p of seedPosts) {
    const created = now - p.hoursAgo * 3600e3;
    batch.set(posts().doc(p.id), {
      alias: p.alias,
      tag: p.tag,
      text: p.text,
      hugs: p.hugs,
      createdAt: Timestamp.fromMillis(created),
      replies: p.replies.map((r, i) => ({
        id: `${p.id}-r${i}`,
        alias: r.alias,
        text: r.text,
        hugs: r.hugs,
        createdAt: Timestamp.fromMillis(created + (i + 1) * 30 * 60e3),
      })),
    });
  }
  await batch.commit();
}

/** Rules first, then the AI check. Returns {ok} or {ok:false, reason, crisis}. */
async function moderate(text) {
  if (needsCrisisSupport(text)) return { ok: false, crisis: true, reason: CRISIS_TEXT };
  const quick = tea.quickCheck(text);
  if (quick) return { ok: false, crisis: false, reason: quick };
  let verdict;
  try {
    const raw = await generate(GEMINI_API_KEY.value(), {
      system: tea.MODERATION_PROMPT,
      contents: [{ role: 'user', parts: [{ text }] }],
      temperature: 0,
      maxOutputTokens: 120,
      json: true,
    });
    verdict = tea.parseModeration(raw);
  } catch (_) {
    verdict = tea.parseModeration('');
  }
  if (verdict.crisis) return { ok: false, crisis: true, reason: CRISIS_TEXT };
  if (!verdict.allow) {
    return { ok: false, crisis: false, reason: verdict.reason || 'This might land as hurtful. Could you soften it?' };
  }
  return { ok: true };
}

exports.teaFeed = onCall(opts, async () => {
  await seedIfEmpty();
  const snap = await posts().orderBy('createdAt', 'desc').limit(100).get();
  return { posts: snap.docs.filter((d) => !d.get('hidden')).map((d) => tea.toClientPost(d.id, d.data())) };
});

exports.teaFirstAnswer = onCall(opts, async (request) => {
  const data = request.data || {};
  const text = typeof data.text === 'string' ? data.text.trim().slice(0, 1000) : '';
  if (!text) throw new HttpsError('invalid-argument', 'text is required');
  if (needsCrisisSupport(text)) return { crisis: true, text: CRISIS_TEXT };
  try {
    const answer = await generate(GEMINI_API_KEY.value(), {
      system: tea.firstAnswerPrompt(data),
      contents: [{ role: 'user', parts: [{ text }] }],
    });
    return { crisis: false, text: answer };
  } catch (e) {
    throw new HttpsError('unavailable', e.message);
  }
});

exports.teaPublish = onCall(opts, async (request) => {
  const data = request.data || {};
  const text = typeof data.text === 'string' ? data.text.trim() : '';
  const tag = tea.TAGS.includes(data.tag) ? data.tag : 'venting';
  const verdict = await moderate(text);
  if (!verdict.ok) return verdict;
  const doc = { alias: tea.alias(), tag, text, hugs: 0, replies: [], createdAt: Timestamp.now() };
  const ref = await posts().add(doc);
  return { ok: true, post: tea.toClientPost(ref.id, doc) };
});

exports.teaReply = onCall(opts, async (request) => {
  const data = request.data || {};
  const text = typeof data.text === 'string' ? data.text.trim() : '';
  if (typeof data.postId !== 'string') throw new HttpsError('invalid-argument', 'postId is required');
  const verdict = await moderate(text);
  if (!verdict.ok) return verdict;
  const reply = { id: `${data.postId}-r${Date.now()}`, alias: tea.alias(), text, hugs: 0, createdAt: Timestamp.now() };
  await posts().doc(data.postId).update({ replies: FieldValue.arrayUnion(reply) });
  return { ok: true, reply: tea.toClientPost('x', { replies: [reply] }).replies[0] };
});

exports.teaHug = onCall(opts, async (request) => {
  const { postId, replyId } = request.data || {};
  if (typeof postId !== 'string') throw new HttpsError('invalid-argument', 'postId is required');
  const ref = posts().doc(postId);
  if (!replyId) {
    await ref.update({ hugs: FieldValue.increment(1) });
    return { ok: true };
  }
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return;
    const replies = (snap.get('replies') || []).map((r) => (r.id === replyId ? { ...r, hugs: (r.hugs || 0) + 1 } : r));
    tx.update(ref, { replies });
  });
  return { ok: true };
});
