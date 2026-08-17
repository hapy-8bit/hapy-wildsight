import express from 'express';
import multer from 'multer';
import { BaiduPlantProvider } from './BaiduPlantProvider.js';
import { BaiduTokenManager } from './BaiduTokenManager.js';
import { DailyUsageStore } from './DailyUsageStore.js';
import { ApiError } from './errors.js';
import { PlantKnowledgeRepository } from './knowledge/PlantKnowledgeRepository.js';
import { IdentificationEnrichmentService } from './knowledge/IdentificationEnrichmentService.js';

const INSTALLATION_ID_PATTERN = /^[A-Za-z0-9-]{16,128}$/;

export function createApp(config, dependencies = {}) {
  const app = express();
  const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: config.maxUploadBytes, files: 1 }
  });
  const provider = dependencies.provider ?? new BaiduPlantProvider(new BaiduTokenManager(config), config);
  const knowledgeRepository = dependencies.knowledgeRepository ?? new PlantKnowledgeRepository(config.plantKnowledgePath);
  const enrichmentService = dependencies.enrichmentService ?? new IdentificationEnrichmentService(knowledgeRepository);
  const usageStore = dependencies.usageStore ?? new DailyUsageStore(config.usageStorePath, config.dailyIdentifyLimit);

  app.get('/health', (_request, response) => response.status(200).json({ status: 'ok', success: true }));

  app.get('/knowledge/species/:canonicalTaxonId', async (request, response) => {
    const canonicalTaxonId = request.params.canonicalTaxonId;
    if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(canonicalTaxonId)) {
      response.status(400).json({ success: false, error: { code: 'INVALID_CANONICAL_TAXON_ID', message: '物种编号格式无效。' } });
      return;
    }
    const record = await knowledgeRepository.findPublishedById(canonicalTaxonId);
    if (!record) {
      response.status(404).json({ success: false, error: { code: 'KNOWLEDGE_NOT_FOUND', message: '暂无该植物的公开知识。' } });
      return;
    }
    try {
      response.status(200).json({ canonicalTaxonId: record.id, ...enrichmentService.publicKnowledge(record) });
    } catch {
      response.status(404).json({ success: false, error: { code: 'KNOWLEDGE_NOT_FOUND', message: '暂无该植物的公开知识。' } });
    }
  });

  app.post('/api/v1/identification/plant', upload.single('image'), async (request, response, next) => {
    let installationHash;
    let reserved = false;
    try {
      provider.validateUpload(request.file);
      const installationId = request.get('X-WildSight-Installation-Id') ?? '';
      if (!INSTALLATION_ID_PATTERN.test(installationId)) {
        throw new ApiError(400, 'INSTALLATION_REQUIRED', '请更新应用后再试。');
      }
      installationHash = DailyUsageStore.hashInstallationId(installationId);
      const reservation = await usageStore.reserve(installationHash);
      if (!reservation.allowed) {
        throw new ApiError(429, 'DAILY_LIMIT_REACHED', '今日识别次数已用完，明天再来看看吧。');
      }
      reserved = true;
      response.status(200).json(await enrichmentService.enrich(await provider.identify(request.file)));
    } catch (error) {
      // A real Baidu response (including IDENTIFICATION_FAILED) costs one attempt. Release
      // only attempts that never reached a usable upstream result.
      if (reserved && installationHash && error?.code !== 'IDENTIFICATION_FAILED') {
        await usageStore.release(installationHash).catch(() => undefined);
      }
      next(error);
    }
  });

  app.use((error, _request, response, _next) => {
    if (error instanceof multer.MulterError && error.code === 'LIMIT_FILE_SIZE') {
      response.status(413).json({ success: false, error: { code: 'IMAGE_TOO_LARGE', message: '图片过大，请选择小于 8MB 的图片。' } });
      return;
    }
    if (error instanceof ApiError) {
      response.status(error.status).json({ success: false, error: { code: error.code, message: error.message } });
      return;
    }
    response.status(500).json({ success: false, error: { code: 'SERVER_ERROR', message: '识别服务暂时不可用，请稍后再试。' } });
  });

  return app;
}
