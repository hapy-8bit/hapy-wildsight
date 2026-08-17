import { AppColors } from '../../constants/AppColors';
import { AppDimensions } from '../../constants/AppDimensions';
import { AppSpacing } from '../../constants/AppSpacing';
import { AppTypography } from '../../constants/AppTypography';
import { PageTitle } from '../../components/PageTitle';

@Component
export struct DiscoverPage {
  @Prop heroPhotoUri: string = '';
  @Prop notice: string = '';
  @BuilderParam onPickFromAlbum: () => void;
  @BuilderParam onTakePhoto: () => void;

  build() {
    Scroll() {
      Column({ space: AppDimensions.MAIN_TITLE_CONTENT_GAP }) {
        PageTitle({ title: '发现', subtitle: '遇见一株植物，把它记下来。' })
        Column({ space: AppSpacing.MD }) {
          if (this.heroPhotoUri.length > 0) {
            Stack({ alignContent: Alignment.Center }) {
              Image(this.heroPhotoUri)
                .width('100%')
                .height('100%')
                .objectFit(ImageFit.Cover)
                .backgroundColor(AppColors.PHOTO_FALLBACK)
            }
            .width('100%')
            .aspectRatio(1)
            .borderRadius(AppDimensions.RADIUS_LARGE)
            .clip(true)
            .onClick(() => this.onTakePhoto())
          } else {
            Stack({ alignContent: Alignment.Center }) {
              Column({ space: AppSpacing.SM }) {
                SymbolGlyph($r('sys.symbol.camera'))
                  .fontSize(34)
                  .fontColor([AppColors.BRAND_GREEN])
                Text('从一次相遇开始')
                  .fontSize(AppTypography.SECTION_TITLE_SIZE)
                  .fontFamily(AppTypography.DISPLAY_FONT)
                  .fontColor(AppColors.INK)
                Text('点击拍照，记录眼前的植物。')
                  .fontSize(AppTypography.BODY_SIZE)
                  .fontColor(AppColors.INK_MUTED)
                  .lineHeight(24)
              }
              .alignItems(HorizontalAlign.Center)
            }
            .width('100%')
            .aspectRatio(1)
            .backgroundColor(AppColors.SURFACE_PRIMARY)
            .border({ width: AppDimensions.HAIRLINE, color: AppColors.BORDER_SOFT })
            .borderRadius(AppDimensions.RADIUS_LARGE)
            .onClick(() => this.onTakePhoto())
          }
          Column({ space: AppSpacing.XS }) {
            Text('拍照发现')
              .fontSize(AppTypography.SECTION_TITLE_SIZE)
              .fontFamily(AppTypography.DISPLAY_FONT)
              .fontColor(AppColors.INK)
            Text('把此刻遇见的自然，收进自己的图鉴。')
              .fontSize(AppTypography.BODY_SIZE)
              .fontColor(AppColors.INK_MUTED)
            this.identificationButton('从相册识别', () => this.onPickFromAlbum(), true)
            this.identificationButton('拍照识别', () => this.onTakePhoto(), false)
            if (this.notice.length > 0) {
              Text(this.notice)
                .width('100%')
                .fontSize(AppTypography.META_SIZE)
                .lineHeight(18)
                .fontColor(AppColors.INK_MUTED)
            }

            GuidanceCard()
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')

        Column({ space: AppSpacing.XS }) {
          Text('你的图鉴正在形成')
            .fontSize(AppTypography.SECTION_TITLE_SIZE)
            .fontFamily(AppTypography.DISPLAY_FONT)
            .fontColor(AppColors.INK)
          Text('每一次相遇，都会成为一页只属于你的自然档案。')
            .fontSize(AppTypography.BODY_SIZE)
            .fontColor(AppColors.INK_MUTED)
            .lineHeight(24)
        }
        .width('100%')
        .padding({ top: AppSpacing.LG, bottom: AppSpacing.LG })
        .border({ width: { top: AppDimensions.HAIRLINE, bottom: AppDimensions.HAIRLINE }, color: AppColors.DIVIDER })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: AppDimensions.PAGE_HORIZONTAL, right: AppDimensions.PAGE_HORIZONTAL, bottom: AppDimensions.PRIMARY_TABS_CONTENT_INSET })
      .constraintSize({ maxWidth: AppDimensions.CONTENT_MAX_WIDTH })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.PAPER)
  }

  @Builder
  private identificationButton(label: string, onClick: () => void, primary: boolean): void {
    Button(label)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .fontColor(primary ? AppColors.ACTION_ON_PRIMARY : AppColors.INK)
      .width('100%')
      .height(48)
      .backgroundColor(primary ? AppColors.ACTION_PRIMARY : AppColors.BRAND_GREEN_SOFT)
      .border({ width: AppDimensions.HAIRLINE, color: AppColors.BORDER_SOFT })
      .borderRadius(AppDimensions.RADIUS_SUBTLE)
      .onClick(onClick)
  }
}

@Component
struct GuidanceCard {
  build() {
    Row({ space: AppSpacing.SM }) {
      SymbolGlyph($r('sys.symbol.camera'))
        .fontSize(17)
        .fontColor([AppColors.BRAND_GREEN])
        .padding(AppSpacing.SM)
        .backgroundColor(AppColors.BRAND_GREEN_SOFT)
        .borderRadius(18)
      Column({ space: AppSpacing.XXS }) {
        Text('识别更准确的小建议')
          .fontSize(AppTypography.BODY_SIZE)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text('尽量拍清叶片、花朵或整体形态。')
          .fontSize(AppTypography.META_SIZE)
          .fontColor(AppColors.TEXT_SECONDARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(AppSpacing.MD)
    .backgroundColor(AppColors.BACKGROUND_SECONDARY)
    .border({ width: AppDimensions.HAIRLINE, color: AppColors.BORDER_SOFT })
    .borderRadius(AppDimensions.RADIUS_LARGE)
  }
}
