#!/bin/bash
# image-info.sh — 获取图片尺寸和格式信息
# 用法: ./image-info.sh <image_file>
# 依赖: macOS 自带 sips 命令

if [ $# -lt 1 ]; then
    echo "用法: $0 <image_file>"
    exit 1
fi

IMAGE="$1"

if [ ! -f "$IMAGE" ]; then
    echo "❌ 文件不存在: $IMAGE"
    exit 1
fi

echo "📷 图片信息: $IMAGE"
echo "=============================="

# 获取像素尺寸
width=$(sips -g pixelWidth "$IMAGE" 2>/dev/null | tail -1 | awk '{print $2}')
height=$(sips -g pixelHeight "$IMAGE" 2>/dev/null | tail -1 | awk '{print $2}')
format=$(sips -g format "$IMAGE" 2>/dev/null | tail -1 | awk '{print $2}')
dpi=$(sips -g dpiWidth "$IMAGE" 2>/dev/null | tail -1 | awk '{print $2}')
fileSize=$(du -h "$IMAGE" | awk '{print $1}')

echo "格式:     $format"
echo "尺寸:     ${width} × ${height} px"
echo "DPI:      $dpi"
echo "文件大小: $fileSize"

# 宽高比检查
if [ -n "$width" ] && [ -n "$height" ]; then
    ratio=$(echo "scale=3; $width / $height" | bc 2>/dev/null)
    echo "宽高比:   $ratio"

    # PPT 16:9 = 1.778
    is169=$(echo "$ratio > 1.70 && $ratio < 1.85" | bc 2>/dev/null)
    is43=$(echo "$ratio > 1.30 && $ratio < 1.38" | bc 2>/dev/null)
    is11=$(echo "$ratio > 0.95 && $ratio < 1.05" | bc 2>/dev/null)

    if [ "$is169" = "1" ]; then
        echo "✅ 适合全页 PPT 背景 (16:9)"
    elif [ "$is43" = "1" ]; then
        echo "⚠️  4:3 — 适合部分页面区域"
    elif [ "$is11" = "1" ]; then
        echo "⚠️  1:1 方形 — 适合图标或小图"
    else
        echo "⚠️  非标准比例 — 建议裁剪或调整"
    fi
fi

# 分辨率检查（PPT 全页最小要求）
if [ "$width" -lt 1920 ] 2>/dev/null; then
    echo "⚠️  宽度不足 1920px（全页 PPT 最低要求）"
fi
if [ "$height" -lt 1080 ] 2>/dev/null; then
    echo "⚠️  高度不足 1080px（全页 PPT 最低要求）"
fi
