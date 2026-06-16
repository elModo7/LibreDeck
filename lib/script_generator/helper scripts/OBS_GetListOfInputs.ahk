#NoEnv
#SingleInstance Force
SetBatchLines -1
global  wsCall
DetectHiddenWindows, On
IfWinExist, ahk_exe obs64.exe
	wsCall := new LlamadaWS("ws://127.0.0.1:4455")
return

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
		GetInputList =
		(
		{
		  "op": 6,
		  "d": {
			"requestType": "GetInputList",
			"requestId": "f819dcf0-89cc-11eb-8f0e-382c4ac93b9c"
		  }
		}
		)
		this.Send(GetInputList)
	}

	OnMessage(Event)
	{
		respJS := Event.data
		resp := JSON.Load(respJS)
		if(resp.d.requestType == "GetInputList"){
			combo := "Normal Inputs:`n`n"
			for k, v in resp.d.responseData.inputs
			{
				if(k < resp.d.responseData.inputs.length())
					combo .= v.inputName "`n"
				else
					combo .= v.inputName
			}
			MsgBox % combo
			this.getSpecialInputs()
		}
		else if(resp.d.requestType == "GetSpecialInputs"){
			combo := "Special Inputs:`n`n"
			index := 1
			for k, v in resp.d.responseData
			{
				if(index < resp.d.responseData.GetCapacity())
					combo .= k ": " v "`n"
				else
					combo .= k ": " v
				index++
			}
			MsgBox % combo
			this.Disconnect()
			this.Close()
			ExitApp
		}
	}
	
	getSpecialInputs(){
		GetSpecialInputs =
		(
		{
		  "op": 6,
		  "d": {
			"requestType": "GetSpecialInputs",
			"requestId": "f819dcf0-89cc-11eb-8f0e-382c4ac93b9c"
		  }
		}
		)
		this.Send(GetSpecialInputs)
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

SkinForm(Param1 = "Apply", DLL = "", SkinName = ""){
	if(Param1 = Apply){
		DllCall("LoadLibrary", str, DLL)
		DllCall(DLL . "\USkinInit", Int,0, Int,0, AStr, SkinName)
	}else if(Param1 = 0){
		DllCall(DLL . "\USkinExit")
	}
}

#Include ..\lib\JSON.ahk
#Include ..\lib\websocket.ahk