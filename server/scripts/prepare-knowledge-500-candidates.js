import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const serverRoot = path.resolve(scriptDirectory, '..');
const knowledgeRoot = path.join(serverRoot, 'data', 'plant-knowledge');
const baselinePath = path.join(knowledgeRoot, 'imports', 'batch-500-baseline.json');
const outputPath = path.join(knowledgeRoot, 'imports', 'batch-500-expansion-candidates.json');

const expectedCounts = new Map([
  ['城市及常见乔木', 55],
  ['灌木与绿篱', 50],
  ['公园花卉与地被', 65],
  ['路边及荒地草本', 55],
  ['农田、作物及田边植物', 35],
  ['藤本植物', 25],
  ['蕨类植物', 20],
  ['水生及湿地植物', 25],
  ['室内观叶及常见盆栽', 35],
  ['林地及林缘植物', 25],
  ['常见苔藓植物', 10]
]);

const candidateText = String.raw`
城市及常见乔木|三角槭|Acer buergerianum
城市及常见乔木|鸡爪槭|Acer palmatum
城市及常见乔木|元宝槭|Acer truncatum
城市及常见乔木|梣叶槭|Acer negundo
城市及常见乔木|青榨槭|Acer davidii
城市及常见乔木|臭椿|Ailanthus altissima
城市及常见乔木|榆|Ulmus pumila
城市及常见乔木|构树|Broussonetia papyrifera
城市及常见乔木|喜树|Camptotheca acuminata
城市及常见乔木|楸|Catalpa bungei
城市及常见乔木|梓|Catalpa ovata
城市及常见乔木|紫荆|Cercis chinensis
城市及常见乔木|柳杉|Cryptomeria japonica
城市及常见乔木|杉木|Cunninghamia lanceolata
城市及常见乔木|柏木|Cupressus funebris
城市及常见乔木|黄檀|Dalbergia hupeana
城市及常见乔木|柿|Diospyros kaki
城市及常见乔木|杜英|Elaeocarpus decipiens
城市及常见乔木|杜仲|Eucommia ulmoides
城市及常见乔木|梧桐|Firmiana simplex
城市及常见乔木|皂荚|Gleditsia sinensis
城市及常见乔木|山桐子|Idesia polycarpa
城市及常见乔木|胡桃|Juglans regia
城市及常见乔木|圆柏|Juniperus chinensis
城市及常见乔木|复羽叶栾树|Koelreuteria bipinnata
城市及常见乔木|枫香树|Liquidambar formosana
城市及常见乔木|鹅掌楸|Liriodendron chinense
城市及常见乔木|白皮松|Pinus bungeana
城市及常见乔木|云杉|Picea asperata
城市及常见乔木|湖北海棠|Malus hupehensis
城市及常见乔木|海棠花|Malus spectabilis
城市及常见乔木|楝|Melia azedarach
城市及常见乔木|桑|Morus alba
城市及常见乔木|白花泡桐|Paulownia fortunei
城市及常见乔木|加拿利海枣|Phoenix canariensis
城市及常见乔木|马尾松|Pinus massoniana
城市及常见乔木|油松|Pinus tabuliformis
城市及常见乔木|毛白杨|Populus tomentosa
城市及常见乔木|杏|Prunus armeniaca
城市及常见乔木|樱桃李|Prunus cerasifera
城市及常见乔木|梅|Prunus mume
城市及常见乔木|桃|Prunus persica
城市及常见乔木|山樱花|Prunus serrulata
城市及常见乔木|白梨|Pyrus bretschneideri
城市及常见乔木|豆梨|Pyrus calleryana
城市及常见乔木|麻栎|Quercus acutissima
城市及常见乔木|栓皮栎|Quercus variabilis
城市及常见乔木|刺槐|Robinia pseudoacacia
城市及常见乔木|垂柳|Salix babylonica
城市及常见乔木|无患子|Sapindus mukorossi
城市及常见乔木|木荷|Schima superba
城市及常见乔木|落羽杉|Taxodium distichum
城市及常见乔木|香椿|Toona sinensis
城市及常见乔木|棕榈|Trachycarpus fortunei
城市及常见乔木|乌桕|Triadica sebifera

灌木与绿篱|糯米条|Abelia chinensis
灌木与绿篱|日本小檗|Berberis thunbergii
灌木与绿篱|绣线菊|Spiraea salicifolia
灌木与绿篱|大叶黄杨|Buxus megistophylla
灌木与绿篱|皱皮木瓜|Chaenomeles speciosa
灌木与绿篱|海州常山|Clerodendrum trichotomum
灌木与绿篱|红瑞木|Cornus alba
灌木与绿篱|平枝栒子|Cotoneaster horizontalis
灌木与绿篱|瑞香|Daphne odora
灌木与绿篱|溲疏|Deutzia scabra
灌木与绿篱|结香|Edgeworthia chrysantha
灌木与绿篱|胡颓子|Elaeagnus pungens
灌木与绿篱|卫矛|Euonymus alatus
灌木与绿篱|扶芳藤|Euonymus fortunei
灌木与绿篱|白鹃梅|Exochorda racemosa
灌木与绿篱|金钟花|Forsythia viridissima
灌木与绿篱|栀子|Gardenia jasminoides
灌木与绿篱|木芙蓉|Hibiscus mutabilis
灌木与绿篱|绣球|Hydrangea macrophylla
灌木与绿篱|花木蓝|Indigofera kirilowii
灌木与绿篱|云南黄素馨|Jasminum mesnyi
灌木与绿篱|棣棠花|Kerria japonica
灌木与绿篱|猬实|Kolkwitzia amabilis
灌木与绿篱|胡枝子|Lespedeza bicolor
灌木与绿篱|小叶女贞|Ligustrum quihoui
灌木与绿篱|郁香忍冬|Lonicera fragrantissima
灌木与绿篱|檵木|Loropetalum chinense
灌木与绿篱|风箱果|Physocarpus amurensis
灌木与绿篱|十大功劳|Mahonia fortunei
灌木与绿篱|桃金娘|Myrtus communis
灌木与绿篱|夹竹桃|Nerium oleander
灌木与绿篱|柊树|Osmanthus heterophyllus
灌木与绿篱|羊踯躅|Rhododendron molle
灌木与绿篱|太平花|Philadelphus pekinensis
灌木与绿篱|郁李|Prunus glandulosa
灌木与绿篱|石榴|Punica granatum
灌木与绿篱|火棘|Pyracantha fortuneana
灌木与绿篱|石斑木|Rhaphiolepis indica
灌木与绿篱|木香花|Rosa banksiae
灌木与绿篱|野蔷薇|Rosa multiflora
灌木与绿篱|玫瑰|Rosa rugosa
灌木与绿篱|接骨木|Sambucus williamsii
灌木与绿篱|麻叶绣线菊|Spiraea cantoniensis
灌木与绿篱|粉花绣线菊|Spiraea japonica
灌木与绿篱|紫丁香|Syringa oblata
灌木与绿篱|荚蒾|Viburnum dilatatum
灌木与绿篱|珊瑚树|Viburnum odoratissimum
灌木与绿篱|黄荆|Vitex negundo
灌木与绿篱|榆叶梅|Prunus triloba
灌木与绿篱|迎红杜鹃|Rhododendron mucronulatum

公园花卉与地被|蓍|Achillea millefolium
公园花卉与地被|匍匐筋骨草|Ajuga reptans
公园花卉与地被|蜀葵|Alcea rosea
公园花卉与地被|彩叶草|Coleus scutellarioides
公园花卉与地被|金鱼草|Antirrhinum majus
公园花卉与地被|耧斗菜|Aquilegia viridiflora
公园花卉与地被|木茼蒿|Argyranthemum frutescens
公园花卉与地被|海石竹|Armeria maritima
公园花卉与地被|落新妇|Astilbe chinensis
公园花卉与地被|雏菊|Bellis perennis
公园花卉与地被|岩白菜|Bergenia purpurascens
公园花卉与地被|四季秋海棠|Begonia cucullata
公园花卉与地被|长春花|Catharanthus roseus
公园花卉与地被|青葙|Celosia argentea
公园花卉与地被|翠菊|Callistephus chinensis
公园花卉与地被|秋英|Cosmos bipinnatus
公园花卉与地被|野菊|Chrysanthemum indicum
公园花卉与地被|大丽花|Dahlia pinnata
公园花卉与地被|须苞石竹|Dianthus barbatus
公园花卉与地被|石竹|Dianthus chinensis
公园花卉与地被|松果菊|Echinacea purpurea
公园花卉与地被|花菱草|Eschscholzia californica
公园花卉与地被|天人菊|Gaillardia aristata
公园花卉与地被|勋章菊|Gazania rigens
公园花卉与地被|千日红|Gomphrena globosa
公园花卉与地被|向日葵|Helianthus annuus
公园花卉与地被|新几内亚凤仙|Impatiens hawkeri
公园花卉与地被|春星韭|Ipheion uniflorum
公园花卉与地被|德国鸢尾|Iris germanica
公园花卉与地被|香雪球|Lobularia maritima
公园花卉与地被|紫罗兰|Matthiola incana
公园花卉与地被|紫茉莉|Mirabilis jalapa
公园花卉与地被|龙面花|Nemesia strumosa
公园花卉与地被|花烟草|Nicotiana alata
公园花卉与地被|美丽月见草|Oenothera speciosa
公园花卉与地被|蓝目菊|Osteospermum ecklonis
公园花卉与地被|报春花|Primula malacoides
公园花卉与地被|毛剪秋罗|Silene coronaria
公园花卉与地被|五星花|Pentas lanceolata
公园花卉与地被|福禄考|Phlox drummondii
公园花卉与地被|桔梗|Platycodon grandiflorus
公园花卉与地被|大花马齿苋|Portulaca grandiflora
公园花卉与地被|黑心金光菊|Rudbeckia hirta
公园花卉与地被|金光菊|Rudbeckia laciniata
公园花卉与地被|蓝花鼠尾草|Salvia farinacea
公园花卉与地被|一串红|Salvia splendens
公园花卉与地被|大蔓樱草|Silene pendula
公园花卉与地被|佛甲草|Sedum lineare
公园花卉与地被|垂盆草|Sedum sarmentosum
公园花卉与地被|银叶菊|Jacobaea maritima
公园花卉与地被|二色补血草|Limonium bicolor
公园花卉与地被|夏堇|Torenia fournieri
公园花卉与地被|旱金莲|Tropaeolum majus
公园花卉与地被|柳叶马鞭草|Verbena bonariensis
公园花卉与地被|角堇|Viola cornuta
公园花卉与地被|紫花地丁|Viola philippica
公园花卉与地被|葱莲|Zephyranthes candida
公园花卉与地被|韭莲|Zephyranthes carinata
公园花卉与地被|荷兰菊|Symphyotrichum novi-belgii
公园花卉与地被|菊苣|Cichorium intybus
公园花卉与地被|送春花|Clarkia amoena
公园花卉与地被|红绿草|Alternanthera bettzickiana
公园花卉与地被|马缨丹|Lantana camara
公园花卉与地被|瞿麦|Dianthus superbus
公园花卉与地被|香彩雀|Angelonia angustifolia

路边及荒地草本|铁苋菜|Acalypha australis
路边及荒地草本|牛膝|Achyranthes bidentata
路边及荒地草本|苘麻|Abutilon theophrasti
路边及荒地草本|刺苋|Amaranthus spinosus
路边及荒地草本|豚草|Ambrosia artemisiifolia
路边及荒地草本|艾|Artemisia argyi
路边及荒地草本|黄花蒿|Artemisia annua
路边及荒地草本|五月艾|Artemisia indica
路边及荒地草本|鬼针草|Bidens pilosa
路边及荒地草本|白羊草|Bothriochloa ischaemum
路边及荒地草本|荠菜|Capsella bursa-pastoris
路边及荒地草本|碎米荠|Cardamine hirsuta
路边及荒地草本|球序卷耳|Cerastium glomeratum
路边及荒地草本|刺儿菜|Cirsium setosum
路边及荒地草本|鸭跖草|Commelina communis
路边及荒地草本|狗牙根|Cynodon dactylon
路边及荒地草本|鸭茅|Dactylis glomerata
路边及荒地草本|马唐|Digitaria sanguinalis
路边及荒地草本|鳢肠|Eclipta prostrata
路边及荒地草本|粗毛牛膝菊|Galinsoga quadriradiata
路边及荒地草本|野老鹳草|Geranium carolinianum
路边及荒地草本|鼠麹草|Pseudognaphalium affine
路边及荒地草本|鱼腥草|Houttuynia cordata
路边及荒地草本|鸡眼草|Kummerowia striata
路边及荒地草本|翅果菊|Lactuca indica
路边及荒地草本|宝盖草|Lamium amplexicaule
路边及荒地草本|稻槎菜|Lapsana apogonoides
路边及荒地草本|益母草|Leonurus japonicus
路边及荒地草本|独行菜|Lepidium apetalum
路边及荒地草本|冬葵|Malva verticillata
路边及荒地草本|通泉草|Mazus pumilus
路边及荒地草本|天蓝苜蓿|Medicago lupulina
路边及荒地草本|草木樨|Melilotus officinalis
路边及荒地草本|月见草|Oenothera biennis
路边及荒地草本|猪毛蒿|Artemisia scoparia
路边及荒地草本|水蓼|Persicaria hydropiper
路边及荒地草本|垂序商陆|Phytolacca americana
路边及荒地草本|北美车前|Plantago virginica
路边及荒地草本|萹蓄|Polygonum aviculare
路边及荒地草本|委陵菜|Potentilla chinensis
路边及荒地草本|平车前|Plantago depressa
路边及荒地草本|蔊菜|Rorippa indica
路边及荒地草本|皱叶酸模|Rumex crispus
路边及荒地草本|欧洲千里光|Senecio vulgaris
路边及荒地草本|金色狗尾草|Setaria faberi
路边及荒地草本|龙葵|Solanum nigrum
路边及荒地草本|钻叶紫菀|Symphyotrichum subulatum
路边及荒地草本|白车轴草|Trifolium repens
路边及荒地草本|长柄菊|Tridax procumbens
路边及荒地草本|阿拉伯婆婆纳|Veronica persica
路边及荒地草本|救荒野豌豆|Vicia sativa
路边及荒地草本|白花地丁|Viola patrinii
路边及荒地草本|苍耳|Xanthium strumarium
路边及荒地草本|黄鹌菜|Youngia japonica
路边及荒地草本|小花山桃草|Oenothera lindheimeri

农田、作物及田边植物|洋葱|Allium cepa
农田、作物及田边植物|蒜|Allium sativum
农田、作物及田边植物|甜菜|Beta vulgaris
农田、作物及田边植物|甘蓝|Brassica oleracea
农田、作物及田边植物|芜菁|Brassica rapa
农田、作物及田边植物|木豆|Cajanus cajan
农田、作物及田边植物|茶|Camellia sinensis
农田、作物及田边植物|辣椒|Capsicum annuum
农田、作物及田边植物|西瓜|Citrullus lanatus
农田、作物及田边植物|薏苡|Coix lacryma-jobi
农田、作物及田边植物|黄麻|Corchorus capsularis
农田、作物及田边植物|黄瓜|Cucumis sativus
农田、作物及田边植物|甜瓜|Cucumis melo
农田、作物及田边植物|南瓜|Cucurbita moschata
农田、作物及田边植物|胡萝卜|Daucus carota
农田、作物及田边植物|荞麦|Fagopyrum esculentum
农田、作物及田边植物|菊芋|Helianthus tuberosus
农田、作物及田边植物|大麦|Hordeum vulgare
农田、作物及田边植物|蕹菜|Ipomoea aquatica
农田、作物及田边植物|莴苣|Lactuca sativa
农田、作物及田边植物|丝瓜|Luffa aegyptiaca
农田、作物及田边植物|紫苜蓿|Medicago sativa
农田、作物及田边植物|烟草|Nicotiana tabacum
农田、作物及田边植物|菜豆|Phaseolus vulgaris
农田、作物及田边植物|豌豆|Pisum sativum
农田、作物及田边植物|萝卜|Raphanus sativus
农田、作物及田边植物|芝麻|Sesamum indicum
农田、作物及田边植物|番茄|Solanum lycopersicum
农田、作物及田边植物|茄|Solanum melongena
农田、作物及田边植物|马铃薯|Solanum tuberosum
农田、作物及田边植物|高粱|Sorghum bicolor
农田、作物及田边植物|蚕豆|Vicia faba
农田、作物及田边植物|绿豆|Vigna radiata
农田、作物及田边植物|豇豆|Vigna unguiculata
农田、作物及田边植物|菰|Zizania latifolia

藤本植物|木通|Akebia quinata
藤本植物|中华猕猴桃|Actinidia chinensis
藤本植物|蛇葡萄|Ampelopsis glandulosa
藤本植物|马兜铃|Aristolochia debilis
藤本植物|凌霄|Campsis grandiflora
藤本植物|厚萼凌霄|Campsis radicans
藤本植物|南蛇藤|Celastrus orbiculatus
藤本植物|风龙|Sinomenium acutum
藤本植物|威灵仙|Clematis chinensis
藤本植物|铁线莲|Clematis florida
藤本植物|薯蓣|Dioscorea polystachya
藤本植物|千金藤|Stephania japonica
藤本植物|钩吻|Gelsemium elegans
藤本植物|忍冬|Lonicera japonica
藤本植物|鸡矢藤|Paederia foetida
藤本植物|蓝花西番莲|Passiflora caerulea
藤本植物|杠柳|Periploca sepium
藤本植物|葛|Pueraria montana
藤本植物|五味子|Schisandra chinensis
藤本植物|白英|Solanum lyratum
藤本植物|大花老鸦嘴|Thunbergia grandiflora
藤本植物|络石|Trachelospermum jasminoides
藤本植物|山葡萄|Vitis amurensis
藤本植物|葡萄|Vitis vinifera
藤本植物|三叶崖爬藤|Tetrastigma hemsleyanum

蕨类植物|扇叶铁线蕨|Adiantum flabellulatum
蕨类植物|巢蕨|Asplenium nidus
蕨类植物|日本蹄盖蕨|Athyrium niponicum
蕨类植物|东方乌毛蕨|Blechnum orientale
蕨类植物|华凤丫蕨|Coniogramme intermedia
蕨类植物|全缘贯众|Cyrtomium falcatum
蕨类植物|狗脊|Woodwardia japonica
蕨类植物|芒萁|Dicranopteris pedata
蕨类植物|菜蕨|Diplazium esculentum
蕨类植物|粗茎鳞毛蕨|Dryopteris crassirhizoma
蕨类植物|红盖鳞毛蕨|Dryopteris erythrosora
蕨类植物|瓦韦|Lepisorus thunbergianus
蕨类植物|海金沙|Lygodium japonicum
蕨类植物|蘋|Marsilea quadrifolia
蕨类植物|荚果蕨|Matteuccia struthiopteris
蕨类植物|变异鳞毛蕨|Dryopteris varia
蕨类植物|紫萁|Osmunda japonica
蕨类植物|二歧鹿角蕨|Platycerium bifurcatum
蕨类植物|剑叶凤尾蕨|Pteris ensiformis
蕨类植物|卷柏|Selaginella tamariscina

水生及湿地植物|菖蒲|Acorus calamus
水生及湿地植物|石菖蒲|Acorus gramineus
水生及湿地植物|槐叶蘋|Salvinia natans
水生及湿地植物|花蔺|Butomus umbellatus
水生及湿地植物|金鱼藻|Ceratophyllum demersum
水生及湿地植物|芡实|Euryale ferox
水生及湿地植物|黑藻|Hydrilla verticillata
水生及湿地植物|水鳖|Hydrocharis dubia
水生及湿地植物|黄菖蒲|Iris pseudacorus
水生及湿地植物|灯心草|Juncus effusus
水生及湿地植物|水龙|Ludwigia adscendens
水生及湿地植物|鸭舌草|Monochoria vaginalis
水生及湿地植物|穗状狐尾藻|Myriophyllum spicatum
水生及湿地植物|荇菜|Nymphoides peltata
水生及湿地植物|睡莲|Nymphaea tetragona
水生及湿地植物|水车前|Ottelia alismoides
水生及湿地植物|红蓼|Persicaria orientalis
水生及湿地植物|大薸|Pistia stratiotes
水生及湿地植物|菹草|Potamogeton crispus
水生及湿地植物|慈姑|Sagittaria sagittifolia
水生及湿地植物|水葱|Schoenoplectus tabernaemontani
水生及湿地植物|三棱水葱|Schoenoplectus triqueter
水生及湿地植物|紫萍|Spirodela polyrhiza
水生及湿地植物|水烛|Typha angustifolia
水生及湿地植物|苦草|Vallisneria natans

室内观叶及常见盆栽|紫背万年青|Tradescantia spathacea
室内观叶及常见盆栽|海芋|Alocasia odora
室内观叶及常见盆栽|库拉索芦荟|Aloe vera
室内观叶及常见盆栽|花烛|Anthurium andraeanum
室内观叶及常见盆栽|异叶南洋杉|Araucaria heterophylla
室内观叶及常见盆栽|文竹|Asparagus setaceus
室内观叶及常见盆栽|大琴叶榕|Ficus lyrata
室内观叶及常见盆栽|孔雀竹芋|Goeppertia makoyana
室内观叶及常见盆栽|袖珍椰子|Chamaedorea elegans
室内观叶及常见盆栽|变叶木|Codiaeum variegatum
室内观叶及常见盆栽|朱蕉|Cordyline fruticosa
室内观叶及常见盆栽|玉树|Crassula ovata
室内观叶及常见盆栽|花叶万年青|Dieffenbachia seguine
室内观叶及常见盆栽|香龙血树|Dracaena fragrans
室内观叶及常见盆栽|铁海棠|Euphorbia milii
室内观叶及常见盆栽|垂叶榕|Ficus benjamina
室内观叶及常见盆栽|网纹草|Fittonia albivenis
室内观叶及常见盆栽|条纹十二卷|Haworthiopsis attenuata
室内观叶及常见盆栽|球兰|Hoya carnosa
室内观叶及常见盆栽|长寿花|Kalanchoe blossfeldiana
室内观叶及常见盆栽|竹芋|Maranta leuconeura
室内观叶及常见盆栽|波士顿蕨|Nephrolepis exaltata
室内观叶及常见盆栽|豆瓣绿|Peperomia obtusifolia
室内观叶及常见盆栽|心叶喜林芋|Philodendron hederaceum
室内观叶及常见盆栽|冷水花|Pilea cadierei
室内观叶及常见盆栽|羽叶福禄桐|Polyscias fruticosa
室内观叶及常见盆栽|棕竹|Rhapis excelsa
室内观叶及常见盆栽|鹅掌藤|Heptapleurum arboricola
室内观叶及常见盆栽|蟹爪兰|Schlumbergera truncata
室内观叶及常见盆栽|镜面草|Pilea peperomioides
室内观叶及常见盆栽|合果芋|Syngonium podophyllum
室内观叶及常见盆栽|吊竹梅|Tradescantia zebrina
室内观叶及常见盆栽|象腿丝兰|Yucca gigantea
室内观叶及常见盆栽|雪铁芋|Zamioculcas zamiifolia
室内观叶及常见盆栽|鹤望兰|Strelitzia reginae

林地及林缘植物|杏香兔儿风|Ainsliaea fragrans
林地及林缘植物|紫金牛|Ardisia japonica
林地及林缘植物|一把伞南星|Arisaema erubescens
林地及林缘植物|华细辛|Asarum sieboldii
林地及林缘植物|秋海棠|Begonia grandis
林地及林缘植物|苎麻|Boehmeria nivea
林地及林缘植物|紫珠|Callicarpa bodinieri
林地及林缘植物|宽叶薹草|Carex siderosticta
林地及林缘植物|及己|Chloranthus serratus
林地及林缘植物|四照花|Cornus kousa
林地及林缘植物|榛|Corylus heterophylla
林地及林缘植物|宝铎草|Disporum sessile
林地及林缘植物|淫羊藿|Epimedium brevicornu
林地及林缘植物|大吴风草|Farfugium japonicum
林地及林缘植物|活血丹|Glechoma longituba
林地及林缘植物|刻叶紫堇|Corydalis incisa
林地及林缘植物|山麦冬|Liriope spicata
林地及林缘植物|过路黄|Lysimachia christinae
林地及林缘植物|舞鹤草|Maianthemum japonicum
林地及林缘植物|七叶一枝花|Paris polyphylla
林地及林缘植物|玉竹|Polygonatum odoratum
林地及林缘植物|黄精|Polygonatum sibiricum
林地及林缘植物|地黄|Rehmannia glutinosa
林地及林缘植物|山莓|Rubus corchorifolius
林地及林缘植物|菝葜|Smilax china

常见苔藓植物|银叶真藓|Bryum argenteum
常见苔藓植物|葫芦藓|Funaria hygrometrica
常见苔藓植物|灰藓|Hypnum cupressiforme
常见苔藓植物|地钱|Marchantia polymorpha
常见苔藓植物|匐灯藓|Plagiomnium cuspidatum
常见苔藓植物|大金发藓|Polytrichum commune
常见苔藓植物|长齿藓|Niphotrichum canescens
常见苔藓植物|大叶藓|Rhodobryum roseum
常见苔藓植物|细枝羽藓|Thuidium delicatulum
常见苔藓植物|墙藓|Tortula muralis
`;

const normalizeScientificName = (value) => String(value ?? '')
  .normalize('NFKC')
  .replace(/[×✕✖]/g, 'x')
  .replace(/[._-]+/g, ' ')
  .replace(/\s+/g, ' ')
  .trim()
  .toLowerCase();

const slugify = (scientificName) => normalizeScientificName(scientificName)
  .replace(/\s+x\s+/g, '-x-')
  .replace(/[^a-z0-9]+/g, '-')
  .replace(/^-+|-+$/g, '');

const stripHtml = (value) => String(value ?? '')
  .replace(/<br\s*\/?\s*>/gi, '\n')
  .replace(/<[^>]*>/g, '')
  .replace(/&nbsp;/g, ' ')
  .replace(/&amp;/g, '&')
  .replace(/&lt;/g, '<')
  .replace(/&gt;/g, '>')
  .replace(/&#39;/g, "'")
  .replace(/&quot;/g, '"')
  .replace(/\s+/g, ' ')
  .trim();

const sourceRows = candidateText.trim().split('\n').filter(Boolean).map((line, index) => {
  const [group, inputName, inputScientificName] = line.split('|');
  if (!group || !inputName || !inputScientificName) throw new Error(`Invalid candidate line ${index + 1}: ${line}`);
  return { group, inputName, inputScientificName };
});

for (const [group, expected] of expectedCounts) {
  const actual = sourceRows.filter((row) => row.group === group).length;
  if (actual !== expected) throw new Error(`${group}: expected ${expected}, got ${actual}`);
}
if (sourceRows.length !== 400) throw new Error(`Expected 400 candidates, got ${sourceRows.length}`);
const scientificInputs = new Set();
for (const row of sourceRows) {
  const key = normalizeScientificName(row.inputScientificName);
  if (scientificInputs.has(key)) throw new Error(`Duplicate input scientific name: ${row.inputScientificName}`);
  scientificInputs.add(key);
}

const baseline = JSON.parse(await readFile(baselinePath, 'utf8'));
const baselineScientificNames = new Set(baseline.species.flatMap((item) => [item.acceptedScientificName, ...(item.scientificSynonyms ?? [])]).map(normalizeScientificName));
const baselineIds = new Set(baseline.species.map((item) => item.canonicalTaxonId));
const baselineGbifIds = new Set(baseline.species.map((item) => String(item.gbifId)));

const fetchText = async (url) => {
  const response = await fetch(url, { headers: { 'user-agent': 'WildSight knowledge maintenance/1.0' }, signal: AbortSignal.timeout(30000) });
  if (!response.ok) throw new Error(`${response.status} ${response.statusText}`);
  return response.text();
};

const fetchJson = async (url) => JSON.parse(await fetchText(url));
const floraNorthAmericaTaxonIds = new Map([
  ['symphyotrichum subulatum', '250049273'],
  ['bryum argenteum', '200001406'],
  ['funaria hygrometrica', '200001339'],
  ['hypnum cupressiforme', '200002507'],
  ['marchantia polymorpha', '233500824'],
  ['plagiomnium cuspidatum', '200001511'],
  ['polytrichum commune', '200002665'],
  ['niphotrichum canescens', '250075452'],
  ['rhodobryum roseum', '200001489'],
  ['thuidium delicatulum', '200002117'],
  ['tortula muralis', '200001223']
]);

const resolveEfloras = async (scientificName) => {
  const taxonId = floraNorthAmericaTaxonIds.get(normalizeScientificName(scientificName));
  if (!taxonId) return null;
  const url = `https://www.efloras.org/florataxon.aspx?flora_id=1&taxon_id=${taxonId}`;
  return { url, title: `Flora of North America: ${scientificName}`, accessVerifiedAt: '2026-08-16' };
};

const ncsuUrlFor = (scientificName) => `https://plants.ces.ncsu.edu/plants/${normalizeScientificName(scientificName).replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '')}/`;

const resolveNcsu = async (scientificName) => {
  const url = ncsuUrlFor(scientificName);
  try {
    const page = await fetchText(url);
    const normalizedPage = page.toLowerCase();
    if (!normalizedPage.includes(String(scientificName).toLowerCase())) return null;
    if (!/(leaf|flower|fruit|stem|habit|description)/i.test(page)) return null;
    return { url, title: `NC State Extension Plant Toolbox: ${scientificName}` };
  } catch {
    return null;
  }
};

const resolveGbif = async (scientificName) => {
  const match = await fetchJson(`https://api.gbif.org/v1/species/match?name=${encodeURIComponent(scientificName)}`);
  if (!match.usageKey || match.rank !== 'SPECIES') return { match, accepted: null };
  const usage = await fetchJson(`https://api.gbif.org/v1/species/${match.usageKey}`);
  const acceptedKey = usage.acceptedKey ?? usage.acceptedUsageKey ?? (usage.taxonomicStatus === 'ACCEPTED' ? usage.key : null);
  if (!acceptedKey) return { match, usage, accepted: null };
  const accepted = String(acceptedKey) === String(usage.key) ? usage : await fetchJson(`https://api.gbif.org/v1/species/${acceptedKey}`);
  return { match, usage, accepted };
};

const resolveIPlant = async (scientificName) => {
  const pageUrl = `https://www.iplant.cn/info/${encodeURIComponent(scientificName)}?t=z`;
  const page = await fetchText(pageUrl);
  const spno = page.match(/var\s+spno\s*=\s*"([^"]*)"/)?.[1] ?? '';
  const chineseName = page.match(/var\s+spcname\s*=\s*"([^"]*)"/)?.[1] ?? '';
  const latinName = page.match(/var\s+latin2\s*=\s*"([^"]*)"/)?.[1] ?? '';
  if (!spno || !chineseName || !latinName) return { pageUrl, spno, chineseName, latinName, classification: null, frps: null, plantInfo: null };
  const [classification, frps, plantInfo] = await Promise.all([
    fetchJson(`https://www.iplant.cn/ashx/getclasssys.ashx?spid=${encodeURIComponent(spno)}`).catch(() => null),
    fetchJson(`https://www.iplant.cn/ashx/getfrps.ashx?key=${encodeURIComponent(latinName)}`).catch(() => null),
    fetchJson(`https://www.iplant.cn/ashx/plantinfo.ashx?spid=${encodeURIComponent(spno)}&type=descall`).catch(() => null)
  ]);
  return { pageUrl, spno, chineseName, latinName, classification, frps, plantInfo };
};

const morphologyFacts = (iplant) => {
  const section = iplant?.plantInfo?.spdesc?.find((item) => item.t === '形态特征');
  return (section?.desclist ?? []).filter((item) => item.desc && !['代表图片'].includes(item.subname));
};

const resolveCandidate = async (row, index) => {
  const errors = [];
  let gbif;
  try { gbif = await resolveGbif(row.inputScientificName); } catch (error) { errors.push(`GBIF访问失败：${error.message}`); }
  const acceptedScientificName = gbif?.accepted?.canonicalName ?? gbif?.accepted?.scientificName ?? '';
  let iplant;
  if (acceptedScientificName) {
    try {
      iplant = await resolveIPlant(acceptedScientificName);
      if (!iplant.spno && normalizeScientificName(acceptedScientificName) !== normalizeScientificName(row.inputScientificName)) {
        iplant = await resolveIPlant(row.inputScientificName);
      }
      if (!iplant.spno) iplant = await resolveIPlant(row.inputName);
    } catch (error) { errors.push(`iPlant访问失败：${error.message}`); }
  }
  const canonicalTaxonId = acceptedScientificName ? slugify(acceptedScientificName) : '';
  const acceptedChineseName = iplant?.chineseName ?? '';
  const family = iplant?.classification?.famctxt ?? '';
  const genus = iplant?.classification?.genctxt ?? '';
  const gbifId = gbif?.accepted?.key ? String(gbif.accepted.key) : '';
  if (!gbif?.accepted || gbif.accepted.rank !== 'SPECIES') errors.push(`GBIF未解析为接受的物种级记录：${gbif?.accepted?.rank ?? '无等级'}`);
  if (gbif?.match?.confidence < 95 || !['EXACT', 'HIGHERRANK'].includes(gbif?.match?.matchType)) errors.push(`GBIF匹配置信不足：${gbif?.match?.confidence ?? '无'} / ${gbif?.match?.matchType ?? '无'}`);
  if (!iplant?.spno) errors.push('iPlant无直接物种页');
  const verifiedScientificSynonyms = [];
  if (gbif?.usage && gbif?.accepted && String(gbif.usage.key) !== String(gbif.accepted.key)
      && normalizeScientificName(row.inputScientificName) !== normalizeScientificName(acceptedScientificName)) {
    verifiedScientificSynonyms.push(row.inputScientificName);
  }
  if (acceptedScientificName && iplant?.latinName && normalizeScientificName(acceptedScientificName) !== normalizeScientificName(iplant.latinName)) {
    try {
      const iplantNameGbif = await resolveGbif(iplant.latinName);
      if (String(iplantNameGbif?.accepted?.key) === gbifId) verifiedScientificSynonyms.push(iplant.latinName);
      else errors.push(`iPlant学名未能核验为同一物种：${iplant.latinName}`);
    } catch (error) {
      errors.push(`iPlant学名关系核验失败：${iplant.latinName}（${error.message}）`);
    }
  }
  if (!acceptedChineseName) errors.push('iPlant未给出中文名');
  if (!family || !genus) errors.push('iPlant未给出中文科属');
  const iPlantMorphologyFacts = morphologyFacts(iplant);
  const floraText = stripHtml(iplant?.frps?.frpsdesc ?? '');
  const hasSourcedLifeForm = iPlantMorphologyFacts.some((item) => ['生活型', '株'].includes(item.subname))
    || /乔木|灌木|草本|藤本|攀援|蕨|叶状体|藓/.test(floraText);
  const externalMorphologySource = ((!iplant?.frps?.frpsdesc && iPlantMorphologyFacts.length < 3) || !hasSourcedLifeForm)
    ? (await resolveNcsu(acceptedScientificName)) ?? (await resolveEfloras(acceptedScientificName))
    : null;
  if (!iplant?.frps?.frpsdesc && iPlantMorphologyFacts.length < 3 && !externalMorphologySource) errors.push(`直接形态事实不足：中国植物志无正文，iPlant物种名片仅${iPlantMorphologyFacts.length}项，NC State无对应物种页`);
  if (baselineScientificNames.has(normalizeScientificName(acceptedScientificName))) errors.push('接受学名与现有100种重复');
  if (baselineIds.has(canonicalTaxonId)) errors.push('canonicalTaxonId与现有100种重复');
  if (baselineGbifIds.has(gbifId)) errors.push('GBIF ID与现有100种重复');
  return {
    inputName: row.inputName,
    inputScientificName: row.inputScientificName,
    acceptedChineseName,
    acceptedScientificName,
    family,
    genus,
    scientificSynonyms: [...new Set(verifiedScientificSynonyms)],
    providerMappings: { gbif: gbifId },
    requestedCoverageGroups: [row.group],
    resolutionStatus: errors.length ? 'needs_review' : 'new',
    resolvedCanonicalTaxonId: canonicalTaxonId,
    source: {
      gbif: gbifId ? `https://api.gbif.org/v1/species/${gbifId}` : `https://api.gbif.org/v1/species/match?name=${encodeURIComponent(row.inputScientificName)}`,
      chineseNameAndMorphology: iplant?.pageUrl ?? '',
      floraOfChina: iplant?.frps?.frpslink ? `https://www.iplant.cn/info/${encodeURIComponent(iplant.latinName)}?t=z` : '',
      supplementalMorphology: externalMorphologySource?.url ?? ''
    },
    notes: [
      row.inputName !== acceptedChineseName && acceptedChineseName ? `规划中文名“${row.inputName}”与iPlant正式名“${acceptedChineseName}”不同；规划名仅作为待审别名，不自动映射。` : '',
      gbif?.usage && gbif?.accepted && String(gbif.usage.key) !== String(gbif.accepted.key) ? `输入学名在GBIF为异名，接受名解析为 ${acceptedScientificName}。` : '',
      ...errors
    ].filter(Boolean).join(' '),
    verification: {
      gbifMatchType: gbif?.match?.matchType ?? '',
      gbifConfidence: gbif?.match?.confidence ?? null,
      inputGbifTaxonomicStatus: gbif?.usage?.taxonomicStatus ?? '',
      iPlantSpeciesId: iplant?.spno ?? '',
      iPlantScientificName: iplant?.latinName ?? '',
      hasChineseFloraDescription: Boolean(iplant?.frps?.frpsdesc),
      iPlantMorphologyFactCount: iPlantMorphologyFacts.length,
      iPlantMorphologyFields: iPlantMorphologyFacts.map((item) => item.subname),
      floraChineseName: iplant?.frps?.frpscname ?? '',
      floraDescriptionPreview: stripHtml(iplant?.frps?.frpsdesc ?? '').slice(0, 240)
    },
    planning: { coveragePriority: 'P1', sequence: index + 1 }
  };
};

const results = new Array(sourceRows.length);
let nextIndex = 0;
const worker = async () => {
  while (true) {
    const index = nextIndex++;
    if (index >= sourceRows.length) return;
    results[index] = await resolveCandidate(sourceRows[index], index);
    process.stdout.write(`${index + 1}/400 ${sourceRows[index].inputScientificName}: ${results[index].resolutionStatus}\n`);
  }
};
await Promise.all(Array.from({ length: 8 }, worker));

const acceptedNameOwners = new Map();
const idOwners = new Map();
const gbifOwners = new Map();
for (const item of results) {
  for (const [map, key, label] of [
    [acceptedNameOwners, normalizeScientificName(item.acceptedScientificName), '接受学名'],
    [idOwners, item.resolvedCanonicalTaxonId, 'canonicalTaxonId'],
    [gbifOwners, item.providerMappings.gbif, 'GBIF ID']
  ]) {
    if (!key) continue;
    if (map.has(key)) {
      item.resolutionStatus = 'needs_review';
      item.notes = `${item.notes} ${label}与候选“${map.get(key)}”重复。`.trim();
    } else map.set(key, item.inputName);
  }
}

const batch = {
  schemaVersion: 1,
  purpose: '现有100种基础上扩展至500种的新增400种候选；不是正式知识库。',
  generatedAt: '2026-08-16',
  sourcePolicy: 'GBIF直接物种端点核验接受名和外部ID；iPlant具体物种页核验中文名、中文科属与形态来源可用性。',
  expectedCoverageGroupCounts: Object.fromEntries(expectedCounts),
  candidates: results
};
await writeFile(outputPath, `${JSON.stringify(batch, null, 2)}\n`, 'utf8');
console.log(`Wrote ${results.length} candidates to ${outputPath}`);
console.log(results.reduce((summary, item) => ({ ...summary, [item.resolutionStatus]: (summary[item.resolutionStatus] ?? 0) + 1 }), {}));
