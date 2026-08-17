import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { HdsTabs, HdsTabsController, hdsMaterial } from '@kit.UIDesignKit';
import { SymbolGlyphModifier, window } from '@kit.ArkUI';
import { AppColors } from './constants/AppColors';
import { AppDimensions } from './constants/AppDimensions';
import { AppTypography } from './constants/AppTypography';
import { Discovery, DiscoverySummary } from './models/Discovery';
import { IdentificationMatch, IdentificationResult } from './models/IdentificationResult';
import { IdentificationState } from './models/IdentificationState';
import { IdentificationErrorCode, IdentificationRequestError } from './models/IdentificationRequestError';
import { AppRoute } from './models/AppRoute';
import { Species } from './models/Species';
import { MockDiscoveryFactory } from './mock/MockDiscoveryFactory';
import { MockSpeciesData } from './mock/MockSpeciesData';
import { DiscoveryRepository } from './repositories/DiscoveryRepository';
import { SpeciesRepository } from './repositories/SpeciesRepository';
import { AtlasPage } from './pages/atlas/AtlasPage';
import { MyAtlasPage } from './pages/atlas/MyAtlasPage';
import { DiscoverPage } from './pages/discovery/DiscoverPage';
import { DiscoveryDetailPage } from './pages/discovery/DiscoveryDetailPage';
import { IdentificationResultPage } from './pages/discovery/IdentificationResultPage';
import { ProfilePage } from './pages/profile/ProfilePage';
import { SpeciesDetailPage } from './pages/species/SpeciesDetailPage';
import { PlantKnowledgeService } from './services/PlantKnowledgeService';
import { IdentificationService } from './services/IdentificationService';
import { IdentificationServiceFactory } from './services/IdentificationServiceFactory';
import { PhotoService } from './services/PhotoService';
import { InstallationIdentityService } from './services/InstallationIdentityService';
import { AppearanceMode, AppearancePreferenceService } from './services/AppearancePreferenceService';
import { PrivacyConsentService } from './services/PrivacyConsentService';

@Component
export struct WildSightApp {
  @State route: AppRoute = AppRoute.DISCOVER;
  @State previousRoute: AppRoute = AppRoute.DISCOVER;
  @State discoveryReturnRoute: AppRoute = AppRoute.DISCOVER;
  @State selectedSpeciesId: string = '';
  @State selectedDiscoveryId: string = '';
  @State discoveries: Discovery[] = [];
  @State selectedPhotoUri: string = '';
  @State discoveryNotice: string = '';
  @State identificationState: IdentificationState = IdentificationState.IDLE;
  @State identificationResult: IdentificationResult = new IdentificationResult();
  @State identificationFailureMessage: string = '';
  @State identificationTakingLong: boolean = false;
  @State species: Species[] = MockSpeciesData.all();
  @State primaryTabIndex: number = 1;
  @State appearanceRevision: number = 0;
  @State privacyConsentReady: boolean = false;
  @State privacyConsentAccepted: boolean = false;
  @State privacyConsentVisible: boolean = false;
  // HDS Tabs owns the bar's expansion/collapse animation on HarmonyOS 6.1.
  private readonly primaryTabsController: HdsTabsController = new HdsTabsController();
  private readonly atlasTabSymbol: TabBarSymbol = {
    normal: new SymbolGlyphModifier($r('sys.symbol.ohos_photo')),
    selected: new SymbolGlyphModifier($r('sys.symbol.ohos_photo'))
  };
  private readonly discoverTabSymbol: TabBarSymbol = {
    normal: new SymbolGlyphModifier($r('sys.symbol.camera')),
    selected: new SymbolGlyphModifier($r('sys.symbol.camera'))
  };
  private readonly profileTabSymbol: TabBarSymbol = {
    normal: new SymbolGlyphModifier($r('sys.symbol.gearshape')),
    selected: new SymbolGlyphModifier($r('sys.symbol.gearshape'))
  };
  private readonly discoveryRepository: DiscoveryRepository = new DiscoveryRepository();
  private readonly speciesRepository: SpeciesRepository = new SpeciesRepository();
  private readonly photoService: PhotoService = new PhotoService();
  private readonly installationIdentityService: InstallationIdentityService = new InstallationIdentityService();
  private readonly appearancePreferenceService: AppearancePreferenceService = new AppearancePreferenceService();
  private readonly privacyConsentService: PrivacyConsentService = new PrivacyConsentService();
  private readonly identificationService: IdentificationService = IdentificationServiceFactory.create();
  private identificationRequestSequence: number = 0;

  aboutToAppear(): void {
    this.restoreLocalDiscoveries();
    this.restoreAppearance();
    this.restorePrivacyConsent();
  }

  private async restorePrivacyConsent(): Promise<void> {
    try {
      const accepted = await this.privacyConsentService.load(getContext(this) as common.UIAbilityContext);
      this.privacyConsentAccepted = accepted;
      this.privacyConsentVisible = !accepted;
    } catch (_error) {
      this.privacyConsentAccepted = false;
      this.privacyConsentVisible = true;
    } finally {
      this.privacyConsentReady = true;
    }
  }

  private async acceptPrivacyConsent(): Promise<void> {
    try {
      await this.privacyConsentService.save(getContext(this) as common.UIAbilityContext, true);
      this.privacyConsentAccepted = true;
      this.privacyConsentVisible = false;
    } catch (_error) {
      this.privacyConsentAccepted = false;
    }
  }

  private declinePrivacyConsent(): void {
    this.privacyConsentVisible = false;
  }

  private async revokePrivacyConsent(): Promise<void> {
    try {
      await this.privacyConsentService.save(getContext(this) as common.UIAbilityContext, false);
    } catch (_error) {
    }
    this.privacyConsentAccepted = false;
    this.privacyConsentVisible = true;
  }

  private async restoreAppearance(): Promise<void> {
    try { this.applyAppearance(await this.appearancePreferenceService.load(getContext(this) as common.UIAbilityContext)); } catch (_error) { this.applyAppearance(AppearanceMode.LIGHT); }
  }

  private async restoreLocalDiscoveries(): Promise<void> {
    try {
      const seedSpecies = MockSpeciesData.all();
      for (let index = 0; index < seedSpecies.length; index += 1) {
        await this.speciesRepository.upsert(seedSpecies[index]);
      }
      this.species = await this.speciesRepository.listAll();
      this.discoveries = await this.discoveryRepository.listAll();
    } catch (error) {
      // No in-memory fake data is substituted: persistence failures remain visible as an empty atlas.
      this.discoveries = [];
    }
  }

  private selectedSpecies(): Species {
    return this.species.find((species: Species) => species.id === this.selectedSpeciesId) ?? MockSpeciesData.crapeMyrtle();
  }

  private selectedDiscovery(): Discovery {
    return this.discoveries.find((discovery: Discovery) => discovery.id === this.selectedDiscoveryId) ?? new Discovery();
  }

  private discoveriesForSelectedSpecies(): Discovery[] {
    return this.discoveries
      .filter((discovery: Discovery) => discovery.speciesId === this.selectedSpeciesId)
      .sort((left: Discovery, right: Discovery) => right.discoveredAt.getTime() - left.discoveredAt.getTime());
  }

  private summaries(): DiscoverySummary[] {
    return this.species.map((species: Species) => this.summaryForSpecies(species.id))
      .filter((summary: DiscoverySummary) => summary.encounterCount > 0);
  }

  private summaryForSpecies(speciesId: string): DiscoverySummary {
    const encounters = this.discoveries
      .filter((discovery: Discovery) => discovery.speciesId === speciesId)
      .sort((left: Discovery, right: Discovery) => left.discoveredAt.getTime() - right.discoveredAt.getTime());
    const summary = new DiscoverySummary();
    summary.speciesId = speciesId;
    summary.encounterCount = encounters.length;
    summary.firstDiscovery = encounters[0];
    summary.latestDiscovery = encounters.length > 0 ? encounters[encounters.length - 1] : undefined;
    summary.locations = encounters.map((discovery: Discovery) => discovery.locationName);
    return summary;
  }

  private atlasSpecies(): Species[] {
    return this.species.filter((species: Species) => this.summaryForSpecies(species.id).encounterCount > 0);
  }

  private recentDiscoveries(): Discovery[] {
    return this.discoveries
      .slice()
      .sort((left: Discovery, right: Discovery) => right.discoveredAt.getTime() - left.discoveredAt.getTime());
  }

  private tabBarStyle(symbol: TabBarSymbol, title: string): BottomTabBarStyle {
    return new BottomTabBarStyle(symbol, title)
      .iconStyle({
        selectedColor: AppColors.TAB_SELECTED,
        unselectedColor: AppColors.TAB_UNSELECTED
      })
      .labelStyle({
        selectedColor: AppColors.TAB_SELECTED,
        unselectedColor: AppColors.TAB_UNSELECTED
      });
  }

  private applyTabBarSymbolColors(): void {
    this.atlasTabSymbol.normal.fontColor([AppColors.TAB_UNSELECTED]);
    this.atlasTabSymbol.selected?.fontColor([AppColors.TAB_SELECTED]);
    this.discoverTabSymbol.normal.fontColor([AppColors.TAB_UNSELECTED]);
    this.discoverTabSymbol.selected?.fontColor([AppColors.TAB_SELECTED]);
    this.profileTabSymbol.normal.fontColor([AppColors.TAB_UNSELECTED]);
    this.profileTabSymbol.selected?.fontColor([AppColors.TAB_SELECTED]);
  }

  private async pickPhotoFromAlbum(): Promise<void> {
    if (!this.privacyConsentAccepted) {
      this.privacyConsentVisible = true;
      return;
    }
    try {
      const photoUri = await this.photoService.selectPhoto();
      if (photoUri === undefined || photoUri.length === 0) {
        return;
      }
      this.startIdentification(photoUri);
    } catch (error) {
      this.identificationState = IdentificationState.FAILED;
      this.route = AppRoute.IDENTIFICATION_RESULT;
    }
  }

  private async takePhoto(): Promise<void> {
    if (!this.privacyConsentAccepted) {
      this.privacyConsentVisible = true;
      return;
    }
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const photoUri = await this.photoService.capturePhoto(context);
      if (photoUri === undefined || photoUri.length === 0) {
        return;
      }
      this.startIdentification(photoUri);
    } catch (_error) {
      this.route = AppRoute.DISCOVER;
      this.discoveryNotice = '相机权限未开启或拍摄未完成，仍可使用“从相册识别”。';
    }
  }

  private startIdentification(photoUri: string): void {
    this.selectedPhotoUri = photoUri;
    this.discoveryNotice = '';
    this.identificationState = IdentificationState.IMAGE_SELECTED;
    this.identificationFailureMessage = '';
    this.route = AppRoute.IDENTIFICATION_RESULT;
    this.performIdentification(photoUri);
  }

  private retryIdentification(): void {
    if (this.selectedPhotoUri.length === 0) {
      this.changeRoute(AppRoute.DISCOVER);
      return;
    }
    this.identificationState = IdentificationState.IMAGE_SELECTED;
    this.identificationFailureMessage = '';
    this.performIdentification(this.selectedPhotoUri);
  }

  private async performIdentification(photoUri: string): Promise<void> {
    const requestSequence = ++this.identificationRequestSequence;
    this.identificationState = IdentificationState.IDENTIFYING;
    this.identificationTakingLong = false;
    const slowTimer = setTimeout((): void => {
      if (requestSequence === this.identificationRequestSequence && this.identificationState === IdentificationState.IDENTIFYING) {
        this.identificationTakingLong = true;
      }
    }, 5000);
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const installationId = await this.installationIdentityService.getOrCreate(context);
      const result = this.enrichKnownSpecies(await this.identificationService.identify(photoUri, installationId));
      if (requestSequence !== this.identificationRequestSequence) {
        return;
      }
      this.identificationResult = result;
      this.identificationState = result.primaryMatch.confidence < 0.55 ? IdentificationState.LOW_CONFIDENCE : IdentificationState.SUCCESS;
    } catch (error) {
      if (requestSequence === this.identificationRequestSequence) {
        this.applyIdentificationFailure(error);
      }
    } finally {
      clearTimeout(slowTimer);
      if (requestSequence === this.identificationRequestSequence) {
        this.identificationTakingLong = false;
      }
    }
  }

  private applyIdentificationFailure(error: Object): void {
    if (error instanceof IdentificationRequestError) {
      if (error.errorCode === IdentificationErrorCode.DAILY_LIMIT_REACHED) {
        this.identificationState = IdentificationState.LIMIT_REACHED;
        this.identificationFailureMessage = '今天的识别次数已用完，明天再来看看吧。';
        return;
      }
      if (error.errorCode === IdentificationErrorCode.INVALID_IMAGE) {
        this.identificationFailureMessage = '换一张更清晰的照片试试，让植物主体尽量出现在画面中央。';
      } else if (error.errorCode === IdentificationErrorCode.NETWORK_UNAVAILABLE) {
        this.identificationFailureMessage = '网络好像开小差了，检查网络后再试一次。';
      } else if (error.errorCode === IdentificationErrorCode.UPSTREAM_TIMEOUT) {
        this.identificationFailureMessage = '这次辨认花了一点时间，稍后再试一次。';
      } else {
        this.identificationFailureMessage = '暂时没有识别成功，换个角度或稍后再试。';
      }
    } else {
      this.identificationFailureMessage = '暂时没有识别成功，稍后再试。';
    }
    this.identificationState = IdentificationState.FAILED;
  }

  private async collectDiscovery(): Promise<void> {
    if (this.identificationState !== IdentificationState.SUCCESS) {
      return;
    }
    const species = await this.speciesForMatch(this.identificationResult.primaryMatch);
    const discovery = MockDiscoveryFactory.create(
      species.id,
      this.selectedPhotoUri,
      this.identificationResult.primaryMatch.confidence,
      this.discoveries
    );
    try {
      await this.speciesRepository.upsert(species);
      await this.discoveryRepository.save(discovery);
      if (!this.species.some((item: Species) => item.id === species.id)) {
        this.species = this.species.concat([species]);
      }
      this.discoveries = await this.discoveryRepository.listAll();
      this.selectedSpeciesId = discovery.speciesId;
      this.changeRoute(AppRoute.ATLAS);
    } catch (error) {
      this.identificationState = IdentificationState.FAILED;
    }
  }

  private enrichKnownSpecies(result: IdentificationResult): IdentificationResult {
    result.primaryMatch = this.enrichMatch(result.primaryMatch);
    result.alternativeMatches = result.alternativeMatches.map((match: IdentificationMatch) => this.enrichMatch(match));
    return result;
  }

  private enrichMatch(match: IdentificationMatch): IdentificationMatch {
    const knownSpecies = this.species.find((species: Species) => species.chineseName === match.displayName);
    if (knownSpecies === undefined) {
      return match;
    }
    match.scientificName = knownSpecies.scientificName.length > 0 ? knownSpecies.scientificName : undefined;
    match.family = knownSpecies.family.length > 0 ? knownSpecies.family : undefined;
    match.genus = knownSpecies.genus.length > 0 ? knownSpecies.genus : undefined;
    return match;
  }

  private async speciesForMatch(match: IdentificationMatch): Promise<Species> {
    const canonicalTaxonId = match.canonicalSpeciesId ?? '';
    let existing = canonicalTaxonId.length > 0 ? await this.speciesRepository.findByCanonicalTaxonId(canonicalTaxonId) : undefined;
    if (existing === undefined) {
      existing = this.species.find((species: Species) => species.chineseName === match.displayName);
    }
    if (existing !== undefined) {
      this.applyKnowledge(existing, match);
      return existing;
    }
    const species = new Species();
    species.id = `sp_remote_${this.stableIdentifier(match.displayName)}`;
    species.chineseName = match.displayName;
    species.scientificName = match.scientificName ?? '';
    species.family = match.family ?? '';
    species.genus = match.genus ?? '';
    species.description = match.description ?? '';
    species.coverPhotoUri = match.referenceImageUrl ?? this.selectedPhotoUri;
    this.applyKnowledge(species, match);
    return species;
  }

  private applyKnowledge(species: Species, match: IdentificationMatch): void {
    if (match.canonicalSpeciesId !== undefined) {
      species.canonicalTaxonId = match.canonicalSpeciesId;
    }
    if (match.knowledge === undefined) {
      return;
    }
    const knowledge = match.knowledge;
    species.chineseName = knowledge.acceptedChineseName.length > 0 ? knowledge.acceptedChineseName : species.chineseName;
    species.scientificName = knowledge.scientificName;
    species.family = knowledge.family;
    species.genus = knowledge.genus;
    species.aliases = knowledge.aliases;
    species.description = knowledge.summary.length > 0 ? knowledge.summary : species.description;
    species.features = knowledge.identificationReferences;
    species.knowledgeJson = JSON.stringify(knowledge);
    species.knowledgeVersion = knowledge.contentVersion;
    species.knowledgeReviewStatus = match.knowledgeReviewStatus ?? '';
  }

  private stableIdentifier(value: string): string {
    let hash = 0;
    for (let index = 0; index < value.length; index += 1) {
      hash = (hash * 31 + value.charCodeAt(index)) >>> 0;
    }
    return hash.toString(16);
  }

  private openSpecies(speciesId: string): void {
    this.previousRoute = this.route;
    this.selectedSpeciesId = speciesId;
    this.route = AppRoute.SPECIES_DETAIL;
  }

  private async refreshSelectedSpeciesKnowledge(): Promise<void> {
    const species = this.selectedSpecies();
    if (species.canonicalTaxonId.length === 0) return;
    const knowledge = await new PlantKnowledgeService().fetch(species.canonicalTaxonId);
    if (knowledge === undefined || knowledge.contentVersion <= species.knowledgeVersion) return;
    species.chineseName = knowledge.acceptedChineseName; species.scientificName = knowledge.scientificName; species.family = knowledge.family; species.genus = knowledge.genus;
    species.aliases = knowledge.aliases; species.description = knowledge.summary; species.features = knowledge.identificationReferences;
    species.knowledgeJson = JSON.stringify(knowledge); species.knowledgeVersion = knowledge.contentVersion;
    species.knowledgeReviewStatus = knowledge.knowledgeReviewStatus;
    await this.speciesRepository.updateKnowledgeByCanonicalTaxonId(species);
    this.species = await this.speciesRepository.listAll();
  }

  private openDiscovery(discoveryId: string): void {
    this.discoveryReturnRoute = this.route;
    this.selectedDiscoveryId = discoveryId;
    this.route = AppRoute.DISCOVERY_DETAIL;
  }

  private returnToPreviousRoute(): void {
    this.changeRoute(this.previousRoute === AppRoute.SPECIES_DETAIL ? AppRoute.DISCOVER : this.previousRoute);
  }

  private closeDiscoveryDetail(): void {
    this.changeRoute(this.discoveryReturnRoute);
  }

  private changeRoute(route: AppRoute): void {
    this.route = route;
    if (route === AppRoute.ATLAS) {
      this.primaryTabIndex = 0;
    } else if (route === AppRoute.DISCOVER) {
      this.primaryTabIndex = 1;
    } else if (route === AppRoute.PROFILE) {
      this.primaryTabIndex = 2;
    }
  }

  private changePrimaryTab(index: number): void {
    this.primaryTabIndex = index;
    if (index === 0) {
      this.route = AppRoute.ATLAS;
    } else if (index === 1) {
      this.route = AppRoute.DISCOVER;
    } else {
      this.route = AppRoute.PROFILE;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        if (this.route === AppRoute.IDENTIFICATION_RESULT) {
          IdentificationResultPage({
            state: this.identificationState,
            result: this.identificationResult,
            photoUri: this.selectedPhotoUri,
            isTakingLong: this.identificationTakingLong,
            failureMessage: this.identificationFailureMessage,
            onBack: () => this.changeRoute(AppRoute.DISCOVER),
            onRetry: () => this.retryIdentification(),
            onCollect: () => this.collectDiscovery()
          })
        } else if (this.route === AppRoute.SPECIES_DETAIL) {
          SpeciesDetailPage({
            species: this.selectedSpecies(),
            discoveries: this.discoveriesForSelectedSpecies(),
            onRefreshKnowledge: () => this.refreshSelectedSpeciesKnowledge(),
            onBack: () => this.returnToPreviousRoute(),
            onOpenDiscovery: (discoveryId: string) => this.openDiscovery(discoveryId)
          })
        } else if (this.route === AppRoute.DISCOVERY_DETAIL) {
          DiscoveryDetailPage({
            discovery: this.selectedDiscovery(),
            species: this.selectedSpecies(),
            onBack: () => this.closeDiscoveryDetail()
          })
        } else if (this.route === AppRoute.MY_ATLAS) {
          MyAtlasPage({
            species: this.atlasSpecies(),
            summaries: this.summaries(),
            onBack: () => this.changeRoute(AppRoute.ATLAS),
            onOpenSpecies: (speciesId: string) => this.openSpecies(speciesId)
          })
        } else {
          HdsTabs({ index: this.primaryTabIndex, controller: this.primaryTabsController }) {
              TabContent() {
                AtlasPage({
                  species: this.atlasSpecies(),
                  summaries: this.summaries(),
                  onOpenSpecies: (speciesId: string) => this.openSpecies(speciesId),
                  onOpenAll: () => this.changeRoute(AppRoute.MY_ATLAS)
                })
              }
              .tabBar(this.tabBarStyle(this.atlasTabSymbol, '图鉴'))

              TabContent() {
                DiscoverPage({
                  heroPhotoUri: this.selectedPhotoUri,
                  species: this.species,
                  recentDiscoveries: this.recentDiscoveries(),
                  notice: this.discoveryNotice,
                  onPickFromAlbum: () => this.pickPhotoFromAlbum(),
                  onTakePhoto: () => this.takePhoto(),
                  onNavigate: (route: AppRoute) => this.changeRoute(route),
                  onOpenSpecies: (speciesId: string) => this.openSpecies(speciesId)
                })
              }
              .tabBar(this.tabBarStyle(this.discoverTabSymbol, '发现'))

              TabContent() {
                ProfilePage({ onReloadLocalData: () => this.reloadLocalDataAfterSettingsClear(), onAppearanceChanged: (mode: AppearanceMode) => this.applyAppearance(mode), onPrivacyConsentRevoked: () => this.revokePrivacyConsent() })
              }
              .tabBar(this.tabBarStyle(this.profileTabSymbol, '设置'))
            }
            .width('100%')
            .height('100%')
            // Official HDS floating-tabs requirements for HarmonyOS 6.1.
            .barOverlap(true)
            .barPosition(BarPosition.End)
            .vertical(false)
            .scrollable(false)
            .barFloatingStyle({
              barWidth: { smallWidth: 228, mediumWidth: 284, largeWidth: 328 },
              barBottomMargin: 20,
              systemMaterialEffect: {
                materialType: hdsMaterial.MaterialType.IMMERSIVE,
                materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
              }
            })
            .onChange((index: number) => this.changePrimaryTab(index))
        }
      }
      .width('100%')
      .height('100%')
      .opacity(this.appearanceRevision >= 0 ? 1 : 1)
      .backgroundColor(AppColors.PAPER)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      if (this.privacyConsentReady && this.privacyConsentVisible) {
        Column() {
          Column({ space: 14 }) {
            Text('隐私保护提示')
              .width('100%')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.INK)
            Text('使用植物图片识别前，见野会处理你主动选择的单张图片，并通过 HTTPS 发送到 WildSight 后端，再由后端调用百度智能云植物识别服务。随机安装标识仅用于每日识别次数控制。')
              .width('100%')
              .fontSize(AppTypography.BODY_SIZE)
              .lineHeight(24)
              .fontColor(AppColors.INK_MUTED)
            Text('你可以暂不同意并继续浏览不需要识别的本地功能；完整内容请查看“设置 > 权限与隐私 > 隐私政策”。')
              .width('100%')
              .fontSize(AppTypography.META_SIZE)
              .lineHeight(19)
              .fontColor(AppColors.INK_MUTED)
            Row({ space: 10 }) {
              Button('暂不同意')
                .layoutWeight(1)
                .height(44)
                .fontSize(AppTypography.BODY_SIZE)
                .fontColor(AppColors.INK)
                .backgroundColor(AppColors.SURFACE_MUTED)
                .borderRadius(AppDimensions.RADIUS_SMALL)
                .onClick(() => this.declinePrivacyConsent())
              Button('同意并继续')
                .layoutWeight(1)
                .height(44)
                .fontSize(AppTypography.BODY_SIZE)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppColors.ACTION_ON_PRIMARY)
                .backgroundColor(AppColors.ACTION_PRIMARY)
                .borderRadius(AppDimensions.RADIUS_SMALL)
                .onClick(() => this.acceptPrivacyConsent())
            }
            .width('100%')
          }
          .width('88%')
          .padding(20)
          .backgroundColor(AppColors.PAPER_ELEVATED)
          .borderRadius(AppDimensions.SETTINGS_GROUP_RADIUS)
          .shadow({ radius: 18, color: AppColors.FLOATING_SHADOW, offsetY: 6 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor(AppColors.PHOTO_OVERLAY)
        .onClick(() => { })
      }
    }
    .width('100%')
    .height('100%')
  }

  private async reloadLocalDataAfterSettingsClear(): Promise<void> {
    this.discoveries = await this.discoveryRepository.listAll();
    this.species = await this.speciesRepository.listAll();
  }

  private applyAppearance(mode: AppearanceMode): void {
    const systemDark = (getContext(this) as common.UIAbilityContext).config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    const dark = mode === AppearanceMode.DARK || (mode === AppearanceMode.SYSTEM && systemDark);
    AppColors.apply(dark);
    this.applyTabBarSymbolColors();
    this.syncSystemBars(dark);
    this.appearanceRevision += 1;
  }

  private syncSystemBars(dark: boolean): void {
    window.getLastWindow(getContext(this) as common.UIAbilityContext)
      .then((mainWindow: window.Window) => mainWindow.setWindowSystemBarProperties({
        // The app surface is drawn under both system bars so light and dark modes
        // share one continuous paper/green-black canvas.
        statusBarColor: '#00000000',
        navigationBarColor: '#00000000',
        statusBarContentColor: dark ? '#FFFFFFFF' : '#FF1E251F',
        navigationBarContentColor: dark ? '#FFFFFFFF' : '#FF1E251F',
        isStatusBarLightIcon: dark,
        isNavigationBarLightIcon: dark
      }))
      .catch(() => {
        // A system bar capability can be unavailable on a particular device; page content remains usable.
      });
  }
}
