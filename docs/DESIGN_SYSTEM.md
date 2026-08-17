# 见野 V1：设计系统

> 实施注记（2026-08-16）：统一视觉已继续收口到 ArkUI Token、系统栏、轻量浮动底栏、图鉴首页、我的图鉴、发现/识别状态、详情与设置中心。页面完整度和功能状态以 [PROJECT_STATUS.md](PROJECT_STATUS.md) 为准。

## 视觉目标

见野是“随身携带的一座个人自然博物馆”，不是传统植物养护工具。当前 Token 将本项目设计文档中的纸张、档案标签、低饱和自然摄影与克制的编辑式排版落为 ArkUI 可复用配置。

视觉规则：彩色照片表达“遇见”；黑白照片只用于叶片、纹理、树皮、标本等“观察”。不使用大面积绿色、渐变、Material 风格的卡片堆叠或儿童科普插画。

实现文件位于 `entry/src/main/ets/constants/`。

## 色彩：AppColors

设置中心 V1.0.1 将 `AppColors` 改为集中运行时调色板：浅色保留纸张档案气质，深色使用深灰绿背景、克制表面层级和高对比文字。外观切换不会在业务页面散落深色条件；现有页面继续只消费 Token。

| Token | 值 | 用途 |
| --- | --- | --- |
| `BACKGROUND_PRIMARY` | `#F5F3EF` | 页面主背景，暖白纸张感；同时作为浅色启动页背景 |
| `BACKGROUND_SECONDARY` | `#EDF0E9` | 弱分区与次级表面 |
| `SURFACE_PRIMARY` | `#F6F7F2` | 搜索、图鉴列表等轻量表面 |
| `SURFACE_ELEVATED` | `#FCFCF8` | Hero 信息区与更高一级承载面 |
| `TEXT_PRIMARY` | `#1E251F` | 主要文字、主按钮 |
| `TEXT_SECONDARY` | `#697269` | 元信息、辅助文案 |
| `TEXT_TERTIARY` | `#969D95` | 地点等弱信息 |
| `BRAND_GREEN` | `#4F6955` | 克制的自然强调色，不可大面积铺陈 |
| `BRAND_GREEN_SOFT` | `#DDE8DB` | 非导航控件的局部强调与轻提示背景 |
| `EARTH` | `#8B7564` | 标本 / 土壤系细节 |
| `SKY` | `#C8D7D5` | 低饱和天空色细节 |
| `OBSERVATION` | `#59625A` | `OBS.0042` 等档案编号 |
| `BORDER_SOFT` | `#E0E4DC` | 章节和轻材质边缘 |
| `PHOTO_FALLBACK` | `#C9C8C0` | 图片尚未加载时的底色 |
| `SURFACE_TINT` / `BORDER_STRONG` | 浅色 `#E8EEEA` / `#DCE4DD` | 详情工具栏等轻交互表面与边界，深色自动适配 |
| `DANGER` | 浅色 `#A84C43` | 不可逆操作提示；深色自动提高对比度 |
| `PHOTO_OVERLAY` | `#66000000` | 照片内观察编号的半透明承载面 |
| `ACTION_PRIMARY` / `ACTION_ON_PRIMARY` | 浅色 `#1E251F` / `#FFFFFF` | 主 CTA 的成对前景/背景；深色使用浅苔表面与深色文字，避免复用正文色 |

## 字体：AppTypography

| 层级 | Token | 当前值 | 用途 |
| --- | --- | --- | --- |
| 展示标题 | `DISPLAY_FONT`, `HERO_SIZE` | serif, 40vp | 品牌区、页面宣言 |
| 页面标题 | `PAGE_TITLE_SIZE` | 29vp | 我的图鉴等页面层级 |
| 章节标题 | `SECTION_TITLE_SIZE` | 20vp | 编辑式段落标题 |
| 卡片标题 | `CARD_TITLE_SIZE` | 19vp | 物种中文名 |
| 正文 | `BODY_SIZE` | 15vp | 短段落、介绍文字 |
| 元信息 | `META_SIZE` | 12vp | 时间、地点、置信度、分类 |
| 档案编号 | `MONO_FONT` | monospace | `OBS.0001` 的科学观察感 |

字体在当前骨架中使用系统 serif / sans-serif / monospace，以确保无额外字体资产时可运行。品牌字库的授权、字体文件体积与 HarmonyOS 实机回退效果应在视觉验收阶段另行决定。

主页面标题统一由 `components/PageTitle.ets` 输出，三个主标题固定为“图鉴 / 发现 / 设置”，共用 `PAGE_TITLE_SIZE=29vp`、`PAGE_TITLE_WEIGHT=Bold`、`TEXT_PRIMARY`、`PAGE_HORIZONTAL=20vp`、`MAIN_TITLE_TOP_INSET=32vp` 和 `MAIN_TITLE_CONTENT_GAP=20vp`。设置详情页不复用主标题组件，使用 56vp 的紧凑 Header，并以 0.92～1.00 的小范围背景透明度变化响应滚动。

## 间距与尺寸

| Token | 值 | 用途 |
| --- | --- | --- |
| `AppSpacing.XXS / XS / SM / MD / LG / XL / XXL` | 4 / 8 / 12 / 16 / 24 / 32 / 48vp | 垂直节奏、内外边距 |
| `PAGE_HORIZONTAL` | 20vp | 手机页面统一水平留白 |
| `CONTENT_MAX_WIDTH` | 680vp | 平板与大屏的阅读宽度上限 |
| `BOTTOM_NAV_HEIGHT` | 60vp | 更薄的浮层导航高度 |
| `PRIMARY_TABS_CONTENT_INSET` | 120vp | 浮动 HdsTabs 下的滚动末端安全空间 |
| `RADIUS_SMALL / MEDIUM / LARGE / HERO` | 12 / 16 / 24 / 28vp | 图片、轻列表、Hero、底栏的层级差异 |
| `PHOTO_RATIO_PORTRAIT` | 4:5 | 主要自然摄影的推荐比例 |
| `PHOTO_RATIO_DETAIL` | 3:2 | 黑白科学观察图的推荐比例 |

页面可以为信息层级使用专有尺寸（如首页主摄影高度），但若该数值被两个以上页面复用，应先加入 `AppDimensions`，而不是复制 magic number。

## 组件规则

- `PhotoFrame`：摄影载体。彩色默认代表用户遇见；`observationMode` 为真时使用黑白观察图；允许将轻量 `ObservationCode` 叠加在角落。
- `ObservationCode`：只出现于照片角、详情顶栏或图鉴条目，作为档案细节而非主视觉。
- `SectionHeading`：以文字和细线组织长页面章节，避免用堆叠容器制造“卡片 Dashboard”。
- `HdsTabs`：始终为「图鉴 / 发现 / 设置」；使用系统 `SymbolGlyph`。选中态、选中图标和系统指示器使用项目原有绿色（浅色 `#2F8F5B`、深色 `#9BD4A5`），未选中态使用灰绿色（浅色 `#69756C`、深色 `#A5B0A7`）；不使用系统默认蓝色、PNG 图标或悬浮加号式 FAB。
- 可滚动容器：静态扫描到 7 个 `Scroll` 和 1 个 `List`，共 8 个容器，8/8 均使用 `.scrollBar(BarState.Off)`。图鉴首页、发现、设置首页和设置详情显式使用 `.edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })`；“我的图鉴”列表当前显式为 `EdgeEffect.None`，另外三个详情页未显式设置回弹，不能写成全局 8/8 均启用 Spring。
- 系统安全区：状态栏与手势导航区由窗口系统栏属性统一为 `BACKGROUND_PRIMARY`，并随浅深外观同步图标明暗；视觉连续，但交互内容仍避开系统指示器。
- 图标：正式应用图标为无白边的叶形路径，已移除拍摄取景角标；使用应用纸张色作为分层背景。
- 开屏：鸿蒙系统原生启动过渡保留，普通第三方应用不尝试禁用；当前 SDK 要求 `startWindowIcon` 字段，因此使用 1×1 透明资源，不使用正式 `layered_image`、foreground 或 background 作为启动图标。应用内只显示“见野 / 在城市里，遇见植物”文字，不使用路径或取景框图片层，约 390ms 淡出至首页。浅色启动页与首页统一为 `#F5F3EF`，深色统一为 `#151A18`。

## 页面应用

| 页面 | 核心视觉关系 |
| --- | --- |
| 发现 | 日期与一句引导 + 一张大幅彩色摄影 + 清晰拍照入口 |
| 识别结果 | “你遇见了”优先于算法术语；“收入我的图鉴”为主 CTA |
| 物种详情 | 长页面杂志阅读节奏；封面后先给出物种元信息与“我的相遇”摘要，再进入简介和相遇记录；首屏只保留透明悬浮返回键，不使用遮挡照片的整条顶栏 |
| 图鉴首页 | 一个封面式 Hero 相遇 + 最多两条紧凑记录 + 识别建议，形成图像主导而非卡片瀑布的节奏 |
| 我的图鉴 | 搜索 + 单一当前排序入口；使用官方菜单展开排序，彩色相遇照片、次数、首/最近相遇而非百科目录 |

## 禁止项

- 不复制 Material Design 组件组合或大面积圆角卡片。
- 不用满屏绿色、强渐变、卡通植物、儿童科普插画。
- 不把识别页写成工具仪表盘；“你遇见了”与收藏行为始终优先。
- 不在页面中直接散落重复色值、间距与圆角值；优先扩展现有 Token。

## 知识内容

物种详情的“我的相遇”仍先于知识内容。审核知识采用独立、克制的浅灰绿文字卡片：怎么认、下次这样确认、认识它、容易混淆、观察提醒。卡片使用 `BACKGROUND_SECONDARY`、`BORDER_SOFT`、16vp 圆角、16vp 内边距且无阴影；空字段和空章节均隐藏。不显示逐物种来源、永久识别百分比或“AI 判断依据”。
