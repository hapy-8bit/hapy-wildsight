import { Context } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';

/**
 * The only local persistent store in V1. Repositories own all SQL access;
 * pages must not call relationalStore directly.
 */
export class AppDatabase {
  private static store: relationalStore.RdbStore | undefined = undefined;
  private static initialization: Promise<void> | undefined = undefined;

  static async initialize(context: Context): Promise<void> {
    if (AppDatabase.store !== undefined) {
      return;
    }
    if (AppDatabase.initialization !== undefined) {
      return AppDatabase.initialization;
    }
    AppDatabase.initialization = AppDatabase.open(context);
    return AppDatabase.initialization;
  }

  private static async open(context: Context): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: 'wildsight.db',
      securityLevel: relationalStore.SecurityLevel.S1
    };
    AppDatabase.store = await relationalStore.getRdbStore(context, config);
    await AppDatabase.createSchema(AppDatabase.store);
  }

  static getStore(): relationalStore.RdbStore {
    if (AppDatabase.store === undefined) {
      throw new Error('AppDatabase is not initialized.');
    }
    return AppDatabase.store;
  }

  private static async createSchema(store: relationalStore.RdbStore): Promise<void> {
    await store.executeSql(`CREATE TABLE IF NOT EXISTS species (
      id TEXT PRIMARY KEY NOT NULL,
      category TEXT NOT NULL,
      chinese_name TEXT NOT NULL,
      scientific_name TEXT NOT NULL,
      aliases_json TEXT NOT NULL,
      family TEXT NOT NULL,
      genus TEXT NOT NULL,
      description TEXT NOT NULL,
      distribution TEXT NOT NULL,
      features_json TEXT NOT NULL,
      flowering_period TEXT NOT NULL,
      toxicity TEXT NOT NULL,
      pet_safety TEXT NOT NULL,
      cover_photo_uri TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    )`);

    await store.executeSql(`CREATE TABLE IF NOT EXISTS discoveries (
      id TEXT PRIMARY KEY NOT NULL,
      observation_code TEXT NOT NULL UNIQUE,
      species_id TEXT NOT NULL,
      photo_uri TEXT NOT NULL,
      identified_at INTEGER NOT NULL,
      discovered_at INTEGER NOT NULL,
      latitude REAL,
      longitude REAL,
      location_name TEXT NOT NULL,
      weather TEXT NOT NULL,
      temperature REAL,
      confidence REAL NOT NULL,
      note TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY(species_id) REFERENCES species(id) ON DELETE RESTRICT
    )`);

    // `CREATE TABLE IF NOT EXISTS` never updates an installed database. Each
    // additive migration is intentionally independent so existing encounters,
    // photo URIs and primary keys stay untouched.
    await AppDatabase.addSpeciesColumnIfMissing(store, 'canonical_taxon_id TEXT NOT NULL DEFAULT \'\'');
    await AppDatabase.addSpeciesColumnIfMissing(store, 'knowledge_json TEXT NOT NULL DEFAULT \'\'');
    await AppDatabase.addSpeciesColumnIfMissing(store, 'knowledge_version INTEGER NOT NULL DEFAULT 0');
    await AppDatabase.addSpeciesColumnIfMissing(store, 'knowledge_review_status TEXT NOT NULL DEFAULT \'\'');

    await store.executeSql('CREATE INDEX IF NOT EXISTS idx_discoveries_species_date ON discoveries(species_id, discovered_at DESC)');
    await store.executeSql('CREATE INDEX IF NOT EXISTS idx_discoveries_date ON discoveries(discovered_at DESC)');
  }

  private static async addSpeciesColumnIfMissing(store: relationalStore.RdbStore, definition: string): Promise<void> {
    try {
      await store.executeSql(`ALTER TABLE species ADD COLUMN ${definition}`);
    } catch (_error) {
      // SQLite reports a duplicate-column error after the first successful
      // migration. Any existing app data remains available in that case.
    }
  }
}
