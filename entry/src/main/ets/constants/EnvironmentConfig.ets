export enum AppEnvironment {
  DEVELOPMENT = 'development',
  PRODUCTION = 'production'
}

/**
 * The only client-side location for backend addresses. Development uses the
 * deployed WildSight HTTPS domain. Both environments intentionally use the
 * same public API while the app is in this single-environment beta stage.
 */
export class EnvironmentConfig {
  static readonly environment: AppEnvironment = AppEnvironment.DEVELOPMENT;
  static readonly DEV_API_BASE_URL: string = 'https://api.hapybuilds.com';
  static readonly PROD_API_BASE_URL: string = 'https://api.hapybuilds.com';

  static apiBaseUrl(): string {
    return EnvironmentConfig.environment === AppEnvironment.PRODUCTION
      ? EnvironmentConfig.PROD_API_BASE_URL
      : EnvironmentConfig.DEV_API_BASE_URL;
  }
}
