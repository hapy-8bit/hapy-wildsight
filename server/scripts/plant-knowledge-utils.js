import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const knowledgeRoot = process.env.PLANT_KNOWLEDGE_ROOT
  ? path.resolve(process.env.PLANT_KNOWLEDGE_ROOT)
  : path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../data/plant-knowledge');
export const speciesDirectory = path.join(knowledgeRoot, 'species');

// The knowledge corpus was reviewed and versioned on this date. It is only a
// fallback for records that do not carry an explicit stable source/review
// date; it must never be replaced with the process's current date.
export const KNOWLEDGE_INDEX_DATE_FALLBACK = '2026-08-16';

export function normalizeScientificName(value) {
  return typeof value === 'string' ? value.trim().replace(/\s+/g, ' ').toLowerCase() : '';
}

export function normalizeLooseName(value) {
  return typeof value === 'string' ? value.trim().replace(/\s+/g, ' ') : '';
}

export async function readKnowledgeJson(relativePath) {
  const file = path.resolve(knowledgeRoot, relativePath);
  if (!file.startsWith(`${knowledgeRoot}${path.sep}`)) throw new Error(`invalid knowledge path: ${relativePath}`);
  return JSON.parse(await readFile(file, 'utf8'));
}

export async function readSpeciesRecords() {
  const files = (await readdir(speciesDirectory)).filter((file) => file.endsWith('.json')).sort();
  return Promise.all(files.map(async (file) => ({
    path: `species/${file}`,
    record: JSON.parse(await readFile(path.join(speciesDirectory, file), 'utf8'))
  })));
}

function stableDate(value) {
  if (typeof value !== 'string') return '';
  const date = value.trim().match(/^(\d{4})-(\d{2})-(\d{2})(?:$|T)/);
  if (!date) return '';
  const year = Number(date[1]);
  const month = Number(date[2]);
  const day = Number(date[3]);
  const daysInMonth = [31, (year % 4 === 0 && (year % 100 !== 0 || year % 400 === 0)) ? 29 : 28,
    31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  return month >= 1 && month <= 12 && day >= 1 && day <= daysInMonth[month - 1] ? date[0].slice(0, 10) : '';
}

function recordDates(record) {
  const dates = [
    record.updatedAt,
    record.reviewedAt,
    record.reviewDate,
    record.versionDate,
    record.catalogMetadata?.updatedAt,
    record.catalogMetadata?.reviewedAt,
    record.knowledge?.updatedAt,
    ...(record.internalSourceRefs ?? []).flatMap((source) => [source.accessedAt, source.reviewedAt])
  ];
  return dates.map(stableDate).filter(Boolean);
}

export function buildIndex(records) {
  const updatedAt = records
    .flatMap(({ record }) => recordDates(record))
    .sort()
    .at(-1) ?? KNOWLEDGE_INDEX_DATE_FALLBACK;
  return {
    schemaVersion: 1,
    knowledgeBaseVersion: '1.0.0',
    updatedAt: updatedAt || KNOWLEDGE_INDEX_DATE_FALLBACK,
    species: [...records]
      .sort((left, right) => left.record.id.localeCompare(right.record.id)
        || left.path.localeCompare(right.path)
        || String(left.record.status ?? '').localeCompare(String(right.record.status ?? ''))
        || String(left.record.reviewStatus ?? '').localeCompare(String(right.record.reviewStatus ?? '')))
      .map(({ path: filePath, record }) => ({ id: record.id, path: filePath, status: record.status, reviewStatus: record.reviewStatus }))
  };
}

export function stableJson(value) {
  return `${JSON.stringify(value, null, 2)}\n`;
}

export function parseExplicitExternalId(source) {
  if (typeof source !== 'string') return undefined;
  const match = source.trim().match(/^(gbif|powo|col):([^\s:]+)$/i);
  return match ? { provider: match[1].toLowerCase(), id: match[2] } : undefined;
}

export function buildRecordLookup(records) {
  const externalIds = new Map();
  const ids = new Map();
  const scientificNames = new Map();
  const scientificSynonyms = new Map();
  const chineseNames = new Map();
  const aliases = new Map();
  for (const { record } of records) {
    ids.set(record.id, record);
    const scientificName = normalizeScientificName(record.identity?.scientificName);
    if (scientificName) scientificNames.set(scientificName, record);
    for (const synonym of record.scientificSynonyms ?? []) {
      const normalized = normalizeScientificName(synonym);
      if (normalized) scientificSynonyms.set(normalized, record);
    }
    const chineseName = normalizeLooseName(record.identity?.acceptedChineseName);
    if (chineseName) chineseNames.set(chineseName, record);
    for (const alias of record.identity?.aliases ?? []) {
      const normalized = normalizeLooseName(alias);
      if (normalized) aliases.set(normalized, record);
    }
    for (const [provider, externalId] of Object.entries(record.providerMappings ?? {})) {
      if (typeof externalId === 'string' && externalId.trim()) externalIds.set(`${provider}\u0000${externalId.trim()}`, record);
    }
  }
  return { externalIds, ids, scientificNames, scientificSynonyms, chineseNames, aliases };
}

export function checkCandidate(candidate, lookup) {
  const explicitMappings = candidate.providerMappings && typeof candidate.providerMappings === 'object' ? candidate.providerMappings : {};
  for (const [provider, id] of Object.entries(explicitMappings)) {
    const record = typeof id === 'string' ? lookup.externalIds.get(`${provider}\u0000${id.trim()}`) : undefined;
    if (record) return result('existing', record.id, `matched ${provider} ID ${id}`);
  }
  const external = parseExplicitExternalId(candidate.source);
  if (external) {
    const record = lookup.externalIds.get(`${external.provider}\u0000${external.id}`);
    if (record) return result('existing', record.id, `matched ${external.provider} ID ${external.id}`);
  }
  if (candidate.resolvedCanonicalTaxonId && lookup.ids.has(candidate.resolvedCanonicalTaxonId)) {
    return result('existing', candidate.resolvedCanonicalTaxonId, 'matched canonicalTaxonId');
  }
  const scientificName = normalizeScientificName(candidate.inputScientificName);
  if (scientificName) {
    const accepted = lookup.scientificNames.get(scientificName);
    if (accepted) return result('existing', accepted.id, 'matched accepted scientificName');
    const synonym = lookup.scientificSynonyms.get(scientificName);
    if (synonym) return result('existing', synonym.id, 'matched scientificSynonyms');
  }
  const inputName = normalizeLooseName(candidate.inputName);
  const named = lookup.chineseNames.get(inputName) ?? lookup.aliases.get(inputName);
  if (named) return result('needs_review', named.id, `Chinese name matches ${named.id}; name-only matching is not automatic`);
  return result('new', '', 'no exact external ID, canonical ID, accepted scientific name, or scientific synonym match');
}

export function checkCandidateBatch(candidates, lookup) {
  const duplicateKeys = new Map();
  const externalKeys = new Map();
  const canonicalIds = new Map();
  const results = candidates.map((candidate, index) => {
    const external = candidate?.providerMappings && typeof candidate.providerMappings === 'object'
      ? Object.entries(candidate.providerMappings).sort(([left], [right]) => left.localeCompare(right)).map(([provider, id]) => `${provider}:${id}`).join('|')
      : candidate?.source ?? '';
    const key = `${external}\u0000${normalizeScientificName(candidate?.inputScientificName)}\u0000${candidate?.resolvedCanonicalTaxonId ?? ''}`;
    const duplicateOf = key !== '\u0000\u0000' ? duplicateKeys.get(key) : undefined;
    if (key !== '\u0000\u0000') duplicateKeys.set(key, index);
    const providerMappings = candidate?.providerMappings && typeof candidate.providerMappings === 'object' ? candidate.providerMappings : {};
    const externalKey = Object.entries(providerMappings).sort(([left], [right]) => left.localeCompare(right)).map(([provider, id]) => `${provider}:${id}`).join('|');
    const externalDuplicateOf = externalKey ? externalKeys.get(externalKey) : undefined;
    if (externalKey) externalKeys.set(externalKey, index);
    const canonicalTaxonId = candidate?.resolvedCanonicalTaxonId?.trim();
    const canonicalDuplicateOf = canonicalTaxonId ? canonicalIds.get(canonicalTaxonId) : undefined;
    if (canonicalTaxonId) canonicalIds.set(canonicalTaxonId, index);
    return { ...checkCandidate(candidate ?? {}, lookup), duplicateOf, externalDuplicateOf, canonicalDuplicateOf };
  });
  return results;
}

function result(status, canonicalTaxonId, reason) { return { status, canonicalTaxonId, reason }; }
