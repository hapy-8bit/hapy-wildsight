import { relationalStore } from '@kit.ArkData';
import { AppDatabase } from '../database/AppDatabase';
import { OrganismCategory, PetSafety, Species } from '../models/Species';

export class SpeciesRepository {
  async upsert(species: Species): Promise<void> {
    const values: relationalStore.ValuesBucket = {
      id: species.id,
      category: species.category,
      chinese_name: species.chineseName,
      scientific_name: species.scientificName,
      aliases_json: JSON.stringify(species.aliases),
      family: species.family,
      genus: species.genus,
      description: species.description,
      distribution: species.distribution,
      features_json: JSON.stringify(species.features),
      flowering_period: species.floweringPeriod,
      toxicity: species.toxicity,
      pet_safety: species.petSafety,
      cover_photo_uri: species.coverPhotoUri,
      canonical_taxon_id: species.canonicalTaxonId,
      knowledge_json: species.knowledgeJson,
      knowledge_version: species.knowledgeVersion,
      knowledge_review_status: species.knowledgeReviewStatus,
      updated_at: Date.now()
    };
    const store = AppDatabase.getStore();
    const predicates = new relationalStore.RdbPredicates('species');
    predicates.equalTo('id', species.id);
    const updatedCount = await store.update(values, predicates);
    if (updatedCount === 0) {
      await store.insert('species', values);
    }
  }

  async findById(id: string): Promise<Species | undefined> {
    const predicates = new relationalStore.RdbPredicates('species');
    predicates.equalTo('id', id);
    const resultSet = await AppDatabase.getStore().query(predicates, []);
    try {
      if (resultSet.goToFirstRow()) {
        return this.map(resultSet);
      }
      return undefined;
    } finally {
      resultSet.close();
    }
  }

  async findByCanonicalTaxonId(canonicalTaxonId: string): Promise<Species | undefined> {
    if (canonicalTaxonId.length === 0) {
      return undefined;
    }
    const predicates = new relationalStore.RdbPredicates('species');
    predicates.equalTo('canonical_taxon_id', canonicalTaxonId);
    const resultSet = await AppDatabase.getStore().query(predicates, []);
    try {
      if (resultSet.goToFirstRow()) {
        return this.map(resultSet);
      }
      return undefined;
    } finally {
      resultSet.close();
    }
  }

  async updateKnowledgeByCanonicalTaxonId(species: Species): Promise<void> {
    if (species.canonicalTaxonId.length === 0) return;
    const values: relationalStore.ValuesBucket = {
      chinese_name: species.chineseName, scientific_name: species.scientificName,
      aliases_json: JSON.stringify(species.aliases), family: species.family, genus: species.genus,
      description: species.description, features_json: JSON.stringify(species.features),
      knowledge_json: species.knowledgeJson, knowledge_version: species.knowledgeVersion,
      knowledge_review_status: species.knowledgeReviewStatus, updated_at: Date.now()
    };
    const predicates = new relationalStore.RdbPredicates('species');
    predicates.equalTo('canonical_taxon_id', species.canonicalTaxonId);
    await AppDatabase.getStore().update(values, predicates);
  }

  async listAll(): Promise<Species[]> {
    const predicates = new relationalStore.RdbPredicates('species');
    predicates.orderByAsc('chinese_name');
    const resultSet = await AppDatabase.getStore().query(predicates, []);
    const species: Species[] = [];
    try {
      while (resultSet.goToNextRow()) {
        species.push(this.map(resultSet));
      }
      return species;
    } finally {
      resultSet.close();
    }
  }

  async deleteAll(): Promise<number> {
    return AppDatabase.getStore().delete(new relationalStore.RdbPredicates('species'));
  }

  private map(resultSet: relationalStore.ResultSet): Species {
    const species = new Species();
    species.id = resultSet.getString(resultSet.getColumnIndex('id'));
    species.category = resultSet.getString(resultSet.getColumnIndex('category')) as OrganismCategory;
    species.chineseName = resultSet.getString(resultSet.getColumnIndex('chinese_name'));
    species.scientificName = resultSet.getString(resultSet.getColumnIndex('scientific_name'));
    species.aliases = JSON.parse(resultSet.getString(resultSet.getColumnIndex('aliases_json'))) as string[];
    species.family = resultSet.getString(resultSet.getColumnIndex('family'));
    species.genus = resultSet.getString(resultSet.getColumnIndex('genus'));
    species.description = resultSet.getString(resultSet.getColumnIndex('description'));
    species.distribution = resultSet.getString(resultSet.getColumnIndex('distribution'));
    species.features = JSON.parse(resultSet.getString(resultSet.getColumnIndex('features_json'))) as string[];
    species.floweringPeriod = resultSet.getString(resultSet.getColumnIndex('flowering_period'));
    species.toxicity = resultSet.getString(resultSet.getColumnIndex('toxicity'));
    species.petSafety = resultSet.getString(resultSet.getColumnIndex('pet_safety')) as PetSafety;
    species.coverPhotoUri = resultSet.getString(resultSet.getColumnIndex('cover_photo_uri'));
    species.canonicalTaxonId = resultSet.getString(resultSet.getColumnIndex('canonical_taxon_id'));
    species.knowledgeJson = resultSet.getString(resultSet.getColumnIndex('knowledge_json'));
    species.knowledgeVersion = resultSet.getLong(resultSet.getColumnIndex('knowledge_version'));
    species.knowledgeReviewStatus = resultSet.getString(resultSet.getColumnIndex('knowledge_review_status'));
    return species;
  }
}
