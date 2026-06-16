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
global inputsCombo, wsCall
DetectHiddenWindows, On
IfWinExist, ahk_exe obs64.exe
	wsCall := new LlamadaWS("ws://127.0.0.1:4455")
global sceneList

Gui Add, Text, x32 y8 w72 h23 +0x200, Input Name:
Gui Add, Edit, x112 y8 w200 h21 vinput
Gui Add, ComboBox, x112 y8 w200 +0x40 vinputsCombo gselectInput Hidden +Sort,
Gui Add, Radio, x32 y72 w120 h23 vmute checked, Mute Source
Gui Add, Radio, x160 y72 w120 h23 vunmute, Unmute Source

Gui Show, w339 h96, Mute/Unmute Source
return

selectInput:
	GuiControlGet, inputsCombo,, inputsCombo
	GuiControl,, input, % inputsCombo
	wsCall.getSceneItems(sceneCombo)
return

GetOut:
GuiEscape:
GuiClose:
	SkinForm(0)
    ExitApp

#If WinActive("Mute/Unmute Source")
	Enter::
		GuiControlGet, input,, input
		GuiControlGet, mute,, mute
		if(input = "")
		{
			MsgBox 0x10, Error, No input selected!
			return
		}
	else if(workingDir = "")
	{
		workingDir := A_Desktop
	}
	muteStatus := "false"
	if(mute){
		muteStatus := "true"
	}
	if FileExist(buttonPath)
	{
		OnMessage(0x44, "OnMsgBox")
		MsgBox 0x34, Overwrite?, This button already has a macro file`, do you want to overwrite it?`n`nPrevious function will be lost!
		OnMessage(0x44, "")

		IfMsgBox Yes, {
			Generar(input, muteStatus)
		}
	}
	else
	{
		Generar(input, muteStatus)
	}
	return
#If
	
Generar(inputName, muteStatus)
{
	src :=
	(
"#NoEnv
#NoTrayIcon
#SingleInstance, Force
SetBatchLines, -1
#Include %A_WorkingDir%\lib\nm_msg.ahk
DetectHiddenWindows, On
IfWinNotExist, ahk_exe obs64.exe
{
	nmMsg(""OBS Not Detected!"",2)
	ExitApp
}
new LlamadaWS(""ws://127.0.0.1:4455"")
return

class LlamadaWS extends WebSocket
{
	OnOpen(Event)
	{
		Authenticate =
		`(
		{
		  ""op"": 1,
		  ""d"": {
			""rpcVersion"": 1,
			""eventSubscriptions"": 33
		  }
		}
		`)
		this.Send(Authenticate)
		command =
		`(
		{
		  ""op"": 6,
		  ""d"": {
			""requestType"": ""SetInputMute"",
			""requestId"": ""f819dcf0-89cc-11eb-8f0e-382c4ac93b9c"",
			""requestData"": {
			  ""inputName"": """ inputName """,
			  ""inputMuted"": " muteStatus "
			}
		  }
		}
		`)
		this.Send(command)
		nmMsg(""Source mute status: " muteStatus """)
	}
	
	OnMessage(Event)
	{
		respJS := Event.data
		resp := JSON.Load(respJS)
		if(resp.d.requestType == ""SetInputMute""){
			this.Close()
		}
	}
	
	OnClose(Event)
	{
		this.Disconnect()
		ExitApp
	}
	
	__Delete()
	{
		ExitApp
	}
}

"
	)
	FileRead, websocketlibsrc, ./lib/script_generator/lib/websocket.ahk
	src .= websocketlibsrc "`n"
	FileRead, jsonlibsrc, ./lib/script_generator/lib/JSON.ahk
	src .= jsonlibsrc
	FileDelete, % buttonPath
	FileAppend, %src%, % buttonPath
	ExitApp
}

class LlamadaWS extends WebSocket
{
	itemId := 0
	OnOpen(Event)
	{
		Authenticate =
		(
		{
		  "op": 1,
		  "d": {
			"rpcVersion": 1,
			"eventSubscriptions": 33
		  }
		}
		)
		this.Send(Authenticate)
		sleep, 250
		GetSceneList =
		(
		{
		  "op": 6,
		  "d": {
			"requestType": "GetInputList",
			"requestId": "f819dcf0-89cc-11eb-8f0e-382c4ac93b9c"
		  }
		}
		)
		this.Send(GetSceneList)
	}

	OnMessage(Event)
	{
		respJS := Event.data
		resp := JSON.Load(respJS)
		if(resp.d.requestType == "GetInputList"){
			combo := ""
			for k, v in resp.d.responseData.inputs
			{
				if(k < resp.d.responseData.inputs.length())
					combo .= v.inputName "|"
				else
					combo .= v.inputName
			}
			GuiControl,, inputsCombo, % combo
			GuiControl, Show, inputsCombo
			GuiControl, Hide, input
			this.Disconnect()
		}
	}
	
	OnClose(Event)
	{
		;~ this.Disconnect()
		;~ ExitApp
	}

	__Delete()
	{
		ExitApp
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

#Include <JSON>
#Include <websocket>
