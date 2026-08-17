export class AppDimensions {
  static readonly PAGE_HORIZONTAL: number = 20;
  static readonly CONTENT_MAX_WIDTH: number = 680;
  static readonly BOTTOM_NAV_HEIGHT: number = 60;
  static readonly BOTTOM_NAV_MARGIN: number = 10;
  static readonly MAIN_TITLE_TOP_INSET: number = 32;
  // Keep the title block identical across the three primary tabs, including the settings header.
  static readonly MAIN_TITLE_BLOCK_HEIGHT: number = 100;
  static readonly MAIN_TITLE_SUBTITLE_GAP: number = 6;
  static readonly MAIN_TITLE_CONTENT_GAP: number = 20;
  // Compact secondary toolbar: a 48vp control with 4vp breathing room above and below.
  static readonly SECONDARY_PAGE_HEADER_HEIGHT: number = 56;
  static readonly SECONDARY_PAGE_CONTENT_TOP_INSET: number = 68;
  // HdsTabs overlaps its content; scrollable primary-tab pages reserve this visual/safe-area space.
  static readonly PRIMARY_TABS_CONTENT_INSET: number = 120;
  // Settings follows the compact grouped-card language used by the reference app.
  static readonly SETTINGS_HEADER_HEIGHT: number = AppDimensions.MAIN_TITLE_BLOCK_HEIGHT;
  static readonly SETTINGS_CONTENT_TOP_INSET: number = AppDimensions.MAIN_TITLE_BLOCK_HEIGHT;
  static readonly SETTINGS_CONTENT_BOTTOM_INSET: number = 132;
  static readonly SETTINGS_GROUP_SPACE: number = 10;
  static readonly SETTINGS_GROUP_RADIUS: number = 16;
  static readonly SETTINGS_ROW_HEIGHT: number = 56;
  static readonly SETTINGS_ROW_HORIZONTAL_PADDING: number = 16;
  static readonly SETTINGS_ICON_SIZE: number = 34;
  static readonly SETTINGS_ICON_SYMBOL_SIZE: number = 19;
  static readonly SETTINGS_CHEVRON_SIZE: number = 26;
  static readonly SETTINGS_CHEVRON_WIDTH: number = 18;
  static readonly SETTINGS_CHEVRON_HEIGHT: number = 28;
  static readonly SETTINGS_DIVIDER_LEFT_MARGIN: number = 62;
  static readonly SETTINGS_DIVIDER_RIGHT_MARGIN: number = 16;
  static readonly PHOTO_HERO_RATIO: number = 1.18;
  static readonly PHOTO_CARD_RATIO: number = 0.8;
  static readonly PHOTO_OBSERVATION_RATIO: number = 1.35;
  static readonly HAIRLINE: number = 1;
  static readonly RADIUS_NONE: number = 0;
  static readonly RADIUS_SUBTLE: number = 10;
  static readonly RADIUS_SMALL: number = 12;
  static readonly RADIUS_MEDIUM: number = 16;
  static readonly RADIUS_LARGE: number = 24;
  static readonly RADIUS_HERO: number = 28;
  static readonly CARD_SHADOW_RADIUS: number = 10;
  static readonly FLOATING_SHADOW_RADIUS: number = 14;
}
