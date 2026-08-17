import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { buildRecordLookup, checkCandidateBatch, knowledgeRoot, readSpeciesRecords } from './plant-knowledge-utils.js';

const flag = process.argv.indexOf('--file');
if (flag < 0 || !process.argv[flag + 1]) {
  console.error('Usage: npm run report:knowledge-candidates -- --file <candidate batch JSON>');
  process.exit(1);
}
const filePath = path.resolve(process.cwd(), process.argv[flag + 1]);
if (!filePath.startsWith(`${knowledgeRoot}${path.sep}`)) {
  console.error('Candidate batch must be inside server/data/plant-knowledge.');
  process.exit(1);
}
const batch = JSON.parse(await readFile(filePath, 'utf8'));
const candidates = Array.isArray(batch.candidates) ? batch.candidates : [];
const results = checkCandidateBatch(candidates, buildRecordLookup(await readSpeciesRecords()));

console.log(`Candidate total: ${candidates.length}`);
count('Declared resolution status', candidates, (candidate) => candidate.resolutionStatus);
count('Checker recommendation', results, (result) => result.status);
countMany('Requested coverage groups', candidates, (candidate) => candidate.requestedCoverageGroups);
count('Expected taxon groups', candidates, (candidate) => candidate.planning?.taxonGroup);
countMany('Expected growth forms', candidates, (candidate) => candidate.planning?.growthForms);
countMany('Planned regions/scenes', candidates, (candidate) => candidate.planning?.regions);
const missingExternal = candidates.filter((candidate) => !Object.values(candidate.providerMappings ?? {}).some((value) => typeof value === 'string' && value.length));
const ambiguousNames = results.filter((result) => result.status === 'needs_review');
const existing = results.filter((result) => result.status === 'existing');
const duplicateInputs = results.filter((result) => result.duplicateOf !== undefined);
const duplicateExternalIds = results.filter((result) => result.externalDuplicateOf !== undefined);
const duplicateCanonicalIds = results.filter((result) => result.canonicalDuplicateOf !== undefined);
const substitutes = candidates.filter((candidate) => candidate.requestedCoverageGroups?.includes('冲突替补'));
console.log(`Missing external ID: ${missingExternal.length}${missingExternal.length ? ` (${missingExternal.map((item) => item.inputName).join(', ')})` : ''}`);
console.log(`Chinese-name ambiguity: ${ambiguousNames.length}${ambiguousNames.length ? ` (${ambiguousNames.map((item) => item.inputName).join(', ')})` : ''}`);
console.log(`Scientific-name/external-ID duplicates with existing knowledge: ${existing.length}`);
console.log(`Duplicate candidate inputs: ${duplicateInputs.length}`);
console.log(`Duplicate external IDs within candidates: ${duplicateExternalIds.length}`);
console.log(`Duplicate canonicalTaxonIds within candidates: ${duplicateCanonicalIds.length}`);
console.log(`Substitute candidates: ${substitutes.length}${substitutes.length ? ` (${substitutes.map((item) => item.acceptedChineseName).join(', ')})` : ''}`);

function count(label, values, pick) { const totals = {}; for (const value of values) { const key = pick(value); if (key) totals[key] = (totals[key] ?? 0) + 1; } console.log(`${label}:`, totals); }
function countMany(label, values, pick) { const totals = {}; for (const value of values) for (const key of pick(value) ?? []) if (key) totals[key] = (totals[key] ?? 0) + 1; console.log(`${label}:`, totals); }
