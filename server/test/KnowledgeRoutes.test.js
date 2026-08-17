import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { createApp } from '../src/app.js';

const config = {
  maxUploadBytes: 8 * 1024 * 1024, maxEncodedBytes: 4 * 1024 * 1024,
  baiduApiKey: 'test', baiduSecretKey: 'test', tokenRefreshSkewMs: 1,
  providerTimeoutMs: 1, dailyIdentifyLimit: 20,
  plantKnowledgePath: path.resolve(process.cwd(), 'data/plant-knowledge'),
  usageStorePath: '/tmp/wildsight-knowledge-route-usage.json'
};

async function request(path, requestConfig = config, dependencies = {}) {
  const app = createApp(requestConfig, dependencies);
  const server = await new Promise((resolve) => { const value = app.listen(0, () => resolve(value)); });
  try { return await fetch(`http://127.0.0.1:${server.address().port}${path}`); } finally { await new Promise((resolve) => server.close(resolve)); }
}

test('serves only reviewed public knowledge by canonicalTaxonId', async () => {
  const response = await request('/knowledge/species/epipremnum-aureum');
  const body = await response.json();
  assert.equal(response.status, 200);
  assert.equal(body.canonicalTaxonId, 'epipremnum-aureum');
  assert.equal(body.contentVersion, 1);
  assert.equal(body.knowledgeReviewStatus, 'reviewed');
  for (const key of ['internalSourceRefs', 'sourceFacts', 'catalogMetadata', 'providerMappings', 'path']) assert.equal(key in body, false, key);
});

test('rejects invalid and unknown public knowledge identifiers without calling identification', async () => {
  assert.equal((await request('/knowledge/species/not_a_safe_id')).status, 400);
  assert.equal((await request('/knowledge/species/not-a-real-species')).status, 404);
});

test('does not serve unpublished or needs_review index entries', async () => {
  const root = await createFixture({ status: 'draft', reviewStatus: 'needs_review' });
  const fixtureConfig = { ...config, plantKnowledgePath: root };
  assert.equal((await request('/knowledge/species/epipremnum-aureum', fixtureConfig)).status, 404);
});

test('safely returns 404 for corrupt knowledge JSON without leaking file paths', async () => {
  const root = await createFixture({ corruptRecord: true });
  const fixtureConfig = { ...config, plantKnowledgePath: root };
  const response = await request('/knowledge/species/epipremnum-aureum', fixtureConfig);
  const body = await response.json();
  assert.equal(response.status, 404);
  assert.equal(body.error.code, 'KNOWLEDGE_NOT_FOUND');
  assert.equal(JSON.stringify(body).includes(root), false);
  assert.equal(JSON.stringify(body).includes('species/epipremnum-aureum.json'), false);
});

test('safely returns 404 when an otherwise readable record is structurally incomplete', async () => {
  const root = await createFixture({ incompleteRecord: true });
  const response = await request('/knowledge/species/epipremnum-aureum', { ...config, plantKnowledgePath: root });
  assert.equal(response.status, 404);
  assert.equal((await response.json()).error.code, 'KNOWLEDGE_NOT_FOUND');
});

test('public knowledge route never invokes the provider or daily usage store', async () => {
  const calls = { provider: 0, reserve: 0, release: 0 };
  const provider = { validateUpload: () => { calls.provider += 1; }, identify: () => { calls.provider += 1; } };
  const usageStore = { reserve: () => { calls.reserve += 1; }, release: () => { calls.release += 1; } };
  assert.equal((await request('/knowledge/species/epipremnum-aureum', config, { provider, usageStore })).status, 200);
  assert.deepEqual(calls, { provider: 0, reserve: 0, release: 0 });
});

async function createFixture(options = {}) {
  const root = await mkdtemp(path.join(os.tmpdir(), 'wildsight-knowledge-route-'));
  await mkdir(path.join(root, 'species'));
  const status = options.status ?? 'published';
  const reviewStatus = options.reviewStatus ?? 'reviewed';
  await writeFile(path.join(root, 'index.json'), JSON.stringify({ species: [{ id: 'epipremnum-aureum', path: 'species/epipremnum-aureum.json', status, reviewStatus }] }));
  await writeFile(path.join(root, 'species', 'epipremnum-aureum.json'), options.corruptRecord ? '{' : JSON.stringify(options.incompleteRecord ? {
    id: 'epipremnum-aureum', status, reviewStatus, contentVersion: 1
  } : {
    id: 'epipremnum-aureum', status, reviewStatus, contentVersion: 1,
    identity: { acceptedChineseName: '绿萝', scientificName: 'Epipremnum aureum', family: '天南星科', genus: '麒麟叶属', aliases: [] },
    knowledge: { summary: '常见藤本植物。', identificationReferences: [], howToConfirm: [], appearance: '', growthHabit: '', keyCharacteristics: [], observationTips: [], confusableSpecies: [], observationReminder: '' },
    internalSourceRefs: [{ private: true }], sourceFacts: [{ private: true }], catalogMetadata: { private: true }, providerMappings: { baidu: '绿萝' }
  }));
  return root;
}
