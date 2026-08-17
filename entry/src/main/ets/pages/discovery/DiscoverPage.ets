import { AppColors } from '../../constants/AppColors';
import { AppDimensions } from '../../constants/AppDimensions';
import { AppSpacing } from '../../constants/AppSpacing';
import { AppTypography } from '../../constants/AppTypography';
import { PageTitle } from '../../components/PageTitle';
import { PhotoFrame } from '../../components/PhotoFrame';
import { SectionHeading } from '../../components/SectionHeading';
import { Discovery } from '../../models/Discovery';
import { AppRoute } from '../../models/AppRoute';
import { Species } from '../../models/Species';
import { DateFormatter } from '../../utils/DateFormatter';

@Component
export struct DiscoverPage {
  @Prop heroPhotoUri: string = '';
  @Prop species: Species[] = [];
  @Prop recentDiscoveries: Discovery[] = [];
  @Prop notice: string = '';
  @BuilderParam onPickFromAlbum: () => void;
  @BuilderParam onTakePhoto: () => void;
  @BuilderParam onNavigate: (route: AppRoute) => void;
  @BuilderParam onOpenSpecies: (speciesId: string) => void;

  private speciesName(speciesId: string): string {
    return this.species.find((species: Species) => species.id === speciesId)?.chineseName ?? '待确认植物';
  }

  build() {
    Scroll() {
      Column({ space: AppDimensions.MAIN_TITLE_CONTENT_GAP }) {
        PageTitle({ title: '发现', subtitle: '遇见一株植物，把它记下来。' })
        Column({ space: AppSpacing.MD }) {
          if (this.heroPhotoUri.length > 0) {
            PhotoFrame({ uri: this.heroPhotoUri, frameHeight: 300 })
          } else {
            Column({ space: AppSpacing.SM }) {
              Text('从一次相遇开始')
                .fontSize(AppTypography.SECTION_TITLE_SIZE)
                .fontFamily(AppTypography.DISPLAY_FONT)
                .fontColor(AppColors.INK)
              Text('选择一张植物照片，或现场拍一张，开始建立自己的图鉴。')
                .fontSize(AppTypography.BODY_SIZE)
                .fontColor(AppColors.INK_MUTED)
                .lineHeight(24)
            }
            .width('100%')
            .padding(AppSpacing.XL)
            .backgroundColor(AppColors.SURFACE_PRIMARY)
            .border({ width: AppDimensions.HAIRLINE, color: AppColors.BORDER_SOFT })
            .borderRadius(AppDimensions.RADIUS_LARGE)
            .alignItems(HorizontalAlign.Start)
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
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')

        Column() {
          SectionHeading({ label: '最近发现', action: '查看图鉴', onAction: () => this.onNavigate(AppRoute.ATLAS) })
          if (this.recentDiscoveries.length === 0) {
            Text('第一条自然记录，等待被你带回。')
              .fontSize(AppTypography.BODY_SIZE)
              .fontColor(AppColors.INK_MUTED)
              .padding({ top: AppSpacing.SM, bottom: AppSpacing.LG })
          } else {
            ForEach(this.recentDiscoveries.slice(0, 3), (discovery: Discovery) => {
              Row({ space: AppSpacing.SM }) {
                Image(discovery.photoUri)
                  .width(88)
                  .height(88)
                  .objectFit(ImageFit.Cover)
                  .backgroundColor(AppColors.PHOTO_FALLBACK)
                  .borderRadius(AppDimensions.RADIUS_SUBTLE)
                Column({ space: AppSpacing.XXS }) {
                  Text(this.speciesName(discovery.speciesId))
                    .fontSize(17)
                    .fontColor(AppColors.INK)
                  Text(discovery.locationName.length > 0
                    ? `${DateFormatter.short(discovery.discoveredAt)} · ${discovery.locationName}`
                    : DateFormatter.short(discovery.discoveredAt))
                    .fontSize(AppTypography.META_SIZE)
                    .fontColor(AppColors.INK_MUTED)
                  Text(discovery.observationCode)
                    .fontSize(AppTypography.CAPTION_SIZE)
                    .fontFamily(AppTypography.MONO_FONT)
                    .fontColor(AppColors.OBSERVATION)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')
              .padding({ top: AppSpacing.SM, bottom: AppSpacing.MD })
              .border({ width: { bottom: AppDimensions.HAIRLINE }, color: AppColors.DIVIDER })
              .onClick(() => this.onOpenSpecies(discovery.speciesId))
            }, (discovery: Discovery) => discovery.id)
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

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
