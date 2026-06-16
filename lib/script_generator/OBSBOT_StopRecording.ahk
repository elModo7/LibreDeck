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
if FileExist(buttonPath)
{
	OnMessage(0x44, "OnMsgBox")
	MsgBox 0x34, Overwrite?, This button already has a macro file`, do you want to overwrite it?`n`nPrevious function will be lost!
	OnMessage(0x44, "")

	IfMsgBox Yes, {
		Generate()
	}
}
else
{
	Generate()
}
return


Generate()
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
myCam.StopRecording()
ExitApp
"
	)
	FileDelete, % buttonPath
	FileAppend, %src%, % buttonPath
	ExitApp
}
