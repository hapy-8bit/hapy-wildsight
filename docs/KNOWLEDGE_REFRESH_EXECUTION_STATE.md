# 知识版本刷新执行状态

> 已完成：2026-08-16。本文记录 100 种阶段的知识刷新接口交付，随后已被 500 种知识库部署阶段覆盖；当前数量和门禁状态见 [PROJECT_STATUS.md](PROJECT_STATUS.md)。本文不含密钥、Token、用户图片或用户数据。

## 已交付

- 后端新增只读接口 `GET /knowledge/species/:canonicalTaxonId`。ID 仅接受小写字母、数字和单词间连字符；非法 ID 返回 400，未知、未发布、未审核或损坏记录返回无内部细节的 404。
- `PlantKnowledgeRepository` 先从 `index.json` 查找记录，再读取索引指向的文件；不会根据请求参数拼接文件路径。仅 `published/reviewed` 数据可返回。
- `IdentificationEnrichmentService.publicKnowledge()` 是识别富化和公开接口共用的字段白名单。响应只含公开身份和知识字段、`contentVersion`、`knowledgeReviewStatus`，不含内部来源、事实、维护元数据、provider 映射、GBIF ID 或文件路径。
- App 在物种详情页出现后立即展示本地缓存，并在后台按 `canonicalTaxonId` 查询最新知识。仅当远端 `contentVersion` 严格大于本地 `knowledgeVersion` 时，才用 `SpeciesRepository.updateKnowledgeByCanonicalTaxonId()` 更新已存在的 Species；审核状态按服务端响应原样保存。
- 该受限 SQL 更新只写公开 identity/knowledge、版本、审核状态和更新时间；不会创建或删除 Species，也不会改动 `canonical_taxon_id`、照片、匹配度、首次相遇时间、相遇次数或任何 Discovery。断网、超时、404 和解析失败都保留本地缓存且不弹阻塞错误。

## 验收记录

- 本地（当时）：知识索引构建/检查、校验和报告通过；100 个 `published/reviewed` 物种、102 条已核验映射、100 个 L2、0 个审核警告、0 个未知标签、0 个潜在重复；后端自动测试 18/18 通过。
- 服务端：最终更新前的备份位于 `C:/apps/wildsight/backups/refresh-20260816-172629`，临时同步目录位于 `C:/apps/wildsight/deploy/refresh-20260816-172629`。只停止、更新和启动了 `WildSight-API`；服务器 `validate:knowledge` 和 18 项测试通过，任务状态为 Running，`/health` 返回成功。
- 公网：`https://api.hapybuilds.com/knowledge/species/epipremnum-aureum` 返回 200、版本 1、状态 `reviewed` 且无内部字段；非法 ID 返回 400，未知 ID 返回 404。
- 客户端：签名 HAP 构建成功，文件为 `entry/build/default/outputs/default/entry-default-signed.hap`（2026-08-16 17:18，约 686 KB）。已使用 `hdc install -r` 覆盖安装到唯一设备 `2UCUT23C27028737`，并成功启动 `com.wildsight.jianye/EntryAbility`。

## 保护边界

公开知识接口不调用 `BaiduPlantProvider`，也不调用 `DailyUsageStore`；相应的注入式自动测试已验证 provider、额度预留和释放调用数均为零。执行过程未修改 `.env`、百度凭证或额度数据，未卸载 App、清数据、重置 relationalStore，也未修改 IIS、证书、安全组、端口或其他服务器服务。
