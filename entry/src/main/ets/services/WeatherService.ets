export class WeatherSnapshot {
  condition: string = '';
  temperature: number | undefined = undefined;
}

/** Weather will be served by the product backend later; no public weather API is used here. */
export class WeatherService {
  async fetch(): Promise<WeatherSnapshot> {
    throw new Error('Weather is not connected in the Mock phase.');
  }
}
