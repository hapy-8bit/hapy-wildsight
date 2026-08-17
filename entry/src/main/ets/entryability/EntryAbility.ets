import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { AppDatabase } from '../database/AppDatabase';
import { AppColors } from '../constants/AppColors';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.configureSystemBars(windowStage);
    AppDatabase.initialize(this.context)
      .then(() => windowStage.loadContent('pages/Index'))
      .catch(() => windowStage.loadContent('pages/Index'));
  }

  /**
   * Keep the system-provided safe areas visible, while giving them the same paper surface as ArkUI.
   * This removes the detached white status/navigation strips without placing interactive content
   * underneath system indicators.
   */
  private configureSystemBars(windowStage: window.WindowStage): void {
    windowStage.getMainWindow().then((mainWindow: window.Window) => {
      mainWindow.setWindowBackgroundColor('#00000000');
      mainWindow.setImmersiveModeEnabledState(true);
      mainWindow.setWindowLayoutFullScreen(true).catch(() => {
        // Full-screen layout is unavailable on some device configurations.
      });
      mainWindow.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        navigationBarColor: '#00000000',
        statusBarContentColor: AppColors.TEXT_PRIMARY,
        navigationBarContentColor: AppColors.TEXT_PRIMARY,
        isStatusBarLightIcon: false,
        isNavigationBarLightIcon: false
      }).catch(() => {
        // A system bar capability can be unavailable on a particular device; page content remains usable.
      });
    }).catch(() => {
      // Window creation is asynchronous. No fallback layout is required if it is already being destroyed.
    });
  }
}
