import { AppColors } from './AppColors';

/** Typography avoids a dashboard feel: display type is editorial, metadata is quiet. */
export class AppTypography {
  static readonly DISPLAY_FONT: string = 'serif';
  static readonly BODY_FONT: string = 'sans-serif';
  static readonly MONO_FONT: string = 'monospace';
  static readonly HERO_SIZE: number = 40;
  static readonly PAGE_TITLE_SUBTITLE_SIZE: number = 15;
  static readonly PAGE_TITLE_SUBTITLE_LINE_HEIGHT: number = 22;
  static readonly SECONDARY_PAGE_TITLE_SIZE: number = 22;
  static readonly SECONDARY_PAGE_TITLE_WEIGHT: FontWeight = FontWeight.Bold;
  static readonly SECTION_TITLE_SIZE: number = 20;
  static readonly CARD_TITLE_SIZE: number = 19;
  static readonly BODY_SIZE: number = 15;
  static readonly META_SIZE: number = 12;
  static readonly CAPTION_SIZE: number = 10;
  static readonly MICRO_SIZE: number = 9;
  static readonly NAV_SIZE: number = 11;
  static readonly PRIMARY_COLOR: string = AppColors.INK;
  static readonly SECONDARY_COLOR: string = AppColors.INK_MUTED;
}
