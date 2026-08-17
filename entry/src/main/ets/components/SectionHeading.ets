import { AppColors } from '../constants/AppColors';
import { AppSpacing } from '../constants/AppSpacing';

@Component
export struct SectionHeading {
  @Prop label: string = '';
  @Prop action: string = '';
  @BuilderParam onAction: () => void;

  build() {
    Row() {
      Text(this.label.toUpperCase())
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.INK_MUTED)
        .letterSpacing(1.2)
      Blank()
      if (this.action.length > 0) {
        Text(this.action)
          .fontSize(12)
          .fontColor(AppColors.INK)
          .onClick(() => this.onAction())
      }
    }
    .width('100%')
    .margin({ bottom: AppSpacing.SM })
  }
}
