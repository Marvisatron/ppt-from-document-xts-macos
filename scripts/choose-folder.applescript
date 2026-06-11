-- choose-folder.applescript — 原生文件夹选择对话框
-- 用法: osascript choose-folder.applescript
-- 返回: POSIX 路径字符串（以 / 结尾）
set theFolder to choose folder with prompt "选择 PPT 输出目录："
return POSIX path of theFolder
