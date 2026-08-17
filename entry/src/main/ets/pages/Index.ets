import { WildSightApp } from '../App';
import { AppColors } from '../constants/AppColors';

@Entry
@Component
struct Index {
  @State private splashVisible: boolean = true;
  @State private splashOpacity: number = 1;
  @State private wordmarkOpacity: number = 0;

  private playSplash(): void {
    // Keep the native system transition intact; this short app-owned layer is text only.
    animateTo({ duration: 150, curve: Curve.EaseOut }, () => {
      this.wordmarkOpacity = 1;
    });
    setTimeout((): void => {
      animateTo({ duration: 190, curve: Curve.EaseInOut }, () => {
        this.splashOpacity = 0;
      });
    }, 170);
    setTimeout((): void => {
      this.splashVisible = false;
    }, 390);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      WildSightApp()
      if (this.splashVisible) {
        Stack({ alignContent: Alignment.Center }) {
          Column({ space: 12 }) {
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
            .opacity(this.wordmarkOpacity)
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
    .onAppear((): void => this.playSplash())
  }
}
