# PPT from Document — macOS 特供版

> 全自动文档→PPT 生成器。macOS 独占特性：Antigravity CLI (`agy`) 直接调用 Gemini 生成配图，AppleScript 系统通知 + Finder 集成，OfficeCLI 原生 PPTX 构建。

## 版本历史

| 版本 | 日期 | 关键变更 |
|------|------|---------|
| **v2.1** | 2026-06-11 | 动画默认加速 2x（duration 200-300ms），批量加速脚本，过渡 fade-fast 默认 |
| **v2.0** | 2026-06-11 | agy CLI 替代 Safari MCP，色块 padding ≥0.4cm，正文放大 16-18pt，网络搜图优先，动画与切换规则 |
| **v1.0** | 2026-06-10 | 初始版本：Safari MCP → Gemini 配图，Eight Confirmations 设计，OfficeCLI 构建 |

## 快速开始

```bash
# 安装依赖
brew install antigravity-cli officecli

# 登录 agy（一次性）
agy

# 在 Claude Code 中使用
根据文档生成PPT /path/to/document.md
```

## 目录结构

```
├── SKILL.md              # 主 skill 文件（给 Claude Code 读取）
├── README.md             # 本文件
├── scripts/              # AppleScript 工具脚本
├── references/           # 参考文档
└── examples/             # 示例
```

## 平台

- **macOS 12+**（独占）

## License

MIT
