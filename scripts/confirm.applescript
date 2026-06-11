-- confirm.applescript — 确认对话框
-- 用法: osascript confirm.applescript "确认消息内容"
-- 返回: "确认" 或 "取消"
on run argv
    set theMessage to item 1 of argv
    display dialog theMessage buttons {"取消", "确认"} default button "确认" with title "PPT macOS Skill" with icon note
    return button returned of result
end run
