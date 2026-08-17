import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { AppDatabase } from '../database/AppDatabase';
import { AppColors } from '../constants/AppColors';
import { AppearanceMode, AppearancePreferenceService } from '../services/AppearancePreferenceService';

export default class EntryAbility extends UIAbility {
  private readonly appearancePreferences: AppearancePreferenceService = new AppearancePreferenceService();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.configureSystemBars(windowStage).then(() => {
      AppDatabase.initialize(this.context)
        .then(() => windowStage.loadContent('pages/Index'))
        .catch(() => windowStage.loadContent('pages/Index'));
    });
  }

  /**
   * Keep the system-provided safe areas visible, while giving them the same paper surface as ArkUI.
   * This removes the detached white status/navigation strips without placing interactive content
   * underneath system indicators.
   */
  private async configureSystemBars(windowStage: window.WindowStage): Promise<void> {
    try {
      const mainWindow = await windowStage.getMainWindow();
      const dark = await this.resolveDarkMode();
      const surface = dark ? '#FF151A18' : '#FFF5F3EF';
      const content = dark ? '#FFFFFFFF' : '#FF1E251F';

      // Seed the runtime palette before the first ArkUI frame is built.
      AppColors.apply(dark);
      mainWindow.setWindowBackgroundColor(surface);
      mainWindow.setImmersiveModeEnabledState(true);
      await mainWindow.setWindowLayoutFullScreen(true).catch(() => {
        // Full-screen layout is unavailable on some device configurations.
      });
      await mainWindow.setWindowSystemBarProperties({
        // Use an opaque theme-matched seed during cold start. App.syncSystemBars()
        // switches both bars back to transparent after the app surface is ready.
        statusBarColor: surface,
        navigationBarColor: surface,
        statusBarContentColor: content,
        navigationBarContentColor: content,
        isStatusBarLightIcon: dark,
        isNavigationBarLightIcon: dark
      }).catch(() => {
        // A system bar capability can be unavailable on a particular device; page content remains usable.
      });
    } catch (_error) {
      // Window creation is asynchronous. No fallback layout is required if it is already being destroyed.
    }
  }

  private isDarkMode(): boolean {
    return this.context.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  }

  private async resolveDarkMode(): Promise<boolean> {
    const systemDark = this.isDarkMode();
    try {
      const mode = await this.appearancePreferences.load(this.context);
      if (mode === AppearanceMode.DARK) {
        this.context.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
        return true;
      }
      if (mode === AppearanceMode.LIGHT) {
        this.context.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
        return false;
      }
      this.context.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (_error) {
      // Fall back to the resolved system color mode when preferences are unavailable.
    }
    return systemDark;
  }
}
