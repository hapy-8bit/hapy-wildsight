/** Adds reviewed WildSight knowledge to a provider-neutral result without exposing internal sources. */
export class IdentificationEnrichmentService {
  constructor(repository) {
    this.repository = repository;
  }

  async enrich(result) {
    const resolved = await this.repository.find(result.provider, result.primary.name);
    if (!resolved) return result;
    const { record, matchType } = resolved;
    const knowledge = this.publicKnowledge(record);
    return {
      ...result,
      primary: {
        ...result.primary,
        name: knowledge.acceptedChineseName,
        canonicalSpeciesId: record.id,
        knowledgeMatch: matchType,
        knowledgeReviewStatus: record.reviewStatus,
        knowledge
      }
    };
  }

  publicKnowledge(record) {
    return {
      acceptedChineseName: record.identity.acceptedChineseName,
      scientificName: record.identity.scientificName,
      family: record.identity.family,
      genus: record.identity.genus,
      aliases: record.identity.aliases,
      summary: record.knowledge.summary,
      identificationReferences: record.knowledge.identificationReferences,
      howToConfirm: record.knowledge.howToConfirm,
      appearance: record.knowledge.appearance,
      growthHabit: record.knowledge.growthHabit,
      keyCharacteristics: record.knowledge.keyCharacteristics,
      observationTips: record.knowledge.observationTips,
      confusableSpecies: record.knowledge.confusableSpecies,
      observationReminder: record.knowledge.observationReminder,
      contentVersion: record.contentVersion,
      knowledgeReviewStatus: record.reviewStatus
    };
  }
}
