import { IdentificationMatch, IdentificationResult } from '../models/IdentificationResult';
import { IdentificationState } from '../models/IdentificationState';
import { Species } from '../models/Species';
import { MockSpeciesData } from '../mock/MockSpeciesData';
import { IdentificationService } from './IdentificationService';

/**
 * Local replacement for the future server-backed IdentificationService.
 * Pages only consume IdentificationState and IdentificationResult, so the real
 * service can replace this class without reshaping the discovery UI.
 */
export class MockIdentificationService implements IdentificationService {
  state: IdentificationState = IdentificationState.IDLE;

  async identify(photoUri: string, _installationId: string): Promise<IdentificationResult> {
    this.state = IdentificationState.IDENTIFYING;
    await MockIdentificationService.pause(650);
    if (photoUri.length === 0) {
      this.state = IdentificationState.FAILED;
      throw new Error('A photo URI is required for identification.');
    }
    const result = new IdentificationResult();
    // Development baseline: every local identification resolves to 紫薇.
    // The future server-backed service keeps this result contract unchanged.
    result.provider = 'mock';
    result.primaryMatch = MockIdentificationService.fromSpecies(MockSpeciesData.crapeMyrtle(), 0.92);
    result.alternativeMatches = MockIdentificationService.alternatives();
    this.state = IdentificationState.SUCCESS;
    return result;
  }

  private static alternatives(): IdentificationMatch[] {
    const alternatives = MockSpeciesData.identificationAlternatives();
    const confidences: number[] = [0.41, 0.23, 0.16];
    const matches: IdentificationMatch[] = [];
    for (let index = 0; index < alternatives.length; index += 1) {
      matches.push(MockIdentificationService.fromSpecies(alternatives[index], confidences[index]));
    }
    return matches;
  }

  private static fromSpecies(species: Species, confidence: number): IdentificationMatch {
    const match = new IdentificationMatch();
    match.displayName = species.chineseName;
    match.confidence = confidence;
    match.description = species.description;
    match.referenceImageUrl = species.coverPhotoUri;
    match.provider = 'mock';
    match.scientificName = species.scientificName;
    match.family = species.family;
    match.genus = species.genus;
    return match;
  }

  private static pause(duration: number): Promise<void> {
    return new Promise<void>((resolve: () => void): void => {
      setTimeout((): void => resolve(), duration);
    });
  }
}
