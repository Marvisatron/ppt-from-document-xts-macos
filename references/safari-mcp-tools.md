# Safari MCP 关键工具速查

> 基于 [safari-mcp](https://github.com/achiya-automation/safari-mcp) by achiya-automation
> 
> 本参考列出了用于 PPT 图片生成自动化的关键 MCP 工具及其参数。
> 完整工具列表（80+），请参见官方文档。

## 导航类

| 工具名 | 参数 | 说明 |
|--------|------|------|
| `safari_navigate` | `url: string` | 导航到指定 URL |
| `safari_go_back` | 无 | 返回上一页 |
| `safari_go_forward` | 无 | 前进到下一页 |
| `safari_reload` | 无 | 刷新当前页面 |
| `safari_get_current_url` | 无 | 获取当前标签页 URL |
| `safari_get_page_title` | 无 | 获取当前页面标题 |

## 元素交互类

| 工具名 | 参数 | 说明 |
|--------|------|------|
| `safari_click` | `selector: string` (CSS) | 点击匹配的第一个元素 |
| `safari_type` | `selector: string`, `text: string` | 在匹配元素中输入文本 |
| `safari_fill` | `selector: string`, `value: string` | 填充表单字段 |
| `safari_select` | `selector: string`, `value: string` | 选择下拉菜单选项 |
| `safari_hover` | `selector: string` | 鼠标悬停在元素上 |
| `safari_press_key` | `key: string` | 按下键盘按键（Enter, Escape, Tab 等） |
| `safari_scroll_to` | `selector: string` | 滚动到指定元素 |
| `safari_scroll_down` | `amount: number` | 向下滚动指定像素 |
| `safari_scroll_up` | `amount: number` | 向上滚动指定像素 |

## 页面读取类

| 工具名 | 参数 | 说明 |
|--------|------|------|
| `safari_get_text` | 无 | 获取页面可见文本（简化版） |
| `safari_get_html` | `selector?: string` | 获取页面/元素 HTML |
| `safari_get_element_text` | `selector: string` | 获取特定元素文本 |
| `safari_get_attribute` | `selector: string`, `attribute: string` | 获取元素属性值 |
| `safari_execute_javascript` | `script: string` | 在页面中执行 JavaScript 并返回结果 |

## 截图与视觉类

| 工具名 | 参数 | 说明 |
|--------|------|------|
| `safari_screenshot` | `selector?: string`, `fullPage?: boolean` | 截取页面/元素截图 |
| `safari_get_element_screenshot` | `selector: string` | 截取特定元素截图 |
| `safari_get_accessibility_tree` | 无 | 获取可访问性树（结构化页面理解） |

## 等待类

| 工具名 | 参数 | 说明 |
|--------|------|------|
| `safari_wait_for_selector` | `selector: string`, `timeout?: number` | 等待 CSS 选择器出现 |
| `safari_wait_for_text` | `text: string`, `timeout?: number` | 等待文本出现在页面中 |
| `safari_wait_for_navigation` | `timeout?: number` | 等待页面导航完成 |
| `safari_sleep` | `ms: number` | 等待指定毫秒数（用于避免速率限制检测） |

## 标签页管理类

| 工具名 | 参数 | 说明 |
|--------|------|------|
| `safari_new_tab` | `url?: string` | 打开新标签页 |
| `safari_close_tab` | `index?: number` | 关闭当前/指定标签页 |
| `safari_switch_to_tab` | `index: number` | 切换到指定标签页 |
| `safari_list_tabs` | 无 | 列出所有打开的标签页 |
| `safari_get_current_tab_index` | 无 | 获取当前活动标签页索引 |

## 下载与文件类

| 工具名 | 参数 | 说明 |
|--------|------|------|
| `safari_download_current_image` | `selector: string` | 下载指定图片元素 |
| `safari_get_downloads` | 无 | 获取最近下载列表 |
| `safari_wait_for_download` | `timeout?: number` | 等待下载完成 |

## PPT 配图自动化常用组合

### 组合 1: 导航 + 登录检查

```
1. safari_navigate { url: "https://gemini.google.com/app/image" }
2. safari_wait_for_selector { selector: "textarea, div[contenteditable], [role='textbox']", timeout: 15000 }
3. safari_execute_javascript { script: "检查登录状态的 JS" }
4. 如果未登录 → AppleScript 通知用户
```

### 组合 2: 输入 Prompt + 生成

```
1. safari_click { selector: "div[contenteditable='true']" }    # 点击输入框
2. safari_sleep { ms: 500 }                                    # 等待焦点
3. safari_type { selector: "div[contenteditable='true']", text: "prompt text" }
4. safari_sleep { ms: 300 }
5. safari_click { selector: "button[aria-label*='Send']" }   # 点击发送
6. safari_wait_for_selector { selector: "img[src*='gemini']", timeout: 120000 }
```

### 组合 3: 下载图片

```
1. safari_execute_javascript { script: "获取最新图片 src 的 JS" }
2. curl -o images/xxx.png "提取到的 URL"
```

### 组合 4: 开始新对话

```
1. safari_navigate { url: "https://gemini.google.com/app/image" }   # 重新进入图片模式
2. safari_wait_for_selector { selector: "div[contenteditable], textarea", timeout: 10000 }
```

## 注意事项

1. **所有 selector 参数使用标准 CSS 选择器**（不是 XPath）
2. **safari_execute_javascript 中的 JS 在页面上下文中执行**，可以访问 DOM、全局变量
3. **工具名前缀可能有所不同**（取决于 MCP 服务器配置的名称），如 `safari_` 或其他自定义前缀
4. **Safari 在后台时不渲染 CSS 动画**，某些视觉等待可能不触发
5. **速率限制**：在批量生成时，在每张图片之间添加 `safari_sleep { ms: 3000 }` 以避免触发 Gemini 的频率限制
