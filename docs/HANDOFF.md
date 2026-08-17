# 见野 WildSight：项目交接文档

> 最后核对：2026-08-17。本文给新窗口、协作者和维护者使用。它只记录当前可执行入口与交接边界，不替代历史部署日志。

## 1. 接手顺序

1. 阅读 [HARMONYOS_PROJECT.md](HARMONYOS_PROJECT.md)，理解客户端、服务端和本地数据边界。
2. 阅读 [PROBLEM_SOLUTIONS.md](PROBLEM_SOLUTIONS.md)，确认已修复问题与待处理问题。
3. 如果改植物知识，必须阅读 [PLANT_KNOWLEDGE.md](PLANT_KNOWLEDGE.md)。
4. 修改前检查工作区状态；保留用户已有改动，不做大范围重写。

## 2. 当前工程快照

- HarmonyOS NEXT 原生客户端，ArkTS/ArkUI/Stage Model。
- 包名 `com.wildsight.jianye`，版本 1.0.1，SDK 6.1.1(24)。
- 当前主链路：相册或系统相机 → 真实识别 → 用户确认 → 本地 Species + Discovery。
- 知识库：500 个物种 JSON、500 个索引条目、501 条已核验百度映射，500/500 物种可映射。
- 当前知识记录：500 `published/reviewed`、500 L2、0 未知标签、0 潜在重复。
- 系统栏冷启动按当前色彩模式初始化；应用内开屏约 1 秒并展示正式图标。深色冷启动和开屏时长本轮未重新做真机回归。
- 设置已移除“关于见野”入口；反馈问题直接调用邮件反馈，邮件不可用时复制邮箱。
- 发现页拍摄入口已改为 1:1 区域；已移除“最近发现”，识别建议仅保留在发现页。
- 我的图鉴、识别结果、相遇详情、物种详情和设置详情页已统一使用 `SecondaryPageHeader`。

## 3. 当前验证事实

在 `server/` 执行：

```bash
npm run check:knowledge-index
npm run validate:knowledge
npm run report:knowledge
npm test
```

2026-08-17 已知结果：

- 索引检查：通过。
- 知识校验：通过。
- 知识报告：500 published/reviewed、500 L2、500/500 mapped、0 duplicates。
- `npm test`：2026-08-17 在当前环境执行，19/19 全部通过。
- 当前不能把正式 HTTPS 当作当日已验证；此前环境无法解析 `api.hapybuilds.com`。
- 真机/生产验证必须记录实际日期、设备和命令，不得沿用旧日期结论。
- 本轮客户端改动：在配置 `DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk`、`JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home` 后，`/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --mode module -p product=default assembleHap` 完整通过并生成签名 HAP。
- 真机设备 `2UCUT23C27028737` 已覆盖安装且未清除应用数据；已验证正方形拍摄区、设置支持组、反馈入口，以及系统相机拍摄确认后返回识别结果。2026-08-17 又完成标题专项验收：三个一级页共用标题基线；所有二级页采用日月同款 56vp/44vp/23vp/22fp 标题栏规格；物种详情快速滚动停止后标题、返回按钮和不透明背景仍固定可见。深色冷启动、开屏约 1 秒和浅深主题切换本轮未重新验证。

## 4. 客户端验证边界

客户端改动优先进行：

1. ArkTS 静态检查或 DevEco/Hvigor 编译。
2. 不清数据的同签名覆盖安装。
3. 冷启动、浅色/深色、设置、拍照/相册、识别结果和本地保存回归。
4. 杀掉并重启 App，验证 Species、Discovery 和照片 URI 的实际表现。

不能在未取得设备时声称真机通过；不能通过临时降低生产额度做普通 UI 验收。

## 5. 服务端与生产交接

- 生产目录：`C:/apps/wildsight/backend`。
- 任务：`WildSight-API`，Backend 实际监听 `0.0.0.0:3101`，IIS 反代到 `127.0.0.1:3101`。
- 正式入口：`https://api.hapybuilds.com`。
- 日限额文件只含安装标识哈希、UTC 日期和次数；不要手工删除或编辑。
- `.env`、百度凭证、IIS、证书、安全组、其他计划任务不属于普通代码改动范围。
- 新部署必须先完整备份，再跑索引检查、知识校验、报告和测试，最后验证本机及正式 health。
- 任一门禁失败，停止部署并回滚，不得带失败结果上线。

## 6. 交接报告格式

每次交接至少写清：

- 修改文件和原因；
- 是否改变路由、数据库、识别协议或知识白名单；
- 执行的命令及逐项结果；
- 是否构建 HAP、是否安装真机、是否访问生产；
- 未验证事项和下一步；
- 不得写入任何凭据、Token、签名口令或用户图片。

## 7. 高风险未完成项

- PhotoPicker URI 的长期可读性尚未完成完整沙箱副本方案；CameraPicker 当前拍摄结果先保存到应用沙箱 URI，长期媒体资产策略仍未定型。
- 真实位置、天气、地图、待确认发现、单条记录编辑删除、账号和云同步尚未实现。
- 多后端实例共享识别额度尚未实现。
- 根目录签名配置仍有本机路径和明文凭据风险，需要迁移到安全配置并轮换。
