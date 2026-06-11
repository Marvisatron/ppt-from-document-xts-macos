# 完整工作流示例

> 以 "AI 在医疗领域的应用综述.md" 为例，演示端到端的 macOS 自动化 PPT 生成流程。

## 场景

- **源文件**: `~/Documents/AI在医疗领域的应用综述.md`
- **输出目录**: `~/Desktop/AI医疗PPT/`
- **目标**: 12 页商务专业风格 PPT，16:9 画布

## 执行日志

### Step 1: 源文档处理

```bash
# 读取 Markdown 文件
cp ~/Documents/AI在医疗领域的应用综述.md ~/Desktop/AI医疗PPT/source.md
```

输出：
```
✅ Step 1 完成：源文档已提取（~3500 字，5 个章节）
```

### Step 2: 设计阶段

用户确认的 Eight Confirmations：

| 项目 | 选择 |
|------|------|
| 画布 | 16:9 (33.87cm × 19.05cm) |
| 页数 | 12 页 |
| 受众 | 医疗行业从业者、投资人 |
| 风格 | 商务专业（深蓝 + 青蓝） |
| 配色 | primary=#1A3A5C, accent=#0099CC, bg=#F0F4F8, text=#2D3436 |
| 字体 | 标题=PingFang SC, 正文=PingFang SC, 英文=Arial |
| 图片 | Safari MCP → Gemini 自动生成（8 张） |

8 张图片需求：
```
1. cover_bg.png      — 封面背景（医疗+AI 科技感）
2. section1_bg.png   — AI医学影像章节分隔
3. diagram_ai_diag.png — AI诊断流程图
4. section2_bg.png   — 药物发现章节分隔
5. data_viz_bg.png   — 数据可视化背景
6. section3_bg.png   — 未来展望章节分隔
7. team_bg.png       — 团队/结论背景
8. ending_bg.png     — 结尾致谢背景
```

### Step 3: 自动化配图（Safari MCP → Gemini）

```bash
# 通知
osascript scripts/notify.applescript "PPT macOS Skill" "Step 3/6 开始配图生成 (8 张)"

# 逐张生成
for i in 1 2 3 4 5 6 7 8; do
    osascript scripts/notify.applescript "PPT macOS Skill" "生成图片 $i/8..."
    
    # Safari MCP 自动化 → 见 SKILL.md §3.2
    
    # 下载后处理
    sips -g pixelWidth ~/Downloads/generated-${i}.png
    mv ~/Downloads/generated-${i}.png ~/Desktop/AI医疗PPT/images/filename.png
done

osascript scripts/notify.applescript "PPT macOS Skill" "✅ 8/8 图片生成完成"

# 批量验证
bash scripts/postprocess-images.sh ~/Desktop/AI医疗PPT/images/
```

### Step 4: OfficeCLI 构建

```bash
officecli create ~/Desktop/AI医疗PPT/presentation.pptx
officecli watch ~/Desktop/AI医疗PPT/presentation.pptx
open http://localhost:26315

# 封面页
officecli add ~/Desktop/AI医疗PPT/presentation.pptx / --type slide --prop layout=blank --prop background=#1A3A5C
officecli add ~/Desktop/AI医疗PPT/presentation.pptx '/slide[1]' --type picture \
    --prop src=~/Desktop/AI医疗PPT/images/cover_bg.png \
    --prop x=0cm --prop y=0cm --prop width=33.87cm --prop height=19.05cm \
    --prop fillmode=cover
officecli add ~/Desktop/AI医疗PPT/presentation.pptx '/slide[1]' --type shape \
    --prop text="AI 在医疗领域的应用综述" \
    --prop x=3cm --prop y=6cm --prop width=27cm --prop height=4cm \
    --prop font="PingFang SC" --prop size=48 --prop bold=true --prop color=#FFFFFF

# 目录页
officecli add ~/Desktop/AI医疗PPT/presentation.pptx / --type slide --prop layout=blank --prop background=#F0F4F8
# ... 继续构建

# ... 其余 10 页

osascript scripts/notify.applescript "PPT macOS Skill" "Step 4/6 PPTX 构建完成 (12 页)"
```

### Step 5: 质量检查

```bash
officecli validate ~/Desktop/AI医疗PPT/presentation.pptx
officecli view ~/Desktop/AI医疗PPT/presentation.pptx issues
officecli view ~/Desktop/AI医疗PPT/presentation.pptx screenshot -o ~/Desktop/AI医疗PPT/preview.png
open ~/Desktop/AI医疗PPT/preview-*.png
```

### Step 6: 交付

```bash
officecli unwatch ~/Desktop/AI医疗PPT/presentation.pptx
osascript scripts/delivery-dialog.applescript "$HOME/Desktop/AI医疗PPT/presentation.pptx" "12" "8"
```

## 预期输出统计

```
✅ PPT 生成完成！（macOS 特供版）
文件：~/Desktop/AI医疗PPT/presentation.pptx
页数：12 页
配色：#1A3A5C + #0099CC
字体：PingFang SC / PingFang SC / Arial
图片：8 张（Safari MCP → Gemini 自动生成）
耗时：约 8 分钟（含 Gemini 图片生成时间）
🖥 macOS 独占：AppleScript 通知 × 12 + Finder 交付
```
