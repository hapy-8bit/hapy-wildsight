# 见野 V1：工程架构（当前实现）

> 最后核对：2026-08-17。当前代码事实与历史部署事实分开描述；服务器今日运行状态见 [PROJECT_STATUS.md](PROJECT_STATUS.md)。

## 原则

- HarmonyOS NEXT 原生：ArkTS、ArkUI、Stage Model。
- Species 是物种；Discovery 是一次相遇，二者为 1:N，不能合并。
- 页面不直接访问 SQL、百度凭证或百度接口。
- 识别供应商隔离在服务端；客户端只消费统一 IdentificationResult。
- 用户图鉴本地优先；服务器不保存图鉴、Discovery 或用户照片。

## 目录职责

entry/src/main/ets：

- pages：图鉴首页、我的图鉴列表、发现、识别结果、物种详情、相遇详情和设置中心。
- models：Species、Discovery、IdentificationResult、路由、识别状态与结构化错误。
- database：AppDatabase，唯一建表入口。
- repositories：SpeciesRepository 与 DiscoveryRepository。
- services：Photo、Mock/Remote Identification、InstallationIdentityService 等系统能力边界。
- constants：视觉 Token 与 EnvironmentConfig。

server/src：

- app.js：health、识别 API、统一错误和日限额检查。
- config.js：非敏感配置与环境变量读取。
- DailyUsageStore.js：日限额 JSON 持久化。
- BaiduTokenManager.js：OAuth Token 获取和进程内缓存。
- BaiduPlantProvider.js：图片规范化、百度调用、统一结果映射。

## 识别链路

PhotoPicker / CameraPicker → PhotoService → App.ets → InstallationIdentityService → Preferences 随机 UUID → IdentificationService → RemoteIdentificationService → HTTPS api.hapybuilds.com → IIS（目标 127.0.0.1:3101）→ Backend（实际绑定 0.0.0.0:3101）→ DailyUsageStore / BaiduPlantProvider → 百度。

MockIdentificationService 仍保留，可随时切回；RemoteIdentificationService 不知道百度 Key、Token、endpoint 或百度原始响应。

## 额度与失败设计

- InstallationIdentityService 仅在首次真正识别时以 util.generateRandomUUID(true) 创建随机 ID，保存至 Preferences：wildsight_runtime / installation_id。
- 请求以 X-WildSight-Installation-Id 传递随机 ID。
- DailyUsageStore 仅保存 SHA-256(ID)、UTC 日期和次数；通过临时文件写入/重命名与单进程队列保证当前单实例写入可靠，保留最近三天。
- 图片校验后、百度调用前预留一次额度。成功或无匹配消耗一次；本地处理、上游超时和服务端错误会归还，避免服务故障误扣。
- 每日上限来自服务器 `DAILY_IDENTIFY_LIMIT`，代码默认值为 20，合法范围 1–1000；生产环境当前值需要在服务器侧单独复核。
- 客户端 5 秒后只切换等待文案；连接超时 10 秒、读取超时 15 秒；服务端百度调用超时 12 秒。

| 情况 | 客户端行为 |
| --- | --- |
| DAILY_LIMIT_REACHED | 提示今日次数用完，返回发现。 |
| 图片无效、超大或格式不支持 | 引导换清晰照片，允许重试。 |
| 无网络 | 显示网络提示，允许重试。 |
| 上游超时 | 显示稍后重试提示。 |
| 服务异常或无匹配 | 显示暂未识别成功，允许重试。 |
| 请求超过 5 秒 | 继续等待，展示“正在仔细辨认这株植物”。 |

## 发现入库

识别成功 → 用户点击“收入我的图鉴” → 优先按 canonicalTaxonId、再按中文名复用或创建 Species → 创建新的 Discovery 和 OBS 编号 → DiscoveryRepository 写 relationalStore → 图鉴按 speciesId 聚合。

当前已实现相册选择和系统相机拍照。新建 Discovery 的地点按未记录语义保存为空字符串；发现卡片和相遇详情在为空时省略地点，避免虚构定位或悬空分隔符。仍未实现：同图缓存、照片沙箱副本、账号、云同步、真实位置、天气、地图、待确认发现，以及多后端实例的共享限额存储。

## 植物知识库与版本刷新

`BaiduPlantProvider` 继续只负责百度调用和 provider-neutral 映射。其后的 `IdentificationEnrichmentService` 通过 `PlantKnowledgeRepository` 查询 `server/data/plant-knowledge/` 中的版本化 JSON；只富化主候选，知识缺失或 JSON 损坏时保留原识别成功结果。它的 `publicKnowledge()` 白名单同时用于识别富化和 `GET /knowledge/species/:canonicalTaxonId`，因此内部来源、事实、维护元数据、provider 映射、GBIF ID 和文件路径不会发送到客户端。

物种详情页先读取本地 Species，随后按 canonicalTaxonId 异步检查公开知识。客户端只在服务端 `contentVersion` 严格更高时通过受限的 `SpeciesRepository.updateKnowledgeByCanonicalTaxonId()` 写入 identity/knowledge、版本和审核状态；网络失败、404 或解析失败保留缓存。这个更新绝不写入或删除 Discovery，不改照片、匹配度、相遇数据、Species ID 或 canonicalTaxonId，也不上传本地数据。公开知识接口不调用百度，亦不使用每日识别额度。

部署操作见 ALIYUN_DEPLOYMENT.md；测试事实见 IDENTIFICATION_TEST.md。
