# Stitch 交接记录

| 项目 | 状态 |
| --- | --- |
| 设计文档版本 | v1.0，`WILDSIGHT_DESIGN.md` |
| Stitch projectId | 未取得：当前 Stitch transport 返回 `Auth required` |
| designSystem assetId | 未取得：需完成 Stitch 登录后上传 DESIGN.md 并创建 |
| 页面 screenId | 未生成：依赖同一 Stitch 授权 |

已按任务要求实际调用 `list_projects`；调用未能通过认证，故没有重复创建项目、没有伪造 projectId/assetId 或页面结论。恢复 Stitch 登录后，先 `list_projects`、复用或创建 “WildSight 见野 — Mobile Design System”，上传 `WILDSIGHT_DESIGN.md`，创建设计系统，再为 Atlas、发现、识别、详情、设置和深色代表页生成 MOBILE 屏幕。

## 本地落地与图标评审

当前 ArkUI 已根据同一份 `WILDSIGHT_DESIGN.md` 落地统一 Token、浅深外观、系统栏、页面安全区与 HdsTabs 原有绿色选中规则；设计检查不以伪造的 Stitch 资产替代真实 API 结果。

三套候选及其迭代稿保留在设计目录供追溯；用户已确认 C 的无白边叶形路径，正式分层图标已落地：

- 正式 foreground：`AppScope/resources/base/media/foreground.png`
- 正式 background：`AppScope/resources/base/media/background.png`
- 当前正式图标不含四个拍摄取景角标；透明启动图标仍单独使用 `AppScope/resources/base/media/transparent.png`

- A 自然标本：`icon-candidates/wildsight-icon-a-specimen.png`
- B 观察取景框：`icon-candidates/wildsight-icon-b-observation.png`
- C 见野路径：`icon-candidates/wildsight-icon-c-path.png`
- C 路径取景（在 C 基础上加入克制的取景框暗示）：`icon-candidates/wildsight-icon-c-path-camera.png`
- C 叶形取景（扩大取景角标，框住叶形主体）：`icon-candidates/wildsight-icon-c-path-camera-leaf.png`
- C 无白边取景（移除米白圆角底，仅保留叶形路径与取景角标）：`icon-candidates/wildsight-icon-c-path-camera-transparent.png`
- 浅色/深色对比：`icon-candidates/wildsight-icon-comparison.png`

候选图仅作为设计审计材料，不应覆盖已确认的正式图标。Stitch 授权恢复后，继续使用本文件与 `WILDSIGHT_DESIGN.md` 创建真实设计系统和页面，不伪造 projectId、assetId 或 screenId。
