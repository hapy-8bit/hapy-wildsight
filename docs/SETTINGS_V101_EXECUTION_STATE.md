# 设置中心 V1.0.1 执行状态

> 阶段任务已完成；本文是 2026-08-16 的执行记录，不是当前进度入口。最新状态见 [PROJECT_STATUS.md](PROJECT_STATUS.md)。

## 已完成

- 已将 `AppScope/app.json5` 更新为 `versionName: 1.0.1`、`versionCode: 1000001`。
- `ProfilePage` 已从单一数据来源开关重构为有限内部页面状态，包含订阅、占用空间、数据来源、外观、权限、语言、关于、隐私政策和服务协议入口。
- 订阅页不含价格、权益、支付或账号；评分入口在未上架包中安全显示暂未开放提示。
- 已新增 `StorageUsageService`，仅统计应用 `wildsight.db` 和本应用可重建缓存目录；不扫描或计入 PhotoPicker 原图。缓存清理只针对应用自有缓存目录。
- 已新增 Repository 级 `DiscoveryRepository.deleteAll()`、`SpeciesRepository.deleteAll()`；危险清理需第二次点击确认，顺序为先 Discovery 后 Species，且不会碰 installationId、偏好或系统图库。
- 已新增 `AppearancePreferenceService`，默认跟随系统并使用 Preferences 保存三个外观选择；设置页可选择跟随系统、浅色、深色。
- 版本、权限、语言策略、拆分后的图片/识别来源与植物文本来源、邮件复制降级、隐私政策和用户服务协议文本均已在 App 内可滚动读取；当前正式文本不包含运营主体、注册地址或个人身份占位资料。
- 已新增 PrivacyConsentService：首次使用图片识别前展示明确的“同意/暂不同意”选项；拒绝时仍可浏览不需要识别的本地功能，设置页提供“撤回识别授权”。
- 使用 DevEco 内置 JBR/SDK 完成一次签名 HAP 构建，结果成功；仅有工程既有 API/异常处理警告和本轮 `getContext` 弃用警告，无编译错误。

## 已完成的后续工作

- AppearancePreferenceService 已接入设置页、UIAbility 正式色彩模式 API、集中 AppColors 调色板和 App 根组件重绘；跟随系统会读取当前系统色彩模式，浅色/深色选择会持久化。
- 已更新 PROJECT_STATUS、DESIGN_SYSTEM、PRODUCT_V1、USER_FLOW。
- 后端索引检查、知识校验和 18 项测试通过；最终签名构建成功。
- 已用 `hdc install -r` 覆盖安装并启动唯一目标 `2UCUT23C27028737`，未卸载、未清除任何真机数据、未调用识别或修改服务器。

## 最终验收

- 邮件反馈使用 `mailto:` Want 优先启动系统邮件，包含非敏感反馈模板；没有可用处理器时自动复制 `hapy8bit@163.com`。评分入口在未上架测试包中安全提示，不伪造评分。
- 缓存清理只针对明确的 WildSight 自有可重建目录；数据库、Species、Discovery、知识、图片 URI、系统图库、installationId 和偏好均不在该操作范围内。本机图鉴清除需二次确认，且本次从未触发。
- 本阶段生成的 HAP 为 `entry/build/default/outputs/default/entry-default-signed.hap`，当时记录为 2026-08-16 19:29:26 +0800、867298 bytes，并已在唯一真机 `2UCUT23C27028737` 覆盖安装和启动。后续客户端改动已产生更新产物，因此这里的时间和大小只用于阶段追溯，不应称为当前最新包。

本阶段无待继续执行的命令；后续验收以当前进度页为准。
