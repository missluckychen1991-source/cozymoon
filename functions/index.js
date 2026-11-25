// Cloud Function that lets the app talk to Gemini without shipping the API
// key inside the app. Deploy with: firebase deploy --only functions
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { needsCrisisSupport, systemPrompt, toGeminiContents } = require('./friend');

const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');
const MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash';

exports.friendChat = onCall(
  { secrets: [GEMINI_API_KEY], region: 'us-central1', maxInstances: 10 },
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

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`;
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': GEMINI_API_KEY.value() },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: systemPrompt(data) }] },
        contents: toGeminiContents(data.history, message),
        generationConfig: { temperature: 0.9, maxOutputTokens: 400 },
      }),
    });
    if (!res.ok) throw new HttpsError('unavailable', `Gemini returned ${res.status}`);
    const json = await res.json();
    const text = (json.candidates?.[0]?.content?.parts || []).map((p) => p.text || '').join('').trim();
    return { crisis: false, text };
  },
);
