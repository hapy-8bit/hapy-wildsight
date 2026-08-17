import { writeFile } from 'node:fs/promises';
import path from 'node:path';
import { buildIndex, knowledgeRoot, readSpeciesRecords, stableJson } from './plant-knowledge-utils.js';

const checkOnly = process.argv.includes('--check');
const generated = stableJson(buildIndex(await readSpeciesRecords()));
const indexPath = path.join(knowledgeRoot, 'index.json');

if (checkOnly) {
  const { readFile } = await import('node:fs/promises');
  let current = '';
  try { current = await readFile(indexPath, 'utf8'); } catch { /* reported below */ }
  if (current !== generated) {
    console.error('Plant knowledge index is out of date. Run npm run build:knowledge-index.');
    process.exitCode = 1;
  } else console.log('Plant knowledge index is current.');
} else {
  await writeFile(indexPath, generated, 'utf8');
  console.log(`Built plant knowledge index: ${generated ? JSON.parse(generated).species.length : 0} species.`);
}
