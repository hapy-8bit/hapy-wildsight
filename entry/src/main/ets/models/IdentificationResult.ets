/** Provider-neutral recognition data. Taxonomy is absent until a knowledge source verifies it. */
export class SpeciesKnowledge {
  acceptedChineseName: string = '';
  scientificName: string = '';
  family: string = '';
  genus: string = '';
  aliases: string[] = [];
  summary: string = '';
  identificationReferences: string[] = [];
  howToConfirm: string[] = [];
  appearance: string = '';
  growthHabit: string = '';
  keyCharacteristics: string[] = [];
  observationTips: string[] = [];
  confusableSpecies: string[] = [];
  observationReminder: string = '';
  contentVersion: number = 0;
  knowledgeReviewStatus: string = '';
}

export class IdentificationMatch {
  displayName: string = '';
  confidence: number = 0;
  description: string | undefined = undefined;
  referenceImageUrl: string | undefined = undefined;
  provider: string = '';
  scientificName: string | undefined = undefined;
  family: string | undefined = undefined;
  genus: string | undefined = undefined;
  canonicalSpeciesId: string | undefined = undefined;
  knowledgeMatch: string | undefined = undefined;
  knowledgeReviewStatus: string | undefined = undefined;
  knowledge: SpeciesKnowledge | undefined = undefined;
}

export class IdentificationResult {
  provider: string = '';
  primaryMatch: IdentificationMatch = new IdentificationMatch();
  alternativeMatches: IdentificationMatch[] = [];
}
