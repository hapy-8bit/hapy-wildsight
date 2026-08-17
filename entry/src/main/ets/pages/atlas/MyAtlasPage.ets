import { AppColors } from '../../constants/AppColors';
import { AppDimensions } from '../../constants/AppDimensions';
import { AppSpacing } from '../../constants/AppSpacing';
import { AppTypography } from '../../constants/AppTypography';
import { Discovery, DiscoverySummary } from '../../models/Discovery';
import { Species } from '../../models/Species';
import { DateFormatter } from '../../utils/DateFormatter';

enum AtlasSort {
  RECENT = '最近发现',
  EARLIEST = '最早发现',
  NAME = '名称'
}

@Component
export struct MyAtlasPage {
  @Prop species: Species[] = [];
  @Prop summaries: DiscoverySummary[] = [];
  @BuilderParam onBack: () => void;
  @BuilderParam onOpenSpecies: (speciesId: string) => void;
  @State query: string = '';
  @State sort: AtlasSort = AtlasSort.RECENT;

  private summaryFor(speciesId: string): DiscoverySummary {
    return this.summaries.find((item: DiscoverySummary) => item.speciesId === speciesId) ?? new DiscoverySummary();
  }

  private visibleSpecies(): Species[] {
    const keyword = this.query.trim().toLowerCase();
    const filtered = this.species.filter((item: Species) => {
      return keyword.length === 0 || item.chineseName.toLowerCase().includes(keyword) ||
        item.scientificName.toLowerCase().includes(keyword) ||
        item.aliases.some((alias: string) => alias.toLowerCase().includes(keyword));
    });
    return filtered.sort((left: Species, right: Species) => this.compare(left, right));
  }

  private compare(left: Species, right: Species): number {
    if (this.sort === AtlasSort.NAME) {
      return left.chineseName.localeCompare(right.chineseName);
    }
    const leftSummary = this.summaryFor(left.id);
    const rightSummary = this.summaryFor(right.id);
    const leftDate = this.sort === AtlasSort.RECENT ? leftSummary.latestDiscovery?.discoveredAt : leftSummary.firstDiscovery?.discoveredAt;
    const rightDate = this.sort === AtlasSort.RECENT ? rightSummary.latestDiscovery?.discoveredAt : rightSummary.firstDiscovery?.discoveredAt;
    const delta = (leftDate?.getTime() ?? 0) - (rightDate?.getTime() ?? 0);
    return this.sort === AtlasSort.RECENT ? -delta : delta;
  }

  private dateLabel(date: Date): string {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    const target = new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
    if (target === today) {
      return '今天';
    }
    if (target === today - 24 * 60 * 60 * 1000) {
      return '昨天';
    }
    return DateFormatter.monthAndDay(date);
  }

  private sortMenu(): MenuElement[] {
    return [
      { value: AtlasSort.RECENT, action: () => this.sort = AtlasSort.RECENT },
      { value: AtlasSort.EARLIEST, action: () => this.sort = AtlasSort.EARLIEST },
      { value: AtlasSort.NAME, action: () => this.sort = AtlasSort.NAME }
    ];
  }

  build() {
    Column({ space: AppSpacing.LG }) {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(21)
          .fontColor([AppColors.TEXT_PRIMARY])
          .padding(AppSpacing.XS)
          .stateStyles({ pressed: { opacity: 0.58 } })
          .onClick(() => this.onBack())
        Text('我的图鉴')
          .fontSize(AppTypography.PAGE_TITLE_SIZE)
          .fontFamily(AppTypography.DISPLAY_FONT)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
          .margin({ left: AppSpacing.XS })
        Blank()
      }
      .width('100%')
      .padding({ top: AppSpacing.XXL })

      Search({ value: this.query, placeholder: '搜索植物' })
        .width('100%')
        .height(38)
        .backgroundColor(AppColors.BACKGROUND_SECONDARY)
        .placeholderColor(AppColors.TEXT_TERTIARY)
        .fontColor(AppColors.TEXT_PRIMARY)
        .border({ width: AppDimensions.HAIRLINE, color: AppColors.BORDER_SOFT })
        .borderRadius(14)
        .searchIcon({ src: $r('sys.symbol.search_things'), color: AppColors.TEXT_TERTIARY, size: 16 })
        .onChange((value: string) => this.query = value)

      Row() {
        Row({ space: AppSpacing.XXS }) {
          Text(this.sort)
            .fontSize(AppTypography.META_SIZE)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.BRAND_GREEN)
          SymbolGlyph($r('sys.symbol.chevron_down'))
            .fontSize(12)
            .fontColor([AppColors.BRAND_GREEN])
        }
        .padding({ right: AppSpacing.SM, top: AppSpacing.XS, bottom: AppSpacing.XS })
        .stateStyles({ pressed: { opacity: 0.6 } })
        .bindMenu(this.sortMenu())
        Blank()
        Text(this.visibleSpecies().length + ' 种植物')
          .fontSize(AppTypography.META_SIZE)
          .fontColor(AppColors.TEXT_TERTIARY)
      }
      .width('100%')

      if (this.visibleSpecies().length === 0) {
        Column({ space: AppSpacing.SM }) {
          Text(this.query.length > 0 ? '没有找到这株植物' : '图鉴从一次相遇开始')
            .fontSize(AppTypography.SECTION_TITLE_SIZE)
            .fontFamily(AppTypography.DISPLAY_FONT)
            .fontColor(AppColors.TEXT_PRIMARY)
          Text(this.query.length > 0 ? '试试植物的别名或学名。' : '去发现一株植物，把它收进自己的图鉴。')
            .fontSize(AppTypography.BODY_SIZE)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
        .width('100%')
        .padding({ top: AppSpacing.XL })
        .alignItems(HorizontalAlign.Start)
      } else {
        List({ space: 0 }) {
          ForEach(this.visibleSpecies(), (item: Species, index: number) => {
            ListItem() {
              AtlasListCard({
                species: item,
                summary: this.summaryFor(item.id),
                showDate: index === 0,
                dateLabel: this.dateLabel((this.summaryFor(item.id).latestDiscovery ?? new Discovery()).discoveredAt),
                onOpen: (speciesId: string) => this.onOpenSpecies(speciesId)
              })
            }
          }, (item: Species) => item.id)
        }
        .width('100%')
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.None)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .padding({
      left: AppDimensions.PAGE_HORIZONTAL,
      right: AppDimensions.PAGE_HORIZONTAL,
      bottom: AppSpacing.XL
    })
    .backgroundColor(AppColors.BACKGROUND_PRIMARY)
  }
}

@Component
struct AtlasListCard {
  @Prop species: Species = new Species();
  @Prop summary: DiscoverySummary = new DiscoverySummary();
  @Prop showDate: boolean = false;
  @Prop dateLabel: string = '';
  @BuilderParam onOpen: (speciesId: string) => void;

  private latest(): Discovery {
    return this.summary.latestDiscovery ?? new Discovery();
  }

  build() {
    Column({ space: AppSpacing.XXS }) {
      if (this.showDate) {
        Row() {
          Text(this.dateLabel)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_SECONDARY)
          Blank()
          Text(this.summary.encounterCount + ' 次相遇')
            .fontSize(AppTypography.META_SIZE)
            .fontColor(AppColors.TEXT_TERTIARY)
        }
        .width('100%')
        .padding({ top: AppSpacing.SM, bottom: AppSpacing.XS })
      }
      Row({ space: AppSpacing.SM }) {
        Image(this.latest().photoUri)
          .width(76)
          .height(76)
          .objectFit(ImageFit.Cover)
          .backgroundColor(AppColors.PHOTO_FALLBACK)
          .borderRadius(AppDimensions.RADIUS_SMALL)
        Column({ space: 3 }) {
          Text(this.species.chineseName)
            .fontSize(AppTypography.CARD_TITLE_SIZE)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.species.scientificName.length > 0) {
            Text(this.species.scientificName)
              .fontSize(AppTypography.META_SIZE)
              .fontStyle(FontStyle.Italic)
              .fontColor(AppColors.TEXT_SECONDARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          Text('最近相遇 · ' + DateFormatter.monthAndDay(this.latest().discoveredAt))
            .fontSize(AppTypography.META_SIZE)
            .fontColor(AppColors.TEXT_SECONDARY)
          if (this.latest().locationName.length > 0) {
            Text(this.latest().locationName)
              .fontSize(AppTypography.META_SIZE)
              .fontColor(AppColors.TEXT_TERTIARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ top: AppSpacing.SM, bottom: AppSpacing.SM, left: AppSpacing.XS, right: AppSpacing.XS })
      .backgroundColor(AppColors.BACKGROUND_SECONDARY)
      .border({ width: { bottom: AppDimensions.HAIRLINE }, color: AppColors.BORDER_SOFT })
      .borderRadius(AppDimensions.RADIUS_SMALL)
      .stateStyles({ pressed: { opacity: 0.72 } })
      .onClick(() => this.onOpen(this.species.id))
    }
    .width('100%')
  }
}
