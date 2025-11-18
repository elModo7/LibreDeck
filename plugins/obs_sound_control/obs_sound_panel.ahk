; Version 1.0.1
#NoEnv
#SingleInstance, Force
#Persistent
SendMode Input
SetWorkingDir %A_ScriptDir%
Setbatchlines, -1
#Include <cJSON>
#Include <websocket>
#Include <Neutron>
#Include, ..\..\lib\nm_msg.ahk
IfWinNotExist, ahk_exe obs64.exe
{
	nmMsg("OBS Not Detected!",2)
	ExitApp
}
global neutron, sliders

neutron := new NeutronWindow()
neutron.Load("obs_sound_panel.html")
neutron.Gui("+LabelNeutron")
neutron.Show("w1024 h600")
if(WinExist("LibreDeck Client"))
	WinGetPos,X,Y,,,LibreDeck Client
else{
	X := A_ScreenWidth / 2 - 505
	Y := A_ScreenHeight / 2 - 280
}
Gui, Show, w1010 h560 x%X% y%Y%, OBS Sound Panel - elModo7 Soft
global wsCall := new wsCall("ws://127.0.0.1:4455")
return

setMute(unhandledParam := "", source := "", value := "true"){
	wsCall.SetInputMute(sliders[source].name, value ? "true" : "false")
}

setVolume(unhandledParam := "", source := "", value := "0"){
	wsCall.SetInputVolume(sliders[source].name, value/100)
}

closeApp(unhandledParam := ""){
	gosub, ExitSub
}

Esc::
NeutronClose:
GuiClose:
ExitSub:
	ExitApp

class wsCall extends WebSocket
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
			"requestType": "GetSpecialInputs",
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
		if(resp.d.requestType == "GetSpecialInputs"){
			index := 1
			global audioVolIndex := 1
			global audioMuteIndex := 1
			html := ""
			sliders := []
			for k, v in resp.d.responseData
			{
				if(v != "" && !IsObject(v)){
					sliders.Push({name:v})
					html .=
					(
	"<div>
		<div style='font-size:28px; font-family:""Bai Jamjuree""; font-weight:bold'><button class='btn btn_toggle btn-link border-0'><i id=""btn_" index """ class='fa fa-toggle-on ico_toggle text-success' style='font-size:22px;position: relative; transform: scale(1.75); '></i></button>" v "&nbsp;`(<span class=""percentageSpan"" id=""span_" index """>50</span>%`)</div>
		<input id=""slider_" index """ class=""slider"" type=""range"" min=""0"" max=""100"" value=""50"" style=""width:50%; position: relative; transform: scale(2); transform-origin: 0 0;"">
	</div></br></br></br>"
					)
					index++
				}
			}
			neutron.doc.getElementById("main").innerHTML := html
			for k, v in sliders
			{
				this.getInputVolume(v.name)
			}
		}else if(resp.d.requestType == "GetInputVolume"){
			sliders[audioVolIndex].vol := resp.d.responseData.inputVolumeMul
			if(audioVolIndex = sliders.length()){
				for k, v in sliders
				{
					this.GetInputMute(v.name)
				}
			}
			audioVolIndex++
		}else if(resp.d.requestType == "GetInputMute"){
			sliders[audioMuteIndex].mute := resp.d.responseData.inputMuted
			if(audioMuteIndex = sliders.length()){
				for k, v in sliders
				{
					percent := Round(v.vol*100)
					neutron.wnd.setVolumeSlider(k, percent)
					neutron.wnd.setMuteSlider(k, v.mute)
					neutron.wnd.reloadButtonEvents()
				}
			}
			audioMuteIndex++
		}
	}
	
	getInputVolume(nameSource)
	{
		getInputVolume =
		(
		{
		  "op": 6,
		  "d": {
			"requestType": "GetInputVolume",
			"requestId": "f819dcf0-89cc-11eb-8f0e-382c4ac93b9c",
			"requestData": {
			  "inputName": "%nameSource%"
			}
		  }
		}
		)
		this.Send(getInputVolume)
	}
	
	GetInputMute(nameSource)
	{
		GetInputMute =
		(
		{
		  "op": 6,
		  "d": {
			"requestType": "GetInputMute",
			"requestId": "f819dcf0-89cc-11eb-8f0e-382c4ac93b9c",
			"requestData": {
			  "inputName": "%nameSource%"
			}
		  }
		}
		)
		this.Send(GetInputMute)
	}	
	
	SetInputMute(nameSource, value)
	{
		SetInputMute =
		(
		{
		  "op": 6,
		  "d": {
			"requestType": "SetInputMute",
			"requestId": "f819dcf0-89cc-11eb-8f0e-382c4ac93b9c",
			"requestData": {
			  "inputName": "%nameSource%",
			  "inputMuted": %value%
			}
		  }
		}
		)
		this.Send(SetInputMute)
	}	
	
	SetInputVolume(nameSource, value)
	{
		SetInputVolume =
		(
		{
		  "op": 6,
		  "d": {
			"requestType": "SetInputVolume",
			"requestId": "f819dcf0-89cc-11eb-8f0e-382c4ac93b9c",
			"requestData": {
			  "inputName": "%nameSource%",
			  "inputVolumeMul": %value%
			}
		  }
		}
		)
		this.Send(SetInputVolume)
	}
	
	OnClose(Event)
	{
		;this.Disconnect()
	}

	__Delete()
	{
		;~ ExitApp
	}
}

; Neutron's FileInstall Resources
FileInstall, obs_sound_panel.html, obs_sound_panel.html
FileInstall, bootstrap.min.css, bootstrap.min.css
FileInstall, font-awesome.min.css, font-awesome.min.css
FileInstall, bootstrap.min.js, bootstrap.min.js
FileInstall, jquery.min.js, jquery.min.js
FileInstall, fontawesome-webfont.woff, fontawesome-webfont.woff