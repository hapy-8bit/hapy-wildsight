import { ApiError } from './errors.js';

const TOKEN_URL = 'https://aip.baidubce.com/oauth/2.0/token';

/**
 * Owns the provider credential exchange and ensures concurrent identification
 * requests share one refresh operation instead of requesting duplicate tokens.
 */
export class BaiduTokenManager {
  constructor(config, fetchImpl = fetch) {
    this.config = config;
    this.fetchImpl = fetchImpl;
    this.cachedToken = undefined;
    this.expiresAt = 0;
    this.refreshPromise = undefined;
  }

  async getAccessToken() {
    if (this.cachedToken && Date.now() < this.expiresAt - this.config.tokenRefreshSkewMs) {
      return this.cachedToken;
    }
    if (!this.refreshPromise) {
      this.refreshPromise = this.refresh();
    }
    try {
      return await this.refreshPromise;
    } finally {
      this.refreshPromise = undefined;
    }
  }

  async refresh() {
    const url = new URL(TOKEN_URL);
    url.search = new URLSearchParams({
      grant_type: 'client_credentials',
      client_id: this.config.baiduApiKey,
      client_secret: this.config.baiduSecretKey
    }).toString();

    let response;
    try {
      response = await this.fetchImpl(url, { method: 'POST' });
    } catch {
      throw new ApiError(502, 'SERVER_ERROR', '识别服务暂时不可用，请稍后再试。');
    }

    let payload;
    try {
      payload = await response.json();
    } catch {
      throw new ApiError(502, 'SERVER_ERROR', '识别服务暂时不可用，请稍后再试。');
    }
    if (!response.ok || !payload.access_token || !payload.expires_in) {
      throw new ApiError(502, 'SERVER_ERROR', '识别服务暂时不可用，请稍后再试。');
    }

    this.cachedToken = payload.access_token;
    this.expiresAt = Date.now() + Number(payload.expires_in) * 1000;
    return this.cachedToken;
  }
}
