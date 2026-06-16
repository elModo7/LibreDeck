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

Gui Font, s14, Bai Jamjuree Bold
Gui Add, Text, x8 y8 w233 h23 +0x200 +Center, Speed
Gui Add, Text, x8 y112 w233 h23 +0x200 +Center, Pan
Gui Add, Text, x264 y168 w73 h23 +0x200 +Center, Pitch
Gui Add, Slider, x8 y40 w233 h41 +NoTicks +Center +Tooltip vspeed range0-90, 45
Gui Add, Slider, x8 y144 w233 h41 +NoTicks +Center +Tooltip vpan range-129-129, 0
Gui Add, Slider, x256 y8 w83 h156 +NoTicks +Center +Tooltip vpitch +Vertical range-59-59, 0
Gui Add, Button, x8 y200 w332 h33 gtestGimbal, Test Script
Gui Add, Button, x8 y240 w332 h33 ggenerateScript, Generate Script
Gui Show, w354 h287, OBSBOT Set Gimbal
return

#If WinActive("OBSBOT Set Gimbal")
	Enter::gosub, generateScript
#If

generateScript:
	gosub, getValuesFromGui
	if FileExist(buttonPath)
	{
		OnMessage(0x44, "OnMsgBox")
		MsgBox 0x34, Overwrite?, This button already has a macro file`, do you want to overwrite it?`n`nPrevious function will be lost!
		OnMessage(0x44, "")

		IfMsgBox Yes, {
			Generate(speed, pan, pitch)
		}
	}
	else
	{
		Generate(speed, pan, pitch)
	}
return

testGimbal:
	gosub, getValuesFromGui
	myCam.SetGimbal(speed, pan, pitch)
return

getValuesFromGui:
	GuiControlGet, pan,, pan
	GuiControlGet, pitch,, pitch
	GuiControlGet, speed,, speed
return

Generate(speed, pan, pitch)
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
myCam.SetGimbal(" speed ", " pan ", " pitch ")
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
