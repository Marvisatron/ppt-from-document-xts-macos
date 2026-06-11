#!/bin/bash
# convert-image.sh — 图片格式转换（转为 PNG，PPT 最佳兼容格式）
# 用法: ./convert-image.sh <input_image>
# 输出: 同目录下生成 .png 文件
# 依赖: macOS 自带 sips 命令

if [ $# -lt 1 ]; then
    echo "用法: $0 <input_image>"
    exit 1
fi

INPUT="$1"

if [ ! -f "$INPUT" ]; then
    echo "❌ 文件不存在: $INPUT"
    exit 1
fi

# 获取文件名（不含扩展名）
BASENAME="${INPUT%.*}"
OUTPUT="${BASENAME}.png"

# 获取原始格式
ORIGINAL_FORMAT=$(sips -g format "$INPUT" 2>/dev/null | tail -1 | awk '{print tolower($2)}')

echo "🔄 转换: $INPUT → $OUTPUT"
echo "   原始格式: $ORIGINAL_FORMAT"

if [ "$ORIGINAL_FORMAT" = "png" ]; then
    echo "✅ 已是 PNG 格式，跳过转换"
    exit 0
fi

# 执行转换
sips -s format png "$INPUT" --out "$OUTPUT" 2>/dev/null

if [ -f "$OUTPUT" ]; then
    NEW_SIZE=$(du -h "$OUTPUT" | awk '{print $1}')
    echo "✅ 转换完成: $OUTPUT ($NEW_SIZE)"
else
    echo "❌ 转换失败"
    exit 1
fi
