# 植物识别联调记录

> 最后核对：2026-08-17。不包含百度凭证、完整 Token、签名口令或用户图片。历史真机/服务器验收与本次本地复核分开记录。

## 当前链路

HarmonyOS PhotoPicker / CameraPicker → PhotoService → RemoteIdentificationService（multipart image + installationId header）→ HTTPS api.hapybuilds.com → IIS → 127.0.0.1:3101 → WildSight Backend（日限额）→ BaiduTokenManager → BaiduPlantProvider → 百度植物识别 → IdentificationEnrichmentService → WildSight 植物知识。

Species 和 Discovery 只写入手机 relationalStore。公开知识刷新接口不调用百度、不使用识别额度，也不上传本地图鉴。

## 2026-08-17 本地复核

| 检查 | 结果 / 证据 |
| --- | --- |
| 后端自动测试 | 2026-08-17 修复后 npm test 共 19 项：13 通过、6 失败。6 项失败均因当前受限环境禁止测试临时 HTTP 服务 listen，错误为 EPERM，不是接口断言失败。此前 18 项 / 12 通过为修复前历史结果。 |
| 知识报告 | 500 published/reviewed、500 L2、500/500 mapped、0 potential duplicates。 |
| 知识索引检查 | 修复后通过；`updatedAt` 由记录内稳定日期推导，500 条索引物种内容未改写。详见 PROJECT_STATUS。 |
| 正式 HTTPS | 本次环境无法解析 api.hapybuilds.com，因此没有把历史 health 结果冒充今日验证。 |
| 相册与相机代码 | PhotoPicker 与 cameraPicker.pick 均已接入，并复用同一识别函数。 |
| 本地签名包 | entry/build/default/outputs/default/entry-default-signed.hap 存在，时间 2026-08-16 23:24:12 CST，大小 980620 bytes；本次未重新构建。 |
| 真机 | 本次 hdc list targets 未返回可用目标；未覆盖安装、未启动、未清数据。 |

## 2026-08-16 已有验收记录

- 生产服务器曾完成 500 种知识库统一部署，服务器侧报告 18/18 自动测试通过，WildSight-API、3101 监听、本机 health、正式 HTTPS health 和抽样知识接口均通过。
- 早期真实识别联调已验证 Token 获取与缓存、紫薇图片识别、日限额持久化、不同 installationId 隔离以及安全错误协议。
- 用户曾在真机完成相册识别、查看知识、收入图鉴和重启后数据保留。后续 UI 改动又生成了更新的 HAP；是否已经安装最新 23:24:12 包，本次无法从设备侧确认。
- 这些是带日期的历史证据，不代表 2026-08-17 生产网络和真机已重新检查。

## 当前参数

| 位置 | 参数 |
| --- | --- |
| 客户端 | 连接超时 10 秒；读取超时 15 秒。 |
| 客户端 UI | 5 秒后切换等待文案，持续等待而非直接失败。 |
| 服务端 | 百度 provider 12 秒超时。 |
| 客户端上传 | 长边最大 1600px；必要时压缩为 JPEG，目标不超过 2MB。 |
| 服务端上传上限 | 8MB。 |
| 日限额 | 代码默认 20，生产值由服务器环境变量决定。 |

无法承诺每张图都在 5 秒内成功：百度侧和用户网络不可控。当前保证 5 秒后不会无反馈或被前端直接判定失败。

## 下一次真机回归清单

1. 分别从相册和系统相机选择一张植物图片，确认都能进入识别结果。
2. 检查成功、低匹配、失败和额度用尽的页面状态。
3. 对知识库内物种确认知识卡片出现；对未命中名称确认识别成功不被误判为识别失败。
4. 收入图鉴后检查 Species 和 Discovery，再杀掉并重启 App 验证数据与照片 URI。
5. 新 Discovery 不应写入虚构地点；无位置权限时保存空字符串，发现卡片和相遇详情应省略地点信息，不出现悬空分隔符。
6. 不通过临时调低生产额度来做普通 UI 验收，除非另开受控服务器测试窗口并能恢复配置。
