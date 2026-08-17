import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { camera, cameraPicker } from '@kit.CameraKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import fileIo from '@ohos.file.fs';
import fileUri from '@ohos.file.fileuri';

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
    const destinationPath = `${context.filesDir}/camera-${Date.now()}.jpg`;
    const destinationFile = fileIo.createRandomAccessFileSync(destinationPath, fileIo.OpenMode.CREATE);
    fileIo.closeSync(destinationFile.fd);
    const profile = new cameraPicker.PickerProfile();
    profile.cameraPosition = camera.CameraPosition.CAMERA_POSITION_BACK;
    profile.saveUri = fileUri.getUriFromPath(destinationPath);
    const result = await cameraPicker.pick(
      context,
      [cameraPicker.PickerMediaType.PHOTO],
      profile
    );
    console.info(`CameraKit picker result: code=${result.resultCode}, uriLength=${result.resultUri.length}`);
    return result.resultUri.length > 0 ? result.resultUri : undefined;
  }

  /** Request the declared camera permission immediately before opening CameraPicker. */
  async requestCameraPermission(context: common.UIAbilityContext): Promise<boolean> {
    const manager = abilityAccessCtrl.createAtManager();
    const result = await manager.requestPermissionsFromUser(context, ['ohos.permission.CAMERA']);
    return result.authResults.length > 0 &&
      result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  }
}
