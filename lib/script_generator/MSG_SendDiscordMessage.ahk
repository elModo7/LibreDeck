;~ ; The idea is to have a list of webhooks name => wh to select from in the config
#NoEnv
#SingleInstance Force
SetBatchLines -1
global buttonPath = %0%
if(SubStr(buttonPath, -3) != ".ahk")
	buttonPath := buttonPath ".ahk"
SplitPath, buttonPath,, buttonDir
if(buttonDir != "")
	FileCreateDir, %buttonDir%
SkinForm(Apply, A_ScriptDir . "\lib\them.dll", A_ScriptDir . "\lib\tm")
OnExit, GetOut
Gui Add, Text, x32 y10 w80 h23 +0x200, Webhook URL:
Gui Add, Edit, x112 y10 w220 h21 vsource
Gui Add, Text, x32 y43 w72 h23 +0x200, Message:
Gui Add, Edit, x32 y65 w300 h200 vmsg
Gui, Font, Bold
Gui Add, Button, x230 y270 w100 h23, Create Button
Gui Show, w339 h300, New Discord MSG
wh_url := "https://discord.com/api/webhooks/<YOUR_WEBHOOK_HERE>"
return


GetOut:
GuiEscape:
GuiClose:
	SkinForm(0)
    ExitApp
	
#If WinActive("Hide / Show Source")
	Enter::
		GuiControlGet, source,, source
		GuiControlGet, show,, show
		if(source = "")
		{
			MsgBox 0x10, Error, No source selected!
			return
		}
	else if(workingDir = "")
	{
		workingDir := A_Desktop
	}
	visibility := "false"
	if(show){
		visibility := "true"
	}
	if FileExist(buttonPath)
	{
		OnMessage(0x44, "OnMsgBox")
		MsgBox 0x34, Overwrite?, This button already has a macro file`, do you want to overwrite it?`n`nPrevious function will be lost!
		OnMessage(0x44, "")

		IfMsgBox Yes, {
			Generar(source, visibility)
		}
	}
	else
	{
		Generar(source, wh_url)
	}
	return
#If
	
Generar(msg, wh_url)
{
	src :=
	(
"#NoEnv
#NoTrayIcon
#SingleInstance, Force
SetBatchLines, -1
SendDiscordMessage(""" msg """, """ wh_url """)

SendDiscordMessage(msg, wh_url)
{
    json_str = {""content"": """ msg """}
    WebClient := ComObjCreate(""WinHttp.WinHttpRequest.5.1"")
    WebClient.Open(""POST"", wh_url, false)
    WebClient.SetRequestHeader(""Content-Type"", ""application/json"")
    WebClient.SetProxy(false)
    WebClient.Send(json_str)
}"
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
