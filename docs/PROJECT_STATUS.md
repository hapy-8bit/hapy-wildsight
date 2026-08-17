# 见野 WildSight：项目进度

> 最后核对：2026-08-17。本文以当前工作区代码、配置、知识数据、可重复运行的本地命令和已有部署记录为依据。历史部署成功不等于 2026-08-17 已重新连通生产服务器；本次环境无法解析 `api.hapybuilds.com`，也没有取得可用 HDC 目标。

## 当前版本与工程

- HarmonyOS NEXT 原生应用，bundleName 为 `com.wildsight.jianye`。
- App 版本为 1.0.1，`versionCode=1000001`；兼容和目标 SDK 均为 HarmonyOS 6.1.1(24)。
- 客户端使用 ArkTS、ArkUI、Stage Model 和本地 `relationalStore`；服务端为 Node.js / Express，通过 WildSight HTTPS 后端调用百度植物识别。
- 本次修复后已重新构建签名 HAP：`entry/build/default/outputs/default/entry-default-signed.hap`，文件时间为 2026-08-17 09:35:07 CST，大小 984811 bytes；已覆盖安装到唯一 HDC 设备并保留原有应用数据。

## 已落地的客户端能力

- 三个主入口为“图鉴 / 发现 / 设置”，底部 `HdsTabs` 当前使用项目自定义绿色选中态和灰绿色未选中态。
- 图鉴、发现、设置的主标题统一复用 `PageTitle`：29vp、粗体、20vp 水平留白、32vp 顶部 inset；发现页标题为“发现”。
- 图鉴和发现页启用 `EdgeEffect.Spring` 回弹；设置首页和设置详情页同样启用。当前 8 个 `Scroll/List` 均关闭滚动条。
- 发现页支持 HarmonyOS PhotoPicker 相册选图和 `CameraKit cameraPicker` 拍照；两条路径复用同一 `startIdentification` / `performIdentification` 识别链路。
- 发现页空状态不再显示默认植物照片。系统启动页继续使用透明启动图标，应用内开屏显示正式 `foreground.png` 品牌图标和“见野 / 在城市里，遇见植物”文字层，约 1 秒后淡出；图标承载面和文字随浅色/深色主题适配。
- 冷启动首帧由 `EntryAbility` 按当前 `colorMode` 设置匹配的窗口、状态栏和导航栏底色及图标明暗；应用进入后继续由 `App.syncSystemBars()` 保持沉浸式透明系统栏逻辑。
- 设置中心已包含订阅说明、占用空间、缓存清理、本机图鉴清除、图片与识别来源、植物知识来源、浅色/深色/跟随系统、权限、语言、支持、反馈、版本、隐私政策、服务协议和评分降级提示；已移除“关于见野”入口，反馈问题直接进入邮件反馈并保留复制邮箱回退。
- 隐私政策和服务协议按当前数据流描述 PhotoPicker、相机、HTTPS 后端、百度识别、installationId、Species、Discovery 和知识库；没有开发者姓名、注册地址、虚构主体或主体占位文案。
- 首次使用图片识别前会展示隐私处理提示；用户可以暂不同意并继续使用不依赖识别的本地功能，也可以在设置中撤回识别授权。

## 数据与识别链路

- `Species` 表示一个物种，`Discovery` 表示一次相遇，关系为 1:N；二者存放在手机本地 `wildsight.db`。
- 用户确认“收入我的图鉴”后才保存：优先按 `canonicalTaxonId` 复用 Species，缺失时回退中文名，再新增一条 Discovery。
- Discovery 保存本次照片 URI、时间、百度匹配度和观察编号；知识内容与版本保存在 Species。
- 用户打开物种详情时，App 会按 `canonicalTaxonId` 请求 `GET /knowledge/species/:canonicalTaxonId`。只有远端 `contentVersion` 严格更高才更新本地 Species 知识，不修改或删除 Discovery。
- 客户端不会在启动时下载 500 种整库；识别命中审核映射时由服务端富化结果，已收入物种则按需刷新。

## 植物知识库

- 当前本地有 500 个物种 JSON、500 个索引条目、501 条已核验百度名称映射，覆盖 500/500 物种。
- `npm run report:knowledge` 当前报告：500 个 `published/reviewed`、500 个 L2、缺失标签 0、未知标签 0、潜在重复 0。
- 类群覆盖：被子植物 448、蕨类 29、裸子植物 13、苔藓植物 10。
- 2026-08-16 的部署记录表明，这 500 种曾统一部署到 `C:/apps/wildsight/backend`，备份为 `C:/apps/wildsight/backups/backend-20260816-191137`；当时服务器门禁、18/18 测试、本机 health、正式 HTTPS health 和抽样知识接口均通过。
- 2026-08-17 本次审计无法联网复核生产服务器，因此只能确认上述部署历史，不能把服务器当前运行状态写成今日已验证。

## 2026-08-17 本地复核结果

| 检查 | 当前结果 |
| --- | --- |
| `npm run check:knowledge-index` | 通过：`updatedAt` 由稳定知识记录日期推导，500 条 species 内容未改写。 |
| `npm run validate:knowledge` | 通过。 |
| `npm run report:knowledge` | 通过：500 published/reviewed、500 L2、500/500 mapped、0 potential duplicates。 |
| `npm test` | 19 项中 13 通过、6 失败；6 项均在测试启动临时 HTTP 监听时被当前沙箱以 `listen EPERM` 拒绝，不是业务断言失败。 |
| 正式 HTTPS | 当前环境 DNS 解析失败，未完成今日复核。 |
| HDC / 真机 | 已在设备 `2UCUT23C27028737` 使用 `hdc install -r` 覆盖安装并冷启动；深色、浅色开屏与首页截图均已检查，未清数据、未调用识别、未访问服务端。 |

## 已知问题与风险

1. **照片长期可读性尚未完整验证**：当前数据库保存 PhotoPicker / CameraPicker 返回的 URI，没有建立应用沙箱媒体副本；应用重启、系统清理或权限变化后的长期可读性仍是 Beta 风险。
2. **签名配置安全风险**：根目录 `build-profile.json5` 当前包含本机签名文件绝对路径和明文签名口令。它不应进入共享版本库或文档；正式提交前需要迁移到本机安全配置并轮换已暴露凭据。本轮不修改、复制或输出其中任何凭据。

## 建议的下一步

1. 真机可连接后只做同签名覆盖安装，人工验证拍照/相册识别、收入图鉴、重启保留、设置清缓存边界和深浅色；不要为验收清除用户数据。
2. 能访问生产网络时，再单独复核 health、500 种报告和至少一个知识接口，把新的时间和证据写回部署文档。
