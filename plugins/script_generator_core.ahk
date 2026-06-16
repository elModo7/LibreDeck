ScriptGenerator_RunFile:
	Run, % A_ScriptDir "\lib\autohotkey.exe ""lib\script_generator\RunFile.ahk"" """ GetButtonScriptRelativePath(BotonActivo, "ahk") """", % A_ScriptDir
return

ScriptGenerator_RunCmd:
	Run, % A_ScriptDir "\lib\autohotkey.exe ""lib\script_generator\RunCmd.ahk"" """ GetButtonScriptRelativePath(BotonActivo, "ahk") """", % A_ScriptDir
return

ScriptGenerator_SendText:
	Run, % A_ScriptDir "\lib\autohotkey.exe ""lib\script_generator\SendTextBlock.ahk"" """ GetButtonScriptRelativePath(BotonActivo, "ahk") """", % A_ScriptDir
return

ScriptGenerator_Hotkey:
	Run, % A_ScriptDir "\lib\autohotkey.exe ""lib\script_generator\HotkeyCreator.ahk"" """ GetButtonScriptRelativePath(BotonActivo, "ahk") """", % A_ScriptDir
return
