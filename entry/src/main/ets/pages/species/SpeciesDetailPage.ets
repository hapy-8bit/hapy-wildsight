import { AppColors } from '../../constants/AppColors';
import { AppDimensions } from '../../constants/AppDimensions';
import { AppSpacing } from '../../constants/AppSpacing';
import { AppTypography } from '../../constants/AppTypography';
import { ObservationCode } from '../../components/ObservationCode';
import { SecondaryPageHeader } from '../../components/SecondaryPageHeader';
import { Discovery } from '../../models/Discovery';
import { Species } from '../../models/Species';
import { DateFormatter } from '../../utils/DateFormatter';

/** A photograph-first species page. Knowledge fields are optional after remote identification. */
@Component
export struct SpeciesDetailPage {
  @Prop species: Species = new Species();
  @Prop discoveries: Discovery[] = [];
  @BuilderParam onBack: () => void;
  @BuilderParam onOpenDiscovery: (discoveryId: string) => void;
  @BuilderParam onRefreshKnowledge: () => void;
  @State scrollOffset: number = 0;

  aboutToAppear(): void { this.onRefreshKnowledge(); }

  private heroUri(): string {
    return this.discoveries.length > 0 ? this.discoveries[0].photoUri : this.species.coverPhotoUri;
  }

  private latest(): Discovery {
    return this.discoveries.length > 0 ? this.discoveries[0] : new Discovery();
  }

  private first(): Discovery {
    return this.discoveries.length > 0 ? this.discoveries[this.discoveries.length - 1] : new Discovery();
  }

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

  private hasReferenceInfo(): boolean {
    return this.species.scientificName.length > 0 || this.taxonomyLine().length > 0 ||
      this.species.distribution.length > 0 || this.species.floweringPeriod.length > 0 ||
      this.species.features.length > 0;
  }

  private encounterDate(): string {
    const latest = this.latest();
    return latest.id.length > 0 ? DateFormatter.monthAndDay(latest.discoveredAt) : '';
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Scroll() {
        Column({ space: AppSpacing.XL }) {
          Image(this.heroUri())
            .width('100%')
            .height(336)
            .objectFit(ImageFit.Cover)
            .backgroundColor(AppColors.PHOTO_FALLBACK)
            .borderRadius(AppDimensions.RADIUS_HERO)

          SpeciesLeadCard({
            species: this.species,
            taxonomy: this.taxonomyLine(),
            encounterDate: this.encounterDate(),
            confidence: this.latest().confidence
          })

          if (this.discoveries.length > 0) {
            EncounterOverview({
              first: this.first(),
              latest: this.latest(),
              encounterCount: this.discoveries.length
            })
          }

          SpeciesKnowledge({ species: this.species })

          if (this.discoveries.length > 0) {
            Column({ space: AppSpacing.MD }) {
              Text('相遇记录')
                .fontSize(AppTypography.SECTION_TITLE_SIZE)
                .fontFamily(AppTypography.DISPLAY_FONT)
                .fontColor(AppColors.INK)
              Text('每一次看见，都是这株植物留在你图鉴里的证据。')
                .fontSize(AppTypography.META_SIZE)
                .fontColor(AppColors.INK_MUTED)
              ForEach(this.discoveries, (discovery: Discovery) => {
                EncounterRecord({
                  discovery: discovery,
                  onOpen: (discoveryId: string) => this.onOpenDiscovery(discoveryId)
                })
              }, (discovery: Discovery) => discovery.id)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
        }
        .width('100%')
          .padding({
            left: AppDimensions.PAGE_HORIZONTAL,
            right: AppDimensions.PAGE_HORIZONTAL,
            top: AppDimensions.SECONDARY_PAGE_CONTENT_TOP_INSET,
            bottom: AppSpacing.XXXL
        })
        .constraintSize({ maxWidth: AppDimensions.CONTENT_MAX_WIDTH })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .onScroll((_xOffset: number, yOffset: number) => {
        this.scrollOffset = Math.max(0, yOffset);
      })

      SecondaryPageHeader({
        title: this.species.chineseName.length > 0 ? this.species.chineseName : '物种详情',
        scrollOffset: this.scrollOffset,
        onBack: () => this.onBack()
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.PAPER)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}

@Component
struct SpeciesLeadCard {
  @Prop species: Species = new Species();
  @Prop taxonomy: string = '';
  @Prop encounterDate: string = '';
  @Prop confidence: number = 0;

  build() {
    Column({ space: AppSpacing.SM }) {
      Text(this.species.chineseName.length > 0 ? this.species.chineseName : '待确认植物')
        .fontSize(31)
        .fontFamily(AppTypography.DISPLAY_FONT)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.INK)
      Row() {
        Text(this.taxonomy)
          .fontSize(AppTypography.META_SIZE)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.MOSS)
        Blank()
        if (this.encounterDate.length > 0) {
          Text(this.encounterDate)
            .fontSize(AppTypography.META_SIZE)
            .fontColor(AppColors.INK_MUTED)
        }
      }
      .width('100%')
      if (this.species.scientificName.length > 0) {
        Text(this.species.scientificName)
          .fontSize(15)
          .fontStyle(FontStyle.Italic)
          .fontColor(AppColors.INK_MUTED)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      if (this.species.description.trim().length > 0) {
        Text(this.species.description)
          .fontSize(AppTypography.BODY_SIZE)
          .fontColor(AppColors.INK_MUTED)
          .lineHeight(24)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      } else {
        Text('已收录这次相遇；可靠的物种简介仍待补充。')
          .fontSize(AppTypography.BODY_SIZE)
          .fontColor(AppColors.INK_MUTED)
          .lineHeight(24)
      }
    }
    .width('100%')
    .padding(AppSpacing.LG)
    .backgroundColor(AppColors.SURFACE_ELEVATED)
    .border({ width: AppDimensions.HAIRLINE, color: AppColors.BORDER_SOFT })
    .borderRadius(AppDimensions.RADIUS_HERO)
    .shadow({ radius: 7, color: AppColors.CARD_SHADOW, offsetY: 3 })
    .alignItems(HorizontalAlign.Start)
  }
}

@Component
struct EncounterOverview {
  @Prop first: Discovery = new Discovery();
  @Prop latest: Discovery = new Discovery();
  @Prop encounterCount: number = 0;

  build() {
    Column({ space: AppSpacing.MD }) {
      Row() {
        Column({ space: AppSpacing.XXS }) {
          Text('我的相遇')
            .fontSize(AppTypography.SECTION_TITLE_SIZE)
            .fontFamily(AppTypography.DISPLAY_FONT)
            .fontColor(AppColors.INK)
          Text('我遇见了 ' + this.encounterCount + ' 次')
            .fontSize(AppTypography.BODY_SIZE)
            .fontColor(AppColors.MOSS)
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        ObservationCode({ code: this.latest.observationCode })
      }
      .width('100%')
      Row({ space: AppSpacing.MD }) {
        EncounterStat({ label: '第一次', discovery: this.first })
        EncounterStat({ label: '最近一次', discovery: this.latest })
      }
      .width('100%')
      if (this.latest.locationName.length > 0) {
        Text('最近地点 · ' + this.latest.locationName)
          .fontSize(AppTypography.META_SIZE)
          .fontColor(AppColors.INK_MUTED)
      }
    }
    .width('100%')
    .padding(AppSpacing.LG)
    .backgroundColor(AppColors.BRAND_GREEN_SOFT)
    .borderRadius(AppDimensions.RADIUS_LARGE)
    .alignItems(HorizontalAlign.Start)
  }
}

@Component
struct EncounterStat {
  @Prop label: string = '';
  @Prop discovery: Discovery = new Discovery();

  build() {
    Column({ space: AppSpacing.XXS }) {
      Text(this.label)
        .fontSize(AppTypography.CAPTION_SIZE)
        .fontColor(AppColors.INK_MUTED)
      Text(DateFormatter.short(this.discovery.discoveredAt))
        .fontSize(14)
        .fontColor(AppColors.INK)
      Text(DateFormatter.time(this.discovery.discoveredAt))
        .fontSize(AppTypography.META_SIZE)
        .fontColor(AppColors.INK_MUTED)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }
}

@Component
struct SpeciesKnowledge {
  @Prop species: Species = new Species();

  private source(): Object | undefined {
    if (this.species.knowledgeJson.length === 0) {
      return undefined;
    }
    try {
      return JSON.parse(this.species.knowledgeJson) as Object;
    } catch (_error) {
      return undefined;
    }
  }

  private text(key: string): string {
    const source = this.source();
    if (source === undefined) {
      return '';
    }
    const value: Object = Reflect.get(source, key) as Object;
    return typeof value === 'string' ? value as string : '';
  }

  private lines(key: string): string[] {
    const source = this.source();
    if (source === undefined) {
      return [];
    }
    const value: Object = Reflect.get(source, key) as Object;
    if (!Array.isArray(value)) {
      return [];
    }
    return (value as Object[]).filter((item: Object) => typeof item === 'string').map((item: Object) => item as string);
  }

  private hasAny(values: string[]): boolean {
    return values.length > 0;
  }

  build() {
    Column({ space: AppSpacing.MD }) {
      if (this.source() === undefined) {
        Text('该植物的知识内容暂未维护')
          .fontSize(AppTypography.BODY_SIZE)
          .fontColor(AppColors.INK_MUTED)
          .lineHeight(24)
      } else if (this.text('summary').length > 0 || this.hasAny(this.lines('identificationReferences'))) {
        KnowledgeSection({ title: '怎么认', body: this.text('summary'), items: this.lines('identificationReferences') })
      }
      if (this.hasAny(this.lines('howToConfirm'))) {
        KnowledgeSection({ title: '下次这样确认', items: this.lines('howToConfirm') })
      }
      if (this.text('appearance').length > 0 || this.text('growthHabit').length > 0 || this.hasAny(this.lines('keyCharacteristics')) || this.hasAny(this.lines('observationTips'))) {
        KnowledgeSection({ title: '认识它', body: this.text('appearance'), secondaryBody: this.text('growthHabit'), items: this.lines('keyCharacteristics').concat(this.lines('observationTips')) })
      }
      if (this.hasAny(this.lines('confusableSpecies'))) {
        KnowledgeSection({ title: '容易混淆', items: this.lines('confusableSpecies') })
      }
      if (this.text('observationReminder').length > 0) {
        KnowledgeSection({ title: '观察提醒', body: this.text('observationReminder') })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

@Component
struct KnowledgeSection {
  @Prop title: string = '';
  @Prop body: string = '';
  @Prop secondaryBody: string = '';
  @Prop items: string[] = [];

  build() {
    Column({ space: AppSpacing.SM }) {
      Text(this.title)
        .fontSize(AppTypography.SECTION_TITLE_SIZE)
        .fontFamily(AppTypography.DISPLAY_FONT)
        .fontColor(AppColors.INK)
      if (this.body.length > 0) {
        Text(this.body)
          .fontSize(AppTypography.BODY_SIZE)
          .fontColor(AppColors.INK_MUTED)
          .lineHeight(24)
      }
      if (this.secondaryBody.length > 0) {
        Text(this.secondaryBody)
          .fontSize(AppTypography.BODY_SIZE)
          .fontColor(AppColors.INK_MUTED)
          .lineHeight(24)
      }
      ForEach(this.items, (item: string) => {
        Row({ space: AppSpacing.XS }) {
          Text('•').fontSize(18).fontColor(AppColors.MOSS)
          Text(item)
            .fontSize(AppTypography.BODY_SIZE)
            .fontColor(AppColors.INK_MUTED)
            .lineHeight(23)
            .layoutWeight(1)
        }.width('100%').alignItems(VerticalAlign.Top)
      }, (item: string) => item)
    }
    .width('100%')
    .padding(AppSpacing.MD)
    .backgroundColor(AppColors.BACKGROUND_SECONDARY)
    .border({ width: AppDimensions.HAIRLINE, color: AppColors.BORDER_SOFT })
    .borderRadius(AppDimensions.RADIUS_MEDIUM)
    .alignItems(HorizontalAlign.Start)
  }
}

@Component
struct EncounterRecord {
  @Prop discovery: Discovery = new Discovery();
  @BuilderParam onOpen: (discoveryId: string) => void;

  build() {
    Row({ space: AppSpacing.MD }) {
      Image(this.discovery.photoUri)
        .width(100)
        .height(100)
        .objectFit(ImageFit.Cover)
        .backgroundColor(AppColors.PHOTO_FALLBACK)
        .borderRadius(AppDimensions.RADIUS_MEDIUM)
      Column({ space: AppSpacing.XS }) {
        Text(DateFormatter.short(this.discovery.discoveredAt))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.INK)
        Text(DateFormatter.time(this.discovery.discoveredAt) + (this.discovery.locationName.length > 0 ? ' · ' + this.discovery.locationName : ''))
          .fontSize(AppTypography.META_SIZE)
          .fontColor(AppColors.INK_MUTED)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        ObservationCode({ code: this.discovery.observationCode })
        if (this.discovery.note.length > 0) {
          Text(this.discovery.note)
            .fontSize(AppTypography.META_SIZE)
            .fontColor(AppColors.INK_MUTED)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(AppSpacing.SM)
    .backgroundColor(AppColors.SURFACE_ELEVATED)
    .border({ width: AppDimensions.HAIRLINE, color: AppColors.BORDER_SOFT })
    .borderRadius(AppDimensions.RADIUS_LARGE)
    .stateStyles({ pressed: { opacity: 0.76 } })
    .onClick(() => this.onOpen(this.discovery.id))
  }
}
