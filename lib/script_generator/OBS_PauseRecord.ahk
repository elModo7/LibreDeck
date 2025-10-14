﻿#NoEnv
#SingleInstance Force
SetBatchLines -1
#NoTrayIcon
global buttonName = %0% 
global buttonPath := buttonName ".ahk"
Generar()
return

Generar()
{
	src :=
	(
"#NoEnv
#NoTrayIcon
#SingleInstance, Force
SetBatchLines, -1
#Include, <nm_msg>
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
			""requestType"": ""PauseRecord"",
			""requestId"": ""f819dcf0-89cc-11eb-8f0e-382c4ac93b9c""
		  }
		}
		`)
		this.Send(Command)
		nmMsg(""Recording paused"")
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

#Include <websocket>