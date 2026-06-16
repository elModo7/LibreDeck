; Since using my new dll version instead of an Exe and being forced to 64bit
; This script needs to run as 64bit ahk and is no longer compatible with uskin
#NoEnv
#SingleInstance Force
SetBatchLines -1
#NoTrayIcon
global buttonPath = %0%
#Include %A_WorkingDir%/lib/setAhk64self.ahk
if(SubStr(buttonPath, -3) != ".ahk")
	buttonPath := buttonPath ".ahk"
SplitPath, buttonPath,, buttonDir
if(buttonDir != "")
	FileCreateDir, %buttonDir%
SkinForm(Apply, A_ScriptDir . "\lib\them.dll", A_ScriptDir . "\lib\tm")
OnExit, GetOut
global zoomValue
#Include %A_WorkingDir%/lib/OBSBOTController.ahk
myCam := new OBSBOTController("127.0.0.1", 16284)

Gui Add, Slider, x16 y40 w307 h38 vzoomValue gshowValueTooltip, 0
Gui Font, s14, Bai Jamjuree Bold
Gui Add, Text, x16 y8 w308 h23 +0x200 +Center, Camera Zoom
Gui Add, Button, x16 y80 w308 h23 gtestZoom, Test Script
Gui Add, Button, x16 y104 w308 h23 ggenerateScript, Create Script
Gui Show, w338 h141, OBSBOT Set Zoom
return

#If WinActive("OBSBOT Set Zoom")
	Enter::gosub, generateScript
#If

generateScript:
	GuiControlGet, zoomValue,, zoomValue
	if(zoomValue = "")
	{
		MsgBox 0x10, Error, Zoom Value is required!
		return
	}
	if FileExist(buttonPath)
	{
		OnMessage(0x44, "OnMsgBox")
		MsgBox 0x34, Overwrite?, This button already has a macro file`, do you want to overwrite it?`n`nPrevious function will be lost!
		OnMessage(0x44, "")

		IfMsgBox Yes, {
			Generate(zoomValue)
		}
	}
	else
	{
		Generate(zoomValue)
	}
return

showValueTooltip:
	GuiControlGet, zoomValue,, zoomValue
	ToolTip, %zoomValue%
	SetTimer, removeToolTip, 500
return

removeToolTip:
	SetTimer, removeToolTip, Off
	ToolTip
return

testZoom:
	GuiControlGet, zoomValue,, zoomValue
	myCam.SetZoom(zoomValue)
return

Generate(zoomValue)
{
	src :=
	(
"#NoEnv
#SingleInstance Force
#NoTrayIcon
#Include %A_WorkingDir%\lib\setAhk64self.ahk
#Include %A_WorkingDir%\lib\OBSBOTController.ahk
#Include %A_WorkingDir%\lib\nm_msg.ahk
SetBatchLines, -1
DetectHiddenWindows, On
ifWinNotExist, ahk_exe OBSBOT_Main.exe
{
	nmMsg(""OBSBOT svc not detected!"", 2)
	ExitApp
}
myCam := new OBSBOTController(""127.0.0.1"", 16284)
myCam.SetZoom(" zoomValue ")
ExitApp
"
	)
	FileDelete, % buttonPath
	FileAppend, %src%, % buttonPath
	ExitApp
}

GetOut:
GuiEscape:
GuiClose:
	SkinForm(0)
    ExitApp

SkinForm(Param1 = "Apply", DLL = "", SkinName = ""){
	if(Param1 = Apply){
		DllCall("LoadLibrary", str, DLL)
		DllCall(DLL . "\USkinInit", Int,0, Int,0, AStr, SkinName)
	}else if(Param1 = 0){
		DllCall(DLL . "\USkinExit")
	}
}
