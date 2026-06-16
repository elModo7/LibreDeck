#NoEnv
#SingleInstance, Force
#NoTrayIcon
SetBatchLines, -1
SetWorkingDir, %A_WorkingDir%\plugins\obs_sound_control
Run, % "..\..\lib\autohotkey.exe obs_sound_panel.ahk"
