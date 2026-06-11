-- delivery-dialog.applescript — 交付完成对话框
-- 用法: osascript delivery-dialog.applescript "/path/to/presentation.pptx" "12" "8"
-- 参数: 文件路径 页数 图片数
on run argv
    set outputPath to item 1 of argv
    set slideCount to item 2 of argv
    set imageCount to item 3 of argv

    set dialogMessage to "✅ PPT 生成完成！" & return & return & "文件：" & outputPath & return & "页数：" & slideCount & " 页" & return & "图片：" & imageCount & " 张（Safari MCP → Gemini 自动生成）" & return & return & "是否在 Finder 中打开？"

    set userChoice to button returned of (display dialog dialogMessage buttons {"关闭", "在 Finder 中打开"} default button "在 Finder 中打开" with title "PPT macOS Skill" with icon note)

    if userChoice = "在 Finder 中打开" then
        tell application "Finder"
            reveal POSIX file outputPath as alias
            activate
        end tell
    end if

    return userChoice
end run
