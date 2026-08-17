# WildSight 500种植物知识库部署前全量审核

> 审核日期：2026-08-16。本报告由 `npm run audit:knowledge-500` 生成；审核器只读取知识JSON、候选、基线、映射和实时权威来源，仅写入本报告。

## 结论

- 审核物种数：500（原100种回归审核；新增400种逐条实时分类、中文身份、形态来源和内容审核）
- published/reviewed：500
- L2：500
- 名称映射物种：500/500；映射条目：501
- BLOCKER：0
- MAJOR：0
- MINOR：0
- 批次是否通过：通过

## 实时来源核验

- GBIF接受种、SPECIES等级、canonicalName及ID一致：400/400
- iPlant具体页中文名、学名和物种ID一致：400/400
- iPlant中文科属分类接口一致：400/400
- iPlant逐字段形态接口可用：400/400
- 补充FNA/NC State直接页可访问且指向目标物种：36/36
- 使用补充英文直接页、逐条保留中文事实转述审查标记：36
- 无法访问的来源请求：0

## 覆盖统计

- 类群：angiosperm 448；fern 29；gymnosperm 13；bryophyte 10
- 生活型：shrub 111；herb 270；tree 92；vine 49；subshrub 1
- 场景：roadside 84；wasteland 36；forest 96；forest-edge 77；wetland-waterside 72；urban-greening 57；park-garden 82；aquatic 26；farmland 34；indoor 17
- 发生类型：wild 266；cultivated 81；naturalized 3
- 用途：ornamental-foliage 11；hedge 14；climber 2；street-tree 2；shade-tree 1；ornamental-flower 3；groundcover 1
- 新增400规划组：城市及常见乔木 55；灌木与绿篱 50；公园花卉与地被 65；路边及荒地草本 55；农田、作物及田边植物 35；藤本植物 25；蕨类植物 20；水生及湿地植物 25；室内观叶及常见盆栽 35；林地及林缘植物 25；常见苔藓植物 10

## 问题明细

未发现问题。

## 新增400种逐条审核结果

| 序号 | 物种ID | 中文名 | GBIF | iPlant身份 | sourceFacts | 补充来源 | 最终状态 |
| ---: | --- | --- | --- | --- | --- | --- | --- |
| 1 | acer-buergerianum | 三角槭 | verified | page-verified | directly-supported | not-required | 可发布 |
| 2 | acer-palmatum | 鸡爪槭 | verified | page-verified | directly-supported | not-required | 可发布 |
| 3 | acer-truncatum | 元宝槭 | verified | page-verified | directly-supported | not-required | 可发布 |
| 4 | acer-negundo | 梣叶槭 | verified | page-verified | directly-supported | not-required | 可发布 |
| 5 | acer-davidii | 青榨槭 | verified | page-verified | directly-supported | not-required | 可发布 |
| 6 | ailanthus-altissima | 臭椿 | verified | page-verified | directly-supported | not-required | 可发布 |
| 7 | ulmus-pumila | 榆 | verified | page-verified | directly-supported | not-required | 可发布 |
| 8 | broussonetia-papyrifera | 构 | verified | page-verified | directly-supported | not-required | 可发布 |
| 9 | camptotheca-acuminata | 喜树 | verified | page-verified | directly-supported | not-required | 可发布 |
| 10 | catalpa-bungei | 楸 | verified | page-verified | directly-supported | not-required | 可发布 |
| 11 | catalpa-ovata | 梓 | verified | page-verified | directly-supported | not-required | 可发布 |
| 12 | cercis-chinensis | 紫荆 | verified | page-verified | directly-supported | not-required | 可发布 |
| 13 | cryptomeria-japonica | 日本柳杉 | verified | page-verified | directly-supported | not-required | 可发布 |
| 14 | cunninghamia-lanceolata | 杉木 | verified | page-verified | directly-supported | not-required | 可发布 |
| 15 | cupressus-funebris | 柏木 | verified | page-verified | directly-supported | not-required | 可发布 |
| 16 | dalbergia-hupeana | 黄檀 | verified | page-verified | directly-supported | not-required | 可发布 |
| 17 | diospyros-kaki | 柿 | verified | page-verified | directly-supported | not-required | 可发布 |
| 18 | elaeocarpus-decipiens | 杜英 | verified | page-verified | directly-supported | not-required | 可发布 |
| 19 | eucommia-ulmoides | 杜仲 | verified | page-verified | directly-supported | not-required | 可发布 |
| 20 | firmiana-simplex | 梧桐 | verified | page-verified | directly-supported | not-required | 可发布 |
| 21 | gleditsia-sinensis | 皂荚 | verified | page-verified | directly-supported | not-required | 可发布 |
| 22 | idesia-polycarpa | 山桐子 | verified | page-verified | directly-supported | not-required | 可发布 |
| 23 | juglans-regia | 胡桃 | verified | page-verified | directly-supported | not-required | 可发布 |
| 24 | juniperus-chinensis | 圆柏 | verified | page-verified | directly-supported | not-required | 可发布 |
| 25 | koelreuteria-bipinnata | 复羽叶栾 | verified | page-verified | directly-supported | not-required | 可发布 |
| 26 | liquidambar-formosana | 枫香树 | verified | page-verified | directly-supported | not-required | 可发布 |
| 27 | liriodendron-chinense | 鹅掌楸 | verified | page-verified | directly-supported | not-required | 可发布 |
| 28 | pinus-bungeana | 白皮松 | verified | page-verified | directly-supported | not-required | 可发布 |
| 29 | picea-asperata | 云杉 | verified | page-verified | directly-supported | not-required | 可发布 |
| 30 | malus-hupehensis | 湖北海棠 | verified | page-verified | directly-supported | not-required | 可发布 |
| 31 | malus-spectabilis | 海棠花 | verified | page-verified | directly-supported | not-required | 可发布 |
| 32 | melia-azedarach | 楝 | verified | page-verified | directly-supported | not-required | 可发布 |
| 33 | morus-alba | 桑 | verified | page-verified | directly-supported | not-required | 可发布 |
| 34 | paulownia-fortunei | 白花泡桐 | verified | page-verified | directly-supported | not-required | 可发布 |
| 35 | phoenix-canariensis | 加那利海枣 | verified | page-verified | directly-supported | not-required | 可发布 |
| 36 | pinus-massoniana | 马尾松 | verified | page-verified | directly-supported | not-required | 可发布 |
| 37 | pinus-tabuliformis | 油松 | verified | page-verified | directly-supported | not-required | 可发布 |
| 38 | populus-tomentosa | 毛白杨 | verified | page-verified | directly-supported | not-required | 可发布 |
| 39 | prunus-armeniaca | 杏 | verified | page-verified | directly-supported | not-required | 可发布 |
| 40 | prunus-cerasifera | 樱桃李 | verified | page-verified | directly-supported | not-required | 可发布 |
| 41 | prunus-mume | 梅 | verified | page-verified | directly-supported | not-required | 可发布 |
| 42 | prunus-persica | 桃 | verified | page-verified | directly-supported | not-required | 可发布 |
| 43 | prunus-serrulata | 山樱花 | verified | page-verified | directly-supported | not-required | 可发布 |
| 44 | pyrus-bretschneideri | 白梨 | verified | page-verified | directly-supported | not-required | 可发布 |
| 45 | pyrus-calleryana | 豆梨 | verified | page-verified | directly-supported | not-required | 可发布 |
| 46 | quercus-acutissima | 麻栎 | verified | page-verified | directly-supported | not-required | 可发布 |
| 47 | quercus-variabilis | 栓皮栎 | verified | page-verified | directly-supported | not-required | 可发布 |
| 48 | robinia-pseudoacacia | 刺槐 | verified | page-verified | directly-supported | not-required | 可发布 |
| 49 | salix-babylonica | 垂柳 | verified | page-verified | directly-supported | not-required | 可发布 |
| 50 | sapindus-mukorossi | 无患子 | verified | page-verified | directly-supported | not-required | 可发布 |
| 51 | schima-superba | 木荷 | verified | page-verified | directly-supported | not-required | 可发布 |
| 52 | taxodium-distichum | 落羽杉 | verified | page-verified | directly-supported | not-required | 可发布 |
| 53 | toona-sinensis | 香椿 | verified | page-verified | directly-supported | not-required | 可发布 |
| 54 | trachycarpus-fortunei | 棕榈 | verified | page-verified | directly-supported | not-required | 可发布 |
| 55 | triadica-sebifera | 乌桕 | verified | page-verified | directly-supported | not-required | 可发布 |
| 56 | abelia-chinensis | 糯米条 | verified | page-verified | directly-supported | not-required | 可发布 |
| 57 | berberis-thunbergii | 日本小檗 | verified | page-verified | directly-supported | not-required | 可发布 |
| 58 | spiraea-salicifolia | 绣线菊 | verified | page-verified | directly-supported | not-required | 可发布 |
| 59 | buxus-megistophylla | 大叶黄杨 | verified | page-verified | directly-supported | not-required | 可发布 |
| 60 | chaenomeles-speciosa | 贴梗海棠 | verified | page-verified | directly-supported | not-required | 可发布 |
| 61 | clerodendrum-trichotomum | 海州常山 | verified | page-verified | directly-supported | not-required | 可发布 |
| 62 | cornus-alba | 红瑞木 | verified | page-verified | directly-supported | not-required | 可发布 |
| 63 | cotoneaster-horizontalis | 平枝栒子 | verified | page-verified | directly-supported | not-required | 可发布 |
| 64 | daphne-odora | 瑞香 | verified | page-verified | directly-supported | not-required | 可发布 |
| 65 | deutzia-scabra | 溲疏 | verified | page-verified | directly-supported | not-required | 可发布 |
| 66 | edgeworthia-chrysantha | 结香 | verified | page-verified | directly-supported | not-required | 可发布 |
| 67 | elaeagnus-pungens | 胡颓子 | verified | page-verified | directly-supported | not-required | 可发布 |
| 68 | euonymus-alatus | 卫矛 | verified | page-verified | directly-supported | not-required | 可发布 |
| 69 | euonymus-fortunei | 扶芳藤 | verified | page-verified | directly-supported | not-required | 可发布 |
| 70 | exochorda-racemosa | 白鹃梅 | verified | page-verified | directly-supported | not-required | 可发布 |
| 71 | forsythia-viridissima | 金钟花 | verified | page-verified | directly-supported | not-required | 可发布 |
| 72 | gardenia-jasminoides | 栀子 | verified | page-verified | directly-supported | not-required | 可发布 |
| 73 | hibiscus-mutabilis | 木芙蓉 | verified | page-verified | directly-supported | not-required | 可发布 |
| 74 | hydrangea-macrophylla | 绣球 | verified | page-verified | directly-supported | not-required | 可发布 |
| 75 | indigofera-kirilowii | 花木蓝 | verified | page-verified | directly-supported | not-required | 可发布 |
| 76 | jasminum-mesnyi | 野迎春 | verified | page-verified | directly-supported | not-required | 可发布 |
| 77 | kerria-japonica | 棣棠 | verified | page-verified | directly-supported | not-required | 可发布 |
| 78 | kolkwitzia-amabilis | 猬实 | verified | page-verified | directly-supported | not-required | 可发布 |
| 79 | lespedeza-bicolor | 胡枝子 | verified | page-verified | directly-supported | not-required | 可发布 |
| 80 | ligustrum-quihoui | 小叶女贞 | verified | page-verified | directly-supported | not-required | 可发布 |
| 81 | lonicera-fragrantissima | 郁香忍冬 | verified | page-verified | directly-supported | not-required | 可发布 |
| 82 | loropetalum-chinense | 檵木 | verified | page-verified | directly-supported | not-required | 可发布 |
| 83 | physocarpus-amurensis | 风箱果 | verified | page-verified | directly-supported | not-required | 可发布 |
| 84 | mahonia-fortunei | 十大功劳 | verified | page-verified | directly-supported | not-required | 可发布 |
| 85 | myrtus-communis | 香桃木 | verified | page-verified | directly-supported | not-required | 可发布 |
| 86 | nerium-oleander | 夹竹桃 | verified | page-verified | directly-supported | not-required | 可发布 |
| 87 | osmanthus-heterophyllus | 柊树 | verified | page-verified | directly-supported | not-required | 可发布 |
| 88 | rhododendron-molle | 羊踯躅 | verified | page-verified | directly-supported | not-required | 可发布 |
| 89 | philadelphus-pekinensis | 太平花 | verified | page-verified | directly-supported | not-required | 可发布 |
| 90 | prunus-glandulosa | 麦李 | verified | page-verified | directly-supported | not-required | 可发布 |
| 91 | punica-granatum | 石榴 | verified | page-verified | directly-supported | not-required | 可发布 |
| 92 | pyracantha-fortuneana | 火棘 | verified | page-verified | directly-supported | not-required | 可发布 |
| 93 | rhaphiolepis-indica | 石斑木 | verified | page-verified | directly-supported | not-required | 可发布 |
| 94 | rosa-banksiae | 木香花 | verified | page-verified | directly-supported | not-required | 可发布 |
| 95 | rosa-multiflora | 野蔷薇 | verified | page-verified | directly-supported | not-required | 可发布 |
| 96 | rosa-rugosa | 玫瑰 | verified | page-verified | directly-supported | not-required | 可发布 |
| 97 | sambucus-williamsii | 接骨木 | verified | page-verified | directly-supported | not-required | 可发布 |
| 98 | spiraea-cantoniensis | 麻叶绣线菊 | verified | page-verified | directly-supported | not-required | 可发布 |
| 99 | spiraea-japonica | 粉花绣线菊 | verified | page-verified | directly-supported | not-required | 可发布 |
| 100 | syringa-oblata | 紫丁香 | verified | page-verified | directly-supported | not-required | 可发布 |
| 101 | viburnum-dilatatum | 荚蒾 | verified | page-verified | directly-supported | not-required | 可发布 |
| 102 | viburnum-odoratissimum | 珊瑚树 | verified | page-verified | directly-supported | not-required | 可发布 |
| 103 | vitex-negundo | 黄荆 | verified | page-verified | directly-supported | not-required | 可发布 |
| 104 | prunus-triloba | 榆叶梅 | verified | page-verified | directly-supported | not-required | 可发布 |
| 105 | rhododendron-mucronulatum | 迎红杜鹃 | verified | page-verified | directly-supported | not-required | 可发布 |
| 106 | achillea-millefolium | 蓍 | verified | page-verified | directly-supported | not-required | 可发布 |
| 107 | ajuga-reptans | 匍匐筋骨草 | verified | page-verified | supplemental-translation-review (8) | verified | 可发布 |
| 108 | alcea-rosea | 蜀葵 | verified | page-verified | directly-supported | not-required | 可发布 |
| 109 | coleus-scutellarioides | 五彩苏 | verified | page-verified | directly-supported | not-required | 可发布 |
| 110 | antirrhinum-majus | 金鱼草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 111 | aquilegia-viridiflora | 耧斗菜 | verified | page-verified | supplemental-translation-review (1) | verified | 可发布 |
| 112 | argyranthemum-frutescens | 木茼蒿 | verified | page-verified | directly-supported | not-required | 可发布 |
| 113 | armeria-maritima | 海石竹 | verified | page-verified | directly-supported | not-required | 可发布 |
| 114 | astilbe-rubra | 腺萼落新妇 | verified | page-verified | directly-supported | not-required | 可发布 |
| 115 | bellis-perennis | 雏菊 | verified | page-verified | directly-supported | not-required | 可发布 |
| 116 | bergenia-purpurascens | 岩白菜 | verified | page-verified | directly-supported | not-required | 可发布 |
| 117 | begonia-cucullata | 四季秋海棠 | verified | page-verified | directly-supported | not-required | 可发布 |
| 118 | catharanthus-roseus | 长春花 | verified | page-verified | directly-supported | not-required | 可发布 |
| 119 | celosia-argentea | 青葙 | verified | page-verified | directly-supported | not-required | 可发布 |
| 120 | callistephus-chinensis | 翠菊 | verified | page-verified | directly-supported | not-required | 可发布 |
| 121 | cosmos-bipinnatus | 秋英 | verified | page-verified | directly-supported | not-required | 可发布 |
| 122 | chrysanthemum-indicum | 野菊 | verified | page-verified | directly-supported | not-required | 可发布 |
| 123 | dahlia-pinnata | 大丽花 | verified | page-verified | directly-supported | not-required | 可发布 |
| 124 | dianthus-barbatus | 须苞石竹 | verified | page-verified | directly-supported | not-required | 可发布 |
| 125 | dianthus-chinensis | 石竹 | verified | page-verified | directly-supported | not-required | 可发布 |
| 126 | echinacea-purpurea | 松果菊 | verified | page-verified | directly-supported | not-required | 可发布 |
| 127 | eschscholzia-californica | 花菱草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 128 | gaillardia-aristata | 宿根天人菊 | verified | page-verified | directly-supported | not-required | 可发布 |
| 129 | gazania-rigens | 勋章菊 | verified | page-verified | directly-supported | not-required | 可发布 |
| 130 | gomphrena-globosa | 千日红 | verified | page-verified | directly-supported | not-required | 可发布 |
| 131 | helianthus-annuus | 向日葵 | verified | page-verified | directly-supported | not-required | 可发布 |
| 132 | impatiens-hawkeri | 新几内亚凤仙花 | verified | page-verified | directly-supported | not-required | 可发布 |
| 133 | ipheion-uniflorum | 春星韭 | verified | page-verified | supplemental-translation-review (6) | verified | 可发布 |
| 134 | iris-germanica | 德国鸢尾 | verified | page-verified | directly-supported | not-required | 可发布 |
| 135 | lobularia-maritima | 香雪球 | verified | page-verified | directly-supported | not-required | 可发布 |
| 136 | matthiola-incana | 紫罗兰 | verified | page-verified | directly-supported | not-required | 可发布 |
| 137 | mirabilis-jalapa | 紫茉莉 | verified | page-verified | directly-supported | not-required | 可发布 |
| 138 | nemesia-strumosa | 龙面花 | verified | page-verified | supplemental-translation-review (6) | verified | 可发布 |
| 139 | nicotiana-alata | 花烟草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 140 | oenothera-speciosa | 美丽月见草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 141 | dimorphotheca-ecklonis | 蓝目菊 | verified | page-verified | directly-supported | not-required | 可发布 |
| 142 | primula-malacoides | 报春花 | verified | page-verified | directly-supported | not-required | 可发布 |
| 143 | silene-coronaria | 毛剪秋罗 | verified | page-verified | directly-supported | not-required | 可发布 |
| 144 | pentas-lanceolata | 五星花 | verified | page-verified | directly-supported | not-required | 可发布 |
| 145 | phlox-drummondii | 福禄考 | verified | page-verified | directly-supported | not-required | 可发布 |
| 146 | platycodon-grandiflorus | 桔梗 | verified | page-verified | directly-supported | not-required | 可发布 |
| 147 | portulaca-grandiflora | 大花马齿苋 | verified | page-verified | directly-supported | not-required | 可发布 |
| 148 | rudbeckia-hirta | 黑心菊 | verified | page-verified | directly-supported | not-required | 可发布 |
| 149 | rudbeckia-laciniata | 金光菊 | verified | page-verified | directly-supported | not-required | 可发布 |
| 150 | salvia-farinacea | 蓝花鼠尾草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 151 | salvia-splendens | 一串红 | verified | page-verified | directly-supported | not-required | 可发布 |
| 152 | silene-pendula | 大蔓樱草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 153 | sedum-lineare | 佛甲草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 154 | sedum-sarmentosum | 垂盆草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 155 | jacobaea-maritima | 银叶菊 | verified | page-verified | directly-supported | not-required | 可发布 |
| 156 | limonium-bicolor | 二色补血草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 157 | torenia-fournieri | 蓝猪耳 | verified | page-verified | directly-supported | not-required | 可发布 |
| 158 | tropaeolum-majus | 旱金莲 | verified | page-verified | directly-supported | not-required | 可发布 |
| 159 | verbena-bonariensis | 柳叶马鞭草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 160 | viola-cornuta | 角堇 | verified | page-verified | supplemental-translation-review (1) | verified | 可发布 |
| 161 | viola-philippica | 紫花地丁 | verified | page-verified | directly-supported | not-required | 可发布 |
| 162 | zephyranthes-candida | 葱莲 | verified | page-verified | directly-supported | not-required | 可发布 |
| 163 | zephyranthes-carinata | 韭莲 | verified | page-verified | directly-supported | not-required | 可发布 |
| 164 | symphyotrichum-novi-belgii | 联毛紫菀 | verified | page-verified | directly-supported | not-required | 可发布 |
| 165 | cichorium-intybus | 菊苣 | verified | page-verified | directly-supported | not-required | 可发布 |
| 166 | clarkia-amoena | 古代稀 | verified | page-verified | directly-supported | not-required | 可发布 |
| 167 | alternanthera-bettzickiana | 锦绣苋 | verified | page-verified | directly-supported | not-required | 可发布 |
| 168 | lantana-camara | 马缨丹 | verified | page-verified | directly-supported | not-required | 可发布 |
| 169 | dianthus-superbus | 瞿麦 | verified | page-verified | directly-supported | not-required | 可发布 |
| 170 | angelonia-angustifolia | 香彩雀 | verified | page-verified | supplemental-translation-review (8) | verified | 可发布 |
| 171 | acalypha-australis | 铁苋菜 | verified | page-verified | directly-supported | not-required | 可发布 |
| 172 | achyranthes-bidentata | 牛膝 | verified | page-verified | directly-supported | not-required | 可发布 |
| 173 | abutilon-theophrasti | 苘麻 | verified | page-verified | directly-supported | not-required | 可发布 |
| 174 | amaranthus-spinosus | 刺苋 | verified | page-verified | directly-supported | not-required | 可发布 |
| 175 | ambrosia-artemisiifolia | 豚草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 176 | artemisia-argyi | 艾 | verified | page-verified | directly-supported | not-required | 可发布 |
| 177 | artemisia-annua | 黄花蒿 | verified | page-verified | directly-supported | not-required | 可发布 |
| 178 | artemisia-indica | 五月艾 | verified | page-verified | directly-supported | not-required | 可发布 |
| 179 | bidens-pilosa | 鬼针草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 180 | bothriochloa-ischaemum | 白羊草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 181 | capsella-bursa-pastoris | 荠 | verified | page-verified | directly-supported | not-required | 可发布 |
| 182 | cardamine-hirsuta | 粗毛碎米荠 | verified | page-verified | directly-supported | not-required | 可发布 |
| 183 | cerastium-glomeratum | 球序卷耳 | verified | page-verified | directly-supported | not-required | 可发布 |
| 184 | cirsium-arvense | 丝路蓟 | verified | page-verified | directly-supported | not-required | 可发布 |
| 185 | commelina-communis | 鸭跖草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 186 | cynodon-dactylon | 狗牙根 | verified | page-verified | directly-supported | not-required | 可发布 |
| 187 | dactylis-glomerata | 鸭茅 | verified | page-verified | supplemental-translation-review (2) | verified | 可发布 |
| 188 | digitaria-sanguinalis | 马唐 | verified | page-verified | directly-supported | not-required | 可发布 |
| 189 | eclipta-prostrata | 鳢肠 | verified | page-verified | directly-supported | not-required | 可发布 |
| 190 | galinsoga-quadriradiata | 粗毛牛膝菊 | verified | page-verified | supplemental-translation-review (3) | verified | 可发布 |
| 191 | geranium-carolinianum | 野老鹳草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 192 | pseudognaphalium-affine | 鼠曲草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 193 | houttuynia-cordata | 蕺菜 | verified | page-verified | directly-supported | not-required | 可发布 |
| 194 | kummerowia-striata | 鸡眼草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 195 | lactuca-indica | 翅果菊 | verified | page-verified | directly-supported | not-required | 可发布 |
| 196 | lamium-amplexicaule | 宝盖草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 197 | lapsanastrum-apogonoides | 稻槎菜 | verified | page-verified | directly-supported | not-required | 可发布 |
| 198 | leonurus-japonicus | 益母草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 199 | lepidium-apetalum | 独行菜 | verified | page-verified | directly-supported | not-required | 可发布 |
| 200 | malva-verticillata | 野葵 | verified | page-verified | directly-supported | not-required | 可发布 |
| 201 | mazus-pumilus | 通泉草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 202 | medicago-lupulina | 天蓝苜蓿 | verified | page-verified | directly-supported | not-required | 可发布 |
| 203 | melilotus-officinalis | 黄香草木犀 | verified | page-verified | directly-supported | not-required | 可发布 |
| 204 | oenothera-biennis | 月见草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 205 | artemisia-scoparia | 猪毛蒿 | verified | page-verified | directly-supported | not-required | 可发布 |
| 206 | persicaria-hydropiper | 水蓼 | verified | page-verified | directly-supported | not-required | 可发布 |
| 207 | phytolacca-americana | 垂序商陆 | verified | page-verified | directly-supported | not-required | 可发布 |
| 208 | plantago-virginica | 北美车前 | verified | page-verified | directly-supported | not-required | 可发布 |
| 209 | polygonum-aviculare | 萹蓄 | verified | page-verified | directly-supported | not-required | 可发布 |
| 210 | potentilla-chinensis | 委陵菜 | verified | page-verified | directly-supported | not-required | 可发布 |
| 211 | plantago-depressa | 平车前 | verified | page-verified | directly-supported | not-required | 可发布 |
| 212 | rorippa-indica | 蔊菜 | verified | page-verified | directly-supported | not-required | 可发布 |
| 213 | rumex-crispus | 皱叶酸模 | verified | page-verified | directly-supported | not-required | 可发布 |
| 214 | senecio-vulgaris | 欧洲千里光 | verified | page-verified | directly-supported | not-required | 可发布 |
| 215 | setaria-faberi | 大狗尾草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 216 | solanum-nigrum | 龙葵 | verified | page-verified | directly-supported | not-required | 可发布 |
| 217 | symphyotrichum-subulatum | 钻叶紫菀 | verified | page-verified | supplemental-translation-review (1) | verified | 可发布 |
| 218 | trifolium-repens | 白车轴草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 219 | tridax-procumbens | 羽芒菊 | verified | page-verified | directly-supported | not-required | 可发布 |
| 220 | veronica-persica | 阿拉伯婆婆纳 | verified | page-verified | directly-supported | not-required | 可发布 |
| 221 | vicia-sativa | 救荒野豌豆 | verified | page-verified | directly-supported | not-required | 可发布 |
| 222 | viola-patrinii | 白花地丁 | verified | page-verified | directly-supported | not-required | 可发布 |
| 223 | xanthium-strumarium | 苍耳 | verified | page-verified | directly-supported | not-required | 可发布 |
| 224 | youngia-japonica | 黄鹌菜 | verified | page-verified | directly-supported | not-required | 可发布 |
| 225 | oenothera-lindheimeri | 山桃草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 226 | allium-cepa | 洋葱 | verified | page-verified | supplemental-translation-review (4) | verified | 可发布 |
| 227 | allium-sativum | 蒜 | verified | page-verified | supplemental-translation-review (4) | verified | 可发布 |
| 228 | beta-vulgaris | 甜菜 | verified | page-verified | directly-supported | not-required | 可发布 |
| 229 | brassica-oleracea | 野甘蓝 | verified | page-verified | directly-supported | not-required | 可发布 |
| 230 | brassica-rapa | 蔓菁 | verified | page-verified | directly-supported | not-required | 可发布 |
| 231 | cajanus-cajan | 木豆 | verified | page-verified | directly-supported | not-required | 可发布 |
| 232 | camellia-sinensis | 茶 | verified | page-verified | directly-supported | not-required | 可发布 |
| 233 | capsicum-annuum | 辣椒 | verified | page-verified | directly-supported | not-required | 可发布 |
| 234 | citrullus-lanatus | 西瓜 | verified | page-verified | directly-supported | not-required | 可发布 |
| 235 | coix-lacryma-jobi | 薏苡 | verified | page-verified | directly-supported | not-required | 可发布 |
| 236 | corchorus-capsularis | 黄麻 | verified | page-verified | directly-supported | not-required | 可发布 |
| 237 | cucumis-sativus | 黄瓜 | verified | page-verified | directly-supported | not-required | 可发布 |
| 238 | cucumis-melo | 甜瓜 | verified | page-verified | directly-supported | not-required | 可发布 |
| 239 | cucurbita-moschata | 南瓜 | verified | page-verified | directly-supported | not-required | 可发布 |
| 240 | daucus-carota | 野胡萝卜 | verified | page-verified | directly-supported | not-required | 可发布 |
| 241 | fagopyrum-esculentum | 荞麦 | verified | page-verified | directly-supported | not-required | 可发布 |
| 242 | helianthus-tuberosus | 菊芋 | verified | page-verified | directly-supported | not-required | 可发布 |
| 243 | hordeum-vulgare | 大麦 | verified | page-verified | directly-supported | not-required | 可发布 |
| 244 | ipomoea-aquatica | 蕹菜 | verified | page-verified | directly-supported | not-required | 可发布 |
| 245 | lactuca-sativa | 莴苣 | verified | page-verified | directly-supported | not-required | 可发布 |
| 246 | luffa-aegyptiaca | 丝瓜 | verified | page-verified | directly-supported | not-required | 可发布 |
| 247 | medicago-sativa | 苜蓿 | verified | page-verified | directly-supported | not-required | 可发布 |
| 248 | nicotiana-tabacum | 烟草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 249 | phaseolus-vulgaris | 菜豆 | verified | page-verified | directly-supported | not-required | 可发布 |
| 250 | lathyrus-oleraceus | 菜山黧豆 | verified | page-verified | supplemental-translation-review (9) | verified | 可发布 |
| 251 | raphanus-sativus | 萝卜 | verified | page-verified | directly-supported | not-required | 可发布 |
| 252 | sesamum-indicum | 芝麻 | verified | page-verified | directly-supported | not-required | 可发布 |
| 253 | solanum-lycopersicum | 番茄 | verified | page-verified | directly-supported | not-required | 可发布 |
| 254 | solanum-melongena | 茄 | verified | page-verified | directly-supported | not-required | 可发布 |
| 255 | solanum-tuberosum | 马铃薯 | verified | page-verified | directly-supported | not-required | 可发布 |
| 256 | sorghum-bicolor | 高粱 | verified | page-verified | directly-supported | not-required | 可发布 |
| 257 | vicia-faba | 蚕豆 | verified | page-verified | directly-supported | not-required | 可发布 |
| 258 | vigna-radiata | 绿豆 | verified | page-verified | directly-supported | not-required | 可发布 |
| 259 | vigna-unguiculata | 豇豆 | verified | page-verified | directly-supported | not-required | 可发布 |
| 260 | zizania-latifolia | 菰 | verified | page-verified | directly-supported | not-required | 可发布 |
| 261 | akebia-quinata | 木通 | verified | page-verified | directly-supported | not-required | 可发布 |
| 262 | actinidia-chinensis | 中华猕猴桃 | verified | page-verified | directly-supported | not-required | 可发布 |
| 263 | ampelopsis-glandulosa | 蛇葡萄 | verified | page-verified | directly-supported | not-required | 可发布 |
| 264 | aristolochia-debilis | 马兜铃 | verified | page-verified | directly-supported | not-required | 可发布 |
| 265 | campsis-grandiflora | 凌霄 | verified | page-verified | directly-supported | not-required | 可发布 |
| 266 | campsis-radicans | 厚萼凌霄 | verified | page-verified | directly-supported | not-required | 可发布 |
| 267 | celastrus-orbiculatus | 南蛇藤 | verified | page-verified | directly-supported | not-required | 可发布 |
| 268 | sinomenium-acutum | 风龙 | verified | page-verified | directly-supported | not-required | 可发布 |
| 269 | clematis-chinensis | 威灵仙 | verified | page-verified | directly-supported | not-required | 可发布 |
| 270 | clematis-florida | 铁线莲 | verified | page-verified | directly-supported | not-required | 可发布 |
| 271 | dioscorea-polystachya | 薯蓣 | verified | page-verified | directly-supported | not-required | 可发布 |
| 272 | stephania-japonica | 千金藤 | verified | page-verified | directly-supported | not-required | 可发布 |
| 273 | gelsemium-elegans | 钩吻 | verified | page-verified | directly-supported | not-required | 可发布 |
| 274 | lonicera-japonica | 忍冬 | verified | page-verified | directly-supported | not-required | 可发布 |
| 275 | paederia-foetida | 鸡屎藤 | verified | page-verified | directly-supported | not-required | 可发布 |
| 276 | passiflora-caerulea | 西番莲 | verified | page-verified | directly-supported | not-required | 可发布 |
| 277 | periploca-sepium | 杠柳 | verified | page-verified | directly-supported | not-required | 可发布 |
| 278 | pueraria-montana | 山葛 | verified | page-verified | directly-supported | not-required | 可发布 |
| 279 | schisandra-chinensis | 五味子 | verified | page-verified | directly-supported | not-required | 可发布 |
| 280 | solanum-lyratum | 白英 | verified | page-verified | directly-supported | not-required | 可发布 |
| 281 | thunbergia-grandiflora | 山牵牛 | verified | page-verified | directly-supported | not-required | 可发布 |
| 282 | trachelospermum-jasminoides | 络石 | verified | page-verified | directly-supported | not-required | 可发布 |
| 283 | vitis-amurensis | 山葡萄 | verified | page-verified | directly-supported | not-required | 可发布 |
| 284 | vitis-vinifera | 葡萄 | verified | page-verified | directly-supported | not-required | 可发布 |
| 285 | tetrastigma-hemsleyanum | 三叶崖爬藤 | verified | page-verified | directly-supported | not-required | 可发布 |
| 286 | adiantum-flabellulatum | 扇叶铁线蕨 | verified | page-verified | directly-supported | not-required | 可发布 |
| 287 | asplenium-nidus | 巢蕨 | verified | page-verified | directly-supported | not-required | 可发布 |
| 288 | anisocampium-niponicum | 日本安蕨 | verified | page-verified | directly-supported | not-required | 可发布 |
| 289 | blechnopsis-orientalis | 乌毛蕨 | verified | page-verified | directly-supported | not-required | 可发布 |
| 290 | coniogramme-intermedia | 普通凤了蕨 | verified | page-verified | directly-supported | not-required | 可发布 |
| 291 | cyrtomium-falcatum | 全缘贯众 | verified | page-verified | directly-supported | not-required | 可发布 |
| 292 | woodwardia-japonica | 狗脊 | verified | page-verified | directly-supported | not-required | 可发布 |
| 293 | dicranopteris-pedata | 芒萁 | verified | page-verified | directly-supported | not-required | 可发布 |
| 294 | diplazium-esculentum | 菜蕨 | verified | page-verified | directly-supported | not-required | 可发布 |
| 295 | dryopteris-crassirhizoma | 粗茎鳞毛蕨 | verified | page-verified | directly-supported | not-required | 可发布 |
| 296 | dryopteris-erythrosora | 红盖鳞毛蕨 | verified | page-verified | directly-supported | not-required | 可发布 |
| 297 | lepisorus-thunbergianus | 瓦韦 | verified | page-verified | directly-supported | not-required | 可发布 |
| 298 | lygodium-japonicum | 海金沙 | verified | page-verified | directly-supported | not-required | 可发布 |
| 299 | marsilea-quadrifolia | 蘋 | verified | page-verified | directly-supported | not-required | 可发布 |
| 300 | matteuccia-struthiopteris | 荚果蕨 | verified | page-verified | directly-supported | not-required | 可发布 |
| 301 | dryopteris-varia | 变异鳞毛蕨 | verified | page-verified | directly-supported | not-required | 可发布 |
| 302 | osmunda-japonica | 紫萁 | verified | page-verified | directly-supported | not-required | 可发布 |
| 303 | platycerium-bifurcatum | 二歧鹿角蕨 | verified | page-verified | directly-supported | not-required | 可发布 |
| 304 | pteris-ensiformis | 剑叶凤尾蕨 | verified | page-verified | directly-supported | not-required | 可发布 |
| 305 | selaginella-tamariscina | 卷柏 | verified | page-verified | directly-supported | not-required | 可发布 |
| 306 | acorus-calamus | 菖蒲 | verified | page-verified | directly-supported | not-required | 可发布 |
| 307 | acorus-gramineus | 金钱蒲 | verified | page-verified | directly-supported | not-required | 可发布 |
| 308 | salvinia-natans | 槐叶蘋 | verified | page-verified | directly-supported | not-required | 可发布 |
| 309 | butomus-umbellatus | 花蔺 | verified | page-verified | directly-supported | not-required | 可发布 |
| 310 | ceratophyllum-demersum | 金鱼藻 | verified | page-verified | directly-supported | not-required | 可发布 |
| 311 | euryale-ferox | 芡 | verified | page-verified | directly-supported | not-required | 可发布 |
| 312 | hydrilla-verticillata | 黑藻 | verified | page-verified | directly-supported | not-required | 可发布 |
| 313 | hydrocharis-dubia | 水鳖 | verified | page-verified | directly-supported | not-required | 可发布 |
| 314 | iris-pseudacorus | 黄菖蒲 | verified | page-verified | directly-supported | not-required | 可发布 |
| 315 | juncus-effusus | 灯芯草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 316 | ludwigia-adscendens | 水龙 | verified | page-verified | directly-supported | not-required | 可发布 |
| 317 | pontederia-vaginalis | 鸭舌草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 318 | myriophyllum-spicatum | 穗状狐尾藻 | verified | page-verified | directly-supported | not-required | 可发布 |
| 319 | nymphoides-peltata | 荇菜 | verified | page-verified | directly-supported | not-required | 可发布 |
| 320 | nymphaea-tetragona | 睡莲 | verified | page-verified | directly-supported | not-required | 可发布 |
| 321 | ottelia-alismoides | 龙舌草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 322 | persicaria-orientalis | 红蓼 | verified | page-verified | directly-supported | not-required | 可发布 |
| 323 | pistia-stratiotes | 大薸 | verified | page-verified | directly-supported | not-required | 可发布 |
| 324 | potamogeton-crispus | 菹草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 325 | sagittaria-sagittifolia | 欧洲慈姑 | verified | page-verified | directly-supported | not-required | 可发布 |
| 326 | schoenoplectus-tabernaemontani | 水葱 | verified | page-verified | supplemental-translation-review (2) | verified | 可发布 |
| 327 | schoenoplectus-triqueter | 三棱水葱 | verified | page-verified | directly-supported | not-required | 可发布 |
| 328 | spirodela-polyrhiza | 紫萍 | verified | page-verified | supplemental-translation-review (4) | verified | 可发布 |
| 329 | typha-angustifolia | 水烛 | verified | page-verified | directly-supported | not-required | 可发布 |
| 330 | vallisneria-natans | 苦草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 331 | tradescantia-spathacea | 紫背万年青 | verified | page-verified | directly-supported | not-required | 可发布 |
| 332 | alocasia-odora | 海芋 | verified | page-verified | directly-supported | not-required | 可发布 |
| 333 | aloe-vera | 芦荟 | verified | page-verified | directly-supported | not-required | 可发布 |
| 334 | anthurium-andraeanum | 花烛 | verified | page-verified | directly-supported | not-required | 可发布 |
| 335 | araucaria-heterophylla | 异叶南洋杉 | verified | page-verified | directly-supported | not-required | 可发布 |
| 336 | asparagus-setaceus | 文竹 | verified | page-verified | directly-supported | not-required | 可发布 |
| 337 | ficus-lyrata | 大琴叶榕 | verified | page-verified | supplemental-translation-review (4) | verified | 可发布 |
| 338 | goeppertia-makoyana | 孔雀竹芋 | verified | page-verified | directly-supported | not-required | 可发布 |
| 339 | chamaedorea-elegans | 袖珍椰子 | verified | page-verified | directly-supported | not-required | 可发布 |
| 340 | codiaeum-variegatum | 变叶木 | verified | page-verified | directly-supported | not-required | 可发布 |
| 341 | cordyline-fruticosa | 朱蕉 | verified | page-verified | directly-supported | not-required | 可发布 |
| 342 | crassula-ovata | 燕子掌 | verified | page-verified | directly-supported | not-required | 可发布 |
| 343 | dieffenbachia-seguine | 黛粉芋 | verified | page-verified | supplemental-translation-review (2) | verified | 可发布 |
| 344 | dracaena-fragrans | 香龙血树 | verified | page-verified | supplemental-translation-review (8) | verified | 可发布 |
| 345 | euphorbia-milii | 铁海棠 | verified | page-verified | directly-supported | not-required | 可发布 |
| 346 | ficus-benjamina | 垂叶榕 | verified | page-verified | directly-supported | not-required | 可发布 |
| 347 | fittonia-albivenis | 网纹草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 348 | haworthiopsis-attenuata | 渐狭十二卷 | verified | page-verified | supplemental-translation-review (8) | verified | 可发布 |
| 349 | hoya-carnosa | 球兰 | verified | page-verified | directly-supported | not-required | 可发布 |
| 350 | kalanchoe-blossfeldiana | 长寿花 | verified | page-verified | directly-supported | not-required | 可发布 |
| 351 | maranta-leuconeura | 豹斑竹芋 | verified | page-verified | supplemental-translation-review (6) | verified | 可发布 |
| 352 | nephrolepis-exaltata | 高大肾蕨 | verified | page-verified | supplemental-translation-review (4) | verified | 可发布 |
| 353 | peperomia-obtusifolia | 圆叶椒草 | verified | page-verified | supplemental-translation-review (5) | verified | 可发布 |
| 354 | philodendron-hederaceum | 心叶蔓绿绒 | verified | page-verified | directly-supported | not-required | 可发布 |
| 355 | pilea-cadierei | 花叶冷水花 | verified | page-verified | directly-supported | not-required | 可发布 |
| 356 | polyscias-fruticosa | 南洋参 | verified | page-verified | supplemental-translation-review (9) | verified | 可发布 |
| 357 | rhapis-excelsa | 棕竹 | verified | page-verified | directly-supported | not-required | 可发布 |
| 358 | heptapleurum-arboricola | 鹅掌藤 | verified | page-verified | directly-supported | not-required | 可发布 |
| 359 | schlumbergera-truncata | 蟹爪兰 | verified | page-verified | supplemental-translation-review (8) | verified | 可发布 |
| 360 | pilea-peperomioides | 镜面草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 361 | syngonium-podophyllum | 合果芋 | verified | page-verified | supplemental-translation-review (9) | verified | 可发布 |
| 362 | tradescantia-zebrina | 吊竹梅 | verified | page-verified | supplemental-translation-review (4) | verified | 可发布 |
| 363 | yucca-gigantea | 象腿丝兰 | verified | page-verified | supplemental-translation-review (8) | verified | 可发布 |
| 364 | zamioculcas-zamiifolia | 雪铁芋 | verified | page-verified | directly-supported | not-required | 可发布 |
| 365 | strelitzia-reginae | 鹤望兰 | verified | page-verified | directly-supported | not-required | 可发布 |
| 366 | ainsliaea-fragrans | 杏香兔儿风 | verified | page-verified | directly-supported | not-required | 可发布 |
| 367 | ardisia-japonica | 紫金牛 | verified | page-verified | directly-supported | not-required | 可发布 |
| 368 | arisaema-erubescens | 一把伞南星 | verified | page-verified | directly-supported | not-required | 可发布 |
| 369 | asarum-sieboldii | 汉城细辛 | verified | page-verified | directly-supported | not-required | 可发布 |
| 370 | begonia-grandis | 秋海棠 | verified | page-verified | directly-supported | not-required | 可发布 |
| 371 | boehmeria-nivea | 苎麻 | verified | page-verified | directly-supported | not-required | 可发布 |
| 372 | callicarpa-bodinieri | 紫珠 | verified | page-verified | directly-supported | not-required | 可发布 |
| 373 | carex-siderosticta | 宽叶薹草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 374 | chloranthus-serratus | 及己 | verified | page-verified | directly-supported | not-required | 可发布 |
| 375 | cornus-kousa | 日本四照花 | verified | page-verified | directly-supported | not-required | 可发布 |
| 376 | corylus-heterophylla | 榛 | verified | page-verified | directly-supported | not-required | 可发布 |
| 377 | disporum-sessile | 宝铎草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 378 | epimedium-brevicornu | 淫羊藿 | verified | page-verified | directly-supported | not-required | 可发布 |
| 379 | farfugium-japonicum | 大吴风草 | verified | page-verified | directly-supported | not-required | 可发布 |
| 380 | glechoma-longituba | 活血丹 | verified | page-verified | directly-supported | not-required | 可发布 |
| 381 | corydalis-incisa | 刻叶紫堇 | verified | page-verified | directly-supported | not-required | 可发布 |
| 382 | liriope-spicata | 山麦冬 | verified | page-verified | directly-supported | not-required | 可发布 |
| 383 | lysimachia-christinae | 过路黄 | verified | page-verified | directly-supported | not-required | 可发布 |
| 384 | maianthemum-japonicum | 鹿药 | verified | page-verified | directly-supported | not-required | 可发布 |
| 385 | paris-polyphylla | 七叶一枝花 | verified | page-verified | directly-supported | not-required | 可发布 |
| 386 | polygonatum-odoratum | 玉竹 | verified | page-verified | directly-supported | not-required | 可发布 |
| 387 | polygonatum-sibiricum | 黄精 | verified | page-verified | directly-supported | not-required | 可发布 |
| 388 | rehmannia-glutinosa | 地黄 | verified | page-verified | directly-supported | not-required | 可发布 |
| 389 | rubus-corchorifolius | 山莓 | verified | page-verified | directly-supported | not-required | 可发布 |
| 390 | smilax-china | 菝葜 | verified | page-verified | directly-supported | not-required | 可发布 |
| 391 | bryum-argenteum | 真藓 | verified | page-verified | supplemental-translation-review (7) | verified | 可发布 |
| 392 | funaria-hygrometrica | 葫芦藓 | verified | page-verified | supplemental-translation-review (7) | verified | 可发布 |
| 393 | hypnum-cupressiforme | 灰藓 | verified | page-verified | supplemental-translation-review (7) | verified | 可发布 |
| 394 | marchantia-polymorpha | 地钱 | verified | page-verified | supplemental-translation-review (7) | verified | 可发布 |
| 395 | plagiomnium-cuspidatum | 匐灯藓 | verified | page-verified | supplemental-translation-review (7) | verified | 可发布 |
| 396 | polytrichum-commune | 金发藓 | verified | page-verified | supplemental-translation-review (7) | verified | 可发布 |
| 397 | niphotrichum-canescens | 长齿藓 | verified | page-verified | supplemental-translation-review (7) | verified | 可发布 |
| 398 | rhodobryum-roseum | 大叶藓 | verified | page-verified | supplemental-translation-review (7) | verified | 可发布 |
| 399 | thuidium-delicatulum | 细枝羽藓 | verified | page-verified | supplemental-translation-review (7) | verified | 可发布 |
| 400 | tortula-muralis | 泛生墙藓 | verified | page-verified | supplemental-translation-review (5) | verified | 可发布 |

## 汇总清单

- 可以继续发布的物种：全部500种
- 必须退回needs_review的物种：无
- 重复或疑似重复物种：无
- 来源无法验证的物种：无
- API内部字段泄漏：审核全部500种的公开白名单；自动化路由测试另行作为最终门禁执行。
- 百度识别调用：未调用；本审核只核验本地人工名称映射，不消耗识别额度。

