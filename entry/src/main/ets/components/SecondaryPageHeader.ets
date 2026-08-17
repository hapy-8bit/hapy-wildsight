import { AppColors } from '../constants/AppColors';
import { AppDimensions } from '../constants/AppDimensions';
import { AppTypography } from '../constants/AppTypography';

/**
 * Shared secondary-page title bar.
 *
 * Its control sizes and typography mirror MingHOS SettingsDetailHeader.
 * Pages place this fixed row above an independent scrolling content region.
 */
@Component
export struct SecondaryPageHeader {
  @Prop title: string = '';
  @BuilderParam onBack: () => void;

  build() {
    Row({ space: AppDimensions.SECONDARY_PAGE_BACK_TITLE_GAP }) {
        Button() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(23)
            .fontColor([AppColors.TEXT_PRIMARY])
        }
        .width(AppDimensions.SECONDARY_PAGE_BACK_SIZE)
        .height(AppDimensions.SECONDARY_PAGE_BACK_SIZE)
        .padding(0)
        .backgroundColor(AppColors.SURFACE_ELEVATED)
        .borderRadius(AppDimensions.SECONDARY_PAGE_BACK_SIZE / 2)
        .stateEffect(true)
        .onClick(() => this.onBack())
        .accessibilityText('返回')

        Text(this.title)
          .fontSize(AppTypography.SECONDARY_PAGE_TITLE_SIZE)
          .fontWeight(AppTypography.SECONDARY_PAGE_TITLE_WEIGHT)
          .fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
    }
    .width('100%')
    .height(AppDimensions.SECONDARY_PAGE_HEADER_HEIGHT)
    .padding({
      left: AppDimensions.SECONDARY_PAGE_HEADER_HORIZONTAL,
      right: AppDimensions.SECONDARY_PAGE_HEADER_HORIZONTAL
    })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(AppColors.PAPER)
  }
}
