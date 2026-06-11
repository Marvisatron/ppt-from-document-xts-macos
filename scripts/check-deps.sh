#!/bin/bash
# check-deps.sh — 前置依赖检查脚本
# 用法: ./check-deps.sh
# 返回: 0 = 所有依赖就绪, 1 = 有缺失

echo "🔍 检查 macOS PPT Skill 依赖..."
echo "================================"
PASS=0
FAIL=0

# 1. macOS
if [[ "$(uname)" == "Darwin" ]]; then
    echo "✅ macOS $(sw_vers -productVersion)"
    PASS=$((PASS + 1))
else
    echo "❌ 非 macOS 系统，本 skill 仅支持 macOS"
    FAIL=$((FAIL + 1))
fi

# 2. OfficeCLI
if command -v officecli &>/dev/null; then
    VER=$(officecli --version 2>&1)
    echo "✅ OfficeCLI $VER"
    PASS=$((PASS + 1))
else
    echo "❌ OfficeCLI 未安装"
    echo "   安装: curl -fsSL https://d.officecli.ai/install.sh | sh"
    FAIL=$((FAIL + 1))
fi

# 3. Node.js 18+
if command -v node &>/dev/null; then
    NODE_VER=$(node --version | sed 's/v//' | cut -d. -f1)
    if [ "$NODE_VER" -ge 18 ]; then
        echo "✅ Node.js $(node --version)"
        PASS=$((PASS + 1))
    else
        echo "❌ Node.js $(node --version) — 需要 18+"
        FAIL=$((FAIL + 1))
    fi
else
    echo "❌ Node.js 未安装"
    echo "   安装: brew install node"
    FAIL=$((FAIL + 1))
fi

# 4. safari-mcp
if npx safari-mcp --version &>/dev/null 2>&1; then
    echo "✅ safari-mcp"
    PASS=$((PASS + 1))
elif npm list -g safari-mcp &>/dev/null 2>&1; then
    echo "✅ safari-mcp (全局安装)"
    PASS=$((PASS + 1))
else
    echo "⚠️  safari-mcp 未安装"
    echo "   安装: npm install -g safari-mcp"
    FAIL=$((FAIL + 1))
fi

# 5. AppleScript
if osascript -e 'return "OK"' &>/dev/null 2>&1; then
    echo "✅ AppleScript (osascript)"
    PASS=$((PASS + 1))
else
    echo "❌ AppleScript 不可用"
    FAIL=$((FAIL + 1))
fi

# 6. sips (macOS 自带图片工具)
if command -v sips &>/dev/null; then
    echo "✅ sips (图片处理)"
    PASS=$((PASS + 1))
else
    echo "⚠️  sips 不可用（非典型 macOS 安装）"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "================================"
echo "结果: $PASS 通过, $FAIL 失败"

if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo "请修复以上失败项后重试。"
    exit 1
else
    echo "✅ 所有依赖就绪！"
    exit 0
fi
