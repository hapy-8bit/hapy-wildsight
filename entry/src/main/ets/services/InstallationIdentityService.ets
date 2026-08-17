import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { util } from '@kit.ArkTS';

/**
 * A random per-installation value for quota accounting. It is not a hardware
 * identifier and is never used as a user account.
 */
export class InstallationIdentityService {
  private static readonly STORE_NAME: string = 'wildsight_runtime';
  private static readonly INSTALLATION_ID_KEY: string = 'installation_id';

  async getOrCreate(context: common.UIAbilityContext): Promise<string> {
    const store = await preferences.getPreferences(context, InstallationIdentityService.STORE_NAME);
    const stored = await store.get(InstallationIdentityService.INSTALLATION_ID_KEY, '');
    if (typeof stored === 'string' && stored.length >= 16) {
      return stored;
    }
    const installationId = util.generateRandomUUID(true);
    await store.put(InstallationIdentityService.INSTALLATION_ID_KEY, installationId);
    await store.flush();
    return installationId;
  }
}
