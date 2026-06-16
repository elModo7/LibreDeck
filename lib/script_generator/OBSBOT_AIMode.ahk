;~ 0->No Tracking;1->Normal Tracking;2->Upper Body;3->Close-up;4->Headless;5->Lower Body;6->Desk Mode;7->Whiteboard;8->Hand;9->Group
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
Gui Add, Radio, x8 y8 w191 h48 Checked vmode0, No Tracking
Gui Add, Radio, x8 y64 w191 h48 vmode1, Normal Tracking
Gui Add, Radio, x8 y120 w191 h48 vmode2, Upper Body
Gui Add, Radio, x208 y8 w191 h48 vmode3, Close Up
Gui Add, Radio, x208 y64 w191 h48 vmode4 disabled, Headless
Gui Add, Radio, x208 y120 w191 h48 vmode5 disabled, Lower Body
Gui Add, Radio, x408 y8 w191 h48 vmode6 disabled, Desk Mode
Gui Add, Radio, x408 y64 w191 h48 vmode7 disabled, Whiteboard
Gui Add, Radio, x408 y120 w191 h48 vmode8, Group

Gui Font, s14 cRed, Bai Jamjuree Bold
Gui Add, Text, x8 y176 w593 h32 +0x200, Only modes 0-3 and 9 are reliable.
Gui Show, w613 h222, OBSBOT AI Mode
Return

#If WinActive("OBSBOT AI Mode")
	Enter::gosub, generateScript
#If

GetOut:
GuiEscape:
GuiClose:
	SkinForm(0)
    ExitApp
	
generateScript:
	GuiControlGet, mode0,, mode0
	GuiControlGet, mode1,, mode1
	GuiControlGet, mode2,, mode2
	GuiControlGet, mode3,, mode3
	GuiControlGet, mode4,, mode4
	GuiControlGet, mode5,, mode5
	GuiControlGet, mode6,, mode6
	GuiControlGet, mode7,, mode7
	GuiControlGet, mode8,, mode8

	if(mode0){
		value := 0
	}else if(mode1){
		value := 1
	}else if(mode2){
		value := 2
	}else if(mode3){
		value := 3
	}else if(mode4){
		value := 4
	}else if(mode5){
		value := 5
	}else if(mode6){
		value := 6
	}else if(mode7){
		value := 7
	}else{
		value := 8
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
myCam.SetAiMode(" value ")
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
