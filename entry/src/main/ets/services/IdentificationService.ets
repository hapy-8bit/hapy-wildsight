import { IdentificationResult } from '../models/IdentificationResult';

/** UI-facing recognition contract. Provider choice stays behind this boundary. */
export interface IdentificationService {
  identify(photoUri: string, installationId: string): Promise<IdentificationResult>;
}
