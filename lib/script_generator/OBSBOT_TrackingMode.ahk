#NoEnv
#SingleInstance Force
SetBatchLines -1
#NoTrayIcon
global buttonPath = %0%
if(SubStr(buttonPath, -3) != ".ahk")
	buttonPath := buttonPath ".ahk"
SplitPath, buttonPath,, buttonDir
if(buttonDir != "")
	FileCreateDir, %buttonDir%

SkinForm(Apply, A_ScriptDir . "\lib\them.dll", A_ScriptDir . "\lib\tm")
OnExit, GetOut

Gui Font, s14, Bai Jamjuree Bold
Gui Add, Radio, x8 y8 w191 h48 vheadroom disabled, Headroom ??
Gui Add, Radio, x8 y64 w191 h48 Checked vstandard, Standard
Gui Add, Radio, x8 y120 w191 h48 vmotion, Motion

Gui Show, w213 h182, OBSBOT Tracking Mode
Return

#If WinActive("OBSBOT Tracking Mode")
	Enter::gosub, generateScript
#If

GetOut:
GuiEscape:
GuiClose:
	SkinForm(0)
    ExitApp
	
generateScript:
	GuiControlGet, headroom,, headroom
	GuiControlGet, standard,, standard
	GuiControlGet, motion,, motion
	if(headroom){
		value := 0
	}else if(standard){
		value := 1
	}else{
		value := 2
	}
	if FileExist(buttonPath)
	{
		OnMessage(0x44, "OnMsgBox")
		MsgBox 0x34, Overwrite?, This button already has a macro file`, do you want to overwrite it?`n`nPrevious function will be lost!
		OnMessage(0x44, "")

		IfMsgBox Yes, {
			Generate(value)
		}
	}
	else
	{
		Generate(value)
	}
return

Generate(value)
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
myCam.SetTrackingMode(" value ")
ExitApp
"
	)
	FileDelete, % buttonPath
	FileAppend, %src%, % buttonPath
	ExitApp
}

SkinForm(Param1 = "Apply", DLL = "", SkinName = ""){
	if(Param1 = Apply){
		DllCall("LoadLibrary", str, DLL)
		DllCall(DLL . "\USkinInit", Int,0, Int,0, AStr, SkinName)
	}else if(Param1 = 0){
		DllCall(DLL . "\USkinExit")
	}
}
