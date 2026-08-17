import { AppColors } from '../constants/AppColors';
import { AppDimensions } from '../constants/AppDimensions';
import { AppTypography } from '../constants/AppTypography';

/** Shared title treatment for the three primary tabs. */
@Component
export struct PageTitle {
  @Prop title: string = '';
  @Prop subtitle: string = '';

  build() {
    Column({ space: AppDimensions.MAIN_TITLE_SUBTITLE_GAP }) {
      Text(this.title)
        .fontSize(AppTypography.PAGE_TITLE_SIZE)
        .fontFamily(AppTypography.PAGE_TITLE_FONT)
        .fontWeight(AppTypography.PAGE_TITLE_WEIGHT)
        .fontColor(AppColors.TEXT_PRIMARY)
        .lineHeight(AppTypography.PAGE_TITLE_LINE_HEIGHT)
      if (this.subtitle.length > 0) {
        Text(this.subtitle)
          .fontSize(AppTypography.PAGE_TITLE_SUBTITLE_SIZE)
          .fontColor(AppColors.TEXT_SECONDARY)
          .lineHeight(AppTypography.PAGE_TITLE_SUBTITLE_LINE_HEIGHT)
      }
    }
    .width('100%')
    .padding({ top: AppDimensions.MAIN_TITLE_TOP_INSET })
    .alignItems(HorizontalAlign.Start)
  }
}
