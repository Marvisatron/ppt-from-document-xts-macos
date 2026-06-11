# Workflow Script Template — ppt-macos-gen

> 本文件是主 context 生成 `.claude/workflows/ppt-macos-gen.js` 时的模板参考。
> 模板分为两部分：**固定部分**（编排逻辑，不可修改）和 **可变部分**（slides[] / images[] / 设计参数，从 design spec 注入）。

## args 结构定义

```json
{
  "outputDir": "/path/to/output/",
  "pptxPath": "/path/to/output/presentation.pptx",
  "imagesDir": "/path/to/output/images/",
  "colors": {
    "primary": "#1A3A5C",
    "accent": "#0099CC",
    "bg": "#F7F8FA",
    "text": "#2D3436"
  },
  "fonts": {
    "heading": "PingFang SC",
    "body": "PingFang SC",
    "en": "Arial"
  },
  "canvas": {
    "width": "33.87cm",
    "height": "19.05cm"
  },
  "images": [
    {
      "filename": "cover_bg.png",
      "prompt": "A professional presentation cover background...",
      "type": "cover",
      "minWidth": 1920,
      "minHeight": 1080
    }
  ],
  "slides": [
    {
      "index": 1,
      "type": "cover",
      "background": "#1A3A5C",
      "shapes": [
        {
          "type": "shape",
          "text": "封面标题",
          "x": "3cm", "y": "6cm",
          "width": "27cm", "height": "3cm",
          "font": "PingFang SC", "size": 48,
          "bold": true, "color": "#FFFFFF",
          "align": "center"
        }
      ]
    }
  ],
  "retryFailedImages": true
}
```

## 图片类型清单

| type | 说明 | 典型尺寸要求 |
|------|------|-------------|
| `cover` | 封面背景图 | 1920×1080 |
| `section-bg` | 章节分隔页背景 | 1920×1080 |
| `diagram` | 概念图示/流程图 | 1600×900 |
| `data-viz` | 数据可视化配图 | 1600×900 |
| `icon` | 小图标/装饰元素 | 512×512 |
| `photo` | 照片/人物图 | 1024×768 |

## Slide 类型清单

| type | 说明 | 典型 shapes 组合 |
|------|------|-----------------|
| `cover` | 封面页 | 大标题 shape + 副标题 shape + 可选背景图 |
| `toc` | 目录页 | 多个卡片 shape（每项一个章节） |
| `section` | 章节分隔页 | 大号章节标题 shape + 背景色块 |
| `content` | 正文内容页 | 标题 shape + 正文 shape + 可选图片/形状 |
| `table` | 数据表格页 | 标题 shape + table 元素 |
| `ending` | 结束页 | 感谢语 shape + 联系方式 |

## 生成规则（主 context 执行）

### 1. 从 design spec 构建 slides[]

对于每一页幻灯片：
- 为每个文本/形状元素创建一个 shape 对象
- 应用 XTS 字号规则（根据文本角色查表）
- 应用防重叠规则（计算 y 坐标确保不溢出）

### 2. 从 design spec 构建 images[]

对于每张需要的图片：
- 使用附录 F 的提示词模板生成 prompt
- 确定 type 和最小分辨率
- 命名规范化：`{序号}_{角色}.png`

### 3. 填充固定模板

将 slides[] 和 images[] 数组 JSON 填入模板的对应位置。
保持其余代码不变。

## 固定模板（直接嵌入生成的 .js 文件）

```javascript
export const meta = {
  name: 'ppt-macos-gen',
  description: 'PPT macOS 自动生成：并行图片生成 → 串行幻灯片构建 → 并行质检',
  whenToUse: '当 design_spec 确认完毕且用户选择 Workflow 模式时',
  phases: [
    { title: 'Phase 1: 图片生成', detail: 'Safari MCP → Gemini 并行生成所有配图' },
    { title: 'Phase 2: 幻灯片构建', detail: 'OfficeCLI 串行构建所有幻灯片' },
    { title: 'Phase 3: 质量检查', detail: '并行 OOXML 验证 + 问题检查 + 预览截图' },
  ],
}

// ── Schema 定义 ──

const IMAGE_RESULT_SCHEMA = {
  type: 'object',
  properties: {
    success: { type: 'boolean' },
    filename: { type: 'string' },
    outputPath: { type: 'string' },
    width: { type: 'number' },
    height: { type: 'number' },
    error: { type: 'string' },
  },
  required: ['success', 'filename'],
}

const QA_RESULT_SCHEMA = {
  type: 'object',
  properties: {
    checkType: { type: 'string' },
    passed: { type: 'boolean' },
    issues: { type: 'array', items: { type: 'string' } },
    stats: { type: 'object' },
  },
  required: ['checkType', 'passed'],
}

// ═══════════════════════════════════════════
// Phase 1: 并行生成所有图片
// ═══════════════════════════════════════════
phase('Phase 1: 图片生成')

// 确保输出目录存在
await agent(
  `确保以下目录存在：\nmkdir -p ${args.imagesDir}\nmkdir -p ${args.outputDir}\n\n使用 AppleScript 发送开始通知：\nosascript -e 'display notification "开始生成 ${args.images.length} 张配图..." with title "PPT macOS Workflow" sound name "Glass"'`,
  { label: 'init-dirs', phase: 'Phase 1: 图片生成' }
)

// 并行生成所有图片
const imgResults = await parallel(
  args.images.map((img, i) => () =>
    agent(
      `你正在为一份 PowerPoint 演示文稿生成配图。使用 Safari MCP 操控 Safari 浏览器访问 Google Gemini 生成图片。

## 图片信息
- **文件名**: ${img.filename}
- **目标目录**: ${args.imagesDir}
- **提示词**: "${img.prompt}"
- **最小分辨率**: ${img.minWidth}×${img.minHeight}px

## 操作流程

### 1. 打开新标签页并导航到 Gemini 图片生成
- 使用 safari_new_tab 打开空白新标签页
- 切换到新标签页
- 使用 safari_navigate 导航到 https://gemini.google.com/app/image
- 等待页面加载完成

### 2. 检查登录状态
- 使用 safari_evaluate 执行 JavaScript 检测登录状态
- 如果页面包含登录按钮或重定向到登录页面 → 返回 { success: false, filename: "${img.filename}", error: "Gemini 未登录，请先在 Safari 中登录 Google 账号" }

### 3. 输入提示词
- 使用 safari_snapshot 获取页面结构，定位输入框
- 输入框可能的选择器：div[contenteditable="true"], textarea, [role="textbox"], [aria-label*="prompt"]
- 使用 safari_fill 或 safari_type_text 输入图片生成提示词
- 提示词末尾必须包含宽高比要求（如 "16:9 aspect ratio"）

### 4. 提交并等待生成
- 使用 safari_snapshot 找到提交/发送按钮
- 使用 safari_click 点击提交
- 使用 safari_wait_for 等待图片元素出现，timeout 设置 120000ms
- 如果超时：等待额外 30 秒再检查一次，仍无图片则返回失败

### 5. 下载图片
- 使用 safari_evaluate 提取最新生成的图片 URL：
  \`\`\`javascript
  const imgs = document.querySelectorAll('img[src*="gemini.google.com"], img[src*="image"], img[loading="lazy"]');
  const latest = imgs[imgs.length - 1];
  return latest ? latest.src : null;
  \`\`\`
- 如果获取到 URL，使用 Bash 下载：
  curl -o "${args.imagesDir}/${img.filename}" "<extracted_url>"
- 如果 URL 提取失败，尝试右键保存方式

### 6. 验证图片
- 使用 Bash 验证：sips -g pixelWidth -g pixelHeight "${args.imagesDir}/${img.filename}"
- 如果图片宽度 < ${img.minWidth} 或高度 < ${img.minHeight}，标记为失败
- 如果文件大小 < 10KB，可能是下载失败，标记为失败

### 7. 清理
- 使用 safari_close_tab 关闭当前标签页

## 返回格式
返回 JSON 对象：{ success: boolean, filename: string, outputPath: string, width: number, height: number, error?: string }`,
      {
        label: `img:${img.filename}`,
        phase: 'Phase 1: 图片生成',
        schema: IMAGE_RESULT_SCHEMA,
        stallMs: 300000,
      }
    )
  )
)

// 汇总结果
const succeeded = imgResults.filter(r => r?.success)
const failed = imgResults.filter(r => !r?.success)
log(`图片生成：${succeeded.length}/${args.images.length} 成功，${failed.length} 失败`)

// 重试失败的图片（逐个重试，避免冲突）
let finalImageResults = [...succeeded]
if (failed.length > 0 && args.retryFailedImages !== false) {
  log(`正在重试 ${failed.length} 张失败的图片...`)

  for (const f of failed) {
    const imgDef = args.images.find(im => im.filename === f.filename)
    if (!imgDef) continue

    const retry = await agent(
      `重试生成图片（第 2/2 次）：
文件名: ${imgDef.filename}
目标目录: ${args.imagesDir}
提示词: "${imgDef.prompt}"
上次失败原因: ${f.error || '未知'}

请按照相同的 Safari MCP → Gemini 流程重新生成。如果这次也失败，返回 success: false。`,
      {
        label: `retry:${imgDef.filename}`,
        phase: 'Phase 1: 图片生成',
        schema: IMAGE_RESULT_SCHEMA,
        stallMs: 300000,
      }
    )
    finalImageResults.push(retry || f)
  }
}

// ═══════════════════════════════════════════
// Phase 2: 串行构建所有幻灯片
// ═══════════════════════════════════════════
phase('Phase 2: 幻灯片构建')

const buildResult = await agent(
  `你正在使用 OfficeCLI 构建 PowerPoint 演示文稿。设计规范如下。

## 全局参数
- **输出文件**: ${args.pptxPath}
- **图片目录**: ${args.imagesDir}
- **画布**: ${args.canvas.width} × ${args.canvas.height}

## 配色
- 主色 (primary): ${args.colors.primary}
- 强调色 (accent): ${args.colors.accent}
- 背景色 (bg): ${args.colors.bg}
- 文字色 (text): ${args.colors.text}

## 字体
- 标题: ${args.fonts.heading}
- 正文: ${args.fonts.body}
- 英文: ${args.fonts.en}

## XTS 字号映射表（最高优先级）
| 角色 | 字号 (pt) |
|------|----------|
| 页脚/页码 | 11pt |
| 表格内容/注释 | 12-13pt |
| 正文/卡片内容 | 14-16pt |
| 小标题/强调 | 16-18pt |
| 节标题 | 20-22pt |
| 卡片标题 | 24-28pt |
| 页面主标题 | 30-36pt |
| 封面大标题 | 44-52pt |
| 超大标题 | 52-56pt |

## 防重叠规则
1. 表格行高 ≥ 字号 × 2.5
2. 文本行数 × 字号 × 1.5 < 框高度
3. 最后一行文字距卡片底部 ≥ 1cm
4. 相邻文本 y 间距 ≥ 上方字号 × 1.6
5. 中文字符数 × 字号 × 0.35mm ≤ 列宽 × 85%

## 构建步骤

### 1. 创建文件并启动预览
\`\`\`bash
officecli create ${args.pptxPath}
officecli watch ${args.pptxPath}
open http://localhost:26315
\`\`\`

### 2. 逐页构建幻灯片

对于下面的每页幻灯片，按顺序执行 OfficeCLI 命令。
**多元素幻灯片使用 batch 模式**以提高效率。

\`\`\`bash
# 单个 shape 示例
officecli add ${args.pptxPath} '/slide[N]' --type shape \\
  --prop text="标题文本" --prop x=1.5cm --prop y=0.8cm \\
  --prop width=30cm --prop height=1.5cm \\
  --prop font="PingFang SC" --prop size=32 --prop bold=true \\
  --prop color=${args.colors.primary}

# batch 模式示例（多元素幻灯片推荐）
echo '[
  {"command":"add","path":"/slide[N]","type":"shape","props":{"text":"要点1","x":"2cm","y":"3cm","width":"14cm","height":"2cm","font":"PingFang SC","size":16,"color":"${args.colors.text}"}},
  {"command":"add","path":"/slide[N]","type":"shape","props":{"text":"要点2","x":"18cm","y":"3cm","width":"14cm","height":"2cm","font":"PingFang SC","size":16,"color":"${args.colors.text}"}}
]' | officecli batch ${args.pptxPath} --json
\`\`\`

### 3. 幻灯片列表

${JSON.stringify(args.slides, null, 2)}

### 4. 完成后 — 必须验证产出物！

⚠️ **不能只看 exit code！** Workflow agent 的"成功"判断只看 exit code，不验证产出物。
必须主动检查 PPTX 文件的实际页数。

\`\`\`bash
# 停止预览
officecli unwatch ${args.pptxPath} 2>/dev/null || true

# 验证产出物
officecli view ${args.pptxPath} stats 2>/dev/null || echo "⚠️ 无法读取 stats"

# 检查文件大小（太小说明构建失败）
FILESIZE=$(stat -f%z "${args.pptxPath}" 2>/dev/null || stat -c%s "${args.pptxPath}" 2>/dev/null || echo "0")
if [ "$FILESIZE" -lt 5000 ]; then
  echo "❌ PPTX 文件过小 (${FILESIZE} bytes)，构建可能失败"
  exit 1
fi

# 检查幻灯片数量
EXPECTED=${args.slides.length}
ACTUAL=$(officecli view ${args.pptxPath} stats 2>/dev/null | grep -o '[0-9]* slide' | grep -o '[0-9]*' || echo "0")
if [ "$ACTUAL" -lt "$EXPECTED" ]; then
  echo "❌ 产出不足：预期 $EXPECTED 页，实际 $ACTUAL 页"
  exit 1
fi
echo "✅ 构建完成：$ACTUAL 页, $FILESIZE bytes"
\`\`\`

返回 JSON: { success: boolean, slideCount: number, fileSize: number, error?: string }`,
  {
    label: 'build-slides',
    phase: 'Phase 2: 幻灯片构建',
    stallMs: 600000,
  }
)

// ═══════════════════════════════════════════
// Phase 3: 并行质量检查
// ═══════════════════════════════════════════
phase('Phase 3: 质量检查')

const qaResults = await parallel([
  // QA1: OOXML Schema 验证
  () => agent(
    `验证 PPTX 文件的 OOXML Schema 合规性。\n\n运行命令：\nofficecli validate ${args.pptxPath}\n\n返回 { checkType: "oooxml", passed: boolean, issues: string[] }`,
    {
      label: 'qa:validate',
      phase: 'Phase 3: 质量检查',
      schema: QA_RESULT_SCHEMA,
    }
  ),

  // QA2: 格式/内容问题检查
  () => agent(
    `检查 PPTX 文件的格式和内容问题。\n\n运行命令：\nofficecli view ${args.pptxPath} issues\nofficecli view ${args.pptxPath} stats\n\n返回 { checkType: "issues", passed: boolean, issues: string[], stats: object }`,
    {
      label: 'qa:issues',
      phase: 'Phase 3: 质量检查',
      schema: QA_RESULT_SCHEMA,
    }
  ),

  // QA3: 预览截图
  () => agent(
    `生成 PPTX 文件的预览截图和 HTML 预览。\n\n运行命令：\nofficecli view ${args.pptxPath} screenshot -o ${args.outputDir}/preview.png\nofficecli view ${args.pptxPath} html -o ${args.outputDir}/preview.html\nopen ${args.outputDir}/preview.html\n\n返回 { checkType: "preview", passed: true, issues: [] }`,
    {
      label: 'qa:preview',
      phase: 'Phase 3: 质量检查',
      schema: QA_RESULT_SCHEMA,
    }
  ),
])

// ═══════════════════════════════════════════
// 汇总返回
// ═══════════════════════════════════════════
const allQAPassed = qaResults.every(r => r?.passed)
const finalSuccessCount = finalImageResults.filter(r => r?.success).length

log(\`
=== PPT 生成完成 ===
图片: ${finalSuccessCount}/${args.images.length} 张生成成功
幻灯片: ${args.slides.length} 页构建完成
质检: ${qaResults.filter(r => r?.passed).length}/${qaResults.length} 项通过
\`)

// 发送 AppleScript 完成通知
await agent(
  `发送 macOS 系统通知：\nosascript -e 'display notification "图片: ${finalSuccessCount}/${args.images.length} | 幻灯片: ${args.slides.length} 页" with title "PPT 生成完成" sound name "Glass"'`,
  { label: 'notify-done', phase: 'Phase 3: 质量检查' }
)

return {
  status: allQAPassed ? 'completed' : 'completed_with_warnings',
  outputPath: args.pptxPath,
  outputDir: args.outputDir,
  slideCount: args.slides.length,
  imageCount: finalSuccessCount,
  imageResults: finalImageResults,
  qaResults: qaResults,
  failedImages: finalImageResults.filter(r => !r?.success).map(r => r?.filename),
  buildResult: buildResult,
}
```

## 生成注意事项

### 1. slides[] 的 JSON 嵌入
- 直接使用 `JSON.stringify(args.slides, null, 2)` 嵌入
- 保留完整的 shapes 数组（每个 shape 包含 OfficeCLI 所需的所有 props）
- 文本内容已截断到合理长度（避免 JS 文件过大）

### 2. images[] 的 JSON 嵌入
- prompt 长度可能很长，需要嵌入完整文本
- 如果 args 过大（接近 524KB），考虑拆分到多个 workflow 调用

### 3. 变量替换
- `${args.xxx}` 是 workflow 运行时的模板插值
- 需要在生成时确保 args 中的字符串不包含破坏模板的特殊字符

### 4. 错误处理
- 图片生成失败：自动重试 1 次，仍失败则在结果中标记
- 幻灯片构建失败：agent 返回 error 字段，主 context 检查
- QA 失败：不阻塞，在最终报告中列出所有问题
- Workflow 工具层面对 agent 失败的处理：agent 返回 null → 过滤掉 null 结果
