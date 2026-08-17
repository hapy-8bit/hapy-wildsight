import { http } from '@kit.NetworkKit';
import { EnvironmentConfig } from '../constants/EnvironmentConfig';
import { SpeciesKnowledge } from '../models/IdentificationResult';

export class PlantKnowledgeService {
  async fetch(canonicalTaxonId: string): Promise<SpeciesKnowledge | undefined> {
    if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(canonicalTaxonId)) return undefined;
    const request = http.createHttp();
    try {
      const response = await request.request(`${EnvironmentConfig.apiBaseUrl()}/knowledge/species/${canonicalTaxonId}`, {
        method: http.RequestMethod.GET, expectDataType: http.HttpDataType.STRING, connectTimeout: 10000, readTimeout: 15000
      });
      if (response.responseCode !== 200 || typeof response.result !== 'string') return undefined;
      const raw = JSON.parse(response.result) as Object;
      const knowledge = new SpeciesKnowledge();
      knowledge.acceptedChineseName = this.string(raw, 'acceptedChineseName');
      knowledge.scientificName = this.string(raw, 'scientificName'); knowledge.family = this.string(raw, 'family'); knowledge.genus = this.string(raw, 'genus');
      knowledge.aliases = this.strings(raw, 'aliases'); knowledge.summary = this.string(raw, 'summary'); knowledge.identificationReferences = this.strings(raw, 'identificationReferences');
      knowledge.howToConfirm = this.strings(raw, 'howToConfirm'); knowledge.appearance = this.string(raw, 'appearance'); knowledge.growthHabit = this.string(raw, 'growthHabit');
      knowledge.keyCharacteristics = this.strings(raw, 'keyCharacteristics'); knowledge.observationTips = this.strings(raw, 'observationTips');
      knowledge.confusableSpecies = this.strings(raw, 'confusableSpecies'); knowledge.observationReminder = this.string(raw, 'observationReminder');
      const version: Object = Reflect.get(raw, 'contentVersion') as Object; knowledge.contentVersion = typeof version === 'number' ? version : 0;
      knowledge.knowledgeReviewStatus = this.string(raw, 'knowledgeReviewStatus');
      return knowledge;
    } catch (_error) { return undefined; } finally { request.destroy(); }
  }
  private string(raw: Object, key: string): string { const value: Object = Reflect.get(raw, key) as Object; return typeof value === 'string' ? value : ''; }
  private strings(raw: Object, key: string): string[] { const value: Object = Reflect.get(raw, key) as Object; const result: string[] = []; if (Array.isArray(value)) { for (const item of value as Object[]) { if (typeof item === 'string') result.push(item); } } return result; }
}
