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
      Row() {
        Text(this.title)
          .fontSize(AppTypography.SECONDARY_PAGE_TITLE_SIZE)
          .fontWeight(AppTypography.SECONDARY_PAGE_TITLE_WEIGHT)
          .fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .height(AppDimensions.MAIN_TITLE_ROW_HEIGHT)
      .alignItems(VerticalAlign.Center)

      if (this.subtitle.length > 0) {
        Text(this.subtitle)
          .width('100%')
          .fontSize(AppTypography.PAGE_TITLE_SUBTITLE_SIZE)
          .fontColor(AppColors.TEXT_SECONDARY)
          .lineHeight(AppTypography.PAGE_TITLE_SUBTITLE_LINE_HEIGHT)
      }
    }
    .width('100%')
    .height(AppDimensions.MAIN_TITLE_BLOCK_HEIGHT)
    .alignItems(HorizontalAlign.Start)
  }
}
