import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../data/plant-knowledge');
const index = await json('index.json');
const mappings = (await json('provider-name-mapping.json')).mappings ?? [];
const vocabulary = await json('catalog-vocabulary.json');
const config = await json('coverage-report-config.json');
const records = await Promise.all((index.species ?? []).map(async (entry) => ({ entry, record: await json(entry.path) })));
const unique = new Map(records.map(({ record }) => [record.id, record]));
const mappedIds = new Set(mappings.map((mapping) => mapping.canonicalTaxonId));

console.log(`Unique species: ${unique.size}`);
count('Taxon groups', unique.values(), (record) => [record.catalogMetadata?.taxonGroup]);
count('Growth forms', unique.values(), (record) => record.catalogMetadata?.growthForms ?? []);
count('Scene tags', unique.values(), (record) => record.catalogMetadata?.sceneTags ?? []);
count('Occurrence types', unique.values(), (record) => record.catalogMetadata?.occurrenceTypes ?? []);
count('Use tags', unique.values(), (record) => record.catalogMetadata?.useTags ?? []);
count('Coverage priority', unique.values(), (record) => [record.catalogMetadata?.coveragePriority]);
count('Publication / review', unique.values(), (record) => [`${record.status}/${record.reviewStatus}`]);

const completeness = { L0: 0, L1: 0, L2: 0 };
for (const record of unique.values()) completeness[completenessLevel(record)] += 1;
console.log('Completeness (highest achieved):', completeness);
console.log(`Mapped / unmapped species: ${[...unique.keys()].filter((id) => mappedIds.has(id)).length} / ${[...unique.keys()].filter((id) => !mappedIds.has(id)).length}`);

console.log('Coverage groups:');
for (const group of config.groups ?? []) {
  const ids = [...unique.values()].filter((record) => matches(record.catalogMetadata ?? {}, group)).map((record) => record.id);
  console.log(`- ${group.label}: ${new Set(ids).size}${ids.length > 0 ? ` (${ids.join(', ')})` : ''}`);
}

const missingMetadata = [...unique.values()].filter((record) => !record.catalogMetadata).map((record) => record.id);
const unknownTags = [...unique.values()].flatMap((record) => unknownCatalogTags(record, vocabulary));
const duplicates = duplicateCandidates(records.map(({ record }) => record));
console.log(`Missing catalogMetadata: ${missingMetadata.length}${missingMetadata.length ? ` (${missingMetadata.join(', ')})` : ''}`);
console.log(`Unknown tags: ${unknownTags.length}${unknownTags.length ? ` (${unknownTags.join('; ')})` : ''}`);
console.log(`Potential duplicates: ${duplicates.length}${duplicates.length ? ` (${duplicates.join('; ')})` : ''}`);

function completenessLevel(record) {
  const identity = record.identity ?? {};
  const l0 = Boolean(record.id && identity.acceptedChineseName && identity.scientificName && identity.family && identity.genus);
  if (!l0) return 'L0';
  const knowledge = record.knowledge ?? {};
  const l1 = Boolean(knowledge.summary || knowledge.appearance || knowledge.growthHabit || (Array.isArray(knowledge.keyCharacteristics) && knowledge.keyCharacteristics.length > 0));
  if (!l1) return 'L1';
  const l2 = [knowledge.identificationReferences, knowledge.howToConfirm, knowledge.observationTips].every((value) => Array.isArray(value) && value.length > 0) && Boolean(knowledge.observationReminder);
  return l2 ? 'L2' : 'L1';
}

function matches(metadata, group) {
  return Object.entries(group.all ?? {}).every(([field, expected]) => expected.every((value) => values(metadata[field]).includes(value))) &&
    Object.entries(group.any ?? {}).every(([field, expected]) => expected.some((value) => values(metadata[field]).includes(value)));
}

function values(value) { return Array.isArray(value) ? value : [value]; }
function count(label, records, pick) {
  const totals = {};
  for (const record of records) for (const value of pick(record).filter(Boolean)) totals[value] = (totals[value] ?? 0) + 1;
  console.log(`${label}:`, totals);
}
function unknownCatalogTags(record, terms) {
  const metadata = record.catalogMetadata;
  if (!metadata) return [];
  return ['taxonGroup', 'growthForms', 'sceneTags', 'occurrenceTypes', 'useTags', 'coveragePriority'].flatMap((field) => values(metadata[field]).filter((value) => !Object.hasOwn(terms[field], value)).map((value) => `${record.id}:${field}/${value}`));
}
function duplicateCandidates(records) {
  const seen = new Map();
  const results = [];
  for (const record of records) {
    const name = record.identity?.scientificName?.trim().replace(/\s+/g, ' ').toLowerCase();
    if (name && seen.has(name)) results.push(`${seen.get(name)} / ${record.id} (scientificName)`);
    if (name) seen.set(name, record.id);
  }
  return results;
}
async function json(relativePath) { return JSON.parse(await readFile(path.resolve(root, relativePath), 'utf8')); }
