const test = require('node:test');
const assert = require('node:assert');
const { needsCrisisSupport, systemPrompt, toGeminiContents } = require('./friend');

test('crisis check', () => {
  assert.ok(needsCrisisSupport('I want to kill myself'));
  assert.ok(!needsCrisisSupport('these cramps are killing me'));
});

test('system prompt respects vibe and name', () => {
  const p = systemPrompt({ vibe: 'cozyAuntie', nickname: 'Mai', mode: 'cozyCocoon', cycleDay: 2 });
  assert.match(p, /cozy auntie/);
  assert.match(p, /Mai/);
  assert.match(p, /day 2/);
  assert.match(p, /Never assume pregnancy/);
});

test('history is mapped and capped', () => {
  const history = Array.from({ length: 20 }, (_, i) => ({ role: i % 2 ? 'model' : 'user', text: `m${i}` }));
  const c = toGeminiContents(history, 'hi');
  assert.strictEqual(c.length, 13);
  assert.deepStrictEqual(c.at(-1), { role: 'user', parts: [{ text: 'hi' }] });
});
