# WildSight Backend 部署说明（Windows Server）

> 状态更新：2026-08-17。本文记录独立 WildSight 后端的部署结构和 2026-08-16 最近一次已知成功部署；不记录 Secret、Token、签名信息或其他项目配置。2026-08-17 当前审计环境无法联网复核生产状态。

## 最近一次已知部署

- 2026-08-16 19:18 CST，500 种 `published/reviewed/L2` 知识统一部署到 `C:/apps/wildsight/backend`。
- 部署前完整备份：`C:/apps/wildsight/backups/backend-20260816-191137`。
- 当时服务器侧 500 种报告、18/18 测试、计划任务、本机 health、正式 HTTPS health 和抽样知识接口均通过。
- 以上是带时间的部署记录，不等于 2026-08-17 已重新检查。新的部署窗口必须重新执行本文健康检查和知识门禁。

## 独立目录

C:/apps/wildsight/

- backend：Node.js 源码与 production dependencies。
- logs：WildSight 独立日志。
- data：运行数据与临时测试图片。
- backups、deploy：仅供 WildSight 使用。

环境变量只存在服务器本机：C:/apps/wildsight/backend/.env。该文件不得上传、提交 Git、写入客户端或打印。它含百度凭证和非敏感的 PORT、HOST、DAILY_IDENTIFY_LIMIT。

日限额数据位于 C:/apps/wildsight/data/identification-usage.json，只含 installationId 哈希、UTC 日期和次数。不要手工删除或编辑该文件。

## 启动和日志

| 项目 | 配置 |
| --- | --- |
| 任务名 | WildSight-API |
| 运行身份 | SYSTEM |
| 启动方式 | Windows 启动时，由任务计划程序启动 |
| Node | C:/Program Files/nodejs/node.exe |
| 工作目录 | C:/apps/wildsight/backend |
| 异常重试 | 最多 3 次，间隔 1 分钟 |
| 输出日志 | C:/apps/wildsight/logs/wildsight-out.log |
| 错误日志 | C:/apps/wildsight/logs/wildsight-error.log |

通过 SSH + PowerShell 运维：

    ssh -i "$HOME/.ssh/id_ed25519_wildsight" Administrator@8.160.176.112
    Get-ScheduledTask -TaskName 'WildSight-API'
    Get-ScheduledTaskInfo -TaskName 'WildSight-API'
    Stop-ScheduledTask -TaskName 'WildSight-API'
    Start-ScheduledTask -TaskName 'WildSight-API'

只可重启 WildSight-API；不要重启 IIS、主站、天气服务、SSH、RDP 或其他任务。

## 网络和健康检查

| 项目 | 配置 |
| --- | --- |
| Backend | 实际绑定 0.0.0.0:3101；IIS 本机目标为 127.0.0.1:3101。 |
| 正式入口 | https://api.hapybuilds.com。 |
| IIS | 独立站点 WildSight-API，匹配 api.hapybuilds.com，反代到本机 3101。 |
| 证书 | Let's Encrypt，由 C:/apps/wildsight/deploy/win-acme/wacs.exe 及其续期任务维护。 |
| 公网 3101 | 阿里云安全组规则已删除，不应重新开放。 |

健康检查：

    Invoke-RestMethod 'http://127.0.0.1:3101/health'
    Invoke-RestMethod 'https://api.hapybuilds.com/health'

客户端只能调用正式 HTTPS 入口；不得写入 3101、百度 endpoint 或百度凭证。

当前 Windows 防火墙未作为 3101 的主要收口层；公网隔离依赖阿里云安全组不包含 3101/TCP。若将来新增宽泛安全组规则，必须先重新评估 3101 的绑定或增加专用入站拒绝规则，不能假定它仍然不可访问。

## 日限额边界

- 请求必须包含 X-WildSight-Installation-Id；缺失或非法会被拒绝。
- 服务端散列该随机 ID 后按 UTC 日记数。
- 达到 DAILY_IDENTIFY_LIMIT 后返回 HTTP 429 / DAILY_LIMIT_REACHED，不调用百度。
- 校验图片后先预留额度；成功或无匹配扣除，明显的本地、上游或服务端异常归还。
- 当前仅一个后端实例；不要为了 MVP 添加 Redis 或数据库。

## 知识库部署门禁

在本地和服务器分别运行：

    npm run check:knowledge-index
    npm run validate:knowledge
    npm run report:knowledge
    npm test

2026-08-17 已修复索引日期确定性问题：`updatedAt` 由知识记录内显式稳定日期推导，无日期时使用知识库版本日期常量，不依赖执行当天、文件 mtime 或目录顺序。部署前仍必须运行上述四项门禁；本轮未访问或修改生产服务器。

不得复用、移动或覆盖已有天气/主站项目的目录、.env、端口、日志、IIS 配置或任务。
