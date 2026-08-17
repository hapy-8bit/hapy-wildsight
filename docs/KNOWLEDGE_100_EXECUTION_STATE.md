# WildSight 100 种知识库执行状态

> 历史阶段记录：2026-08-16。该 100 种任务已经完成并进一步扩展到 500 种；本文件保留第一次部署失败与恢复证据，不再是 active 任务。当前状态见 [PROJECT_STATUS.md](PROJECT_STATUS.md)。

## 已完成

- 已创建持续执行 Goal：100 种正式知识库、100/100 映射、服务器部署、签名 HAP 与真机覆盖安装。
- 对 80 条新增记录逐条读取 iPlant 直接物种页的公开形态/生态字段；其中 76 条已用其自身形态事实替换批量占位知识。
- 虎尾兰、洋常春藤、凤眼莲、欧洲蕨的 iPlant 页面没有形态段落，已改用独立的植物园/园艺学会/专业植物资料页，并保留 iPlant 页面用于正式中文名。
- 本地五项门禁通过：100 published/reviewed、102 verified mappings、100/100 mapped、L2 100、未知标签/潜在重复/审核警告均为 0，`npm test` 为 12 passed / 0 failed。
- 服务器部署前只读检查：`WildSight-API` 运行，3101 监听，服务器知识库为 1 种。
- 已创建服务器完整后端备份：`C:/apps/wildsight/backups/backend-20260816-164306`。

## 本次部署失败与恢复

- 服务器未提供 SCP/SFTP 子系统，已改用 SSH tar 流式上传至隔离目录：`C:/apps/wildsight/deploy/knowledge100-20260816-164306`。
- 首次 tar 包包含 macOS `._*` 元数据文件；服务器索引脚本将其当作 JSON 解析并在首项服务器门禁失败。
- 已从备份恢复知识目录、运行时代码与测试相关文件，并重新启动且确认服务器本机 `http://127.0.0.1:3101/health` 返回 `{status:"ok",success:true}`。
- 未修改 `.env`、`identification-usage.json`、IIS、证书、安全组、端口或其他计划任务；未调用百度。

## 后续结果

该失败随后通过不含 AppleDouble 元数据的干净归档解决，100 种阶段完成后又扩展并统一部署为 500 种。这里不再保留“下一条命令”，避免误把旧 stage 路径当成当前部署入口。
