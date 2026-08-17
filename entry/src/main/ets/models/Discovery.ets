/** A Discovery is the user's core asset: one actual encounter with one species. */
export class Discovery {
  id: string = '';
  observationCode: string = '';
  speciesId: string = '';
  photoUri: string = '';
  identifiedAt: Date = new Date();
  discoveredAt: Date = new Date();
  latitude: number | undefined = undefined;
  longitude: number | undefined = undefined;
  locationName: string = '';
  weather: string = '';
  temperature: number | undefined = undefined;
  confidence: number = 0;
  note: string = '';
  createdAt: Date = new Date();
  updatedAt: Date = new Date();
}

export class DiscoverySummary {
  speciesId: string = '';
  encounterCount: number = 0;
  firstDiscovery: Discovery | undefined = undefined;
  latestDiscovery: Discovery | undefined = undefined;
  locations: string[] = [];
}
