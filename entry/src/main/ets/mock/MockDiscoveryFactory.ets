import { Discovery } from '../models/Discovery';

/** Creates encounter records in the Mock phase exactly as the real flow will do. */
export class MockDiscoveryFactory {
  static create(speciesId: string, photoUri: string, confidence: number, existing: Discovery[]): Discovery {
    const now = new Date();
    const discovery = new Discovery();
    discovery.id = `disc_mock_${now.getTime()}_${existing.length}`;
    discovery.observationCode = MockDiscoveryFactory.nextObservationCode(existing);
    discovery.speciesId = speciesId;
    discovery.photoUri = photoUri;
    discovery.identifiedAt = now;
    discovery.discoveredAt = now;
    // Location is intentionally not recorded: this flow has no location
    // permission or provider, and must not invent a place for the user.
    discovery.locationName = '';
    discovery.confidence = confidence;
    discovery.note = '';
    discovery.createdAt = now;
    discovery.updatedAt = now;
    return discovery;
  }

  private static nextObservationCode(existing: Discovery[]): string {
    let highestNumber = 0;
    for (let index = 0; index < existing.length; index += 1) {
      const value = Number(existing[index].observationCode.replace('OBS.', ''));
      if (!Number.isNaN(value) && value > highestNumber) {
        highestNumber = value;
      }
    }
    return `OBS.${(highestNumber + 1).toString().padStart(4, '0')}`;
  }
}
