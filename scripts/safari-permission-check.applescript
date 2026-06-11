-- safari-permission-check.applescript — Safari 权限检查与配置提示
-- 用法: osascript safari-permission-check.applescript
-- 检查 Safari 是否可被 AppleScript 控制，不可用时弹出配置引导

tell application "System Events"
    -- 检查 Safari 是否在运行
    if (name of processes) does not contain "Safari" then
        tell application "Safari" to activate
        delay 1
    end if
end tell

try
    tell application "Safari"
        set safariRunning to true
        set currentURL to URL of current tab of window 1
    end tell
    -- Safari 可访问，视为已配置
    return "OK"
on error
    -- Safari 不可访问，弹出配置引导
    display dialog "Safari 权限未配置。请按以下步骤操作：" & return & return & "1. 打开 Safari → Settings → Advanced" & return & "   勾选「Show features for web developers」" & return & return & "2. 打开 Safari → Develop" & return & "   勾选「Allow JavaScript from Apple Events」" & return & return & "3. 打开 System Settings → Privacy & Security" & return & "   → Automation → 允许终端控制 Safari" & return & return & "配置完成后点击「继续」" buttons {"取消", "已配置完成，继续"} default button "已配置完成，继续" with title "Safari 权限配置" with icon caution
    return "CONFIGURED"
end try
