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
global sceneCombo, sourceCombo, wsCall
DetectHiddenWindows, On
IfWinExist, ahk_exe obs64.exe
	wsCall := new LlamadaWS("ws://127.0.0.1:4455")
global sceneList

Gui Add, Text, x32 y8 w72 h23 +0x200, Scene Name:
Gui Add, Edit, x112 y8 w200 h21 vscene
Gui Add, ComboBox, x112 y8 w200 vsceneCombo gselectComboScene Hidden +Sort,
Gui Add, Text, x32 y40 w72 h23 +0x200, Source Name:
Gui Add, Edit, x112 y40 w200 h21 vsource
Gui Add, ComboBox, x112 y40 w200 +0x40 vsourceCombo gselectComboSource Hidden +Sort, % comboItems
Gui Add, Radio, x32 y72 w120 h23 vshow checked, Show Source
Gui Add, Radio, x160 y72 w120 h23 vhide, Hide Source

Gui Show, w339 h96, Hide / Show Source
return

selectComboScene:
	GuiControlGet, sceneCombo,, sceneCombo
	GuiControl,, scene, % sceneCombo
	wsCall.getSceneItems(sceneCombo)
return

selectComboSource:
	GuiControlGet, sourceCombo,, sourceCombo
	GuiControl,, source, % sourceCombo
return

GetOut:
GuiEscape:
GuiClose:
	SkinForm(0)
    ExitApp
	
#If WinActive("Hide / Show Source")
	Enter::
		GuiControlGet, scene,, scene
		GuiControlGet, source,, source
		GuiControlGet, show,, show
		if(source = "")
		{
			MsgBox 0x10, Error, No source selected!
			return
		}else if(scene = "")
		{
			MsgBox 0x10, Error, No scene selected!
			return
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
				Generar(scene, source, visibility)
			}
		}
		else
		{
			Generar(scene, source, visibility)
		}
	return
#If
	
Generar(scene, sourceName, visibility)
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
		GetSceneItemId =
		`(
		{
		  ""op"": 6,
		  ""d"": {
			""requestType"": ""GetSceneItemId"",
			""requestId"": ""f819dcf0-89cc-11eb-8f0e-382c4ac93b9c"",
			""requestData"": {
			  ""sceneName"": """ scene """,
			  ""sourceName"": """ sourceName """
			}
		  }
		}
		`)
		this.Send(GetSceneItemId)
	}
	
	OnMessage(Event)
	{
		respJS := Event.data
		resp := JSON.Load(respJS)
		if(resp.d.requestType == ""GetSceneItemId""){
			itemId := resp.d.responseData.sceneItemId
			command =
			`(
			{
			  ""op"": 6,
			  ""d"": {
				""requestType"": ""SetSceneItemEnabled"",
				""requestId"": ""f819dcf0-89cc-11eb-8f0e-382c4ac93b9c"",
				""requestData"": {
				  ""sceneName"": """ scene """,
				  ""sceneItemId"": %itemId%,
				  ""sceneItemEnabled"": " visibility "
				}
			  }
			}
			`)
			this.Send(command)
			this.Close()
			nmMsg(""Item visibility: " visibility """)
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
			"requestType": "GetSceneList",
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
		if(resp.d.requestType == "GetSceneList"){
			combo := ""
			for k, v in resp.d.responseData.scenes
			{
				if(k < resp.d.responseData.scenes.length())
					combo .= v.sceneName "|"
				else
					combo .= v.sceneName
			}
			GuiControl,, sceneCombo, % combo
			GuiControl, Show, sceneCombo
			GuiControl, Hide, scene
		}else if(resp.d.requestType == "GetSceneItemList"){
			comboItems := ""
			for k, v in resp.d.responseData.sceneItems
			{
				if(k < resp.d.responseData.sceneItems.length())
					comboItems .= v.sourceName "|"
				else
					comboItems .= v.sourceName
			}
			GuiControl,, sourceCombo, % "|" comboItems ; First pipe is to flush items before insert
			GuiControl, Show, sourceCombo
			GuiControl, Hide, source
		}
	}
	
	GetSceneItems(sceneName)
	{
		GetSceneItemList =
		(
		{
		  "op": 6,
		  "d": {
			"requestType": "GetSceneItemList",
			"requestId": "f819dcf0-89cc-11eb-8f0e-382c4ac93b9c",
			  "requestData": {
			  "sceneName": "%sceneName%"
			}
		  }
		}
		)
		this.Send(GetSceneItemList)
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
