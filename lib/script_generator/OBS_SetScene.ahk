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
global sceneCombo
DetectHiddenWindows, On
IfWinExist, ahk_exe obs64.exe
	new LlamadaWS("ws://127.0.0.1:4455")
global sceneList

Gui Add, Text, x32 y8 w72 h23 +0x200, Scene Name:
Gui Add, Edit, x112 y8 w200 h21 vnombreEscena
Gui Show, w339 h43, Set OBS Scene
return

selectCombo:
	GuiControlGet, sceneCombo,, sceneCombo
	GuiControl,, nombreEscena, % sceneCombo
return

GetOut:
GuiEscape:
GuiClose:
	SkinForm(0)
    ExitApp
	
#If WinActive("Set OBS Scene")
	Enter::
		GuiControlGet, nombreEscena,, nombreEscena
		GuiControlGet, sceneCombo,, sceneCombo
		if(nombreEscena = "")
		{
			MsgBox 0x10, Error, No scene selected!
			return
		}
	else if(workingDir = "")
	{
		workingDir := A_Desktop
	}
	if FileExist(buttonPath)
	{
		OnMessage(0x44, "OnMsgBox")
		MsgBox 0x34, Overwrite?, This button already has a macro file`, do you want to overwrite it?`n`nPrevious function will be lost!
		OnMessage(0x44, "")

		IfMsgBox Yes, {
			Generar(nombreEscena)
		}
	}
	else
	{
		Generar(nombreEscena)
	}
	return
#If
	
Generar(nombreEscena)
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
		Sleep, 250
		Command = 
		`(
		{
		  ""op"": 6,
		  ""d"": {
			""requestType"": ""SetCurrentProgramScene"",
			""requestId"": ""f819dcf0-89cc-11eb-8f0e-382c4ac93b9c"",
			""requestData"": {
			  ""sceneName"": """ nombreEscena """
			}
		  }
		}
		`)
		this.Send(Command)
		nmMsg(""Scene set: " nombreEscena """ )
	}
	
	OnMessage(Event)
	{
		Sleep, 2000
		this.Close()
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
	src .= websocketlibsrc
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
		command =
		(
		{
		  "op": 6,
		  "d": {
			"requestType": "GetSceneList",
			"requestId": "f819dcf0-89cc-11eb-8f0e-382c4ac93b9c"
		  }
		}
		)
		this.Send(command)
	}

	OnMessage(Event)
	{
		respJS := Event.data
		resp := JSON.Load(respJS)
		if(resp.d.requestType == "GetSceneList"){
			combo := ""
			for k, v in resp.d.responseData.scenes
			{
				if(k < resp.d.responseData.scenes.length())
					combo .= v.sceneName "|"
				else
					combo .= v.sceneName
			}
			Gui Add, ComboBox, x112 y8 w200 +0x40 +Sort vsceneCombo gselectCombo, % combo
			GuiControl, Hide, nombreEscena
			this.Close()
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
