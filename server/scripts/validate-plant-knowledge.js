import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { buildIndex, buildRecordLookup, checkCandidate, checkCandidateBatch, knowledgeRoot, normalizeLooseName, normalizeScientificName, readKnowledgeJson, readSpeciesRecords, stableJson } from './plant-knowledge-utils.js';

const knowledgeArrays = ['identificationReferences', 'howToConfirm', 'keyCharacteristics', 'observationTips', 'confusableSpecies'];
const identityFields = ['acceptedChineseName', 'scientificName', 'family', 'genus', 'aliases'];
const candidateFields = ['inputName', 'inputScientificName', 'acceptedChineseName', 'acceptedScientificName', 'family', 'genus', 'source', 'providerMappings', 'requestedCoverageGroups', 'resolutionStatus', 'resolvedCanonicalTaxonId', 'notes'];
const candidateStatuses = new Set(['pending', 'existing', 'new', 'needs_review', 'rejected']);
const errors = []; const warnings = [];
const index = await readJson('index.json');
const mappingFile = await readJson('provider-name-mapping.json');
const vocabulary = await readJson('catalog-vocabulary.json');
const species = await readSpeciesRecords();
const records = new Map(); const chineseNames = new Map(); const acceptedScientificNames = new Map(); const scientificSynonyms = new Map(); const providerIds = new Map();

const generatedIndex = stableJson(buildIndex(species));
const currentIndex = await readFile(path.join(knowledgeRoot, 'index.json'), 'utf8').catch(() => '');
if (currentIndex !== generatedIndex) error('index.json is not the generated index; run npm run build:knowledge-index');

for (const { path: file, record } of species) {
  if (!record?.id || typeof record.id !== 'string') { error(`${file}: id is required`); continue; }
  if (records.has(record.id)) error(`${file}: duplicate canonical taxon id ${record.id}`);
  records.set(record.id, record);
  if (record.status === 'published' && record.reviewStatus !== 'reviewed') error(`${file}: published records must be reviewed`);
  validateRecord(file, record, vocabulary);
  const scientificName = normalizeScientificName(record.identity?.scientificName);
  if (scientificName && acceptedScientificNames.has(scientificName)) error(`${file}: duplicate normalized accepted scientificName ${scientificName}`);
  if (scientificName) acceptedScientificNames.set(scientificName, record.id);
  const chineseName = normalizeLooseName(record.identity?.acceptedChineseName);
  if (chineseName) chineseNames.set(chineseName, record.id);
  for (const [provider, externalId] of Object.entries(record.providerMappings ?? {})) {
    if (typeof externalId !== 'string' || !externalId.trim()) continue;
    const key = `${provider}\u0000${externalId.trim()}`; const previous = providerIds.get(key);
    if (previous && previous !== record.id) error(`${file}: providerMappings ${provider}/${externalId} belongs to both ${previous} and ${record.id}`);
    providerIds.set(key, record.id);
  }
}
for (const { path: file, record } of species) {
  for (const synonym of record.scientificSynonyms ?? []) {
    const normalized = normalizeScientificName(synonym); if (!normalized) continue;
    const acceptedOwner = acceptedScientificNames.get(normalized);
    if (acceptedOwner && acceptedOwner !== record.id) warning(`${file}: scientific synonym ${synonym} conflicts with accepted scientificName of ${acceptedOwner}`);
    const previous = scientificSynonyms.get(normalized);
    if (previous && previous !== record.id) error(`${file}: scientific synonym ${synonym} belongs to both ${previous} and ${record.id}`);
    scientificSynonyms.set(normalized, record.id);
  }
  for (const alias of record.identity?.aliases ?? []) {
    const owner = chineseNames.get(normalizeLooseName(alias));
    if (owner && owner !== record.id) warning(`${file}: alias ${alias} conflicts with accepted Chinese name of ${owner}`);
  }
}

const indexedIds = new Set();
for (const entry of asArray(index.species, 'index.json species')) {
  if (!entry?.id || !entry?.path || !entry?.status || !entry?.reviewStatus) { error('index.json: every generated entry requires id, path, status and reviewStatus'); continue; }
  if (indexedIds.has(entry.id)) error(`index.json: duplicate species id ${entry.id}`); indexedIds.add(entry.id);
  const record = records.get(entry.id);
  if (!record) error(`index.json: ${entry.id} does not exist in species directory`);
  else if (record.status !== entry.status || record.reviewStatus !== entry.reviewStatus) error(`index.json: ${entry.id} does not match species source`);
}

const mappingKeys = new Map();
for (const mapping of asArray(mappingFile.mappings, 'provider-name-mapping.json mappings')) {
  const key = `${mapping?.provider ?? ''}\u0000${mapping?.name ?? ''}`;
  if (!mapping?.provider || !mapping?.name || !mapping?.canonicalTaxonId) { error('provider-name-mapping.json: every mapping requires provider, name and canonicalTaxonId'); continue; }
  const previous = mappingKeys.get(key);
  if (previous) error(`provider-name-mapping.json: ${mapping.provider}/${mapping.name}${previous === mapping.canonicalTaxonId ? ' is duplicated' : ' maps to multiple species'}`);
  mappingKeys.set(key, mapping.canonicalTaxonId);
  const target = records.get(mapping.canonicalTaxonId);
  if (!target || target.status !== 'published') error(`provider-name-mapping.json: mapping ${mapping.provider}/${mapping.name} has a missing or unpublished canonicalTaxonId`);
  if (mapping.verified !== true) error(`provider-name-mapping.json: mapping ${mapping.provider}/${mapping.name} must be explicitly verified`);
}

await validateCandidateBatches(species); await rejectLevelCopies();
if (warnings.length) { console.warn(`Plant knowledge review warnings (${warnings.length}):`); warnings.forEach((message) => console.warn(`- ${message}`)); }
if (errors.length) { console.error(`Plant knowledge validation failed (${errors.length} issues):`); errors.forEach((message) => console.error(`- ${message}`)); process.exitCode = 1; }
else console.log(`Plant knowledge validation passed: ${records.size} published species, ${mappingKeys.size} verified mappings, ${warnings.length} review warnings.`);

function validateRecord(file, record, terms) {
  if (!record?.identity || typeof record.identity !== 'object') error(`${file}: identity is required`);
  else for (const field of identityFields) { const value = record.identity[field]; if ((field === 'aliases' && !Array.isArray(value)) || (field !== 'aliases' && (typeof value !== 'string' || !value.length))) error(`${file}: identity.${field} is required`); }
  if (record.scientificSynonyms !== undefined && !Array.isArray(record.scientificSynonyms)) error(`${file}: scientificSynonyms must be an array when present`);
  if (record.providerMappings !== undefined && (typeof record.providerMappings !== 'object' || Array.isArray(record.providerMappings))) error(`${file}: providerMappings must be an object when present`);
  if (!record?.knowledge || typeof record.knowledge !== 'object') error(`${file}: knowledge is required`);
  else { for (const field of knowledgeArrays) if (!Array.isArray(record.knowledge[field])) error(`${file}: knowledge.${field} must be an array`); if (Object.hasOwn(record.knowledge, 'internalSourceRefs') || Object.hasOwn(record.knowledge, 'catalogMetadata') || Object.hasOwn(record.knowledge, 'providerMappings')) error(`${file}: internal-only fields must not be inside outward knowledge`); }
  if (!Array.isArray(record?.internalSourceRefs) || !record.internalSourceRefs.length) error(`${file}: internalSourceRefs must not be empty`);
  else record.internalSourceRefs.forEach((source, index) => ['title', 'url', 'accessedAt'].forEach((field) => { if (typeof source?.[field] !== 'string' || !source[field].length) error(`${file}: internalSourceRefs[${index}].${field} is required`); }));
  validateCatalogMetadata(file, record.catalogMetadata, terms);
}
function validateCatalogMetadata(file, metadata, terms) {
  if (!metadata || typeof metadata !== 'object') { error(`${file}: catalogMetadata is required`); return; }
  for (const field of ['taxonGroup', 'coveragePriority']) { const value = metadata[field]; if (Array.isArray(value) || typeof value !== 'string' || !Object.hasOwn(terms?.[field] ?? {}, value)) error(`${file}: catalogMetadata.${field} must be one known single-select code`); }
  for (const field of ['growthForms', 'sceneTags', 'occurrenceTypes', 'useTags']) { const values = metadata[field]; if (!Array.isArray(values)) { error(`${file}: catalogMetadata.${field} must be an array`); continue; } const used = new Set(); for (const value of values) { if (typeof value !== 'string' || !Object.hasOwn(terms?.[field] ?? {}, value)) error(`${file}: catalogMetadata.${field} has unknown tag ${String(value)}`); if (used.has(value)) error(`${file}: catalogMetadata.${field} has duplicate tag ${String(value)}`); used.add(value); } }
}
async function validateCandidateBatches(speciesRecords) {
  const importDirectory = path.join(knowledgeRoot, 'imports'); const files = (await readdir(importDirectory).catch(() => [])).filter((file) => file.endsWith('.json')).sort(); const lookup = buildRecordLookup(speciesRecords);
  for (const file of files) { const relative = `imports/${file}`; const batch = await readJson(relative);
    if (!Object.hasOwn(batch, 'candidates')) {
      if (Array.isArray(batch.species) && typeof batch.purpose === 'string') continue;
      error(`${relative}: import JSON must define candidates or a read-only species baseline`); continue;
    }
    const candidates = asArray(batch.candidates, `${relative} candidates`); const results = checkCandidateBatch(candidates, lookup);
    for (const [index, candidate] of candidates.entries()) { const label = `${relative}: candidates[${index}]`; for (const field of candidateFields) if (!Object.hasOwn(candidate ?? {}, field)) error(`${label}: ${field} is required by candidate schema`); if (!Array.isArray(candidate?.requestedCoverageGroups)) error(`${label}: requestedCoverageGroups must be an array`); if (!candidate?.providerMappings || typeof candidate.providerMappings !== 'object' || Array.isArray(candidate.providerMappings)) error(`${label}: providerMappings must be an object`); if (!candidateStatuses.has(candidate?.resolutionStatus)) error(`${label}: invalid resolutionStatus`); if (results[index].duplicateOf !== undefined) error(`${label}: duplicate candidate input in batch`); if (results[index].externalDuplicateOf !== undefined) error(`${label}: external provider ID is already used by candidates[${results[index].externalDuplicateOf}]`); if (results[index].canonicalDuplicateOf !== undefined) error(`${label}: canonicalTaxonId is already used by candidates[${results[index].canonicalDuplicateOf}]`); const match = checkCandidate(candidate ?? {}, lookup); if (candidate?.resolutionStatus === 'existing' && (!candidate.resolvedCanonicalTaxonId || !lookup.ids.has(candidate.resolvedCanonicalTaxonId))) error(`${label}: existing candidate must point to an existing canonicalTaxonId`); if (candidate?.resolutionStatus === 'new' && match.status === 'existing') error(`${label}: new candidate already matches ${match.canonicalTaxonId}`); }
  }
}
async function rejectLevelCopies() { const entries = await readdir(knowledgeRoot, { withFileTypes: true }); for (const entry of entries) if (/^(l0|l1|l2)(-|_|$)/i.test(entry.name)) error(`${entry.name}: separate L0/L1/L2 species copies are forbidden`); }
async function readJson(relativePath) { try { return await readKnowledgeJson(relativePath); } catch (cause) { error(`${relativePath}: cannot read valid JSON (${cause instanceof SyntaxError ? 'invalid JSON' : 'file missing or unreadable'})`); return {}; } }
function asArray(value, label) { if (!Array.isArray(value)) { error(`${label} must be an array`); return []; } return value; }
function error(message) { errors.push(message); } function warning(message) { warnings.push(message); }
