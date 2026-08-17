# 见野 V1 数据模型（当前实现与演进边界）

> 最后核对：2026-08-17。本文先描述已落地模型；媒体资产、识别历史、地点快照等独立实体属于后续演进，不是当前数据库表。

## 核心原则

```text
Species（一个物种） 1 ───── N Discovery（一次真实相遇）
```

- `Species` 是物种知识，不承载用户遇见的日期、地点或照片记忆。
- `Discovery` 是用户最重要的资产：一张照片、一次识别、一个时间地点和一个 OBS 编号。
- 图鉴不是独立表，而是按 `discoveries.species_id` 对 Species 做聚合后的个人收藏视图。

## 已实现模型

### Species

| 字段 | 说明 |
| --- | --- |
| `id` | 稳定 ID；远程新结果暂以植物中文名生成稳定 hash。 |
| `category` | `plant` / `insect` / `bird` / `fungi` / `other`；V1 当前只写 `plant`。 |
| `chineseName` | 识别结果的中文名。 |
| `scientificName`、`family`、`genus` | 有可靠资料时才显示；未知时为空，不自动猜测。 |
| `aliases`、`description`、`distribution`、`features`、`floweringPeriod`、`toxicity`、`petSafety` | 为物种详情支持/预留；审核知识命中时主要由 WildSight 知识库填充，缺失字段保持空值，不由百度匹配度推断。 |
| `coverPhotoUri` | 用户识别图或服务端参考图。 |
| `canonicalTaxonId` | 可选的已审核知识库 ID；保存时优先用于同物种去重。 |
| `knowledgeJson` / `knowledgeVersion` / `knowledgeReviewStatus` | 已审核展示知识、版本和匹配状态；不含内部来源。 |

### Discovery

| 字段 | 说明 |
| --- | --- |
| `id` | 一次发现的本地 ID。 |
| `observationCode` | 递增档案编号，如 `OBS.0001`。 |
| `speciesId` | 指向一个 Species。 |
| `photoUri` | 此次相遇所选照片的 URI。 |
| `identifiedAt` / `discoveredAt` | 识别完成时间 / 当前发现时间。 |
| `latitude` / `longitude` | 已预留；尚未接入定位。 |
| `locationName` | 当前不请求定位；新 Discovery 保存空字符串，界面直接省略地点信息。历史演示数据可以保留地点文本。 |
| `weather` / `temperature` | 已预留；尚未接入天气。 |
| `confidence` | 统一识别结果的 0–1 置信度。 |
| `note` | 用户备注字段；编辑 UI 尚未实现。 |
| `createdAt` / `updatedAt` | 本地写入与更新时间。 |

### IdentificationResult

这是服务间的内存契约，当前不单独持久化。

| 字段 | 说明 |
| --- | --- |
| `provider` | 当前为 `baidu`；页面不依赖该值。 |
| `primaryMatch` | 名称、置信度、可选简介、参考图、`canonicalSpeciesId`、`knowledgeMatch` 和已审核 `knowledge`；知识字段缺失时仍兼容旧协议。 |
| `alternativeMatches` | 最多显示后端返回的候选。 |

## 当前写入规则

1. 用户选图并获得 `Success` 结果。
2. 用户点击“收入我的图鉴”。
3. 优先按 `canonicalTaxonId` 查找 Species，缺失时回退中文名；不存在才创建新 Species。
4. 新增一条 Discovery，不覆盖旧 Discovery。
5. 页面从数据库重新查询，图鉴和详情按 `speciesId` 聚合。

当前限制：低置信度和失败状态尚不能保存成“待确认发现”；这是产品文档中的目标，尚未实现。

## 后续演进，不等于当前实现

| 后续对象 | 作用 | 触发时机 |
| --- | --- | --- |
| `MediaAsset` / `DiscoveryMedia` | 多图、缩略图、沙箱副本、媒体生命周期 | 完善照片长期保存策略时；相机本身已经接入。 |
| `IdentificationHistory` | 保存原始候选、模型/请求版本、失败原因 | 需要结果可追溯时。 |
| `PlaceSnapshot` | 精度、隐私粒度、逆地理名称 | 接入定位时。 |
| `WeatherSnapshot` | 一次相遇的天气快照 | 接入天气服务时。 |
| `CollectionEntry` | 预计算图鉴摘要 | 数据量增大、聚合性能不足时。 |
| 图片摘要缓存 | 同图重试不重复请求百度 | 做识别配额控制时。 |

详细 SQL 列请见 [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md)，实施进度请见 [PROJECT_STATUS.md](PROJECT_STATUS.md)。
