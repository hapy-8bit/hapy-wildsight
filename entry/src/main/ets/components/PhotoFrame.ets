import { AppColors } from '../constants/AppColors';
import { AppDimensions } from '../constants/AppDimensions';
import { AppSpacing } from '../constants/AppSpacing';

/** A photograph-first frame. Observation codes are quiet metadata, never badges. */
@Component
export struct PhotoFrame {
  @Prop uri: string = '';
  @Prop observationCode: string = '';
  @Prop frameHeight: number = 260;
  @Prop observationMode: boolean = false;

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Image(this.uri)
        .width('100%')
        .height(this.frameHeight)
        .objectFit(ImageFit.Cover)
        .grayscale(this.observationMode ? 1 : 0)
        .backgroundColor(AppColors.PHOTO_FALLBACK)

      if (this.observationCode.length > 0) {
        Text(this.observationCode)
          .fontSize(10)
          .fontColor(AppColors.WHITE)
          .fontFamily('monospace')
          .letterSpacing(0.8)
          .margin({ left: AppSpacing.SM, bottom: AppSpacing.SM })
          .backgroundColor(AppColors.PHOTO_OVERLAY)
          .padding({ left: AppSpacing.XS, right: AppSpacing.XS, top: AppSpacing.XXS, bottom: AppSpacing.XXS })
      }
    }
    .width('100%')
    .borderRadius(AppDimensions.RADIUS_SUBTLE)
    .clip(true)
  }
}
