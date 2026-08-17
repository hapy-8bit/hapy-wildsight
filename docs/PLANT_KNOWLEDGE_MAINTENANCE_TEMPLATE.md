# 见野植物知识库维护模板

> 用途：交给独立 Codex 窗口，在本地新增或修订植物知识。默认只维护本地数据、校验和报告；除非用户另外明确要求，不部署服务器、不构建 HAP、不操作真机。

## 一、开始前固定规则

1. 工程目录：`/Users/liuhang/Documents/Google_Project/Github/WildSight`。
2. 每个物种唯一事实源：`server/data/plant-knowledge/species/<canonicalTaxonId>.json`。
3. 创建文件前依次按 GBIF/其他外部 ID、canonicalTaxonId、规范化接受学名、科学异名查重。
4. 中文名相同或相似只能触发人工复核，不能自动合并。
5. 已存在物种只更新原文件并增加 `contentVersion`，禁止创建第二份记录。
6. `index.json` 只能通过 `npm run build:knowledge-index` 生成，禁止手工编辑。
   `updatedAt` 由知识记录内显式稳定日期推导；没有日期时使用明确的知识库版本日期常量，不依赖执行当天、文件 mtime 或目录顺序。相同输入必须生成字节级相同的 `index.json`。
7. 不创建 L0/L1/L2 副本；完整度由报告脚本计算。
8. `internalSourceRefs`、`sourceFacts`、`catalogMetadata` 和外部 ID 只留在服务端，不能进入 App 响应。
9. 百度匹配度属于本次 Discovery；知识内容属于 Species。
10. “怎么认”描述一般物种特征，不能声称本次照片已经检测到这些特征。

## 二、正式物种 JSON 模板

模板仅供复制结构，不要把带占位符的文件放进 `species/`。

```json
{
  "id": "scientific-name-kebab-case",
  "category": "plant",
  "status": "draft",
  "identity": {
    "acceptedChineseName": "有来源支持的正式中文名",
    "scientificName": "Accepted scientific name",
    "family": "中文科名",
    "genus": "中文属名",
    "aliases": [
      "有来源支持且指向同一分类单元的常用名"
    ]
  },
  "scientificSynonyms": [
    "仅填写已核验的科学异名"
  ],
  "sourceFacts": {
    "lifeForm": "来源支持的生活型",
    "stem": "来源支持的茎、枝或树皮特征；无依据时留空",
    "leaf": "来源支持的叶序、叶形、叶缘、质地等",
    "flower": "来源支持的花或花序特征；无依据时留空",
    "fruit": "来源支持的果实或孢子结构；无依据时留空",
    "habitat": "来源支持的生境；无依据时留空",
    "distribution": "来源支持的分布；无依据时留空",
    "floweringPeriod": "有直接依据才填写，否则留空",
    "diagnosticTraits": [
      "可观察且有来源支持的诊断特征1",
      "可观察且有来源支持的诊断特征2"
    ]
  },
  "knowledge": {
    "summary": "面向普通用户的简短摘要，不添加来源未支持的结论。",
    "identificationReferences": [
      "怎么认：可观察特征1",
      "怎么认：可观察特征2"
    ],
    "howToConfirm": [
      "下次这样确认：应补拍或核对的结构1",
      "下次这样确认：应补拍或核对的结构2"
    ],
    "appearance": "外观特征的通俗转述。",
    "growthHabit": "生长习性的通俗转述。",
    "keyCharacteristics": [
      "主要特点1",
      "主要特点2"
    ],
    "observationTips": [
      "普通观察者可执行的观察建议1",
      "普通观察者可执行的观察建议2"
    ],
    "confusableSpecies": [],
    "observationReminder": "植物识别仅供自然观察与记录参考；请勿仅凭识别结果判断植物是否可食用、可药用或对人和宠物安全。"
  },
  "catalogMetadata": {
    "taxonGroup": "angiosperm",
    "growthForms": [
      "herb"
    ],
    "sceneTags": [
      "park-garden"
    ],
    "occurrenceTypes": [
      "wild"
    ],
    "useTags": [],
    "coveragePriority": "P1"
  },
  "internalSourceRefs": [
    {
      "id": "gbif-canonical-id",
      "title": "GBIF species record: Accepted scientific name",
      "url": "https://api.gbif.org/v1/species/GBIF_ID",
      "accessedAt": "YYYY-MM-DD",
      "usedFor": [
        "accepted scientific name",
        "family",
        "genus",
        "external ID"
      ]
    },
    {
      "id": "morphology-canonical-id",
      "title": "权威站点具体物种页标题",
      "url": "具体物种页面URL，不能只写搜索页",
      "accessedAt": "YYYY-MM-DD",
      "usedFor": [
        "accepted Chinese name",
        "habit",
        "leaf",
        "flower",
        "fruit",
        "diagnostic traits"
      ]
    }
  ],
  "providerMappings": {
    "gbif": "GBIF_ID"
  },
  "contentVersion": 1,
  "reviewStatus": "needs_review"
}
```

资料与内容完成、自查通过后才可改为：

```json
"status": "published",
"reviewStatus": "reviewed"
```

## 三、名称映射模板

`provider-name-mapping.json` 中，每个正式物种至少有一个明确中文名映射；可靠且语义唯一的别名可增加 alias 映射。

```json
{
  "provider": "baidu",
  "name": "正式中文名",
  "canonicalTaxonId": "scientific-name-kebab-case",
  "matchType": "exact",
  "verified": true
}
```

```json
{
  "provider": "baidu",
  "name": "经审核别名",
  "canonicalTaxonId": "scientific-name-kebab-case",
  "matchType": "alias",
  "verified": true
}
```

一个 `provider/name` 只能指向一个 canonicalTaxonId。宽泛名称、种与变种混用名称、园艺类群名称没有消歧依据时不得映射。

## 四、受控内部标签

以 `server/data/plant-knowledge/catalog-vocabulary.json` 为唯一词表：

- `taxonGroup`：`angiosperm`、`gymnosperm`、`fern`、`bryophyte`、`other`。
- `growthForms`：`tree`、`shrub`、`subshrub`、`herb`、`vine`。
- `sceneTags`：`urban-greening`、`park-garden`、`roadside`、`wasteland`、`farmland`、`forest`、`forest-edge`、`wetland-waterside`、`aquatic`、`indoor`。
- `occurrenceTypes`：`wild`、`cultivated`、`naturalized`。
- `useTags`：`street-tree`、`shade-tree`、`hedge`、`groundcover`、`lawn`、`ornamental-flower`、`ornamental-foliage`、`ornamental-fruit`、`climber`、`crop`、`fruit-tree`。
- `coveragePriority`：`P0`、`P1`、`P2`。

除 `taxonGroup` 和 `coveragePriority` 为单选外，其余标签允许多选，因此各分类统计会重叠。

## 五、来源规则

1. GBIF仅支持分类学名、科属和外部 ID。
2. 中文名、形态和诊断特征优先使用 iPlant、Flora of China/eFloras、中国植物志、POWO、权威植物园或大学植物资料的具体物种页。
3. 搜索结果页只能用于定位具体页面。
4. 每个来源的 `usedFor` 必须与实际支持字段一致。
5. 不从来源推导毒性、药用、食用、宠物安全或保护状态。
6. `confusableSpecies` 没有逐项依据时保持空数组。
7. 允许通用安全提醒复用，其他识别内容必须按物种独立改写。

## 六、新窗口执行提示词

将植物名单放在提示词末尾，然后交给新窗口：

```text
请在本地维护 WildSight 植物知识库，严格阅读并执行：

/Users/liuhang/Documents/Google_Project/Github/WildSight/docs/PLANT_KNOWLEDGE_MAINTENANCE_TEMPLATE.md

任务边界：
1. 只生产和校验本地知识数据，不部署服务器、不构建HAP、不操作真机。
2. 开始前运行 npm run report:knowledge，记录当前物种数和分类覆盖。
3. 对本次名单先按外部ID、canonicalTaxonId、接受学名和科学异名查重。
4. 已存在物种只能更新原species JSON并增加contentVersion；新物种才创建新文件。
5. 逐物种核验GBIF分类和直接形态来源，不用批量通用模板伪造知识。
6. 每种完成正式JSON、内部标签、来源、正式名映射和可靠别名映射。
7. 一个百度名称不得映射到多个物种；遇到歧义保留needs_review并继续其他物种。
8. 禁止手工编辑index.json，完成后运行：
   npm run build:knowledge-index
   npm run check:knowledge-index
   npm run validate:knowledge
   npm run report:knowledge
   npm test
   若索引检查失败，应先比较生成结果并查明真实数据或生成规则变化，不能忽略失败后部署。跨日不应单独造成失败；可通过更改记录的显式审核/版本日期触发预期更新。
9. 不降低校验标准，不泄漏internalSourceRefs和catalogMetadata。
10. 最终报告新增、更新、needs_review、重复拦截、映射变化、分类覆盖变化和全部命令结果。

本次植物名单：
[在这里粘贴植物名单]
```
