# 见野 100 种植物知识库统一生产、部署与真机交付方案

> 历史方案：该 100 种部署目标已完成，随后知识库扩展并部署为 500 种。本文保留当时的名称消歧、门禁和部署规则，不能按其中“20 → 100”数量或旧路径再次执行。当前状态见 [PROJECT_STATUS.md](PROJECT_STATUS.md)，日常维护模板见 [PLANT_KNOWLEDGE_MAINTENANCE_TEMPLATE.md](PLANT_KNOWLEDGE_MAINTENANCE_TEMPLATE.md)。

## 一、必须先确认的事实

- `server/data/plant-knowledge/imports/batch-100-candidates.json` 是候选清单，不是运行时知识库。
- 服务器实际读取的是 `server/data/plant-knowledge/species/*.json`、生成的 `index.json` 和 `provider-name-mapping.json`。
- 开始执行时 `species/` 应为 20 个正式文件；完成生产后必须恰好为 100 个唯一正式文件。
- App 不会预先下载整套 100 种数据。百度返回名称命中这 100 种的正式名或已审核别名映射时，后端在本次识别响应中附带对应知识，App 再保存到本地 `Species`；未命中这 100 种时保留原百度识别结果，并在知识区域明确显示“该植物的知识内容暂未维护”。
- 候选审核确认 100/100 GBIF ID 有效、GBIF ID/规范 ID/接受学名无重复。审核发现的问题主要是中文正式名、种下等级和来源记录，不推翻这 100 个分类候选。

## 二、执行边界

- 不修改 Species 1:N Discovery、本地 relationalStore 语义、识别 API 主体契约或现有知识卡片视觉。允许补充“知识未维护”的空状态文案与显示条件，但不得重做详情页。
- 不新增 PostgreSQL、Redis、RAG、运行时大模型或模糊匹配。
- 不自动把百度候选列表写成“容易混淆”。
- 不填写没有逐项可靠依据的花期、详细分布、毒性、药用、宠物安全、保护状态或可食用结论。
- `internalSourceRefs`、`catalogMetadata`、外部 ID 和维护字段不得进入 API/App。
- 不覆盖服务器 `.env`，不改百度凭证、每日限额、IIS、证书、安全组、端口、其他计划任务或其他项目。
- 不卸载 App、不清除 App 数据；真机只允许同签名覆盖安装。

## 三、吸收候选审核结论

### 3.1 中文名处理规则

正式记录的 `identity.acceptedChineseName` 使用来源支持的正式名；候选原 `inputName` 在两者不同时写入 `identity.aliases`，以保留用户熟悉名称。知识摘要第一次出现时可写“正式名（也常称别名）”。

已确定的调整：

| canonicalTaxonId | 正式名 | 应保留别名 |
| --- | --- | --- |
| euonymus-japonicus | 冬青卫矛 | 大叶黄杨 |
| rosa-chinensis | 月季花 | 月季 |
| cinnamomum-camphora | 樟 | 香樟 |
| fraxinus-chinensis | 白蜡树 | 白蜡 |
| styphnolobium-japonicum | 槐 | 国槐 |
| koelreuteria-paniculata | 栾 | 栾树 |
| celtis-sinensis | 朴 | 朴树 |
| magnolia-grandiflora | 荷花木兰 | 广玉兰（只有补到可靠园艺来源后才能作为已审核别名） |
| jasminum-sambac | 茉莉花 | 茉莉 |
| osmanthus-fragrans | 木犀 | 桂花 |
| jasminum-nudiflorum | 迎春花 | 迎春 |
| calendula-officinalis | 金盏花 | 金盏菊（须有可靠来源后保留） |
| oryza-sativa | 稻 | 水稻 |
| arachis-hypogaea | 落花生 | 花生 |
| ipomoea-batatas | 番薯 | 甘薯 |
| brassica-napus | 欧洲油菜 | 油菜仅作有歧义常用名，不自动加入百度映射 |
| parthenocissus-tricuspidata | 地锦 | 爬山虎 |
| hedera-helix | 洋常春藤 | 常春藤仅作有歧义常用名，不自动加入百度映射 |
| pteris-vittata | 蜈蚣凤尾蕨 | 凤尾蕨仅作宽泛名称，不自动加入百度映射 |
| pteridium-aquilinum | 欧洲蕨 | 蕨仅作有歧义名称，不自动加入百度映射 |
| trapa-natans | 欧菱 | 菱仅作有歧义名称，不自动加入百度映射 |
| sagittaria-trifolia | 野慈姑 | 慈姑仅作有歧义名称，不自动加入百度映射 |
| ficus-elastica | 印度榕 | 橡皮树 |
| chimonanthus-praecox | 蜡梅 | 腊梅 |
| cotinus-coggygria | 欧黄栌 | 黄栌仅作有歧义名称，不自动加入百度映射 |

`Euonymus japonicus` 不得和 iPlant 所指的 `Buxus megistophylla` 合并。以后百度若返回“大叶黄杨”，必须结合候选学名或人工审核后再增加映射。

### 3.2 樟的分类体系

- 本项目规范分类主干继续采用已核验 GBIF 接受名 `Cinnamomum camphora` 和 GBIF ID `3033991`，canonicalTaxonId 保持 `cinnamomum-camphora`。
- 正式记录增加 `scientificSynonyms: ["Camphora officinarum"]`。
- `internalSourceRefs` 明确记录 GBIF 与 COL/iPlant 采用不同接受组合，避免以后把二者生产为两个 Species。

### 3.3 4 个清单项统一纳入正式发布集

`chimonanthus-praecox`、`albizia-julibrissin`、`cotinus-coggygria`、`rhus-typhina` 与其余清单记录相同，本次全部进入 100 个正式物种发布集。同步修正审核说明，避免机器状态与文档矛盾。

## 四、统一形成 100 个正式知识记录

复用已经存在且审核通过的正式记录，并为清单中尚未落成正式记录的物种逐个以 `resolvedCanonicalTaxonId` 创建：

`server/data/plant-knowledge/species/<canonicalTaxonId>.json`

每条必须满足：

1. `id/category/status/reviewStatus/contentVersion` 完整；新记录为 `published`、`reviewed`、`contentVersion: 1`。
2. `identity` 包含正式中文名、接受学名、中文科、中文属、别名。
3. `scientificSynonyms` 只保存已核验科学异名。
4. `providerMappings.gbif` 使用候选已审核 GBIF ID，一个 ID 只能归属一个物种。
5. `sourceFacts` 只写来源直接支持的生活型、茎、叶、花、果、环境和诊断特征；没有依据的字段保持空字符串。
6. `knowledge` 至少达到现有 L2：摘要、怎么认、下次确认、外观、生长方式、主要特点、观察要点和观察提醒完整；内容描述一般物种特征，不声称当前照片已观察到这些特征。
7. `catalogMetadata` 只使用 `catalog-vocabulary.json` 受控词表。
8. 每条至少保存：
   - GBIF 直接 species URL：`https://api.gbif.org/v1/species/<GBIF_ID>`，用于学名、科、属、外部 ID；
   - iPlant、Flora of China 或其他可靠植物学页面的直接 URL，用于中文名和形态字段；
   - `accessedAt` 和精确 `usedFor`。
9. 搜索页只能作为定位入口；支持正式字段时应尽量保存具体物种页面。来源不支持的内容不得凭常识扩写。
10. `confusableSpecies` 没有可靠逐项依据时保持空数组。

不得简单复制模板句造成不同植物知识雷同。每个物种的“怎么认”和“下次确认”至少包含该物种可观察的区分特征与拍摄建议。

## 五、100 种名称映射必须全部建好

- 保留现有已经真机/人工审核的映射，不破坏绿萝、月季等已验证链路。
- 100 个正式物种中的每一种都必须在 `provider-name-mapping.json` 至少拥有一条百度精确名称映射；最低覆盖该物种来源支持的 `identity.acceptedChineseName`。最终“已映射物种数”必须为 100，不允许出现知识已入库但完全不可命中的物种。
- 来源支持且语义唯一的 `identity.aliases` 同时建立 `matchType: "alias"` 映射。例如：`月季` 和 `月季花` 都指向 `rosa-chinensis`；`槐` 和 `国槐` 都指向 `styphnolobium-japonicum`；`刺槐` 和 `洋槐` 必须指向另一个唯一 canonicalTaxonId。
- 一个 `provider/name` 只能指向一个 canonicalTaxonId；同名多目标必须使校验失败，不得通过数组顺序决定结果。
- “大叶黄杨、常春藤、凤尾蕨、蕨、菱、慈姑、黄栌、油菜”等宽泛或跨等级名称，只有已经明确选择唯一分类单元且有来源支持时才能映射；否则不映射这些歧义别名，但对应物种的正式中文名仍必须建立映射，从而保证该物种至少可通过一个明确名称命中。
- 所有匹配保持精确字符串匹配，不做包含、相似度、拼音或大模型猜测。
- 不要求用 100 张照片逐种调用百度，自动生产和部署阶段不得调用百度。未来百度出现未登记的新叫法时，只追加一条审核映射，不重复维护或创建 Species。
- 增强校验器：检查 100 个 published/reviewed 物种均至少被一个 verified 百度映射覆盖；检查正式名映射目标正确、provider/name 唯一、目标存在且已发布。

## 六、App 未收录知识的显示

- 百度识别成功且知识命中时，保持现有知识卡片展示。
- 百度识别成功但名称未命中 100 种映射时，保留百度名称、匹配度和候选结果，不伪造知识；在原知识卡片区域显示统一空状态：“该植物的知识内容暂未维护”。
- 空状态只代表见野知识库未收录，不得写成识别失败，也不得阻止用户继续查看识别结果。
- 收入图鉴时仍保存本次 Discovery；没有知识时不得伪造 canonicalTaxonId 或空知识 JSON。
- 为“命中知识”和“识别成功但知识未维护”补充客户端或服务层测试，随后重新构建 HAP。

## 七、本地发布门禁

在 `server` 目录执行并全部通过：

```bash
npm run build:knowledge-index
npm run check:knowledge-index
npm run validate:knowledge
npm run report:knowledge
npm test
```

强制验收结果：

- `species/*.json` 恰好 100 个。
- `index.json` 恰好 100 个唯一条目，全部 `published/reviewed`。
- 已映射物种必须为 100/100；映射条目可以多于 100，因为同一物种允许正式名和多个已审核别名。
- 100 个规范 ID、接受学名、GBIF ID 唯一。
- 未知标签 0、潜在重复 0、校验错误 0、测试失败 0。
- 100 个均达到 L2；若某物种可靠资料不足以达到 L2，应停在本地并明确报告，禁止用臆造内容凑齐后部署。
- 自动测试继续证明 `internalSourceRefs` 和内部标签不会进入 API。
- 增加或保留一个遍历全部已审核百度映射的测试，确保每个映射都能解析到唯一 published/reviewed 记录。

门禁失败时只修失败项并重跑全套命令；不得带失败结果部署。

## 八、一次性部署阿里云后端

目标目录：`C:/apps/wildsight/backend`

1. 只读确认 `WildSight-API` 当前状态、3101 监听进程、服务器现有知识数量。
2. 在 `C:/apps/wildsight/backups/` 创建带时间戳的完整 backend 备份，确保可回滚。
3. 同步本轮所需内容：
   - `server/data/plant-knowledge/`
   - `server/src/knowledge/`（仅在本地与服务器运行时代码确有差异时）
   - `server/scripts/`、`server/test/` 和 `server/package.json`（用于服务器复验）
   - 仅当依赖确有变化才同步 lockfile 并安装依赖；本轮原则上不新增依赖。
4. 绝不覆盖服务器 `.env`，绝不触碰 `C:/apps/wildsight/data/identification-usage.json`。
5. 在服务器运行与本地相同的索引检查、知识校验、覆盖报告和测试，确认服务器报告也是 100 种。
6. 只停止并启动计划任务 `WildSight-API`。
7. 验证：
   - `http://127.0.0.1:3101/health`
   - `https://api.hapybuilds.com/health`
   - 3101 仅由预期 Node 进程监听；公网安全组仍不开放 3101。
   - WildSight 错误日志末尾无模块加载、JSON 解析、知识路径、端口冲突或未处理异常。
8. 使用仓库测试或不调用百度的本地 repository/enrichment 测试验证全部已审核映射；不得上传真实图片、不得消耗百度额度。
9. 任一服务器门禁失败，恢复部署前备份并重新启动 `WildSight-API`，报告失败原因，不触碰其他服务。

## 九、构建并覆盖安装真机

知识库更新本身是服务端变更，App 无需靠 HAP 携带 100 种数据；本轮仍按用户要求构建当前最新客户端并覆盖安装，确保真机使用最新代码。

从工程根目录使用 DevEco Studio 内置 JBR 和 Hvigor：

```bash
export JAVA_HOME="/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home"
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw \
  --mode module \
  -p product=default \
  -p module=entry@default \
  assembleHap \
  --no-daemon
```

确认生成并签名：

`entry/build/default/outputs/default/entry-default-signed.hap`

使用：

`/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc`

执行要求：

1. `hdc list targets` 必须恰好看到一个目标设备；多个设备时不得猜测目标。
2. 使用 `hdc -t <target> install -r <signed-hap-absolute-path>` 覆盖安装。
3. 不执行 uninstall、清数据或任何数据库迁移重置。
4. 安装后启动 `com.wildsight.jianye/EntryAbility`，确认进程正常启动。
5. 自动执行到启动为止，不代替用户进行真实图片识别。

## 十、交付报告与用户真机验收

Terra 最终必须报告：

- 本地和服务器正式物种数、published/reviewed 数、L2 数。
- 映射总数和已映射物种数；已映射物种必须为 100/100。
- 修正的名称/分类冲突、已加入的正式名与别名映射，以及因歧义未加入的宽泛别名。
- 本地及服务器五条门禁命令结果、后端测试数。
- 服务器备份路径、同步范围、计划任务状态、两个 health 结果和错误日志结论。
- 新签名 HAP 的绝对路径、生成时间、文件大小、真机 target、覆盖安装和启动结果。
- 明确声明没有调用百度、没有消耗识别额度、没有清除 App 数据。

用户随后人工检查：

1. 用已有照片识别一至数个这 100 种以内的物种。
2. 确认识别结果带出知识卡片，正式名与别名语义合理。
3. 收入我的图鉴，进入物种详情检查卡片。
4. 杀掉并重启 App，确认 Species 知识与 Discovery 相遇记录仍保留。
5. 再用一张不属于这 100 种或返回名未收录的照片，确认识别仍成功且知识区域显示“该植物的知识内容暂未维护”。
6. 若百度为这 100 种返回一个尚未登记的新叫法，记录返回名称，后续只补映射；不要创建第二份物种知识。
