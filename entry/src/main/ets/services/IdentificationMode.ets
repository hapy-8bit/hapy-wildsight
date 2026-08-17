import { EnvironmentConfig } from '../constants/EnvironmentConfig';

export enum IdentificationMode {
  MOCK = 'Mock',
  REMOTE = 'Remote'
}

/** The service implementation is swappable without changing pages or models. */
export class IdentificationConfiguration {
  static readonly mode: IdentificationMode = IdentificationMode.REMOTE;
  static readonly backendEndpoint: string = EnvironmentConfig.apiBaseUrl();
}
