; Necesita el plugin WebSockets OBS
; Recoge los datos de sonido y los muestra al inicio, se pueden cambiar una vez iniciado el programa
#SingleInstance, Force
#NoTrayIcon
CoordMode,Mouse,Screen
DetectHiddenWindows, On
#Include, plugins\nm_msg.ahk
WinGetPos,X,Y,,,LibreDeck Client
IfWinNotExist, ahk_exe obs64.exe
{
	nmMsg("OBS Not Detected!",2)
	ExitApp
}
X := X+825
global Demo_Slider_1 , DS1Edit , pSlider := []
global Demo_Slider_2 , DS2Edit
global volEscritorio, muteEscritorio, volMic, muteMic, imgMuteDesktop, imgMuteMic, Volumen
new getDesktopVol("ws://127.0.0.1:4444")
new getMicVol("ws://127.0.0.1:4444")

Gui,1:-DPIScale -Caption +ToolWindow +AlwaysOnTop
Gui,1:Color,333333
Gui,1:Font,s10 w600

Gui Font, c0xFFFFFF
Gui,1:Add,Text,x5 y10 w80 h17 -E0x200 Center,Escritorio
pSlider[1]:= New Progress_Slider("1","Demo_Slider_1",15,50,60,200,0,100,100,"555555","Green",1,"DS1Edit",0,1)
Gui,1:Add,Text,x20 y30 w50 h17 -E0x200 Center vDS1Edit ,100
Gui,1:Add,Text,x105 y10 w80 h17 -E0x200 Center,Micrófono
pSlider[2]:= New Progress_Slider("1","Demo_Slider_2",115,50,60,200,0,100,100,"555555","Green",1,"DS2Edit",0,1)
Gui,1:Add,Text,x120 y30 w50 h17 -E0x200 Center vDS2Edit ,100
Gui Add, Picture, gtoggleMuteDesktop vimgMuteDesktop x16 y248 w60 h60, img\on.png
Gui Add, Picture, gtoggleMuteMic vimgMuteMic x115 y248 w60 h60, img\on.png
Gui Font, s36 c0xCC0000
Gui,1:Add,Text,x0 y300 w200 h50 -E0x200 Center gSalir,SALIR
gosub, setVolumeImgs
gosub, setVolumeValues
Gui,1:Show, w200 x%X% y%Y% NoActivate, OBS Sound Panel
return

Salir:
GuiClose:
GuiContextMenu:
	MouseMove, 1280, 540, 0
	ExitApp
	
setVolumeImgs:
	Sleep, 1000
	if(muteMic){
		GuiControl,Text,imgMuteMic,img\off.png
	}else{
		GuiControl,Text,imgMuteMic,img\on.png
	}
	if(muteEscritorio){
		GuiControl,Text,imgMuteDesktop,img\off.png
	}else{
		GuiControl,Text,imgMuteDesktop,img\on.png
	}
return

setVolumeValues:
	MouseMove, 1280, 540, 0
	StringReplace, volEscritorio,volEscritorio, `n,, All
	StringReplace, volMic,volMic, `n,, All
	if(Trim(volEscritorio) <= 1){
		GuiControl,Text,DS1Edit,% Floor(volEscritorio * 100)
		GuiControl,Text,Demo_Slider_1,% volEscritorio * 100
	}
	if(volMic <= 1){
		GuiControl,Text,DS2Edit,% Floor(volMic * 100)
		GuiControl,Text,Demo_Slider_2,% volMic * 100
	}
	SetearColoresBarrasEscritorio(volEscritorio * 100)
	SetearColoresBarrasMic(volMic * 100)
return
	
toggleMuteDesktop:
	MouseMove, 1280, 540, 0
	muteEscritorio := !muteEscritorio
	if(muteEscritorio){
		GuiControl,Text,imgMuteDesktop,img\off.png
		Run, plugins\OBS_mute_desktop.ahk
	}else{
		GuiControl,Text,imgMuteDesktop,img\on.png
		Run, plugins\OBS_unmute_desktop.ahk
	}
return

toggleMuteMic:
	MouseMove, 1280, 540, 0
	muteMic := !muteMic
	if(muteMic){
		GuiControl,Text,imgMuteMic,img\off.png
		Run, plugins\OBS_mute_mic.ahk
	}else{
		GuiControl,Text,imgMuteMic,img\on.png
		Run, plugins\OBS_unmute_mic.ahk
	}
return

SetearColoresBarrasEscritorio(valor)
{
	if(valor <= 20){
		GuiControl,+cBB0000,Demo_Slider_1
	}else if(valor <= 55){
		GuiControl,+cFF681F,Demo_Slider_1
	}else if(valor <= 80){
		GuiControl,+cFFDD00,Demo_Slider_1
	}else if(valor <= 100){
		GuiControl,+cGreen,Demo_Slider_1
	}
}

SetearColoresBarrasMic(valor)
{
	if(valor <= 20){
		GuiControl,+cBB0000,Demo_Slider_2
	}else if(valor <= 55){
		GuiControl,+cFF681F,Demo_Slider_2
	}else if(valor <= 80){
		GuiControl,+cFFDD00,Demo_Slider_2
	}else if(valor <= 100){
		GuiControl,+cGreen,Demo_Slider_2
	}	
}


AdjustSlider1:
	MouseMove, 1280, 540, 0
	(A_GuiControl="Sub5")?(pSlider[1].Slider_Value-=5):(A_GuiControl="Sub1")?(pSlider[1].Slider_Value-=1):(A_GuiControl="Add1")?(pSlider[1].Slider_Value+=1):(A_GuiControl="Add5")?(pSlider[1].Slider_Value+=5)
	(pSlider[1].Slider_Value > pSlider[1].End_Range)?(pSlider[1].SET_pSlider(pSlider[1].End_Range)):(pSlider[1].Slider_Value < pSlider[1].Start_Range)?(pSlider[1].SET_pSlider(pSlider[1].Start_Range)):(pSlider[1].SET_pSlider(pSlider[1].Slider_Value))
	return
	
class Progress_Slider	{
	__New(pSlider_GUI_NAME , pSlider_Control_ID , pSlider_X , pSlider_Y , pSlider_W , pSlider_H , pSlider_Range_Start , pSlider_Range_End , pSlider_Value:=0 , pSlider_Background_Color := "Black" , pSlider_Top_Color := "Red" , pSlider_Pair_With_Edit := 0 , pSlider_Paired_Edit_ID := "" , pSlider_Use_Tooltip := 0 ,  pSlider_Vertical := 0 , pSlider_Smooth := 1){
		This.GUI_NAME:=pSlider_GUI_NAME
		This.Control_ID:=pSlider_Control_ID
		This.X := pSlider_X
		This.Y := pSlider_Y
		This.W := pSlider_W
		This.H := pSlider_H
		This.Start_Range := pSlider_Range_Start
		This.End_Range := pSlider_Range_End
		This.Slider_Value := pSlider_Value
		This.Background_Color := pSlider_Background_Color
		This.Top_Color := pSlider_Top_Color
		This.Vertical := pSlider_Vertical
		This.Smooth := pSlider_Smooth
		This.Pair_With_Edit := pSlider_Pair_With_Edit
		This.Paired_Edit_ID := pSlider_Paired_Edit_ID
		This.Use_Tooltip := pSlider_Use_Tooltip
		This.Add_pSlider()
	}
	Add_pSlider(){
		Gui, % This.GUI_NAME ":Add" , Text , % "x" This.X " y" This.Y " w" This.W " h" This.H " hwndpSliderTriggerhwnd"
		pSlider_Trigger := This.Adjust_pSlider.BIND( THIS ) 
		GUICONTROL +G , %pSliderTriggerhwnd% , % pSlider_Trigger
		if(This.Smooth=1&&This.Vertical=0)
			Gui, % This.GUI_NAME ":Add" , Progress , % "x" This.X " y" This.Y " w" This.W " h" This.H " Background" This.Background_Color " c" This.Top_Color " Range" This.Start_Range "-" This.End_Range  " v" This.Control_ID ,% This.Slider_Value
		else if(This.Smooth=0&&This.Vertical=0)
			Gui, % This.GUI_NAME ":Add" , Progress , % "x" This.X " y" This.Y " w" This.W " h" This.H " -Smooth Range" This.Start_Range "-" This.End_Range  " v" This.Control_ID ,% This.Slider_Value
		else if(This.Smooth=1&&This.Vertical=1)
			Gui, % This.GUI_NAME ":Add" , Progress , % "x" This.X " y" This.Y " w" This.W " h" This.H " Background" This.Background_Color " c" This.Top_Color " Range" This.Start_Range "-" This.End_Range  " Vertical v" This.Control_ID ,% This.Slider_Value
		else if(This.Smooth=0&&This.Vertical=1)
			Gui, % This.GUI_NAME ":Add" , Progress , % "x" This.X " y" This.Y " w" This.W " h" This.H " -Smooth Range" This.Start_Range "-" This.End_Range  " Vertical v" This.Control_ID ,% This.Slider_Value
	}
	Adjust_pSlider(){
		global pSlider_Temp_Yo, pSlider_Temp_Xo
		CoordMode,Mouse,Client
		while(GetKeyState("LButton")){
			MouseGetPos,pSlider_Temp_X,pSlider_Temp_Y
			if(pSlider_Temp_X != pSlider_Temp_Xo || pSlider_Temp_Y != pSlider_Temp_Yo)
			{
				if(This.Vertical=0)
					This.Slider_Value := Round((pSlider_Temp_X - This.X ) / ( This.W / (This.End_Range - This.Start_Range) )) + This.Start_Range
				else
					This.Slider_Value := Round(((pSlider_Temp_Y - This.Y ) / ( This.H / (This.End_Range - This.Start_Range) )) + This.Start_Range )* -1 + This.End_Range
				if(This.Slider_Value > This.End_Range )
					This.Slider_Value:=This.End_Range
				else if(This.Slider_Value<This.Start_Range)
					This.Slider_Value:=This.Start_Range
				GuiControl,% This.GUI_NAME ":" ,% This.Control_ID , % This.Slider_Value 
				if(This.Pair_With_Edit=1)
					GuiControl,% This.GUI_NAME ":" ,% This.Paired_Edit_ID , % This.Slider_Value 
				if(This.Use_Tooltip=1)
					ToolTip , % This.Slider_Value 
				if(This.Paired_Edit_ID = "DS1Edit") ; Logica barra1
				{
					SetearColoresBarrasEscritorio(This.Slider_Value)
				}
				else if(This.Paired_Edit_ID = "DS2Edit") ; Logica barra2
				{
					SetearColoresBarrasMic(This.Slider_Value)
				}
				Volumen := This.Slider_Value / 100 ; Volumen de 0.0 a 1.0
				if(This.Paired_Edit_ID = "DS1Edit") ; Logica barra1
				{
					SetTimer, SetearVolumenEscritorio, 333
				}
				else if(This.Paired_Edit_ID = "DS2Edit") ; Logica barra2
				{
					SetTimer, SetearVolumenMicrofono, 333
				}
			}
			pSlider_Temp_Xo := pSlider_Temp_X
			pSlider_Temp_Yo := pSlider_Temp_Y
		}
		if(This.Use_Tooltip=1)
			ToolTip,
	}
	SET_pSlider(NEW_pSlider_Value){
		This.Slider_Value := NEW_pSlider_Value
		GuiControl,% This.GUI_NAME ":" ,% This.Control_ID , % This.Slider_Value
		if(This.Pair_With_Edit=1)
			GuiControl,% This.GUI_NAME ":" ,% This.Paired_Edit_ID , % This.Slider_Value
	}
}

class getDesktopVol extends WebSocket
{
	OnOpen(Event)
	{
		Sleep, 100
		Data = {"source": "Audio del escritorio","request-type": "GetVolume","message-id": "123"}
		this.Send(Data)
	}
	
	OnMessage(Event)
	{
		volEscritorio := SubStr(Event.Data, InStr(Event.Data, "volume")+9, 4)
		muteEscritorio := SubStr(Event.Data, InStr(Event.Data, "mute")+8, 1) = "t" ? 1 : 0 ; f/t false/true
		;~ MsgBox, Vol: %volEscritorio%`nMuted: %muteEscritorio%
		;~ MsgBox, % Event.Data
		this.Close()
	}
	
	OnClose(Event)
	{
		this.Disconnect()
	}
	
	__Delete()
	{
		this.Disconnect()
	}
}

class getMicVol extends WebSocket
{
	OnOpen(Event)
	{
		Sleep, 100
		Data = {"source": "Mic/Aux","request-type": "GetVolume","message-id": "123"}
		this.Send(Data)
	}
	
	OnMessage(Event)
	{
		volMic := SubStr(Event.Data, InStr(Event.Data, "volume")+9, 4)
		muteMic := SubStr(Event.Data, InStr(Event.Data, "mute")+8, 1) = "t" ? 1 : 0 ; f/t false/true
		;~ MsgBox, Vol: %volMic%`nMuted: %muteMic%
		;~ MsgBox, % Event.Data
		this.Close()
	}
	
	OnClose(Event)
	{
		this.Disconnect()
	}
	
	__Delete()
	{
		this.Disconnect()
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
		Script.text := "ws = new WebSocket(ahk_ws_url);`n"
		. "ws.onopen = function(event){ ahk_event('Open', event); };`n"
		. "ws.onclose = function(event){ ahk_event('Close', event); };`n"
		. "ws.onerror = function(event){ ahk_event('Error', event); };`n"
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

SetearVolumenEscritorio:
	SetTimer, SetearVolumenEscritorio, Off
	Run, plugins\OBS_escritorio.ahk %Volumen%
return

SetearVolumenMicrofono:
	SetTimer, SetearVolumenMicrofono, Off
	Run, plugins\OBS_microfono.ahk %Volumen%
return
