#NoEnv
#SingleInstance, Force
SetBatchLines, -1
#NoTrayIcon
SetWorkingDir C:\Program Files\obs-studio\bin\64bit

global Ejecutable := "obs64.exe"

IfWinExist, ahk_exe %Ejecutable%
{
	WinActivate, ahk_exe %Ejecutable%
}
else
{
	Run, C:\Program Files\obs-studio\bin\64bit\obs64.exe
}