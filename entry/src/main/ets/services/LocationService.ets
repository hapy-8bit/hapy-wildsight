export class LocationSnapshot {
  latitude: number | undefined = undefined;
  longitude: number | undefined = undefined;
  locationName: string = '';
}

/** Capability boundary only; no location request is made in this phase. */
export class LocationService {
  async capture(): Promise<LocationSnapshot> {
    throw new Error('Location is not connected in the Mock phase.');
  }
}
