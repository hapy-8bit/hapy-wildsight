# 见野 V1：本地数据库结构

> 实现状态：2026-08-17。下方两张表已在 `AppDatabase.ets` 中创建并由仓储实际读写。

## 存储策略

V1 使用 HarmonyOS `relationalStore`，数据库文件名为 `wildsight.db`，安全级别为 `S1`。不做云同步。

数据库的持久化核心是两张表：

```text
species (一个物种)  1 ───── N  discoveries (用户的一次真实相遇)
```

`discoveries` 是用户资产的事实来源。图鉴中“遇见次数、第一次、最近一次、地点”等信息由它按 `species_id` 聚合，不在 `species` 中冗余保存。

## species

| 列 | 类型 | 约束 | 对应模型字段 | 含义 |
| --- | --- | --- | --- | --- |
| `id` | TEXT | PK, NOT NULL | `id` | 稳定物种 ID |
| `category` | TEXT | NOT NULL | `category` | 当前为 `plant`；为昆虫、鸟类、真菌预留 |
| `chinese_name` | TEXT | NOT NULL | `chineseName` | 中文名称 |
| `scientific_name` | TEXT | NOT NULL | `scientificName` | 学名 |
| `aliases_json` | TEXT | NOT NULL | `aliases` | JSON 字符串数组 |
| `family` | TEXT | NOT NULL | `family` | 科 |
| `genus` | TEXT | NOT NULL | `genus` | 属 |
| `description` | TEXT | NOT NULL | `description` | 简介 |
| `distribution` | TEXT | NOT NULL | `distribution` | 分布 / 常见环境 |
| `features_json` | TEXT | NOT NULL | `features` | JSON 字符串数组 |
| `flowering_period` | TEXT | NOT NULL | `floweringPeriod` | 花期；非植物分类可为空字符串 |
| `toxicity` | TEXT | NOT NULL | `toxicity` | 毒性提示 |
| `pet_safety` | TEXT | NOT NULL | `petSafety` | 宠物安全枚举 |
| `cover_photo_uri` | TEXT | NOT NULL | `coverPhotoUri` | 物种内容封面 |
| `updated_at` | INTEGER | NOT NULL | — | Unix 毫秒 |
| `canonical_taxon_id` | TEXT | NOT NULL, default `''` | `canonicalTaxonId` | 已审核知识库物种 ID；用于优先复用同一物种。 |
| `knowledge_json` | TEXT | NOT NULL, default `''` | `knowledgeJson` | 已审核的展示知识 JSON；不含内部来源。 |
| `knowledge_version` | INTEGER | NOT NULL, default `0` | `knowledgeVersion` | 对应知识内容版本。 |
| `knowledge_review_status` | TEXT | NOT NULL, default `''` | `knowledgeReviewStatus` | 服务端知识审核状态，例如 `reviewed`。 |

## discoveries

| 列 | 类型 | 约束 | 对应模型字段 | 含义 |
| --- | --- | --- | --- | --- |
| `id` | TEXT | PK, NOT NULL | `id` | 发现记录 ID |
| `observation_code` | TEXT | UNIQUE, NOT NULL | `observationCode` | 轻量档案编号，如 `OBS.0042` |
| `species_id` | TEXT | FK, NOT NULL | `speciesId` | 指向 `species.id` |
| `photo_uri` | TEXT | NOT NULL | `photoUri` | 这一次相遇的照片 |
| `identified_at` | INTEGER | NOT NULL | `identifiedAt` | 完成识别的时间，Unix 毫秒 |
| `discovered_at` | INTEGER | NOT NULL | `discoveredAt` | 实际发现时间，Unix 毫秒 |
| `latitude` | REAL | NULL | `latitude` | 可选纬度 |
| `longitude` | REAL | NULL | `longitude` | 可选经度 |
| `location_name` | TEXT | NOT NULL | `locationName` | 可读地点名；未授权时为空字符串 |
| `weather` | TEXT | NOT NULL | `weather` | 发现瞬间的天气快照；未接入时为空字符串 |
| `temperature` | REAL | NULL | `temperature` | 可选温度（℃） |
| `confidence` | REAL | NOT NULL | `confidence` | 识别置信度，范围 0–1 |
| `note` | TEXT | NOT NULL | `note` | 用户备注 |
| `created_at` | INTEGER | NOT NULL | `createdAt` | Unix 毫秒 |
| `updated_at` | INTEGER | NOT NULL | `updatedAt` | Unix 毫秒 |

## 索引与查询

- `idx_discoveries_species_date (species_id, discovered_at DESC)`：物种详情的相遇历史、每个物种的首次与最近一次。
- `idx_discoveries_date (discovered_at DESC)`：发现页的最近发现、以后按时间的自然记录。
- `observation_code UNIQUE`：保证观察编号可成为稳定档案标签。

常用的个人图鉴聚合逻辑：

```sql
SELECT
  species_id,
  COUNT(*) AS encounter_count,
  MIN(discovered_at) AS first_discovered_at,
  MAX(discovered_at) AS latest_discovered_at
FROM discoveries
GROUP BY species_id;
```

地点、月份、地图足迹都由同一张 `discoveries` 表继续派生。V1 不创建“图鉴表”，以避免把 `Species` 与用户的相遇记录混为一谈。

## 写入原则

1. AI 返回候选结果后，用户确认“收入我的图鉴”才创建或更新 `Species`，并写入一个 `Discovery`。
2. 同一物种的新相遇只新增 `Discovery`，不覆盖旧照片、日期、地点或备注。
3. 物种知识更新使用 `SpeciesRepository.upsert`；个人相遇使用 `DiscoveryRepository.save`。
4. 设置中的“清除本机图鉴数据”已经实现为二次确认操作：先删除全部 Discovery，再删除全部 Species；它不会删除数据库结构、系统图库原图、installationId 或外观偏好。单条 Discovery / Species 的编辑与删除仍未实现。

## 知识库迁移

`AppDatabase` 在既有数据库打开时以独立的 `ALTER TABLE ... ADD COLUMN` 迁移上述四列。迁移只增加默认值，不重建表、不修改 `species.id`，也不删除 `discoveries`、照片 URI 或既有 Species。保存新识别结果时优先按 `canonical_taxon_id` 查找，再回退中文名；命中旧记录会补写已审核知识。

## 图片说明

`photo_uri` 和 `cover_photo_uri` 目前只保存 URI 字符串。PhotoPicker 与 CameraPicker 都已接入，但尚未建立应用沙箱媒体副本或完整的媒体生命周期策略。

“应用重启、系统清理或权限变化后每一张 PhotoPicker / CameraPicker URI 始终可读”的实机验证尚未完成；因此照片长期保存仍是 Beta 风险，不应误认为已经完成了沙箱媒体资产管理。

新 Discovery 由 `MockDiscoveryFactory` 写入空的 `location_name`。应用没有位置权限，界面在空值时省略地点信息；历史演示数据中的地点仅用于演示，不代表真实定位。
