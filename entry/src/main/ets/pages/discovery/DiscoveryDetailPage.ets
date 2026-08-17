import { AppColors } from '../../constants/AppColors';
import { AppDimensions } from '../../constants/AppDimensions';
import { AppSpacing } from '../../constants/AppSpacing';
import { AppTypography } from '../../constants/AppTypography';
import { ObservationCode } from '../../components/ObservationCode';
import { PhotoFrame } from '../../components/PhotoFrame';
import { Discovery } from '../../models/Discovery';
import { Species } from '../../models/Species';
import { DateFormatter } from '../../utils/DateFormatter';

@Component
export struct DiscoveryDetailPage {
  @Prop discovery: Discovery = new Discovery();
  @Prop species: Species = new Species();
  @BuilderParam onBack: () => void;

  private taxonomyLine(): string {
    const parts: string[] = [];
    if (this.species.family.length > 0) {
      parts.push(this.species.family);
    }
    if (this.species.genus.length > 0) {
      parts.push(this.species.genus);
    }
    return parts.join(' · ');
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.XL }) {
        Row() {
          Text('‹ 返回')
            .fontSize(14)
            .fontColor(AppColors.INK_MUTED)
            .onClick(() => this.onBack())
          Blank()
          ObservationCode({ code: this.discovery.observationCode })
        }
        .width('100%')

        Column({ space: AppSpacing.XS }) {
          Text('这一次相遇')
            .fontSize(AppTypography.HERO_SIZE)
            .fontFamily(AppTypography.DISPLAY_FONT)
            .fontColor(AppColors.INK)
          Text('留在你个人自然档案中的一页。')
            .fontSize(AppTypography.BODY_SIZE)
            .fontColor(AppColors.INK_MUTED)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        PhotoFrame({ uri: this.discovery.photoUri, observationCode: this.discovery.observationCode, frameHeight: 360 })

        Column({ space: AppSpacing.XXS }) {
          Text(this.species.chineseName)
            .fontSize(30)
            .fontFamily(AppTypography.DISPLAY_FONT)
            .fontColor(AppColors.INK)
          if (this.species.scientificName.length > 0) {
            Text(this.species.scientificName)
              .fontSize(15)
              .fontStyle(FontStyle.Italic)
              .fontColor(AppColors.INK_MUTED)
          }
          if (this.taxonomyLine().length > 0) {
            Text(this.taxonomyLine())
              .fontSize(AppTypography.META_SIZE)
              .fontColor(AppColors.INK_MUTED)
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: AppSpacing.MD }) {
          DiscoveryMeta({ label: '发现时间', value: `${DateFormatter.short(this.discovery.discoveredAt)} · ${DateFormatter.time(this.discovery.discoveredAt)}` })
          if (this.discovery.locationName.length > 0) {
            DiscoveryMeta({ label: '发现地点', value: this.discovery.locationName })
          }
          DiscoveryMeta({ label: '识别可信度', value: `${Math.round(this.discovery.confidence * 100)}% 匹配` })
        }
        .width('100%')
        .padding({ top: AppSpacing.LG, bottom: AppSpacing.LG })
        .border({ width: { top: AppDimensions.HAIRLINE, bottom: AppDimensions.HAIRLINE }, color: AppColors.DIVIDER })

        Column({ space: AppSpacing.XS }) {
          Text('我的备注')
            .fontSize(11)
            .letterSpacing(1)
            .fontColor(AppColors.INK_MUTED)
          Text(this.discovery.note.length > 0 ? this.discovery.note : '尚未写下备注。')
            .fontSize(AppTypography.BODY_SIZE)
            .fontColor(this.discovery.note.length > 0 ? AppColors.INK : AppColors.INK_MUTED)
            .lineHeight(25)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Text('天气、经纬度与地图将在后续版本补充。')
          .fontSize(AppTypography.CAPTION_SIZE)
          .fontColor(AppColors.INK_MUTED)
          .width('100%')
          .padding({ top: AppSpacing.MD, bottom: AppSpacing.LG })
      }
      .width('100%')
      .padding({ left: AppDimensions.PAGE_HORIZONTAL, right: AppDimensions.PAGE_HORIZONTAL, top: AppSpacing.LG, bottom: AppSpacing.XXL })
      .constraintSize({ maxWidth: AppDimensions.CONTENT_MAX_WIDTH })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.PAPER)
  }
}

@Component
struct DiscoveryMeta {
  @Prop label: string = '';
  @Prop value: string = '';

  build() {
    Row() {
      Text(this.label)
        .fontSize(AppTypography.META_SIZE)
        .fontColor(AppColors.INK_MUTED)
      Blank()
      Text(this.value)
        .fontSize(AppTypography.BODY_SIZE)
        .fontColor(AppColors.INK)
    }
    .width('100%')
  }
}
