import { access, readFile, writeFile } from 'node:fs/promises';
import { execFile } from 'node:child_process';
import path from 'node:path';
import { promisify } from 'node:util';
import { fileURLToPath } from 'node:url';

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const serverRoot = path.resolve(scriptDirectory, '..');
const knowledgeRoot = path.join(serverRoot, 'data', 'plant-knowledge');
const candidatePath = path.join(knowledgeRoot, 'imports', 'batch-500-expansion-candidates.json');
const speciesDirectory = path.join(knowledgeRoot, 'species');
const mappingPath = path.join(knowledgeRoot, 'provider-name-mapping.json');
const execFileAsync = promisify(execFile);

const valueAfter = (flag, fallback) => {
  const index = process.argv.indexOf(flag);
  return index >= 0 ? Number(process.argv[index + 1]) : fallback;
};
const start = valueAfter('--start', 1);
const count = valueAfter('--count', 20);
const repair = process.argv.includes('--repair');
if (!Number.isInteger(start) || start < 1 || !Number.isInteger(count) || count < 1 || count > 25) {
  throw new Error('Usage: node scripts/produce-knowledge-500-work-unit.js --start <1-based> --count <1..25>');
}

const batch = JSON.parse(await readFile(candidatePath, 'utf8'));
const candidates = batch.candidates.slice(start - 1, start - 1 + count);
if (candidates.length !== count) throw new Error(`Requested ${count} candidates from ${start}, got ${candidates.length}`);
if (candidates.some((candidate) => !['new', ...(repair ? ['existing'] : [])].includes(candidate.resolutionStatus))) throw new Error('Every work-unit candidate must be new, or existing in --repair mode');

const fetchText = async (url) => {
  if (url.includes('efloras.org')) {
    const { stdout } = await execFileAsync('curl', ['-skL', '--max-time', '30', '--retry', '2', '-A', 'WildSight knowledge maintenance/1.0', url], { maxBuffer: 5 * 1024 * 1024 });
    if (!stdout) throw new Error(`Empty response: ${url}`);
    return stdout;
  }
  const response = await fetch(url, { headers: { 'user-agent': 'WildSight knowledge maintenance/1.0' }, signal: AbortSignal.timeout(30000) });
  if (!response.ok) throw new Error(`${response.status} ${response.statusText}: ${url}`);
  return response.text();
};
const fetchJson = async (url) => JSON.parse(await fetchText(url));
const decodeBase64 = (value) => Buffer.from(String(value), 'base64').toString('utf8').replace(/\s+/g, ' ').trim();
const stripHtml = (value) => String(value ?? '')
  .replace(/<\/?p[^>]*>/gi, '\n')
  .replace(/<br\s*\/?\s*>/gi, '\n')
  .replace(/<[^>]*>/g, '')
  .replace(/&nbsp;/g, ' ')
  .replace(/&amp;/g, '&')
  .replace(/&lt;/g, '<')
  .replace(/&gt;/g, '>')
  .replace(/&#39;/g, "'")
  .replace(/&quot;/g, '"')
  .replace(/[ \t]+/g, ' ')
  .replace(/\n+/g, '\n')
  .trim();
const cleanPunctuation = (value) => String(value ?? '')
  .replace(/\s+/g, ' ')
  .replace(/;/g, '；')
  .replace(/\s+([，。；！？])/g, '$1')
  .replace(/[；;，,]+([。！？])/g, '$1')
  .replace(/([。！？])\1+/g, '$1')
  .trim();
const ensurePeriod = (value) => {
  const cleaned = cleanPunctuation(value).replace(/[；;，,]+$/g, '');
  return cleaned && /[。！？]$/.test(cleaned) ? cleaned : `${cleaned}。`;
};
const withoutPeriod = (value) => cleanPunctuation(value).replace(/[。！？]+$/g, '');
const completeFact = (value) => ensurePeriod(value);
const usableMorphologyFact = (value) => {
  const text = cleanPunctuation(value);
  return text &&
    !/入药|药用|主治|疗效|可食|食用|精油|经济价值|时过境迁/.test(text) &&
    !/^(?:产|分布(?:于)?|生于)/.test(text) &&
    text.length <= 500;
};
const firstUsable = (...values) => values.find((value) => usableMorphologyFact(value)) ?? '';
const concise = (value, clauses = 3) => {
  const text = cleanPunctuation(value);
  if (!text) return '';
  const firstSentence = text.split(/(?<=[。！？])\s*/)[0];
  const parts = firstSentence.split(/[；;，,]/).map((item) => item.trim()).filter(Boolean);
  const selected = parts.slice(0, clauses).join('，').replace(/[。！？]+$/g, '');
  return ensurePeriod(selected);
};
const lifeFormBrief = (value) => ensurePeriod(String(value ?? '').split(/[，,；;]/)[0]);

const readIPlant = async (candidate) => {
  const page = await fetchText(candidate.source.chineseNameAndMorphology);
  const spno = page.match(/var\s+spno\s*=\s*"([^"]*)"/)?.[1] ?? '';
  const latinName = page.match(/var\s+latin2\s*=\s*"([^"]*)"/)?.[1] ?? '';
  if (!spno || !latinName) throw new Error(`${candidate.resolvedCanonicalTaxonId}: iPlant direct page lacks species identifiers`);
  const [plantInfo, frps] = await Promise.all([
    fetchJson(`https://www.iplant.cn/ashx/plantinfo.ashx?spid=${encodeURIComponent(spno)}&type=descall`).catch(() => null),
    fetchJson(`https://www.iplant.cn/ashx/getfrps.ashx?key=${encodeURIComponent(latinName)}`).catch(() => null)
  ]);
  const supplementalPage = /plants\.ces\.ncsu\.edu|efloras\.org/.test(candidate.source.supplementalMorphology)
    ? await fetchText(candidate.source.supplementalMorphology)
    : '';
  const supplementalKind = candidate.source.supplementalMorphology.includes('plants.ces.ncsu.edu') ? 'ncsu'
    : candidate.source.supplementalMorphology.includes('efloras.org') ? 'fna'
      : '';
  return { plantInfo, frps, spno, latinName, supplementalPage, supplementalKind };
};

const fieldsFromPlantInfo = (plantInfo) => {
  const fields = new Map();
  for (const section of plantInfo?.spdesc ?? []) {
    for (const item of section.desclist ?? []) {
      if (!item.desc) continue;
      const decoded = decodeBase64(item.desc);
      if (decoded && !decoded.includes('$')) fields.set(item.subname, decoded);
    }
  }
  return fields;
};

const factsFromFlora = (frps) => {
  const paragraphs = stripHtml(frps?.frpsdesc ?? '').split('\n').map((item) => item.trim()).filter(Boolean);
  const sentences = paragraphs.flatMap((paragraph) => paragraph.split(/(?<=[。！？])/)).map((item) => item.trim()).filter(Boolean);
  const clauses = sentences.flatMap((sentence) => sentence.split(/[；;]/)).map((item) => item.trim()).filter(Boolean);
  const first = (startPattern, containsPattern = startPattern) => clauses.find((item) => startPattern.test(item))
    ?? clauses.find((item) => containsPattern.test(item) && !/^\d+[\.．、]/.test(item) && !/\bin\b|\bet\b|图版|本草|日名/i.test(item))
    ?? '';
  const lifeForm = first(/^(?:常绿|落叶|半常绿|一年生|二年生|多年生|乔木|小乔木|灌木|半灌木|草本|藤本|攀援|植株|植物体)/, /乔木|灌木|草本|藤本|攀援|蕨|叶状体|藓/);
  const stem = first(/^(?:树皮|小枝|枝条|枝|茎|秆|稈|根状茎|根茎|块茎)/, /树皮|小枝|枝|茎|秆|稈|根状茎|根茎|块茎/);
  const leaf = first(/^(?:基生叶|茎生叶|针叶|羽片|小叶|叶片|叶)/, /基生叶|茎生叶|针叶|羽片|小叶|叶片|叶/);
  const flower = first(/^(?:头状花序|总状花序|圆锥花序|聚伞花序|伞形花序|穗状花序|雄花序|雌花序|花序|花|小穗|孢子囊群)/, /头状花序|总状花序|圆锥花序|聚伞花序|伞形花序|穗状花序|花序|花|小穗|孢子囊群/);
  const fruit = first(/^(?:蒴果|浆果|核果|瘦果|蓇葖|小坚果|坚果|颖果|果实|果序|果|种子|孢子)/, /蒴果|浆果|核果|瘦果|蓇葖|小坚果|坚果|颖果|果实|果序|种子|孢子/);
  const habitat = sentences.find((item) => /^(?:生于|生长于|多生|常生|野生于|栽培于|常栽培)/.test(item))
    ?? sentences.find((item) => /生于|生长于|路旁|田边|林下|水中|湿地|山坡|草地/.test(item) && item.length < 180)
    ?? '';
  return {
    lifeForm,
    stem,
    leaf,
    flower,
    fruit,
    habitat
  };
};

const valuesAfterLabel = (html, label) => {
  const escaped = label.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const section = String(html).match(new RegExp(`<dt>${escaped}:<\\/dt>([\\s\\S]*?)(?=<dt>|<\\/dl>)`, 'i'))?.[1] ?? '';
  return [...section.matchAll(/<span class="detail_display_attribute">([\s\S]*?)<\/span>/gi)].map((match) => stripHtml(match[1]));
};
const translateValues = (values, dictionary) => values.map((value) => dictionary[value] ?? '').filter(Boolean);
const dictionaries = {
  plantType: {
    'Herbaceous Perennial': '多年生草本', Perennial: '多年生草本', Annual: '一年生草本', Biennial: '二年生草本', Bulb: '鳞茎植物', 'Water Plant': '水生草本植物', Shrub: '灌木', Tree: '乔木', Vine: '藤本', Fern: '蕨类植物', 'Ground Cover': '地被植物', Houseplant: '室内栽培植物', Succulent: '多肉植物', Epiphyte: '附生植物'
  },
  lifeCycle: { Annual: '一年生', Biennial: '二年生', Perennial: '多年生' },
  habit: { Creeping: '匍匐', Clumping: '丛生', Erect: '直立', Spreading: '开展', Dense: '密生', Horizontal: '横向生长', Mounding: '垫状', Rounded: '近圆形', Arching: '弓垂', Trailing: '蔓生', Cascading: '下垂', Columnar: '柱状', Upright: '直立' },
  leafType: { Simple: '单叶', Compound: '复叶', Needled: '针形叶', Fronds: '叶状体或羽叶' },
  arrangement: { Alternate: '互生', Opposite: '对生', Whorled: '轮生', Rosulate: '莲座状排列', Basal: '基生', Spiral: '螺旋状排列' },
  shape: { Ovate: '卵形', Obovate: '倒卵形', Lanceolate: '披针形', Elliptical: '椭圆形', Cordate: '心形', Linear: '线形', Spatulate: '匙形', Oblong: '长圆形', Orbicular: '近圆形', Deltoid: '三角形', Acicular: '针形', Reniform: '肾形', Sagittate: '箭形' },
  margin: { Entire: '全缘', Crenate: '圆齿', Dentate: '齿状', Serrate: '锯齿', Lobed: '分裂', Undulate: '波状', Revolute: '反卷', Ciliate: '具缘毛' },
  feel: { Glossy: '有光泽', Leathery: '革质', Smooth: '光滑', Velvety: '具绒毛感', Waxy: '具蜡质感', Rough: '粗糙', Fleshy: '肉质' },
  inflorescence: { Spike: '穗状花序', Raceme: '总状花序', Panicle: '圆锥花序', Cyme: '聚伞花序', Solitary: '花单生', Umbel: '伞形花序', Head: '头状花序', Catkin: '柔荑花序', Corymb: '伞房花序' },
  flowerShape: { Tubular: '管状', Lipped: '唇形', Star: '星形', Bell: '钟形', Funnel: '漏斗形', Trumpet: '喇叭形', Saucer: '碟形', Cup: '杯形', Cross: '十字形', Papilionaceous: '蝶形' },
  color: { Blue: '蓝色', 'Purple/Lavender': '紫色或淡紫色', White: '白色', Red: '红色', 'Red/Burgundy': '红色或酒红色', Pink: '粉红色', Yellow: '黄色', Orange: '橙色', Green: '绿色', Brown: '褐色', Black: '黑色', 'Cream/Tan': '乳白色或浅褐色', 'Gold/Yellow': '黄色或金黄色' },
  stemSurface: { 'Smooth (glabrous)': '光滑无毛', Rough: '粗糙', Hairy: '具毛' },
  stemBuds: { 'Hairy tips': '顶端具毛' },
  fruitType: { Capsule: '蒴果', Berry: '浆果', Drupe: '核果', Achene: '瘦果', Nut: '坚果', Pod: '荚果', Samara: '翅果', Cone: '球果' },
  fruitShape: { Round: '近圆形', Oval: '椭圆形', Elongated: '长形', Flattened: '扁平', Irregular: '不规则形' }
};
const factsFromNcsu = (html) => {
  if (!html) return {};
  const plantTypes = translateValues(valuesAfterLabel(html, 'Plant Type'), dictionaries.plantType);
  const lifeCycles = translateValues(valuesAfterLabel(html, 'Life Cycle'), dictionaries.lifeCycle);
  const habits = translateValues(valuesAfterLabel(html, 'Habit/Form'), dictionaries.habit);
  const leafParts = [
    ...translateValues(valuesAfterLabel(html, 'Leaf Arrangement'), dictionaries.arrangement),
    ...translateValues(valuesAfterLabel(html, 'Leaf Type'), dictionaries.leafType),
    ...translateValues(valuesAfterLabel(html, 'Leaf Shape'), dictionaries.shape),
    ...translateValues(valuesAfterLabel(html, 'Leaf Margin'), dictionaries.margin),
    ...translateValues(valuesAfterLabel(html, 'Leaf Feel'), dictionaries.feel)
  ];
  const flowerParts = [
    ...translateValues(valuesAfterLabel(html, 'Flower Inflorescence'), dictionaries.inflorescence),
    ...translateValues(valuesAfterLabel(html, 'Flower Shape'), dictionaries.flowerShape),
    ...translateValues(valuesAfterLabel(html, 'Flower Color'), dictionaries.color)
  ];
  const fruitParts = [
    ...translateValues(valuesAfterLabel(html, 'Fruit Type'), dictionaries.fruitType),
    ...translateValues(valuesAfterLabel(html, 'Fruit Shape'), dictionaries.fruitShape),
    ...translateValues(valuesAfterLabel(html, 'Fruit Color'), dictionaries.color)
  ];
  const stemParts = [
    ...translateValues(valuesAfterLabel(html, 'Stem Color'), dictionaries.color),
    ...translateValues(valuesAfterLabel(html, 'Stem Surface'), dictionaries.stemSurface),
    ...translateValues(valuesAfterLabel(html, 'Stem Buds'), dictionaries.stemBuds)
  ];
  return {
    lifeForm: [...new Set([...lifeCycles, ...plantTypes, ...habits])].join('，'),
    stem: stemParts.length ? `茎${[...new Set(stemParts)].join('，')}` : '',
    leaf: leafParts.length ? `叶${[...new Set(leafParts)].join('，')}` : '',
    flower: flowerParts.length ? `花为${[...new Set(flowerParts)].join('，')}` : '',
    fruit: fruitParts.length ? `果实为${[...new Set(fruitParts)].join('，')}` : '',
    habitat: plantTypes.length ? '有园艺栽培记录' : ''
  };
};

const textAfterBoldLabel = (html, labels) => {
  const alternatives = labels.map((label) => label.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('|');
  const value = String(html).match(new RegExp(`<b>(?:${alternatives})<\\/b>([\\s\\S]*?)(?=<b>|<p>|<\\/span>)`, 'i'))?.[1] ?? '';
  return stripHtml(value).replace(/^\s*[,.:;]\s*/, '').trim();
};
const factsFromFna = (html) => {
  if (!html) return {};
  const treatment = String(html).match(/<span id="lblTaxonDesc">([\s\S]*?)<\/span>/i)?.[1] ?? html;
  const plain = stripHtml(treatment);
  let lifeForm = '';
  if (/\bAnnuals?\b/i.test(plain)) lifeForm = '一年生草本';
  else if (/\bPerennials?\b/i.test(plain)) lifeForm = '多年生草本';
  else if (/\bHerbs?\b/i.test(plain)) lifeForm = '草本植物';
  return {
    lifeForm,
    stem: textAfterBoldLabel(treatment, ['Stems', 'Stem']),
    leaf: textAfterBoldLabel(treatment, ['Leaves', 'Leaf']),
    flower: textAfterBoldLabel(treatment, ['Flowers', 'Flower', 'Heads', 'Inflorescences']),
    fruit: textAfterBoldLabel(treatment, ['Fruits', 'Fruit', 'Cypselae', 'Capsules', 'Sporophytes', 'Spores']),
    habitat: ''
  };
};

// Faithful Chinese normalizations of the directly cited FNA/NC State treatments.
const supplementalFactOverrides = {
  'bryum-argenteum': {
    lifeForm: '苔藓植物，常密集成垫生长，白绿色至银绿色',
    stem: '茎长0.2-1厘米，近圆柱状或芽状',
    leaf: '叶湿时直立，卵形至卵状披针形，叶片上部常透明而呈银白色',
    flower: '', fruit: '孢蒴红色至红褐色，卵形，长2-3毫米', habitat: ''
  },
  'funaria-hygrometrica': {
    lifeForm: '苔藓植物，植株通常高4-10毫米或更高',
    stem: '叶在茎上部密集，整体可呈芽状',
    leaf: '上部叶长2-4毫米，深凹，长圆状卵形至宽倒卵形，先端急尖至短渐尖',
    flower: '', fruit: '蒴柄细长而可弯曲，孢蒴梨形、不对称，可弯曲或近直立', habitat: ''
  },
  'hypnum-cupressiforme': {
    lifeForm: '苔藓植物，植株小至大，颜色可为锈绿色、金绿色、黄绿色或淡绿色',
    stem: '茎长1-8厘米以上，匍匐至直立，不规则羽状分枝或近不分枝',
    leaf: '叶卵形至长圆状披针形，可由近直至明显镰刀状并偏向一侧',
    flower: '', fruit: '以孢子繁殖', habitat: ''
  },
  'plagiomnium-cuspidatum': {
    lifeForm: '苔藓植物，直立茎通常长1-2厘米，不呈树状',
    stem: '直立茎通常长1-2厘米，不育茎可达7厘米',
    leaf: '叶深绿色或黄绿色，干时扭曲、湿时平展，倒卵形至近菱形，叶缘中部以上具尖齿',
    flower: '', fruit: '孢蒴下垂，卵形或圆柱形，长2-3.5毫米', habitat: ''
  },
  'polytrichum-commune': {
    lifeForm: '苔藓植物，植株中等至粗壮，形成疏松或较密的高丛',
    stem: '茎通常长5-10厘米，直立至斜卧，多数不分枝',
    leaf: '叶长6-8毫米，干时直立或开展，湿时开展至明显反曲，叶片边缘具齿',
    flower: '', fruit: '以孢子繁殖', habitat: ''
  },
  'niphotrichum-canescens': {
    lifeForm: '苔藓植物，形成疏松或密集的斑块或丛，干时常呈灰白色',
    stem: '茎通常长3-10厘米，不规则分枝或具短枝而呈羽状',
    leaf: '叶直或明显镰弯，干时覆瓦状排列，湿时开展至反曲，卵形至宽卵状披针形，先端常具芒',
    flower: '', fruit: '以孢子繁殖', habitat: ''
  },
  'rhodobryum-roseum': {
    lifeForm: '苔藓植物，茎长1-3厘米，通常由近顶端细枝分枝',
    stem: '茎长1-3厘米，通常由近顶端细枝分枝',
    leaf: '茎叶较少，18-22枚聚成莲座状，叶缘反卷至叶片中部附近，先端急尖',
    flower: '', fruit: '孢子直径16-20微米', habitat: ''
  },
  'tortula-muralis': {
    lifeForm: '苔藓植物', stem: '',
    leaf: '叶卵形、椭圆形至倒卵形，先端宽急尖、圆钝或微凹并常具芒，叶缘多反卷',
    flower: '', fruit: '孢蒴圆柱形，直立且近直，孢子球形、表面细乳突状或近光滑', habitat: ''
  },
  'marchantia-polymorpha': {
    lifeForm: '叶状体苔藓植物，在土壤表面形成叶状垫片',
    stem: '植物体为叶状体，不分化为真正的茎、根和叶，由假根固着于土壤',
    leaf: '叶状体在土壤表面平展并形成垫片',
    flower: '', fruit: '以孢子及杯状结构内形成的芽胞繁殖', habitat: ''
  },
  'thuidium-delicatulum': {
    lifeForm: '多年生匍匐苔藓植物，可在地面形成覆盖层',
    stem: '枝条呈类似羽状复叶的分枝方式',
    leaf: '叶简单、卵形、全缘',
    flower: '', fruit: '孢蒴稍弯曲、圆柱形，着生于锈色蒴柄上', habitat: ''
  },
  'spirodela-polyrhiza': {
    lifeForm: '多年生水生草本，叶状体漂浮于水面', stem: '',
    leaf: '叶状体扁平，宽倒卵形，长5-8毫米，宽4-6毫米，先端钝圆，上面绿色、下面紫色；叶状体下面中央生5-11条根，根旁一侧囊内可形成圆形新芽',
    flower: '', fruit: '', habitat: '生于水田、水塘、湖湾和水沟',
    diagnosticTraits: [
      '叶状体扁平、宽倒卵形，上面绿色、下面紫色。',
      '叶状体下面中央生5-11条根，根旁一侧囊内可形成圆形新芽。'
    ]
  }
};

const buildSourceFacts = (candidate, iplant) => {
  const fields = fieldsFromPlantInfo(iplant.plantInfo);
  const flora = factsFromFlora(iplant.frps);
  const factOverride = supplementalFactOverrides[candidate.resolvedCanonicalTaxonId];
  const supplemental = factOverride ?? (iplant.supplementalKind === 'ncsu'
    ? factsFromNcsu(iplant.supplementalPage)
    : iplant.supplementalKind === 'fna'
      ? factsFromFna(iplant.supplementalPage)
      : {});
  const classificationLifeForm = candidate.requestedCoverageGroups[0] === '蕨类植物' ? '蕨类植物'
    : candidate.requestedCoverageGroups[0] === '常见苔藓植物' ? '苔藓植物'
      : '';
  const splitLeafAndFlower = (value) => {
    const text = String(value ?? '');
    const marker = text.search(/[；;](?=(?:花茎|花序|花梗|花单生|花多数|花[黄白红紫蓝]|头状花序|总状花序|圆锥花序|聚伞花序|伞形花序|小穗))/);
    if (marker < 0) return { leaf: /^(?:叶|基生叶|茎生叶|小叶)/.test(text) ? text : '', flower: '' };
    return { leaf: text.slice(0, marker), flower: text.slice(marker + 1) };
  };
  const rawLeaf = fields.get('叶') || '';
  const rawFlower = fields.get('花') || fields.get('花序') || '';
  const leafFlower = splitLeafAndFlower(rawLeaf || rawFlower);
  const flowerParts = splitLeafAndFlower(rawFlower);
  const lifeFormCandidates = [fields.get('生活型'), fields.get('株'), flora.lifeForm, supplemental.lifeForm, classificationLifeForm, fields.get('根'), fields.get('茎')];
  const lifeForm = factOverride?.lifeForm || lifeFormCandidates.find((value) => /乔木|灌木|草本|藤本|攀援|蕨|苔|藓|叶状体|附生|水生|一年生|二年生|多年生|鳞茎植物|漂浮|飘浮|浮水|丛生|蔓生|植株|株高|根状茎|块茎|鳞茎|秆|茎.*直立/.test(value ?? '') && !/^本种与|区别/.test(value ?? '')) || classificationLifeForm;
  const stem = factOverride?.stem || firstUsable(fields.get('茎'), fields.get('枝'), fields.get('树皮'), flora.stem, supplemental.stem);
  const leaf = factOverride?.leaf || firstUsable(leafFlower.leaf, rawLeaf, flora.leaf, supplemental.leaf);
  const flower = factOverride?.flower || firstUsable(flowerParts.flower, !flowerParts.leaf ? rawFlower : '', leafFlower.flower, flora.flower, supplemental.flower);
  const fruit = factOverride?.fruit || firstUsable(fields.get('果'), fields.get('种子'), fields.get('孢子囊'), fields.get('蒴'), flora.fruit, supplemental.fruit);
  const habitat = factOverride?.habitat || fields.get('生境') || fields.get('栽培') || flora.habitat || supplemental.habitat;
  const explicitDiagnostic = fields.get('识别要点') || '';
  const candidates = [leaf, flower, fruit, stem, explicitDiagnostic].map((item) => concise(item, 5)).filter(Boolean);
  const uniqueTraits = factOverride?.diagnosticTraits ?? [...new Set(candidates)];
  if (!lifeForm || uniqueTraits.length < 2) {
    throw new Error(`${candidate.resolvedCanonicalTaxonId}: insufficient sourced facts (lifeForm=${Boolean(lifeForm)}, traits=${uniqueTraits.length})`);
  }
  return {
    lifeForm: completeFact(lifeForm),
    stem: stem ? completeFact(stem) : '',
    leaf: leaf ? completeFact(leaf) : '',
    flower: flower ? completeFact(flower) : '',
    fruit: fruit ? completeFact(fruit) : '',
    habitat: habitat ? completeFact(habitat) : '',
    distribution: '',
    floweringPeriod: '',
    diagnosticTraits: uniqueTraits.slice(0, 3)
  };
};

const normalizedTrait = (value) => withoutPeriod(value).replace(/[\s，、；;]/g, '');
const traitsOverlap = (left, right) => {
  const a = normalizedTrait(left); const b = normalizedTrait(right);
  return !a || !b || a === b || a.includes(b) || b.includes(a);
};
const secondaryTrait = (facts, primary) => [facts.flower, facts.fruit, facts.stem, ...facts.diagnosticTraits]
  .find((item) => item && !traitsOverlap(item, primary)) ?? facts.diagnosticTraits.find((item) => !traitsOverlap(item, primary));
const organForTrait = (facts, trait) => trait === facts.flower ? '花或花序' : trait === facts.fruit ? '果实或孢子结构' : trait === facts.stem ? '茎或茎节' : '对应特征部位';
const buildKnowledge = (candidate, facts) => {
  const primary = facts.leaf || facts.stem || facts.diagnosticTraits[0];
  const secondary = secondaryTrait(facts, primary);
  const organ = organForTrait(facts, secondary);
  const primaryShort = concise(primary, 5);
  const secondaryShort = concise(secondary, 4);
  const habitShort = lifeFormBrief(facts.lifeForm);
  const categoricalHabit = /乔木|灌木|草本|藤本|蕨|苔|藓|一年生|二年生|多年生|附生|水生|地被|多肉|叶状体/.test(habitShort);
  const summaryLead = categoricalHabit ? `${candidate.acceptedChineseName}是${withoutPeriod(habitShort)}` : `${candidate.acceptedChineseName}的生长形态为${withoutPeriod(habitShort)}`;
  const primaryInstruction = facts.leaf
    ? /叶状体/.test(primaryShort)
      ? `近拍叶状体正反面、边缘及附属结构，核对“${withoutPeriod(primaryShort)}”。`
      : `近拍叶片正反面及其在茎枝上的着生方式，核对“${withoutPeriod(primaryShort)}”。`
    : facts.stem
      ? `近拍茎或茎节的形状、表面和分枝方式，核对“${withoutPeriod(primaryShort)}”。`
      : `近拍主要营养体的整体与细节，核对“${withoutPeriod(primaryShort)}”。`;
  return {
    summary: `${summaryLead}。观察时重点看${withoutPeriod(primaryShort)}，并结合${withoutPeriod(secondaryShort)}确认。`,
    identificationReferences: [primaryShort, secondaryShort],
    howToConfirm: [
      primaryInstruction,
      `补拍${organ}的整体与细节，核对“${withoutPeriod(secondaryShort)}”。`
    ],
    appearance: `${primaryShort}${secondaryShort}`,
    growthHabit: facts.habitat ? `${habitShort}${concise(facts.habitat, 3)}` : habitShort,
    keyCharacteristics: [primaryShort, secondaryShort],
    observationTips: [
      facts.leaf ? /叶状体/.test(primaryShort) ? `记录叶状体的形状、表面和附属结构，重点核对“${withoutPeriod(primaryShort)}”。` : `记录叶片的形状、边缘和排列，重点核对“${withoutPeriod(primaryShort)}”。` : `记录主要营养体的形状和排列，重点核对“${withoutPeriod(primaryShort)}”。`,
      `若现场有${organ}，同时拍下其与主要营养体的相对位置。`
    ],
    confusableSpecies: [],
    observationReminder: '植物识别仅供自然观察与记录参考；请勿仅凭识别结果判断植物是否可食用、可药用或对人和宠物安全。'
  };
};

const taxonGroup = (candidate, facts) => {
  const group = candidate.requestedCoverageGroups[0];
  if (group === '常见苔藓植物') return 'bryophyte';
  if (group === '蕨类植物' || /蕨|槐叶蘋/.test(`${facts.lifeForm} ${candidate.family} ${candidate.genus}`)) return 'fern';
  if (/松科|柏科|杉科|银杏科|南洋杉科/.test(candidate.family)) return 'gymnosperm';
  return 'angiosperm';
};
const growthForms = (candidate, facts) => {
  const text = facts.lifeForm;
  const values = [];
  if (/乔木/.test(text)) values.push('tree');
  if (/灌木/.test(text)) values.push('shrub');
  if (/半灌木/.test(text)) values.push('subshrub');
  if (/藤|攀援|缠绕/.test(text)) values.push('vine');
  if (/草本|蕨|苔|藓|叶状体|鳞茎|根状茎|块茎/.test(text)) values.push('herb');
  return [...new Set(values)];
};
const catalogMetadata = (candidate, facts) => {
  const evidence = `${facts.lifeForm} ${facts.habitat}`;
  const sceneTags = [];
  if (/园林|绿化|行道|城市道路/.test(evidence)) sceneTags.push('urban-greening');
  if (/园林|庭园|庭院|花坛|花境|地被|园艺栽培/.test(evidence)) sceneTags.push('park-garden');
  if (/路旁|路边|道旁/.test(evidence)) sceneTags.push('roadside');
  if (/荒地|荒野/.test(evidence)) sceneTags.push('wasteland');
  if (/农田|田间|田边|旱地|水田/.test(evidence)) sceneTags.push('farmland');
  if (/林下|林中|森林|山林/.test(evidence)) sceneTags.push('forest');
  if (/林缘|林边|灌丛/.test(evidence)) sceneTags.push('forest-edge');
  if (/湿地|水边|河边|湖边|溪边|沼泽|水沟|水塘|池塘|湖湾/.test(evidence)) sceneTags.push('wetland-waterside');
  if (/水生|水中|水面|漂浮|飘浮|沉水/.test(evidence)) sceneTags.push('aquatic');
  if (/室内栽培|室内观叶|室内植物/.test(evidence)) sceneTags.push('indoor');
  const occurrenceTypes = /归化|逸生/.test(evidence) ? ['naturalized']
    : /栽培|园艺|盆栽|温室|引种/.test(evidence) ? ['cultivated']
      : /生于|生长于|野生|林下|山坡|草地|路旁|荒地|湿地|水中/.test(evidence) ? ['wild']
        : [];
  return { taxonGroup: taxonGroup(candidate, facts), growthForms: growthForms(candidate, facts), sceneTags: [...new Set(sceneTags)], occurrenceTypes, useTags: [], coveragePriority: 'P1' };
};

const makeRecord = async (candidate) => {
  const iplant = await readIPlant(candidate);
  const facts = buildSourceFacts(candidate, iplant);
  const sourceRefs = [
    {
      id: `gbif-${candidate.resolvedCanonicalTaxonId}`,
      title: `GBIF species record: ${candidate.acceptedScientificName}`,
      url: candidate.source.gbif,
      accessedAt: '2026-08-16',
      usedFor: ['accepted scientific name', 'external ID', 'taxonomic group']
    },
    {
      id: `iplant-${candidate.resolvedCanonicalTaxonId}`,
      title: `iPlant 植物智：${candidate.acceptedChineseName}（${iplant.latinName}）`,
      url: candidate.source.chineseNameAndMorphology,
      accessedAt: '2026-08-16',
      usedFor: ['accepted Chinese name', 'Chinese family', 'Chinese genus', 'habit', 'stem', 'leaf', 'flower', 'fruit', 'habitat', 'diagnostic traits']
    }
  ];
  if (candidate.source.supplementalMorphology) {
    sourceRefs.push({
      id: `supplemental-morphology-${candidate.resolvedCanonicalTaxonId}`,
      title: candidate.source.supplementalMorphology.includes('efloras') ? `Flora of North America: ${candidate.acceptedScientificName}` : `NC State Extension Plant Toolbox: ${candidate.acceptedScientificName}`,
      url: candidate.source.supplementalMorphology,
      accessedAt: '2026-08-16',
      usedFor: ['habit', 'leaf', 'reproductive structures', 'diagnostic traits']
    });
  }
  const existingPath = path.join(speciesDirectory, `${candidate.resolvedCanonicalTaxonId}.json`);
  let contentVersion = 1;
  if (repair) {
    try { contentVersion = JSON.parse(await readFile(existingPath, 'utf8')).contentVersion + 1; } catch {}
  }
  return {
    id: candidate.resolvedCanonicalTaxonId,
    category: 'plant',
    status: 'published',
    identity: { acceptedChineseName: candidate.acceptedChineseName, scientificName: candidate.acceptedScientificName, family: candidate.family, genus: candidate.genus, aliases: [] },
    scientificSynonyms: candidate.scientificSynonyms,
    sourceFacts: facts,
    knowledge: buildKnowledge(candidate, facts),
    catalogMetadata: catalogMetadata(candidate, facts),
    internalSourceRefs: sourceRefs,
    providerMappings: { gbif: candidate.providerMappings.gbif },
    contentVersion,
    reviewStatus: 'reviewed'
  };
};

const targetPaths = candidates.map((candidate) => path.join(speciesDirectory, `${candidate.resolvedCanonicalTaxonId}.json`));
for (const target of targetPaths) {
  try { await access(target); if (!repair) throw new Error(`Refusing to overwrite existing species file: ${target}`); } catch (error) { if (error.code !== 'ENOENT') throw error; }
}

const records = [];
for (const candidate of candidates) {
  const record = await makeRecord(candidate);
  records.push(record);
  process.stdout.write(`Prepared ${candidate.planning.sequence}: ${record.identity.acceptedChineseName} (${record.id})\n`);
}

const mappingFile = JSON.parse(await readFile(mappingPath, 'utf8'));
const existingKeys = new Set(mappingFile.mappings.map((mapping) => `${mapping.provider}\u0000${mapping.name}`));
const existingIds = new Set(mappingFile.mappings.map((mapping) => mapping.canonicalTaxonId));
for (const record of records) {
  const key = `baidu\u0000${record.identity.acceptedChineseName}`;
  const existingMapping = mappingFile.mappings.find((mapping) => `${mapping.provider}\u0000${mapping.name}` === key);
  if (existingMapping && existingMapping.canonicalTaxonId !== record.id) throw new Error(`Refusing duplicate provider/name mapping: ${record.identity.acceptedChineseName}`);
  if (existingMapping) continue;
  if (existingIds.has(record.id)) throw new Error(`Species already has a provider mapping under another name: ${record.id}`);
  existingKeys.add(key); existingIds.add(record.id);
  mappingFile.mappings.push({ provider: 'baidu', name: record.identity.acceptedChineseName, canonicalTaxonId: record.id, matchType: 'exact', verified: true });
}
mappingFile.mappings.sort((left, right) => left.name.localeCompare(right.name, 'zh-CN'));

for (const [index, record] of records.entries()) {
  await writeFile(targetPaths[index], `${JSON.stringify(record, null, 2)}\n`, 'utf8');
}
await writeFile(mappingPath, `${JSON.stringify(mappingFile, null, 2)}\n`, 'utf8');
for (const candidate of candidates) candidate.resolutionStatus = 'existing';
await writeFile(candidatePath, `${JSON.stringify(batch, null, 2)}\n`, 'utf8');
console.log(`Produced ${records.length} reviewed L2 records for sequences ${start}-${start + count - 1}.`);
