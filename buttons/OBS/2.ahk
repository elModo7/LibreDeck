#NoEnv
#NoTrayIcon
#SingleInstance, Force
SetBatchLines, -1
#Include %A_WorkingDir%\lib\nm_msg.ahk
DetectHiddenWindows, On
global willDelete := false
IfWinNotExist, ahk_exe obs64.exe
{
	nmMsg("OBS Not Detected!",2)
	ExitApp
}
new LlamadaWS("ws://127.0.0.1:4455")
return

class LlamadaWS extends WebSocket
{
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
		Sleep, 250
		Command =
		(
		{
		  "op": 6,
		  "d": {
			"requestType": "StopRecord",
			"requestId": "f819dcf0-89cc-11eb-8f0e-382c4ac93b9c"
		  }
		}
		)
		this.Send(Command)
		nmMsg("Recording stopped")
		MsgBox 0x34, Keep Video?, Do you want to keep last video you recorded?

		IfMsgBox No, {
			willDelete := true
		}
	}

	OnMessage(Event)
	{
		Sleep, 2000
		this.Close()
	}

	OnClose(Event)
	{
		this.Disconnect()
		if (willDelete) {
			Loop, Files, V:\VIDEO\*.mp4
			{
				if(newest < A_LoopFileTimeCreated)
				{
					newest := A_LoopFileTimeCreated
					fileToDelete := A_LoopFileFullPath
				}
			}
			FileDelete, %fileToDelete%
		}
		ExitApp
	}

	__Delete()
	{
		ExitApp
	}
}

; ************************
; WEB SOCKET STUFF
; ************************
class WebSocket
{
	__New(WS_URL)
	{
		static wb

		; Create an IE instance
		Gui, +hWndhOld
		Gui, New, +hWndhWnd
		this.hWnd := hWnd
		Gui, Add, ActiveX, vWB, Shell.Explorer
		Gui, %hOld%: Default

		; Write an appropriate document
		WB.Navigate("about:<!DOCTYPE html><meta http-equiv='X-UA-Compatible'"
		. "content='IE=edge'><body></body>")
		while (WB.ReadyState < 4)
			sleep, 50
		this.document := WB.document

		; Add our handlers to the JavaScript namespace
		this.document.parentWindow.ahk_savews := this._SaveWS.Bind(this)
		this.document.parentWindow.ahk_event := this._Event.Bind(this)
		this.document.parentWindow.ahk_ws_url := WS_URL

		; Add some JavaScript to the page to open a socket
		Script := this.document.createElement("script")
		Script.text := "ws = new WebSocket(ahk_ws_url);"

		. "ws.onopen = function(event){ ahk_event('Open', event); };"

		. "ws.onclose = function(event){ ahk_event('Close', event); };"

		. "ws.onerror = function(event){ ahk_event('Error', event); };"

		. "ws.onmessage = function(event){ ahk_event('Message', event); };"
		this.document.body.appendChild(Script)
	}

	; Called by the JS in response to WS events
	_Event(EventName, Event)
	{
		this["On" EventName](Event)
	}

	; Sends data through the WebSocket
	Send(Data)
	{
		this.document.parentWindow.ws.send(Data)
	}

	; Closes the WebSocket connection
	Close(Code:=1000, Reason:="")
	{
		this.document.parentWindow.ws.close(Code, Reason)
	}

	; Closes and deletes the WebSocket, removing
	; references so the class can be garbage collected
	Disconnect()
	{
		if this.hWnd
		{
			this.Close()
			Gui, % this.hWnd ": Destroy"
			this.hWnd := False
		}
	}
}