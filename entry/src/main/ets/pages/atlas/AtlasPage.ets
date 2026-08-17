import { AppColors } from '../../constants/AppColors';
import { AppDimensions } from '../../constants/AppDimensions';
import { AppSpacing } from '../../constants/AppSpacing';
import { AppTypography } from '../../constants/AppTypography';
import { PageTitle } from '../../components/PageTitle';
import { Discovery, DiscoverySummary } from '../../models/Discovery';
import { Species } from '../../models/Species';
import { DateFormatter } from '../../utils/DateFormatter';

@Component
export struct AtlasPage {
  @Prop species: Species[] = [];
  @Prop summaries: DiscoverySummary[] = [];
  @BuilderParam onOpenSpecies: (speciesId: string) => void;
  @BuilderParam onOpenAll: () => void;

  private orderedSummaries(): DiscoverySummary[] {
    return this.summaries.slice().sort((left: DiscoverySummary, right: DiscoverySummary) => {
      const leftTime = left.latestDiscovery === undefined ? 0 : left.latestDiscovery.discoveredAt.getTime();
      const rightTime = right.latestDiscovery === undefined ? 0 : right.latestDiscovery.discoveredAt.getTime();
      return rightTime - leftTime;
    });
  }

  private recentSummaries(): DiscoverySummary[] {
    return this.orderedSummaries().slice(0, 3);
  }

  private speciesFor(summary: DiscoverySummary): Species {
    return this.species.find((item: Species) => item.id === summary.speciesId) ?? new Species();
  }

  build() {
    Scroll() {
      Column({ space: AppDimensions.MAIN_TITLE_CONTENT_GAP }) {
        PageTitle({ title: '图鉴', subtitle: '去遇见，也去记住每一株植物。' })
        Row() {
          Text('最近相遇')
            .fontSize(AppTypography.SECTION_TITLE_SIZE)
            .fontFamily(AppTypography.DISPLAY_FONT)
            .fontColor(AppColors.TEXT_PRIMARY)
          Text('累计 ' + this.summaries.reduce((total: number, summary: DiscoverySummary) => total + summary.encounterCount, 0) + ' 次')
            .fontSize(AppTypography.META_SIZE)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_SECONDARY)
            .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: 5, bottom: 5 })
            .backgroundColor(AppColors.SURFACE_ELEVATED)
            .border({ width: AppDimensions.HAIRLINE, color: AppColors.BORDER_SOFT })
            .borderRadius(16)
            .margin({ left: AppSpacing.SM })
          Blank()
          Text('查看全部')
            .fontSize(AppTypography.META_SIZE)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.BRAND_GREEN)
            .padding({ left: AppSpacing.SM, top: AppSpacing.XS, bottom: AppSpacing.XS })
            .stateStyles({ pressed: { opacity: 0.66 } })
            .onClick(() => this.onOpenAll())
        }
        .width('100%')

        if (this.summaries.length === 0) {
          Column({ space: AppSpacing.SM }) {
            Text('你的第一页图鉴，等待一次相遇。')
              .fontSize(AppTypography.SECTION_TITLE_SIZE)
              .fontFamily(AppTypography.DISPLAY_FONT)
              .fontColor(AppColors.TEXT_PRIMARY)
            Text('去发现一株植物，让它成为这座小小自然博物馆的开端。')
              .fontSize(AppTypography.BODY_SIZE)
              .fontColor(AppColors.TEXT_SECONDARY)
              .lineHeight(24)
          }
          .width('100%')
          .padding(AppSpacing.XL)
          .backgroundColor(AppColors.SURFACE_PRIMARY)
          .borderRadius(AppDimensions.RADIUS_LARGE)
          .alignItems(HorizontalAlign.Start)
        } else {
          Column({ space: AppSpacing.SM }) {
            ForEach(this.recentSummaries(), (summary: DiscoverySummary) => {
              RecentEncounterCard({
                species: this.speciesFor(summary),
                summary: summary,
                onOpen: (speciesId: string) => this.onOpenSpecies(speciesId)
              })
            }, (summary: DiscoverySummary) => summary.speciesId)
          }
          .width('100%')
        }

        GuidanceCard()
      }
      .width('100%')
      .padding({
        left: AppDimensions.PAGE_HORIZONTAL,
        right: AppDimensions.PAGE_HORIZONTAL,
        bottom: AppDimensions.PRIMARY_TABS_CONTENT_INSET
      })
      .constraintSize({ maxWidth: AppDimensions.CONTENT_MAX_WIDTH })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.BACKGROUND_PRIMARY)
  }
}

@Component
struct RecentEncounterCard {
  @Prop species: Species = new Species();
  @Prop summary: DiscoverySummary = new DiscoverySummary();
  @BuilderParam onOpen: (speciesId: string) => void;

  private latest(): Discovery {
    return this.summary.latestDiscovery ?? new Discovery();
  }

  private supportingText(): string {
    const description = this.cleanDescription();
    if (description.length > 0) {
      return description;
    }
    return '物种简介待补充，已保存这次相遇。';
  }

  private cleanDescription(): string {
    let description = this.species.description.trim();
    if (this.species.chineseName.length > 0 && description.startsWith(this.species.chineseName)) {
      description = description.substring(this.species.chineseName.length).trim();
    }
    if (this.species.scientificName.length > 0) {
      description = description.replace(this.species.scientificName, '').trim();
    }
    return description.replace(/^[-—:：，,。\s]+/, '').trim();
  }

  build() {
    Row({ space: AppSpacing.MD }) {
      Image(this.latest().photoUri.length > 0 ? this.latest().photoUri : this.species.coverPhotoUri)
        .width(92)
        .height(92)
        .objectFit(ImageFit.Cover)
        .backgroundColor(AppColors.PHOTO_FALLBACK)
        .borderRadius(AppDimensions.RADIUS_MEDIUM)
      Column({ space: AppSpacing.XS }) {
        Row() {
          Text(this.species.chineseName)
          .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Blank()
        }
        .width('100%')
        Text(this.supportingText())
          .fontSize(AppTypography.META_SIZE)
          .fontColor(AppColors.TEXT_SECONDARY)
          .lineHeight(17)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row() {
          Text('相遇 ' + this.summary.encounterCount + ' 次')
            .fontSize(AppTypography.META_SIZE)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.BRAND_GREEN)
          Blank()
          Text(DateFormatter.monthAndDay(this.latest().discoveredAt))
            .fontSize(AppTypography.META_SIZE)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(AppSpacing.SM)
    .backgroundColor(AppColors.SURFACE_ELEVATED)
    .border({ width: AppDimensions.HAIRLINE, color: AppColors.BORDER_SOFT })
    .borderRadius(AppDimensions.RADIUS_LARGE)
    .shadow({ radius: 5, color: AppColors.CARD_SHADOW, offsetY: 2 })
    .stateStyles({ pressed: { opacity: 0.88 } })
    .onClick(() => this.onOpen(this.species.id))
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
