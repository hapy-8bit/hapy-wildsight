import sharp from 'sharp';
import { ApiError } from './errors.js';

const PLANT_URL = 'https://aip.baidubce.com/rest/2.0/image-classify/v1/plant';
const ALLOWED_MIME_TYPES = new Set(['image/jpeg', 'image/png', 'image/bmp']);

/** Adapts Baidu's provider response into WildSight's provider-neutral contract. */
export class BaiduPlantProvider {
  constructor(tokenManager, config, fetchImpl = fetch) {
    this.tokenManager = tokenManager;
    this.config = config;
    this.fetchImpl = fetchImpl;
  }

  async identify(upload) {
    this.validateUpload(upload);
    const normalizedImage = await this.normalizeImage(upload.buffer);
    const accessToken = await this.tokenManager.getAccessToken();
    const url = new URL(PLANT_URL);
    url.searchParams.set('access_token', accessToken);

    const form = new URLSearchParams();
    form.set('image', normalizedImage.toString('base64'));
    form.set('baike_num', '1');

    let response;
    try {
      response = await this.fetchImpl(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: form,
        signal: AbortSignal.timeout(this.config.providerTimeoutMs ?? 12_000)
      });
    } catch (error) {
      if (error?.name === 'TimeoutError' || error?.name === 'AbortError') {
        throw new ApiError(504, 'UPSTREAM_TIMEOUT', '识别服务响应较慢，请稍后再试。');
      }
      throw new ApiError(502, 'SERVER_ERROR', '识别服务暂时不可用，请稍后再试。');
    }

    let payload;
    try {
      payload = await response.json();
    } catch {
      throw new ApiError(502, 'SERVER_ERROR', '识别服务暂时不可用，请稍后再试。');
    }
    if (!response.ok || payload.error_code) {
      throw new ApiError(502, 'SERVER_ERROR', '识别服务暂时不可用，请稍后再试。');
    }
    return BaiduPlantProvider.toContract(payload);
  }

  validateUpload(upload) {
    if (!upload || !upload.buffer || upload.size === 0) {
      throw new ApiError(400, 'IMAGE_REQUIRED', '请选择一张植物照片。');
    }
    if (!ALLOWED_MIME_TYPES.has(upload.mimetype)) {
      throw new ApiError(415, 'UNSUPPORTED_IMAGE', '请使用 JPG、PNG 或 BMP 格式的图片。');
    }
    if (upload.size > this.config.maxUploadBytes) {
      throw new ApiError(413, 'IMAGE_TOO_LARGE', '图片过大，请选择小于 8MB 的图片。');
    }
  }

  async normalizeImage(input) {
    let output;
    try {
      output = await sharp(input)
        .rotate()
        .resize({ width: 2048, height: 2048, fit: 'inside', withoutEnlargement: true })
        .jpeg({ quality: 85, mozjpeg: true })
        .toBuffer();
    } catch {
      throw new ApiError(400, 'INVALID_IMAGE', '这张图片无法识别，请换一张清晰的植物照片。');
    }
    if (Buffer.byteLength(output.toString('base64')) > this.config.maxEncodedBytes) {
      throw new ApiError(413, 'IMAGE_TOO_LARGE', '图片压缩后仍然过大，请选择更小的图片。');
    }
    return output;
  }

  static toContract(payload) {
    const results = Array.isArray(payload.result) ? payload.result : [];
    if (results.length === 0 || !results[0].name) {
      throw new ApiError(422, 'IDENTIFICATION_FAILED', '这次没有认出来，换个角度再试试。');
    }
    const primary = results[0];
    return {
      success: true,
      provider: 'baidu',
      primary: {
        name: primary.name,
        confidence: Number(primary.score) || 0,
        description: primary.baike_info?.description ?? null,
        referenceImageUrl: primary.baike_info?.image_url ?? null
      },
      alternatives: results.slice(1, 4).filter((item) => item.name).map((item) => ({
        name: item.name,
        confidence: Number(item.score) || 0
      }))
    };
  }
}
