import { AppColors } from '../constants/AppColors';

@Component
export struct ObservationCode {
  @Prop code: string = '';

  build() {
    Text(this.code)
      .fontSize(10)
      .fontColor(AppColors.OBSERVATION)
      .fontFamily('monospace')
      .letterSpacing(0.8)
  }
}
