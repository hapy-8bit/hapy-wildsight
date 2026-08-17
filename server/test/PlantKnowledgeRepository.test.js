import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { PlantKnowledgeRepository } from '../src/knowledge/PlantKnowledgeRepository.js';
import { IdentificationEnrichmentService } from '../src/knowledge/IdentificationEnrichmentService.js';

const repository = new PlantKnowledgeRepository();

const reviewedExactMatches = [
  ['绿萝', 'epipremnum-aureum', 'Epipremnum aureum'],
  ['紫薇', 'lagerstroemia-indica', 'Lagerstroemia indica'],
  ['银杏', 'ginkgo-biloba', 'Ginkgo biloba'],
  ['龟背竹', 'monstera-deliciosa', 'Monstera deliciosa'],
  ['月季花', 'rosa-chinensis', 'Rosa chinensis']
];

test('enriches the exact Baidu name 绿萝 without exposing internal source references', async () => {
  const result = await new IdentificationEnrichmentService(repository).enrich({ success: true, provider: 'baidu', primary: { name: '绿萝', confidence: 0.9 }, alternatives: [{ name: '常春藤', confidence: 0.1 }] });
  assert.equal(result.primary.canonicalSpeciesId, 'epipremnum-aureum');
  assert.equal(result.primary.knowledgeMatch, 'exact');
  assert.equal(result.primary.knowledgeReviewStatus, 'reviewed');
  assert.equal(result.primary.knowledge.scientificName, 'Epipremnum aureum');
  assert.equal('internalSourceRefs' in result.primary.knowledge, false);
  assert.equal('internalSourceRefs' in result.primary, false);
  assert.deepEqual(result.alternatives, [{ name: '常春藤', confidence: 0.1 }]);
});

test('enriches every reviewed exact plant mapping without exposing internal source references', async () => {
  const service = new IdentificationEnrichmentService(repository);
  for (const [name, canonicalSpeciesId, scientificName] of reviewedExactMatches) {
    const result = await service.enrich({ success: true, provider: 'baidu', primary: { name, confidence: 0.8 }, alternatives: [] });
    assert.equal(result.primary.canonicalSpeciesId, canonicalSpeciesId, name);
    assert.equal(result.primary.knowledgeMatch, 'exact', name);
    assert.equal(result.primary.knowledgeReviewStatus, 'reviewed', name);
    assert.equal(result.primary.knowledge?.scientificName, scientificName, name);
    assert.equal('internalSourceRefs' in (result.primary.knowledge ?? {}), false, name);
  }
});

test('uses only a manually reviewed alias mapping after an exact-name attempt', async () => {
  const root = await createFixture({ name: '黄金葛', matchType: 'alias', verified: true });
  const found = await new PlantKnowledgeRepository(root).find('baidu', '黄金葛');
  assert.equal(found?.record.id, 'epipremnum-aureum');
  assert.equal(found?.matchType, 'alias');
});

test('keeps a successful provider response unchanged when knowledge is not mapped', async () => {
  const raw = { success: true, provider: 'baidu', primary: { name: '未知植物', confidence: 0.8 }, alternatives: [] };
  assert.deepEqual(await new IdentificationEnrichmentService(repository).enrich(raw), raw);
});

test('safely degrades when a mapped knowledge JSON record is corrupt', async () => {
  const root = await createFixture({ corruptSpecies: true });
  const raw = { success: true, provider: 'baidu', primary: { name: '绿萝', confidence: 0.8 }, alternatives: [] };
  assert.deepEqual(await new IdentificationEnrichmentService(new PlantKnowledgeRepository(root)).enrich(raw), raw);
});

async function createFixture(mapping) {
  const root = await mkdtemp(path.join(os.tmpdir(), 'wildsight-knowledge-'));
  await mkdir(path.join(root, 'species'));
  await writeFile(path.join(root, 'index.json'), JSON.stringify({ species: [{ id: 'epipremnum-aureum', path: 'species/epipremnum-aureum.json', status: 'published' }] }));
  await writeFile(path.join(root, 'provider-name-mapping.json'), JSON.stringify({ mappings: [{ provider: 'baidu', name: mapping.name ?? '绿萝', canonicalTaxonId: 'epipremnum-aureum', matchType: mapping.matchType ?? 'exact', verified: mapping.verified ?? true }] }));
  await writeFile(path.join(root, 'species/epipremnum-aureum.json'), mapping.corruptSpecies ? '{' : JSON.stringify({ id: 'epipremnum-aureum', status: 'published', reviewStatus: 'reviewed', identity: { acceptedChineseName: '绿萝', scientificName: 'Epipremnum aureum', family: '天南星科', genus: '麒麟叶属', aliases: [] }, knowledge: { summary: '', identificationReferences: [], howToConfirm: [], appearance: '', growthHabit: '', keyCharacteristics: [], observationTips: [], confusableSpecies: [], observationReminder: '' }, contentVersion: 1, internalSourceRefs: [{ private: true }] }));
  return root;
}
