import 'dotenv/config';
import path from 'node:path';

const required = ['BAIDU_API_KEY', 'BAIDU_SECRET_KEY'];

function portFromEnvironment(value) {
  const port = Number(value ?? '3000');
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error('PORT must be an integer between 1 and 65535.');
  }
  return port;
}

function positiveIntegerFromEnvironment(name, value, fallback) {
  const parsed = Number(value ?? fallback);
  if (!Number.isInteger(parsed) || parsed < 1 || parsed > 1000) {
    throw new Error(`${name} must be an integer between 1 and 1000.`);
  }
  return parsed;
}

export function getConfig() {
  for (const name of required) {
    if (!process.env[name]) {
      throw new Error(`Missing required environment variable: ${name}`);
    }
  }

  return {
    port: portFromEnvironment(process.env.PORT),
    host: process.env.HOST ?? '0.0.0.0',
    baiduAppId: process.env.BAIDU_APP_ID ?? '',
    baiduApiKey: process.env.BAIDU_API_KEY,
    baiduSecretKey: process.env.BAIDU_SECRET_KEY,
    maxUploadBytes: 8 * 1024 * 1024,
    maxEncodedBytes: 4 * 1024 * 1024,
    tokenRefreshSkewMs: 5 * 60 * 1000,
    providerTimeoutMs: 12 * 1000,
    dailyIdentifyLimit: positiveIntegerFromEnvironment('DAILY_IDENTIFY_LIMIT', process.env.DAILY_IDENTIFY_LIMIT, 20),
    usageStorePath: process.env.IDENTIFY_USAGE_STORE_PATH ?? path.resolve(process.cwd(), '..', 'data', 'identification-usage.json')
  };
}
