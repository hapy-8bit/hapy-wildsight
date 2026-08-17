# 见野 WildSight：鸿蒙项目文档

> 当前事实入口：2026-08-17。本文描述 HarmonyOS 客户端、服务端边界、产品结构、数据模型和视觉约束；历史部署与未完成问题分别见 [HANDOFF.md](HANDOFF.md) 和 [PROBLEM_SOLUTIONS.md](PROBLEM_SOLUTIONS.md)。

## 1. 项目定位与技术栈

见野是一个 HarmonyOS NEXT 原生个人植物图鉴：用户通过相机或相册识别植物，确认后把一次相遇保存到本机图鉴。

- 客户端：ArkTS、ArkUI、Stage Model、HarmonyOS 6.1.1(24)、本地 `relationalStore`。
- 服务端：Node.js / Express；服务端隔离百度凭证、Token 和原始响应。
- 包名：`com.wildsight.jianye`。
- 当前版本：`1.0.1`，`versionCode=1000001`。
- 核心边界：页面不直接访问 SQL、百度接口或凭证；客户端只消费统一 `IdentificationResult`。
- 用户图鉴、Discovery 和照片默认只保存在手机；服务器不保存用户图鉴或照片。

## 2. 代码结构

### 客户端 `entry/src/main/ets`

- `pages`：图鉴、我的图鉴、发现、识别结果、物种详情、相遇详情、设置。
- `models`：`Species`、`Discovery`、`IdentificationResult`、路由、识别状态和错误。
- `database`：`AppDatabase`，唯一建表入口。
- `repositories`：`SpeciesRepository`、`DiscoveryRepository`。
- `services`：PhotoPicker/CameraPicker、Mock/Remote Identification、知识刷新、外观和隐私授权。
- `components`：`PageTitle`、`SecondaryPageHeader`、照片框和观察编号等共享视觉组件。
- `constants`：`AppColors`、尺寸、字体、环境地址等 Token。
- `entryability`：窗口、系统栏和页面启动。

### 服务端 `server/src`

- `app.js`：health、识别 API、统一错误、日限额。
- `config.js`：非敏感配置和环境变量。
- `DailyUsageStore.js`：日限额 JSON 持久化。
- `BaiduTokenManager.js`：Token 获取和进程内缓存。
- `BaiduPlantProvider.js`：图片规范化、百度调用和统一结果映射。
- 知识链路：`PlantKnowledgeRepository`、`IdentificationEnrichmentService`、公开知识接口。

## 3. 识别与保存链路

```text
PhotoPicker / CameraPicker
  → PhotoService
  → App.ets
  → InstallationIdentityService / Preferences 随机 UUID
  → IdentificationService
  → RemoteIdentificationService
  → HTTPS api.hapybuilds.com
  → IIS → 127.0.0.1:3101
  → WildSight Backend
  → DailyUsageStore / BaiduPlantProvider
  → 百度植物识别
  → IdentificationEnrichmentService
  → App 统一识别结果
```

识别成功后，用户点击“收入我的图鉴”才执行：

1. 优先按 `canonicalTaxonId` 复用 `Species`，缺失时回退中文名。
2. 新增一条 `Discovery`，生成唯一 `OBS` 编号。
3. 写入手机 `relationalStore`，按 `speciesId` 聚合显示图鉴。

日限额默认 20，合法范围 1–1000。客户端连接超时 10 秒、读取超时 15 秒；服务端百度调用超时 12 秒。客户端等待超过 5 秒只切换文案，不直接判定失败。

## 4. 页面和导航

一级入口固定为：**图鉴 / 发现 / 设置**。

- 图鉴：最近相遇、个人图鉴、搜索/排序、物种详情和相遇历史。
- 发现：拍照识别、相册识别、识别结果和保存入口。
- 设置：存储、数据来源、外观、权限、语言、隐私、协议、反馈和版本；支持组移除了“关于见野”，反馈问题直接进入邮件反馈并保留复制邮箱回退。

`Species` 是知识对象，`Discovery` 是用户的一次真实相遇，关系始终为 1:N，不得把二者合并。

## 5. 数据模型与本地数据库

```text
Species（一个物种） 1 ───── N Discovery（一次相遇）
```

### Species

保存物种身份、学名、科属、别名、封面 URI、`canonicalTaxonId`、公开知识 JSON、知识版本和审核状态。物种不承载用户某次相遇的时间、照片或地点。

### Discovery

保存本次照片 URI、识别时间、发现时间、匹配度、地点字段、天气预留字段、备注和 `observationCode`。当前无位置权限，新 Discovery 的 `locationName` 保存空字符串；界面为空时省略地点。

### 数据库

- 文件：`wildsight.db`。
- 存储：HarmonyOS `relationalStore`，安全级别 S1。
- 表：`species`、`discoveries`。
- 聚合：按 `discoveries.species_id` 计算相遇次数、第一次和最近一次。
- 迁移：只增加知识字段，不重建表、不删除 Discovery、不改既有 Species ID。
- 当前未实现：照片沙箱副本、位置/天气快照、账号、云同步、待确认发现、单条记录编辑删除。

## 6. 植物知识接口边界

知识事实源为 `server/data/plant-knowledge/species/<canonicalTaxonId>.json`，索引由脚本生成。只有 `published/reviewed` 记录可对外发布。

- 百度识别后只富化主候选。
- 公开知识接口和识别富化共用字段白名单。
- `sourceFacts`、`internalSourceRefs`、`catalogMetadata`、provider 映射、GBIF ID 和文件路径不得进入客户端。
- 物种详情先显示本地缓存，远端 `contentVersion` 严格更高才更新本地 Species。
- 知识刷新不调用百度、不消耗识别额度、不修改或删除 Discovery。

## 7. 视觉与交互约束

- 浅色背景：`#F5F3EF`；深色背景：`#151A18`。
- 所有页面使用 `AppColors`、`AppDimensions`、`AppTypography`，不要散落硬编码主题色。
- 底部 `HdsTabs` 只有“图鉴 / 发现 / 设置”，保持项目绿色选中态和灰绿色未选中态。
- 页面保持纸张档案、低饱和自然、克制编辑式排版。
- 二级页面统一使用固定的大标题栏、圆形返回按钮和滚动后轻遮罩的 `SecondaryPageHeader`；不改变当前应用内路由和 HdsTabs。
- 禁止满屏绿色、强渐变、玻璃拟态、霓虹、卡通植物、Material Dashboard 和悬浮加号式 FAB。
- 系统启动页使用透明系统图标；应用内开屏显示正式品牌图标和品牌文字，当前约 1 秒，并按浅深主题适配。

## 8. 开发边界

任何客户端改动都必须保留：本地优先、Species/Discovery 1:N、百度供应商隔离、知识公开白名单和隐私授权流程。未明确要求时，不新增权限、不访问生产、不修改签名凭据、不清除真机数据。

日常验证命令和交接信息见 [HANDOFF.md](HANDOFF.md)；问题处理记录见 [PROBLEM_SOLUTIONS.md](PROBLEM_SOLUTIONS.md)；植物知识专用规则见 [PLANT_KNOWLEDGE.md](PLANT_KNOWLEDGE.md)。
