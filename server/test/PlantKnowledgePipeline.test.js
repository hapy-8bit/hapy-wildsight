import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, readFile, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { buildIndex, buildRecordLookup, checkCandidate, checkCandidateBatch, stableJson } from '../scripts/plant-knowledge-utils.js';

const greenPothos = record('epipremnum-aureum', 'Epipremnum aureum', '绿萝', { gbif: '2868323' }, ['Pothos aureus'], ['黄金葛']);
const rose = record('rosa-chinensis', 'Rosa chinensis', '月季', { gbif: '3005039' });
const lookup = buildRecordLookup([{ path: 'species/epipremnum-aureum.json', record: greenPothos }, { path: 'species/rosa-chinensis.json', record: rose }]);

test('candidate checker treats identical GBIF IDs and mechanical scientific-name variants as existing', () => {
  assert.deepEqual(checkCandidate({ source: 'gbif:2868323', inputName: '', inputScientificName: '', resolvedCanonicalTaxonId: '' }, lookup).status, 'existing');
  const result = checkCandidate({ source: '', inputName: '', inputScientificName: '  EPIPREMNUM   AUREUM ', resolvedCanonicalTaxonId: '' }, lookup);
  assert.equal(result.status, 'existing');
  assert.equal(result.canonicalTaxonId, 'epipremnum-aureum');
  const batch = checkCandidateBatch([{ providerMappings: { gbif: '2868323' }, source: '', inputScientificName: '', resolvedCanonicalTaxonId: '' }, { providerMappings: { gbif: '2868323' }, source: '', inputScientificName: 'Different scientific name', resolvedCanonicalTaxonId: '' }], lookup);
  assert.equal(batch[1].externalDuplicateOf, 0);
  const forward = checkCandidateBatch([{ inputName: '绿萝', inputScientificName: '', source: '', resolvedCanonicalTaxonId: '' }, { inputName: '真正新候选', inputScientificName: 'Example novum', source: '', resolvedCanonicalTaxonId: '' }], lookup).map((item) => item.status).sort();
  const reversed = checkCandidateBatch([{ inputName: '真正新候选', inputScientificName: 'Example novum', source: '', resolvedCanonicalTaxonId: '' }, { inputName: '绿萝', inputScientificName: '', source: '', resolvedCanonicalTaxonId: '' }], lookup).map((item) => item.status).sort();
  assert.deepEqual(reversed, forward);
});

test('candidate checker recognizes scientific synonyms, preserves name ambiguity, and admits true new records', () => {
  assert.equal(checkCandidate({ inputName: '', inputScientificName: 'Pothos aureus', source: '', resolvedCanonicalTaxonId: '' }, lookup).canonicalTaxonId, 'epipremnum-aureum');
  assert.equal(checkCandidate({ inputName: '绿萝', inputScientificName: '', source: '', resolvedCanonicalTaxonId: '' }, lookup).status, 'needs_review');
  assert.equal(checkCandidate({ inputName: '真正新候选', inputScientificName: 'Example novum', source: '', resolvedCanonicalTaxonId: '' }, lookup).status, 'new');
});

test('generated indexes are stable and a manually damaged index fails check mode', async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), 'wildsight-index-'));
  await mkdir(path.join(root, 'species'));
  await writeFile(path.join(root, 'species', 'z.json'), JSON.stringify({ id: 'zeta', status: 'published', reviewStatus: 'reviewed' }));
  await writeFile(path.join(root, 'species', 'a.json'), JSON.stringify({ id: 'alpha', status: 'published', reviewStatus: 'reviewed' }));
  const script = path.resolve('scripts/build-plant-knowledge-index.js');
  const env = { ...process.env, PLANT_KNOWLEDGE_ROOT: root };
  assert.equal(spawnSync(process.execPath, [script], { env }).status, 0);
  const first = await readFile(path.join(root, 'index.json'), 'utf8');
  assert.equal(spawnSync(process.execPath, [script], { env }).status, 0);
  assert.equal(await readFile(path.join(root, 'index.json'), 'utf8'), first);
  assert.equal(stableJson(buildIndex([{ path: 'species/a.json', record: { id: 'alpha', status: 'published', reviewStatus: 'reviewed' } }, { path: 'species/z.json', record: { id: 'zeta', status: 'published', reviewStatus: 'reviewed' } }])), first);
  await writeFile(path.join(root, 'index.json'), '{"species":[]}\n');
  assert.notEqual(spawnSync(process.execPath, [script, '--check'], { env }).status, 0);
});

test('index date is deterministic across current dates and record order', () => {
  const records = [
    { path: 'species/z.json', record: { id: 'zeta', status: 'published', reviewStatus: 'reviewed' } },
    { path: 'species/a.json', record: { id: 'alpha', status: 'published', reviewStatus: 'reviewed' } }
  ];
  const OriginalDate = globalThis.Date;
  const at = (iso) => class extends OriginalDate {
    constructor(...args) { super(...(args.length === 0 ? [iso] : args)); }
    static now() { return OriginalDate.parse(iso); }
  };
  let before;
  try {
    globalThis.Date = at('2026-08-16T23:59:59+08:00');
    before = stableJson(buildIndex(records));
    globalThis.Date = at('2026-08-17T00:00:01+08:00');
    assert.equal(stableJson(buildIndex([...records].reverse())), before);
  } finally {
    globalThis.Date = OriginalDate;
  }
});

function record(id, scientificName, acceptedChineseName, providerMappings = {}, scientificSynonyms = [], aliases = []) {
  return { id, status: 'published', reviewStatus: 'reviewed', providerMappings, scientificSynonyms, identity: { scientificName, acceptedChineseName, aliases } };
}
