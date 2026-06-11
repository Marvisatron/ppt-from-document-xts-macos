-- reveal-in-finder.applescript — 在 Finder 中定位文件
-- 用法: osascript reveal-in-finder.applescript "/path/to/file.pptx"
on run argv
    set thePath to item 1 of argv
    tell application "Finder"
        reveal POSIX file thePath as alias
        activate
    end tell
end run
