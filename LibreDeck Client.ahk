; OS Version ...: Windows 10+ (Previous versions tested working on Win7)
; Requires AutoHotkeyU32
;@Ahk2Exe-SetName LibreDeck Client
;@Ahk2Exe-SetDescription LibreDeck for TouchScreen and Remote Control
;@Ahk2Exe-SetVersion 3.8.7
;@Ahk2Exe-SetCopyright Copyright (c) 2025`, elModo7 - VictorDevLog
;@Ahk2Exe-SetOrigFilename LibreDeck Client.exe
; INITIALIZE
; *******************************
/*
TODO:
- Reactive window configurer GUI (Program Selector, Page Selector)
- Más funciones de OBS
- BtnDescriptions (label con texto de descripción (texto, color, transparencia, fontweight))

REQUIERES:
- Windows 10
- AutoHotkey U32 (las librerías JSON y them.dll no funcionan en U64)
- Compilar sin MPRESS, se pierde compatibilidad con USkin.dll
- Notification System ONLY works when compiled

DISCARDED:
- Volver a la carpeta anterior y volver a la raíz si se pulsa p.ej control

LATEST CHANGES:
- OBS Websocket Compat 4.x -> 5.X
- Improve online mode
- Add dynamic buttons (3.7.6+)
- Add notifications integration (same machine via talk.ahk) (3.7.6+)
- Add remote icon, background changes (3.8.1+)
- Add spotify integration (3.8.2+) -> https://github.com/CloakerSmoker/Spotify.ahk

COMMENTS:
- This script is one of my very first AutoHotkey scripts (Jun 2017), it can be improved A LOT, code quality wise (starting from keeping it consistent with a single language instead of Spanglish). However, I use it on a day to day basis and it is "robust enough" and convenient that I make heavy use of it, even above any other Hotkey, Dedicated Keyboard, Macro Deck, StreamDock or Android solutions I currently have purchased.
- It packs a few libraries of my own and a few "hacky" resources. While doing it I learned A LOT on GUI optimisations such as double buffering, temporal GUI freezing, image in-memory caching for quick updates, autoupdating scripts, Config, Sockets, WebSockets, OSC protocol, theming, GDI, Win32 API, HTTP OBJ, encryption, base 64 resources, queuing...
- It gave birth to many snippets for other projects such as OBS Control via WebSockets, OBSBOT Gimbal Webcams control via OSC, SplashScreen and About generic GUI snippets, ClientUpdater lib, Installer Generator, Obfuscation (removed), Online Licensing (removed).
*/
#NoEnv
#Persistent
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
DetectHiddenWindows, On
CoordMode,Mouse,Screen
SetBatchLines, -1
#Include, <JSON>
#Include <SplashScreen>
#Include <Socket>
#Include <util>
#Include <client_updater>
#Include <aboutScreen>
#Include <talk>
#Include <plugin_system>
rutaSplash = ./resources/img/splash.png
global ClientVersionNumber := "3.8.7"
global ClientVersion := ClientVersionNumber " - elModo7 / VictorDevLog " A_YYYY
SplashScreen(rutaSplash, 3000, 545, 160, 0, 0, true)
global EsVisible = true
global EnCarpeta = false
global CarpetaBoton, PaginaCarpeta, BotonActivo, BotonAPulsar, windowHandler, IpTxt, PortTxt, OnlineChk, AHK_ICONCLICKCOUNT, server_config, previousActiveProcess
global RutaBoton1, RutaBoton2, RutaBoton3, RutaBoton4, RutaBoton5, RutaBoton6, RutaBoton7, RutaBoton8, RutaBoton9, RutaBoton10, RutaBoton11, RutaBoton12, RutaBoton13, RutaBoton14, RutaBoton15
global feedbackEjecucion := []
global plugins := []
global NumeroPagina := 0
global serverFound := 0
global reactiveWindow := 0
global MsgBoxBtn1, MsgBoxBtn2, MsgBoxBtn3, MsgBoxBtn4
SkinForm(Apply, A_ScriptDir . "\lib\script_generator\lib\them.dll", A_ScriptDir . "\lib\script_generator\lib\tm")
OnExit, GetOut
FileCreateDir, conf
global btnPics := {}
GuiControl, splashScreen:, splashTxt, % "Reading config..."
contextcolor(2) ;0=Default ;1=AllowDark ;2=ForceDark ;3=ForceLight ;4=Max

; Talk (WM_COPYDATA) params
global incomingNotification := {"text": "", "duration": 1000, "region": "top"} ; Notification System
global incomingButtonChange := {"imagePathOrName": "", "buttonId": 14}
global incomingBackgroundChange := {"imagePathOrName": ""}
global incomingPageChange := {"pageNumber": 0, "isFolder": 0, "folderName": ""}

if(!FileExist("./conf/config.json"))
{
	GuiControl, splashScreen:, splashTxt, % "Config not found, creating new config..."
	conf := {}
	conf.programFolder["obs64.exe"] := "obs"
	conf.programFolder["SciTE.exe"] := "ahk"
	conf.scriptEditorPath := "C:\Program Files\AutoHotkey\SciTE\SciTE.exe"
	conf.ip := "127.0.0.1"
	conf.port := "7778"
	conf.resourcesPort := "7779"
	conf.extension := "ahk"
	conf.folderButtons := {"5":"OBS"}
	conf.folderButtons.1 := "UtilesStream"
	conf.folderButtons.2 := "SonidosOBS"
	conf.folderButtons.3 := "VoiceMod"
	conf.folderButtons.6 := "App"
	conf.folderButtons.7 := "Game"
	conf.folderButtons.4 := "Magix"
	conf.folderButtons.8 := "AHK"
	conf.pantalla_Mitad_X := A_ScreenWidth / 2
	conf.pantalla_Mitad_Y := A_ScreenHeight / 2
	conf.x_Inicial := 960
	conf.y_Inicial := 1080
	conf.moverRatonAlPulsarBoton := 1
	conf.enviarAltTabAlPulsarBoton := 1
	conf.cargaProgresivaIconos := 0
	conf.siempreVisible := 0
	conf.miniClient := 0
	conf.online := 0
	conf.builtin_ahk := 1
	conf.reactiveWindow := 0
	conf.lookForUpdates := 1
	gosub, guardarConfig
}

gosub, loadConfig
GuiControl, splashScreen:, splashTxt, % "Creating Tray & Context Menus..."

; dark mode menu options
contextcolor(color:=2) ; change the number here from the list above if you want light mode
{
	static uxtheme := DllCall("GetModuleHandle", "str", "uxtheme", "ptr")
	static SetPreferredAppMode := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 135, "ptr")
	static FlushMenuThemes := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 136, "ptr")
	DllCall(SetPreferredAppMode, "int", color)
	DllCall(FlushMenuThemes)
}
; TRAY MENU
; *******************************
Menu, tray, NoStandard
Menu, tray, tip, LibreDeck Client v%ClientVersionNumber%
Menu, tray, add, Run LibreDeck server, runServer
Menu tray, Icon, Run LibreDeck server, .\resources\img\ico\libredeck.ico
Menu, tray, add, Hide, ToggleHide
Menu tray, Icon, Hide, .\resources\img\ico\windows\cut_visibility.ico
Menu, tray, add, Set Editor Path, CambiarRutaEditor
Menu tray, Icon, Set Editor Path, .\resources\img\ico\windows\edit2.ico
Menu tray, add, Set Start Window Possition, setStartPossition
Menu tray, Icon, Set Start Window Possition, .\resources\img\ico\windows\window_possition.ico
Menu tray, add, Backup LibreDeck Folder (*.7z), generateBackup
Menu tray, Icon, Backup LibreDeck Folder (*.7z), .\resources\img\ico\windows\compressed_folder.ico
Menu tray, add, Open LibreDeck Folder, openLibreDeckFolder
Menu tray, Icon, Open LibreDeck Folder, .\resources\img\ico\windows\folder.ico
Menu, tray, add
Menu, tray, add, Network Settings, crearGuiNetworkSettings
Menu tray, Icon, Network Settings, .\resources\img\ico\windows\network2.ico
Menu, tray, add
Menu LookForUpdatesMenu, Add, On Boot, lookForUpdatesOnBootLabel
Menu LookForUpdatesMenu, Icon, On Boot, .\resources\img\ico\windows\look_for_updates.ico
Menu LookForUpdatesMenu, Add, Now, lookForUpdatesLabel
Menu LookForUpdatesMenu, Icon, Now, .\resources\img\ico\windows\download.ico
Menu tray, Add, Look for Updates, :LookForUpdatesMenu
Menu tray, Icon, Look for Updates, .\resources\img\ico\windows\refresh.ico

Menu, tray, add, % "v" ClientVersion, showAboutScreen
Menu tray, Icon, % "v" ClientVersion, .\resources\img\ico\windows\info.ico
;~ Menu, tray, disable, % "v" ClientVersion
Menu, tray, add, Exit, Exit
Menu tray, Icon, Exit, .\resources\img\ico\windows\close3.ico

if(conf.lookForUpdates)
	Menu LookForUpdatesMenu, Check, On Boot
else
	Menu LookForUpdatesMenu, UnCheck, On Boot

; CONTEXT MENU GENERICO
; *******************************
Menu ContextMenuGenerico, Add, Always on Top, SiempreVisible
if(conf.siempreVisible)
{
	Menu ContextMenuGenerico, Check, Always on Top
}
else
{
	Menu ContextMenuGenerico, UnCheck, Always on Top
}

Menu ContextMenuGenerico, Add, Center Mouse after Activation, MoverRatonAlPulsarBotonToggle
if(conf.moverRatonAlPulsarBoton)
{
	Menu ContextMenuGenerico, Check, Center Mouse after Activation
}
else
{
	Menu ContextMenuGenerico, UnCheck, Center Mouse after Activation
}
Menu ContextMenuGenerico, Add, Send Alt+Tab after Activation, enviarAltTabAlPulsarBotonToggle
if(conf.enviarAltTabAlPulsarBoton)
{
	Menu ContextMenuGenerico, Check, Send Alt+Tab after Activation
}
else
{
	Menu ContextMenuGenerico, UnCheck, Send Alt+Tab after Activation
}
Menu ContextMenuGenerico, Add, Progressive Icon Loading, cargaProgresivaIconosToggle
if(conf.cargaProgresivaIconos)
{
	Menu ContextMenuGenerico, Check, Progressive Icon Loading
}
else
{
	Menu ContextMenuGenerico, UnCheck, Progressive Icon Loading
}
Menu ContextMenuGenerico, Add, Mini Client, CambiarDimensionesCliente
Menu ContextMenuGenerico, UnCheck, Mini Client
Menu ContextMenuGenerico, Add, Set Start Window Possition, setStartPossition
Menu ContextMenuGenerico, UnCheck, Set Start Window Possition
Menu ContextMenuGenerico, Add, Use built-in AHK, toggleBuiltInAhk
if(conf.builtin_ahk)
{
	Menu ContextMenuGenerico, Check, Use built-in AHK
}
else
{
	Menu ContextMenuGenerico, UnCheck, Use built-in AHK
}
Menu ContextMenuGenerico, Add, Minimize to tray (Hide), ToggleHide
Menu ContextMenuGenerico, Add, Reactive Pages, changeReactiveSetting
if(conf.reactiveWindow)
{
	Menu ContextMenuGenerico, Check, Reactive Pages
}
else
{
	Menu ContextMenuGenerico, UnCheck, Reactive Pages
}
Menu ContextMenuGenerico, Add, Bind this folder to a program or window, bindFolderToProgramOrWindow
Menu ContextMenuGenerico, Disable, Bind this folder to a program or window

; Plugin System
GuiControl, splashScreen:, splashTxt, % "Loading Plugins..."
Loop, Files, plugins/*.json
{
	FileRead, pluginJson, % A_LoopFileFullPath
	plugin := ParseJson(pluginJson)
	plugins.push(plugin)
}
SortPluginsByPriority(plugins)
gosub, reloadPlugins
GuiControl, splashScreen:, splashTxt, % "Loaded Plugins!"

Menu ContextMenu, Add, Edit Script`tShift + Click, GuiEditarScript
Menu ContextMenu, Default, Edit Script`tShift + Click
Menu ContextMenu, Icon, Edit Script`tShift + Click, .\resources\img\ico\windows\edit2.ico
Menu ContextMenu, Add, Script Generator`tAlt + Right Click, :scriptGenerator
Menu ContextMenu, Icon, Script Generator`tAlt + Right Click, shell32.dll, 85
Menu ContextMenu, Add, Change/Del Image`tCtrl + Shift + Click, GuiCambiarImagenBoton
Menu ContextMenu, Icon, Change/Del Image`tCtrl + Shift + Click, shell32.dll, 142
Menu ContextMenu, Add, Button Name`tCtrl + Click, GuiInfoBoton
Menu ContextMenu, Icon, Button Name`tCtrl + Click, shell32.dll, 24
Menu ContextMenu, Add, Create Folder Button, CreateFolderButton
Menu ContextMenu, Icon, Create Folder Button, .\resources\img\ico\windows\folder.ico
Menu ContextMenu, Add, Delete Folder Button, DeleteFolderButton
Menu ContextMenu, Icon, Delete Folder Button, shell32.dll, 235
Menu ContextMenu, Add, Delete Button Function, DeleteButtonFunction
Menu ContextMenu, Icon, Delete Button Function, shell32.dll, 132

; CONNECTION TO SERVER (ONLINE == 1)
if(conf.online)
{
	GuiControl, splashScreen:, splashTxt, % conf.ip ":" conf.port " - Connecting to server..."
	sleep, 1 ; Needed to apply previous GuiControl
	global tcpCon := new SocketTCP()
	tcpCon.connect(conf.ip, conf.port)
	tcpCon.onRecv := Func("OnTcpRecv")
	if(tcpCon.errorNM != "")
	{
		gosub, precargaIconosLocalesEnRam
		GuiControl, , wifi_icon, % btnPics["wifi_icon_offline.png"] ? "HBITMAP:*" btnPics["wifi_icon_offline.png"] : ""
		serverFound := 0 ; Online Mode but couldn't connect, so we keep Offline Functionality
		GuiControl, splashScreen:, splashTxt, % tcpCon.errorNM
		Sleep, 500
	}
	else
	{
		serverFound := 1
		GuiControl, splashScreen:, splashTxt, % "Connected! Downloading Profile..."
		gosub, downloadServerProfile
		GuiControl, , wifi_icon, % btnPics["wifi_icon_online.png"] ? "HBITMAP:*" btnPics["wifi_icon_online.png"] : ""
		FileRead, server_config, % "./resources/img/" conf.ip "/resourcePack_info.txt"
		server_config := ParseJson(server_config)
		conf.folderButtons := server_config.folderButtons
	}
}
else
{
	gosub, precargaIconosLocalesEnRam
}

GuiControl, splashScreen:, splashTxt, % "Creating GUI..."
; GUI
; *******************************
Gui, Color, 282828
Gui -Caption +LastFound +ToolWindow +HwndwindowHandler +E0x02080000
Loop, 15
{
    i   := A_Index
    var := "Boton" i
    src := btnPics[i ".png"] ? "HBITMAP:*" btnPics[i ".png"] : "HBITMAP:*" btnPics["button_placeholder.png"]
    Gui, Add, Picture, +BackgroundTrans gOnButton v%var%, % src
}

; Fondos Activaciones Botones
Gui Add, Picture, vActivar1 Hidden x120 y40 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar2 Hidden x280 y40 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar3 Hidden x440 y40 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar4 Hidden x600 y40 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar5 Hidden x760 y40 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar6 Hidden x120 y220 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar7 Hidden x280 y220 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar8 Hidden x440 y220 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar9 Hidden x600 y220 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar10 Hidden x760 y220 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar11 Hidden x120 y400 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar12 Hidden x280 y400 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar13 Hidden x440 y400 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar14 Hidden x600 y400 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar15 Hidden x760 y400 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
; Botones Página
Gui Add, Picture, +BackgroundTrans gRightPage vRightPage x910 y240 w130 h130, % btnPics["RightPage.png"] ? "HBITMAP:*" btnPics["RightPage.png"] : ""
Gui Add, Picture, +BackgroundTrans gLeftPage vLeftPage x0 y240 w130 h130, % btnPics["LeftPage.png"] ? "HBITMAP:*" btnPics["LeftPage.png"] : ""
; Icono Ajustes
Gui Add, Picture, +BackgroundTrans gGuiContextMenu vsettings_icon x960 y0 w64 h64, % btnPics["settings_icon.png"] ? "HBITMAP:*" btnPics["settings_icon.png"] : ""
; Icono Wi-Fi
Gui Add, Picture, +BackgroundTrans gcrearGuiNetworkSettings vwifi_icon x960 y536 w64 h64, % btnPics["wifi_icon_disabled.png"] ? "HBITMAP:*" btnPics["wifi_icon_disabled.png"] : ""
if(serverFound)
{
	GuiControl, , wifi_icon, % btnPics["wifi_icon_online.png"] ? "HBITMAP:*" btnPics["wifi_icon_online.png"] : ""
}
else if(conf.online)
{
	GuiControl, , wifi_icon, % btnPics["wifi_icon_offline.png"] ? "HBITMAP:*" btnPics["wifi_icon_offline.png"] : ""
}
; Fondo y secciones mover
Gui Font, s24, Bai Jamjuree SemiBold
Gui, Add, Text, x0 y0 w1024 h50 +BackgroundTrans cWhite Center GMoverVentana vMoverVentanaUp, ; Mover Ventana de arriba (3.7.6+ Top Notifications)
Gui, Add, Text, x0 y543 w1024 h59 +BackgroundTrans cWhite Center GMoverVentana vMoverVentanaDown, ; Mover Ventana de abajo (3.7.6+ Bottom Notifications)
Gui Add, Picture, x0 y0 w1024 h600 vbackgroundImg, % btnPics["background.png"] ? "HBITMAP:*" btnPics["background.png"] : ""
EstablecerPagina(0)
Gui, SplashScreen:Destroy
Gui Show, % "w1024 h600 x" conf.x_Inicial "y" conf.y_Inicial, LibreDeck Client ; Do NOT change the name, it's used for notifications amongst other stuff
if(conf.miniClient)
{
	conf.miniClient := 0
	gosub, CambiarDimensionesCliente
}
gosub, SetSiempreVisibleInicial
OnMessage(0x404, "AHK_ICONCLICKNOTIFY") ; Detectar doble left click en el icono de notificación para mostrar
gosub, setReactiveService
if(conf.lookForUpdates){
	lookForUpdates(true)
}

global sender := new talk("Background")
; END AUTOEXECUTE SECTION
Return

; LABELS BOTONES Y FUNCIONES GENERALES
; *******************************
ToggleHide:
if EsVisible
{
	WinHide, LibreDeck Client
	Menu, tray, Rename, Hide, Show
	EsVisible = 0
}
else
{
	WinShow, LibreDeck Client
	WinActivate, LibreDeck Client
	Menu, tray, Rename, Show, Hide
	EsVisible = 1
}
Return

GuiContextMenu:
	if GetKeyState("Alt")
		scriptGen := 1
	else
		scriptGen := 0
	if A_GuiControl In Boton1,Boton2,Boton3,Boton4,Boton5,Boton6,Boton7,Boton8,Boton9,Boton10,Boton11,Boton12,Boton13,Boton14,Boton15
	{
		StringReplace, BotonAPulsar, A_GuiControl, boton,
		if(EnCarpeta){
			BotonActivo := CarpetaBoton 15*PaginaCarpeta+BotonAPulsar
			if(BotonAPulsar == 15)
				return ; Button 15* inside a folder is always a return key (no script attached)
		}
		else
			BotonActivo := 15*NumeroPagina+BotonAPulsar
		if (scriptGen)
		{
			KeyWait, Alt,
			Menu scriptGenerator, Show
		}
		else
		{
			Menu ContextMenu, Show
		}
	}
	else if(A_GuiControl == "settings_icon")
	{
		Menu ContextMenuGenerico, Show
	}
	; Background used to show the action context menu, now there is a top-right button for that (easier for touch mode and for newer users)
	;~ else
		;~ Menu ContextMenuGenerico, Show
return

GuiEditarScript:
	EditarScriptBoton(BotonActivo)
return

GuiCambiarImagenBoton:
	EstablecerImagenBoton(BotonActivo)
return

GuiInfoBoton:
	MsgBox,,Button ID, Clicked button Id is: %BotonActivo%
return

NotImplemented:
	MsgBox, Not implemented
return

ComprobarExistenciaBoton()
{
	buttonPath := "" BotonActivo ".ahk"
	if FileExist(buttonPath)
	{
		OnMessage(0x44, "OnMsgBox")
		MsgBoxBtn1 = Overwrite
		MsgBoxBtn2 = Cancel
		MsgBox 0x34, Overwrite?, This button already has a macro file`, do you want to overwrite it?`n`nPrevious function will be lost!
		OnMessage(0x44, "")

		IfMsgBox Yes, {
			return 1
		}else{
			return 0
		}
	}
	else
	{
		return 1
	}
}

SiempreVisible:
	if(conf.siempreVisible)
	{
		Winset, AlwaysOnTop, Off, LibreDeck Client
		conf.siempreVisible := 0
		Menu ContextMenuGenerico, UnCheck, Always on Top
	}
	else
	{
		Winset, AlwaysOnTop, , LibreDeck Client
		conf.siempreVisible := 1
		Menu ContextMenuGenerico, Check, Always on Top
	}
	gosub, guardarConfig
return

SetSiempreVisibleInicial:
	if(!conf.siempreVisible)
	{
		Winset, AlwaysOnTop, Off, LibreDeck Client
		Menu ContextMenuGenerico, UnCheck, Always on Top
	}
	else
	{
		Winset, AlwaysOnTop, , LibreDeck Client
		Menu ContextMenuGenerico, Check, Always on Top
	}
return

MoverRatonAlPulsarBotonToggle:
	if(conf.moverRatonAlPulsarBoton)
	{
		conf.moverRatonAlPulsarBoton := 0
		Menu ContextMenuGenerico, UnCheck, Center Mouse after Activation
	}
	else
	{
		conf.moverRatonAlPulsarBoton := 1
		Menu ContextMenuGenerico, Check, Center Mouse after Activation
	}
	gosub, guardarConfig
return

enviarAltTabAlPulsarBotonToggle:
	if(conf.enviarAltTabAlPulsarBoton)
	{
		conf.enviarAltTabAlPulsarBoton := 0
		Menu ContextMenuGenerico, UnCheck, Send Alt+Tab after Activation
	}
	else
	{
		conf.enviarAltTabAlPulsarBoton := 1
		Menu ContextMenuGenerico, Check, Send Alt+Tab after Activation
	}
	gosub, guardarConfig
return

cargaProgresivaIconosToggle:
	if(conf.cargaProgresivaIconos)
	{
		conf.cargaProgresivaIconos := 0
		Menu ContextMenuGenerico, UnCheck, Progressive Icon Loading
	}
	else
	{
		conf.cargaProgresivaIconos := 1
		Menu ContextMenuGenerico, Check, Progressive Icon Loading
	}
	gosub, guardarConfig
return

toggleBuiltInAhk:
	if(conf.builtin_ahk)
	{
		conf.builtin_ahk := 0
		Menu ContextMenuGenerico, UnCheck, Use built-in AHK
	}
	else
	{
		conf.builtin_ahk := 1
		Menu ContextMenuGenerico, Check, Use built-in AHK
	}
	gosub, guardarConfig
return
 
CambiarDimensionesCliente:
if(!conf.cargaProgresivaIconos)
	DllCall("LockWindowUpdate", "UInt", windowHandler)
if conf.miniClient
{
	Menu, ContextMenuGenerico, Rename, Normal Client, Mini Client
	conf.miniClient := 0
	GuiControl, MoveDraw, Activar1, x120 y40 w150 h150
	GuiControl, MoveDraw, Activar2, x280 y40 w150 h150
	GuiControl, MoveDraw, Activar3, x440 y40 w150 h150
	GuiControl, MoveDraw, Activar4, x600 y40 w150 h150
	GuiControl, MoveDraw, Activar5, x760 y40 w150 h150
	GuiControl, MoveDraw, Activar6, x120 y220 w150 h150
	GuiControl, MoveDraw, Activar7, x280 y220 w150 h150
	GuiControl, MoveDraw, Activar8, x440 y220 w150 h150
	GuiControl, MoveDraw, Activar9, x600 y220 w150 h150
	GuiControl, MoveDraw, Activar10, x760 y220 w150 h150
	GuiControl, MoveDraw, Activar11, x120 y400 w150 h150
	GuiControl, MoveDraw, Activar12, x280 y400 w150 h150
	GuiControl, MoveDraw, Activar13, x440 y400 w150 h150
	GuiControl, MoveDraw, Activar14, x600 y400 w150 h150
	GuiControl, MoveDraw, Activar15, x760 y400 w150 h150
	GuiControl, MoveDraw, LeftPage, x0 y230 w130 h130
	GuiControl, MoveDraw, RightPage, x910 y230 w130 h130
	Gui Font, s24 cWhite, Bai Jamjuree SemiBold
	GuiControl, Font, MoverVentanaUp
	GuiControl, Font, MoverVentanaDown
	GuiControl, MoveDraw, MoverVentanaUp, x0 y0 w1024 h50
	GuiControl, MoveDraw, MoverVentanaDown, x0 y543 w1024 h59
	GuiControl, MoveDraw, wifi_icon, x960 y536 w64 h64
	GuiControl, MoveDraw, settings_icon, x960 y0 w64 h64
	GuiControl, MoveDraw, backgroundImg, x0 y0 w1024 h600
	Gui Show, w1024 h600, LibreDeck Client
}
else
{
	Menu, ContextMenuGenerico, Rename, Mini Client, Normal Client
	conf.miniClient := 1
	GuiControl, MoveDraw, Activar1, x54 y14 w59 h59
	GuiControl, MoveDraw, Activar2, x110 y14 w59 h59
	GuiControl, MoveDraw, Activar3, x166 y14 w59 h59
	GuiControl, MoveDraw, Activar4, x222 y14 w59 h59
	GuiControl, MoveDraw, Activar5, x278 y14 w59 h59
	GuiControl, MoveDraw, Activar6, x54 y70 w59 h59
	GuiControl, MoveDraw, Activar7, x110 y70 w59 h59
	GuiControl, MoveDraw, Activar8, x166 y70 w59 h59
	GuiControl, MoveDraw, Activar9, x222 y70 w59 h59
	GuiControl, MoveDraw, Activar10, x278 y70 w59 h59
	GuiControl, MoveDraw, Activar11, x54 y126 w59 h59
	GuiControl, MoveDraw, Activar12, x110 y126 w59 h59
	GuiControl, MoveDraw, Activar13, x166 y126 w59 h59
	GuiControl, MoveDraw, Activar14, x222 y126 w59 h59
	GuiControl, MoveDraw, Activar15, x278 y126 w59 h59
	GuiControl, MoveDraw, LeftPage, x0 y75 w49 h49
	GuiControl, MoveDraw, RightPage, x340 y75 w49 h49
	Gui Font, s12 cWhite, Bai Jamjuree SemiBold
	GuiControl, Font, MoverVentanaUp
	GuiControl, Font, MoverVentanaDown
	GuiControl, MoveDraw, MoverVentanaUp, x-8 y-5 w413 h23
	GuiControl, MoveDraw, MoverVentanaDown, x0 y175 w401 h23
	GuiControl, MoveDraw, wifi_icon, x353 y168 w32 h32
	GuiControl, MoveDraw, settings_icon, x353 y0 w32 h32
	GuiControl, MoveDraw, backgroundImg, x0 y0 w385 h200
	Gui, Show, w385 h200, LibreDeck Client
}
gosub, setWifiIcon ; Resets the wifi icon without loosing quality bug on resize
DllCall("LockWindowUpdate", "UInt", 0)
gosub, guardarConfig
; Refrescar Botones para no perder calidad de imagen por bug resize
gosub, refreshButtonsAndPage
Return

refreshButtons:
	if(conf.miniClient)
	{
		RefrescarBotonesMini()
	}
	else
	{
		RefrescarBotones()
	}
return

refreshPage:
	if(EnCarpeta)
	{
		EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
	}
	else
	{
		EstaBlecerPagina(NumeroPagina)
	}
return

refreshButtonsAndPage:
	gosub, refreshButtons
	gosub, refreshPage
return

MoverVentana:
PostMessage, 0xA1, 2,,, A 
Return

OnButton:
{
    RegExMatch(A_GuiControl, "\d+$", idx)
    if (idx = "")
        return
    PulsarBoton(idx)
}
return

PulsarBoton(BotonAPulsar)
{
	if(conf.moverRatonAlPulsarBoton)
		MouseMove, % conf.pantalla_Mitad_X, % conf.pantalla_Mitad_Y, 0
	if(conf.reactiveWindow){
		SetTimer, setPageByActiveProgram, 1000
	}
	AltTab()
	; Lógica Botón
	if(EnCarpeta)
	{
		if(BotonAPulsar != 15)
		{
			IdBoton := CarpetaBoton 15*PaginaCarpeta+BotonAPulsar
			if GetKeyState("Control")
			{
				if GetKeyState("Shift")
				{
					EstablecerImagenBoton(IdBoton)
					return
				}
				MsgBox,,Button ID, Clicked button Id is: %IdBoton%
				return
			}
			if GetKeyState("Shift")
			{
				EditarScriptBoton(IdBoton)
				return
			}
			if(conf.online && serverFound)
			{
				if(conf.folderButtons[idBoton] != "")
				{
					CarpetaBoton := conf.folderButtons[idBoton]
					global PaginaCarpeta := 0
					EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
					return
				}
			}
			else
			{
				if(conf.folderButtons[idBoton] != "")
				{
					CarpetaBoton := conf.folderButtons[idBoton]
					global PaginaCarpeta := 0
					EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
					return
				}
			}
			EjecutarFuncionBoton(BotonAPulsar, IdBoton)
		}
		else if (BotonAPulsar = 15)
		{
			; Este es un caso especial ya que si está en carpeta siempre tiene el valor volver (salir fuera de la carpeta)
			IdBoton := CarpetaBoton 15*PaginaCarpeta+BotonAPulsar
			EstablecerPagina(NumeroPagina)
			EnCarpeta = 0
			Menu ContextMenuGenerico, Disable, Bind this folder to a program or window
			PaginaCarpeta = 0
			return	
		}
	}
	else
	{
		IdBoton := 15*NumeroPagina+BotonAPulsar
		if GetKeyState("Control")
		{
			if GetKeyState("Shift")
			{
				EstablecerImagenBoton(IdBoton)
				return
			}
			MsgBox,,Button ID, Clicked button Id is: %IdBoton%
			return
		}
		if GetKeyState("Shift")
		{
			EditarScriptBoton(IdBoton)
			return
		}
		if(conf.online && serverFound)
		{
			if(conf.folderButtons[idBoton] != "")
			{
				CarpetaBoton := conf.folderButtons[idBoton]
				global PaginaCarpeta := 0
				EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
				return
			}
		}
		else
		{
			if(conf.folderButtons[idBoton] != "")
			{
				CarpetaBoton := conf.folderButtons[idBoton]
				global PaginaCarpeta := 0
				EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
				return
			}
		}
		EjecutarFuncionBoton(BotonAPulsar, IdBoton)
	}
	Boton%BotonAPulsar% = 1
}

EstablecerPagina(NumeroPagina)
{
	global
	EnCarpeta := 0
	if(!conf.cargaProgresivaIconos)
		DllCall("LockWindowUpdate", "UInt", windowHandler)
	CarpetaBoton := ""
	RutaBoton1 := CarpetaBoton 15*NumeroPagina+1 ".png"
	RutaBoton2 := CarpetaBoton 15*NumeroPagina+2 ".png"
	RutaBoton3 := CarpetaBoton 15*NumeroPagina+3 ".png"
	RutaBoton4 := CarpetaBoton 15*NumeroPagina+4 ".png"
	RutaBoton5 := CarpetaBoton 15*NumeroPagina+5 ".png"
	RutaBoton6 := CarpetaBoton 15*NumeroPagina+6 ".png"
	RutaBoton7 := CarpetaBoton 15*NumeroPagina+7 ".png"
	RutaBoton8 := CarpetaBoton 15*NumeroPagina+8 ".png"
	RutaBoton9 := CarpetaBoton 15*NumeroPagina+9 ".png"
	RutaBoton10 := CarpetaBoton 15*NumeroPagina+10 ".png"
	RutaBoton11 := CarpetaBoton 15*NumeroPagina+11 ".png"
	RutaBoton12 := CarpetaBoton 15*NumeroPagina+12 ".png"
	RutaBoton13 := CarpetaBoton 15*NumeroPagina+13 ".png"
	RutaBoton14 := CarpetaBoton 15*NumeroPagina+14 ".png"
	RutaBoton15 := CarpetaBoton 15*NumeroPagina+15 ".png"
	
	if (NumeroPagina == 0)
		GuiControl, Hide, LeftPage
	else
		GuiControl, Show, LeftPage
	
	if(conf.miniClient)
	{
		RefrescarBotonesMini()
	}
	else
	{
		RefrescarBotones()
	}
	DllCall("LockWindowUpdate", "UInt", 0)
}

EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
{
	global
	EnCarpeta = 1
	Menu ContextMenuGenerico, Enable, Bind this folder to a program or window
	if(!conf.cargaProgresivaIconos)
		DllCall("LockWindowUpdate", "UInt", windowHandler)
	RutaBoton1 := CarpetaBoton 15*PaginaCarpeta+1 ".png"
	RutaBoton2 := CarpetaBoton 15*PaginaCarpeta+2 ".png"
	RutaBoton3 := CarpetaBoton 15*PaginaCarpeta+3 ".png"
	RutaBoton4 := CarpetaBoton 15*PaginaCarpeta+4 ".png"
	RutaBoton5 := CarpetaBoton 15*PaginaCarpeta+5 ".png"
	RutaBoton6 := CarpetaBoton 15*PaginaCarpeta+6 ".png"
	RutaBoton7 := CarpetaBoton 15*PaginaCarpeta+7 ".png"
	RutaBoton8 := CarpetaBoton 15*PaginaCarpeta+8 ".png"
	RutaBoton9 := CarpetaBoton 15*PaginaCarpeta+9 ".png"
	RutaBoton10 := CarpetaBoton 15*PaginaCarpeta+10 ".png"
	RutaBoton11 := CarpetaBoton 15*PaginaCarpeta+11 ".png"
	RutaBoton12 := CarpetaBoton 15*PaginaCarpeta+12 ".png"
	RutaBoton13 := CarpetaBoton 15*PaginaCarpeta+13 ".png"
	RutaBoton14 := CarpetaBoton 15*PaginaCarpeta+14 ".png"
	
	if (PaginaCarpeta == 0)
		GuiControl, Hide, LeftPage
	else
		GuiControl, Show, LeftPage
	
	if(conf.miniClient)
	{
		RefrescarBotonesMini(true)
	}
	else
	{
		RefrescarBotones(true)
	}
	DllCall("LockWindowUpdate", "UInt", 0)
}

RefrescarBotones(esCarpeta = false)
{
	global
	if(!conf.cargaProgresivaIconos)
		DllCall("LockWindowUpdate", "UInt", windowHandler)
	GuiControl, Text, Boton1, % btnPics[RutaBoton1] ? "HBITMAP:*" btnPics[RutaBoton1] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton1, x130 y50 w130 h130 ; Al cambiarle la ruta hay que resizear el boton
	GuiControl, Text, Boton2, % btnPics[RutaBoton2] ? "HBITMAP:*" btnPics[RutaBoton2] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton2, x290 y50 w130 h130
	GuiControl, Text, Boton3, % btnPics[RutaBoton3] ? "HBITMAP:*" btnPics[RutaBoton3] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton3, x450 y50 w130 h130
	GuiControl, Text, Boton4, % btnPics[RutaBoton4] ? "HBITMAP:*" btnPics[RutaBoton4] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton4, x610 y50 w130 h130
	GuiControl, Text, Boton5, % btnPics[RutaBoton5] ? "HBITMAP:*" btnPics[RutaBoton5] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton5, x770 y50 w130 h130
	GuiControl, Text, Boton6, % btnPics[RutaBoton6] ? "HBITMAP:*" btnPics[RutaBoton6] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton6, x130 w130 y230 h130
	GuiControl, Text, Boton7, % btnPics[RutaBoton7] ? "HBITMAP:*" btnPics[RutaBoton7] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton7, x290 w130 y230 h130
	GuiControl, Text, Boton8, % btnPics[RutaBoton8] ? "HBITMAP:*" btnPics[RutaBoton8] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton8, x450 w130 y230 h130
	GuiControl, Text, Boton9, % btnPics[RutaBoton9] ? "HBITMAP:*" btnPics[RutaBoton9] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton9, x610 w130 y230 h130
	GuiControl, Text, Boton10, % btnPics[RutaBoton10] ? "HBITMAP:*" btnPics[RutaBoton10] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton10, x770 y230 w130 h130
	GuiControl, Text, Boton11, % btnPics[RutaBoton11] ? "HBITMAP:*" btnPics[RutaBoton11] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton11, x130 x130 y410 w130 h130
	GuiControl, Text, Boton12, % btnPics[RutaBoton12] ? "HBITMAP:*" btnPics[RutaBoton12] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton12, x290 y410 w130 h130
	GuiControl, Text, Boton13, % btnPics[RutaBoton13] ? "HBITMAP:*" btnPics[RutaBoton13] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton13, x450 y410 w130 h130
	GuiControl, Text, Boton14, % btnPics[RutaBoton14] ? "HBITMAP:*" btnPics[RutaBoton14] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton14, x610 y410 w130 h130
	if(esCarpeta)
	{
		GuiControl, Text, Boton15,  % btnPics["Volver.png"] ? "HBITMAP:*" btnPics["Volver.png"] : "HBITMAP:*" btnPics["button_placeholder.png"]
		GuiControl, MoveDraw, Boton15, x770 y410 w130 h130	
	}
	else
	{
		GuiControl, Text, Boton15,  % btnPics[RutaBoton15] ? "HBITMAP:*" btnPics[RutaBoton15] : "HBITMAP:*" btnPics["button_placeholder.png"]
		GuiControl, MoveDraw, Boton15, x770 y410 w130 h130		
	}
	DllCall("LockWindowUpdate", "UInt", 0)
}

RefrescarBotonesMini(esCarpeta = false)
{
	global
	if(!conf.cargaProgresivaIconos)
		DllCall("LockWindowUpdate", "UInt", windowHandler)
	GuiControl, Text, Boton1, % btnPics[RutaBoton1] ? "HBITMAP:*" btnPics[RutaBoton1] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton1, x59 y19 w49 h49
	GuiControl, Text, Boton2, % btnPics[RutaBoton2] ? "HBITMAP:*" btnPics[RutaBoton2] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton2, x115 y19 w49 h49
	GuiControl, Text, Boton3, % btnPics[RutaBoton3] ? "HBITMAP:*" btnPics[RutaBoton3] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton3, x171 y19 w49 h49
	GuiControl, Text, Boton4, % btnPics[RutaBoton4] ? "HBITMAP:*" btnPics[RutaBoton4] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton4, x227 y19 w49 h49
	GuiControl, Text, Boton5, % btnPics[RutaBoton5] ? "HBITMAP:*" btnPics[RutaBoton5] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton5, x283 y19 w49 h49
	GuiControl, Text, Boton6, % btnPics[RutaBoton6] ? "HBITMAP:*" btnPics[RutaBoton6] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton6, x59 y75 w49 h49
	GuiControl, Text, Boton7, % btnPics[RutaBoton7] ? "HBITMAP:*" btnPics[RutaBoton7] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton7, x115 y75 w49 h49
	GuiControl, Text, Boton8, % btnPics[RutaBoton8] ? "HBITMAP:*" btnPics[RutaBoton8] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton8, x171 y75 w49 h49
	GuiControl, Text, Boton9, % btnPics[RutaBoton9] ? "HBITMAP:*" btnPics[RutaBoton9] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton9, x227 y75 w49 h49
	GuiControl, Text, Boton10, % btnPics[RutaBoton10] ? "HBITMAP:*" btnPics[RutaBoton10] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton10, x283 y75 w49 h49
	GuiControl, Text, Boton11, % btnPics[RutaBoton11] ? "HBITMAP:*" btnPics[RutaBoton11] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton11, x59 y131 w49 h49
	GuiControl, Text, Boton12, % btnPics[RutaBoton12] ? "HBITMAP:*" btnPics[RutaBoton12] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton12, x115 y131 w49 h49
	GuiControl, Text, Boton13, % btnPics[RutaBoton13] ? "HBITMAP:*" btnPics[RutaBoton13] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton13, x171 y131 w49 h49
	GuiControl, Text, Boton14, % btnPics[RutaBoton14] ? "HBITMAP:*" btnPics[RutaBoton14] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton14, x227 y131 w49 h49
	if(esCarpeta)
	{
		GuiControl, Text, Boton15, % btnPics["Volver.png"] ? "HBITMAP:*" btnPics["Volver.png"] : "HBITMAP:*" btnPics["button_placeholder.png"]
		GuiControl, MoveDraw, Boton15, x283 y131 w49 h49
	}
	else
	{
		GuiControl, Text, Boton15, % btnPics[RutaBoton15] ? "HBITMAP:*" btnPics[RutaBoton15] : "HBITMAP:*" btnPics["button_placeholder.png"]
		GuiControl, MoveDraw, Boton15, x283 y131 w49 h49
	}
	DllCall("LockWindowUpdate", "UInt", 0)
}

LeftPage:
	if(conf.moverRatonAlPulsarBoton)
		MouseMove, % conf.pantalla_Mitad_X, % conf.pantalla_Mitad_Y, 0
	AltTab()
	if(EnCarpeta)
	{
		if(PaginaCarpeta != 0)
		{
			if GetKeyState("Control")
			{
				if(PaginaCarpeta >= 10)
				{
					PaginaCarpeta := PaginaCarpeta - 10
					EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
				}
				return
			}
			PaginaCarpeta--
			EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
		}
	}
	else
	{
		if(NumeroPagina != 0)
		{
			if GetKeyState("Control")
			{
				if(NumeroPagina >= 10)
				{
					NumeroPagina := NumeroPagina - 10
					EstablecerPagina(NumeroPagina)
				}
			}
			else
			{
				NumeroPagina--
				EstablecerPagina(NumeroPagina)
			}
		}
	}
return

RightPage:
	if(conf.moverRatonAlPulsarBoton)
		MouseMove, % conf.pantalla_Mitad_X, % conf.pantalla_Mitad_Y, 0
	AltTab()
	if(EnCarpeta)
	{
		if GetKeyState("Control")
		{
			PaginaCarpeta := PaginaCarpeta + 10
			EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
			return
		}
		PaginaCarpeta++
		EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
	}
	else
	{
		if GetKeyState("Control")
		{
			NumeroPagina := NumeroPagina + 10
		}
		else
		{
			NumeroPagina++
		}
		EstablecerPagina(NumeroPagina)
	}
return

EstablecerImagenBoton(IdBoton)
{
	global btnPics
	OnMessage(0x44, "OnMsgBox")
	MsgBoxBtn1 = Change Img
	MsgBoxBtn2 = Remove
	MsgBoxBtn3 = Cancel
	MsgBox 0x23, Change - Delete, Change Image or Remove Button?
	OnMessage(0x44, "")

	IfMsgBox Yes, {
		FileSelectFile, ImagenAEstablecer, ,,,*.jpg; *.png; *.gif; *.jpeg; *.bmp; *.ico
		if ImagenAEstablecer =
			MsgBox, No image selected!
		else
		{
			FileCopy, %ImagenAEstablecer%, ./resources/img/%IdBoton%.png, 1
			DllCall("DeleteObject", "ptr", btnPics[IdBoton ".png"]) ; Dispose image from memory
			btnPics[IdBoton ".png"] := LoadPicture("./resources/img/" IdBoton ".png")
		}
	} 
	Else IfMsgBox No, {
		FileDelete,./resources/img/%IdBoton%.png
		DllCall("DeleteObject", "ptr", btnPics[IdBoton ".png"]) ; Dispose image from memory
		btnPics[IdBoton ".png"] := ""
		if(FileExist("./" IdBoton ".ahk"))
		{
			OnMessage(0x44, "OnMsgBox")
			MsgBoxBtn1 = Delete
			MsgBoxBtn2 = Keep
			MsgBox 0x34, Overwrite?, This button has a macro file`, do you want to delete it?`n`nIts function will be lost!
			OnMessage(0x44, "")

			IfMsgBox Yes, {
				FileDelete, %IdBoton%.ahk
			}
		}
	} 
	Else IfMsgBox Cancel, {
		return
	}	
	;~ Sleep, 300 ; Lo he quitado porque para qué esperar
	if(EnCarpeta)
	{
		EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
	}
	else
	{
		EstablecerPagina(NumeroPagina)	
	}
}

EditarScriptBoton(IdBoton)
{
	RutaScript := "" IdBoton "." conf.extension ""
	if(!FileExist(RutaScript))
	{
		FileAppend,,%RutaScript%
	}
	Run, % conf.scriptEditorPath " " RutaScript
}

CambiarRutaEditor:
	; Ruta Editor
	FileSelectFile, RutaEditorScripts, ,,,*.exe
	if RutaEditorScripts =
		MsgBox, No executable selected!
	else
	{
		StringReplace, RutaEditorScripts, RutaEditorScripts, \, \\, All
		conf.scriptEditorPath := RutaEditorScripts
	}
	; Extension Scripts
	InputBox, ExtensionScripts, Button Script EXT, Insert the extension of the Scripts triggered by the buttons`nExamples`: exe`, ahk`, py`.`.`., , 500, 145,,,,,ahk
	if ExtensionScripts =
		MsgBox, Couldn't retrieve the extension!
	else
	{
		conf.extension := ExtensionScripts
	}
	gosub, guardarConfig
return

GuiClose:
Exit:
	ExitApp

; HOTKEYS
; *******************************
~Right::
	SetTitleMatchMode, 3
	IfWinActive, LibreDeck Client ahk_class AutoHotkeyGUI
	{
		gosub, RightPage
	}
	SetTitleMatchMode, 1
return

~Left::
	SetTitleMatchMode, 3
	IfWinActive, LibreDeck Client ahk_class AutoHotkeyGUI
	{
		gosub, LeftPage
	}
	SetTitleMatchMode, 1
return

~^Right::
	SetTitleMatchMode, 3
	IfWinActive, LibreDeck Client ahk_class AutoHotkeyGUI
	{
		gosub, RightPage ; Incremento de 10 en 10
	}
	SetTitleMatchMode, 1
return

~^Left::
	SetTitleMatchMode, 3
	IfWinActive, LibreDeck Client ahk_class AutoHotkeyGUI
	{
		gosub, LeftPage ; Decremento de 10 en 10
	}
	SetTitleMatchMode, 1
return

EjecutarFuncionBoton(BotonVisual, FicheroEjecutar)
{
	if(conf.online && serverFound)
	{
		EnviarTCP("{""BotonVisual"":""" BotonVisual """,""FicheroEjecutar"":""" FicheroEjecutar "." conf.extension """}")
		;~ OutputDebug, % "Enviando: " "{BotonVisual:" BotonVisual ",FicheroEjecutar:" FicheroEjecutar "." conf.extension "}"
	}
	else
	{
		Activacion := "Activar" BotonVisual
		GuiControl, Show, %Activacion%
		try
		{
			if(FileExist(A_ScriptDir "\" FicheroEjecutar "." conf.extension))
			{
				if(conf.builtin_ahk)
				{
					
					Run, % A_ScriptDir "\lib\autohotkey.exe " FicheroEjecutar "." conf.extension
				}
				else
				{
					Run, % FicheroEjecutar "." conf.extension
				}
			}
		}
		feedbackEjecucion.push(Activacion)
		SetTimer, OcultarFeedbackEjecucion, 150
	}
}

OcultarFeedbackEjecucion:
	if(feedbackEjecucion.length() = 1)
	{
		SetTimer, OcultarFeedbackEjecucion, Off
	}
	GuiControl, Hide, % feedbackEjecucion[1]
	feedbackEjecucion.remove(1)
return

CreateFolderButton:
	InputBox, nombreCarpetaNueva, Input Folder Name, Input the folder name WITHOUT spaces or weird symbols. Samples: (Programs`,GameFolder`,OBS_Buttons...)
	if(nombreCarpetaNueva != "")
	{
		if(Instr(nombreCarpetaNueva, A_Space))
		{
			MsgBox,,Error, A folder name can not have spaces!`nPlease choose a different name.
			gosub, CreateFolderButton
		}
		nameExists := 0
		StringLower, nombreCarpetaNuevaLower, nombreCarpetaNueva
		for k, v in conf.folderButtons
		{
			StringLower, vLower, v
			if(vLower = nombreCarpetaNuevaLower)
				nameExists := 1
		}
		if(!nameExists)
		{
			conf.folderButtons[BotonActivo] := nombreCarpetaNueva
			gosub, guardarConfig
		}
		else
		{
			MsgBox,,Error, A folder with this name already exists!`nPlease choose a different name.
			gosub, CreateFolderButton
		}
	}
	else
	{
		MsgBox,,Error, Error while creating folder or cancelled.
	}
return

DeleteFolderButton:
	OnMessage(0x44, "OnMsgBox")
	MsgBoxBtn1 = Delete
	MsgBoxBtn2 = Cancel
	MsgBox 0x34, Delete Folder?, This folder may contain other buttons or folders, delete it anyway?
	OnMessage(0x44, "")
	IfMsgBox Yes, {
		OnMessage(0x44, "OnMsgBox")
		MsgBoxBtn1 = Delete them
		MsgBoxBtn2 = Cancel
		MsgBox 0x34, Delete Inside?, You deleted the folder!`nDo you want to also remove buttons/folders that were inside of this folder?`nThis function is experimental, it is recommended that you delete those yourself!`n`nProceed Anyway?
		OnMessage(0x44, "")
		IfMsgBox Yes, {
			if(conf.folderButtons[BotonActivo] != "")
			{
				Loop, Files, % A_ScriptDir "\" conf.folderButtons[BotonActivo] "*.ahk"
				{
					FileDelete, % A_LoopFileFullPath
				}
				Loop, Files, % A_ScriptDir "\resources\img\" conf.folderButtons[BotonActivo] "*.png"
				{
					FileDelete, % A_LoopFileFullPath
				}
			}
		}
		conf.folderButtons.delete(BotonActivo) 
		gosub, guardarConfig
		OnMessage(0x44, "OnMsgBox")
		MsgBoxBtn1 = Delete
		MsgBoxBtn2 = Cancel
		MsgBox 0x34, Delete Icon?, Do you want to also remove this folder icon?
		OnMessage(0x44, "")
		IfMsgBox Yes, {
			FileDelete,./resources/img/%BotonActivo%.png
			DllCall("DeleteObject", "ptr", btnPics[BotonActivo ".png"]) ; Dispose image from memory
			btnPics[BotonActivo ".png"] := ""
			if(EnCarpeta)
			{
				EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
			}
			else
			{
				EstablecerPagina(NumeroPagina)	
			}
		}
	}else{
		return
	}	
return

DeleteButtonFunction:
	if(FileExist(BotonActivo ".ahk"))
	{
		OnMessage(0x44, "OnMsgBox")
		MsgBoxBtn1 = Delete
		MsgBoxBtn2 = Cancel
		MsgBox 0x34, Delete Function?, This button has a function it will be deleted!
		OnMessage(0x44, "")

		IfMsgBox Yes, {
			FileDelete, %BotonActivo%.ahk
			OnMessage(0x44, "OnMsgBox")
			MsgBoxBtn1 = Delete
			MsgBoxBtn2 = Cancel
			MsgBox 0x34, Delete Icon?, Do you want to also remove this button icon?
			OnMessage(0x44, "")
			IfMsgBox Yes, {
				FileDelete,./resources/img/%BotonActivo%.png
				DllCall("DeleteObject", "ptr", btnPics[BotonActivo ".png"]) ; Dispose image from memory
				btnPics[BotonActivo ".png"] := ""
				if(EnCarpeta)
				{
					EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
				}
				else
				{
					EstablecerPagina(NumeroPagina)	
				}
			}
		}
	}
return

setStartPossition:
	if(WinExist("LibreDeck Start Pos"))
	{
		WinActivate, LibreDeck Start Pos
	}
	else
	{
		Gui startPos:Add, Text, x8 y8 w61 h23 +0x200, Initial X Pos:
		Gui startPos:Add, Text, x8 y40 w60 h23 +0x200, Initial Y Pos:
		Gui startPos:Add, Edit, x72 y8 w120 h21 vx_Inicial +Center +Number, % conf.x_Inicial
		Gui startPos:Add, Edit, x72 y40 w120 h21 vy_Inicial +Center +Number, % conf.y_Inicial
		Gui startPos:Add, Button, x112 y72 w80 h23 gsaveStartPossition, Set and Save
		Gui startPos:Add, Button, x8 y72 w80 h23 ggetCurrentPos, Get current
		Gui startPos:Show, w200 h103, LibreDeck Start Pos
	}
return

saveStartPossition:
	GuiControlGet, x_Inicial, startPos:, x_Inicial
	GuiControlGet, y_Inicial, startPos:, y_Inicial
	conf.x_Inicial := x_Inicial
	conf.y_Inicial := y_Inicial
	gosub, guardarConfig
	Gui, startPos:Destroy
	WinMove, LibreDeck Client,, % x_Inicial, % y_Inicial
return

getCurrentPos:
	WinGetPos, x, y,,, LibreDeck Client
	GuiControl, startPos:, x_Inicial, % x
	GuiControl, startPos:, y_Inicial, % y
return

guardarConfig:
	if(!conf.online){
		FileDelete, ./conf/config.json
		FileAppend, % JSON_Beautify(BuildJson(conf)), ./conf/config.json
	}
return

guardarConfigCambioOnline:
	FileDelete, ./conf/config.json
	FileAppend, % JSON_Beautify(BuildJson(conf)), ./conf/config.json
return

startPosguiEscape:
startPosguiClose:
	Gui, startPos:Destroy
return

OnMsgBox() {
    DetectHiddenWindows, On
    Process, Exist
    If (WinExist("ahk_class #32770 ahk_pid " . ErrorLevel)) {
        ControlSetText Button1, % MsgBoxBtn1
        ControlSetText Button2, % MsgBoxBtn2
        ControlSetText Button3, % MsgBoxBtn3
        ControlSetText Button4, % MsgBoxBtn4
    }
}

AltTab(){
	global
	; Alt tab replacement, faster, less distracting
	if(conf.enviarAltTabAlPulsarBoton)
	{
		list := ""
		WinGet, id, list
		Loop, %id%
		{
			this_ID := id%A_Index%
			IfWinActive, ahk_id %this_ID%
				continue    
			WinGetTitle, title, ahk_id %this_ID%
			If (title = "")
				continue
			If (!IsWindow(WinExist("ahk_id" . this_ID))) 
				continue
			WinActivate, ahk_id %this_ID%, ,2
				break
		}
	}
}

; Check whether the target window is activation target
IsWindow(hWnd){
    WinGet, dwStyle, Style, ahk_id %hWnd%
    if ((dwStyle&0x08000000) || !(dwStyle&0x10000000)) {
        return false
    }
    WinGet, dwExStyle, ExStyle, ahk_id %hWnd%
    if (dwExStyle & 0x00000080) {
        return false
    }
    WinGetClass, szClass, ahk_id %hWnd%
    if (szClass = "TApplication") {
        return false
    }
    return true
}

SkinForm(Param1 = "Apply", DLL = "", SkinName = ""){
	if(Param1 = Apply){
		DllCall("LoadLibrary", str, DLL)
		DllCall(DLL . "\USkinInit", Int,0, Int,0, AStr, SkinName)
	}else if(Param1 = 0){
		DllCall(DLL . "\USkinExit")
		}
}

GetOut:
	SkinForm(0)
    ExitApp


; NETWORKING MODULE
EnviarTCP(txtSnd)
{
    tcpCon.sendText(txtSnd)
}

OnTcpRecv(this)
{
	Activacion := "Activar" this.RecvText()
	GuiControl, Show, %Activacion%
	feedbackEjecucion.push(Activacion)
	SetTimer, OcultarFeedbackEjecucion, 150
}

crearGuiNetworkSettings:
	if(WinExist("LibreDeck Network Settings"))
	{
		WinActivate, LibreDeck Network Settings
	}
	else
	{
		if(conf.online)
			Gui networkSettings:Add, CheckBox, x16 y8 w120 h23 vOnlineChk checked, Online Mode
		else
			Gui networkSettings:Add, CheckBox, x16 y8 w120 h23 vOnlineChk, Online Mode
		Gui networkSettings:Add, Text, x16 y40 w43 h23 +0x200, IP:
		Gui networkSettings:Add, Text, x16 y72 w43 h23 +0x200, Port:
		Gui networkSettings:Add, Text, x16 y104 w43 h23 +0x200, Res Port:
		Gui networkSettings:Add, Edit, +Center x64 y40 w120 h21 vIpTxt, % conf.ip
		Gui networkSettings:Add, Edit, +Center x64 y72 w120 h21 vPortTxt, % conf.port
		Gui networkSettings:Add, Edit, +Center x64 y104 w120 h21 vResourcesPortTxt, % conf.resourcesPort
		Gui networkSettings:Add, Button, x16 y136 w80 h23 gSaveNetworkConfig, SAVE CONFIG
		Gui networkSettings:Add, Button, x104 y136 w80 h23 gConnectToServer, CONNECT
		Gui networkSettings:Add, Text, x0 y168 w214 h2 +0x10 ; Separator
		Gui networkSettings:Add, Text, x8 y169 w191 h23 +Center +0x200 vNetworkStatusInfo, LibreDeck - Network Config
		Gui networkSettings:Show, w208 h192, LibreDeck Network Settings
	}
Return

SaveNetworkConfig:
	GuiControlGet, IpTxt, networkSettings:, IpTxt
	GuiControlGet, PortTxt, networkSettings:, PortTxt
	GuiControlGet, OnlineChk, networkSettings:, OnlineChk
	GuiControlGet, ResourcesPortTxt, networkSettings:, ResourcesPortTxt
	mustReload := 0
	if(OnlineChk != conf.online)
	{
		mustReload := 1
	}
	gosub, loadConfig ; This is needed because when we are online, folder config is the remote server's config, and we don't want to keep it when we switch back to local mode
	conf.online := OnlineChk
	conf.ip := IpTxt
	conf.port := PortTxt
	conf.resourcesPort := ResourcesPortTxt
	gosub, guardarConfigCambioOnline
	GuiControl, networkSettings:+cBlue, NetworkStatusInfo
	GuiControl, networkSettings:Text, NetworkStatusInfo, Config Saved!
	if(mustReload)
	{
		reload
	}
return

ConnectToServer:
	GuiControlGet, OnlineChk, networkSettings:, OnlineChk
	if(!OnlineChk)
	{
		MsgBox, % "Enable online mode first!"
		return
	}
	GuiControlGet, IpTxt, networkSettings:, IpTxt
	GuiControlGet, PortTxt, networkSettings:, PortTxt
	GuiControlGet, ResourcesPortTxt, networkSettings:, ResourcesPortTxt
	GuiControl, networkSettings:+cBlack, NetworkStatusInfo
	GuiControl, networkSettings:Text, NetworkStatusInfo, Connecting...
	tcpCon := new SocketTCP()
	tcpCon.connect(IpTxt, PortTxt)
	tcpCon.onRecv := Func("OnTcpRecv")
	if(tcpCon.errorNM != "")
	{
		serverFound := 0
		GuiControl, networkSettings:+cRed, NetworkStatusInfo
		GuiControl, networkSettings:Text, NetworkStatusInfo, Could not connect!
	}
	else
	{
		serverFound := 1
		gosub, SaveNetworkConfig
		GuiControl, networkSettings:+cGreen, NetworkStatusInfo
		GuiControl, networkSettings:Text, NetworkStatusInfo, Connected to the server!
		gosub, downloadServerProfile
	}
	gosub, setWifiIcon
return

networkSettingsguiClose:
networkSettingsguiEscape:
	Gui, networkSettings:Destroy
return

setWifiIcon:
	Gui, 1:Default
	if(conf.online)
	{
		if(serverFound)
		{
			GuiControl, , wifi_icon, % btnPics["wifi_icon_online.png"] ? "HBITMAP:*" btnPics["wifi_icon_online.png"] : ""
		}
		else
		{
			GuiControl, , wifi_icon, % btnPics["wifi_icon_offline.png"] ? "HBITMAP:*" btnPics["wifi_icon_offline.png"] : ""
		}
	}
	else
	{
		GuiControl, , wifi_icon, % btnPics["wifi_icon_disabled.png"] ? "HBITMAP:*" btnPics["wifi_icon_disabled.png"] : ""
	}
return

downloadServerProfile:
	if(!FileExist(A_ScriptDir "\resources\img\" conf.ip)) ; Nuevo servidor
	{
		MsgBox 0x4, Download Server Resource Pack?, Do you want to try to download the server's Resource Pack?
		IfMsgBox Yes, {
			FileCreateDir, % "./resources/img/" conf.ip
			URLDownloadToFile, % "http://" conf.ip ":" conf.resourcesPort "/resourcePack.7z", % "./resources/img/" conf.ip "/resourcePack.7z"
			URLDownloadToFile, % "http://" conf.ip ":" conf.resourcesPort "/resourcePack_info.txt", % "./resources/img/" conf.ip "/resourcePack_info.txt"
			gosub, descomprimirResourcePack
		}
	}
	else
	{
		server_config := ParseJson(URLToVar("http://" conf.ip ":" conf.resourcesPort "/resourcePack_info.txt"))
		serverMD5 := server_config.resourcePackMD5
		FileRead, localMD5, % "./resources/img/" conf.ip "/resourcePack_info.txt"
		localMD5 := ParseJson(localMD5).resourcePackMD5
		if(serverMD5 != localMD5) ; Reemplazo local pq ha cambiado el MD5
		{
			MsgBox 0x4, Download Server Resource Pack?, Do you want to try to download the server's Resource Pack?
			IfMsgBox Yes, {
				FileRemoveDir, % "./resources/img/" conf.ip, 1
				FileCreateDir, % "./resources/img/" conf.ip
				URLDownloadToFile, % "http://" conf.ip ":" conf.resourcesPort "/resourcePack.7z", % "./resources/img/" conf.ip "/resourcePack.7z"
				URLDownloadToFile, % "http://" conf.ip ":" conf.resourcesPort "/resourcePack_info.txt", % "./resources/img/" conf.ip "/resourcePack_info.txt"
				gosub, descomprimirResourcePack
			}
		}
		gosub, precargaIconosRemotosEnRam
	}
return

descomprimirResourcePack:
	ToolTip, % "Decompressing..."
	RunWait, % """" A_WorkingDir "\lib\7za.exe"" x """ A_WorkingDir "\resources\img\" conf.ip "\resourcePack.7z"" -o"""A_WorkingDir "\resources\img\" conf.ip """",, Hide
	FileDelete, % A_WorkingDir "\resources\img\" conf.ip "\resourcePack.7z"
	reload
return


; WM_COPYDATA specific funtions
setBackground:
	try {
		incomingBackgroundChange := ParseJson(incomingBackgroundChange)
		imagePathOrName := incomingBackgroundChange.imagePathOrName
		DllCall("LockWindowUpdate", "UInt", windowHandler)
		Loop, 2 ; Bug? Blurry on first change
		{
			GuiControl, Text, backgroundImg, % btnPics[imagePathOrName] ? "HBITMAP:*" btnPics[imagePathOrName] : imagePathOrName
			if conf.miniClient
			{
				GuiControl, MoveDraw, backgroundImg, x0 y0 w385 h200
			}
			else
			{
				GuiControl, MoveDraw, backgroundImg, x0 y0 w1024 h600
			}
		}
		DllCall("LockWindowUpdate", "UInt", 0)
	}
return

setButtonIconRemote:
	try {
		incomingButtonChange := ParseJson(incomingButtonChange)
		setButtonIcon(incomingButtonChange.buttonId, incomingButtonChange.imagePathOrName)
	}
return

setButtonIcon(buttonId, imagePathOrName) {
	global
	GuiControl, Text, Boton%buttonId%, % btnPics[imagePathOrName] ? "HBITMAP:*" btnPics[imagePathOrName] : imagePathOrName
	if(conf.miniClient)
		GuiControl, MoveDraw, Boton%buttonId%, w49 h49
	else
		GuiControl, MoveDraw, Boton%buttonId%, w130 h130
}

; Notification examples at: plugins: notification_examples.ahk & backup_libredeck.ahk
showIncomingNotification:
	try {
		incomingNotification := ParseJson(incomingNotification)
		if (incomingNotification.region == "top") {
			setNotificationTop(incomingNotification.text, incomingNotification.duration)
		} else if (incomingNotification.region == "bottom") {
			setNotificationBottom(incomingNotification.text, incomingNotification.duration)
		}
	}
return

setNotificationTop(notificationText, notificationDuration) {
	global MoverVentanaUp
	GuiControl,, MoverVentanaUp, % notificationText
	if (notificationDuration != 0) ; Indefinite duration
		SetTimer, removeNotificationTop, % notificationDuration
}

setNotificationBottom(notificationText, notificationDuration) {
	global MoverVentanaDown
	GuiControl,, MoverVentanaDown, % notificationText
	if (notificationDuration != 0) ; Indefinite duration
		SetTimer, removeNotificationBottom, % notificationDuration
}

removeNotificationTop:
	SetTimer, removeNotificationTop, Off
	GuiControl,, MoverVentanaUp, % ""
return

removeNotificationBottom:
	SetTimer, removeNotificationBottom, Off
	GuiControl,, MoverVentanaDown, % ""
return

removeNotifications:
	SetTimer, removeNotifications, Off
	gosub, removeNotificationBottom
	gosub, removeNotificationTop
return

remotePageChange:
	try {
		incomingPageChange := ParseJson(incomingPageChange)
		if (incomingPageChange.isFolder) {
			CarpetaBoton := incomingPageChange.folderName
			global PaginaCarpeta := incomingPageChange.pageNumber
			EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
		} else {
			NumeroPagina := incomingPageChange.pageNumber
			EstablecerPagina(NumeroPagina)
		}
	}
return

precargaIconosLocalesEnRam:
	; Precarga imágenes de botones en memoria (mucha más rápida la navegación) (qué majo soy, unos comentarios los pongo en inglés y otros en español, tremendo caraalpargata)
	GuiControl, splashScreen:, splashTxt, % "Calculating Resource Count..."
	gosub, vaciarMemoriaIconos
	Loop, Files, ./resources/img/*.png
	{
		i++
	}
	Loop, Files, ./resources/img/*.png
	{
		btnPics[A_LoopFileName] := LoadPicture(A_LoopFileFullPath) ; Images loaded using this method are stored in RAM, to free up assigned image resources -> DllCall("DeleteObject", "ptr", btnPics["image_name.png"])
		GuiControl, splashScreen:, splashTxt, % "[" Round((A_Index/i)*100) "%] Loading Resources: " A_LoopFileFullPath
	}
return

precargaIconosRemotosEnRam:
	GuiControl, splashScreen:, splashTxt, % "Calculating Resource Count..."
	gosub, vaciarMemoriaIconos
	Loop, Files, % "./resources/img/" conf.ip "/*.png"
	{
		i++
	}
	Loop, Files, % "./resources/img/" conf.ip "/*.png"
	{
		btnPics[A_LoopFileName] := LoadPicture(A_LoopFileFullPath) ; Images loaded using this method are stored in RAM, to free up assigned image resources -> DllCall("DeleteObject", "ptr", btnPics["image_name.png"])
		GuiControl, splashScreen:, splashTxt, % "[" Round((A_Index/i)*100) "%] Loading Resources: " A_LoopFileFullPath
	}
return

vaciarMemoriaIconos:
	for, k, v in btnPics
	{
		DllCall("DeleteObject", "ptr", btnPics[k]) ; Dispose image from memory
	}
return

generateBackup:
	Run, % """" A_ScriptDir "\lib\autohotkey.exe"" """ A_ScriptDir "\plugins\backup_libredeck.ahk"""
return

changeReactiveSetting:
	if(conf.reactiveWindow){
		conf.reactiveWindow := 0
	}else{
		conf.reactiveWindow := 1
	}
	gosub, guardarConfig
	if(conf.reactiveWindow)
	{
		Menu ContextMenuGenerico, Check, Reactive Pages
	}
	else
	{
		Menu ContextMenuGenerico, UnCheck, Reactive Pages
	}
	gosub, setReactiveService
return

setReactiveService:
	if(conf.reactiveWindow){
		SetTimer, setPageByActiveProgram, 500
	}else{
		SetTimer, setPageByActiveProgram, Off
	}
return

setPageByActiveProgram:
	; Only trigger changes and app check when LibreDeck is visible
	DetectHiddenWindows, Off
	if(WinExist("LibreDeck Client"))
	{
		WinGet, activeProcess, ProcessName, A
		if(previousActiveProcess != activeProcess && activeProcess != A_ScriptName){
			previousActiveProcess := activeProcess
			if(conf.programFolder[activeProcess] != ""){
				gosub, setPageByActiveProcess ; This was needed due to the improvements in folder change and reactive service folder change being quicker than pulsarBoton() function
			}
		}
	}
	DetectHiddenWindows, On
return

setPageByActiveProcess:
	CarpetaBoton := conf.programFolder[activeProcess]
	PaginaCarpeta := 0
	EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
return

lookForUpdatesOnBootLabel:
	if(conf.lookForUpdates)
	{
		conf.lookForUpdates := 0
		Menu LookForUpdatesMenu, UnCheck, On Boot
	}
	else
	{
		conf.lookForUpdates := 1
		Menu LookForUpdatesMenu, Check, On Boot
	}
	gosub, guardarConfig
return

lookForUpdatesLabel:
	lookForUpdates()
return

dummyLabel:
return

bindFolderToProgramOrWindow:
	OnMessage(0x44, "OnBindDeleteMsgBox")
	MsgBox 0x1, Bind Action, Bind or delete bind?
	OnMessage(0x44, "")

	IfMsgBox OK, {
		Gui bindFolderToProgram:Add, Edit, vfileName x16 y15 w325 h21
		Gui bindFolderToProgram:Add, Button, gSelectFile x344 y14 w120 h23, Select Executable
		Gui bindFolderToProgram:Font, Bold
		Gui bindFolderToProgram:Add, Button, x16 y50 w246 h28 gDetect, + Detect already open program
		Gui bindFolderToProgram:Add, Button, x360 y50 w104 h28 gsetFolderProgramBind, SAVE
		Gui bindFolderToProgram:Show, w472 h87, Bind program to page
	} Else IfMsgBox Cancel, {
		; Delete bind
		programFolderTmp := []
		for exe, folder in conf.programFolder
		{
			if(folder != CarpetaBoton){
				
				programFolderTmp[exe] := folder
			}
		}
		conf.programFolder := programFolderTmp
		gosub, guardarConfig
	}
return

OnBindDeleteMsgBox() {
    DetectHiddenWindows, On
    Process, Exist
    If (WinExist("ahk_class #32770 ahk_pid " . ErrorLevel)) {
        ControlSetText Button1, Bind EXE
        ControlSetText Button2, Unbind
    }
}

SelectFile:
	FileSelectFile, fullFilePath,, %A_Desktop%, Select executable, Executables (*.exe)
	if(fullFilePath != "")
	{
		SplitPath, fullFilePath, fileName, workingDir
		GuiControl, bindFolderToProgram:,fileName, % fileName
	}
Return

Detect:
	MsgBox,,Select Window, 1) Activate a window of the program you want this folder being bound to `n2) Press ENTER
	Hotkey, Enter, DetectOpenProgram, On
return

DetectOpenProgram:
	winget, appPath, processpath, a
	SplitPath, appPath, fileName, workingDir
	Hotkey, Enter, DetectOpenProgram, Off
	GuiControl, bindFolderToProgram:,fileName, % fileName
	WinActivate, Bind program to page
return

setFolderProgramBind:
	GuiControlGet, fileName, bindFolderToProgram:, fileName
	conf.programFolder[fileName] := CarpetaBoton
	gosub, guardarConfig
	Gui, bindFolderToProgram:Destroy
return

bindFolderToProgramEscape:
bindFolderToProgramClose:
	Gui, bindFolderToProgram:Destroy
return

showAboutScreen:
	showAboutScreen("LibreDeck v" ClientVersionNumber, "A multi-purpose macro pannel tailored to be used both in single screen setups, multi screen, touch support and multi machine setups via sockets.")
return

openLibreDeckFolder:
	Run, % A_ScriptDir
return

loadConfig:
	FileRead, conf, ./conf/config.json
	global conf := ParseJson(conf)
	scriptEditorPath := conf.scriptEditorPath
	StringReplace, scriptEditorPath, scriptEditorPath, \, \\, All
	conf.scriptEditorPath := scriptEditorPath
return

reloadPlugins:
	for key, plugin in plugins
	{
		BuildMenusFromPlugin(plugin)
	}
return

runServer:
	Run, LibreDeck Server.exe
return

#Include plugins/plugin_list.ahk