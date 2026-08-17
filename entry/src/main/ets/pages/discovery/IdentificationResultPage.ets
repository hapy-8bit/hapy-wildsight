import { AppColors } from '../../constants/AppColors';
import { AppDimensions } from '../../constants/AppDimensions';
import { AppSpacing } from '../../constants/AppSpacing';
import { AppTypography } from '../../constants/AppTypography';
import { PhotoFrame } from '../../components/PhotoFrame';
import { IdentificationMatch, IdentificationResult } from '../../models/IdentificationResult';
import { IdentificationState } from '../../models/IdentificationState';

@Component
export struct IdentificationResultPage {
  @Prop state: IdentificationState = IdentificationState.IDLE;
  @Prop result: IdentificationResult = new IdentificationResult();
  @Prop photoUri: string = '';
  @Prop isTakingLong: boolean = false;
  @Prop failureMessage: string = '';
  @BuilderParam onBack: () => void;
  @BuilderParam onRetry: () => void;
  @BuilderParam onCollect: () => void;

  private taxonomyLine(): string {
    const parts: string[] = [];
    if (this.result.primaryMatch.family !== undefined && this.result.primaryMatch.family.length > 0) {
      parts.push(this.result.primaryMatch.family);
    }
    if (this.result.primaryMatch.genus !== undefined && this.result.primaryMatch.genus.length > 0) {
      parts.push(this.result.primaryMatch.genus);
    }
    return parts.join(' · ');
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.LG }) {
        Row() {
          Text('‹ 返回')
            .fontSize(14)
            .fontColor(AppColors.INK_MUTED)
            .onClick(() => this.onBack())
          Blank()
        }
        .width('100%')

        if (this.state === IdentificationState.IDENTIFYING) {
          Column({ space: AppSpacing.LG }) {
            Text('正在辨认')
              .fontSize(AppTypography.HERO_SIZE)
              .fontFamily(AppTypography.DISPLAY_FONT)
              .fontColor(AppColors.INK)
            Text(this.isTakingLong ? '正在仔细辨认这株植物…' : '让我们先仔细看看这片花与叶。')
              .fontSize(AppTypography.BODY_SIZE)
              .fontColor(AppColors.INK_MUTED)
            PhotoFrame({ uri: this.photoUri, frameHeight: 360 })
            Text(this.isTakingLong ? '仍在比对植物特征…' : '正在比对植物特征…')
              .fontSize(AppTypography.META_SIZE)
              .fontFamily(AppTypography.MONO_FONT)
              .fontColor(AppColors.OBSERVATION)
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: AppSpacing.MD, bottom: AppSpacing.MD })
              .border({ width: { top: AppDimensions.HAIRLINE, bottom: AppDimensions.HAIRLINE }, color: AppColors.DIVIDER })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        } else if (this.state === IdentificationState.SUCCESS) {
          Column({ space: AppSpacing.LG }) {
            Column({ space: AppSpacing.XS }) {
              Text('你遇见了')
                .fontSize(AppTypography.HERO_SIZE)
                .fontFamily(AppTypography.DISPLAY_FONT)
                .fontColor(AppColors.INK)
              Text('一次新的自然相遇，已经有了名字。')
                .fontSize(AppTypography.BODY_SIZE)
                .fontColor(AppColors.INK_MUTED)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            PhotoFrame({ uri: this.photoUri, frameHeight: 320 })

            Column({ space: AppSpacing.XS }) {
              Text('本次识别')
                .fontSize(AppTypography.META_SIZE)
                .fontColor(AppColors.INK_MUTED)
                .letterSpacing(0.5)
              Text(this.result.primaryMatch.displayName)
                .fontSize(30)
                .fontFamily(AppTypography.DISPLAY_FONT)
                .fontColor(AppColors.INK)
              if (this.result.primaryMatch.scientificName !== undefined && this.result.primaryMatch.scientificName.length > 0) {
                Text(this.result.primaryMatch.scientificName)
                  .fontSize(15)
                  .fontStyle(FontStyle.Italic)
                  .fontColor(AppColors.INK_MUTED)
              }
              if (this.taxonomyLine().length > 0) {
                Text(this.taxonomyLine())
                  .fontSize(AppTypography.META_SIZE)
                  .fontColor(AppColors.INK_MUTED)
              }
              Text(`本次识别匹配度 · ${Math.round(this.result.primaryMatch.confidence * 100)}%`)
                .fontSize(AppTypography.META_SIZE)
                .fontColor(AppColors.INK_MUTED)
              if (this.result.primaryMatch.description !== undefined && this.result.primaryMatch.description.length > 0) {
                Text(this.result.primaryMatch.description)
                  .fontSize(AppTypography.BODY_SIZE)
                  .fontColor(AppColors.INK_MUTED)
                  .lineHeight(23)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .padding({ top: AppSpacing.XS })
              }
            }
            .width('100%')
            .padding(AppSpacing.LG)
            .backgroundColor(AppColors.SURFACE_PRIMARY)
            .border({ width: AppDimensions.HAIRLINE, color: AppColors.BORDER_SOFT })
            .borderRadius(AppDimensions.RADIUS_LARGE)
            .shadow({ radius: 5, color: AppColors.CARD_SHADOW, offsetY: 2 })
            .alignItems(HorizontalAlign.Start)

            Text('收入我的图鉴')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.ACTION_ON_PRIMARY)
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: AppSpacing.MD, bottom: AppSpacing.MD })
              .backgroundColor(AppColors.ACTION_PRIMARY)
              .borderRadius(AppDimensions.RADIUS_MEDIUM)
              .onClick(() => this.onCollect())

            Row() {
              Text('重新识别')
                .fontSize(14)
                .fontColor(AppColors.INK)
                .onClick(() => this.onRetry())
              Blank()
            }
            .width('100%')
            .padding({ top: AppSpacing.XS, bottom: AppSpacing.XS })

            if (this.result.alternativeMatches.length > 0) {
              Column({ space: AppSpacing.SM }) {
                Text('其他可能')
                  .fontSize(11)
                  .fontColor(AppColors.INK_MUTED)
                  .letterSpacing(1)
                ForEach(this.result.alternativeMatches, (match: IdentificationMatch, index: number) => {
                  Row() {
                    Column({ space: AppSpacing.XXS }) {
                      Text(match.displayName)
                        .fontSize(15)
                        .fontColor(AppColors.INK)
                    }
                    .alignItems(HorizontalAlign.Start)
                    Blank()
                    Text(`${Math.round(match.confidence * 100)}%`)
                      .fontSize(12)
                      .fontColor(AppColors.INK_MUTED)
                  }
                  .width('100%')
                  .padding({ top: AppSpacing.SM, bottom: AppSpacing.SM })
                  .border({ width: { bottom: AppDimensions.HAIRLINE }, color: AppColors.DIVIDER })
                }, (match: IdentificationMatch, index: number) => `${match.displayName}-${index}`)
              }
              .width('100%')
              .padding({ top: AppSpacing.MD })
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        } else if (this.state === IdentificationState.LOW_CONFIDENCE) {
          Column({ space: AppSpacing.MD }) {
            Text('这次还不太确定')
              .fontSize(AppTypography.HERO_SIZE)
              .fontFamily(AppTypography.DISPLAY_FONT)
              .fontColor(AppColors.INK)
            Text('换个角度再试试，尽量让植物主体占据画面。')
              .fontSize(AppTypography.BODY_SIZE)
              .fontColor(AppColors.INK_MUTED)
              .lineHeight(24)
            PhotoFrame({ uri: this.photoUri, frameHeight: 300 })
            Text('重新识别')
              .fontSize(16)
              .fontColor(AppColors.ACTION_ON_PRIMARY)
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: AppSpacing.MD, bottom: AppSpacing.MD })
              .backgroundColor(AppColors.ACTION_PRIMARY)
              .borderRadius(AppDimensions.RADIUS_SUBTLE)
              .onClick(() => this.onRetry())
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        } else if (this.state === IdentificationState.LIMIT_REACHED) {
          Column({ space: AppSpacing.MD }) {
            Text('今天先把目光留给身边')
              .fontSize(AppTypography.HERO_SIZE)
              .fontFamily(AppTypography.DISPLAY_FONT)
              .fontColor(AppColors.INK)
            Text(this.failureMessage.length > 0 ? this.failureMessage : '今天的识别次数已用完，明天再来看看吧。')
              .fontSize(AppTypography.BODY_SIZE)
              .fontColor(AppColors.INK_MUTED)
              .lineHeight(24)
            PhotoFrame({ uri: this.photoUri, frameHeight: 300 })
            Text('返回发现')
              .fontSize(16)
              .fontColor(AppColors.ACTION_ON_PRIMARY)
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: AppSpacing.MD, bottom: AppSpacing.MD })
              .backgroundColor(AppColors.ACTION_PRIMARY)
              .borderRadius(AppDimensions.RADIUS_SUBTLE)
              .onClick(() => this.onBack())
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        } else {
          Column({ space: AppSpacing.MD }) {
            Text('这一次还没有名字')
              .fontSize(AppTypography.HERO_SIZE)
              .fontFamily(AppTypography.DISPLAY_FONT)
              .fontColor(AppColors.INK)
            Text(this.failureMessage.length > 0 ? this.failureMessage : '换一张更清晰的照片，再试一次。')
              .fontSize(AppTypography.BODY_SIZE)
              .fontColor(AppColors.INK_MUTED)
            Text('重新识别')
              .fontSize(16)
              .fontColor(AppColors.ACTION_ON_PRIMARY)
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: AppSpacing.MD, bottom: AppSpacing.MD })
              .backgroundColor(AppColors.ACTION_PRIMARY)
              .borderRadius(AppDimensions.RADIUS_SUBTLE)
              .onClick(() => this.onRetry())
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
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
