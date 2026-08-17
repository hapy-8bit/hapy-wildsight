import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { AppColors } from '../../constants/AppColors';
import { AppDimensions } from '../../constants/AppDimensions';
import { AppSpacing } from '../../constants/AppSpacing';
import { AppTypography } from '../../constants/AppTypography';
import { DiscoveryRepository } from '../../repositories/DiscoveryRepository';
import { SpeciesRepository } from '../../repositories/SpeciesRepository';
import { AppearanceMode, AppearancePreferenceService } from '../../services/AppearancePreferenceService';
import { StorageUsage, StorageUsageService } from '../../services/StorageUsageService';
import { PageTitle } from '../../components/PageTitle';
import { SecondaryPageHeader } from '../../components/SecondaryPageHeader';

/** 设置页采用紧凑的分组卡片，同时保留 WildSight 的纸张色板和原有业务入口。 */
@Component
export struct ProfilePage {
  @BuilderParam onReloadLocalData: () => void;
  @BuilderParam onAppearanceChanged: (mode: AppearanceMode) => void;
  @BuilderParam onPrivacyConsentRevoked: () => void;
  @State page: string = 'home';
  @State usage: StorageUsage = new StorageUsage();
  @State appearance: AppearanceMode = AppearanceMode.SYSTEM;
  @State notice: string = '';
  @State eraseArmed: boolean = false;
  @State detailScrollOffset: number = 0;
  private readonly storage = new StorageUsageService();
  private readonly prefs = new AppearancePreferenceService();
  private readonly discoveries = new DiscoveryRepository();
  private readonly species = new SpeciesRepository();

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      this.usage = await this.storage.measure(context);
      this.appearance = await this.prefs.load(context);
    } catch (_error) {
    }
  }

  private async selectAppearance(mode: AppearanceMode): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      await this.prefs.save(context, mode);
      context.setColorMode(
        mode === AppearanceMode.DARK ? ConfigurationConstant.ColorMode.COLOR_MODE_DARK :
          mode === AppearanceMode.LIGHT ? ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT :
            ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
      );
      this.appearance = mode;
      this.onAppearanceChanged(mode);
      this.notice = '外观偏好已保存，重启后仍会保留。';
    } catch (_error) {
      this.notice = '暂时无法保存外观偏好。';
    }
  }

  private async clearCache(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const freed = await this.storage.clearRebuildableCache(context);
      this.usage = await this.storage.measure(context);
      this.notice = freed > 0 ? `已清理 ${this.storage.format(freed)} 缓存。` : '当前没有可安全清理的缓存。';
    } catch (_error) {
      this.notice = '暂时无法清理缓存。';
    }
  }

  private async eraseData(): Promise<void> {
    if (!this.eraseArmed) {
      this.eraseArmed = true;
      return;
    }
    try {
      await this.discoveries.deleteAll();
      await this.species.deleteAll();
      this.eraseArmed = false;
      this.onReloadLocalData();
      this.notice = '本机图鉴数据已清除，系统图库原图未受影响。';
    } catch (_error) {
      this.notice = '暂时无法清除本机图鉴数据。';
    }
  }

  private async copyMail(): Promise<void> {
    try {
      await pasteboard.getSystemPasteboard().setData(
        pasteboard.createData('text/plain', 'hapy8bit@163.com')
      );
      this.notice = '邮箱地址已复制。';
    } catch (_error) {
      this.notice = '请联系 hapy8bit@163.com';
    }
  }

  private async openFeedback(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      await context.startAbility({
        uri: 'mailto:hapy8bit@163.com?subject=WildSight%20%E8%A7%81%E9%87%8E%201.0.1%20%E9%97%AE%E9%A2%98%E5%8F%8D%E9%A6%88&body=%E9%97%AE%E9%A2%98%E6%8F%8F%E8%BF%B0%EF%BC%9A%0A%0A%E5%A4%8D%E7%8E%B0%E6%AD%A5%E9%AA%A4%EF%BC%9A%0A%0A%E6%9C%9F%E6%9C%9B%E7%BB%93%E6%9E%9C%EF%BC%9A'
      });
    } catch (_error) {
      await this.copyMail();
    }
  }

  private label(): string {
    if (this.page === 'subscription') return '订阅服务';
    if (this.page === 'storage') return '占用空间';
    if (this.page === 'imageSources') return '图片与识别来源';
    if (this.page === 'knowledgeSources') return '植物文本与知识来源';
    if (this.page === 'appearance') return '外观';
    if (this.page === 'permissions') return '权限说明';
    if (this.page === 'language') return '语言';
    if (this.page === 'privacy') return '隐私政策';
    return '服务协议';
  }

  private appearanceText(): string {
    return this.appearance === AppearanceMode.DARK ? '深色' :
      this.appearance === AppearanceMode.LIGHT ? '浅色' : '跟随系统';
  }

  private openPage(page: string): void {
    this.page = page;
    this.notice = '';
    this.detailScrollOffset = 0;
  }

  build() {
    if (this.page === 'home') {
      this.home();
    } else {
      this.detail();
    }
  }

  @Builder
  private home(): void {
    Stack({ alignContent: Alignment.Top }) {
      Scroll() {
        Column({ space: AppDimensions.SETTINGS_GROUP_SPACE }) {
          this.serviceGroup();
          this.storageGroup();
          this.personalizationGroup();
          this.privacyGroup();
          this.supportGroup();
          this.homeFooter();
        }
        .width('100%')
        .constraintSize({ minHeight: '100%' })
        .padding({
          left: AppDimensions.PAGE_HORIZONTAL,
          right: AppDimensions.PAGE_HORIZONTAL,
          top: AppDimensions.SETTINGS_CONTENT_TOP_INSET,
          bottom: AppDimensions.SETTINGS_CONTENT_BOTTOM_INSET
        })
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .backgroundColor(AppColors.PAPER)

      this.settingsHeader()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.PAPER)
  }

  @Builder
  private settingsHeader(): void {
    Column() {
      PageTitle({ title: '设置' })
    }
    .width('100%')
    .height(AppDimensions.SETTINGS_HEADER_HEIGHT)
    .padding({ left: AppDimensions.PAGE_HORIZONTAL, right: AppDimensions.PAGE_HORIZONTAL })
    .backgroundColor(AppColors.PAPER)
  }

  @Builder
  private serviceGroup(): void {
    Column({ space: 7 }) {
      this.sectionTitle('服务')
      Column() {
        this.actionRow(
          '订阅服务',
          '基础服务 · 订阅暂未开放',
          $r('sys.symbol.info_circle'),
          AppColors.EARTH,
          () => this.openPage('subscription')
        )
      }
      .width('100%')
      .backgroundColor(AppColors.PAPER_ELEVATED)
      .borderRadius(AppDimensions.SETTINGS_GROUP_RADIUS)
      .clip(true)
    }
    .width('100%')
  }

  @Builder
  private storageGroup(): void {
    Column({ space: 7 }) {
      this.sectionTitle('存储与数据')
      Column() {
        this.actionRow(
          '占用空间',
          this.storage.format(this.usage.totalBytes),
          $r('sys.symbol.doc_plaintext'),
          AppColors.EARTH,
          () => this.openPage('storage')
        )
        this.settingsDivider()
        this.actionRow(
          '图片与识别来源',
          '系统相册、识别接口与百度服务',
          $r('sys.symbol.info_circle'),
          AppColors.SKY,
          () => this.openPage('imageSources')
        )
        this.settingsDivider()
        this.actionRow(
          '植物文本与知识来源',
          '分类资料、形态描述与审核流程',
          $r('sys.symbol.doc_plaintext'),
          AppColors.BRAND_GREEN,
          () => this.openPage('knowledgeSources')
        )
      }
      .width('100%')
      .backgroundColor(AppColors.PAPER_ELEVATED)
      .borderRadius(AppDimensions.SETTINGS_GROUP_RADIUS)
      .clip(true)
    }
    .width('100%')
  }

  @Builder
  private personalizationGroup(): void {
    Column({ space: 7 }) {
      this.sectionTitle('个性化')
      Column() {
        this.actionRow(
          '外观',
          this.appearanceText(),
          $r('sys.symbol.sun_max_fill'),
          AppColors.BRAND_GREEN,
          () => this.openPage('appearance')
        )
        this.settingsDivider()
        this.actionRow(
          '语言',
          '简体中文',
          $r('sys.symbol.info_circle'),
          AppColors.SKY,
          () => this.openPage('language')
        )
      }
      .width('100%')
      .backgroundColor(AppColors.PAPER_ELEVATED)
      .borderRadius(AppDimensions.SETTINGS_GROUP_RADIUS)
      .clip(true)
    }
    .width('100%')
  }

  @Builder
  private privacyGroup(): void {
    Column({ space: 7 }) {
      this.sectionTitle('权限与隐私')
      Column() {
        this.actionRow(
          '权限说明',
          '照片选择与网络使用',
          $r('sys.symbol.hand_raised_fingers_spread'),
          AppColors.BRAND_GREEN,
          () => this.openPage('permissions')
        )
        this.settingsDivider()
        this.actionRow(
          '隐私政策',
          '本地数据、识别服务与隐私处理',
          $r('sys.symbol.info_circle'),
          AppColors.SKY,
          () => this.openPage('privacy')
        )
        this.settingsDivider()
        this.actionRow(
          '服务协议',
          'WildSight 使用说明与责任边界',
          $r('sys.symbol.doc_plaintext'),
          AppColors.EARTH,
          () => this.openPage('terms')
        )
        this.settingsDivider()
        this.actionRow(
          '撤回识别授权',
          '停止后续图片识别与上传，可再次主动同意',
          $r('sys.symbol.info_circle'),
          AppColors.DANGER,
          () => this.onPrivacyConsentRevoked()
        )
      }
      .width('100%')
      .backgroundColor(AppColors.PAPER_ELEVATED)
      .borderRadius(AppDimensions.SETTINGS_GROUP_RADIUS)
      .clip(true)
    }
    .width('100%')
  }

  @Builder
  private supportGroup(): void {
    Column({ space: 7 }) {
      this.sectionTitle('支持')
      Column() {
        this.actionRow(
          '反馈问题',
          '问题反馈与建议',
          $r('sys.symbol.message'),
          AppColors.EARTH,
          () => this.openFeedback()
        )
        this.settingsDivider()
        this.staticRow(
          '版本',
          '1.0.1',
          $r('sys.symbol.doc_plaintext'),
          AppColors.INK_SUBTLE
        )
        this.settingsDivider()
        this.actionRow(
          '给个好评',
          '支持见野继续完善',
          $r('sys.symbol.info_circle'),
          AppColors.BRAND_GREEN,
          () => this.notice = '当前测试版本暂未开放应用市场评分'
        )
      }
      .width('100%')
      .backgroundColor(AppColors.PAPER_ELEVATED)
      .borderRadius(AppDimensions.SETTINGS_GROUP_RADIUS)
      .clip(true)
    }
    .width('100%')
  }

  @Builder
  private homeFooter(): void {
    Column({ space: 6 }) {
      if (this.notice.length > 0) {
        Text(this.notice)
          .width('100%')
          .fontSize(AppTypography.META_SIZE)
          .lineHeight(18)
          .fontColor(AppColors.INK_MUTED)
      }
    }
    .width('100%')
    .padding({ left: 4, right: 4, top: 2 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private sectionTitle(title: string): void {
    Text(title)
      .width('100%')
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.INK_MUTED)
      .padding({ left: 6 })
  }

  @Builder
  private actionRow(
    title: string,
    subtitle: string,
    symbol: Resource,
    iconColor: ResourceColor,
    onClick: () => void
  ): void {
    Row({ space: 13 }) {
      this.settingsIcon(symbol, iconColor)
      this.rowText(title, subtitle)
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(AppDimensions.SETTINGS_CHEVRON_SIZE)
        .fontColor([AppColors.INK_SUBTLE])
        .width(AppDimensions.SETTINGS_CHEVRON_WIDTH)
        .height(AppDimensions.SETTINGS_CHEVRON_HEIGHT)
    }
    .width('100%')
    .height(AppDimensions.SETTINGS_ROW_HEIGHT)
    .padding({
      left: AppDimensions.SETTINGS_ROW_HORIZONTAL_PADDING,
      right: AppDimensions.SETTINGS_ROW_HORIZONTAL_PADDING
    })
    .alignItems(VerticalAlign.Center)
    .onClick(onClick)
    .accessibilityText(`${title}，${subtitle}`)
  }

  @Builder
  private staticRow(
    title: string,
    subtitle: string,
    symbol: Resource,
    iconColor: ResourceColor
  ): void {
    Row({ space: 13 }) {
      this.settingsIcon(symbol, iconColor)
      this.rowText(title, subtitle)
    }
    .width('100%')
    .height(AppDimensions.SETTINGS_ROW_HEIGHT)
    .padding({
      left: AppDimensions.SETTINGS_ROW_HORIZONTAL_PADDING,
      right: AppDimensions.SETTINGS_ROW_HORIZONTAL_PADDING
    })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private rowText(title: string, subtitle: string): void {
    Column({ space: 2 }) {
      Text(title)
        .fontSize(AppTypography.BODY_SIZE)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.INK)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(subtitle)
        .fontSize(AppTypography.META_SIZE)
        .fontColor(AppColors.INK_MUTED)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private settingsIcon(symbol: Resource, color: ResourceColor): void {
    Stack({ alignContent: Alignment.Center }) {
      SymbolGlyph(symbol)
        .fontSize(AppDimensions.SETTINGS_ICON_SYMBOL_SIZE)
        .fontColor([AppColors.WHITE])
    }
    .width(AppDimensions.SETTINGS_ICON_SIZE)
    .height(AppDimensions.SETTINGS_ICON_SIZE)
    .backgroundColor(color)
    .borderRadius(AppDimensions.SETTINGS_ICON_SIZE / 2)
  }

  @Builder
  private settingsDivider(): void {
    Divider()
      .strokeWidth(0.5)
      .color(AppColors.DIVIDER)
      .margin({
        left: AppDimensions.SETTINGS_DIVIDER_LEFT_MARGIN,
        right: AppDimensions.SETTINGS_DIVIDER_RIGHT_MARGIN
      })
  }

  @Builder
  private detail(): void {
    Column() {
      Stack({ alignContent: Alignment.Top }) {
        Scroll() {
          Column({ space: AppSpacing.MD }) {
            this.content()
            if (this.notice.length > 0) {
              Text(this.notice)
                .width('100%')
                .fontSize(AppTypography.META_SIZE)
                .lineHeight(18)
                .fontColor(AppColors.INK_MUTED)
            }
          }
          .width('100%')
          .constraintSize({ minHeight: '100%' })
          .padding({
            left: AppDimensions.PAGE_HORIZONTAL,
            right: AppDimensions.PAGE_HORIZONTAL,
            top: AppDimensions.SECONDARY_PAGE_CONTENT_TOP_INSET,
            bottom: AppDimensions.SETTINGS_CONTENT_BOTTOM_INSET
          })
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
        .onScroll((_xOffset: number, yOffset: number) => {
          this.detailScrollOffset = Math.max(0, yOffset);
        })

        SecondaryPageHeader({
          title: this.label(),
          scrollOffset: this.detailScrollOffset,
          onBack: () => this.openPage('home')
        })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.PAPER)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  private content(): void {
    if (this.page === 'subscription') {
      this.textCard('当前使用基础服务。订阅功能正在规划，本版本不展示价格或未确定权益，不调用支付服务，也不修改识别额度。');
    } else if (this.page === 'storage') {
      this.storagePage();
    } else if (this.page === 'imageSources') {
      this.imageSourcesPage();
    } else if (this.page === 'knowledgeSources') {
      this.knowledgeSourcesPage();
    } else if (this.page === 'sources') {
      Column({ space: AppSpacing.MD }) {
        this.imageSourcesPage();
        this.knowledgeSourcesPage();
      }
    } else if (this.page === 'appearance') {
      this.appearancePage();
    } else if (this.page === 'permissions') {
      this.textCard('相机：仅在你主动点击“拍照识别”时，通过 HarmonyOS 系统相机能力申请并使用相机权限；拒绝权限不影响“从相册识别”。\n\n照片与图库：仅处理你主动选择或拍摄的图片；相册使用系统 PhotoPicker，不扫描整个图库，不删除或修改系统图库原图。\n\n位置：当前未主动采集地理位置。\n\n网络：用于把你主动发起识别的图片发送到 WildSight HTTPS 后端，并获取识别结果和植物知识。网络权限用于连接服务，不是每次弹窗授权。');
    } else if (this.page === 'language') {
      this.languagePage();
    } else if (this.page === 'privacy') {
      this.privacyPolicyPage();
    } else {
      this.termsPage();
    }
  }

  @Builder
  private textCard(value: string): void {
    Text(value)
      .fontSize(AppTypography.BODY_SIZE)
      .fontColor(AppColors.INK_MUTED)
      .lineHeight(25)
      .width('100%')
      .padding(16)
      .backgroundColor(AppColors.PAPER_ELEVATED)
      .borderRadius(AppDimensions.SETTINGS_GROUP_RADIUS)
  }

  @Builder
  private imageSourcesPage(): void {
    Column({ space: AppSpacing.MD }) {
      this.infoCard('图片从哪里来', '图片来源分为两类：你主动点击“从相册识别”后，由 HarmonyOS PhotoPicker 提供你选择的一张系统相册图片；你主动点击“拍照识别”后，由 HarmonyOS 系统相机拍摄并返回一张新图片。两种方式都只处理当前图片，不扫描整个图库，不删除或修改系统图库原图。');
      this.infoCard('图片识别服务', '你主动确认相册选择或拍照后，应用会按识别接口要求处理当前图片，通过 HTTPS 发送到 WildSight 后端 api.hapybuilds.com。后端再调用百度智能云植物识别服务，取得候选名称和匹配度后返回应用。百度负责图片识别候选；识别结果页显示的植物文本来自 WildSight 植物知识库，不是百度接口直接生成的长篇内容。');
      this.infoCard('上传范围与留存', '单次请求只上传当前选择的图片和用于每日额度控制的随机安装标识，不上传本机 Species、Discovery、备注或整部图库。WildSight 后端使用内存接收本次图片，应用业务代码不把图片写入业务数据库；百度及网络基础设施可能按其自身规则产生必要的处理记录，具体以其公开规则为准。');
      this.infoCard('识别结果边界', '识别结果只表示“可能是什么植物”，匹配度不是确定性结论。它仅供自然观察、学习和个人记录，不构成食用、药用、医疗、毒性、宠物安全、农业防治或野外采集建议。');
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private knowledgeSourcesPage(): void {
    Column({ space: AppSpacing.MD }) {
      this.infoCard('分类、学名与外部编号', 'GBIF（全球生物多样性信息机构）用于核验接受学名、分类身份、科属关系及外部分类编号。GBIF 是分类学核验来源，不是用户图片识别服务，也不会接收本次识别图片。');
      this.infoCard('中文名与形态事实', '植物文本按物种记录分别参考植物智（iPlant）、Flora of China／中国植物志、Flora of North America、Plants of the World Online（POWO）、专业植物园及大学资料等公开来源。不同物种实际使用的来源不完全相同，服务端为每条知识记录保留对应来源和访问日期。');
      this.infoCard('WildSight 审核与展示', 'WildSight 将来源资料按物种整理为中文名、学名、科属、形态特征、观察要点和易混淆提示，经人工审核后发布到知识库。识别页中的植物文本来自这套审核后的 WildSight 知识记录，不是百度识别接口直接生成的长文本；知识会按内容版本更新。');
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private languagePage(): void {
    Column() {
      Row({ space: 13 }) {
        this.settingsIcon($r('sys.symbol.info_circle'), AppColors.SKY)
        Column({ space: 2 }) {
          Text('简体中文')
            .fontSize(AppTypography.BODY_SIZE)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.INK)
          Text('当前界面语言')
            .fontSize(AppTypography.META_SIZE)
            .fontColor(AppColors.INK_MUTED)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        SymbolGlyph($r('sys.symbol.checkmark'))
          .fontSize(20)
          .fontColor([AppColors.MOSS])
      }
      .width('100%')
      .height(AppDimensions.SETTINGS_ROW_HEIGHT)
      .padding({ left: AppDimensions.SETTINGS_ROW_HORIZONTAL_PADDING, right: AppDimensions.SETTINGS_ROW_HORIZONTAL_PADDING })
      .alignItems(VerticalAlign.Center)
      .onClick(() => this.notice = '已选择简体中文。')
      .accessibilityText('简体中文，已选择')
    }
    .width('100%')
    .backgroundColor(AppColors.PAPER_ELEVATED)
    .borderRadius(AppDimensions.SETTINGS_GROUP_RADIUS)
    .clip(true)
  }

  @Builder
  private infoCard(title: string, body: string): void {
    Column({ space: 7 }) {
      Text(title)
        .width('100%')
        .fontSize(AppTypography.CARD_TITLE_SIZE)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
      Text(body)
        .width('100%')
        .fontSize(AppTypography.BODY_SIZE)
        .lineHeight(24)
        .fontColor(AppColors.INK_MUTED)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.PAPER_ELEVATED)
    .borderRadius(AppDimensions.SETTINGS_GROUP_RADIUS)
  }

  @Builder
  private legalHeader(title: string, updated: string, summary: string): void {
    Column({ space: 7 }) {
      Text(title)
        .width('100%')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
      Text(updated)
        .width('100%')
        .fontSize(AppTypography.META_SIZE)
        .fontColor(AppColors.INK_MUTED)
      Text(summary)
        .width('100%')
        .fontSize(AppTypography.BODY_SIZE)
        .lineHeight(24)
        .fontColor(AppColors.INK_MUTED)
    }
    .width('100%')
    .padding({ left: 4, right: 4, bottom: 2 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private legalSection(title: string, body: string): void {
    Column({ space: 7 }) {
      Text(title)
        .width('100%')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
      Text(body)
        .width('100%')
        .fontSize(AppTypography.BODY_SIZE)
        .lineHeight(24)
        .fontColor(AppColors.INK_MUTED)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.PAPER_ELEVATED)
    .borderRadius(AppDimensions.SETTINGS_GROUP_RADIUS)
  }

  @Builder
  private legalNotice(title: string, body: string): void {
    Column({ space: 7 }) {
      Text(title)
        .width('100%')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
      Text(body)
        .width('100%')
        .fontSize(AppTypography.BODY_SIZE)
        .fontWeight(FontWeight.Bold)
        .lineHeight(24)
        .fontColor(AppColors.INK)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.MOSS_LIGHT)
    .borderRadius(AppDimensions.SETTINGS_GROUP_RADIUS)
  }

  @Builder
  private privacyPolicyPage(): void {
    Column({ space: AppSpacing.MD }) {
      this.legalHeader('见野（WildSight）隐私政策', '更新日期：2026年8月16日　生效日期：2026年8月16日', '本政策说明见野（WildSight）在植物识别、植物知识浏览、个人图鉴和本地记录功能中如何处理信息，以及你可以如何管理这些信息。')
      this.legalSection('一、适用范围与基本原则', '本政策适用于见野（WildSight）客户端及其发起的植物识别、知识查询和问题反馈请求。我们只在实现相应功能所必要的范围内处理信息；不通过本应用主动采集地理位置，不建立账号资料，不进行广告画像、精准营销或与本政策无关的模型训练。')
      this.legalSection('二、处理的信息及来源', '1. 图片：来源是你主动使用 HarmonyOS PhotoPicker 选择的一张系统相册图片，或主动点击“拍照识别”后由系统相机拍摄的一张图片。图片用于本次植物识别和在识别结果中展示；不扫描整个图库，不在后台静默调用相机。\n2. 本地 Species 与 Discovery：Species 用于保存和展示植物名称、学名、分类、形态描述、观察提示及知识来源；Discovery 用于保存你主动收入图鉴的相遇照片 URI、识别结果、匹配度、相遇时间、地点名称和备注，便于在本机查看、管理和形成个人图鉴。这些记录保存在 HarmonyOS 应用沙箱的本地数据库中。\n3. installationId：首次发起识别时在本机随机生成并保存在应用偏好设置中，用于识别服务的每日额度控制；它不是姓名、账号或硬件标识。\n4. 反馈信息：只有在你主动通过邮件反馈时，邮件正文、附件和联系地址才会由你提交给邮件服务。')
      this.legalSection('三、图片识别和知识内容的处理', '你主动发起识别后，当前图片会按接口要求读取，必要时压缩为 JPEG，并通过 HTTPS 发送至 WildSight 后端 api.hapybuilds.com。后端调用百度智能云植物识别服务，返回候选植物名称和匹配度。应用再根据识别结果匹配本地或 WildSight 知识库，展示植物名称、分类、形态描述、观察提示及审核状态。识别结果、匹配度和知识内容用于结果展示、帮助你了解植物和收入个人图鉴，不代表确定性鉴定。')
      this.legalSection('四、第三方服务与数据来源', '1. HarmonyOS PhotoPicker：提供系统相册选择和临时图片访问范围。\n2. HarmonyOS 系统相机：在你主动点击“拍照识别”时提供拍摄能力，系统按流程申请相机权限。\n3. WildSight 后端：接收单次识别图片和 installationId，处理识别请求、额度控制并返回结果；本次图片由业务代码在请求期间以内存处理，不写入本地或业务数据库。\n4. 百度智能云植物识别服务：由 WildSight 后端发送本次识别图片，返回植物候选名称、匹配度及接口基础结果；其处理规则以百度公开政策为准。\n5. 植物文本来源：植物知识库使用分类资料、植物智（iPlant）、Flora of China／中国植物志、GBIF、POWO、专业植物园和大学资料等公开来源，并经整理、审核后在应用中展示。识别服务来源与植物文本来源相互独立。')
      this.legalSection('五、保存、删除与共享', '系统图库原图仍由系统图库管理，WildSight 不删除或修改。应用本地保存的是图片 URI、Species 和 Discovery 等本地记录，直到你在“设置 > 占用空间”清除本机图鉴数据、清除应用数据或卸载应用；清理缓存不会删除图鉴记录。服务端对 installationId 按真实服务逻辑进行 SHA-256 哈希，用于每日额度控制；识别图片由后端和百度按各自服务规则处理。我们不主动上传本地 Species、Discovery、备注或整部图库，也不将其用于广告或营销。')
      this.legalSection('六、权限与用户权利', '网络权限用于连接识别和知识服务；照片访问仅通过系统 PhotoPicker；相机权限仅在你主动拍照时申请。当前版本不主动采集地理位置。你可以拒绝相册或相机权限而继续使用不依赖识别的本地功能，也可以在设置中撤回识别授权、清理缓存或清除本机图鉴数据。清除本机图鉴数据不会删除系统图库原图。需要咨询、反馈问题、行使查阅或删除请求，请联系 hapy8bit@163.com；请在反馈中说明请求事项，不要发送与处理请求无关的敏感信息。')
      this.legalSection('七、未成年人保护与政策更新', '未成年人应在监护人指导下使用，并避免上传包含身份证件、人脸、住址或精确位置等与植物识别无关的信息。功能、处理方式或第三方服务发生变化时，我们会在应用内更新本政策并标明日期；涉及重大变化时依法提示并重新取得必要同意。')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private termsPage(): void {
    Column({ space: AppSpacing.MD }) {
      this.legalHeader('见野（WildSight）用户服务协议', '更新日期：2026年8月16日　生效日期：2026年8月16日', '欢迎使用见野（WildSight）。本协议说明植物识别、植物知识、本地个人图鉴和问题反馈服务的使用规则与责任边界。使用需要联网或处理图片的功能前，请阅读并同意本协议及《见野（WildSight）隐私政策》。')
      this.legalSection('一、服务内容', '见野提供植物图片识别、识别结果展示、审核后的植物知识浏览、个人图鉴和相遇记录、本机数据管理及问题反馈入口。图片可以来自 HarmonyOS PhotoPicker 或你主动使用的系统相机。服务内容以当前应用实际提供的功能为准。')
      this.legalSection('二、使用条件与用户义务', '你应具备使用本服务所需的民事行为能力；不具备的，应在监护人同意和指导下使用。你只能上传自己拥有或已获授权处理的图片，并应尊重他人的肖像权、隐私权、著作权和其他合法权益。你不得上传违法、有害、侵权、恶意程序或与植物识别无关的敏感内容，不得反向攻击、批量爬取、破解接口、绕过每日额度、干扰服务或利用本应用实施违法活动。')
      this.legalSection('三、识别结果与植物知识的使用边界', '识别结果由图片算法和第三方识别服务共同产生，受拍摄角度、光线、图片清晰度、物种相似度、知识覆盖范围和网络状况影响，可能错误、遗漏或无法识别。植物文本是 WildSight 根据公开植物资料整理并审核的观察参考，不是对当前图片的确定性鉴定。识别结果和植物文本不构成食用、药用、医疗、毒性、宠物安全、农业防治、法律合规、野外采集或其他专业建议。涉及人身、动物、食物、药物或财产安全的决定，应以现场核验和具备资质的专业意见为准。')
      this.legalSection('四、图片、图鉴记录及知识内容权利', '系统图库原图的权利归原权利人所有；你应确保有权让本应用为识别目的进行必要处理。你授予我们一项非独占、非转让、仅限完成本次识别、返回结果和在本机图鉴展示所必需的处理许可，我们不因提供服务取得图片所有权。图鉴中的备注和相遇记录由你管理。植物知识内容可能同时受到来源网站、数据集或其他权利人的许可和知识产权保护，未经授权不得批量复制、抓取、再分发或用于商业用途。')
      this.legalSection('五、第三方服务与网络连接', '图片识别需要经 api.hapybuilds.com 连接 WildSight 后端，并由后端调用百度智能云植物识别服务；植物知识详情可能按需从 WildSight 知识接口获取。第三方服务的接口、算法、网络、可用性和隐私规则由相应服务方负责。你主动使用识别功能，即理解所选图片会按《隐私政策》发送至该服务链路；你可以拒绝选择图片而继续使用不需要识别的本地功能。')
      this.legalSection('六、服务变更、中断与终止', '我们会因产品维护、安全需要、法律法规、知识来源变化或第三方服务变化，对功能进行更新、调整、暂停或终止，并在合理范围内提示。因网络、设备、系统维护、第三方服务故障、不可抗力或其他非我们可合理控制的原因导致的中断、延迟、错误或数据丢失，我们会在能力范围内恢复，但不保证服务始终连续、及时、无错误。你可以停止使用、清除本机数据或卸载应用。')
      this.legalSection('七、知识产权与侵权处理', '应用界面、程序代码、品牌标识、原创编排和 WildSight 自行制作的内容，其权利归相应权利人所有。你发现图片、文字或其他内容可能侵犯合法权益，可以通过 hapy8bit@163.com 提交权利证明、具体链接和联系方式；我们会在法律法规和事实核验范围内处理。你提交反馈时应保证内容真实、合法并有权提交。')
      this.legalSection('八、责任限制', '在法律允许的范围内，我们不对识别结果的绝对准确性、完整性、持续可用性或特定用途适用性作保证，也不对你仅依据识别结果作出的决定承担责任。因你上传无权处理的内容、违反本协议或不当使用服务造成第三方损害的，由你依法承担相应责任。法律规定不得排除或限制的责任、消费者依法享有的权利不受本条影响。')
      this.legalSection('九、未成年人使用', '未成年人应在监护人阅读并同意本协议和隐私政策后，在监护人指导下使用。监护人应帮助未成年人理解识别结果的局限，监督其只上传用于植物观察的图片，并避免上传个人敏感信息。')
      this.legalSection('十、协议更新、适用法律与联系我们', '当服务内容、处理规则或法律要求发生变化时，我们会在应用内更新本协议并标明更新日期；重大变化会通过适当方式提示。更新后的协议公布后生效，法律法规要求重新取得同意的，我们会依法处理。除法律法规另有规定外，本协议适用中华人民共和国现行法律。对本协议有疑问、投诉或需要协助，请联系 hapy8bit@163.com。')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private storagePage(): void {
    Column({ space: AppSpacing.MD }) {
      this.textCard(`应用本地数据  ${this.storage.format(this.usage.totalBytes)}\n数据库与图鉴记录  ${this.storage.format(this.usage.databaseBytes)}\n缓存和临时文件  ${this.storage.format(this.usage.cacheBytes)}\n\n图库原图属于系统图库，不计入可清理缓存。`);

      Button('清理缓存')
        .width('100%')
        .height(48)
        .fontSize(AppTypography.BODY_SIZE)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.WHITE)
        .backgroundColor(AppColors.MOSS)
        .borderRadius(AppDimensions.RADIUS_SMALL)
        .onClick(() => this.clearCache())

      Text(this.eraseArmed ?
        '请再次点击确认清除本机图鉴数据。此操作不可撤销。' :
        '清除本机图鉴数据会删除本机 Species 和 Discovery，不删除系统图库原图、installationId、外观或语言偏好。'
      )
        .width('100%')
        .fontSize(AppTypography.META_SIZE)
        .lineHeight(18)
        .fontColor(AppColors.DANGER)
        .padding({ left: 4, right: 4 })

      Button(this.eraseArmed ? '确认清除本机图鉴数据' : '清除本机图鉴数据')
        .width('100%')
        .height(48)
        .fontSize(AppTypography.BODY_SIZE)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.WHITE)
        .backgroundColor(AppColors.DANGER)
        .borderRadius(AppDimensions.RADIUS_SMALL)
        .onClick(() => this.eraseData())
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private appearancePage(): void {
    Column() {
      this.option(AppearanceMode.SYSTEM, '跟随系统', '默认；响应系统浅色/深色变化', $r('sys.symbol.info_circle'), AppColors.SKY)
      this.settingsDivider()
      this.option(AppearanceMode.LIGHT, '浅色', '浅灰绿纸张外观', $r('sys.symbol.sun_max_fill'), AppColors.EARTH)
      this.settingsDivider()
      this.option(AppearanceMode.DARK, '深色', '深灰绿档案外观', $r('sys.symbol.info_circle'), AppColors.BRAND_GREEN)
    }
    .width('100%')
    .backgroundColor(AppColors.PAPER_ELEVATED)
    .borderRadius(AppDimensions.SETTINGS_GROUP_RADIUS)
    .clip(true)
  }

  @Builder
  private option(
    mode: AppearanceMode,
    title: string,
    subtitle: string,
    symbol: Resource,
    iconColor: ResourceColor
  ): void {
    Row({ space: 13 }) {
      this.settingsIcon(symbol, iconColor)
      this.rowText(title, subtitle)
      Text(this.appearance === mode ? '已选择' : '')
        .fontSize(AppTypography.META_SIZE)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.MOSS)
    }
    .width('100%')
    .height(AppDimensions.SETTINGS_ROW_HEIGHT)
    .padding({
      left: AppDimensions.SETTINGS_ROW_HORIZONTAL_PADDING,
      right: AppDimensions.SETTINGS_ROW_HORIZONTAL_PADDING
    })
    .alignItems(VerticalAlign.Center)
    .onClick(() => this.selectAppearance(mode))
  }

}
