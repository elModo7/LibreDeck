#NoEnv
#SingleInstance, Force
SetBatchLines, -1
#NoTrayIcon
SetWorkingDir C:\Windows\System32

global Executable := "calc.exe"

IfWinExist, ahk_exe %Executable%
{
	WinActivate, ahk_exe %Executable%
}
else
{
	Run, "C:\Windows\System32\calc.exe"
}