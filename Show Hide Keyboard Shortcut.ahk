#NoEnv
#NoTrayIcon
#SingleInstance, Force
SetBatchLines, -1
SetWorkingDir %A_ScriptDir%
DetectHiddenWindows, Off

global Ejecutable := "LibreDeck Client.exe"

IfWinNotExist, ahk_exe %Ejecutable%
{
	DetectHiddenWindows, On
	IfWinExist, ahk_exe %Ejecutable%
	{
		WinShow, ahk_exe %Ejecutable%
		WinHide, ahk_class Shell_SecondaryTrayWnd
		WinHide, Start ahk_class Button
		WinActivate, ahk_exe %Ejecutable%
	}
	else
	{
		Run, "%A_ScriptDir%\LibreDeck Client.exe"
	}
}
else
{
	IfWinActive, ahk_exe %Ejecutable%
	{
		WinHide, ahk_exe %Ejecutable%
		WinShow, ahk_class Shell_SecondaryTrayWnd
		WinShow, Start ahk_class Button
	}
	else
	{
		WinShow, ahk_exe %Ejecutable%
		WinHide, ahk_class Shell_SecondaryTrayWnd
		WinHide, Start ahk_class Button
		WinActivate, ahk_exe %Ejecutable%
	}
}
