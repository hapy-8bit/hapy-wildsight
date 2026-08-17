import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { camera, cameraPicker } from '@kit.CameraKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

/** Native photo-selection and camera-capture boundary. */
export class PhotoService {
  async selectPhoto(): Promise<string | undefined> {
    const options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = 1;

    const picker = new photoAccessHelper.PhotoViewPicker();
    const result = await picker.select(options);
    return result.photoUris.length > 0 ? result.photoUris[0] : undefined;
  }

  async capturePhoto(context: common.UIAbilityContext): Promise<string | undefined> {
    try {
      const profile = new cameraPicker.PickerProfile();
      profile.cameraPosition = camera.CameraPosition.CAMERA_POSITION_BACK;
      const result = await cameraPicker.pick(
        context,
        [cameraPicker.PickerMediaType.PHOTO],
        profile
      );
      return result.resultUri.length > 0 ? result.resultUri : undefined;
    } catch (error) {
      console.error(`CameraKit picker failed: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  /** Request the declared camera permission immediately before opening CameraPicker. */
  async requestCameraPermission(context: common.UIAbilityContext): Promise<boolean> {
    const manager = abilityAccessCtrl.createAtManager();
    const result = await manager.requestPermissionsFromUser(context, ['ohos.permission.CAMERA']);
    return result.authResults.length > 0 &&
      result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  }
}
