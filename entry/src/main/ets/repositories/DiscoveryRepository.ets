import { relationalStore } from '@kit.ArkData';
import { AppDatabase } from '../database/AppDatabase';
import { Discovery } from '../models/Discovery';

/** Persistence for encounters. It deliberately has no Species fields beyond speciesId. */
export class DiscoveryRepository {
  async save(discovery: Discovery): Promise<void> {
    const values: relationalStore.ValuesBucket = {
      id: discovery.id,
      observation_code: discovery.observationCode,
      species_id: discovery.speciesId,
      photo_uri: discovery.photoUri,
      identified_at: discovery.identifiedAt.getTime(),
      discovered_at: discovery.discoveredAt.getTime(),
      latitude: discovery.latitude ?? null,
      longitude: discovery.longitude ?? null,
      location_name: discovery.locationName,
      weather: discovery.weather,
      temperature: discovery.temperature ?? null,
      confidence: discovery.confidence,
      note: discovery.note,
      created_at: discovery.createdAt.getTime(),
      updated_at: discovery.updatedAt.getTime()
    };
    await AppDatabase.getStore().insert('discoveries', values, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  async listForSpecies(speciesId: string): Promise<Discovery[]> {
    const predicates = new relationalStore.RdbPredicates('discoveries');
    predicates.equalTo('species_id', speciesId).orderByDesc('discovered_at');
    const resultSet = await AppDatabase.getStore().query(predicates, []);
    const discoveries: Discovery[] = [];
    try {
      while (resultSet.goToNextRow()) {
        discoveries.push(this.map(resultSet));
      }
      return discoveries;
    } finally {
      resultSet.close();
    }
  }

  async listAll(): Promise<Discovery[]> {
    const predicates = new relationalStore.RdbPredicates('discoveries');
    predicates.orderByDesc('discovered_at');
    const resultSet = await AppDatabase.getStore().query(predicates, []);
    const discoveries: Discovery[] = [];
    try {
      while (resultSet.goToNextRow()) {
        discoveries.push(this.map(resultSet));
      }
      return discoveries;
    } finally {
      resultSet.close();
    }
  }

  async deleteAll(): Promise<number> {
    return AppDatabase.getStore().delete(new relationalStore.RdbPredicates('discoveries'));
  }

  private map(resultSet: relationalStore.ResultSet): Discovery {
    const discovery = new Discovery();
    discovery.id = resultSet.getString(resultSet.getColumnIndex('id'));
    discovery.observationCode = resultSet.getString(resultSet.getColumnIndex('observation_code'));
    discovery.speciesId = resultSet.getString(resultSet.getColumnIndex('species_id'));
    discovery.photoUri = resultSet.getString(resultSet.getColumnIndex('photo_uri'));
    discovery.identifiedAt = new Date(resultSet.getLong(resultSet.getColumnIndex('identified_at')));
    discovery.discoveredAt = new Date(resultSet.getLong(resultSet.getColumnIndex('discovered_at')));
    const latitudeIndex = resultSet.getColumnIndex('latitude');
    const longitudeIndex = resultSet.getColumnIndex('longitude');
    const temperatureIndex = resultSet.getColumnIndex('temperature');
    discovery.latitude = resultSet.isColumnNull(latitudeIndex) ? undefined : resultSet.getDouble(latitudeIndex);
    discovery.longitude = resultSet.isColumnNull(longitudeIndex) ? undefined : resultSet.getDouble(longitudeIndex);
    discovery.locationName = resultSet.getString(resultSet.getColumnIndex('location_name'));
    discovery.weather = resultSet.getString(resultSet.getColumnIndex('weather'));
    discovery.temperature = resultSet.isColumnNull(temperatureIndex) ? undefined : resultSet.getDouble(temperatureIndex);
    discovery.confidence = resultSet.getDouble(resultSet.getColumnIndex('confidence'));
    discovery.note = resultSet.getString(resultSet.getColumnIndex('note'));
    discovery.createdAt = new Date(resultSet.getLong(resultSet.getColumnIndex('created_at')));
    discovery.updatedAt = new Date(resultSet.getLong(resultSet.getColumnIndex('updated_at')));
    return discovery;
  }
}
