import test from 'node:test';
import assert from 'node:assert/strict';
import sharp from 'sharp';
import { BaiduPlantProvider } from '../src/BaiduPlantProvider.js';
import { BaiduTokenManager } from '../src/BaiduTokenManager.js';

test('maps a Baidu result to the provider-neutral response contract', () => {
  const result = BaiduPlantProvider.toContract({
    result: [
      { name: '紫薇', score: 0.9231, baike_info: { description: '夏季开花植物', image_url: 'https://example.com/crape.jpg' } },
      { name: '大花紫薇', score: 0.052 }
    ]
  });

  assert.equal(result.provider, 'baidu');
  assert.equal(result.primary.name, '紫薇');
  assert.equal(result.primary.confidence, 0.9231);
  assert.equal(result.alternatives[0].name, '大花紫薇');
});

test('shares one Baidu token refresh across concurrent identification requests', async () => {
  let tokenRequestCount = 0;
  const config = {
    baiduApiKey: 'test-api-key',
    baiduSecretKey: 'test-secret',
    tokenRefreshSkewMs: 60_000
  };
  const manager = new BaiduTokenManager(config, async () => {
    tokenRequestCount += 1;
    return {
      ok: true,
      json: async () => ({ access_token: 'cached-token', expires_in: 1800 })
    };
  });

  const tokens = await Promise.all([manager.getAccessToken(), manager.getAccessToken(), manager.getAccessToken()]);

  assert.deepEqual(tokens, ['cached-token', 'cached-token', 'cached-token']);
  assert.equal(tokenRequestCount, 1);
});

test('converts a Baidu provider error into a safe backend error', async () => {
  const provider = new BaiduPlantProvider(
    { getAccessToken: async () => 'test-token' },
    { maxUploadBytes: 8 * 1024 * 1024, maxEncodedBytes: 4 * 1024 * 1024 },
    async () => ({ ok: true, json: async () => ({ error_code: 17 }) })
  );
  const onePixelPng = await sharp({
    create: { width: 1, height: 1, channels: 3, background: { r: 30, g: 90, b: 50 } }
  }).png().toBuffer();

  await assert.rejects(
    () => provider.identify({ buffer: onePixelPng, size: onePixelPng.length, mimetype: 'image/png' }),
    (error) => error.code === 'SERVER_ERROR' && error.message === '识别服务暂时不可用，请稍后再试。'
  );
});
