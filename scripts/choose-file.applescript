-- choose-file.applescript — 原生文件选择对话框
-- 用法: osascript choose-file.applescript
-- 返回: POSIX 路径字符串
set theFile to choose file of type {"public.plain-text", "com.microsoft.word.doc", "org.openxmlformats.wordprocessingml.document", "com.adobe.pdf"} with prompt "选择要生成 PPT 的文档："
return POSIX path of theFile
