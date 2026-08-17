import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

/** Stores only the user's decision to allow the image-identification flow. */
export class PrivacyConsentService {
  private static readonly STORE = 'wildsight_privacy';
  private static readonly KEY = 'image_identification_consent';

  async load(context: common.UIAbilityContext): Promise<boolean> {
    const store = await preferences.getPreferences(context, PrivacyConsentService.STORE);
    return (await store.get(PrivacyConsentService.KEY, false)) === true;
  }

  async save(context: common.UIAbilityContext, accepted: boolean): Promise<void> {
    const store = await preferences.getPreferences(context, PrivacyConsentService.STORE);
    await store.put(PrivacyConsentService.KEY, accepted);
    await store.flush();
  }
}
