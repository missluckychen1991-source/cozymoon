const MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash';

/** Calls Gemini and returns the reply text. */
async function generate(apiKey, { system, contents, temperature = 0.9, maxOutputTokens = 400, json = false }) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`;
  const generationConfig = { temperature, maxOutputTokens };
  if (json) generationConfig.responseMimeType = 'application/json';
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
    body: JSON.stringify({
      systemInstruction: { parts: [{ text: system }] },
      contents,
      generationConfig,
    }),
  });
  if (!res.ok) throw new Error(`Gemini returned ${res.status}`);
  const body = await res.json();
  return (body.candidates?.[0]?.content?.parts || []).map((p) => p.text || '').join('').trim();
}

module.exports = { generate };
