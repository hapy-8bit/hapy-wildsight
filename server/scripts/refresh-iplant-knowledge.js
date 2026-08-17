#!/usr/bin/env node

/*
 * Replace the provisional batch-100 copy with concise, taxon-specific facts
 * extracted from the iPlant direct species page already cited by each record.
 *
 * The script is deliberately opt-in for writes. It fetches and validates a
 * record before each atomic rename, so a bad page or a failed request cannot
 * leave a partly-written JSON file. Use --id first to inspect one record, then
 * use --all --apply only after that output has been reviewed.
 *
 * Usage:
 *   node scripts/refresh-iplant-knowledge.js --id=cinnamomum-camphora
 *   node scripts/refresh-iplant-knowledge.js --id=cinnamomum-camphora --apply
 *   node scripts/refresh-iplant-knowledge.js --all --apply
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { auditOne } from './audit-iplant-source-data.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const speciesDirectory = path.join(root, 'data', 'plant-knowledge', 'species');
const genericSummary = /本批.*已审核物种/u;
const observationReminder = '植物识别仅供自然观察与记录参考；请勿仅凭识别结果判断植物是否可食用、可药用或对人和宠物安全。';

const manualFallbackProfiles = {
  'dracaena-trifasciata': {
    sourceFacts: { lifeForm: '无茎的常绿多年生草本。', stem: '地下根茎粗壮，叶从基部莲座状抽生。', leaf: '叶直立、肉质、剑形，深绿色并具浅灰绿色横纹。', flower: '成熟植株可开小型绿白色花。', fruit: '可结橙色浆果；室内植株少见花果。', habitat: '', distribution: '', floweringPeriod: '', diagnosticTraits: ['直立而尖的剑形肉质叶。', '深绿叶面上的浅灰绿色横向条纹。'] },
    knowledge: { summary: '虎尾兰是无茎的常绿多年生草本；直立的剑形肉质叶从粗壮根茎形成莲座，叶面有浅色横纹。', identificationReferences: ['叶片直立、肉质且剑形。', '深绿叶面具浅灰绿色横向条纹。'], howToConfirm: ['拍摄整株莲座与叶基部，确认叶是否从基部成丛抽生。', '近拍叶面横纹和尖端，并避免仅凭栽培品种的叶色判断。'], appearance: '叶直立、肉质而剑形，深绿色叶面有浅灰绿色横纹。', growthHabit: '无茎的常绿多年生草本。', keyCharacteristics: ['粗壮根茎上的莲座状叶丛。', '带浅色横纹的直立剑形叶。'], observationTips: ['同时拍叶基部、叶片正面与侧面。', '室内植株花果少见，优先记录叶形、叶质和横纹。'], confusableSpecies: [], observationReminder },
    source: { id: 'mobot-dracaena-trifasciata', title: 'Missouri Botanical Garden Plant Finder: Dracaena trifasciata', url: 'https://www.missouribotanicalgarden.org/PlantFinder/PlantFinderDetails.aspx?taxonid=458447', accessedAt: '2026-08-16', usedFor: ['habit', 'leaf', 'flower', 'fruit', 'diagnostic traits'] },
  },
  'hedera-helix': {
    sourceFacts: { lifeForm: '常绿木质藤本。', stem: '茎可攀援，借不定根附着于支撑物。', leaf: '幼枝叶常3—5裂；开花枝叶通常不裂而呈卵形或菱状卵形。', flower: '花小，黄绿色，常聚成伞形花序。', fruit: '果为近球形浆果，成熟呈深色。', habitat: '', distribution: '', floweringPeriod: '', diagnosticTraits: ['攀援茎上的不定根。', '幼枝裂叶与开花枝不裂叶的差异。'] },
    knowledge: { summary: '洋常春藤为常绿木质藤本，能以茎上的不定根攀附；幼枝常见裂叶，开花枝叶多不裂。', identificationReferences: ['攀援茎具有附着用不定根。', '幼枝裂叶、开花枝不裂叶是重要观察线索。'], howToConfirm: ['拍摄攀援茎和与墙面或树干相接处，观察不定根。', '分别记录幼枝与成熟开花枝的叶形，避免只用一类叶片判断。'], appearance: '幼枝叶常裂，开花枝叶多为不裂的卵形或菱状卵形。', growthHabit: '常绿木质藤本。', keyCharacteristics: ['攀援茎上的不定根。', '不同枝龄的叶形差异。'], observationTips: ['拍摄叶片正反面、叶柄和攀附茎。', '若有花果，再补拍伞形花序或深色浆果。'], confusableSpecies: [], observationReminder },
    source: { id: 'rhs-hedera-helix', title: 'Royal Horticultural Society: Hedera helix', url: 'https://www.rhs.org.uk/plants/8726/hedera-helix/details', accessedAt: '2026-08-16', usedFor: ['habit', 'stem', 'leaf', 'flower', 'fruit', 'diagnostic traits'] },
  },
  'pontederia-crassipes': {
    sourceFacts: { lifeForm: '多年生漂浮或挺水水生草本。', stem: '匍匐茎可产生新株并形成密集浮垫。', leaf: '叶聚生，叶柄膨大呈囊状，有助于漂浮；叶片宽卵形至近圆形。', flower: '穗状花序具蓝紫色花，花被片常有黄色斑点。', fruit: '蒴果。', habitat: '静水或缓流水面及岸边。', distribution: '', floweringPeriod: '', diagnosticTraits: ['膨大的囊状叶柄。', '蓝紫色花与花被片上的黄色斑点。'] },
    knowledge: { summary: '凤眼莲是漂浮或挺水的多年生水生草本；膨大的囊状叶柄和蓝紫色花是野外确认的重要线索。', identificationReferences: ['叶柄膨大呈囊状。', '蓝紫色花的花被片常见黄色斑点。'], howToConfirm: ['从安全岸边拍整体浮垫、叶丛和膨大叶柄。', '花期补拍花序正面，核对蓝紫色花与黄色斑点。'], appearance: '叶丛漂浮或挺出水面，宽卵形叶由膨大叶柄托起。', growthHabit: '多年生漂浮或挺水水生草本。', keyCharacteristics: ['囊状膨大的叶柄。', '蓝紫色并常带黄色斑点的花。'], observationTips: ['不进入水体或在湿滑岸边采样。', '同时记录植株是漂浮、挺水还是附着在岸边。'], confusableSpecies: [], observationReminder },
    source: { id: 'cabi-pontederia-crassipes', title: 'CABI Invasive Species Compendium: Pontederia crassipes', url: 'https://www.cabi.org/isc/datasheet/20544', accessedAt: '2026-08-16', usedFor: ['habit', 'stem', 'leaf', 'flower', 'fruit', 'habitat', 'diagnostic traits'] },
  },
  'pteridium-aquilinum': {
    sourceFacts: { lifeForm: '多年生陆生蕨类。', stem: '根茎粗壮而横走，可在地下延伸。', leaf: '叶柄直立，叶片大而近三角形，通常二至三回羽状分裂。', flower: '', fruit: '', habitat: '常见于林缘、开阔地或受扰动生境。', distribution: '', floweringPeriod: '', diagnosticTraits: ['横走根茎与疏生的大型叶。', '近三角形、二至三回羽状分裂的叶片。'] },
    knowledge: { summary: '欧洲蕨是多年生陆生蕨类；大型近三角形叶片通常二至三回羽状分裂，并由横走根茎抽出。', identificationReferences: ['叶片大而近三角形，通常二至三回羽状分裂。', '根茎粗壮横走，叶不密集成簇。'], howToConfirm: ['拍摄完整叶片轮廓和叶柄基部，记录叶片的分裂层次。', '在不挖掘植株的前提下观察叶是否由地下横走根茎间隔抽生。'], appearance: '叶片大型近三角形，常见二至三回羽状分裂。', growthHabit: '多年生陆生蕨类。', keyCharacteristics: ['横走根茎。', '疏生的大型三角形多回羽状叶。'], observationTips: ['拍整叶轮廓并补拍羽片边缘和叶背。', '不要为查看根茎而挖掘或破坏群落。'], confusableSpecies: [], observationReminder },
    source: { id: 'illinoiswildflowers-pteridium-aquilinum', title: 'Illinois Wildflowers: Bracken Fern (Pteridium aquilinum)', url: 'https://www.illinoiswildflowers.info/grasses/plants/bracken_fern.htm', accessedAt: '2026-08-16', usedFor: ['habit', 'stem', 'leaf', 'habitat', 'diagnostic traits'] },
  },
};

function compact(text, maximum = 68) {
  const normalized = String(text || '').replace(/\s+/gu, ' ').trim();
  if (normalized.length <= maximum) return normalized;
  const sentenceEnd = normalized.slice(0, maximum).search(/[。；;]/u);
  if (sentenceEnd >= 24) return normalized.slice(0, sentenceEnd + 1);
  return `${normalized.slice(0, maximum - 1)}…`;
}

function trimPunctuation(text) {
  return String(text || '').replace(/[。；;、]+$/u, '').trim();
}

function signature(fact) {
  const withoutLabel = String(fact.text || '').replace(new RegExp(`^${fact.label}[：:]*`, 'u'), '').trim();
  return compact(withoutLabel, 46);
}

function sourceFieldMap(auditResult) {
  const entries = [
    ...auditResult.sections.morphology,
    ...auditResult.sections.ecology,
  ];
  const facts = new Map();
  for (const entry of entries) {
    if (entry.text && !facts.has(entry.field)) facts.set(entry.field, compact(entry.text));
  }
  return facts;
}

function firstFact(facts, labels) {
  for (const label of labels) {
    if (facts.has(label)) return { label, text: facts.get(label) };
  }
  return null;
}

function featureFacts(facts) {
  const labels = ['叶', '花', '果', '茎', '枝', '根', '根茎', '花序', '孢子囊', '孢子', '株'];
  const selected = labels.map((label) => firstFact(facts, [label])).filter(Boolean);
  return selected.slice(0, 3);
}

function createKnowledge(record, facts) {
  const lifeForm = firstFact(facts, ['生活型', '生活形'])?.text || record.sourceFacts.lifeForm;
  const features = featureFacts(facts);
  if (features.length < 2) {
    throw new Error(`${record.id}: iPlant page has fewer than two usable diagnostic fact groups`);
  }
  const labels = features.map((item) => item.label).join('、');
  const featureLines = features.slice(0, 2).map((item) => `${item.label}：${item.text}`);
  const firstSignature = signature(features[0]);
  const secondSignature = signature(features[1]);
  return {
    sourceFacts: {
      lifeForm: compact(lifeForm),
      stem: firstFact(facts, ['茎', '枝', '株'])?.text || '',
      leaf: firstFact(facts, ['叶'])?.text || '',
      flower: firstFact(facts, ['花', '花序'])?.text || '',
      fruit: firstFact(facts, ['果'])?.text || '',
      habitat: firstFact(facts, ['生境', '生态'])?.text || '',
      distribution: '',
      floweringPeriod: '',
      diagnosticTraits: featureLines,
    },
    knowledge: {
      summary: `${record.identity.acceptedChineseName}为${trimPunctuation(lifeForm)}；${features[0].label}${firstSignature}。观察时再结合${labels}等结构确认。`,
      identificationReferences: featureLines,
      howToConfirm: [
        `先拍摄植株整体，再近拍${labels}等可见结构。`,
        `先核对${features[0].label}：${firstSignature}；再以${features[1].label}${secondSignature}交叉确认。`,
      ],
      appearance: `${features[0].label}${firstSignature}；${features[1].label}${secondSignature}。`,
      growthHabit: compact(lifeForm),
      keyCharacteristics: featureLines,
      observationTips: [
        `将${labels}放在同一组照片中，保留大小或枝条连接关系。`,
        '花、果或孢子结构不可见时，保留不同角度的叶和茎部照片以便后续确认。',
      ],
      confusableSpecies: [],
      observationReminder: '植物识别仅供自然观察与记录参考；请勿仅凭识别结果判断植物是否可食用、可药用或对人和宠物安全。',
    },
  };
}

function readRecords({ id, all }) {
  const records = fs.readdirSync(speciesDirectory)
    .filter((file) => file.endsWith('.json'))
    .sort()
    .map((file) => ({ file, record: JSON.parse(fs.readFileSync(path.join(speciesDirectory, file), 'utf8')) }))
    .filter(({ record }) => (all ? genericSummary.test(record.knowledge?.summary || '') : record.id === id));
  if (all && records.length === 0) throw new Error('No provisional records found');
  if (!all && records.length !== 1) throw new Error(`Expected exactly one record for --id=${id}`);
  return records;
}

function atomicWrite(file, data) {
  const target = path.join(speciesDirectory, file);
  const temporary = path.join(speciesDirectory, `.${file}.${process.pid}.tmp`);
  fs.writeFileSync(temporary, `${JSON.stringify(data, null, 2)}\n`, 'utf8');
  JSON.parse(fs.readFileSync(temporary, 'utf8'));
  fs.renameSync(temporary, target);
}

async function main() {
  const all = process.argv.includes('--all');
  const apply = process.argv.includes('--apply');
  const id = process.argv.find((argument) => argument.startsWith('--id='))?.slice('--id='.length);
  if (all === Boolean(id)) throw new Error('Pass exactly one of --all or --id=<canonicalTaxonId>');

  const targets = readRecords({ id, all });
  const failures = [];
  let refreshed = 0;
  for (const { file, record } of targets) {
    const audit = await auditOne(record);
    try {
      if (audit.status !== 'ok') throw new Error(audit.error || audit.status);
      if (!audit.acceptedChineseNameFound) throw new Error('accepted Chinese name was not present on the direct iPlant page');
      const manualFallback = manualFallbackProfiles[record.id];
      const replacement = manualFallback || createKnowledge(record, sourceFieldMap(audit));
      const updated = { ...record, ...replacement };
      if (manualFallback) {
        updated.internalSourceRefs = [
          ...record.internalSourceRefs.map((ref) => /iplant\.cn\/info\//.test(ref.url)
            ? { ...ref, usedFor: ['Chinese name'] }
            : ref),
          manualFallback.source,
        ];
        delete updated.source;
      }
      if (genericSummary.test(updated.knowledge.summary)) throw new Error('provisional summary remains');
      if (apply) atomicWrite(file, updated);
      refreshed += 1;
      console.log(`${apply ? 'refreshed' : 'verified'}: ${record.id}`);
    } catch (error) {
      failures.push({ id: record.id, error: error.message });
      console.error(`failed: ${record.id} (${error.message})`);
    }
  }
  console.log(JSON.stringify({ mode: apply ? 'apply' : 'dry-run', targets: targets.length, refreshed, failures }, null, 2));
  if (failures.length) process.exitCode = 1;
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
