#!/bin/bash
# postprocess-images.sh — 批量图片后处理
# 用法: ./postprocess-images.sh <images_directory>
# 功能: 批量格式化、尺寸验证、生成报告
# 依赖: macOS 自带 sips 命令

set -e

if [ $# -lt 1 ]; then
    echo "用法: $0 <images_directory>"
    exit 1
fi

IMAGES_DIR="$1"

if [ ! -d "$IMAGES_DIR" ]; then
    echo "❌ 目录不存在: $IMAGES_DIR"
    exit 1
fi

echo "🔍 批量检查图片: $IMAGES_DIR"
echo "=============================="

TOTAL=0
OK=0
WARNINGS=0
ERRORS=0

for img in "$IMAGES_DIR"/*; do
    [ -f "$img" ] || continue

    # 跳过非图片文件
    mime_type=$(file --mime-type -b "$img" 2>/dev/null)
    if [[ ! "$mime_type" =~ ^image/ ]]; then
        continue
    fi

    TOTAL=$((TOTAL + 1))
    BASENAME=$(basename "$img")
    EXT="${BASENAME##*.}"

    # 非 PNG 格式 → 转换
    if [[ ! "$EXT" =~ ^(png|PNG)$ ]]; then
        echo "🔄 $BASENAME → 转为 PNG..."
        sips -s format png "$img" --out "${img%.*}.png" 2>/dev/null && \
            echo "   ✅ ${BASENAME%.*}.png" || \
            echo "   ❌ 转换失败"
    fi

    # 获取尺寸
    width=$(sips -g pixelWidth "$img" 2>/dev/null | tail -1 | awk '{print $2}')
    height=$(sips -g pixelHeight "$img" 2>/dev/null | tail -1 | awk '{print $2}')

    if [ -z "$width" ] || [ -z "$height" ]; then
        echo "❌ $BASENAME — 无法读取尺寸"
        ERRORS=$((ERRORS + 1))
        continue
    fi

    # 分辨率检查
    if [ "$width" -lt 800 ] || [ "$height" -lt 600 ]; then
        echo "⚠️  $BASENAME — 分辨率过低 (${width}×${height})"
        WARNINGS=$((WARNINGS + 1))
    elif [ "$width" -lt 1920 ] && [ "$height" -lt 1080 ]; then
        echo "ℹ️  $BASENAME — ${width}×${height}（非全页分辨率，适合小图）"
        OK=$((OK + 1))
    else
        echo "✅ $BASENAME — ${width}×${height}"
        OK=$((OK + 1))
    fi
done

echo ""
echo "=============================="
echo "📊 统计:"
echo "   总计:   $TOTAL 张"
echo "   ✅ 正常: $OK 张"
echo "   ⚠️  警告: $WARNINGS 张"
echo "   ❌ 错误: $ERRORS 张"

# 返回非零退出码如果有错误
if [ "$ERRORS" -gt 0 ]; then
    exit 1
fi
