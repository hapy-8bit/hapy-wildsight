export enum OrganismCategory {
  PLANT = 'plant',
  INSECT = 'insect',
  BIRD = 'bird',
  FUNGI = 'fungi',
  OTHER = 'other'
}

export enum PetSafety {
  SAFE = 'safe',
  CAUTION = 'caution',
  TOXIC = 'toxic',
  UNKNOWN = 'unknown'
}

/** A taxonomic knowledge object. It never contains a user's personal encounter. */
export class Species {
  id: string = '';
  category: OrganismCategory = OrganismCategory.PLANT;
  chineseName: string = '';
  scientificName: string = '';
  aliases: string[] = [];
  family: string = '';
  genus: string = '';
  description: string = '';
  distribution: string = '';
  features: string[] = [];
  floweringPeriod: string = '';
  toxicity: string = '';
  petSafety: PetSafety = PetSafety.UNKNOWN;
  coverPhotoUri: string = '';
  canonicalTaxonId: string = '';
  knowledgeJson: string = '';
  knowledgeVersion: number = 0;
  knowledgeReviewStatus: string = '';
}
