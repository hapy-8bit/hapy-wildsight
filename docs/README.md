# 见野 WildSight 文档入口

当前只维护四份主文档，避免工程事实、交接记录、问题处理和知识库规则互相重复：

1. [鸿蒙项目文档](HARMONYOS_PROJECT.md)：技术栈、目录、页面、识别链路、数据模型、视觉和工程边界。
2. [项目交接文档](HANDOFF.md)：接手顺序、当前快照、验证命令、部署边界、风险和交接格式。
3. [问题与解决方案](PROBLEM_SOLUTIONS.md)：已修复问题、根因、解决方式、待实施问题和验收规则。
4. [植物知识库](PLANT_KNOWLEDGE.md)：500 种知识状态、发布边界、维护规则、门禁和部署保护。

## 文档合并说明

以下内容已合并进四份主文档，不再作为独立当前入口：工程架构、项目状态、用户流程、信息架构、数据模型、数据库结构、设计系统、识别测试、设置执行状态、100 种扩容方案、知识刷新状态、知识维护模板、产品定型、Stitch 设计提示词和阿里云部署说明。

历史数据文件、知识库 imports 和 `docs/design/icon-candidates/` 仍保留用于追溯，但不应替代四份主文档。

## 常用入口

- 客户端：`entry/src/main/ets/`
- 服务端：`server/src/`
- 知识事实源：`server/data/plant-knowledge/species/`
- 知识门禁：见 [PLANT_KNOWLEDGE.md](PLANT_KNOWLEDGE.md)
