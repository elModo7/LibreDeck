#SingleInstance Force
#NoEnv
SetBatchLines -1
global buttonPath = %0%
if(SubStr(buttonPath, -3) != ".ahk")
	buttonPath := buttonPath ".ahk"
SplitPath, buttonPath,, buttonDir
if(buttonDir != "")
	FileCreateDir, %buttonDir%
global keyDuration, keyDelay, textVar, sendRaw, sendInput, sendEvent, instantPaste, modoSend
SkinForm(Apply, A_ScriptDir . "\lib\them.dll", A_ScriptDir . "\lib\tm")
OnExit, GetOut

Gui Font, Bold
Gui Add, Button, gcreateMacro x480 y408 w123 h33, APPLY
Gui Font
Gui Add, Edit, vtextVar x8 y8 w603 h315
Gui Add, Radio, vsendRaw x8 y336 w360 h23 +Checked, SendRaw (Fast - Recommended for short text)
Gui Add, Radio, vsendInput x8 y360 w360 h23, SendInput (Fast - Recommended when text has no symbols)
Gui Add, Radio, vsendEvent x8 y408 w260 h23, SendEvent (Not Recommended)
Gui Add, Radio, vinstantPaste x8 y384 w379 h23, Send Clipboard (Fastest - Recommended for long text)
Gui Add, GroupBox, x8 y440 w597 h84, SendEvent/SendRaw Options   (ONLY work on SendEvent & SendRaw Mode)
Gui Add, Text, x16 y464 w73 h23 +0x200, Key Delay:
Gui Add, Text, x16 y488 w72 h23 +0x200, Press duration:
Gui Add, Edit, vkeyDelay x88 y464 w120 h21, 0
Gui Add, Edit, vkeyDuration x88 y488 w120 h21, 0
Gui Add, Text, x216 y464 w73 h23 +0x200, ms
Gui Add, Text, x216 y488 w73 h23 +0x200, ms

Gui Show, w619 h549, Text Block
Return

createMacro:
	Gui, Submit, NoHide
	if(sendInput)
	{
		modoSend := "SendInput"
	}
	else if(sendRaw)
	{
		modoSend := "SendRaw"
	}
	else if(sendEvent)
	{
		modoSend := "SendEvent"
	}
	if(textVar = "")
	{
		MsgBox 0x10, Error, There is no text to send!
		return
	}
	if FileExist(buttonPath)
	{
		OnMessage(0x44, "OnMsgBox")
		MsgBox 0x34, Overwrite?, This button already has a macro file`, do you want to overwrite it?`n`nPrevious function will be lost!
		OnMessage(0x44, "")

		IfMsgBox Yes, {
			Generar()
		}
	}
	else
	{
		Generar()
	}
Return

Generar()
{
	if(!instantPaste)
	{
		src =
		(
#NoEnv
#SingleInstance, Force
SetBatchLines, -1
#NoTrayIcon
SetKeyDelay, %keyDelay%, %keyDuration%
text =
`(
%textVar%
`)
%modoSend%, `% text
		)
	}
	else
	{
		src =
		(
#NoEnv
#SingleInstance, Force
SetBatchLines, -1
#NoTrayIcon
Clipboard =
`(
%textVar%
`)
Sleep, 500
Send, {LControl Down}v{LControl Up}
		)
	}
	FileDelete, % buttonPath
	FileAppend, %src%, % buttonPath
	ExitApp
}

GetOut:
GuiEscape:
GuiClose:
	SkinForm(0)
    ExitApp
	
OnMsgBox() {
    DetectHiddenWindows, On
    Process, Exist
    If (WinExist("ahk_class #32770 ahk_pid " . ErrorLevel)) {
        ControlSetText Button1, Overwrite
        ControlSetText Button2, CANCEL
    }
}

SkinForm(Param1 = "Apply", DLL = "", SkinName = ""){
	if(Param1 = Apply){
		DllCall("LoadLibrary", str, DLL)
		DllCall(DLL . "\USkinInit", Int,0, Int,0, AStr, SkinName)
	}else if(Param1 = 0){
		DllCall(DLL . "\USkinExit")
		}
}
