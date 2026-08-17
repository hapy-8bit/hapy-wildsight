import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

export enum AppearanceMode { SYSTEM = 'system', LIGHT = 'light', DARK = 'dark' }

/** Persists the user's explicit rendering preference; system mode remains the default. */
export class AppearancePreferenceService {
  private static readonly STORE = 'wildsight_settings';
  private static readonly KEY = 'appearance_mode';

  async load(context: common.UIAbilityContext): Promise<AppearanceMode> {
    const store = await preferences.getPreferences(context, AppearancePreferenceService.STORE);
    const value = await store.get(AppearancePreferenceService.KEY, AppearanceMode.SYSTEM);
    return value === AppearanceMode.DARK ? AppearanceMode.DARK : value === AppearanceMode.LIGHT ? AppearanceMode.LIGHT : AppearanceMode.SYSTEM;
  }

  async save(context: common.UIAbilityContext, mode: AppearanceMode): Promise<void> {
    const store = await preferences.getPreferences(context, AppearancePreferenceService.STORE);
    await store.put(AppearancePreferenceService.KEY, mode);
    await store.flush();
  }
}
