-- notify.applescript — macOS 系统通知
-- 用法: osascript notify.applescript "标题" "消息内容"
on run argv
    set theTitle to item 1 of argv
    set theMessage to item 2 of argv
    display notification theMessage with title theTitle sound name "Glass"
end run
