const test = require('node:test');
const assert = require('node:assert');
const tea = require('./tea');
const seed = require('./seed_posts.json');

test('alias looks cute and random', () => {
  assert.match(tea.alias(), /^[A-Z][a-z]+ [A-Z][a-z]+ #\d{2}$/);
});

test('quick check blocks personal info and unkindness', () => {
  assert.match(tea.quickCheck('email me at a@b.com'), /email/);
  assert.match(tea.quickCheck('call 0912 345 678'), /phone/);
  assert.match(tea.quickCheck('you are so stupid'), /hurtful/);
  assert.strictEqual(tea.quickCheck('Day 2 cramps are brutal, any tips?'), null);
});

test('moderation fails closed on bad output', () => {
  assert.deepStrictEqual(tea.parseModeration('{"allow":true,"crisis":false}'), { allow: true, crisis: false, reason: null });
  assert.strictEqual(tea.parseModeration('nonsense').allow, false);
  assert.strictEqual(tea.parseModeration('{"allow":true,"crisis":true}').allow, false);
});

test('seed has 8 posts with 2-3 replies', () => {
  assert.strictEqual(seed.length, 8);
  for (const p of seed) {
    assert.ok(p.replies.length >= 2 && p.replies.length <= 3);
    assert.ok(tea.TAGS.includes(p.tag));
  }
});

test('client post shape', () => {
  const p = tea.toClientPost('id1', { alias: 'A', tag: 'solo', text: 't', createdAt: new Date(0), replies: [] });
  assert.strictEqual(p.createdAt, '1970-01-01T00:00:00.000Z');
  assert.strictEqual(p.hugs, 0);
});
