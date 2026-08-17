import { AppColors } from '../constants/AppColors';
import { AppDimensions } from '../constants/AppDimensions';
import { AppSpacing } from '../constants/AppSpacing';
import { AppTypography } from '../constants/AppTypography';

/**
 * Shared secondary-page title bar.
 *
 * It follows the HarmonyOS secondary-page pattern while keeping the app's
 * existing in-process route model: a safe-area-aware fixed header, a large
 * leading title, and a circular back affordance. The title-bar surface is
 * always opaque; scrolling only adds hierarchy through a light shadow.
 */
@Component
export struct SecondaryPageHeader {
  @Prop title: string = '';
  @Prop scrollOffset: number = 0;
  @BuilderParam onBack: () => void;

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.PAPER)
        .border({ width: { bottom: AppDimensions.HAIRLINE }, color: AppColors.BORDER_SOFT })

      Row({ space: AppSpacing.MD }) {
        Button() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(27)
            .fontColor([AppColors.TEXT_PRIMARY])
        }
        .width(48)
        .height(48)
        .padding(0)
        .backgroundColor(AppColors.SURFACE_ELEVATED)
        .border({ width: AppDimensions.HAIRLINE, color: AppColors.BORDER_SOFT })
        .borderRadius(24)
        .stateEffect(true)
        .stateStyles({ pressed: { opacity: 0.62 } })
        .onClick(() => this.onBack())
        .accessibilityText('返回')

        Text(this.title)
          .fontSize(30)
          .fontFamily(AppTypography.PAGE_TITLE_FONT)
          .fontWeight(AppTypography.PAGE_TITLE_WEIGHT)
          .fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }
      .width('100%')
      .height(48)
      .padding({ left: AppDimensions.PAGE_HORIZONTAL, right: AppDimensions.PAGE_HORIZONTAL })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(AppDimensions.SECONDARY_PAGE_HEADER_HEIGHT)
    .shadow(this.scrollOffset > 1 ? {
      radius: 8,
      color: AppColors.CARD_SHADOW,
      offsetY: 2
    } : {
      radius: 0,
      color: '#00000000',
      offsetY: 0
    })
  }
}
