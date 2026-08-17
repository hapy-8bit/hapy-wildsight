# 见野植物知识库

> 当前状态：本地为 500 种 `published/reviewed/L2`；最近一次成功生产部署记录为 2026-08-16。索引 `updatedAt` 由知识记录内稳定日期推导（无日期时使用知识库版本日期常量），因此跨日生成仍可复现。生产服务器今日状态未联网复核。

## 数据与发布边界

`server/data/plant-knowledge/species/<canonicalTaxonId>.json` 是每个物种唯一的人工维护事实源；`index.json` 由脚本稳定生成，`provider-name-mapping.json` 只保存人工审核的百度名称映射。`PlantKnowledgeRepository` 只通过索引读取记录，知识损坏或未命中会安全降级。

每条记录包含面向 App 的 identity/knowledge、内容版本和审核状态，以及仅供服务端追溯的 `sourceFacts`、`internalSourceRefs`、`catalogMetadata` 与 provider 映射。后者不会进入任何识别响应、公开知识接口、客户端 Species 或物种详情页。只有 `published` 且 `reviewed` 的记录可以对外发布。

## 两条知识链路

百度识别完成后，`IdentificationEnrichmentService` 仍会将已审核知识富化至主候选。其公开字段组装函数同时被 `GET /knowledge/species/:canonicalTaxonId` 复用，避免两套字段白名单漂移。

用户打开已收入图鉴的物种详情时，App 立即显示本地缓存并异步请求该接口。远端 `contentVersion` 严格更高才会按 canonical ID 更新已有 Species 的公开字段及 `knowledgeReviewStatus`；相同或更旧版本不会写数据库。接口失败或断网继续使用缓存。这个按需刷新不调用百度、不计入识别额度，也不会在 App 启动时下载整库。

`Species` 与 `Discovery` 是 1:N：刷新只影响 Species 知识字段，绝不改变 Discovery、用户照片、匹配度、相遇时间、相遇次数、Species ID 或 canonical ID。

## 本地门禁与生产验收

在 `server/` 运行：

```bash
npm run audit:knowledge-500
npm run build:knowledge-index
npm run check:knowledge-index
npm run validate:knowledge
npm run report:knowledge
npm test
```

2026-08-16 的 500 种扩容验收结果为：500 个发布/审核物种、501 条已核验映射、500/500 映射物种、500 个 L2、0 个审核警告、0 个未知标签、0 个潜在重复，后端自动测试 18/18 通过。类群覆盖为被子植物 448、蕨类 29、裸子植物 13、苔藓植物 10。

2026-08-17 修复前的复核曾发现 `check:knowledge-index` 和 `validate:knowledge` 因系统日期变化而失败；500 条索引物种内容完全一致。这一历史结果保留用于说明问题来源。修复后 `updatedAt` 取记录内显式稳定日期（当前数据为 `internalSourceRefs[].accessedAt` 的最大日期），没有日期的测试/新记录使用明确的知识库版本日期常量 `2026-08-16`，不读取当前日期、文件 mtime 或目录顺序。修复后的本地门禁和测试结果见下方当前复核记录。

2026-08-17 修复后本地复核：`check:knowledge-index`、`validate:knowledge` 和 `report:knowledge` 通过；索引仍为 500 条且物种条目内容未改写。`npm test` 为 19 项，13 项通过，6 项知识路由测试仍因当前沙箱禁止临时 HTTP `listen`（`EPERM`）失败，不是业务断言失败。

新增400种候选、候选审核和部署前逐种审核分别保留在 `imports/batch-500-expansion-candidates.json`、`imports/batch-500-expansion-review.md` 与 `imports/batch-500-predeployment-audit.md`。部署前审核实时确认400/400 GBIF接受种与ID、400/400 iPlant中文身份和科属、400/400形态接口及36/36补充FNA/NC State直接页，最终BLOCKER、MAJOR、MINOR均为0。这些文件用于可追溯生产，不是独立对外数据源。

正式服务器于2026-08-16 19:18 CST完成统一部署，完整备份为 `C:/apps/wildsight/backups/backend-20260816-191137`。同步范围仅为植物知识数据、维护脚本、后端测试和`package.json`；未覆盖`.env`、百度凭证、日限额配置或usage文件。服务器同样通过500种报告和18/18测试，WildSight-API、3101监听、服务器本机health、正式HTTPS及新旧知识接口均通过。客户端代码没有变化，因此未重新构建或安装HAP；本次未调用百度识别，也未消耗识别额度。
