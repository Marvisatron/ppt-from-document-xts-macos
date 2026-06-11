# AppleScript 集成指南

> 本文档描述如何在 PPT 生成工作流中有效使用 AppleScript。
> AppleScript 通过 `osascript` 命令行工具调用，无需编译。

## 设计原则

1. **每个 AppleScript 脚本应该只做一件事**，通过参数传递数据
2. **所有脚本位于 `scripts/` 目录**，可通过 `osascript <path>` 调用
3. **返回值通过 stdout 传递**，错误通过 stderr 传递
4. **用户可见的交互（对话框、通知）保留原始 AppleScript 体验**

## 可用的集成点

### 集成点 1: 工作流开始通知

```bash
osascript -e 'display notification "PPT 生成流水线启动" with title "PPT macOS Skill" sound name "Pop"'
```

### 集成点 2: 每阶段完成通知

```bash
# Step 1 完成
osascript scripts/notify.applescript "PPT macOS Skill" "Step 1/6 源文档处理完成"

# Step 2 确认
osascript scripts/notify.applescript "PPT macOS Skill" "设计规范已生成，请确认 Eight Confirmations"

# Step 3 图片生成进度
osascript scripts/notify.applescript "PPT macOS Skill" "Step 3/6 图片生成中... (3/8)"

# Step 4 构建
osascript scripts/notify.applescript "PPT macOS Skill" "Step 4/6 PPTX 构建完成"

# Step 5 QA
osascript scripts/notify.applescript "PPT macOS Skill" "Step 5/6 质检通过 ✅"

# Step 6 交付
osascript scripts/notify.applescript "PPT macOS Skill" "🎉 PPT 生成完成！"
```

### 集成点 3: 文件选择（未指定源文件时）

```bash
SOURCE_FILE=$(osascript scripts/choose-file.applescript)
if [ -z "$SOURCE_FILE" ]; then
    echo "用户取消了文件选择"
    exit 0
fi
echo "已选择文件: $SOURCE_FILE"
```

### 集成点 4: 输出目录选择

```bash
OUTPUT_DIR=$(osascript scripts/choose-folder.applescript)
```

### 集成点 5: 关键确认

```bash
# Eight Confirmations 确认
RESULT=$(osascript scripts/confirm.applescript "确认设计方案？页数：12，风格：商务专业，配色：#1A3A5C + #0099CC")
if [ "$RESULT" != "确认" ]; then
    echo "用户需要修改方案"
fi
```

### 集成点 6: 错误告警

```bash
osascript -e 'display dialog "图片生成失败（连续 3 次超时）\n\n请选择处理方式：" buttons {"跳过剩余图片", "切换手动模式", "重试"} default button "重试" with title "PPT macOS Skill" with icon stop'
```

### 集成点 7: 交付完成

```bash
osascript scripts/delivery-dialog.applescript "/path/to/presentation.pptx" "12" "8"
```

## 错误处理模式

```bash
#!/bin/bash
# 安全执行 AppleScript 的模式

run_applescript() {
    local script="$1"
    local output
    output=$(osascript "$script" 2>&1)
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        # 用户取消 (-128) 是正常的
        if [ $exit_code -eq 128 ] || [[ "$output" == *"User canceled"* ]]; then
            echo "⚠️  用户取消了操作"
            return 128
        fi
        echo "❌ AppleScript 执行失败 (exit=$exit_code): $output" >&2
        return $exit_code
    fi

    echo "$output"
    return 0
}
```

## 图片处理命令（sips，替代 AppleScript）

对于纯命令行图片处理，macOS 的 `sips` 命令比 AppleScript 的 Image Events 更快：

```bash
# 获取尺寸
sips -g pixelWidth -g pixelHeight image.png

# 缩放（限定最大尺寸）
sips -Z 1920 image.png

# 格式转换
sips -s format png image.jpg --out image.png

# 旋转
sips -r 90 image.png

# 裁剪（从左上角开始）
sips -c 1080 1920 image.png
```

## 完整集成示例

参见 `examples/workflow-example.sh`
