import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';
import { IdentificationMatch, IdentificationResult, SpeciesKnowledge } from '../models/IdentificationResult';
import { IdentificationErrorCode, IdentificationRequestError } from '../models/IdentificationRequestError';
import { IdentificationService } from './IdentificationService';

class MultipartBody {
  boundary: string = '';
  body: ArrayBuffer = new ArrayBuffer(0);
}

/**
 * Calls only the WildSight backend. It has no Baidu-specific imports, response
 * parsing, keys or tokens, so the backend provider can change independently.
 */
export class RemoteIdentificationService implements IdentificationService {
  // The picker grants a scoped temporary URI. The backend Base64 payload limit
  // is 4 MB, so encode larger originals to a conservative 2 MB JPEG first.
  private static readonly MAX_UPLOAD_BYTES: number = 2 * 1024 * 1024;
  private static readonly MAX_IMAGE_DIMENSION: number = 1600;
  private static readonly JPEG_QUALITIES: number[] = [85, 72, 60, 48];
  private readonly endpoint: string;

  constructor(endpoint: string) {
    this.endpoint = endpoint;
  }

  async identify(photoUri: string, installationId: string): Promise<IdentificationResult> {
    if (this.endpoint.length === 0) {
      throw new Error('Remote identification endpoint is not configured.');
    }
    const request = http.createHttp();
    try {
      const image = await this.readPickerPhoto(photoUri);
      hilog.info(0x0000, 'WildSightIdentify', 'picker photo read: %{public}d bytes', image.byteLength);
      const multipart = this.createMultipartBody(image);
      const response = await request.request(`${this.endpoint}/api/v1/identification/plant`, {
        method: http.RequestMethod.POST,
        extraData: multipart.body,
        expectDataType: http.HttpDataType.STRING,
        header: {
          'Content-Type': `multipart/form-data; boundary=${multipart.boundary}`,
          'X-WildSight-Installation-Id': installationId
        },
        connectTimeout: 10000,
        readTimeout: 15000
      });
      hilog.info(0x0000, 'WildSightIdentify', 'backend response: %{public}d', response.responseCode);
      if (typeof response.result !== 'string') {
        throw new IdentificationRequestError(IdentificationErrorCode.SERVER_ERROR, '识别服务暂时不可用。');
      }
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw this.parseErrorResponse(response.result);
      }
      return this.parseResponse(response.result);
    } catch (error) {
      if (error instanceof IdentificationRequestError) {
        throw error;
      }
      const message = this.errorMessage(error);
      hilog.error(0x0000, 'WildSightIdentify', 'identification failed: %{public}s', message);
      throw new IdentificationRequestError(IdentificationErrorCode.NETWORK_UNAVAILABLE, '网络暂时不可用。');
    } finally {
      request.destroy();
    }
  }

  private errorMessage(error: Object): string {
    if (error instanceof Error) {
      return error.message;
    }
    if (typeof error === 'object' && error !== null) {
      const message = Reflect.get(error, 'message') as Object;
      const code = Reflect.get(error, 'code') as Object;
      if (typeof message === 'string' && typeof code === 'number') {
        return `${code}: ${message}`;
      }
      if (typeof message === 'string') {
        return message;
      }
      if (typeof code === 'number') {
        return `error code ${code}`;
      }
    }
    return 'unknown error';
  }

  private async readPickerPhoto(photoUri: string): Promise<ArrayBuffer> {
    const file = fileIo.openSync(photoUri, fileIo.OpenMode.READ_ONLY);
    let source: image.ImageSource | undefined = undefined;
    let packer: image.ImagePacker | undefined = undefined;
    let pixelMap: image.PixelMap | undefined = undefined;
    try {
      const stat = fileIo.statSync(file.fd);
      if (stat.size <= 0) {
        throw new Error('The selected image is empty.');
      }
      if (stat.size <= RemoteIdentificationService.MAX_UPLOAD_BYTES) {
        return this.readFile(file, stat.size);
      }

      // The picker URI itself is not accepted by ImageSource on some devices.
      // Its opened file descriptor is, and keeps this conversion scoped to the
      // image that the user explicitly selected.
      source = image.createImageSource(file.fd);
      if (source === undefined) {
        throw new Error('The selected image could not be decoded.');
      }
      const info = await source.getImageInfo();
      const width = info.size.width;
      const height = info.size.height;
      if (width <= 0 || height <= 0) {
        throw new Error('The selected image has invalid dimensions.');
      }
      const longestSide = Math.max(width, height);
      const scale = Math.min(1, RemoteIdentificationService.MAX_IMAGE_DIMENSION / longestSide);
      pixelMap = await source.createPixelMap({
        desiredSize: {
          width: Math.max(1, Math.round(width * scale)),
          height: Math.max(1, Math.round(height * scale))
        }
      });
      packer = image.createImagePacker();
      if (packer === undefined) {
        throw new Error('The selected image could not be prepared.');
      }
      for (const quality of RemoteIdentificationService.JPEG_QUALITIES) {
        const jpeg = await packer.packing(pixelMap, { format: 'image/jpeg', quality: quality });
        if (jpeg.byteLength > 0 && jpeg.byteLength <= RemoteIdentificationService.MAX_UPLOAD_BYTES) {
          return jpeg;
        }
      }
      throw new Error('The selected image is too large to upload.');
    } finally {
      if (pixelMap !== undefined) {
        await pixelMap.release();
      }
      if (packer !== undefined) {
        await packer.release();
      }
      if (source !== undefined) {
        await source.release();
      }
      fileIo.closeSync(file);
    }
  }

  private readFile(file: fileIo.File, size: number): ArrayBuffer {
    const content = new ArrayBuffer(size);
    const bytesRead = fileIo.readSync(file.fd, content);
    if (bytesRead <= 0) {
      throw new Error('The selected image could not be read.');
    }
    return bytesRead === content.byteLength ? content : content.slice(0, bytesRead);
  }

  private createMultipartBody(image: ArrayBuffer): MultipartBody {
    const boundary = `----WildSight${Date.now().toString(16)}`;
    const encoder = new util.TextEncoder();
    const prefix = encoder.encodeInto(`--${boundary}\r\nContent-Disposition: form-data; name="image"; filename="plant.jpg"\r\nContent-Type: image/jpeg\r\n\r\n`);
    const suffix = encoder.encodeInto(`\r\n--${boundary}--\r\n`);
    const body = new Uint8Array(prefix.length + image.byteLength + suffix.length);
    body.set(prefix, 0);
    body.set(new Uint8Array(image), prefix.length);
    body.set(suffix, prefix.length + image.byteLength);
    const multipart = new MultipartBody();
    multipart.boundary = boundary;
    const requestBody = new ArrayBuffer(body.length);
    new Uint8Array(requestBody).set(body);
    multipart.body = requestBody;
    return multipart;
  }

  private parseResponse(text: string): IdentificationResult {
    // ArkTS deliberately does not allow structural casts from JSON objects to a
    // custom class. Read the stable backend contract field-by-field instead.
    const response = JSON.parse(text) as Object;
    const successValue: Object = Reflect.get(response, 'success') as Object;
    const providerValue: Object = Reflect.get(response, 'provider') as Object;
    const primary: Object = Reflect.get(response, 'primary') as Object;
    const success = typeof successValue === 'boolean' ? successValue as boolean : false;
    const provider = typeof providerValue === 'string' ? providerValue as string : '';
    if (!success || primary === undefined || this.readString(primary, 'name').length === 0) {
      throw new Error('No identification match was returned.');
    }
    const result = new IdentificationResult();
    result.provider = provider;
    result.primaryMatch = this.toMatch(primary, provider);
    const alternativesValue: Object = Reflect.get(response, 'alternatives') as Object;
    const alternatives: Object[] = Array.isArray(alternativesValue) ? alternativesValue as Object[] : [];
    result.alternativeMatches = Array.isArray(alternatives)
      ? alternatives.map((match: Object) => this.toMatch(match, provider))
      : [];
    return result;
  }

  private parseErrorResponse(text: string): IdentificationRequestError {
    try {
      const response = JSON.parse(text) as Object;
      const error = Reflect.get(response, 'error') as Object;
      const code = error !== undefined ? this.readString(error, 'code') : this.readString(response, 'code');
      const message = error !== undefined ? this.readString(error, 'message') : this.readString(response, 'message');
      if (code === IdentificationErrorCode.DAILY_LIMIT_REACHED) {
        return new IdentificationRequestError(IdentificationErrorCode.DAILY_LIMIT_REACHED, message);
      }
      if (code === 'INVALID_IMAGE' || code === 'IMAGE_REQUIRED' || code === 'UNSUPPORTED_IMAGE' || code === 'IMAGE_TOO_LARGE') {
        return new IdentificationRequestError(IdentificationErrorCode.INVALID_IMAGE, message);
      }
      if (code === IdentificationErrorCode.UPSTREAM_TIMEOUT) {
        return new IdentificationRequestError(IdentificationErrorCode.UPSTREAM_TIMEOUT, message);
      }
      if (code === 'NO_MATCH' || code === IdentificationErrorCode.IDENTIFICATION_FAILED) {
        return new IdentificationRequestError(IdentificationErrorCode.IDENTIFICATION_FAILED, message);
      }
    } catch (_error) {
      // A non-JSON proxy response is still a recoverable server failure.
    }
    return new IdentificationRequestError(IdentificationErrorCode.SERVER_ERROR, '识别服务暂时不可用。');
  }

  private toMatch(source: Object, provider: string): IdentificationMatch {
    const match = new IdentificationMatch();
    match.displayName = this.readString(source, 'name');
    match.confidence = this.readNumber(source, 'confidence');
    match.description = this.readOptionalString(source, 'description');
    match.referenceImageUrl = this.readOptionalString(source, 'referenceImageUrl');
    match.canonicalSpeciesId = this.readOptionalString(source, 'canonicalSpeciesId');
    match.knowledgeMatch = this.readOptionalString(source, 'knowledgeMatch');
    match.knowledgeReviewStatus = this.readOptionalString(source, 'knowledgeReviewStatus');
    const knowledge = Reflect.get(source, 'knowledge') as Object;
    if (knowledge !== undefined && typeof knowledge === 'object') {
      match.knowledge = this.toKnowledge(knowledge);
    }
    match.provider = provider;
    return match;
  }

  private toKnowledge(source: Object): SpeciesKnowledge {
    const knowledge = new SpeciesKnowledge();
    knowledge.acceptedChineseName = this.readString(source, 'acceptedChineseName');
    knowledge.scientificName = this.readString(source, 'scientificName');
    knowledge.family = this.readString(source, 'family');
    knowledge.genus = this.readString(source, 'genus');
    knowledge.aliases = this.readStringArray(source, 'aliases');
    knowledge.summary = this.readString(source, 'summary');
    knowledge.identificationReferences = this.readStringArray(source, 'identificationReferences');
    knowledge.howToConfirm = this.readStringArray(source, 'howToConfirm');
    knowledge.appearance = this.readString(source, 'appearance');
    knowledge.growthHabit = this.readString(source, 'growthHabit');
    knowledge.keyCharacteristics = this.readStringArray(source, 'keyCharacteristics');
    knowledge.observationTips = this.readStringArray(source, 'observationTips');
    knowledge.confusableSpecies = this.readStringArray(source, 'confusableSpecies');
    knowledge.observationReminder = this.readString(source, 'observationReminder');
    knowledge.contentVersion = this.readNumber(source, 'contentVersion');
    return knowledge;
  }

  private readStringArray(source: Object, key: string): string[] {
    const value: Object = Reflect.get(source, key) as Object;
    if (!Array.isArray(value)) {
      return [];
    }
    return (value as Object[]).filter((item: Object) => typeof item === 'string').map((item: Object) => item as string);
  }

  private readString(source: Object, key: string): string {
    const value: Object = Reflect.get(source, key) as Object;
    return typeof value === 'string' ? value as string : '';
  }

  private readNumber(source: Object, key: string): number {
    const value: Object = Reflect.get(source, key) as Object;
    return typeof value === 'number' ? value as number : 0;
  }

  private readOptionalString(source: Object, key: string): string | undefined {
    const value: Object = Reflect.get(source, key) as Object;
    return typeof value === 'string' && (value as string).length > 0 ? value as string : undefined;
  }
}
