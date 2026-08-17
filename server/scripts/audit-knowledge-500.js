#!/usr/bin/env node

/**
 * Read-only, reproducible predeployment audit for the 500-species knowledge base.
 *
 * The script never changes species JSON, mappings, candidates, or index.json. It
 * writes only the requested Markdown audit report. The expansion 400 receive live
 * GBIF/iPlant/direct-source checks; the baseline 100 receive regression, structure,
 * mapping, duplicate, completeness, and public-field isolation checks. Cross-batch
 * uniqueness checks cover all 500 records.
 */

import { execFile } from 'node:child_process';
import { readFile, readdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { promisify } from 'node:util';
import { fileURLToPath } from 'node:url';
import { IdentificationEnrichmentService } from '../src/knowledge/IdentificationEnrichmentService.js';

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const serverRoot = path.resolve(scriptDirectory, '..');
const knowledgeRoot = path.join(serverRoot, 'data', 'plant-knowledge');
const speciesDirectory = path.join(knowledgeRoot, 'species');
const candidatePath = path.join(knowledgeRoot, 'imports', 'batch-500-expansion-candidates.json');
const baselinePath = path.join(knowledgeRoot, 'imports', 'batch-500-baseline.json');
const mappingPath = path.join(knowledgeRoot, 'provider-name-mapping.json');
const vocabularyPath = path.join(knowledgeRoot, 'catalog-vocabulary.json');
const defaultReportPath = path.join(knowledgeRoot, 'imports', 'batch-500-predeployment-audit.md');
const reportArgument = process.argv.find((argument) => argument.startsWith('--report='));
const reportPath = reportArgument ? path.resolve(serverRoot, reportArgument.slice('--report='.length)) : defaultReportPath;
const execFileAsync = promisify(execFile);
const userAgent = 'WildSight knowledge maintenance/1.0';
const auditDate = new Date().toISOString().slice(0, 10);
const forbiddenPublicKeys = new Set(['internalSourceRefs', 'sourceFacts', 'catalogMetadata', 'providerMappings', 'path']);
const permittedSourceDomains = new Set([
  'api.gbif.org',
  'www.iplant.cn',
  'www.efloras.org',
  'plants.ces.ncsu.edu',
  'powo.science.kew.org',
  'www.missouribotanicalgarden.org',
  'www.rhs.org.uk',
  'www.cabi.org',
  'www.illinoiswildflowers.info'
]);

const [candidateBatch, baseline, mappingFile, vocabulary, records] = await Promise.all([
  json(candidatePath),
  json(baselinePath),
  json(mappingPath),
  json(vocabularyPath),
  readRecords()
]);

const issues = [];
const recordById = new Map(records.map(({ record }) => [record.id, record]));
const fileById = new Map(records.map(({ file, record }) => [record.id, file]));
const candidateById = new Map(candidateBatch.candidates.map((candidate) => [candidate.resolvedCanonicalTaxonId, candidate]));
const baselineById = new Map(baseline.species.map((item) => [item.canonicalTaxonId, item]));
const expansionIds = new Set(candidateById.keys());
const baselineIds = new Set(baselineById.keys());
const perSpecies = new Map();
const sourceStats = {
  gbifVerified: 0,
  iPlantPageVerified: 0,
  iPlantClassificationVerified: 0,
  iPlantMorphologyVerified: 0,
  supplementalVerified: 0,
  supplementalTranslationReviews: 0,
  inaccessible: 0
};

auditBatchShape();
auditAllRecords();
auditMappings();
auditDuplicates();
auditBaselineRegression();

console.log(`Live-auditing ${candidateBatch.candidates.length} expansion species with concurrency 4...`);
const liveResults = await mapWithConcurrency(candidateBatch.candidates, 4, auditExpansionSpecies);
for (const result of liveResults) perSpecies.set(result.id, result);

const counts = countIssues();
const report = buildReport(counts);
await writeFile(reportPath, report, 'utf8');

console.log(`Predeployment audit report: ${path.relative(serverRoot, reportPath)}`);
console.log(`Audited ${records.length} species (${candidateBatch.candidates.length} live expansion checks, ${baseline.species.length} baseline regressions).`);
console.log(`BLOCKER ${counts.BLOCKER}, MAJOR ${counts.MAJOR}, MINOR ${counts.MINOR}`);
console.log(`Live sources: GBIF ${sourceStats.gbifVerified}/${candidateBatch.candidates.length}, iPlant page ${sourceStats.iPlantPageVerified}/${candidateBatch.candidates.length}, iPlant classification ${sourceStats.iPlantClassificationVerified}/${candidateBatch.candidates.length}, iPlant morphology ${sourceStats.iPlantMorphologyVerified}/${candidateBatch.candidates.length}, supplemental ${sourceStats.supplementalVerified}`);
if (counts.BLOCKER || counts.MAJOR) process.exitCode = 1;

function auditBatchShape() {
  if (records.length !== 500) add('BLOCKER', 'batch', 'species/', 'record count', String(records.length), 'local species directory', '正式物种数不等于500。', '修复缺失或多余记录后重新审核。');
  if (candidateBatch.candidates.length !== 400) add('BLOCKER', 'batch', relative(candidatePath), 'candidate count', String(candidateBatch.candidates.length), 'expansion candidate batch', '新增批次不等于400种。', '恢复经审核的400种候选清单。');
  if (baseline.species.length !== 100 || baseline.speciesCount !== 100) add('BLOCKER', 'batch', relative(baselinePath), 'baseline count', `${baseline.speciesCount}/${baseline.species.length}`, 'read-only baseline', '只读基线不等于100种。', '恢复任务开始前的100种基线。');
  for (const id of expansionIds) if (baselineIds.has(id)) add('BLOCKER', id, fileById.get(id) ?? relative(candidatePath), 'batch membership', id, 'candidate batch and baseline', '新增400与原100发生canonicalTaxonId交叉。', '移除重复候选并以同组物种替换。');
  for (const candidate of candidateBatch.candidates) {
    if (candidate.resolutionStatus !== 'existing') add('BLOCKER', candidate.resolvedCanonicalTaxonId, relative(candidatePath), 'resolutionStatus', candidate.resolutionStatus, 'formal species directory', '新增候选未全部落为正式记录。', '完成来源审核和正式生产，或替换阻塞候选。');
    if (!recordById.has(candidate.resolvedCanonicalTaxonId)) add('BLOCKER', candidate.resolvedCanonicalTaxonId, relative(candidatePath), 'resolvedCanonicalTaxonId', candidate.resolvedCanonicalTaxonId, 'formal species directory', '候选指向的正式记录不存在。', '补齐正确记录或修正候选解析结果。');
  }
}

function auditAllRecords() {
  const reminder = '植物识别仅供自然观察与记录参考；请勿仅凭识别结果判断植物是否可食用、可药用或对人和宠物安全。';
  for (const { file, record } of records) {
    const id = record.id || path.basename(file, '.json');
    const source = sourceSummary(record);
    if (path.basename(file, '.json') !== id) add('BLOCKER', id, relative(file), 'id', id, 'local filename', '文件名与canonicalTaxonId不一致。', '将记录保存在与稳定ID一致的唯一文件中。');
    if (!/^[a-z0-9]+(?:-[a-z0-9]+)+$/.test(id)) add('BLOCKER', id, relative(file), 'id', id, 'maintenance naming rule', 'canonicalTaxonId不符合小写kebab-case命名规则。', '按接受学名生成稳定、唯一的小写ID。');
    const expectedId = canonicalId(record.identity?.scientificName);
    if (expectedId && expectedId !== id) add('BLOCKER', id, relative(file), 'id', id, 'identity.scientificName', `canonicalTaxonId与接受学名不一致（预期${expectedId}）。`, '核对分类单元后修正ID或接受学名，并同步映射。');
    for (const field of ['acceptedChineseName', 'scientificName', 'family', 'genus']) if (!record.identity?.[field]) add('BLOCKER', id, relative(file), `identity.${field}`, '(empty)', source, 'L0必需身份字段缺失。', '从直接权威来源补齐。');
    if (!record.providerMappings?.gbif) add('BLOCKER', id, relative(file), 'providerMappings.gbif', '(empty)', source, '缺少外部分类ID。', '核验接受种后填写对应GBIF ID。');
    if (record.status !== 'published' || record.reviewStatus !== 'reviewed') add('BLOCKER', id, relative(file), 'publication state', `${record.status}/${record.reviewStatus}`, source, '目标库存在未发布或未审核记录。', '仅在问题全部解决后设为published/reviewed。');
    if (!Number.isInteger(record.contentVersion) || record.contentVersion < 1) add('MAJOR', id, relative(file), 'contentVersion', String(record.contentVersion), source, '内容版本无效。', '使用正整数版本并在明确修订时递增。');
    if (!Array.isArray(record.internalSourceRefs) || !record.internalSourceRefs.length) add('BLOCKER', id, relative(file), 'internalSourceRefs', '(empty)', 'none', '没有可靠来源。', '补充至少一个直接分类来源和相应形态来源。');
    else auditSourceMetadata(id, file, record);
    auditCompleteness(id, file, record, source);
    auditKnowledgeSemantics(id, file, record, source, reminder);
    auditCatalog(id, file, record, source);
    const publicKnowledge = new IdentificationEnrichmentService({}).publicKnowledge(record);
    for (const key of forbiddenPublicKeys) if (Object.hasOwn(publicKnowledge, key)) add('BLOCKER', id, relative(file), `publicKnowledge.${key}`, '(present)', 'IdentificationEnrichmentService.publicKnowledge', '内部字段进入公开知识对象。', '从公开白名单删除该字段并增加回归测试。');
  }
}

function auditSourceMetadata(id, file, record) {
  const allowedGbifUsedFor = new Set(['accepted scientific name', 'family', 'genus', 'external ID', 'taxonomic group', 'taxonomy']);
  for (const [index, ref] of record.internalSourceRefs.entries()) {
    let url;
    try { url = new URL(ref.url); } catch {
      add('BLOCKER', id, relative(file), `internalSourceRefs[${index}].url`, String(ref.url), ref.title ?? '(untitled)', '来源URL无效。', '替换为可访问的直接来源URL。');
      continue;
    }
    if (!permittedSourceDomains.has(url.hostname)) add('MAJOR', id, relative(file), `internalSourceRefs[${index}].url`, ref.url, ref.title, '来源域名不在本批权威来源白名单中。', '人工确认机构权威性后加入明确白名单或更换来源。');
    if (!Array.isArray(ref.usedFor) || !ref.usedFor.length) add('MAJOR', id, relative(file), `internalSourceRefs[${index}].usedFor`, JSON.stringify(ref.usedFor), ref.url, '来源未声明实际支持字段。', '按页面实际内容缩小usedFor。');
    if (url.hostname === 'api.gbif.org') for (const usedFor of ref.usedFor ?? []) if (!allowedGbifUsedFor.has(usedFor)) add('BLOCKER', id, relative(file), `internalSourceRefs[${index}].usedFor`, usedFor, ref.url, '分类数据库被用于支持形态、安全或用途事实。', '删除超出分类范围的usedFor，并补直接事实来源。');
    if (expansionIds.has(id) && /\/search|\/results/i.test(url.pathname) && !url.hostname.includes('api.gbif.org')) add('MAJOR', id, relative(file), `internalSourceRefs[${index}].url`, ref.url, ref.title, '搜索结果页不能替代直接物种页。', '替换为具体物种页面。');
  }
}

function auditCompleteness(id, file, record, source) {
  const knowledge = record.knowledge ?? {};
  for (const field of ['summary', 'appearance', 'growthHabit', 'observationReminder']) if (!String(knowledge[field] ?? '').trim()) add('BLOCKER', id, relative(file), `knowledge.${field}`, '(empty)', source, 'L1/L2必需字段为空。', '根据直接形态事实补写并重新审核。');
  for (const field of ['keyCharacteristics', 'identificationReferences', 'howToConfirm', 'observationTips']) {
    if (!Array.isArray(knowledge[field]) || knowledge[field].length < 2) add('BLOCKER', id, relative(file), `knowledge.${field}`, JSON.stringify(knowledge[field]), source, 'L2字段少于两个可用条目。', '补充至少两个有来源、可执行且互相独立的条目。');
    else if (new Set(knowledge[field].map(normalized)).size < 2) add('MAJOR', id, relative(file), `knowledge.${field}`, summarize(knowledge[field]), source, '两个条目实质重复。', '改为两个不同的稳定特征或确认动作。');
  }
  if (!Array.isArray(knowledge.confusableSpecies)) add('MAJOR', id, relative(file), 'knowledge.confusableSpecies', String(knowledge.confusableSpecies), source, '易混淆物种字段不是数组。', '没有逐项依据时设为空数组。');
}

function auditKnowledgeSemantics(id, file, record, source, reminder) {
  const knowledge = record.knowledge ?? {};
  const facts = record.sourceFacts ?? {};
  const allKnowledge = flattenStrings(knowledge);
  const factTexts = flattenStrings(facts).filter(Boolean);
  const sourceCorpus = normalized(factTexts.join(' '));
  const unsafePattern = /(?:有毒|毒性|无毒|可食|食用|药用|入药|宠物安全|保护等级|濒危|禁止采挖|不可采挖)/u;
  for (const [field, value] of Object.entries(knowledge)) {
    if (field !== 'observationReminder' && unsafePattern.test(flattenStrings(value).join(' '))) add('BLOCKER', id, relative(file), `knowledge.${field}`, summarize(value), source, '出现毒性、药用、食用、宠物安全或保护结论，但本批没有对应专项可靠来源。', '删除该结论；如确需保留，补专项权威来源并逐项审核。');
  }
  if (knowledge.observationReminder !== reminder) add('MAJOR', id, relative(file), 'knowledge.observationReminder', summarize(knowledge.observationReminder), source, '安全提醒偏离统一免责声明，可能引入物种特定安全承诺。', '恢复统一、非物种特定的安全提醒。');
  const artifactPattern = /(?:\.\.\.|……|<\/?[a-z][^>]*>|https?:\/\/|您的访问请求|网络错误|undefined|\$\{|\[object Object\]|copyright|all rights reserved)/iu;
  for (const [field, value] of Object.entries({ sourceFacts: facts, knowledge })) if (artifactPattern.test(flattenStrings(value).join(' '))) add('BLOCKER', id, relative(file), field, summarize(value), source, '存在截断、省略号、HTML/URL或网页残片。', '回到直接来源提取完整事实并人工重写。');
  if (/(?:当前照片中|本次照片中|照片中(?:可见|已经|显示)|从照片中(?:看到|检测)|系统已检测)/u.test(allKnowledge.join(' '))) add('MAJOR', id, relative(file), 'knowledge.identificationReferences', summarize(knowledge.identificationReferences), source, '识别文案声称系统已从当前照片观察到特征。', '改为一般物种特征和下一次可观察动作。');
  if (!expansionIds.has(id)) return;
  const nonMorphologyPattern = /入药|药用|主治|疗效|可食|食用|精油|经济价值/u;
  for (const field of ['stem', 'leaf', 'flower', 'fruit']) {
    const value = String(facts[field] ?? '');
    if (nonMorphologyPattern.test(value)) add('BLOCKER', id, relative(file), `sourceFacts.${field}`, value, source, '用途或药用段被误写为形态事实。', '改用同一直接物种页的对应形态段；不得为字段完整扩大来源原意。');
    if (/^(?:产|分布(?:于)?)/u.test(value) || value.length > 500) add('BLOCKER', id, relative(file), `sourceFacts.${field}`, value, source, '分布长段或非器官内容被误写为形态事实。', '按来源字段重新提取器官特征，并移除分布清单。');
  }
  if (!/乔木|灌木|草本|藤本|攀援|蕨|苔|藓|叶状体|附生|水生|一年生|二年生|多年生|鳞茎植物|漂浮|飘浮|浮水|丛生|蔓生|植株|株高|根状茎|块茎|鳞茎|秆|茎.*直立/u.test(String(facts.lifeForm ?? '')) || /^本种与|区别/u.test(String(facts.lifeForm ?? ''))) add('MAJOR', id, relative(file), 'sourceFacts.lifeForm', String(facts.lifeForm ?? ''), source, '生活型字段不是可辨认的生活型或生长方式。', '从直接来源填写草本、木本、藤本、蕨类、地下器官或生长方式。');
  for (const [index, trait] of (facts.diagnosticTraits ?? []).entries()) if (String(trait).length > 250 || /时过境迁/u.test(String(trait))) add('BLOCKER', id, relative(file), `sourceFacts.diagnosticTraits[${index}]`, trait, source, '诊断特征含网页/OCR残片或整段分布，不能用于识别。', '换成简短、有来源的可观察器官特征。');
  for (const field of ['identificationReferences', 'keyCharacteristics']) for (const item of knowledge[field] ?? []) {
    const itemText = normalized(item);
    if (itemText && !sourceCorpus.includes(itemText) && !factTexts.some((fact) => overlap(normalized(fact), itemText))) add('BLOCKER', id, relative(file), `knowledge.${field}`, item, source, '知识特征不能追溯到sourceFacts。', '忠实转述有直接来源支持的sourceFacts。');
  }
  for (const quote of allKnowledge.flatMap((text) => [...String(text).matchAll(/“([^”]+)”/gu)].map((match) => match[1]))) {
    if (!factTexts.some((fact) => overlap(normalized(fact), normalized(quote)))) add('BLOCKER', id, relative(file), 'knowledge quoted fact', quote, source, '确认或观察文案引用的事实不在sourceFacts中。', '删除或改为已记录的来源事实。');
  }
  for (const reference of knowledge.identificationReferences ?? []) if (!normalized(knowledge.summary).includes(normalized(reference)) && !overlap(normalized(knowledge.summary), normalized(reference))) add('MINOR', id, relative(file), 'knowledge.summary', summarize(knowledge.summary), source, '摘要未清楚覆盖主要识别方向。', '简短纳入两项主要观察特征。');
  if (!facts.leaf && /拍叶|叶片正反面/u.test((knowledge.howToConfirm ?? []).join(' '))) add('MAJOR', id, relative(file), 'knowledge.howToConfirm', summarize(knowledge.howToConfirm), source, '无叶片事实的物种仍要求拍叶。', '改拍实际存在且有来源支持的营养体或生殖结构。');
  if ((knowledge.summary ?? '').length > 220) add('MINOR', id, relative(file), 'knowledge.summary', summarize(knowledge.summary), source, '摘要过长。', '压缩为物种性质和两个主要观察方向。');
}

function auditCatalog(id, file, record, source) {
  const metadata = record.catalogMetadata ?? {};
  for (const field of ['taxonGroup', 'coveragePriority']) if (!Object.hasOwn(vocabulary[field] ?? {}, metadata[field])) add('MAJOR', id, relative(file), `catalogMetadata.${field}`, String(metadata[field]), source, '不在受控词表中。', '改用catalog-vocabulary.json现有词。');
  for (const field of ['growthForms', 'sceneTags', 'occurrenceTypes', 'useTags']) {
    if (!Array.isArray(metadata[field])) { add('MAJOR', id, relative(file), `catalogMetadata.${field}`, String(metadata[field]), source, '多选标签不是数组。', '使用受控词数组。'); continue; }
    for (const tag of metadata[field]) if (!Object.hasOwn(vocabulary[field] ?? {}, tag)) add('MAJOR', id, relative(file), `catalogMetadata.${field}`, tag, source, '出现未知标签。', '删除或替换为受控词。');
  }
  if (baselineIds.has(id)) return;
  const evidence = `${record.sourceFacts?.lifeForm ?? ''} ${record.sourceFacts?.habitat ?? ''}`;
  const growthEvidence = {
    tree: /乔木/u, shrub: /灌木/u, subshrub: /半灌木/u, vine: /藤|攀援|缠绕/u, herb: /草本|蕨|苔|藓|叶状体|鳞茎|根状茎|块茎/u
  };
  for (const tag of metadata.growthForms ?? []) if (!growthEvidence[tag]?.test(evidence)) add('MAJOR', id, relative(file), 'catalogMetadata.growthForms', tag, source, '生活型标签缺少sourceFacts明确支持。', '删除机械标签或补直接生活型依据。');
  const sceneEvidence = {
    'urban-greening': /园林|绿化|行道|城市道路/u,
    'park-garden': /园林|庭园|庭院|花坛|花境|地被|园艺栽培/u,
    roadside: /路旁|路边|道旁/u,
    wasteland: /荒地|荒野/u,
    farmland: /农田|田间|田边|旱地|水田/u,
    forest: /林下|林中|森林|山林/u,
    'forest-edge': /林缘|林边|灌丛/u,
    'wetland-waterside': /湿地|水边|河边|湖边|溪边|沼泽|水沟|水塘|池塘|湖湾/u,
    aquatic: /水生|水中|水面|漂浮|飘浮|沉水/u,
    indoor: /室内栽培|室内观叶|室内植物/u
  };
  for (const tag of metadata.sceneTags ?? []) if (!sceneEvidence[tag]?.test(evidence)) add('MAJOR', id, relative(file), 'catalogMetadata.sceneTags', tag, source, '场景标签缺少sourceFacts明确支持。', '删除按规划组推断的标签或补直接场景依据。');
  const occurrenceEvidence = { wild: /生于|生长于|野生|林下|山坡|草地|路旁|荒地|湿地|水中/u, cultivated: /栽培|园艺|盆栽|温室|引种/u, naturalized: /归化|逸生/u };
  for (const tag of metadata.occurrenceTypes ?? []) if (!occurrenceEvidence[tag]?.test(evidence)) add('MAJOR', id, relative(file), 'catalogMetadata.occurrenceTypes', tag, source, '发生类型缺少明确事实支持。', '删除推断标签或补直接野生/栽培/归化依据。');
  if ((metadata.useTags ?? []).length) add('MAJOR', id, relative(file), 'catalogMetadata.useTags', summarize(metadata.useTags), source, '新增批次用途标签没有独立用途事实来源。', '删除用途标签；如需保留，增加明确用途来源。');
  if (metadata.coveragePriority !== 'P1') add('MAJOR', id, relative(file), 'catalogMetadata.coveragePriority', String(metadata.coveragePriority), 'batch planning rule', '新增400种未使用首批500覆盖优先级P1。', '改为P1。');
}

function auditMappings() {
  const seen = new Map();
  const mappedIds = new Set();
  for (const [index, mapping] of mappingFile.mappings.entries()) {
    const key = `${mapping.provider}\u0000${mapping.name}`;
    const previous = seen.get(key);
    if (previous && previous !== mapping.canonicalTaxonId) add('BLOCKER', mapping.canonicalTaxonId, relative(mappingPath), `mappings[${index}]`, `${mapping.provider}/${mapping.name} -> ${mapping.canonicalTaxonId}`, 'provider-name-mapping.json', `同一provider/name也指向${previous}。`, '只保留经人工确认的唯一目标。');
    if (previous === mapping.canonicalTaxonId) add('MAJOR', mapping.canonicalTaxonId, relative(mappingPath), `mappings[${index}]`, `${mapping.provider}/${mapping.name}`, 'provider-name-mapping.json', '映射条目重复。', '保留一条。');
    seen.set(key, mapping.canonicalTaxonId);
    mappedIds.add(mapping.canonicalTaxonId);
    const target = recordById.get(mapping.canonicalTaxonId);
    if (!target) add('BLOCKER', mapping.canonicalTaxonId, relative(mappingPath), `mappings[${index}]`, mapping.name, 'formal species directory', '名称映射指向不存在的物种。', '删除映射或修正为正确canonicalTaxonId。');
    if (mapping.verified !== true || !['exact', 'alias'].includes(mapping.matchType)) add('MAJOR', mapping.canonicalTaxonId, relative(mappingPath), `mappings[${index}]`, JSON.stringify(mapping), 'mapping policy', '映射未明确审核或匹配类型无效。', '仅保留人工审核的exact/alias映射。');
    if (target && mapping.matchType === 'exact' && mapping.name !== target.identity.acceptedChineseName) add('MAJOR', mapping.canonicalTaxonId, relative(mappingPath), `mappings[${index}].name`, mapping.name, sourceSummary(target), 'exact映射不是正式中文名。', '有可靠别名依据时改为alias，否则删除。');
    if (target && mapping.matchType === 'alias' && !target.identity.aliases.includes(mapping.name)) add('MAJOR', mapping.canonicalTaxonId, relative(mappingPath), `mappings[${index}].name`, mapping.name, sourceSummary(target), 'alias映射未记录为该物种可靠别名。', '补可靠别名来源并同步identity.aliases，或删除映射。');
  }
  for (const { file, record } of records) if (!mappedIds.has(record.id)) add('BLOCKER', record.id, relative(file), 'provider mapping', '(missing)', relative(mappingPath), '正式物种没有百度正式名映射。', '增加经审核的正式中文名精确映射。');
}

function auditDuplicates() {
  const indexes = {
    canonicalTaxonId: new Map(),
    acceptedScientificName: new Map(),
    gbif: new Map(),
    acceptedChineseName: new Map(),
    scientificSynonym: new Map()
  };
  const acceptedScientificOwners = new Map();
  const acceptedChineseOwners = new Map();
  for (const { file, record } of records) {
    unique(indexes.canonicalTaxonId, record.id, record.id, file, 'canonicalTaxonId');
    const scientific = normalizedScientific(record.identity?.scientificName);
    unique(indexes.acceptedScientificName, scientific, record.id, file, 'accepted scientificName');
    acceptedScientificOwners.set(scientific, record.id);
    unique(indexes.gbif, String(record.providerMappings?.gbif ?? '').trim(), record.id, file, 'GBIF ID');
    const chinese = normalizedChinese(record.identity?.acceptedChineseName);
    unique(indexes.acceptedChineseName, chinese, record.id, file, 'accepted Chinese name');
    acceptedChineseOwners.set(chinese, record.id);
    for (const synonym of record.scientificSynonyms ?? []) unique(indexes.scientificSynonym, normalizedScientific(synonym), record.id, file, 'scientific synonym');
  }
  for (const { file, record } of records) {
    for (const synonym of record.scientificSynonyms ?? []) {
      const owner = acceptedScientificOwners.get(normalizedScientific(synonym));
      if (owner && owner !== record.id) add('BLOCKER', record.id, relative(file), 'scientificSynonyms', synonym, fileById.get(owner), `科学异名是另一记录${owner}的接受名。`, '核对分类后合并重复记录或删除错误异名。');
    }
    for (const alias of record.identity?.aliases ?? []) {
      const owner = acceptedChineseOwners.get(normalizedChinese(alias));
      if (owner && owner !== record.id) add('BLOCKER', record.id, relative(file), 'identity.aliases', alias, fileById.get(owner), `中文别名与另一物种${owner}的正式名冲突。`, '删除歧义别名映射；必要时退回人工审核。');
    }
  }
}

function auditBaselineRegression() {
  for (const item of baseline.species) {
    const record = recordById.get(item.canonicalTaxonId);
    if (!record) { add('BLOCKER', item.canonicalTaxonId, relative(baselinePath), 'baseline record', '(missing)', 'read-only baseline', '原有100种被删除。', '恢复原记录。'); continue; }
    const comparisons = [
      ['identity.scientificName', record.identity.scientificName, item.acceptedScientificName],
      ['identity.acceptedChineseName', record.identity.acceptedChineseName, item.acceptedChineseName],
      ['providerMappings.gbif', record.providerMappings?.gbif, item.gbifId]
    ];
    for (const [field, current, old] of comparisons) if (String(current) !== String(old)) add('BLOCKER', record.id, relative(fileById.get(record.id)), field, String(current), relative(baselinePath), `原100种身份字段从基线“${old}”发生变化，且本次没有独立修订记录。`, '恢复基线值，或提供明确分类来源和版本化修订说明。');
    if (record.contentVersion < item.contentVersion) add('BLOCKER', record.id, relative(fileById.get(record.id)), 'contentVersion', String(record.contentVersion), relative(baselinePath), '内容版本低于只读基线。', '恢复不低于基线的版本。');
  }
}

async function auditExpansionSpecies(candidate) {
  const id = candidate.resolvedCanonicalTaxonId;
  const record = recordById.get(id);
  const result = { id, chineseName: candidate.acceptedChineseName, gbif: 'failed', iPlant: 'failed', facts: 'failed', supplemental: candidate.source.supplementalMorphology ? 'failed' : 'not-required' };
  if (!record) return result;
  const file = fileById.get(id);
  const candidateSource = [candidate.source.gbif, candidate.source.chineseNameAndMorphology, candidate.source.supplementalMorphology].filter(Boolean).join('; ');
  for (const [field, current, expected] of [
    ['id', record.id, candidate.resolvedCanonicalTaxonId],
    ['identity.acceptedChineseName', record.identity.acceptedChineseName, candidate.acceptedChineseName],
    ['identity.scientificName', record.identity.scientificName, candidate.acceptedScientificName],
    ['identity.family', record.identity.family, candidate.family],
    ['identity.genus', record.identity.genus, candidate.genus],
    ['providerMappings.gbif', record.providerMappings?.gbif, candidate.providerMappings.gbif]
  ]) if (String(current) !== String(expected)) add('BLOCKER', id, relative(file), field, String(current), candidateSource, `正式记录与审核候选“${expected}”不一致。`, '重新核对来源并使候选与唯一正式记录一致。');
  if (JSON.stringify(record.scientificSynonyms ?? []) !== JSON.stringify(candidate.scientificSynonyms ?? [])) add('BLOCKER', id, relative(file), 'scientificSynonyms', summarize(record.scientificSynonyms), candidateSource, '正式记录的科学异名与已核验候选不一致。', '逐项核验后同步，禁止凭模型记忆添加。');
  if ((record.identity.aliases ?? []).length) add('MAJOR', id, relative(file), 'identity.aliases', summarize(record.identity.aliases), candidateSource, '新增400种存在候选清单未逐项记录的中文别名。', '补可靠直接来源和审核记录，或删除别名。');

  const gbif = await getJson(candidate.source.gbif);
  if (!gbif.ok) {
    sourceStats.inaccessible += 1;
    add('BLOCKER', id, relative(file), 'internalSourceRefs.gbif', candidate.source.gbif, candidate.source.gbif, `GBIF直接端点无法验证：${gbif.error}`, '重试或切换访问方式；验证完成前退回needs_review。');
  } else {
    const data = gbif.value;
    const problems = [];
    if (String(data.key) !== String(candidate.providerMappings.gbif)) problems.push(`key=${data.key}`);
    if (data.taxonomicStatus !== 'ACCEPTED') problems.push(`taxonomicStatus=${data.taxonomicStatus}`);
    if (data.rank !== 'SPECIES') problems.push(`rank=${data.rank}`);
    if (normalizedScientific(data.canonicalName) !== normalizedScientific(candidate.acceptedScientificName)) problems.push(`canonicalName=${data.canonicalName}`);
    if (data.genus !== candidate.acceptedScientificName.split(/\s+/u)[0]) problems.push(`genus=${data.genus}`);
    if (problems.length) add('BLOCKER', id, relative(file), 'identity/providerMappings.gbif', `${candidate.acceptedScientificName} / ${candidate.providerMappings.gbif}`, candidate.source.gbif, `GBIF未确认同一接受种：${problems.join(', ')}。`, '更正接受学名/ID，或用同规划组候选替换。');
    else { result.gbif = 'verified'; sourceStats.gbifVerified += 1; }
    result.gbifTaxonGroup = taxonGroupFromGbif(data);
    if (result.gbifTaxonGroup && result.gbifTaxonGroup !== record.catalogMetadata.taxonGroup) add('BLOCKER', id, relative(file), 'catalogMetadata.taxonGroup', record.catalogMetadata.taxonGroup, candidate.source.gbif, `GBIF分类对应${result.gbifTaxonGroup}。`, '修正类群标签并重新审核。');
  }

  const page = await getText(candidate.source.chineseNameAndMorphology);
  if (!page.ok) {
    sourceStats.inaccessible += 1;
    add('BLOCKER', id, relative(file), 'internalSourceRefs.iPlant', candidate.source.chineseNameAndMorphology, candidate.source.chineseNameAndMorphology, `iPlant具体页无法访问：${page.error}`, '按故障绕行策略重试；验证完成前退回needs_review。');
    return result;
  }
  const html = page.value;
  const spid = html.match(/var\s+spno\s*=\s*"([^"]+)"/u)?.[1];
  const latin = html.match(/var\s+latin2\s*=\s*"([^"]+)"/u)?.[1];
  const chinese = html.match(/var\s+spcname\s*=\s*"([^"]+)"/u)?.[1];
  if (!spid || /您的访问请求|请求可能存在威胁/u.test(html)) add('BLOCKER', id, relative(file), 'internalSourceRefs.iPlant', candidate.source.chineseNameAndMorphology, candidate.source.chineseNameAndMorphology, '页面不是可验证的iPlant具体物种页。', '更换访问方式或直接物种来源。');
  else if (spid !== String(candidate.verification.iPlantSpeciesId) || normalizedScientific(latin) !== normalizedScientific(candidate.acceptedScientificName) || chinese !== candidate.acceptedChineseName) add('BLOCKER', id, relative(file), 'identity', `${chinese} / ${latin} / spid ${spid}`, candidate.source.chineseNameAndMorphology, 'iPlant页面与候选中文名、接受学名或物种ID不一致。', '纠正候选和正式记录；无法消歧时替换物种。');
  else { result.iPlant = 'page-verified'; sourceStats.iPlantPageVerified += 1; }

  const [classification, plantInfo, flora] = await Promise.all([
    getJson(`https://www.iplant.cn/ashx/getclasssys.ashx?spid=${encodeURIComponent(spid ?? '')}`),
    getJson(`https://www.iplant.cn/ashx/plantinfo.ashx?spid=${encodeURIComponent(spid ?? '')}&type=descall`),
    getJson(`https://www.iplant.cn/ashx/getfrps.ashx?key=${encodeURIComponent(latin ?? '')}`)
  ]);
  if (!classification.ok) add('BLOCKER', id, relative(file), 'identity.family/genus', `${record.identity.family}/${record.identity.genus}`, candidate.source.chineseNameAndMorphology, `iPlant分类接口无法验证：${classification.error}`, '重试分类接口或补另一直接中文分类来源。');
  else if (classification.value.famctxt !== record.identity.family || classification.value.genctxt !== record.identity.genus || classification.value.genl !== candidate.acceptedScientificName.split(/\s+/u)[0]) add('BLOCKER', id, relative(file), 'identity.family/genus', `${record.identity.family}/${record.identity.genus}`, candidate.source.chineseNameAndMorphology, `iPlant返回${classification.value.famctxt}/${classification.value.genctxt}（${classification.value.genl}）。`, '修正中文科属或分类单元。');
  else sourceStats.iPlantClassificationVerified += 1;

  if (!plantInfo.ok || !Array.isArray(plantInfo.value?.spdesc)) add('BLOCKER', id, relative(file), 'sourceFacts', summarize(record.sourceFacts), candidate.source.chineseNameAndMorphology, `iPlant形态接口无法验证：${plantInfo.error ?? 'invalid response'}`, '重试或补另一直接形态来源。');
  else {
    sourceStats.iPlantMorphologyVerified += 1;
    const decoded = decodedPlantInfo(plantInfo.value);
    const floraText = flora.ok ? stripHtml(flora.value?.frpsdesc ?? '') : '';
    const directCorpus = normalized(`${decoded.map((item) => item.text).join(' ')} ${floraText}`);
    const unsupported = sourceFactEntries(record.sourceFacts).filter(({ field, text }) => {
      if (field === 'lifeForm' && result.gbifTaxonGroup === 'fern' && normalized(text) === normalized('蕨类植物')) return false;
      const fact = normalized(text);
      return fact && !directCorpus.includes(fact) && !decoded.some((item) => overlap(normalized(item.text), fact));
    });
    if (!unsupported.length) result.facts = 'directly-supported';
    else if (candidate.source.supplementalMorphology) {
      result.facts = `supplemental-translation-review (${unsupported.length})`;
      sourceStats.supplementalTranslationReviews += 1;
    } else {
      add('BLOCKER', id, relative(file), 'sourceFacts', unsupported.map((item) => `${item.field}: ${item.text}`).join('；'), candidate.source.chineseNameAndMorphology, '一个或多个事实不能在iPlant形态/植物志正文中定位，且无补充形态来源。', '回到直接物种页修正事实，禁止扩大来源原意。');
    }
  }

  if (candidate.source.supplementalMorphology) {
    const supplemental = await getText(candidate.source.supplementalMorphology, candidate.source.supplementalMorphology.includes('efloras.org'));
    if (!supplemental.ok || supplemental.value.length < 500) {
      sourceStats.inaccessible += 1;
      add('BLOCKER', id, relative(file), 'internalSourceRefs.supplemental', candidate.source.supplementalMorphology, candidate.source.supplementalMorphology, `补充形态直接页无法访问：${supplemental.error ?? 'empty response'}`, '重试或改用另一权威直接物种页。');
    } else {
      const sourceText = stripHtml(supplemental.value).toLowerCase();
      const epithet = candidate.acceptedScientificName.split(/\s+/u).at(-1).toLowerCase();
      if (!sourceText.includes(epithet)) add('BLOCKER', id, relative(file), 'internalSourceRefs.supplemental', candidate.source.supplementalMorphology, candidate.source.supplementalMorphology, '补充来源页面未能确认目标物种名称。', '替换为确切物种页。');
      else { result.supplemental = 'verified'; sourceStats.supplementalVerified += 1; }
    }
  }
  return result;
}

function buildReport(counts) {
  const classificationCounts = countTags(records.map(({ record }) => record), 'taxonGroup');
  const growthCounts = countTags(records.map(({ record }) => record), 'growthForms');
  const sceneCounts = countTags(records.map(({ record }) => record), 'sceneTags');
  const occurrenceCounts = countTags(records.map(({ record }) => record), 'occurrenceTypes');
  const useCounts = countTags(records.map(({ record }) => record), 'useTags');
  const coverageCounts = new Map();
  for (const candidate of candidateBatch.candidates) for (const group of candidate.requestedCoverageGroups) coverageCounts.set(group, (coverageCounts.get(group) ?? 0) + 1);
  const mappingsById = new Set(mappingFile.mappings.map((mapping) => mapping.canonicalTaxonId));
  const failedIds = new Set(issues.filter((issue) => issue.level === 'BLOCKER' || issue.level === 'MAJOR').map((issue) => issue.id).filter((id) => recordById.has(id)));
  const publishable = records.map(({ record }) => record.id).filter((id) => !failedIds.has(id));
  const duplicateIssues = issues.filter((issue) => /重复|冲突|multiple|belongs to/u.test(issue.reason));
  const sourceFailures = new Set(issues.filter((issue) => /无法访问|无法验证|不能在|来源页面未能/u.test(issue.reason)).map((issue) => issue.id));
  const lines = [
    '# WildSight 500种植物知识库部署前全量审核',
    '',
    `> 审核日期：${auditDate}。本报告由 \`npm run audit:knowledge-500\` 生成；审核器只读取知识JSON、候选、基线、映射和实时权威来源，仅写入本报告。`,
    '',
    '## 结论',
    '',
    `- 审核物种数：${records.length}（原100种回归审核；新增400种逐条实时分类、中文身份、形态来源和内容审核）`,
    `- published/reviewed：${records.filter(({ record }) => record.status === 'published' && record.reviewStatus === 'reviewed').length}`,
    `- L2：${records.filter(({ record }) => isL2(record)).length}`,
    `- 名称映射物种：${records.filter(({ record }) => mappingsById.has(record.id)).length}/${records.length}；映射条目：${mappingFile.mappings.length}`,
    `- BLOCKER：${counts.BLOCKER}`,
    `- MAJOR：${counts.MAJOR}`,
    `- MINOR：${counts.MINOR}`,
    `- 批次是否通过：${counts.BLOCKER === 0 && counts.MAJOR === 0 ? '通过' : '不通过'}`,
    '',
    '## 实时来源核验',
    '',
    `- GBIF接受种、SPECIES等级、canonicalName及ID一致：${sourceStats.gbifVerified}/${candidateBatch.candidates.length}`,
    `- iPlant具体页中文名、学名和物种ID一致：${sourceStats.iPlantPageVerified}/${candidateBatch.candidates.length}`,
    `- iPlant中文科属分类接口一致：${sourceStats.iPlantClassificationVerified}/${candidateBatch.candidates.length}`,
    `- iPlant逐字段形态接口可用：${sourceStats.iPlantMorphologyVerified}/${candidateBatch.candidates.length}`,
    `- 补充FNA/NC State直接页可访问且指向目标物种：${sourceStats.supplementalVerified}/${candidateBatch.candidates.filter((candidate) => candidate.source.supplementalMorphology).length}`,
    `- 使用补充英文直接页、逐条保留中文事实转述审查标记：${sourceStats.supplementalTranslationReviews}`,
    `- 无法访问的来源请求：${sourceStats.inaccessible}`,
    '',
    '## 覆盖统计',
    '',
    `- 类群：${formatCounts(classificationCounts)}`,
    `- 生活型：${formatCounts(growthCounts)}`,
    `- 场景：${formatCounts(sceneCounts)}`,
    `- 发生类型：${formatCounts(occurrenceCounts)}`,
    `- 用途：${formatCounts(useCounts) || '无标签'}`,
    `- 新增400规划组：${formatCounts(coverageCounts)}`,
    '',
    '## 问题明细',
    ''
  ];
  if (!issues.length) lines.push('未发现问题。', '');
  else for (const [index, issue] of issues.entries()) lines.push(
    `### ${index + 1}. ${issue.level} — ${issue.id} — ${issue.field}`,
    '',
    `- 等级：${issue.level}`,
    `- 物种ID：${issue.id}`,
    `- 文件路径：\`${issue.file}\``,
    `- 字段：\`${issue.field}\``,
    `- 当前内容摘要：${escapeMarkdown(issue.current)}`,
    `- 对应来源：${escapeMarkdown(issue.source)}`,
    `- 问题原因：${escapeMarkdown(issue.reason)}`,
    `- 建议修改方式：${escapeMarkdown(issue.suggestion)}`,
    ''
  );
  lines.push(
    '## 新增400种逐条审核结果',
    '',
    '| 序号 | 物种ID | 中文名 | GBIF | iPlant身份 | sourceFacts | 补充来源 | 最终状态 |',
    '| ---: | --- | --- | --- | --- | --- | --- | --- |'
  );
  for (const candidate of candidateBatch.candidates) {
    const result = perSpecies.get(candidate.resolvedCanonicalTaxonId) ?? { gbif: 'not-run', iPlant: 'not-run', facts: 'not-run', supplemental: 'not-run' };
    const problem = issues.some((issue) => issue.id === candidate.resolvedCanonicalTaxonId && ['BLOCKER', 'MAJOR'].includes(issue.level));
    lines.push(`| ${candidate.planning.sequence} | ${candidate.resolvedCanonicalTaxonId} | ${candidate.acceptedChineseName} | ${result.gbif} | ${result.iPlant} | ${result.facts} | ${result.supplemental} | ${problem ? '退回needs_review' : '可发布'} |`);
  }
  lines.push(
    '',
    '## 汇总清单',
    '',
    `- 可以继续发布的物种：${publishable.length === records.length ? `全部${records.length}种` : publishable.join('、')}`,
    `- 必须退回needs_review的物种：${failedIds.size ? [...failedIds].sort().join('、') : '无'}`,
    `- 重复或疑似重复物种：${duplicateIssues.length ? duplicateIssues.map((issue) => issue.id).join('、') : '无'}`,
    `- 来源无法验证的物种：${sourceFailures.size ? [...sourceFailures].sort().join('、') : '无'}`,
    '- API内部字段泄漏：审核全部500种的公开白名单；自动化路由测试另行作为最终门禁执行。',
    '- 百度识别调用：未调用；本审核只核验本地人工名称映射，不消耗识别额度。',
    ''
  );
  return `${lines.join('\n')}\n`;
}

function add(level, id, file, field, current, source, reason, suggestion) {
  issues.push({ level, id, file, field, current: summarize(current), source: summarize(source), reason, suggestion });
}
function countIssues() { return issues.reduce((result, issue) => ({ ...result, [issue.level]: result[issue.level] + 1 }), { BLOCKER: 0, MAJOR: 0, MINOR: 0 }); }
function unique(map, key, id, file, label) {
  if (!key) return;
  const owner = map.get(key);
  if (owner && owner !== id) add('BLOCKER', id, relative(file), label, key, fileById.get(owner) ?? 'species/', `${label}与${owner}重复。`, '核对分类单元后合并重复记录或更正错误值。');
  else map.set(key, id);
}
function canonicalId(name) { return String(name ?? '').normalize('NFKD').toLowerCase().replace(/×/gu, ' x ').replace(/[^a-z0-9]+/gu, '-').replace(/^-|-$/gu, ''); }
function normalized(value) { return String(value ?? '').normalize('NFKC').toLowerCase().replace(/<[^>]*>/gu, '').replace(/[\s，。；;、：:,.!?！？()（）\[\]【】“”'"‘’\-–—/]/gu, ''); }
function normalizedScientific(value) { return String(value ?? '').trim().replace(/\s+/gu, ' ').toLowerCase(); }
function normalizedChinese(value) { return String(value ?? '').trim().replace(/\s+/gu, ''); }
function overlap(left, right) {
  if (!left || !right) return false;
  if (left.includes(right) || right.includes(left)) return true;
  const shorter = left.length <= right.length ? left : right;
  const longer = left.length <= right.length ? right : left;
  const window = Math.min(16, shorter.length);
  return window >= 6 && [...Array(shorter.length - window + 1).keys()].some((index) => longer.includes(shorter.slice(index, index + window)));
}
function flattenStrings(value) {
  if (typeof value === 'string') return [value];
  if (Array.isArray(value)) return value.flatMap(flattenStrings);
  if (value && typeof value === 'object') return Object.values(value).flatMap(flattenStrings);
  return [];
}
function sourceFactEntries(facts) {
  return Object.entries(facts ?? {}).flatMap(([field, value]) => field === 'diagnosticTraits'
    ? (value ?? []).map((text, index) => ({ field: `${field}[${index}]`, text }))
    : typeof value === 'string' && value ? [{ field, text: value }] : []);
}
function decodedPlantInfo(plantInfo) {
  return (plantInfo.spdesc ?? []).flatMap((section) => (section.desclist ?? []).flatMap((item) => {
    if (!item.desc || String(item.desc).includes('$')) return [];
    try { return [{ section: section.t, field: item.subname, text: Buffer.from(String(item.desc), 'base64').toString('utf8').replace(/\s+/gu, ' ').trim() }]; } catch { return []; }
  }));
}
function stripHtml(value) { return String(value ?? '').replace(/<script[\s\S]*?<\/script>/giu, ' ').replace(/<style[\s\S]*?<\/style>/giu, ' ').replace(/<[^>]+>/gu, ' ').replace(/&nbsp;|&amp;|&lt;|&gt;|&#39;|&quot;/gu, ' ').replace(/\s+/gu, ' ').trim(); }
function taxonGroupFromGbif(data) {
  const text = `${data.phylum ?? ''} ${data.class ?? ''} ${data.order ?? ''} ${data.family ?? ''}`;
  if (/Bryophyta|Marchantiophyta|Anthocerotophyta/iu.test(text)) return 'bryophyte';
  if (/Polypodiopsida|Equisetopsida|Lycopodiopsida/iu.test(text)) return 'fern';
  if (/Pinopsida|Ginkgoopsida|Cycadopsida|Gnetopsida|Pinaceae|Cupressaceae|Taxaceae|Ginkgoaceae|Cycadaceae/iu.test(text)) return 'gymnosperm';
  if (data.kingdom === 'Plantae') return 'angiosperm';
  return '';
}
function isL2(record) {
  const knowledge = record.knowledge ?? {};
  return Boolean(record.id && record.identity?.acceptedChineseName && record.identity?.scientificName && record.identity?.family && record.identity?.genus && knowledge.summary && knowledge.appearance && knowledge.growthHabit && knowledge.observationReminder && ['keyCharacteristics', 'identificationReferences', 'howToConfirm', 'observationTips'].every((field) => Array.isArray(knowledge[field]) && knowledge[field].length >= 2));
}
function countTags(sourceRecords, field) {
  const result = new Map();
  for (const record of sourceRecords) {
    const raw = record.catalogMetadata?.[field];
    for (const value of (Array.isArray(raw) ? raw : raw ? [raw] : [])) result.set(value, (result.get(value) ?? 0) + 1);
  }
  return result;
}
function formatCounts(counts) { return [...counts.entries()].map(([key, value]) => `${key} ${value}`).join('；'); }
function sourceSummary(record) { return (record.internalSourceRefs ?? []).map((source) => source.url).join('; ') || 'none'; }
function summarize(value) {
  const text = typeof value === 'string' ? value : JSON.stringify(value);
  const compact = String(text ?? '').replace(/\s+/gu, ' ').trim();
  return compact.length > 240 ? `${compact.slice(0, 237)}…` : compact || '(empty)';
}
function escapeMarkdown(value) { return String(value ?? '').replace(/\|/gu, '\\|').replace(/\n/gu, ' '); }
function relative(file) { return path.relative(serverRoot, file).replaceAll(path.sep, '/'); }
async function json(file) { return JSON.parse(await readFile(file, 'utf8')); }
async function readRecords() {
  const files = (await readdir(speciesDirectory)).filter((file) => file.endsWith('.json')).sort();
  return Promise.all(files.map(async (file) => ({ file: path.join(speciesDirectory, file), record: await json(path.join(speciesDirectory, file)) })));
}
async function mapWithConcurrency(items, limit, callback) {
  const results = new Array(items.length);
  let next = 0;
  async function worker() {
    while (next < items.length) {
      const index = next++;
      results[index] = await callback(items[index]);
      if ((index + 1) % 25 === 0 || index + 1 === items.length) console.log(`Audited expansion source ${index + 1}/${items.length}`);
    }
  }
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, worker));
  return results;
}
async function getText(url, insecureTls = false) {
  let lastError;
  for (let attempt = 0; attempt < 3; attempt += 1) {
    try {
      if (insecureTls) {
        const { stdout } = await execFileAsync('curl', ['-skL', '--max-time', '30', '--retry', '2', '-A', userAgent, url], { maxBuffer: 12 * 1024 * 1024 });
        if (!stdout) throw new Error('empty response');
        return { ok: true, value: stdout };
      }
      const response = await fetch(url, { headers: { 'user-agent': userAgent }, signal: AbortSignal.timeout(30_000) });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const text = await response.text();
      if (!text) throw new Error('empty response');
      return { ok: true, value: text };
    } catch (error) { lastError = error; }
  }
  return { ok: false, error: lastError?.message ?? 'request failed' };
}
async function getJson(url) {
  const response = await getText(url);
  if (!response.ok) return response;
  try { return { ok: true, value: JSON.parse(response.value) }; } catch (error) { return { ok: false, error: `invalid JSON: ${error.message}` }; }
}
