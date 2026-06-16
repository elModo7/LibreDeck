ScriptGenerator_OBS_HideShowSource:
	Run, % A_ScriptDir "\lib\autohotkey.exe ""lib\script_generator\OBS_HideShowSource.ahk"" """ GetButtonScriptRelativePath(BotonActivo, "ahk") """", % A_ScriptDir
return

ScriptGenerator_OBS_SetScene:
	Run, % A_ScriptDir "\lib\autohotkey.exe ""lib\script_generator\OBS_SetScene.ahk"" """ GetButtonScriptRelativePath(BotonActivo, "ahk") """", % A_ScriptDir
return

ScriptGenerator_OBS_Record:
	Run, % A_ScriptDir "\lib\autohotkey.exe ""lib\script_generator\OBS_Record.ahk"" """ GetButtonScriptRelativePath(BotonActivo, "ahk") """", % A_ScriptDir
return

ScriptGenerator_OBS_StopRecord:
	Run, % A_ScriptDir "\lib\autohotkey.exe ""lib\script_generator\OBS_StopRecord.ahk"" """ GetButtonScriptRelativePath(BotonActivo, "ahk") """", % A_ScriptDir
return

ScriptGenerator_OBS_PauseRecord:
	Run, % A_ScriptDir "\lib\autohotkey.exe ""lib\script_generator\OBS_PauseRecord.ahk"" """ GetButtonScriptRelativePath(BotonActivo, "ahk") """", % A_ScriptDir
return

ScriptGenerator_OBS_ResumeRecord:
	Run, % A_ScriptDir "\lib\autohotkey.exe ""lib\script_generator\OBS_ResumeRecord.ahk"" """ GetButtonScriptRelativePath(BotonActivo, "ahk") """", % A_ScriptDir
return

ScriptGenerator_OBS_MuteUnmuteSource:
	Run, % A_ScriptDir "\lib\autohotkey.exe ""lib\script_generator\OBS_MuteUnmuteSource.ahk"" """ GetButtonScriptRelativePath(BotonActivo, "ahk") """", % A_ScriptDir
return

ScriptGenerator_OBS_ShowCurrentScene:
	if(ComprobarExistenciaBoton())
	{
		buttonPath := GetButtonScriptRelativePath(BotonActivo, "ahk")
		EnsureButtonScriptDirectory(buttonPath)
		FileCopy, % A_ScriptDir "\lib\script_generator\OBS_ShowCurrentScene.ahk", % A_ScriptDir "\" buttonPath, 1
	}
return

ScriptGenerator_OBS_SoundPannel:
	if(ComprobarExistenciaBoton()){
		buttonPath := GetButtonScriptRelativePath(BotonActivo, "ahk")
		EnsureButtonScriptDirectory(buttonPath)
		FileDelete, % buttonPath
		scriptContent =
		(LTrim
		#NoEnv
		#SingleInstance, Force
		#NoTrayIcon
		SetWorkingDir `%A_WorkingDir`%\plugins\obs_sound_control
		Run, `% """" A_WorkingDir "\lib\autohotkey.exe"" """ A_WorkingDir "\plugins\obs_sound_control\obs_sound_panel.ahk""""
		)
		FileAppend, % scriptContent, % buttonPath
	}
return
