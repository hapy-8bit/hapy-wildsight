import { WildSightApp } from '../App';
import { AppColors } from '../constants/AppColors';

@Entry
@Component
struct Index {
  private static readonly SPLASH_TOTAL_DURATION_MS: number = 1000;
  private static readonly SPLASH_FADE_IN_DURATION_MS: number = 160;
  private static readonly SPLASH_FADE_OUT_DURATION_MS: number = 180;
  @State private splashVisible: boolean = true;
  @State private splashOpacity: number = 1;
  @State private brandOpacity: number = 0;
  private splashTimer: number = -1;
  private splashStarted: boolean = false;

  aboutToAppear(): void {
    this.playSplash();
  }

  aboutToDisappear(): void {
    this.cancelSplashTimer();
    this.splashStarted = false;
  }

  private playSplash(): void {
    if (this.splashStarted) return;
    this.splashStarted = true;

    animateTo({ duration: Index.SPLASH_FADE_IN_DURATION_MS, curve: Curve.EaseOut }, () => {
      this.brandOpacity = 1;
    });

    const fadeStartDelay = Index.SPLASH_TOTAL_DURATION_MS - Index.SPLASH_FADE_OUT_DURATION_MS;
    this.splashTimer = setTimeout((): void => {
      this.splashTimer = -1;
      animateTo({
        duration: Index.SPLASH_FADE_OUT_DURATION_MS,
        curve: Curve.EaseInOut,
        onFinish: (): void => {
          this.splashVisible = false;
          this.splashStarted = false;
        }
      }, () => {
        this.splashOpacity = 0;
      });
    }, fadeStartDelay);
  }

  private cancelSplashTimer(): void {
    if (this.splashTimer >= 0) {
      clearTimeout(this.splashTimer);
      this.splashTimer = -1;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      WildSightApp()
      if (this.splashVisible) {
        Stack({ alignContent: Alignment.Center }) {
          Column({ space: 18 }) {
            Stack({ alignContent: Alignment.Center }) {
              Image($r('app.media.foreground'))
                .width(116)
                .height(116)
                .objectFit(ImageFit.Contain)
            }
            .width(132)
            .height(132)
            .backgroundColor(AppColors.SURFACE_ELEVATED)
            .borderRadius(34)
            .clip(true)
            .opacity(this.brandOpacity)

            Column({ space: 4 }) {
              Text('见野')
                .fontSize(22)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppColors.TEXT_PRIMARY)
              Text('在城市里，遇见植物')
                .fontSize(13)
                .fontColor(AppColors.TEXT_SECONDARY)
            }
            .alignItems(HorizontalAlign.Center)
            .opacity(this.brandOpacity)
          }
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.PAPER)
        .opacity(this.splashOpacity)
      }
    }
    .width('100%')
    .height('100%')
  }
}
