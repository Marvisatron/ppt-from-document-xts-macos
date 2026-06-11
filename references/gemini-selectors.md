# Gemini Web 界面 CSS 选择器参考

> 本文档记录 Google Gemini (gemini.google.com) 网页界面的关键 DOM 元素选择器，
> 用于 Safari MCP 自动化时定位元素。
>
> 注意：Google 会频繁更新 Gemini 界面，以下选择器可能随时间变化。
> 使用前建议先通过 Safari MCP 的 `execute JavaScript` 工具验证选择器是否仍然有效。

## 基础 URL

| 页面 | URL |
|------|-----|
| Gemini 首页 | `https://gemini.google.com/app` |
| 图片生成页面 | `https://gemini.google.com/app/image` |
| 直接进入聊天 | `https://gemini.google.com/app?q=prompt` |

## 登录状态检测

```javascript
// 检测是否已登录 Google 账号
const signInBtn = document.querySelector('a[href*="SignIn"], a[href*="signin"], [aria-label*="Sign in"]');
const userAvatar = document.querySelector('img[src*="user"], [data-user-avatar], .gb_ya');
const isLoggedIn = !signInBtn && !!userAvatar;
return isLoggedIn ? 'logged_in' : 'not_logged_in';
```

## 模型选择器

```javascript
// 当前选中的模型（显示在输入框上方或侧边栏）
const modelSelector = document.querySelector('[aria-label*="model"], [data-model], .model-selector');
// 常见模型标识:
// "Gemini 2.5 Flash" — 默认
// "Gemini 2.5 Pro" — 高级推理
// "Nano Banana" / "Create images" — 图片生成
```

## 图片生成模式激活

Gemini 有多种方式进入图片生成模式：

### 途径 1: 模型选择器切换到 Nano Banana

```javascript
// 点击模型选择器
document.querySelector('[aria-label*="model"], .model-picker')?.click();
// 等待下拉菜单出现后，选择包含 "image" 或 "Nano Banana" 的选项
// 选择器可能是动态渲染的
```

### 途径 2: 直接 URL 跳转

```
navigate to https://gemini.google.com/app/image
```

### 途径 3: 在聊天中通过自然语言触发

在输入框中输入包含图片生成请求的 prompt，Gemini 会自动激活图片生成能力。

## 输入框定位

```javascript
// 主输入框（ChatGPT 风格的 textarea/contenteditable）
// 可能的选择器（按优先级排列）：
const inputSelectors = [
    'div[contenteditable="true"]',
    'rich-textarea div[contenteditable]',
    'textarea[aria-label*="prompt"]',
    'textarea[aria-label*="message"]',
    'textarea[placeholder*="Ask"]',
    'textarea[placeholder*="Gemini"]',
    'div[role="textbox"]',
    '[data-input-box]',
];

function findInput() {
    for (const sel of inputSelectors) {
        const el = document.querySelector(sel);
        if (el) return el;
    }
    return null;
}
```

## 提交按钮定位

```javascript
// 发送/提交按钮
const submitSelectors = [
    'button[aria-label*="Send"]',
    'button[aria-label*="Submit"]',
    'button[aria-label*="send message"]',
    'button[data-test-id="send-button"]',
    'button.send-button',
    'button[type="submit"]',
    'svg[aria-label*="Send"]',
    'button:has(svg)',
];

function findSubmitButton() {
    for (const sel of submitSelectors) {
        const el = document.querySelector(sel);
        if (el && !el.disabled) return el;
    }
    return null;
}
```

## 生成中状态检测

```javascript
// 检测图片是否正在生成
// 1. 加载动画
const loadingSpinner = document.querySelector('[aria-label*="loading"], .loading, .spinner, .generating');
// 2. 进度条
const progressBar = document.querySelector('[role="progressbar"]');
// 3. 状态文本
const statusText = document.body.innerText.includes('Generating') || document.body.innerText.includes('Creating');

const isGenerating = !!(loadingSpinner || progressBar || statusText);
return isGenerating ? 'generating' : 'idle';
```

## 已生成图片定位

```javascript
// 找到聊天中生成的图片
const imageSelectors = [
    'img[src*="gemini.google.com"]',
    'img[src*="image/generated"]',
    'img[src*="/image/"]',
    'img[loading="lazy"]',
    '.generated-image img',
    '[data-generated-image] img',
    'div[data-message] img',
];

function findGeneratedImages() {
    const imgs = [];
    for (const sel of imageSelectors) {
        document.querySelectorAll(sel).forEach(img => {
            if (img.naturalWidth > 100 && !imgs.includes(img)) {
                imgs.push(img);
            }
        });
    }
    return imgs;
}

// 获取最新生成的图片（通常是消息列表中最后一张）
function getLatestImage() {
    const imgs = findGeneratedImages();
    return imgs.length > 0 ? imgs[imgs.length - 1] : null;
}
```

## 图片下载

```javascript
// 方案 1: 获取图片的直接 URL（用于 curl 下载）
const img = getLatestImage();
if (img) {
    // Gemini 可能使用 blob URL 或 CDN URL
    const src = img.src;
    const srcset = img.srcset;  // 可能有多个分辨率
    return JSON.stringify({ src, srcset, width: img.naturalWidth, height: img.naturalHeight });
}

// 方案 2: 触发右键菜单
// 在 Safari 中，可以通过 JavaScript 模拟右键或使用图片的 context menu
img.dispatchEvent(new MouseEvent('contextmenu', { bubbles: true }));

// 方案 3: 点击图片打开预览（部分界面设计）
img.click();
// 然后从预览模式下载
```

## 新对话 / 清空输入

```javascript
// 开始新对话
const newChatBtn = document.querySelector('[aria-label*="New chat"], [aria-label*="new chat"], [data-new-chat]');
if (newChatBtn) newChatBtn.click();

// 清空当前输入
const input = findInput();
if (input) {
    input.textContent = '';
    input.dispatchEvent(new Event('input', { bubbles: true }));
}
```

## 等待策略

| 事件 | 等待方式 | 超时 |
|------|---------|------|
| 页面加载 | 等待 `body` 或特定选择器出现 | 15s |
| 登录完成 | 等待用户头像出现 | 60s（首次可能需用户手动登录） |
| 图片开始生成 | 等待加载动画出现 | 15s |
| 图片生成完成 | 轮询检测图片元素出现 | 120s |
| 图片可点击 | 等待图片 `naturalWidth > 0` | 10s |

## 错误检测

```javascript
// 检测常见错误
const errorSelectors = [
    '[aria-label*="error"]',
    '[role="alert"]',
    '.error-message',
    '.error-state',
    'div:contains("Something went wrong")',
    'div:contains("couldn\'t")',
    'div:contains("unable to")',
    'div:contains("I can\'t")',
];

function detectError() {
    const body = document.body.innerText;
    for (const sel of errorSelectors) {
        const el = document.querySelector(sel);
        if (el) return el.textContent || el.innerText;
    }
    if (body.includes('Something went wrong')) return body;
    if (body.includes("I can't generate")) return body;
    return null;
}
```

## macOS Safari 特有注意事项

1. **焦点管理**：Safari 在后台运行时，某些 JavaScript 事件（如 `focus`、`click`）可能行为不同。使用 `safari_activate` 先激活窗口。
2. **剪贴板权限**：Safari 在后台时，`document.execCommand('paste')` 可能被阻止。优先使用 `safari_type` 工具。
3. **下载路径**：Safari 默认下载到 `~/Downloads/`。可通过 AppleScript 设置自定义下载路径。
4. **Cookie/会话**：Safari MCP 使用真实 Safari 会话，所以 Google 登录状态会保留（无需每次登录）。
