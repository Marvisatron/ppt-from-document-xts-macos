---
name: ppt-from-document-xts-macos
description: >-
  macOS 特供版全自动文档→PPT 生成器。通过 Antigravity CLI (agy) 直接调用 Gemini 生成配图，
  结合 AppleScript 实现文件管理、系统通知与图像处理，再通过 OfficeCLI 直接生成原生 .pptx 文件。
  Use when user says "根据文档生成PPT", "用这份文档做PPT", "document to PPT", "macOS PPT",
  "文档转PPT Mac版", "ppt from document mac", or provides a document file and asks for PPT with Mac automation.
---

# PPT from Document — macOS 特供版

> 全自动文档→PPT 工作流，macOS 独占特性：
> - **Antigravity CLI (`agy`)** 直接调用 Gemini 图片生成，命令行一键完成
> - **AppleScript** 深度集成：系统通知、文件管理、图像预处理、用户对话框
> - 复用 **OfficeCLI** 原生 PPTX 构建管线 + XTS 字体放大规则

## 前置依赖检查

| # | 依赖 | 必要性 | 检查方式 | 安装方式 |
|---|------|--------|---------|---------|
| 1 | **macOS** | **必须** | 自动检测 | 本 skill 仅支持 macOS |
| 2 | **OfficeCLI** | **必须** | `officecli --version` | `curl -fsSL https://d.officecli.ai/install.sh \| sh` |
| 3 | **agy CLI** | **必须**（配图自动化） | `agy --version` | `brew install antigravity-cli` |
| 4 | **agy 登录** | **必须**（配图自动化） | `agy -p "hello" --print-timeout 15s` | 运行 `agy` 交互式完成 Google OAuth 登录 |
| 5 | **AppleScript 权限** | **必须** | 首次运行时系统弹窗授权 | 见 §D.3 macOS 权限配置 |

### 检查流程

```bash
# 1. 确认 macOS
[[ "$(uname)" == "Darwin" ]] && echo "✅ macOS" || echo "❌ 非 macOS，本 skill 不可用"

# 2. 确认 OfficeCLI
officecli --version && echo "✅ OfficeCLI" || echo "❌ 请安装 OfficeCLI"

# 3. 确认 agy CLI
agy --version && echo "✅ agy CLI" || echo "❌ 请执行: brew install antigravity-cli"

# 4. 确认 agy 登录状态
agy -p "hello" --print-timeout 15s 2>/dev/null && echo "✅ agy 已登录" || echo "⚠️ 请运行 agy 交互式登录"

# 5. 确认 AppleScript
osascript -e 'display notification "✅ AppleScript OK" with title "PPT macOS Skill"' 2>/dev/null && echo "✅ AppleScript" || echo "❌ AppleScript 不可用"
```

**OfficeCLI 缺失 → 阻塞**，输出安装命令后暂停。
**agy CLI 缺失 → 阻塞**，输出 `brew install antigravity-cli`。
**agy 未登录 → 阻塞**，提示用户运行 `agy` 完成 Google OAuth 登录。
**其余 → 继续**，但提醒用户开通权限。

### AutoMode 权限预置（agy CLI 专用）

> agy CLI 使用 `--dangerously-skip-permissions` 参数自动跳过交互式权限确认。
> 无需额外配置 `.claude/settings.local.json`，在命令中直接使用该参数即可。

**使用方式**：所有 `agy -p` 命令都带上 `--dangerously-skip-permissions`。

```bash
agy -p "generate image..." --add-dir /path/to/output --dangerously-skip-permissions --print-timeout 180s
```

---

## 触发条件

用户说以下任意一句话时激活：
- `根据文档生成PPT` / `用这份文档做PPT` / `文档转PPT`
- `from document to PPT` / `make a PPT from this file`
- `macOS PPT` / `文档转PPT Mac版` / `ppt from document mac`
- 提供文档文件并说 `生成演示文稿` / `做PPT`

## 全局规则

1. **全自动执行**：用户只需提供文档和确认 Eight Confirmations，其余全自动（包括图片生成！）
2. **串行管道**：Step 必须按顺序执行，前一步的输出是后一步的输入
3. **字体放大规则**：所有幻灯片字号使用 §字体规则 中的 XTS 放大值
4. **图片策略**：**网络搜图优先** → agy CLI AI 生成兜底。能用真实图片的绝不 AI 生成；emoji/图标类优先从 Unsplash/Wikimedia 等搜真实素材，搜不到再用 agy 生成
5. **实时预览**：使用 `officecli watch` 提供浏览器内实时预览
6. **macOS 原生体验**：AppleScript 通知贯穿全流程，关键节点弹窗确认
7. **双模式执行**：本 skill 支持两种执行模式：
   - **Linear 模式**（默认，< 6 张配图时自动选择）：串行执行 Step 3→4→5，适合简单场景
   - **Workflow 模式**（≥ 6 张配图时推荐）：使用 Workflow 工具并行生成图片、串行构建幻灯片、并行质检，节省 50–70% 时间
8. **Workflow 模式要求**：需设置 `CLAUDE_CODE_WORKFLOWS=1`，通过 `/workflows` 命令可监控和管理执行进度
9. **动画与切换**：所有幻灯片必须有切换动画（默认 fade），内容形状按类型自动添加入场动画。学术场景以微妙动画为主，禁止浮夸效果。详见 §动画与切换规则。

---

## 管道总览

### Linear 模式（串行 — 默认）

```
Step 1: 源文档处理
  ↓
Step 2: Strategist 设计（Eight Confirmations）
  ↓
Step 3: agy CLI 自动化配图（Antigravity CLI → Gemini）
  ↓
Step 4: OfficeCLI 构建 PPTX（含 XTS 字体规则）
  ↓
Step 5: 质检与预览
  ↓
Step 6: 交付
```

### Workflow 模式（并行 — ≥6 张图片时推荐）

```
Step 1: 源文档处理
  ↓
Step 2: Strategist 设计（Eight Confirmations）
  ↓
Step 2d: 选择 Workflow 模式 → 生成 workflow script
  ↓
┌──────────────────────────────────────────────────┐
│         Workflow 工具（后台并行执行）               │
│                                                  │
│  Phase 1: 图片并行生成 — N 个 agent 并行            │
│    agy CLI → Gemini，每张图片独立 agent              │
│                                                  │
│  Phase 2: 幻灯片串行构建 — 单个 agent                │
│    OfficeCLI 逐页构建，batch 模式高效处理             │
│                                                  │
│  Phase 3: 质检并行 — 3 个 agent 并行                │
│    OOXML 验证 + 问题检查 + 预览截图                   │
└──────────────────────────────────────────────────┘
  ↓
Step 6: 交付
```

---

## Step 1: 源文档处理

读取用户提供的文档。OfficeCLI 可以直接读取 .docx：

```bash
officecli view <file.docx> text        # 提取纯文本
officecli view <file.docx> outline     # 提取结构大纲
```

| 格式 | 处理方式 |
|------|---------|
| .md / .txt | 直接 Read 读取 |
| .docx | `officecli view` 提取文本和结构 |
| .pdf | macOS 自带 `textutil` 转换：`textutil -convert txt file.pdf` |
| URL | 用 WebFetch 提取内容 |
| .pages | `textutil -convert txt file.pages` |

将提取的文本保存为 `source.md`，作为后续步骤的输入。

### macOS 增强：文件选择对话框

如果用户未指定文件，使用 AppleScript 弹出文件选择窗口：

```applescript
set theFile to choose file of type {"public.plain-text", "com.microsoft.word.doc", "org.openxmlformats.wordprocessingml.document", "com.adobe.pdf"} with prompt "选择要生成 PPT 的文档："
return POSIX path of theFile
```

```bash
osascript scripts/choose-file.applescript
```

---

## Step 2: Strategist 设计阶段

> 需要用户确认

### 2a. 分析源文档

读取 `source.md`，提取：
- 主题、章节结构、核心论点
- 表格、数据、关键术语
- 适合的页数估算

### 2b. Eight Confirmations

通过 AppleScript 对话框逐项确认（或直接在对话中输出）：

1. **画布格式** — 推荐 16:9（OfficeCLI 默认 33.87cm × 19.05cm）
2. **页数范围** — 根据文档内容估算
3. **目标受众与场景** — 学术/商业/科普
4. **风格定位** — 简洁科技 / 商务专业 / 创意活泼
5. **配色方案** — 主色 + 强调色 + 背景色 + 文字色（HEX）
6. **图标方案** — OfficeCLI 内置形状预设（roundRect / ellipse / arrow 等）
7. **排版方案** — 标题字体 + 正文字体 + 字号映射（使用 §字体规则）
   - macOS 默认使用 **PingFang SC**（苹方），系统原生字体，渲染清晰
   - 如需兼容 Windows 显示，可选 **Heiti SC**（黑体-简，两平台均内置）
8. **图片方案** — 按优先级选择（网络搜图优先！）：
   - **网络搜图**（最优先）：从 Unsplash / Wikimedia / Openverse 搜索真实图片，适合 emoji 替代、场景配图、数据插图
   - **agy CLI → Gemini**（AI 生成兜底）：搜不到的抽象背景、章节分隔页等用 AI 生成
   - **Gemini API**：如果用户有 `GEMINI_API_KEY`，通过 curl 直接调用 API
   - **手动外部工具**：用户自行在 DALL·E / Midjourney / Gemini 等工具中生成
   - **纯排版**：仅使用 OfficeCLI 内置形状，不使用外部图片

### 2c. 输出设计规范

用户确认后，记录以下设计参数（用于 Step 3-4 执行）：

```
CANVAS: 33.87cm x 19.05cm (16:9)
COLORS: primary=#1A3A5C, accent=#0099CC, bg=#F7F8FA, text=#2D3436
FONTS: heading="PingFang SC", body="PingFang SC", en="Arial"
SLIDES: [封面, 目录, Ch1..., Ch2..., ...]
IMAGES: [cover_bg.png, diagram1.png, ...]
```

### macOS：AppleScript 确认对话框

```applescript
display dialog "确认以下设计方案？\n\n画布：16:9 (33.87cm×19.05cm)\n页数：约 12 页\n风格：商务专业\n配色：#1A3A5C + #0099CC" \
    buttons {"修改", "确认"} default button "确认" with title "PPT 设计方案确认" with icon note
```

### 2d. 选择执行模式

用户确认设计后，根据 **图片数量** 自动推荐执行模式：

| 条件 | 推荐模式 | 理由 |
|------|---------|------|
| 图片数 < 6 张 | **Linear 模式** | 图片少，并行优势不明显，串行更简单可靠 |
| 图片数 ≥ 6 张 | **Workflow 模式** | 多图片可并行生成，节省 50-70% 总时间 |
| 用户明确要求并行 | **Workflow 模式** | 尊重用户选择 |
| 用户明确要求串行 | **Linear 模式** | 尊重用户选择 |

**询问用户确认**，记录所选模式后，输出完整的 design spec JSON（供后续执行使用）：

```json
{
  "outputDir": "<output_dir>",
  "pptxPath": "<output_dir>/presentation.pptx",
  "imagesDir": "<output_dir>/images/",
  "colors": { "primary": "#...", "accent": "#...", "bg": "#...", "text": "#..." },
  "fonts": { "heading": "...", "body": "...", "en": "..." },
  "canvas": { "width": "33.87cm", "height": "19.05cm" },
  "images": [
    { "filename": "cover_bg.png", "prompt": "...", "type": "cover", "minWidth": 1920, "minHeight": 1080 },
    ...
  ],
  "slides": [
    { "index": 1, "type": "cover", "background": "#...", "shapes": [...] },
    ...
  ],
  "retryFailedImages": true
}
```

**如果选择 Linear 模式** → 继续执行下方 Step 3→4→5。
**如果选择 Workflow 模式** → 跳转到 [Workflow 模式执行路径](#workflow-模式执行路径)，跳过 Linear 模式的 Step 3-5。

---

## Linear 模式执行路径

> 以下 Step 3–5 为 **Linear 模式**（串行执行）使用。
> 如果用户选择了 Workflow 模式，跳过此部分，直接跳转到 [Workflow 模式执行路径](#workflow-模式执行路径)。

## Step 3: agy CLI 自动化配图

> 本 step 使用 **Antigravity CLI (`agy`)** 直接从命令行生成配图。
> agy 是 Google 官方的 AI Agent CLI，内置 Gemini 图片生成能力。
> 相比 Safari MCP 浏览器操控方案：无 DOM 依赖、无标签页管理、无上下文污染问题，可靠性大幅提升。

### 3.0 前置条件

**安装 agy CLI**（一次性）：

```bash
brew install antigravity-cli
```

**登录**（一次性）：
```bash
# 交互式登录，使用 Google 账号完成 OAuth 认证
agy
# 凭据保存在 ~/.gemini/oauth_creds.json
```

**验证认证状态**：
```bash
agy -p "say hello" --print-timeout 15s
# 正常返回文本响应即表示认证成功
```

> ⚠️ 如果凭据过期，重新运行 `agy` 交互式登录即可刷新。agy 复用 `~/.gemini/` 下的 OAuth 凭据。

### 3.1 图片获取优先级：网络搜图 → AI 生成

> ⛔ **铁律：能用真实图片的绝不 AI 生成。**
> 尤其 emoji 替代图、场景配图、数据插图、概念示意图——优先从免费图库搜索真实素材。
> AI 生成仅限于抽象背景、章节分隔页等无真实素材可用的场景。

**判定逻辑**：

```
每张需要的图片：
  ├─ 是抽象背景/分隔页背景？
  │   └─ YES → 进入 §3.3-3.5 用 agy AI 生成（无真实素材可用）
  │
  ├─ 是 emoji 替代 / 场景配图 / 概念插图？
  │   └─ YES → 先执行 §3.1.1 网络搜图
  │       ├─ 搜到合适的 → 下载使用 ✅
  │       └─ 搜不到 → 进入 §3.3-3.5 用 agy AI 生成
  │
  └─ 不确定？
      └─ 先搜图（5 分钟），搜不到再 AI 生成
```

#### 3.1.1 网络搜图流程

**Step 1: 搜索**

使用 WebSearch 工具搜索免费图库：

```
搜索词模板: "site:unsplash.com OR site:wikimedia.org OR site:openverse.org [关键词] [风格]"
示例: "site:unsplash.com logistics warehouse RFID technology"
```

**免费图库源**（按优先级）：

| 来源 | 特点 | 搜索方式 |
|------|------|---------|
| **Unsplash** | 高质量摄影，免费商用 | `site:unsplash.com [keyword]` |
| **Wikimedia Commons** | 百科式图库，PD/CC 许可 | `site:commons.wikimedia.org [keyword]` |
| **Openverse** | CC 许可聚合搜索 | `site:openverse.org [keyword]` |
| **Pexels** | 免费 stock 图片 | `site:pexels.com [keyword]` |
| **Pixabay** | 免费图片+插画 | `site:pixabay.com [keyword]` |

**Step 2: 下载**

```bash
# 直接 curl 下载（Unsplash 等通常允许直链）
curl -L -o <output_dir>/images/<filename>.jpg "<image_direct_url>"

# 验证下载成功
sips -g pixelWidth -g pixelHeight <output_dir>/images/<filename>.jpg
```

**Step 3: 判断是否可用**

| 条件 | 判定 |
|------|------|
| 图片尺寸 ≥ 800×600 | ✅ 可用 |
| 图片内容与主题相关 | ✅ 可用 |
| 图片尺寸 < 800×600 | ❌ 不可用，进入 AI 生成 |
| 无水印、无版权顾虑 | ✅ 可用（Unsplash/Wikimedia 天然满足） |
| 搜了 3 分钟没找到合适的 | ❌ 放弃搜索，进入 AI 生成 |

**Step 4: 后处理**

```bash
# 统一转 PNG（PPT 最佳兼容格式）
sips -s format png image.jpg --out image.png 2>/dev/null
```

### 3.2 图片路径初始化

```bash
mkdir -p <output_dir>/images
```

### 3.3 提示词生成规则

根据 Step 2 的设计规范，为每张**需要 AI 生成**的图片准备提示词。网络搜图获得的图片跳过此步。

**agy 提示词格式**（自然语言驱动）：
- agy 是 AI Agent，提示词必须是**完整的自然语言指令**
- 格式：`Generate an image: [详细图片描述]. Save the image to [精确路径].`
- 必须同时包含"生成什么"和"保存到哪里"

**提示词示例**：
```
Generate an image: A professional presentation cover background with abstract geometric shapes in coral orange (#E8614D) and cyan (#00B4D8) tones, minimalist style, 16:9 widescreen aspect ratio, clean composition with ample negative space on the right side for text overlay, no text or letters. Save the image to /path/to/output/images/cover_bg.png.
```

**重要约束**：
- 必须说明宽高比（16:9 for widescreen PPT slides）
- 明确指定绝对路径输出文件
- 使用 `--add-dir` 将输出目录加入 agy 工作空间
- 全页背景图：`"no text, no letters, no words"`（纯背景，文字由 PPT 叠加）

### 3.4 单张图片 AI 生成命令

```bash
agy -p "Generate an image: [prompt]. Save the image to [output_dir]/images/[filename].png." \
    --add-dir [output_dir] \
    --dangerously-skip-permissions \
    --print-timeout 180s
```

**参数说明**：

| 参数 | 说明 |
|------|------|
| `-p` / `--print` | 非交互模式，执行单次 prompt 并打印响应后退出 |
| `--add-dir <dir>` | 将目录添加到 agy 工作空间，允许 agy 在该目录中创建/写入文件 |
| `--dangerously-skip-permissions` | 自动批准所有工具权限请求（自动化必需，无此参数 agy 会弹出交互式确认） |
| `--print-timeout 180s` | 超时等待时间（默认 5 分钟，图片生成建议 3 分钟） |

### 3.5 批量 AI 生成循环

```bash
#!/bin/bash
# 批量生成 PPT 配图 via agy CLI
OUTPUT_DIR="<output_dir>/images"
mkdir -p "$OUTPUT_DIR"

SUCCESS=0
FAILED=()

generate_image() {
  local filename="$1"
  local prompt="$2"
  
  echo "🎨 正在生成: $filename"
  
  if agy -p "$prompt" \
      --add-dir "$OUTPUT_DIR" \
      --dangerously-skip-permissions \
      --print-timeout 180s 2>&1; then
    
    if [ -f "$OUTPUT_DIR/$filename" ]; then
      width=$(sips -g pixelWidth "$OUTPUT_DIR/$filename" 2>/dev/null | tail -1 | awk '{print $2}')
      height=$(sips -g pixelHeight "$OUTPUT_DIR/$filename" 2>/dev/null | tail -1 | awk '{print $2}')
      echo "  ✅ 成功: ${width}x${height}"
      return 0
    else
      echo "  ⚠️ agy 返回成功但文件不存在: $filename"
      return 1
    fi
  else
    echo "  ❌ 生成失败: $filename"
    return 1
  fi
}

# 逐张生成（agy 不支持并发）
generate_image "cover_bg.png" \
  "Generate an image: [封面背景提示词]. Save the image to $OUTPUT_DIR/cover_bg.png." \
  && ((SUCCESS++)) || FAILED+=("cover_bg.png")

generate_image "section_01.png" \
  "Generate an image: [章节背景提示词]. Save the image to $OUTPUT_DIR/section_01.png." \
  && ((SUCCESS++)) || FAILED+=("section_01.png")

# ... 更多图片 ...

echo "---"
echo "完成: $SUCCESS 张成功"
[ ${#FAILED[@]} -gt 0 ] && echo "失败: ${FAILED[*]}"
```

### 3.6 错误处理与重试

| 问题 | 处理方式 |
|------|---------|
| agy 未安装 | 提示 `brew install antigravity-cli` |
| agy 未登录 | 提示运行 `agy` 交互式登录，完成后继续 |
| 单张超时 (>180s) | agy 自动退出，重试 1 次（调整 prompt 增加 "high quality, detailed" 修饰） |
| 图片文件未生成 | 检查 agy 输出日志，改用绝对路径重试 |
| 图片尺寸不足 (<800×600) | sips 验证后标记，自动重试 1 次 |
| 连续 3 张失败 | 暂停，AppleScript 通知用户选择：继续重试 / 跳过剩余 / 切换手动模式 |
| 全部失败 | 回退到 §3.8 备用方案 |

### 3.7 图片后处理

```bash
# 统一格式为 PNG
sips -s format png image.jpg --out image.png 2>/dev/null

# 批量验证分辨率（PPT 全页图片至少 1920×1080）
for img in <output_dir>/images/*.png; do
  width=$(sips -g pixelWidth "$img" 2>/dev/null | tail -1 | awk '{print $2}')
  height=$(sips -g pixelHeight "$img" 2>/dev/null | tail -1 | awk '{print $2}')
  if [ "$width" -lt 800 ] || [ "$height" -lt 600 ]; then
    echo "⚠️ $img 分辨率过低 (${width}x${height})，需重新生成"
  else
    echo "✅ $img (${width}x${height})"
  fi
done
```

### 3.8 备用图片路径

如果 agy CLI 完全不可用，提供以下回退方案（按优先级）：

- **路径 A**：用户手动在 Gemini / DALL·E / Midjourney 中生成，放入 `<output_dir>/images/`
- **路径 B**：网络搜图（通过 Openverse / Unsplash / Wikimedia）
- **路径 C**：纯排版 PPT（仅 OfficeCLI 内置形状，无外部图片）

### 3.9 进度追踪

在生成过程中，使用 AppleScript 展示实时进度：

```applescript
display notification "正在生成图片 3/8：封面背景图..." with title "PPT macOS Skill" subtitle "agy CLI → Gemini"
```

---

## Step 4: OfficeCLI 构建 PPTX（核心执行层）

> 本步骤与原版 ppt-from-document-xts 相同，图片路径使用 Step 3 生成的本地文件。

### ⚠️ OfficeCLI 已知踩坑（必读）

> 以下问题在实际执行中反复出现，在 Skill 中预先文档化可节省大量调试时间。

| # | 问题 | 现象 | 正确做法 |
|---|------|------|---------|
| 1 | `officecli create` 创建 0 张 slide | 预期有 1 张默认页，实际为空 | slide 编号从 0 开始，或先 `add` 第一张 slide 再操作 |
| 2 | `officecli set / --prop background=...` 失败 | presentation 级别无 background 属性 | **必须在每张 slide 上单独设置** background，不能在根路径 `/` 设置 |
| 3 | `bash set -e` + OfficeCLI 非零退出码 | OfficeCLI 某些命令返回非零但实际成功（如 set 无匹配时），`set -e` 导致整个脚本静默退出 | **禁止在 OfficeCLI 脚本中使用 `set -e`**，改用 `|| true` 容错 |
| 4 | `declare -A` 关联数组 | macOS 默认 bash 3.x 不完全支持 bash 4 的关联数组语法 | 避免使用 `declare -A`，改用普通数组或字符串拼接 |
| 5 | Workflow 脚本中 `${}` 冲突 | agent prompt 里的 bash `${VAR}` 被 JS 模板解析器当作 JS 插值 | **先用 Write 工具写 .sh 脚本到文件，再让 agent 执行脚本文件** |

### 脚本容错模板（Workflow 模式专用）

> 当通过 Workflow agent 执行 OfficeCLI 命令时，**必须**使用以下模板：

```bash
#!/bin/bash
# PPT 构建脚本 — 由 Workflow agent 生成并执行
# ⚠️ 禁止 set -e（OfficeCLI 某些命令返回非零但并非致命错误）
# ⚠️ 禁止 declare -A（macOS bash 3.x 不兼容）
# ✅ 每条 OfficeCLI 命令后跟 || true 容错

PPTX="<output_dir>/presentation.pptx"

# 创建文件
officecli create "$PPTX" || true

# ⚠️ 不能在根路径设置背景！必须在每张 slide 上设置
# 错误: officecli set "$PPTX" / --prop background=#F7F8FA
# 正确: 在 add slide 时指定 background

# 构建 slide 1
officecli add "$PPTX" / --type slide --prop layout=blank --prop background=#F7F8FA || true
officecli add "$PPTX" '/slide[0]' --type shape \
  --prop text="封面标题" \
  --prop x=3cm --prop y=6cm --prop width=27cm --prop height=3cm \
  --prop font="PingFang SC" --prop size=48 --prop bold=true \
  --prop color=#FFFFFF --prop align=center || true

# ... 后续 slides ...

# 验证产出
echo "--- 验证 ---"
officecli view "$PPTX" stats 2>/dev/null || echo "⚠️ 无法读取 stats"
EXPECTED_SLIDES=<预期页数>
ACTUAL_SLIDES=$(officecli view "$PPTX" stats 2>/dev/null | grep -o '[0-9]* slide' | grep -o '[0-9]*' || echo "0")
if [ "$ACTUAL_SLIDES" -lt "$EXPECTED_SLIDES" ]; then
  echo "❌ 产出不足：预期 $EXPECTED_SLIDES 页，实际 $ACTUAL_SLIDES 页"
  exit 1
fi
echo "✅ 构建完成：$ACTUAL_SLIDES 页"
```

### Workflow 模式：Write 脚本 → agent 执行

> ⛔ **禁止**在 Workflow agent 的 prompt 中直接嵌入多行 bash 命令（`${}` 会被 JS 解析器吞掉）。
> **必须**先用 Write 工具将完整的 .sh 脚本写到文件，再让 agent 执行该文件。

**正确流程**：
1. 主 context 用 Write 工具生成 `<output_dir>/build.sh`（使用上述容错模板）
2. Workflow agent 的 prompt 只包含：`执行以下脚本并报告结果：bash <output_dir>/build.sh`
3. agent 执行脚本，捕获 stdout/stderr，验证产出

### 4.1 创建文件并启动预览

```bash
officecli create <output_dir>/presentation.pptx
officecli watch <output_dir>/presentation.pptx
```

`watch` 在 http://localhost:26315 启动实时预览。之后每执行一条 `add`/`set` 命令，浏览器自动刷新。

macOS 增强：使用 `open` 命令自动打开预览页面。

```bash
open http://localhost:26315
```

### 4.2 设置主题

> ⚠️ **不能**在根路径设置背景（`officecli set pptx.pptx / --prop background=...` 会失败）。
> 必须在每张 slide 的 `add` 命令中通过 `--prop background=` 设置。

```bash
# ❌ 错误（会报错）：
# officecli set presentation.pptx / --prop background=<bg_color>

# ✅ 正确（在每张 slide 创建时设置）：
# officecli add presentation.pptx / --type slide --prop layout=blank --prop background=<bg_color>
```

> 从 Step 4.3 开始，所有 `officecli add ... --type slide` 命令都**必须**包含 `--prop background=<bg_color>`。
> 如果省略，该 slide 会使用 OfficeCLI 默认背景（白色），与设计规范不符。

### 4.3 逐页构建

对每一页幻灯片，按以下模式操作：

**添加幻灯片**：
```bash
officecli add presentation.pptx / --type slide --prop layout=blank --prop background=<bg_color>
```

**添加标题**：
```bash
officecli add presentation.pptx '/slide[N]' --type shape \
  --prop text="标题文本" \
  --prop x=1.5cm --prop y=0.8cm --prop width=30cm --prop height=1.5cm \
  --prop font="PingFang SC" --prop size=32 --prop bold=true \
  --prop color=<primary_color>
```

**添加正文文本框**：
```bash
officecli add presentation.pptx '/slide[N]' --type shape \
  --prop text="正文内容" \
  --prop x=1.5cm --prop y=3cm --prop width=30cm --prop height=14cm \
  --prop font="PingFang SC" --prop size=18 --prop color=<text_color>
```

**添加表格**：
```bash
officecli add presentation.pptx '/slide[N]' --type table \
  --prop rows=5 --prop cols=4 \
  --prop x=1.5cm --prop y=3cm --prop width=30cm --prop height=13cm
# 填充表头
officecli set presentation.pptx '/slide[N]/table[1]/row[1]' \
  --prop "c1=列1标题" --prop "c2=列2标题" --prop "c3=列3标题" --prop "c4=列4标题" \
  --prop bold=true --prop fill=<primary_color> --prop color=FFFFFF
# 填充数据行（逐行）
officecli set presentation.pptx '/slide[N]/table[1]/row[2]' \
  --prop "c1=数据1" --prop "c2=数据2" --prop "c3=数据3" --prop "c4=数据4" \
  --prop size=14
```

**添加图片**（使用 Step 3 自动生成的图片）：
```bash
officecli add presentation.pptx '/slide[N]' --type picture \
  --prop src=<output_dir>/images/filename.png \
  --prop x=5cm --prop y=4cm --prop width=20cm --prop height=11cm \
  --prop fillmode=contain
```

**添加装饰形状**（色块、分隔线、卡片背景）：
```bash
officecli add presentation.pptx '/slide[N]' --type shape \
  --prop preset=roundRect \
  --prop x=1.5cm --prop y=3cm --prop width=30cm --prop height=14cm \
  --prop fill=F5F7FA --prop line=none \
  --prop text="卡片内容" --prop font="PingFang SC" --prop size=18
```

**添加章节分隔页**：
```bash
officecli add presentation.pptx / --type slide --prop background=<primary_color>
officecli add presentation.pptx '/slide[N]' --type shape \
  --prop text="章节标题" \
  --prop x=3cm --prop y=7cm --prop width=27cm --prop height=3cm \
  --prop font="PingFang SC" --prop size=44 --prop bold=true --prop color=FFFFFF \
  --prop align=center
```

**添加演讲者备注**：
```bash
officecli add presentation.pptx '/slide[N]' --type notes \
  --prop text="备注内容..."
```

### 4.4 批量模式（高效）

对于内容密集的幻灯片，使用 batch 命令一次执行多个操作：

```bash
echo '[
  {"command":"add","path":"/slide[N]","type":"shape","props":{"text":"要点1","x":"2cm","y":"4cm","width":"14cm","height":"2cm","font":"PingFang SC","size":18,"color":"#2D3436"}},
  {"command":"add","path":"/slide[N]","type":"shape","props":{"text":"要点2","x":"2cm","y":"7cm","width":"14cm","height":"2cm","font":"PingFang SC","size":18,"color":"#2D3436"}}
]' | officecli batch presentation.pptx --json
```

### §字体规则（XTS 定制 — 最高优先级）

> 这是从实际项目中校准的规则。OfficeCLI 使用 **pt（磅）** 为单位。

**字号映射表**（直接使用放大后的 pt 值）：

| 角色 | XTS 字号 (pt) | OfficeCLI 属性 |
|------|--------------|---------------|
| 页脚、页码 | **11pt** | `--prop size=11` |
| 表格内容、注释 | **12–13pt** | `--prop size=12` 或 `--prop size=13` |
| 正文、卡片内容 | **16–18pt** | `--prop size=16` ~ `--prop size=18` |
| 小标题、强调文字 | **18–20pt** | `--prop size=18` ~ `--prop size=20` |
| 节标题 | **22–24pt** | `--prop size=22` ~ `--prop size=24` |
| 卡片标题 | **26–30pt** | `--prop size=26` ~ `--prop size=30` |
| 页面主标题 | **32–38pt** | `--prop size=32` ~ `--prop size=38` |
| 封面大标题 | **46–54pt** | `--prop size=46` ~ `--prop size=54` |
| 超大标题 | **54–58pt** | `--prop size=54` ~ `--prop size=58` |

> ⚠️ 正文从 14-16pt 提升至 16-18pt。各层级相应放大，确保正文可读性。
> **底线：绝不允许字体重叠。** 字号放大后必须重新计算所有 y 坐标，宁可有留白也不能叠。

**防重叠规则**（强制！）：

1. **表格行高**：每行至少分配字号 × 2.5 的高度（例：16pt 字体 → 行高 ≥ 1.0cm）
2. **文本框不溢出**：框内文字行数 × 字号 × 1.5 < 框高度
3. **卡片底部安全距离**：最后一行文字距卡片底部 ≥ 1cm
4. **行间距**：相邻文本的 y 间距 ≥ 上方字号的 1.6 倍
5. **表格列宽**：中文字符数 × 字号 × 0.33mm ≤ 列宽的 85%（PingFang SC 字形略窄于雅黑，系数从 0.35 调至 0.33）

**色块背景规则**（强制！）：

> ⛔ 每当使用有色形状（roundRect 等）作为文本背景时，色块尺寸**必须大于**文本框。
> 色块与文本框共用相同 x/y/width/height 是**最常见导致视觉不适的原因**——文字贴边甚至溢出。

6. **色块 padding**：色块四边各比文本框大 ≥ 0.4cm
   - 文本框 x=2.0cm, y=4.0cm, width=14cm, height=8cm
   - 对应色块 x=1.6cm, y=3.6cm, width=14.8cm, height=8.8cm
7. **色块先于文本**：脚本中色块必须在文本框之前 add，确保 z-order 正确（色块在底层）
8. **色块圆角**：使用 `--prop preset=roundRect` 时圆角半径自动适配，无需手动设置

**正文放大检查清单**（每页执行）：

> ⛔ 正文放大到 16-18pt 后，必须逐页验证以下条件，**任一不满足即调整**：

- [ ] 每行文字不超出文本框 width（中文约 2.5 字符/cm @ 16pt，PingFang SC）
- [ ] 文本框 height ≥ 文字行数 × 字号(pt) × 0.05cm × 1.5
- [ ] 相邻 shape 的 y 间距 ≥ 0.4cm
- [ ] 页面底部最后一个 shape 的 (y + height) ≤ 18.55cm

**y 坐标自动计算规则**（避免手工算重叠）：

> 构建幻灯片时，不要手工猜测 y 坐标。使用以下公式自动计算每个元素的 y 位置：

```
页面顶部留白: 0.8cm
页面底部留白: 0.5cm
可用高度: 19.05cm - 0.8cm - 0.5cm = 17.75cm

规则：
1. 标题 y = 0.8cm，height = max(字号pt × 0.04cm, 1.5cm)
2. 标题下方第一个元素 y = 标题y + 标题height + 0.3cm（间距）
3. 后续元素 y = 上一个元素y + 上一个元素height + 0.3cm
4. 最后一个元素的 y + height ≤ 18.55cm（= 19.05cm - 0.5cm）

双栏布局：
  左栏: x=1.5cm,  width=14cm
  右栏: x=17cm,    width=14cm
  两栏 y 值相同

卡片布局（带背景色块）：
  ⚠️ 色块必须比内部文字大！遵循 §色块背景规则（padding ≥ 0.4cm）
  卡片背景: x=1.1cm, y=2.6cm, width=31.7cm, height=14.8cm（比文本框大 0.4cm 四边）
  卡片内标题: x=1.9cm, y=3.4cm, width=29.9cm（卡片背景 x + 0.8cm）
  卡片内正文: x=1.9cm, y=卡片内标题y + 卡片内标题height + 0.3cm, width=29.9cm

表格布局：
  表头行高: max(16pt × 0.04cm, 0.9cm) = 0.9cm
  数据行高: max(13pt × 0.04cm, 0.7cm) = 0.7cm
  表格总高度: 表头行高 + 数据行数 × 数据行高
  表格起始 y: 标题下方 0.5cm
```

> **在 Workflow 模式中**：将这些规则写入 build.sh 脚本的注释中，让 agent 在计算每个元素位置时参考。

### 4.5 OfficeCLI 内置设计规范（参考）

- 标题 ≥ 36pt（XTS 封面 44-52pt 已满足）
- 正文 ≥ 18pt（XTS 正文 14-16pt 略小，学术场景可接受；商业场景建议 18pt）
- 每张幻灯片最多 2 种字体
- 每张幻灯片 ≤ 1 个动画，≤ 600ms
- 标题下不加装饰线（AI 生成 PPT 的典型识别特征）
- 不同幻灯片之间变换布局（交替双栏、callout、网格、半出血）
- 画布尺寸：33.87cm × 19.05cm，边缘留白 ≥ 1.27cm，块间距 ≥ 0.76cm，≥ 20% 留白

### §动画与切换规则（XTS 定制 — 强制！）

> ⛔ **所有幻灯片必须有切换动画，所有内容形状必须有人入场动画。**
> 学术场景以微妙（subtle）动画为主，禁止浮夸效果（bounce、boomerang、credits 等）。

#### 切换动画（Slide Transition）

**每张 slide 必须设置 `--prop transition=`**，按 slide 类型选用：

| Slide 类型 | transition | 说明 |
|------------|-----------|------|
| 封面 (slide 1) | `fade` | 简洁淡入（~1000ms） |
| 目录 | `morph` | 平滑过渡 |
| 章节分隔页 | `push-right` | 方向感推进 |
| 正文内容页 | `fade-fast` | 快速淡入（~500ms，学术不拖沓） |
| 表格/数据页 | `fade-fast` | 不分散注意力 |
| 结论 | `morph` | 呼应开头 |
| 结尾致谢 | `fade` | 优雅收尾 |

**命令示例**：
```bash
# 正文内容页 —— 快速淡入（学术场景不拖沓）
officecli set "$PPTX" '/slide[5]' --prop transition=fade-fast || true

# 章节分隔页 —— 推进感
officecli set "$PPTX" '/slide[7]' --prop transition=push-right || true

# 封面 —— 简洁淡入
officecli set "$PPTX" '/slide[1]' --prop transition=fade || true

# 自动切页（演讲者模式，5 秒后自动切）
officecli set "$PPTX" '/slide[5]' --prop advanceTime=5000 || true
```

#### 形状入场动画（Shape Animation）

**每个文本/图片 shape 必须添加入场动画**。动画挂在 shape 上：

```
officecli add "$PPTX" '/slide[N]/shape[M]' --type animation --prop effect=... --prop class=entrance ...
```

**按内容类型选用动画**：

| 内容类型 | effect | trigger | duration | delay |
|---------|--------|---------|----------|-------|
| 页面主标题 | `fade` | `withPrevious` | 300 | 0 |
| 副标题/小标题 | `fade` | `afterPrevious` | 200 | 100 |
| 正文卡片（每个） | `fade` | `afterPrevious` | 200 | 75 |
| 图片 | `fade` | `withPrevious` | 300 | 0 |
| 表格 | `fade` | `afterPrevious` | 250 | 150 |
| 章节分隔页标题 | `fade` | `withPrevious` | 400 | 0 |
| 封面大标题 | `fade` | `withPrevious` | 500 | 0 |
| 封面副标题 | `fade` | `afterPrevious` | 300 | 150 |
| 装饰色块/分隔线 | `wipe` | `withPrevious` | 200 | 0 |
| 列表项（逐条） | `fade` | `afterPrevious` | 150 | 100 |

> ⚠️ 上述值为经验校准后的**快节奏学术默认值**。实际项目中发现：400-1000ms 的动画在逐页播放时显得拖沓。
> 学术场景动画应"观众刚察觉就已到位"——duration 以 200-300ms 为宜，delay 以 75-100ms 为宜。
> 封面可稍慢（500ms）以营造仪式感。

**禁止使用的动画效果**（学术场景不适用）：
- ❌ `bounce`, `boomerang`, `credits`, `pinwheel`, `spiralOut`
- ❌ `spin`, `growShrink`, `pulse`, `teeter`（太浮夸）
- ❌ `swivel`, `flip`（过度炫技）

**命令示例**：
```bash
# 标题 —— 随页面一起淡入（300ms，快速到位）
officecli add "$PPTX" '/slide[5]/shape[1]' --type animation \
  --prop effect=fade --prop class=entrance \
  --prop trigger=withPrevious --prop duration=300 || true

# 正文卡片 —— 标题之后逐个淡入（200ms + 75ms delay）
officecli add "$PPTX" '/slide[5]/shape[2]' --type animation \
  --prop effect=fade --prop class=entrance \
  --prop trigger=afterPrevious --prop duration=200 --prop delay=75 || true

# 图片 —— 随标题一起出现
officecli add "$PPTX" '/slide[5]/shape[5]' --type animation \
  --prop effect=fade --prop class=entrance \
  --prop trigger=withPrevious --prop duration=300 || true

# 装饰线 —— 擦除效果
officecli add "$PPTX" '/slide[1]/shape[3]' --type animation \
  --prop effect=wipe --prop class=entrance \
  --prop trigger=withPrevious --prop duration=200 --prop direction=right || true
```

#### 表格逐行出现（Build）

表格整体添加入场动画后，设置 `chartBuild`（也适用于 table）：

```bash
# 表格逐行出现（类似图表 build）
officecli add "$PPTX" '/slide[10]/table[1]' --type animation \
  --prop effect=fade --prop class=entrance \
  --prop trigger=onClick --prop duration=250 || true
```

#### 动画密度控制

| 约束 | 值 |
|------|-----|
| 单页最多动画数 | ≤ 6 个 shape 动画 |
| 单页总动画时长 | ≤ 3 秒（封面 ≤ 1.5 秒） |
| 最小 delay 间隔 | ≥ 50ms（快节奏，无感知卡顿） |
| 封面动画 | 仅标题+副标题+装饰线，≤ 3 个 |

#### 批量加速已有动画

> 实践表明：初版动画几乎一定偏慢。以下脚本可将全部动画 duration/delay **统一减半**：

```bash
#!/bin/bash
# 所有 slide 所有 shape 的动画 duration 和 delay 减半
PPTX="presentation.pptx"

for slide in $(seq 1 21); do
  for s in $(seq 1 30); do
    anim_info=$(officecli get "$PPTX" "/slide[$slide]/shape[$s]/animation[1]" 2>&1)
    if echo "$anim_info" | grep -q "effect="; then
      dur=$(echo "$anim_info" | grep -o "duration=[0-9]*" | grep -o "[0-9]*")
      delay=$(echo "$anim_info" | grep -o "delay=[0-9]*" | grep -o "[0-9]*")
      [ -n "$dur" ] && [ "$dur" -gt 20 ] && officecli set "$PPTX" "/slide[$slide]/shape[$s]/animation[1]" --prop "duration=$((dur / 2))" 2>/dev/null || true
      [ -n "$delay" ] && [ "$delay" -gt 10 ] && officecli set "$PPTX" "/slide[$slide]/shape[$s]/animation[1]" --prop "delay=$((delay / 2))" 2>/dev/null || true
    fi
  done
done

# 切换也加速：fade-slow → fade-fast
for s in $(seq 1 21); do
  speed=$(officecli get "$PPTX" "/slide[$s]" 2>&1 | grep -o "transitionSpeed=[a-z]*" | cut -d= -f2)
  trans=$(officecli get "$PPTX" "/slide[$s]" 2>&1 | grep -o "transition=[a-z-]*" | head -1 | cut -d= -f2)
  [ "$speed" = "slow" ] && officecli set "$PPTX" "/slide[$s]" --prop "transition=${trans}-fast" 2>/dev/null || true
done
```

**过渡速度对照**：

| token | 大约时长 | 适用 |
|-------|---------|------|
| `-fast` | ~500ms | 默认（学术场景） |
| 无后缀（med） | ~1000ms | 重要切换（章节分隔） |
| `-slow` | ~2000ms | 几乎不用（太拖沓） |

#### 构建脚本中的动画顺序

```
对每张 slide：
  1. 创建 slide（含 background）
  2. 添加所有 shape（色块 → 图片 → 文本，按 z-order）
  3. 设置 slide transition（officecli set /slide[N] --prop transition=...）
  4. 为每个 shape 添加 animation（按视觉出现顺序：标题 → 副标题 → 卡片1 → 卡片2 → ...）
```

> ⚠️ 动画必须在 shape 全部创建完毕后添加，因为 animation 挂在 `/slide[N]/shape[M]` 路径下。

---

## Step 5: 质检与预览

### 5.1 内置质检

```bash
officecli validate presentation.pptx        # OOXML schema 验证
officecli view presentation.pptx issues      # 格式化/内容/结构问题
officecli view presentation.pptx stats       # 幻灯片数 + 缺失 alt 文本统计
```

> **产出物验证**（重要！）：
> 检查 `stats` 输出中的幻灯片数量是否 ≥ 预期页数。
> 如果页数不足（如预期 12 页但实际只有 3 页），说明构建脚本中途失败。
> 这种情况下 `officecli validate` 可能仍然通过，但 PPTX 内容不完整。

### 5.2 视觉验证

```bash
officecli view presentation.pptx html -o preview.html     # 生成静态 HTML 预览
officecli view presentation.pptx screenshot -o preview.png # 逐页 PNG 截图
```

**macOS 增强：Safari 预览**

> `officecli view screenshot` 需要 headless browser（Chrome/Playwright），macOS 上可能不可用。
> 替代方案：使用 `officecli view html` 生成 HTML 预览，在 Safari 中打开查看。

```bash
# 生成 HTML 预览
officecli view presentation.pptx html -o <output_dir>/preview.html

# 在 Safari 中打开预览（macOS 原生）
open -a Safari <output_dir>/preview.html
```

**HTML 预览注意事项**：
- HTML 预览文件可能较大（含内联 CSS），Safari 渲染可能与 Keynote/PowerPoint 有差异
- 重点关注：文字是否溢出框外、图片是否正确显示、表格列宽是否合理
- 如果发现明显排版问题，使用 §5.3 的查找替换功能修复

**Quick Look 快速预览**（仅查看单页截图）：
```bash
qlmanage -p <output_dir>/preview-*.png 2>/dev/null
```

macOS 增强：直接用 `open` 打开 HTML 预览和截图：

```bash
open preview.html
open preview-*.png
```

或用 Quick Look 预览：

```bash
qlmanage -p preview.png 2>/dev/null
```

### 5.3 查找替换（修复问题）

如发现占位符文本或格式问题：

```bash
officecli set presentation.pptx / --prop find=draft --prop replace=final     # 全局替换
officecli set presentation.pptx '/slide[N]' --prop find=TODO --prop bold=true  # 格式化匹配文本
```

---

## Workflow 模式执行路径

> 当用户选择 Workflow 模式时，Step 3–5 通过 Workflow 工具在后台并行执行。
> 参考 `references/workflow-template.md` 了解完整的 workflow script 模板。

### W1. 生成 Workflow Script

基于 `references/workflow-template.md` 的固定模板，将设计参数注入生成 `.claude/workflows/ppt-macos-gen.js`：

1. **填充 `images[]`**：将每张图片的文件名、Gemini 提示词、类型、分辨率要求填入
2. **填充 `slides[]`**：将每页幻灯片的类型、背景、shapes 数组（含 OfficeCLI 属性和 XTS 字号）填入
3. **填充设计参数**：colors、fonts、canvas 直接复制
4. **保持模板其余部分不变**：编排逻辑（parallel / agent / retry）不需要修改

**生成后验证**：
- 检查 `export const meta` 是否为纯字面量（无变量、无函数调用）
- 检查 `images[]` 和 `slides[]` 数组是否完整
- 检查模板字符串 `${args.xxx}` 是否正确引用

### W2. 启动 Workflow

```bash
# 确保 Workflow 功能已启用
export CLAUDE_CODE_WORKFLOWS=1
```

然后通过 Workflow 工具启动：

```
Workflow({ scriptPath: '.claude/workflows/ppt-macos-gen.js' })
```

Workflow 工具会自动读取 script 中的 `meta.phases` 并显示实时进度树。

### W3. 监控执行

告知用户以下操作：
- 使用 **`/workflows`** 查看实时进度树（按 Phase 分组）
- **P** 键暂停/恢复 workflow
- **X** 键跳过某个 agent（如图片生成卡住）
- 失败的 agent 会自动重试 1 次

**各阶段预估耗时**：

| Phase | 内容 | 预估时间 |
|-------|------|---------|
| Phase 1 | 图片并行生成 | 2–4 分钟（取决于最慢的那张图） |
| Phase 2 | 幻灯片串行构建 | 1–3 分钟（取决于页数和复杂度） |
| Phase 3 | 并行质检 | 30–60 秒 |

### W4. Workflow 完成后的处理

Workflow 返回结果结构：

```json
{
  "status": "completed" | "completed_with_warnings",
  "outputPath": "/path/to/presentation.pptx",
  "outputDir": "/path/to/output/",
  "slideCount": 12,
  "imageCount": 8,
  "imageResults": [{ "success": true, "filename": "cover_bg.png", ... }],
  "qaResults": [
    { "checkType": "oooxml", "passed": true, "issues": [] },
    { "checkType": "issues", "passed": true, "issues": [] },
    { "checkType": "preview", "passed": true, "issues": [] }
  ],
  "failedImages": [],
  "buildResult": { "success": true, "slideCount": 12 }
}
```

**处理逻辑**：

| 结果 | 处理方式 |
|------|---------|
| `status: "completed"` | 直接跳到 Step 6 交付 |
| `failedImages.length <= 2` 且无非封面图 | 继续交付（纯排版回退缺失图片位置） |
| `failedImages.length > 2` | 询问用户：跳过/手动补充图片/重新生成 |
| `qaResults` 有警告 | 列出警告，继续交付；用户可选择修复 |
| `buildResult.success === false` | 检查错误信息，重试构建或回退到 Linear 模式 |

### W5. 手动回退

如果 Workflow 模式遇到无法恢复的错误（如 agy CLI 完全不可用），可以回退：

1. 停止当前 workflow
2. 使用 Step 3.6 的备用图片路径（手动图片、网络搜图、纯排版）
3. 按 Linear 模式执行 Step 4–5

---

## Step 6: 交付

1. 停止预览：`officecli unwatch presentation.pptx`
2. 将 `.pptx` 复制到用户指定位置（默认与源文档同目录）

### macOS 增强：AppleScript 交付通知

```applescript
display dialog "✅ PPT 生成完成！\n\n文件：" & outputPath & "\n页数：" & slideCount & "\n图片：" & imageCount & " 张\n\n是否在 Finder 中打开？" \
    buttons {"关闭", "在 Finder 中打开"} default button "在 Finder 中打开" with title "PPT macOS Skill" with icon note

-- 在 Finder 中定位文件
tell application "Finder"
    reveal POSIX file outputPath as alias
    activate
end tell
```

### 输出统计摘要

```
✅ PPT 生成完成！（macOS 特供版）
文件：<路径>/presentation.pptx
页数：N 页
配色：<primary> + <accent>
字体：<heading_font> / <body_font>
图片：M 张（agy CLI → Gemini 自动生成）
🖥 macOS 独占：AppleScript 通知 + agy CLI 自动化配图
```

---

## 附录 A：工具链一览

| 环节 | 工具 | 说明 |
|------|------|------|
| 文档读取 | OfficeCLI `view` / Read / `textutil` | .docx/.md/.pdf/.pages 全格式支持 |
| 设计规范 | Strategist Eight Confirmations | 参考 PPT Master |
| AI 生图 | **agy CLI → Google Gemini** | 🆕 macOS 独有：命令行一键生成，无需浏览器 |
| 图像后处理 | `sips` | 🆕 macOS 独有：格式转换、尺寸验证 |
| 系统通知 | AppleScript `display notification` | 🆕 macOS 独有：全流程实时通知 |
| 文件对话框 | AppleScript `choose file/folder` | 🆕 macOS 独有：原生文件选择体验 |
| PPTX 构建 | **OfficeCLI** `create` + `add` + `set` | 直接生成原生 DrawingML PPTX |
| 实时预览 | **OfficeCLI** `watch` | 浏览器内 HTML 渲染，自动刷新 |
| 质量检查 | **OfficeCLI** `validate` + `view issues` | OOXML 验证 + 问题枚举 |
| 视觉验证 | **OfficeCLI** `view screenshot` | 逐页 PNG 截图 |

## 附录 B：输出物清单

生成完成后，输出目录中应有：
- `presentation.pptx` — 原生可编辑 PPTX（主输出）
- `images/` — agy CLI → Gemini 自动生成的配图
- `source.md` — 源文档文本副本
- `prompts.md` — 所有图片生成提示词记录（便于复现）

## 附录 C：与原版对比

| 维度 | 原版（ppt-from-document-xts） | macOS 特供版 |
|------|---------------------------|-------------|
| 图片生成 | 手动外部工具（用户复制提示词） | **全自动** agy CLI → Gemini |
| 用户交互 | 对话中确认 | 对话 + **AppleScript 原生对话框** |
| 进度通知 | 对话文字 | **系统通知横幅** |
| 文件管理 | 手动 | AppleScript + **Finder 集成** |
| 图像处理 | 无 | `sips` 自动验证 + 格式转换 |
| 预览 | 浏览器 | 浏览器 + **Quick Look** + Finder 定位 |
| 平台 | 跨平台 | **macOS 独占** |
| 依赖 | OfficeCLI | OfficeCLI + agy CLI + AppleScript |

## 附录 D：agy CLI 配置指南

### D.1 安装

```bash
brew install antigravity-cli
# 安装后二进制文件位于 /opt/homebrew/bin/agy
```

验证安装：
```bash
agy --version
# 输出示例: 1.0.7
```

### D.2 登录认证

```bash
# 交互式登录（一次性），使用 Google 账号完成 OAuth
agy
# 凭据保存在 ~/.gemini/oauth_creds.json
```

验证登录：
```bash
agy -p "say hello" --print-timeout 15s
# 正常返回文本响应即表示认证成功
```

**凭据管理**：
- 凭据文件：`~/.gemini/oauth_creds.json`（与旧 Gemini CLI 共享）
- 凭据过期后重新运行 `agy` 交互式登录即可刷新
- 无需在 Claude Code 的 settings.json 中额外配置 MCP

### D.3 macOS 权限配置清单

- [ ] **AppleScript 权限**：System Settings → Privacy & Security → Automation → 允许终端/Claude
- [ ] **辅助功能权限**（可选）：System Settings → Privacy & Security → Accessibility → 允许终端/Claude

> agy CLI 本身不需要 macOS 特殊权限。以上权限仅用于 AppleScript 通知和 Finder 集成。

### D.4 常用命令

```bash
# 列出可用模型
agy models

# 非交互模式执行单次 prompt（图片生成核心用法）
agy -p "Generate an image: [描述]. Save to /path/to/file.png." \
    --add-dir /path/to/output \
    --dangerously-skip-permissions \
    --print-timeout 180s

# 继续上次对话
agy --continue

# 指定模型
agy -p "..." --model gemini-3.1-flash-image

# 查看帮助
agy --help
```

### D.5 常见问题

| 问题 | 解决方案 |
|------|---------|
| `agy: command not found` | 执行 `brew install antigravity-cli` |
| `Please sign in` | 运行 `agy` 交互式登录 |
| 图片未保存到指定路径 | 确认 `--add-dir` 参数包含目标目录，且 prompt 中使用了**绝对路径** |
| 生成超时 | 增大 `--print-timeout`（如 300s）；或检查网络连接 |
| OAuth 凭据过期 | 运行 `agy` 重新登录 |

## 附录 E：AppleScript 实用脚本库

### E.1 系统通知

```applescript
-- scripts/notify.applescript
on run argv
    set theTitle to item 1 of argv
    set theMessage to item 2 of argv
    display notification theMessage with title theTitle sound name "Glass"
end run
```

使用：
```bash
osascript scripts/notify.applescript "PPT macOS Skill" "图片生成完成 3/8"
```

### E.2 文件选择对话框

```applescript
-- scripts/choose-file.applescript
set theFile to choose file of type {"public.plain-text", "com.microsoft.word.doc", "org.openxmlformats.wordprocessingml.document", "com.adobe.pdf"} with prompt "选择要生成 PPT 的文档："
return POSIX path of theFile
```

### E.3 文件夹选择对话框

```applescript
-- scripts/choose-folder.applescript
set theFolder to choose folder with prompt "选择 PPT 输出目录："
return POSIX path of theFolder
```

### E.4 确认对话框

```applescript
-- scripts/confirm.applescript
on run argv
    set theMessage to item 1 of argv
    display dialog theMessage buttons {"取消", "确认"} default button "确认" with title "PPT macOS Skill" with icon note
    return button returned of result
end run
```

### E.5 在 Finder 中显示文件

```applescript
-- scripts/reveal-in-finder.applescript
on run argv
    set thePath to item 1 of argv
    tell application "Finder"
        reveal POSIX file thePath as alias
        activate
    end tell
end run
```

### E.6 图片信息获取

```bash
# scripts/image-info.sh
#!/bin/bash
# 获取图片尺寸和格式
sips -g pixelWidth -g pixelHeight -g format "$1"
```

### E.7 图片格式转换

```bash
# scripts/convert-image.sh
#!/bin/bash
# 将图片转为 PNG（PPT 最佳兼容格式）
sips -s format png "$1" --out "${1%.*}.png" 2>/dev/null
```

### E.8 批量图片下载后处理

```bash
# scripts/postprocess-images.sh
#!/bin/bash
# 批量验证和修正图片
IMAGES_DIR="$1"
for img in "$IMAGES_DIR"/*.{png,jpg,jpeg,webp}; do
    [ -f "$img" ] || continue
    # 转为 PNG
    sips -s format png "$img" --out "${img%.*}.png" 2>/dev/null
    # 验证最小分辨率
    width=$(sips -g pixelWidth "$img" 2>/dev/null | tail -1 | awk '{print $2}')
    height=$(sips -g pixelHeight "$img" 2>/dev/null | tail -1 | awk '{print $2}')
    if [ "$width" -lt 800 ] || [ "$height" -lt 600 ]; then
        echo "⚠️ $img 分辨率过低 (${width}x${height})"
    else
        echo "✅ $img (${width}x${height})"
    fi
done
```

---

## 附录 F：Gemini 图片生成提示词模板

### F.1 PPT 封面背景

```
A professional presentation cover background with abstract geometric shapes in {primary_color} and {accent_color} tones, minimalist corporate style, 16:9 widescreen aspect ratio, clean composition with ample negative space on the left side for text overlay, no text or letters, premium quality
```

### F.2 章节分隔页

```
Abstract gradient background with flowing curves, color palette: {primary_color} to {accent_color}, dark moody atmosphere, modern tech style, 16:9 widescreen, smooth gradient transitions, suitable for section divider slide, no text
```

### F.3 概念图示

```
Professional diagram-style illustration explaining {concept}, clean flat design, {primary_color} and white color scheme, isometric or flat 2D style, with simple geometric icons representing key elements, 16:9 widescreen, minimal text labels only, clear visual hierarchy
```

### F.4 数据可视化背景

```
Abstract data visualization background with subtle grid patterns and glowing data points, {accent_color} highlights on dark {primary_color} background, futuristic but professional, 16:9 widescreen, suitable for charts and data slides, no text
```

### F.5 团队/人物占位图

```
Professional abstract illustration representing teamwork and collaboration, diverse abstract human silhouettes in {accent_color}, clean modern style, light {bg_color} background, 16:9 widescreen, minimal and elegant, no text
```

---

## 附录 G：内存 / 记忆集成

此 skill 集成了以下持久化记忆中的规则：
- `ppt-master-font-requirements` — 字号缩放映射 + 防重叠规则（已适配 pt 单位）
- XTS 字体放大规则来自原版 ppt-from-document-xts skill
