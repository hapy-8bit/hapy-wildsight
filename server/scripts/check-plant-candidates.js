import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { buildRecordLookup, checkCandidateBatch, knowledgeRoot, readSpeciesRecords } from './plant-knowledge-utils.js';

const fileFlag = process.argv.indexOf('--file');
if (fileFlag < 0 || !process.argv[fileFlag + 1]) {
  console.error('Usage: npm run check:knowledge-candidates -- --file <candidate batch JSON>');
  process.exit(1);
}
const supplied = process.argv[fileFlag + 1];
const filePath = path.resolve(process.cwd(), supplied);
if (!filePath.startsWith(`${knowledgeRoot}${path.sep}`)) {
  console.error('Candidate batch must be inside server/data/plant-knowledge.');
  process.exit(1);
}
const batch = JSON.parse(await readFile(filePath, 'utf8'));
const candidates = Array.isArray(batch.candidates) ? batch.candidates : [];
const lookup = buildRecordLookup(await readSpeciesRecords());
const results = checkCandidateBatch(candidates, lookup).map((result, index) => ({ inputName: candidates[index].inputName, inputScientificName: candidates[index].inputScientificName, ...result, index }));
for (const item of results) console.log(`${item.index + 1}. ${item.inputName || item.inputScientificName || '(unnamed)'}: ${item.status}${item.canonicalTaxonId ? ` → ${item.canonicalTaxonId}` : ''} (${item.reason})${item.duplicateOf === undefined ? '' : `; duplicates candidate ${item.duplicateOf + 1}`}${item.externalDuplicateOf === undefined ? '' : `; reuses external ID from candidate ${item.externalDuplicateOf + 1}`}`);
const totals = results.reduce((sum, item) => ({ ...sum, [item.status]: (sum[item.status] ?? 0) + 1 }), {});
console.log('Candidate result totals:', totals);
