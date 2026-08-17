import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const DEFAULT_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../data/plant-knowledge');

/** Reads reviewed, versioned knowledge JSON. Broken entries degrade to no match. */
export class PlantKnowledgeRepository {
  constructor(rootPath = DEFAULT_ROOT) {
    this.rootPath = rootPath;
  }

  async find(provider, name) {
    try {
      const mapping = await this.findMapping(provider, name);
      if (!mapping) return undefined;
      const index = await this.readJson('index.json');
      const entry = index.species?.find((item) => item.id === mapping.canonicalTaxonId && item.status === 'published');
      if (!entry) return undefined;
      const record = await this.readJson(entry.path);
      if (record.id !== mapping.canonicalTaxonId || record.status !== 'published' || record.reviewStatus !== 'reviewed') return undefined;
      return { record, matchType: mapping.matchType };
    } catch {
      return undefined;
    }
  }

  async findPublishedById(canonicalTaxonId) {
    try {
      const index = await this.readJson('index.json');
      const entry = index.species?.find((item) => item.id === canonicalTaxonId && item.status === 'published' && item.reviewStatus === 'reviewed');
      if (!entry) return undefined;
      const record = await this.readJson(entry.path);
      return record.id === canonicalTaxonId && record.status === 'published' && record.reviewStatus === 'reviewed' ? record : undefined;
    } catch {
      return undefined;
    }
  }

  async findMapping(provider, name) {
    const mappingFile = await this.readJson('provider-name-mapping.json');
    const exact = mappingFile.mappings?.find((item) => item.provider === provider && item.name === name && item.verified === true && item.matchType === 'exact');
    if (exact) return exact;
    return mappingFile.mappings?.find((item) => item.provider === provider && item.name === name && item.verified === true && item.matchType === 'alias');
  }

  async readJson(relativePath) {
    const fullPath = path.resolve(this.rootPath, relativePath);
    if (!fullPath.startsWith(`${this.rootPath}${path.sep}`) && fullPath !== this.rootPath) throw new Error('Invalid knowledge path');
    return JSON.parse(await readFile(fullPath, 'utf8'));
  }
}
