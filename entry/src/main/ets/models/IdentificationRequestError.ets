export enum IdentificationErrorCode {
  DAILY_LIMIT_REACHED = 'DAILY_LIMIT_REACHED',
  INVALID_IMAGE = 'INVALID_IMAGE',
  IDENTIFICATION_FAILED = 'IDENTIFICATION_FAILED',
  UPSTREAM_TIMEOUT = 'UPSTREAM_TIMEOUT',
  SERVER_ERROR = 'SERVER_ERROR',
  NETWORK_UNAVAILABLE = 'NETWORK_UNAVAILABLE'
}

/** Structured client-facing failure from the provider-neutral backend API. */
export class IdentificationRequestError extends Error {
  readonly errorCode: IdentificationErrorCode;

  constructor(errorCode: IdentificationErrorCode, message: string) {
    super(message);
    this.errorCode = errorCode;
  }
}
