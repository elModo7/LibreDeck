; OS Version ...: > Windows 10
; Recommended AutoHotkeyU32
;@Ahk2Exe-SetName LibreDeck Client
;@Ahk2Exe-SetDescription Macro Panel Client
;@Ahk2Exe-SetVersion 4.4.1
;@Ahk2Exe-SetCopyright 2026`, elModo7 - VictorDevLog
;@Ahk2Exe-SetOrigFilename LibreDeck Client.exe
; INITIALIZE
; *******************************
/*
TODO:
- Reactive window configurer GUI (Program Selector, Page Selector)
- More OBS functions
- BtnDescriptions (label with description (text, color, transparency, fontweight))

REQUIERES:
- Windows 10
- AutoHotkey (JSON lib (deprecated one, cJSON does) and them.dll do not work under U64 AHK, use U32 for uskin support)
- Compile without MPRESS, USkin.dll compatibility is lost otherwise
- Notification System ONLY works when compiled

DISCARDED:
- Volver a la carpeta anterior y volver a la raíz si se pulsa p.ej control

LATEST CHANGES:
- GoLang server support
- OBS Websocket Compat 4.x -> 5.X
- Improve online mode
- Add dynamic buttons (3.7.6+)
- Add notifications integration (same machine via talk.ahk) (3.7.6+)
- Add remote icon, background changes (3.8.1+)
- Add spotify integration (3.8.2+) -> https://github.com/CloakerSmoker/Spotify.ahk
- Add proper button folders
- Add dynamic discovery (4.1.0+)
- Add network profiling (4.2.0+)
- Add i18n translations (4.3.0+)
- Remove deprecated JSON Lib (4.4.1+)

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
FileEncoding, UTF-8
;~ #Include <JSON> ; Deprecated in 4.4.1
#Include <cJSON>
#Include <i18n>
#Include <SplashScreen>
#Include <Socket>
#Include <LibreDeckDiscovery>
#Include <util>
#Include <client_updater>
#Include <aboutScreen>
#Include <talk>
#Include <plugin_system>
#Include <LibreDeckButtonImage>
rutaSplash = ./resources/img/splash.png
global ClientVersionNumber := "4.4.1"
global ClientVersion := ClientVersionNumber " - elModo7 / VictorDevLog " A_YYYY
SplashScreen(rutaSplash, 3000, 545, 160, 0, 0, true)
global EsVisible = true
global EnCarpeta = false
global CarpetaBoton, PaginaCarpeta, BotonActivo, BotonAPulsar, windowHandler, IpTxt, PortTxt, OnlineChk, AHK_ICONCLICKCOUNT, server_config, previousActiveProcess
global RutaBoton1, RutaBoton2, RutaBoton3, RutaBoton4, RutaBoton5, RutaBoton6, RutaBoton7, RutaBoton8, RutaBoton9, RutaBoton10, RutaBoton11, RutaBoton12, RutaBoton13, RutaBoton14, RutaBoton15
global feedbackEjecucion := []
global plugins := []
global LD_i18n := ""
global LD_ButtonClipboard := ""
global LD_ButtonMoveSource := ""
global LD_ButtonSelection := []
global LD_ButtonSelectionMap := {}
global LD_ScriptGeneratorMenuHandlers := {}
global LD_ScriptGeneratorMenus := {}
global LD_DiscoveryServers := {}
global LD_DiscoveryInterfaces := {}
global LD_DiscoverySocks := []
global LD_DiscoverySock := -1
global LD_DiscoverySocketCallback := ""
global LD_DiscoveryWinsockStarted := false
global LD_DiscoveryDiscovering := false
global LD_DiscoveryPort := 37921
global LD_DiscoveryLocalUdpPort := 0
global LD_DiscoveryLocalIP := ""
global LD_DiscoveryBroadcastIP := ""
global LD_DISCOVERY_SOCKET_MSG := 0x9989
global LD_DISCOVERY_FD_READ := 1
global LD_DISCOVERY_TIMEOUT_MS := 1200
global LD_NetworkConfigSkipReload := false
global LD_CurrentDiscoveredServerName := ""
global LD_TCP_CONNECT_TIMEOUT_MS := 2000
global LD_TCP_CONNECT_ATTEMPTS := 2
global LD_ReconnectAttemptCount := 0
global LD_ButtonEditorActiveId := ""
global NumeroPagina := 0
global serverFound := 0
global reactiveWindow := 0
global MsgBoxBtn1, MsgBoxBtn2, MsgBoxBtn3, MsgBoxBtn4
SkinForm(Apply, A_ScriptDir . "\lib\script_generator\lib\them.dll", A_ScriptDir . "\lib\script_generator\lib\tm")
OnExit, GetOut
FileCreateDir, conf
FileCreateDir, buttons
FileCreateDir, i18n
global btnPics := {}
GuiControl, splashScreen:, splashTxt, % "Reading config..."
contextcolor(2) ;0=Default ;1=AllowDark ;2=ForceDark ;3=ForceLight ;4=Max

; Image Generator
outDir := A_ScriptDir "\resources\img"
FileCreateDir, %outDir%
LD_ButtonImage_Start()

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
	conf.serverProfiles := {}
	conf.favoriteServerProfile := ""
	conf.lastServerProfile := ""
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
	conf.isGolangServer := 0
	conf.language := "en_US"
	gosub, guardarConfig
}

gosub, loadConfig
LD_InitI18n()
LibreDeckApplyStartupProfile()
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
Menu, tray, add, % LD_T("tray.run_server", "Run LibreDeck server"), runServer
Menu tray, Icon, % LD_T("tray.run_server", "Run LibreDeck server"), .\resources\img\ico\libredeck.ico
Menu, tray, add, % LD_T("tray.hide", "Hide"), ToggleHide
Menu tray, Icon, % LD_T("tray.hide", "Hide"), .\resources\img\ico\windows\cut_visibility.ico
Menu, tray, add, % LD_T("tray.set_editor_path", "Set Editor Path"), CambiarRutaEditor
Menu tray, Icon, % LD_T("tray.set_editor_path", "Set Editor Path"), .\resources\img\ico\windows\edit2.ico
Menu tray, add, % LD_T("tray.set_start_position", "Set Start Window Possition"), setStartPossition
Menu tray, Icon, % LD_T("tray.set_start_position", "Set Start Window Possition"), .\resources\img\ico\windows\window_possition.ico
Menu tray, add, % LD_T("tray.backup_folder", "Backup LibreDeck Folder (*.7z)"), generateBackup
Menu tray, Icon, % LD_T("tray.backup_folder", "Backup LibreDeck Folder (*.7z)"), .\resources\img\ico\windows\compressed_folder.ico
Menu tray, add, % LD_T("tray.open_folder", "Open LibreDeck Folder"), openLibreDeckFolder
Menu tray, Icon, % LD_T("tray.open_folder", "Open LibreDeck Folder"), .\resources\img\ico\windows\folder.ico
Menu, tray, add
LD_BuildLanguageMenu()
Menu tray, Add, % LD_T("tray.language", "Language"), :LanguageMenu
Menu tray, Icon, % LD_T("tray.language", "Language"), .\resources\img\ico\windows\internet_time.ico
Menu, tray, add
Menu, tray, add, % LD_T("tray.network_settings", "Network Settings"), crearGuiNetworkSettings
Menu tray, Icon, % LD_T("tray.network_settings", "Network Settings"), .\resources\img\ico\windows\network2.ico
Menu, tray, add
Menu LookForUpdatesMenu, Add, % LD_T("tray.updates_on_boot", "On Boot"), lookForUpdatesOnBootLabel
Menu LookForUpdatesMenu, Icon, % LD_T("tray.updates_on_boot", "On Boot"), .\resources\img\ico\windows\look_for_updates.ico
Menu LookForUpdatesMenu, Add, % LD_T("tray.updates_now", "Now"), lookForUpdatesLabel
Menu LookForUpdatesMenu, Icon, % LD_T("tray.updates_now", "Now"), .\resources\img\ico\windows\download.ico
Menu tray, Add, % LD_T("tray.look_for_updates", "Look for Updates"), :LookForUpdatesMenu
Menu tray, Icon, % LD_T("tray.look_for_updates", "Look for Updates"), .\resources\img\ico\windows\refresh.ico

Menu, tray, add, % "v" ClientVersion, showAboutScreen
Menu tray, Icon, % "v" ClientVersion, .\resources\img\ico\windows\info.ico
;~ Menu, tray, disable, % "v" ClientVersion
Menu, tray, add, % LD_T("tray.exit", "Exit"), Exit
Menu tray, Icon, % LD_T("tray.exit", "Exit"), .\resources\img\ico\windows\close3.ico

if(conf.lookForUpdates)
	Menu LookForUpdatesMenu, Check, % LD_T("tray.updates_on_boot", "On Boot")
else
	Menu LookForUpdatesMenu, UnCheck, % LD_T("tray.updates_on_boot", "On Boot")

; CONTEXT MENU GENERICO
; *******************************
Menu ContextMenuGenerico, Add, % LD_T("app_menu.always_on_top", "Always on Top"), SiempreVisible
if(conf.siempreVisible)
{
	Menu ContextMenuGenerico, Check, % LD_T("app_menu.always_on_top", "Always on Top")
}
else
{
	Menu ContextMenuGenerico, UnCheck, % LD_T("app_menu.always_on_top", "Always on Top")
}

Menu ContextMenuGenerico, Add, % LD_T("app_menu.center_mouse", "Center Mouse after Activation"), MoverRatonAlPulsarBotonToggle
if(conf.moverRatonAlPulsarBoton)
{
	Menu ContextMenuGenerico, Check, % LD_T("app_menu.center_mouse", "Center Mouse after Activation")
}
else
{
	Menu ContextMenuGenerico, UnCheck, % LD_T("app_menu.center_mouse", "Center Mouse after Activation")
}
Menu ContextMenuGenerico, Add, % LD_T("app_menu.send_alt_tab", "Send Alt+Tab after Activation"), enviarAltTabAlPulsarBotonToggle
if(conf.enviarAltTabAlPulsarBoton)
{
	Menu ContextMenuGenerico, Check, % LD_T("app_menu.send_alt_tab", "Send Alt+Tab after Activation")
}
else
{
	Menu ContextMenuGenerico, UnCheck, % LD_T("app_menu.send_alt_tab", "Send Alt+Tab after Activation")
}
Menu ContextMenuGenerico, Add, % LD_T("app_menu.progressive_icon_loading", "Progressive Icon Loading"), cargaProgresivaIconosToggle
if(conf.cargaProgresivaIconos)
{
	Menu ContextMenuGenerico, Check, % LD_T("app_menu.progressive_icon_loading", "Progressive Icon Loading")
}
else
{
	Menu ContextMenuGenerico, UnCheck, % LD_T("app_menu.progressive_icon_loading", "Progressive Icon Loading")
}
Menu ContextMenuGenerico, Add, % LD_T("app_menu.mini_client", "Mini Client"), CambiarDimensionesCliente
Menu ContextMenuGenerico, UnCheck, % LD_T("app_menu.mini_client", "Mini Client")
Menu ContextMenuGenerico, Add, % LD_T("tray.set_start_position", "Set Start Window Possition"), setStartPossition
Menu ContextMenuGenerico, UnCheck, % LD_T("tray.set_start_position", "Set Start Window Possition")
Menu ContextMenuGenerico, Add, % LD_T("app_menu.use_builtin_ahk", "Use built-in AHK"), toggleBuiltInAhk
if(conf.builtin_ahk)
{
	Menu ContextMenuGenerico, Check, % LD_T("app_menu.use_builtin_ahk", "Use built-in AHK")
}
else
{
	Menu ContextMenuGenerico, UnCheck, % LD_T("app_menu.use_builtin_ahk", "Use built-in AHK")
}
Menu ContextMenuGenerico, Add, % LD_T("app_menu.minimize_to_tray", "Minimize to tray (Hide)"), ToggleHide
Menu ContextMenuGenerico, Add, % LD_T("app_menu.reactive_pages", "Reactive Pages"), changeReactiveSetting
if(conf.reactiveWindow)
{
	Menu ContextMenuGenerico, Check, % LD_T("app_menu.reactive_pages", "Reactive Pages")
}
else
{
	Menu ContextMenuGenerico, UnCheck, % LD_T("app_menu.reactive_pages", "Reactive Pages")
}
Menu ContextMenuGenerico, Add, % LD_T("app_menu.bind_folder", "Bind this folder to a program or window"), bindFolderToProgramOrWindow
Menu ContextMenuGenerico, Disable, % LD_T("app_menu.bind_folder", "Bind this folder to a program or window")

; Plugin System
GuiControl, splashScreen:, splashTxt, % "Loading Plugins..."
Loop, Files, plugins/*.json
{
	FileRead, pluginJson, % A_LoopFileFullPath
	plugin := JSON.Load(pluginJson)
	plugins.push(plugin)
}
SortPluginsByPriority(plugins)
gosub, reloadPlugins
GuiControl, splashScreen:, splashTxt, % "Loaded Plugins!"

Menu ContextMenu, Add, % LD_T("button_menu.button_editor", "Button Editor"), GuiButtonEditor
Menu ContextMenu, Default, % LD_T("button_menu.button_editor", "Button Editor")
Menu ContextMenu, Icon, % LD_T("button_menu.button_editor", "Button Editor"), shell32.dll, 269
Menu ContextMenu, Add, % LD_T("button_menu.edit_script", "Edit Script`tShift + Click"), GuiEditarScript
Menu ContextMenu, Icon, % LD_T("button_menu.edit_script", "Edit Script`tShift + Click"), .\resources\img\ico\windows\edit2.ico
Menu ContextMenu, Add, % LD_T("button_menu.script_generator", "Script Generator`tAlt + Right Click"), :scriptGenerator
Menu ContextMenu, Icon, % LD_T("button_menu.script_generator", "Script Generator`tAlt + Right Click"), shell32.dll, 85
Menu ContextMenu, Add, % LD_T("button_menu.change_image", "Change/Del Image`tCtrl + Shift + Click"), GuiCambiarImagenBoton
Menu ContextMenu, Icon, % LD_T("button_menu.change_image", "Change/Del Image`tCtrl + Shift + Click"), shell32.dll, 142
Menu ContextMenu, Add, % LD_T("button_menu.generate_image", "Generate Default Image"), GuiGenerarImagenBoton
Menu ContextMenu, Icon, % LD_T("button_menu.generate_image", "Generate Default Image"), shell32.dll, 135
Menu ContextMenu, Add, % LD_T("button_menu.button_name", "Button Name`tCtrl + Click"), GuiInfoBoton
Menu ContextMenu, Icon, % LD_T("button_menu.button_name", "Button Name`tCtrl + Click"), shell32.dll, 24
Menu ContextMenu, Add
Menu ContextMenu, Add, % LD_T("button_menu.copy_button", "Copy Button"), GuiCopyButton
Menu ContextMenu, Icon, % LD_T("button_menu.copy_button", "Copy Button"), shell32.dll, 134
Menu ContextMenu, Add, % LD_T("button_menu.paste_button", "Paste Button"), GuiPasteButton
Menu ContextMenu, Icon, % LD_T("button_menu.paste_button", "Paste Button"), shell32.dll, 146
Menu ContextMenu, Add, % LD_T("button_menu.move_button", "Move Button"), GuiMoveButton
Menu ContextMenu, Icon, % LD_T("button_menu.move_button", "Move Button"), shell32.dll, 147
Menu ContextMenu, Add
Menu ContextMenu, Add, % LD_T("button_menu.create_folder", "Create Folder Button"), CreateFolderButton
Menu ContextMenu, Icon, % LD_T("button_menu.create_folder", "Create Folder Button"), .\resources\img\ico\windows\folder.ico
Menu ContextMenu, Add, % LD_T("button_menu.delete_folder", "Delete Folder Button"), DeleteFolderButton
Menu ContextMenu, Icon, % LD_T("button_menu.delete_folder", "Delete Folder Button"), shell32.dll, 235
Menu ContextMenu, Add, % LD_T("button_menu.delete_function", "Delete Button Function"), DeleteButtonFunction
Menu ContextMenu, Icon, % LD_T("button_menu.delete_function", "Delete Button Function"), shell32.dll, 132

; CONNECTION TO SERVER (ONLINE == 1)
if(conf.online)
{
	GuiControl, splashScreen:, splashTxt, % conf.ip ":" conf.port " - Connecting to server..."
	sleep, 1 ; Needed to apply previous GuiControl
	if(!LibreDeckConnectWithRetry(conf.ip, conf.port, LD_TCP_CONNECT_ATTEMPTS))
	{
		LibreDeckSwitchToOfflineMode(LD_T("network.status_offline_after_failed_reconnect", "Connection failed twice. Offline mode enabled."), false)
		gosub, precargaIconosLocalesEnRam
		GuiControl, , wifi_icon, % btnPics["wifi_icon_offline.png"] ? "HBITMAP:*" btnPics["wifi_icon_offline.png"] : ""
		serverFound := 0 ; Online Mode but couldn't connect, so we keep Offline Functionality
		GuiControl, splashScreen:, splashTxt, % tcpCon.errorNM
		Sleep, 500
	}
	else
	{
		serverFound := 1
		LD_ReconnectAttemptCount := 0
		SetTimer, LibreDeckConnectionWatchdog, 5000
		GuiControl, splashScreen:, splashTxt, % "Connected! Downloading Profile..."
		gosub, downloadServerProfile
		GuiControl, , wifi_icon, % btnPics["wifi_icon_online.png"] ? "HBITMAP:*" btnPics["wifi_icon_online.png"] : ""
		FileRead, server_config, % "./resources/img/" conf.ip "/resourcePack_info.txt"
		server_config := JSON.Load(server_config)
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
	Menu, tray, Rename, % LD_T("tray.hide", "Hide"), % LD_T("tray.show", "Show")
	EsVisible = 0
}
else
{
	WinShow, LibreDeck Client
	WinActivate, LibreDeck Client
	Menu, tray, Rename, % LD_T("tray.show", "Show"), % LD_T("tray.hide", "Hide")
	EsVisible = 1
}
Return

ChangeLanguageFromTray:
	conf.language := A_ThisMenuItem
	gosub, guardarConfigCambioOnline
	reload
return

GuiContextMenu:
	if GetKeyState("Alt")
		scriptGen := 1
	else
		scriptGen := 0
	if GetKeyState("Control")
		advancedMenu := 1
	else
		advancedMenu := 0
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
		else if(advancedMenu)
		{
			KeyWait, Control
			Menu ContextMenu, Show
		}
		else
			ShowButtonEditor(BotonActivo)
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

GuiGenerarImagenBoton:
	GenerarImagenBotonDefault(BotonActivo)
return

GuiButtonEditor:
	ShowButtonEditor(BotonActivo)
return

GuiInfoBoton:
	MsgBox,,Button ID, Clicked button Id is: %BotonActivo%
return

GuiCopyButton:
	LD_CopyButton(BotonActivo)
return

GuiPasteButton:
	LD_PasteButton(BotonActivo)
return

GuiMoveButton:
	LD_MoveButton(BotonActivo)
return

NotImplemented:
	MsgBox, Not implemented
return

ScriptGeneratorMenuCommand:
	ScriptGeneratorPregenerarImagenBoton(BotonActivo, A_ThisMenuItem)
	handler := LD_ScriptGeneratorMenuHandlers[A_ThisMenu "|" A_ThisMenuItem]
	if(handler != "")
		Gosub, %handler%
return

ComprobarExistenciaBoton()
{
	buttonPath := GetButtonScriptRelativePath(BotonActivo, "ahk")
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
		Menu ContextMenuGenerico, UnCheck, % LD_T("app_menu.always_on_top", "Always on Top")
	}
	else
	{
		Winset, AlwaysOnTop, , LibreDeck Client
		conf.siempreVisible := 1
		Menu ContextMenuGenerico, Check, % LD_T("app_menu.always_on_top", "Always on Top")
	}
	gosub, guardarConfig
return

SetSiempreVisibleInicial:
	if(!conf.siempreVisible)
	{
		Winset, AlwaysOnTop, Off, LibreDeck Client
		Menu ContextMenuGenerico, UnCheck, % LD_T("app_menu.always_on_top", "Always on Top")
	}
	else
	{
		Winset, AlwaysOnTop, , LibreDeck Client
		Menu ContextMenuGenerico, Check, % LD_T("app_menu.always_on_top", "Always on Top")
	}
return

MoverRatonAlPulsarBotonToggle:
	if(conf.moverRatonAlPulsarBoton)
	{
		conf.moverRatonAlPulsarBoton := 0
		Menu ContextMenuGenerico, UnCheck, % LD_T("app_menu.center_mouse", "Center Mouse after Activation")
	}
	else
	{
		conf.moverRatonAlPulsarBoton := 1
		Menu ContextMenuGenerico, Check, % LD_T("app_menu.center_mouse", "Center Mouse after Activation")
	}
	gosub, guardarConfig
return

enviarAltTabAlPulsarBotonToggle:
	if(conf.enviarAltTabAlPulsarBoton)
	{
		conf.enviarAltTabAlPulsarBoton := 0
		Menu ContextMenuGenerico, UnCheck, % LD_T("app_menu.send_alt_tab", "Send Alt+Tab after Activation")
	}
	else
	{
		conf.enviarAltTabAlPulsarBoton := 1
		Menu ContextMenuGenerico, Check, % LD_T("app_menu.send_alt_tab", "Send Alt+Tab after Activation")
	}
	gosub, guardarConfig
return

cargaProgresivaIconosToggle:
	if(conf.cargaProgresivaIconos)
	{
		conf.cargaProgresivaIconos := 0
		Menu ContextMenuGenerico, UnCheck, % LD_T("app_menu.progressive_icon_loading", "Progressive Icon Loading")
	}
	else
	{
		conf.cargaProgresivaIconos := 1
		Menu ContextMenuGenerico, Check, % LD_T("app_menu.progressive_icon_loading", "Progressive Icon Loading")
	}
	gosub, guardarConfig
return

toggleBuiltInAhk:
	if(conf.builtin_ahk)
	{
		conf.builtin_ahk := 0
		Menu ContextMenuGenerico, UnCheck, % LD_T("app_menu.use_builtin_ahk", "Use built-in AHK")
	}
	else
	{
		conf.builtin_ahk := 1
		Menu ContextMenuGenerico, Check, % LD_T("app_menu.use_builtin_ahk", "Use built-in AHK")
	}
	gosub, guardarConfig
return
 
CambiarDimensionesCliente:
if(!conf.cargaProgresivaIconos)
	DllCall("LockWindowUpdate", "UInt", windowHandler)
if conf.miniClient
{
	Menu, ContextMenuGenerico, Rename, % LD_T("app_menu.normal_client", "Normal Client"), % LD_T("app_menu.mini_client", "Mini Client")
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
	Menu, ContextMenuGenerico, Rename, % LD_T("app_menu.mini_client", "Mini Client"), % LD_T("app_menu.normal_client", "Normal Client")
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
			Menu ContextMenuGenerico, Disable, % LD_T("app_menu.bind_folder", "Bind this folder to a program or window")
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
	Menu ContextMenuGenerico, Enable, % LD_T("app_menu.bind_folder", "Bind this folder to a program or window")
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
	LD_RefreshSelectionIndicators()
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
	LD_RefreshSelectionIndicators()
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
	MsgBox 0x23, Change - Delete, Change Image or Remove it?
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
		buttonPath := GetButtonScriptRelativePath(IdBoton, "ahk")
		if(FileExist(buttonPath))
		{
			OnMessage(0x44, "OnMsgBox")
			MsgBoxBtn1 = Delete
			MsgBoxBtn2 = Keep
			MsgBox 0x34, Overwrite?, This button has a macro file`, do you want to delete it?`n`nIts function will be lost!
			OnMessage(0x44, "")

			IfMsgBox Yes, {
				FileDelete, %buttonPath%
			}
		}
	} 
	Else IfMsgBox Cancel, {
		return
	}	
	;~ Sleep, 300 ; Lo he quitado porque para qué esperar
	Gui, 1:Default
	if(EnCarpeta)
	{
		EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
	}
	else
	{
		EstablecerPagina(NumeroPagina)	
	}
}

GenerarImagenBotonDefault(IdBoton)
{
	global btnPics
	InputBox, buttonImageType, Button Image Type, Insert action type`nExamples`: MACRO`, OBS`, APP`, HOTKEY, , 420, 145,,,,,MACRO
	if(ErrorLevel)
		return
	buttonImageType := Trim(buttonImageType)
	;~ if(buttonImageType = "")
		;~ buttonImageType := "MACRO"

	InputBox, buttonImageTitle, Button Image Title, Insert main button title`nExamples`: Record`, Mute Mic`, Browser, , 420, 145,,,,,Demo
	if(ErrorLevel)
		return
	buttonImageTitle := Trim(buttonImageTitle)
	;~ if(buttonImageTitle = "") {
		;~ MsgBox, Button title can not be empty.
		;~ return
	;~ }

	InputBox, buttonImageSubtitle, Button Image Subtitle, Insert short description`nExamples`: LibreDeck`, OBS`, Spotify, , 420, 145,,,,,LibreDeck
	if(ErrorLevel)
		return
	buttonImageSubtitle := Trim(buttonImageSubtitle)
	;~ if(buttonImageSubtitle = "")
		;~ buttonImageSubtitle := "LibreDeck"

	buttonImageStyle := GenerarImagenBotonDefaultSeleccionarEstilo()
	if(buttonImageStyle = "")
		return
	
	if (buttonImageStyle == "image") {
		FileSelectFile, imageSelected, 3,, Select image, *.png; *.jpg; *.jpeg; *.bmp; *.gif; *.ico
		if (!ErrorLevel) {
			buttonImagePath := imageSelected
			buttonImageFit := "cover" ; cover | contain | stretch
		} else {
			MsgBox,,Error, Could not generate button image.
			return
		}
	}
	
	Gui, 1:Default

	outDir := A_ScriptDir "\resources\img"
	FileCreateDir, %outDir%
	imageName := IdBoton ".png"
	imagePath := outDir "\" imageName

	if(FileExist(imagePath))
	{
		OnMessage(0x44, "OnMsgBox")
		MsgBoxBtn1 = Overwrite
		MsgBoxBtn2 = Cancel
		MsgBox 0x34, Overwrite Image?, This button already has an image`, do you want to overwrite it?
		OnMessage(0x44, "")
		IfMsgBox No, {
			return
		}
	}

	DllCall("DeleteObject", "ptr", btnPics[imageName])
	btnPics[imageName] := ""
	FileDelete, %imagePath%

	if (buttonImageStyle == "image") {
		if(!LD_ButtonImage_Render(imagePath, {style:buttonImageStyle, imagePath:buttonImagePath, imageFit:buttonImageFit, title:buttonImageType, subtitle:buttonImageSubtitle}))
		{
			MsgBox,,Error, Could not generate button image.
			return
		}
	} else {
		if(!LD_ButtonImage_Render(imagePath, {style:buttonImageStyle, title:buttonImageType, value:buttonImageTitle, subtitle:buttonImageSubtitle}))
		{
			MsgBox,,Error, Could not generate button image.
			return
		}
	}

	btnPics[imageName] := LoadPicture(imagePath)
	Gui, 1:Default
	if(EnCarpeta)
	{
		EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
	}
	else
	{
		EstablecerPagina(NumeroPagina)
	}
}

ScriptGeneratorPregenerarImagenBoton(IdBoton, menuText := "")
{
	global btnPics

	outDir := A_ScriptDir "\resources\img"
	FileCreateDir, %outDir%
	imageName := IdBoton ".png"
	imagePath := outDir "\" imageName
	subtitle := menuText != "" ? menuText : "Script Generator"
	displayId := IdBoton
	if(EnCarpeta && CarpetaBoton != "" && SubStr(displayId, 1, StrLen(CarpetaBoton)) = CarpetaBoton)
		displayId := SubStr(displayId, StrLen(CarpetaBoton) + 1)

	DllCall("DeleteObject", "ptr", btnPics[imageName])
	btnPics[imageName] := ""
	FileDelete, %imagePath%

	if(!LD_ButtonImage_Render(imagePath, {style:"minimal", title:"SCRIPT", value:displayId, subtitle:subtitle}))
		return false

	btnPics[imageName] := LoadPicture(imagePath)
	Gui, 1:Default
	if(EnCarpeta)
		EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
	else
		EstablecerPagina(NumeroPagina)
	return true
}

GenerarImagenBotonDefaultSeleccionarEstilo()
{
	global LD_ButtonImage_SelectedStyle, LD_ButtonImage_StyleCancelled

	LD_ButtonImage_SelectedStyle := "minimal"
	LD_ButtonImage_StyleCancelled := 1

	Gui, ButtonImageStyle:New, +AlwaysOnTop +ToolWindow +OwnDialogs, Button Image Style
	Gui, ButtonImageStyle:Margin, 12, 12
	Gui, ButtonImageStyle:Add, Text, w260, Choose button image style:
	Gui, ButtonImageStyle:Add, DropDownList, vLD_ButtonImage_SelectedStyle w260 Choose6, neon|resident|warning|pokemon|glass|minimal|image
	Gui, ButtonImageStyle:Add, Button, x70 y80 w80 Default gButtonImageStyleOK, OK
	Gui, ButtonImageStyle:Add, Button, x160 y80 w80 gButtonImageStyleCancel, Cancel
	Gui, ButtonImageStyle:Show,, Button Image Style
	WinWaitClose, Button Image Style
	Gui, 1:Default

	if(LD_ButtonImage_StyleCancelled)
		return ""
	return LD_ButtonImage_SelectedStyle
}

ButtonImageStyleOK:
	Gui, ButtonImageStyle:Submit
	LD_ButtonImage_StyleCancelled := 0
	Gui, ButtonImageStyle:Destroy
	Gui, 1:Default
return

ButtonImageStyleCancel:
ButtonImageStyleGuiClose:
ButtonImageStyleGuiEscape:
	LD_ButtonImage_StyleCancelled := 1
	Gui, ButtonImageStyle:Destroy
	Gui, 1:Default
return

ShowButtonEditor(IdBoton)
{
	global LD_ButtonEditorActiveId, EnCarpeta, CarpetaBoton, PaginaCarpeta, NumeroPagina, conf
	global ButtonEditorIdTxt, ButtonEditorDisplayTxt, ButtonEditorIsFolderChk, ButtonEditorFolderTxt, ButtonEditorScriptTxt, ButtonEditorPreview, ButtonEditorStatus
	global ButtonEditorEditScriptBtn, ButtonEditorChangeImageBtn, ButtonEditorGenerateImageBtn, ButtonEditorTestBtn
	global ButtonEditorCreateFolderBtn, ButtonEditorDeleteFolderBtn, ButtonEditorDeleteFunctionBtn, ButtonEditorScriptGeneratorBtn
	global ButtonEditorCopyButtonBtn, ButtonEditorPasteButtonBtn, ButtonEditorMoveButtonBtn
	global ButtonEditorSelectButtonBtn, ButtonEditorDeselectAllBtn, ButtonEditorSelectionTxt

	LD_ButtonEditorActiveId := IdBoton
	displayId := GetButtonDisplayId(IdBoton)
	scriptPath := GetButtonScriptRelativePath(IdBoton, conf.extension)
	folderInfo := GetButtonEditorFolderInfo(IdBoton)
	isFolderChecked := folderInfo.isFolder ? "Checked" : ""

	Gui, ButtonEditor:Destroy
	Gui, ButtonEditor:New, +ToolWindow +OwnDialogs, LibreDeck Button Editor
	Gui, ButtonEditor:Margin, 12, 12
	Gui, ButtonEditor:Font, s9, Segoe UI
	Gui, ButtonEditor:Add, Text, x12 y10 w90 h23 +0x200, % LD_T("button_editor.button_id", "Button ID:")
	Gui, ButtonEditor:Add, Edit, x110 y10 w250 h21 ReadOnly vButtonEditorIdTxt, %IdBoton%
	Gui, ButtonEditor:Add, Text, x12 y40 w90 h23 +0x200, % LD_T("button_editor.display", "Display:")
	Gui, ButtonEditor:Add, Edit, x110 y40 w250 h21 ReadOnly vButtonEditorDisplayTxt, %displayId%
	Gui, ButtonEditor:Add, Text, x12 y70 w90 h23 +0x200, % LD_T("button_editor.folder", "Folder:")
	Gui, ButtonEditor:Add, Edit, x110 y70 w120 h21 ReadOnly vButtonEditorFolderTxt, % folderInfo.name
	Gui, ButtonEditor:Add, CheckBox, x240 y70 w120 h23 Disabled %isFolderChecked% vButtonEditorIsFolderChk, % LD_T("button_editor.is_folder_button", "Is folder button")
	Gui, ButtonEditor:Add, Text, x12 y100 w90 h23 +0x200, % LD_T("button_editor.script", "Script:")
	Gui, ButtonEditor:Add, Edit, x110 y100 w250 h21 ReadOnly vButtonEditorScriptTxt, %scriptPath%
	Gui, ButtonEditor:Add, Picture, x390 y10 w128 h128 vButtonEditorPreview, % ButtonEditorPreviewSource(IdBoton)

	Gui, ButtonEditor:Add, Button, x12 y142 w110 h28 vButtonEditorEditScriptBtn gButtonEditorEditScript, % LD_T("button_editor.edit_script", "Edit Script")
	Gui, ButtonEditor:Add, Button, x130 y142 w110 h28 vButtonEditorChangeImageBtn gButtonEditorChangeImage, % LD_T("button_editor.change_image", "Change Image")
	Gui, ButtonEditor:Add, Button, x248 y142 w110 h28 vButtonEditorGenerateImageBtn gButtonEditorGenerateImage, % LD_T("button_editor.generate_image", "Generate Image")
	Gui, ButtonEditor:Add, Button, x366 y142 w110 h28 vButtonEditorTestBtn gButtonEditorTest, % LD_T("button_editor.test", "Test")
	Gui, ButtonEditor:Add, Button, x12 y178 w110 h28 vButtonEditorCreateFolderBtn gButtonEditorCreateFolder, % LD_T("button_editor.create_folder", "Create Folder")
	Gui, ButtonEditor:Add, Button, x130 y178 w110 h28 vButtonEditorDeleteFolderBtn gButtonEditorDeleteFolder, % LD_T("button_editor.delete_folder", "Delete Folder")
	Gui, ButtonEditor:Add, Button, x248 y178 w110 h28 vButtonEditorDeleteFunctionBtn gButtonEditorDeleteFunction, % LD_T("button_editor.delete_function", "Delete Function")
	Gui, ButtonEditor:Add, Button, x366 y178 w110 h28 vButtonEditorScriptGeneratorBtn gButtonEditorScriptGenerator, % LD_T("button_editor.script_generator", "Script Gen")
	Gui, ButtonEditor:Add, Button, x12 y214 w110 h28 vButtonEditorCopyButtonBtn gButtonEditorCopyButton, % LD_T("button_editor.copy_button", "Copy Button")
	Gui, ButtonEditor:Add, Button, x130 y214 w110 h28 vButtonEditorPasteButtonBtn gButtonEditorPasteButton, % LD_T("button_editor.paste_button", "Paste Button")
	Gui, ButtonEditor:Add, Button, x248 y214 w110 h28 vButtonEditorMoveButtonBtn gButtonEditorMoveButton, % LD_T("button_editor.move_button", "Move Button")
	Gui, ButtonEditor:Add, Button, x366 y214 w110 h28 vButtonEditorSelectButtonBtn gButtonEditorSelectButton, % LD_T("button_editor.select_button", "Select")
	Gui, ButtonEditor:Add, Button, x12 y250 w110 h28 vButtonEditorDeselectAllBtn gButtonEditorDeselectAll, % LD_T("button_editor.deselect_all", "Deselect All")
	Gui, ButtonEditor:Add, Text, x130 y250 w346 h28 +Center +0x200 vButtonEditorSelectionTxt, % LD_T("button_editor.selection_count", "Selected: {count}", {count: 0})
	Gui, ButtonEditor:Add, Text, x12 y286 w506 h23 +Center +0x200 vButtonEditorStatus, % LD_T("button_editor.ready", "Ready")
	ButtonEditorUpdateActions(IdBoton)
	Gui, ButtonEditor:Show, w532 h320, LibreDeck Button Editor
}

ButtonEditorPreviewSource(IdBoton)
{
	global btnPics
	imageName := IdBoton ".png"
	if(btnPics[imageName])
		return "HBITMAP:*" btnPics[imageName]
	if(btnPics["button_placeholder.png"])
		return "HBITMAP:*" btnPics["button_placeholder.png"]
	return ""
}

ButtonEditorRefreshInfo()
{
	global LD_ButtonEditorActiveId, conf
	if(!WinExist("LibreDeck Button Editor") || LD_ButtonEditorActiveId = "")
		return
	IdBoton := LD_ButtonEditorActiveId
	scriptPath := GetButtonScriptRelativePath(IdBoton, conf.extension)
	folderInfo := GetButtonEditorFolderInfo(IdBoton)
	GuiControl, ButtonEditor:, ButtonEditorDisplayTxt, % GetButtonDisplayId(IdBoton)
	GuiControl, ButtonEditor:, ButtonEditorIsFolderChk, % folderInfo.isFolder
	GuiControl, ButtonEditor:, ButtonEditorFolderTxt, % folderInfo.name
	GuiControl, ButtonEditor:, ButtonEditorScriptTxt, %scriptPath%
	GuiControl, ButtonEditor:, ButtonEditorPreview, % ButtonEditorPreviewSource(IdBoton)
	ButtonEditorUpdateActions(IdBoton)
	GuiControl, ButtonEditor:, ButtonEditorStatus, % LD_T("button_editor.updated", "Updated")
}

ButtonEditorUpdateActions(IdBoton)
{
	global conf, LD_ButtonClipboard, LD_ButtonMoveSource
	selectedCount := LD_SelectedButtonCount()

	folderInfo := GetButtonEditorFolderInfo(IdBoton)
	scriptPath := GetButtonScriptRelativePath(IdBoton, conf.extension)
	imagePath := GetButtonImageRelativePath(IdBoton)
	hasScript := FileExist(A_ScriptDir "\" scriptPath) ? 1 : 0
	hasImage := FileExist(A_ScriptDir "\" imagePath) ? 1 : 0
	hasContent := hasScript || hasImage || folderInfo.isFolder
	canPaste := LD_ClipboardHasButtons()
	canMove := hasContent || selectedCount > 0 || LD_ButtonMoveSource != ""
	canCopy := hasContent || selectedCount > 0

	ButtonEditorSetControlEnabled("ButtonEditorCreateFolderBtn", !folderInfo.isFolder)
	ButtonEditorSetControlEnabled("ButtonEditorDeleteFolderBtn", folderInfo.isFolder)
	ButtonEditorSetControlEnabled("ButtonEditorDeleteFunctionBtn", hasScript || selectedCount > 0)
	ButtonEditorSetControlEnabled("ButtonEditorCopyButtonBtn", canCopy)
	ButtonEditorSetControlEnabled("ButtonEditorPasteButtonBtn", canPaste)
	ButtonEditorSetControlEnabled("ButtonEditorMoveButtonBtn", canMove)
	ButtonEditorSetControlEnabled("ButtonEditorSelectButtonBtn", !LD_IsButtonSelected(IdBoton))
	ButtonEditorSetControlEnabled("ButtonEditorDeselectAllBtn", selectedCount > 0)
	GuiControl, ButtonEditor:, ButtonEditorSelectionTxt, % LD_T("button_editor.selection_count", "Selected: {count}", {count: selectedCount})
}

ButtonEditorSetControlEnabled(controlName, enabled)
{
	if(enabled)
		GuiControl, ButtonEditor:Enable, %controlName%
	else
		GuiControl, ButtonEditor:Disable, %controlName%
}

GetButtonEditorFolderInfo(IdBoton)
{
	global conf, EnCarpeta, CarpetaBoton

	info := {}
	info.isFolder := conf.folderButtons[IdBoton] != ""
	if(info.isFolder)
		info.name := conf.folderButtons[IdBoton]
	else if(EnCarpeta && CarpetaBoton != "")
		info.name := CarpetaBoton
	else
		info.name := "-"
	return info
}

GetButtonDisplayId(IdBoton)
{
	global EnCarpeta, CarpetaBoton
	displayId := IdBoton
	if(EnCarpeta && CarpetaBoton != "" && SubStr(displayId, 1, StrLen(CarpetaBoton)) = CarpetaBoton)
		displayId := SubStr(displayId, StrLen(CarpetaBoton) + 1)
	return displayId
}

GetButtonVisualId(IdBoton)
{
	displayId := GetButtonDisplayId(IdBoton)
	visualId := Mod(displayId, 15)
	if(visualId = 0)
		visualId := 15
	return visualId
}

ButtonEditorEditScript:
	EditarScriptBoton(LD_ButtonEditorActiveId)
return

ButtonEditorChangeImage:
	EstablecerImagenBoton(LD_ButtonEditorActiveId)
	ButtonEditorRefreshInfo()
return

ButtonEditorGenerateImage:
	GenerarImagenBotonDefault(LD_ButtonEditorActiveId)
	ButtonEditorRefreshInfo()
return

ButtonEditorTest:
	EjecutarFuncionBoton(GetButtonVisualId(LD_ButtonEditorActiveId), LD_ButtonEditorActiveId)
return

ButtonEditorCreateFolder:
	BotonActivo := LD_ButtonEditorActiveId
	gosub, CreateFolderButton
	ButtonEditorRefreshInfo()
return

ButtonEditorDeleteFolder:
	BotonActivo := LD_ButtonEditorActiveId
	gosub, DeleteFolderButton
	ButtonEditorRefreshInfo()
return

ButtonEditorDeleteFunction:
	BotonActivo := LD_ButtonEditorActiveId
	gosub, DeleteButtonFunction
	ButtonEditorRefreshInfo()
return

ButtonEditorScriptGenerator:
	BotonActivo := LD_ButtonEditorActiveId
	Menu scriptGenerator, Show
	ButtonEditorRefreshInfo()
return

ButtonEditorCopyButton:
	LD_CopyButton(LD_ButtonEditorActiveId)
	ButtonEditorRefreshInfo()
return

ButtonEditorPasteButton:
	LD_PasteButton(LD_ButtonEditorActiveId)
	ButtonEditorRefreshInfo()
return

ButtonEditorMoveButton:
	LD_MoveButton(LD_ButtonEditorActiveId)
	ButtonEditorRefreshInfo()
return

ButtonEditorSelectButton:
	LD_SelectButton(LD_ButtonEditorActiveId)
	ButtonEditorRefreshInfo()
return

ButtonEditorDeselectAll:
	LD_ClearButtonSelection()
	ButtonEditorRefreshInfo()
return

ButtonEditorGuiClose:
ButtonEditorGuiEscape:
	Gui, ButtonEditor:Destroy
return

GetButtonScriptRelativePath(IdBoton, extension = "")
{
	global conf
	if(extension = "")
		extension := conf.extension
	if(SubStr(extension, 1, 1) != ".")
		extension := "." extension

	bestFolder := ""
	bestSuffix := ""
	for, k, folderName in conf.folderButtons
	{
		if(folderName = "")
			continue
		if(SubStr(IdBoton, 1, StrLen(folderName)) = folderName)
		{
			suffix := SubStr(IdBoton, StrLen(folderName) + 1)
			if suffix is integer
			{
				if(StrLen(folderName) > StrLen(bestFolder))
				{
					bestFolder := folderName
					bestSuffix := suffix
				}
			}
		}
	}

	if(bestFolder != "")
		return "buttons\" bestFolder "\" bestSuffix extension
	return "buttons\" IdBoton extension
}

EnsureButtonScriptDirectory(scriptPath)
{
	SplitPath, scriptPath,, scriptDir
	if(scriptDir != "")
		FileCreateDir, %scriptDir%
}

CopyScriptToButton(sourcePath, IdBoton = "")
{
	global BotonActivo
	if(IdBoton = "")
		IdBoton := BotonActivo
	buttonPath := GetButtonScriptRelativePath(IdBoton, "ahk")
	EnsureButtonScriptDirectory(buttonPath)
	FileCopy, %sourcePath%, % A_ScriptDir "\" buttonPath, 1
}

GetButtonImageRelativePath(IdBoton)
{
	return "resources\img\" IdBoton ".png"
}

LD_CopyButton(IdBoton)
{
	global LD_ButtonClipboard

	LD_ButtonClipboard := LD_BuildButtonClipboardFromSelectionOrButton(IdBoton)
	setNotificationBottom(LD_T("button_menu.copy_done", "Button copied"), 1200)
}

LD_PasteButton(IdBoton)
{
	global LD_ButtonClipboard, conf

	if(!LD_ClipboardHasButtons())
	{
		MsgBox,, % LD_T("button_menu.paste_title", "Paste Button"), % LD_T("button_menu.empty_clipboard", "Copy a button first.")
		return
	}
	if(LD_ButtonClipboard.buttons.Length() = 1 && LD_ButtonClipboard.buttons[1].id = IdBoton)
	{
		MsgBox,, % LD_T("button_menu.paste_title", "Paste Button"), % LD_T("button_menu.same_button", "Choose a different button to paste into.")
		return
	}

	targetIds := LD_GetSequentialButtonTargets(IdBoton, LD_ButtonClipboard.buttons.Length())
	if(!LD_ConfirmOverwriteButtons(targetIds))
		return

	for index, clipData in LD_ButtonClipboard.buttons
	{
		targetId := targetIds[index]
		LD_PasteButtonData(clipData, targetId)
	}
	gosub, guardarConfig
	LD_ButtonsChanged(targetIds)
	setNotificationBottom(LD_T("button_menu.paste_done", "Button pasted"), 1200)
}

LD_MoveButton(IdBoton)
{
	global LD_ButtonMoveSource, conf

	selectedCount := LD_SelectedButtonCount()
	if(selectedCount > 0)
	{
		moveClipboard := LD_BuildButtonClipboardFromSelectionOrButton(IdBoton)
		moveDataList := moveClipboard.buttons
		targetIds := LD_GetSequentialButtonTargets(IdBoton, moveDataList.Length())
		if(!LD_ConfirmOverwriteButtons(targetIds))
			return
		for index, clipData in moveDataList
		{
			targetId := targetIds[index]
			LD_PasteButtonData(clipData, targetId)
		}
		for index, clipData in moveDataList
		{
			if(!LD_ArrayContains(targetIds, clipData.id))
				LD_ClearButton(clipData.id)
		}
		LD_ClearButtonSelection()
		gosub, guardarConfig
		LD_ButtonsChanged(targetIds)
		LD_ButtonsChanged(LD_GetIdsFromClipDataList(moveDataList))
		setNotificationBottom(LD_T("button_menu.move_done", "Button moved"), 1200)
		return
	}

	if(LD_ButtonMoveSource = "")
	{
		LD_ButtonMoveSource := IdBoton
		setNotificationBottom(LD_T("button_menu.move_select_destination", "Select destination button"), 1800)
		return
	}
	if(LD_ButtonMoveSource = IdBoton)
	{
		LD_ButtonMoveSource := ""
		setNotificationBottom(LD_T("button_menu.move_cancelled", "Move cancelled"), 1200)
		return
	}
	if(!LD_ConfirmOverwriteButton(IdBoton))
		return

	moveData := LD_BuildButtonClipboardData(LD_ButtonMoveSource)
	LD_PasteButtonData(moveData, IdBoton)
	LD_ClearButton(LD_ButtonMoveSource)
	LD_ButtonMoveSource := ""
	gosub, guardarConfig
	LD_ButtonChanged(moveData.id)
	LD_ButtonChanged(IdBoton)
	setNotificationBottom(LD_T("button_menu.move_done", "Button moved"), 1200)
}

LD_SelectButton(IdBoton)
{
	global LD_ButtonSelection, LD_ButtonSelectionMap

	if(LD_ButtonSelectionMap[IdBoton])
		return
	LD_ButtonSelection.Push(IdBoton)
	LD_ButtonSelectionMap[IdBoton] := 1
	LD_RefreshSelectionIndicators()
	setNotificationBottom(LD_T("button_menu.selection_added", "Button selected"), 900)
}

LD_ClearButtonSelection()
{
	global LD_ButtonSelection, LD_ButtonSelectionMap

	LD_ButtonSelection := []
	LD_ButtonSelectionMap := {}
	LD_RefreshSelectionIndicators()
	setNotificationBottom(LD_T("button_menu.selection_cleared", "Selection cleared"), 900)
}

LD_IsButtonSelected(IdBoton)
{
	global LD_ButtonSelectionMap

	return LD_ButtonSelectionMap[IdBoton] ? 1 : 0
}

LD_SelectedButtonCount()
{
	global LD_ButtonSelection

	if(IsObject(LD_ButtonSelection))
		return LD_ButtonSelection.Length()
	return 0
}

LD_BuildButtonClipboardFromSelectionOrButton(IdBoton)
{
	global LD_ButtonSelection

	clipboardData := {}
	clipboardData.buttons := []
	if(LD_SelectedButtonCount() > 0)
	{
		for index, selectedId in LD_ButtonSelection
			clipboardData.buttons.Push(LD_BuildButtonClipboardData(selectedId))
	}
	else
	{
		clipboardData.buttons.Push(LD_BuildButtonClipboardData(IdBoton))
	}
	clipboardData.id := clipboardData.buttons[1].id
	return clipboardData
}

LD_ClipboardHasButtons()
{
	global LD_ButtonClipboard

	return IsObject(LD_ButtonClipboard) && IsObject(LD_ButtonClipboard.buttons) && LD_ButtonClipboard.buttons.Length() > 0
}

LD_DeleteSelectedButtons()
{
	global LD_ButtonSelection, MsgBoxBtn1, MsgBoxBtn2

	if(LD_SelectedButtonCount() = 0)
		return
	OnMessage(0x44, "OnMsgBox")
	MsgBoxBtn1 := LD_T("button_menu.delete_selected", "Delete")
	MsgBoxBtn2 := LD_T("button_menu.cancel", "Cancel")
	MsgBox 0x34, % LD_T("button_menu.delete_selected_title", "Delete Selected Buttons?"), % LD_T("button_menu.delete_selected_prompt", "Delete scripts, images and folder links from selected buttons?")
	OnMessage(0x44, "")
	IfMsgBox No
		return

	changedIds := []
	for index, selectedId in LD_ButtonSelection
	{
		LD_ClearButton(selectedId)
		changedIds.Push(selectedId)
	}
	LD_ClearButtonSelection()
	gosub, guardarConfig
	LD_ButtonsChanged(changedIds)
	setNotificationBottom(LD_T("button_menu.delete_selected_done", "Selected buttons deleted"), 1200)
}

LD_BuildButtonClipboardData(IdBoton)
{
	global conf

	data := {}
	data.id := IdBoton
	data.scriptPath := GetButtonScriptRelativePath(IdBoton, conf.extension)
	data.imagePath := GetButtonImageRelativePath(IdBoton)
	data.scriptSnapshotPath := LD_CreateButtonClipboardSnapshot(data.scriptPath, "ahk")
	data.imageSnapshotPath := LD_CreateButtonClipboardSnapshot(data.imagePath, "png")
	data.folderName := conf.folderButtons[IdBoton]
	return data
}

LD_CreateButtonClipboardSnapshot(relativePath, extension)
{
	sourcePath := A_ScriptDir "\" relativePath
	if(!FileExist(sourcePath))
		return ""
	tempDir := A_Temp "\LibreDeckButtonClipboard"
	FileCreateDir, %tempDir%
	Random, randomId, 100000, 999999
	targetPath := tempDir "\" A_Now A_MSec "_" randomId "." extension
	FileCopy, %sourcePath%, %targetPath%, 1
	return targetPath
}

LD_ButtonHasContent(IdBoton)
{
	global conf

	scriptPath := GetButtonScriptRelativePath(IdBoton, conf.extension)
	imagePath := GetButtonImageRelativePath(IdBoton)
	return FileExist(A_ScriptDir "\" scriptPath) || FileExist(A_ScriptDir "\" imagePath) || conf.folderButtons[IdBoton] != ""
}

LD_ConfirmOverwriteButton(IdBoton)
{
	global MsgBoxBtn1, MsgBoxBtn2

	if(!LD_ButtonHasContent(IdBoton))
		return 1
	OnMessage(0x44, "OnMsgBox")
	MsgBoxBtn1 := LD_T("button_menu.overwrite", "Overwrite")
	MsgBoxBtn2 := LD_T("button_menu.cancel", "Cancel")
	MsgBox 0x34, % LD_T("button_menu.overwrite_title", "Overwrite Button?"), % LD_T("button_menu.overwrite_prompt", "This button already has content. Overwrite script, image and folder data?")
	OnMessage(0x44, "")
	IfMsgBox No
		return 0
	return 1
}

LD_ConfirmOverwriteButtons(targetIds)
{
	global MsgBoxBtn1, MsgBoxBtn2

	for index, targetId in targetIds
	{
		if(LD_ButtonHasContent(targetId))
		{
			OnMessage(0x44, "OnMsgBox")
			MsgBoxBtn1 := LD_T("button_menu.overwrite", "Overwrite")
			MsgBoxBtn2 := LD_T("button_menu.cancel", "Cancel")
			MsgBox 0x34, % LD_T("button_menu.overwrite_title", "Overwrite Button?"), % LD_T("button_menu.overwrite_many_prompt", "One or more destination buttons already have content. Overwrite scripts, images and folder data?")
			OnMessage(0x44, "")
			IfMsgBox No
				return 0
			return 1
		}
	}
	return 1
}

LD_GetSequentialButtonTargets(startId, count)
{
	global EnCarpeta, CarpetaBoton, PaginaCarpeta, NumeroPagina

	targetIds := []
	startVisual := LD_GetButtonVisualIndexOnCurrentPage(startId)
	if(!startVisual)
		startVisual := 1
	if(EnCarpeta)
	{
		prefix := CarpetaBoton
		page := PaginaCarpeta
	}
	else
	{
		prefix := ""
		page := NumeroPagina
	}
	Loop, %count%
	{
		visualIndex := startVisual + A_Index - 1
		targetIds.Push(prefix 15*page+visualIndex)
	}
	return targetIds
}

LD_PasteButtonData(clipData, IdBoton)
{
	LD_PasteButtonScript(clipData, IdBoton)
	LD_PasteButtonImage(clipData, IdBoton)
	LD_PasteButtonFolder(clipData, IdBoton)
}

LD_ArrayContains(values, needle)
{
	for index, value in values
	{
		if(value = needle)
			return 1
	}
	return 0
}

LD_GetIdsFromClipDataList(dataList)
{
	ids := []
	for index, clipData in dataList
		ids.Push(clipData.id)
	return ids
}

LD_PasteButtonScript(clipData, IdBoton)
{
	global conf

	sourcePath := clipData.scriptSnapshotPath != "" ? clipData.scriptSnapshotPath : A_ScriptDir "\" clipData.scriptPath
	targetPath := GetButtonScriptRelativePath(IdBoton, conf.extension)
	targetFullPath := A_ScriptDir "\" targetPath
	if(FileExist(sourcePath))
	{
		EnsureButtonScriptDirectory(targetPath)
		FileCopy, %sourcePath%, %targetFullPath%, 1
	}
	else if(FileExist(targetFullPath))
	{
		FileDelete, %targetFullPath%
	}
}

LD_PasteButtonImage(clipData, IdBoton)
{
	global btnPics

	sourcePath := clipData.imageSnapshotPath != "" ? clipData.imageSnapshotPath : A_ScriptDir "\" clipData.imagePath
	targetPath := GetButtonImageRelativePath(IdBoton)
	targetFullPath := A_ScriptDir "\" targetPath
	imageName := IdBoton ".png"
	if(btnPics[imageName])
	{
		DllCall("DeleteObject", "ptr", btnPics[imageName])
		btnPics[imageName] := ""
	}
	if(FileExist(sourcePath))
		FileCopy, %sourcePath%, %targetFullPath%, 1
	else if(FileExist(targetFullPath))
		FileDelete, %targetFullPath%

	btnPics[imageName] := FileExist(targetFullPath) ? LoadPicture(targetFullPath) : ""
}

LD_PasteButtonFolder(clipData, IdBoton)
{
	global conf

	if(clipData.folderName != "")
		conf.folderButtons[IdBoton] := clipData.folderName
	else
		conf.folderButtons.delete(IdBoton)
}

LD_ClearButton(IdBoton)
{
	global conf, btnPics

	scriptPath := GetButtonScriptRelativePath(IdBoton, conf.extension)
	imagePath := GetButtonImageRelativePath(IdBoton)
	imageName := IdBoton ".png"
	if(FileExist(A_ScriptDir "\" scriptPath))
		FileDelete, % A_ScriptDir "\" scriptPath
	if(btnPics[imageName])
	{
		DllCall("DeleteObject", "ptr", btnPics[imageName])
		btnPics[imageName] := ""
	}
	if(FileExist(A_ScriptDir "\" imagePath))
		FileDelete, % A_ScriptDir "\" imagePath
	conf.folderButtons.delete(IdBoton)
}

LD_RefreshCurrentPage()
{
	global EnCarpeta, CarpetaBoton, PaginaCarpeta, NumeroPagina

	Gui, 1:Default
	if(EnCarpeta)
		EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
	else
		EstablecerPagina(NumeroPagina)
}

LD_ButtonChanged(IdBoton)
{
	global LD_ButtonEditorActiveId

	LD_RefreshCurrentPage()
	LD_RefreshButtonOnCurrentPage(IdBoton)
	if(LD_ButtonEditorActiveId = IdBoton)
		ButtonEditorRefreshInfo()
}

LD_ButtonsChanged(ids)
{
	global LD_ButtonEditorActiveId

	LD_RefreshCurrentPage()
	for index, IdBoton in ids
	{
		LD_RefreshButtonOnCurrentPage(IdBoton)
		if(LD_ButtonEditorActiveId = IdBoton)
			ButtonEditorRefreshInfo()
	}
}

LD_RefreshSelectionIndicators()
{
	global EnCarpeta, CarpetaBoton, PaginaCarpeta, NumeroPagina

	Gui, 1:Default
	Loop, 15
	{
		visualIndex := A_Index
		if(EnCarpeta)
			buttonId := CarpetaBoton 15*PaginaCarpeta+visualIndex
		else
			buttonId := 15*NumeroPagina+visualIndex
		activationControl := "Activar" visualIndex
		if(LD_IsButtonSelected(buttonId))
			GuiControl, Show, %activationControl%
		else if(!LD_IsActivationFeedbackActive(activationControl))
			GuiControl, Hide, %activationControl%
	}
}

LD_IsActivationFeedbackActive(activationControl)
{
	global feedbackEjecucion

	for index, activeControl in feedbackEjecucion
	{
		if(activeControl = activationControl)
			return 1
	}
	return 0
}

LD_GetButtonVisualIndexOnCurrentPage(IdBoton)
{
	global EnCarpeta, CarpetaBoton, PaginaCarpeta, NumeroPagina

	if(EnCarpeta)
	{
		prefix := CarpetaBoton
		page := PaginaCarpeta
	}
	else
	{
		prefix := ""
		page := NumeroPagina
	}
	Loop, 15
	{
		expectedId := prefix 15*page+A_Index
		if(expectedId = IdBoton)
			return A_Index
	}
	return 0
}

LD_RefreshButtonOnCurrentPage(IdBoton)
{
	global btnPics, EnCarpeta

	Gui, 1:Default
	visualIndex := LD_GetButtonVisualIndexOnCurrentPage(IdBoton)
	if(!visualIndex)
		return
	if(EnCarpeta && visualIndex = 15)
		imageName := "Volver.png"
	else
		imageName := IdBoton ".png"
	if(imageName != "Volver.png")
	{
		if(btnPics[imageName])
		{
			DllCall("DeleteObject", "ptr", btnPics[imageName])
			btnPics[imageName] := ""
		}
		imagePath := A_ScriptDir "\resources\img\" imageName
		if(FileExist(imagePath))
			btnPics[imageName] := LoadPicture(imagePath)
	}
	src := btnPics[imageName] ? "HBITMAP:*" btnPics[imageName] : "HBITMAP:*" btnPics["button_placeholder.png"]
	controlName := "Boton" visualIndex
	GuiControl, Text, %controlName%, %src%
	LD_MoveDrawButton(visualIndex)
	WinSet, Redraw,, LibreDeck Client
}

LD_MoveDrawButton(visualIndex)
{
	global conf

	if(conf.miniClient)
	{
		if(visualIndex <= 5)
		{
			x := 59 + (visualIndex - 1) * 56
			y := 19
		}
		else if(visualIndex <= 10)
		{
			x := 59 + (visualIndex - 6) * 56
			y := 75
		}
		else
		{
			x := 59 + (visualIndex - 11) * 56
			y := 131
		}
		size := 49
	}
	else
	{
		if(visualIndex <= 5)
		{
			x := 130 + (visualIndex - 1) * 160
			y := 50
		}
		else if(visualIndex <= 10)
		{
			x := 130 + (visualIndex - 6) * 160
			y := 230
		}
		else
		{
			x := 130 + (visualIndex - 11) * 160
			y := 410
		}
		size := 130
	}
	controlName := "Boton" visualIndex
	GuiControl, MoveDraw, %controlName%, x%x% y%y% w%size% h%size%
}

EditarScriptBoton(IdBoton)
{
	RutaScript := GetButtonScriptRelativePath(IdBoton, conf.extension)
	if(!FileExist(RutaScript))
	{
		EnsureButtonScriptDirectory(RutaScript)
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
	RutaScript := GetButtonScriptRelativePath(FicheroEjecutar, conf.extension)
	if(conf.online && serverFound)
	{
		EnviarTCP("{""BotonVisual"":""" BotonVisual """,""FicheroEjecutar"":""" StrReplace(RutaScript, "\", "/") """}")
		;~ OutputDebug, % "Enviando: " "{BotonVisual:" BotonVisual ",FicheroEjecutar:" FicheroEjecutar "." conf.extension "}"
	}
	else
	{
		Activacion := "Activar" BotonVisual
		GuiControl, Show, %Activacion%
		try
		{
			if(FileExist(A_ScriptDir "\" RutaScript))
			{
				if(conf.builtin_ahk)
				{
					
					Run, % A_ScriptDir "\lib\autohotkey.exe """ A_ScriptDir "\" RutaScript """", % A_ScriptDir
				}
				else
				{
					Run, % """" A_ScriptDir "\" RutaScript """", % A_ScriptDir
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
	feedbackControl := feedbackEjecucion[1]
	feedbackEjecucion.remove(1)
	if(!LD_IsSelectedActivationControl(feedbackControl))
		GuiControl, Hide, %feedbackControl%
return

LD_IsSelectedActivationControl(activationControl)
{
	global EnCarpeta, CarpetaBoton, PaginaCarpeta, NumeroPagina

	RegExMatch(activationControl, "\d+$", visualIndex)
	if(visualIndex = "")
		return 0
	if(EnCarpeta)
		buttonId := CarpetaBoton 15*PaginaCarpeta+visualIndex
	else
		buttonId := 15*NumeroPagina+visualIndex
	return LD_IsButtonSelected(buttonId)
}

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
	folderNameToDelete := conf.folderButtons[BotonActivo]
	OnMessage(0x44, "OnMsgBox")
	MsgBoxBtn1 = Delete
	MsgBoxBtn2 = Cancel
	MsgBox 0x34, Delete Folder?, This folder may contain other buttons or folders, delete it anyway?
	OnMessage(0x44, "")
	IfMsgBox Yes, {
		if(LD_ConfirmPhysicalFolderDelete(folderNameToDelete))
		{
			if(folderNameToDelete != "")
			{
				FileRemoveDir, % A_ScriptDir "\buttons\" folderNameToDelete, 1
				FileRemoveDir, % A_ScriptDir "\resources\img\" folderNameToDelete, 1
				/*
				Loop, Files, % A_ScriptDir "\buttons\" folderNameToDelete "\*.ahk"
				{
					FileDelete, % A_LoopFileFullPath
				}
				Loop, Files, % A_ScriptDir "\resources\img\" folderNameToDelete "*.png"
				{
					FileDelete, % A_LoopFileFullPath
				}
				*/
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
			DllCall("DeleteObject", "ptr", btnPics[BotonActivo ".png"]) ; Dispose image from memory
			btnPics[BotonActivo ".png"] := ""
			FileDelete,./resources/img/%BotonActivo%.png
		}
		LD_ButtonChanged(BotonActivo)
	}else{
		return
	}	
return

LD_ConfirmPhysicalFolderDelete(folderName)
{
	if(folderName = "")
		return 0
	title := LD_T("button_menu.delete_physical_folder_title", "Delete Physical Folder")
	prompt := LD_T("button_menu.delete_physical_folder_prompt", "To delete the physical scripts folder from disk, type the folder name exactly:`n`n{folder}", {folder: folderName})
	InputBox, typedFolderName, %title%, %prompt%, , 500, 180
	if(ErrorLevel)
		return 0
	if(typedFolderName = folderName)
		return 1
	MsgBox,, %title%, % LD_T("button_menu.delete_physical_folder_mismatch", "Folder name did not match. The button folder link will be removed, but physical scripts will stay on disk.")
	return 0
}

DeleteButtonFunction:
	if(LD_SelectedButtonCount() > 0)
	{
		LD_DeleteSelectedButtons()
		return
	}
	buttonPath := GetButtonScriptRelativePath(BotonActivo, "ahk")
	if(FileExist(buttonPath))
	{
		OnMessage(0x44, "OnMsgBox")
		MsgBoxBtn1 = Delete
		MsgBoxBtn2 = Cancel
		MsgBox 0x34, Delete Function?, This button has a function it will be deleted!
		OnMessage(0x44, "")

		IfMsgBox Yes, {
			FileDelete, %buttonPath%
			OnMessage(0x44, "OnMsgBox")
			MsgBoxBtn1 = Delete
			MsgBoxBtn2 = Cancel
			MsgBox 0x34, Delete Icon?, Do you want to also remove this button icon?
			OnMessage(0x44, "")
			IfMsgBox Yes, {
				DllCall("DeleteObject", "ptr", btnPics[BotonActivo ".png"]) ; Dispose image from memory
				btnPics[BotonActivo ".png"] := ""
				FileDelete,./resources/img/%BotonActivo%.png
				LD_ButtonChanged(BotonActivo)
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
		Gui startPos:Add, Text, x8 y8 w61 h23 +0x200, % LD_T("start_pos.initial_x", "Initial X Pos:")
		Gui startPos:Add, Text, x8 y40 w60 h23 +0x200, % LD_T("start_pos.initial_y", "Initial Y Pos:")
		Gui startPos:Add, Edit, x72 y8 w120 h21 vx_Inicial +Center +Number, % conf.x_Inicial
		Gui startPos:Add, Edit, x72 y40 w120 h21 vy_Inicial +Center +Number, % conf.y_Inicial
		Gui startPos:Add, Button, x102 y72 w90 h23 gsaveStartPossition, % LD_T("start_pos.set_and_save", "Set and Save")
		Gui startPos:Add, Button, x8 y72 w86 h23 ggetCurrentPos, % LD_T("start_pos.get_current", "Get current")
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
		FileAppend, % JSON.Dump(conf, 1), ./conf/config.json
	}
return

guardarConfigCambioOnline:
	FileDelete, ./conf/config.json
	FileAppend, % JSON.Dump(conf, 1), ./conf/config.json
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
	LibreDeckDiscoveryShutdown()
	LD_ButtonImage_Shutdown()
    ExitApp


; NETWORKING MODULE
EnviarTCP(txtSnd)
{
	global conf, tcpCon
	txtSnd := conf.isGolangServer ? txtSnd "`n" : txtSnd
    tcpCon.sendText(txtSnd)
}

OnTcpRecv(this)
{
	global conf, feedbackEjecucion
	if (conf.isGolangServer)
		StringReplace, txtBtnRecv, % this.recvText(), `n,,All
	else
		txtBtnRecv := this.recvText()
	Activacion := "Activar" txtBtnRecv
	GuiControl, Show, %Activacion%
	feedbackEjecucion.push(Activacion)
	SetTimer, OcultarFeedbackEjecucion, 150
}

OnTcpDisconnect(this)
{
	global serverFound, LD_ReconnectAttemptCount

	serverFound := 0
	LD_ReconnectAttemptCount := 0
	RefreshWifiIcon()
	if(WinExist("LibreDeck Network Settings"))
	{
		GuiControl, networkSettings:+cRed, NetworkStatusInfo
		GuiControl, networkSettings:Text, NetworkStatusInfo, % LD_T("network.status_connection_lost", "Connection lost. Reconnecting...")
	}
	SetTimer, LibreDeckConnectionWatchdog, 5000
}

LibreDeckConnectionWatchdog:
	if(!conf.online)
	{
		SetTimer, LibreDeckConnectionWatchdog, Off
		return
	}
	if(serverFound)
		return
	if(LD_ReconnectAttemptCount >= 1)
	{
		LibreDeckSwitchToOfflineMode(LD_T("network.status_offline_after_failed_reconnect", "Connection failed twice. Offline mode enabled."))
		return
	}
	LD_ReconnectAttemptCount++
	if(LibreDeckReconnectConfiguredServer())
	{
		LD_ReconnectAttemptCount := 0
		gosub, downloadServerProfile
	}
	else
	{
		LibreDeckSwitchToOfflineMode(LD_T("network.status_offline_after_failed_reconnect", "Connection failed twice. Offline mode enabled."))
		return
	}
	gosub, setWifiIcon
return

LibreDeckReconnectConfiguredServer()
{
	global conf, tcpCon, serverFound

	if(!LibreDeckAttemptServerConnection(conf.ip, conf.port))
	{
		serverFound := 0
		if(WinExist("LibreDeck Network Settings"))
		{
			GuiControl, networkSettings:+cRed, NetworkStatusInfo
			GuiControl, networkSettings:Text, NetworkStatusInfo, % LD_T("network.status_reconnect_failed", "Reconnect failed: {error}", {error: tcpCon.errorNM})
		}
		return false
	}
	serverFound := 1
	if(WinExist("LibreDeck Network Settings"))
	{
		GuiControl, networkSettings:+cGreen, NetworkStatusInfo
		GuiControl, networkSettings:Text, NetworkStatusInfo, % LD_T("network.status_reconnected", "Reconnected to the server!")
	}
	return true
}

LibreDeckAttemptServerConnection(ip, port)
{
	global tcpCon, LD_TCP_CONNECT_TIMEOUT_MS

	if(IsObject(tcpCon))
		tcpCon.disconnect()
	tcpCon := new SocketTCP()
	connected := tcpCon.connect(ip, port, LD_TCP_CONNECT_TIMEOUT_MS)
	tcpCon.onRecv := Func("OnTcpRecv")
	tcpCon.onDisconnect := Func("OnTcpDisconnect")
	return connected
}

LibreDeckConnectWithRetry(ip, port, attempts := 2)
{
	Loop, %attempts%
	{
		if(LibreDeckAttemptServerConnection(ip, port))
			return true
		if(A_Index < attempts)
			Sleep, 150
	}
	return false
}

LibreDeckSwitchToOfflineMode(statusText := "", updateGui := true)
{
	global conf, tcpCon, serverFound, LD_ReconnectAttemptCount

	if(IsObject(tcpCon))
		tcpCon.disconnect()
	FileRead, localConfigJson, ./conf/config.json
	localConf := JSON.Load(localConfigJson)
	if(IsObject(localConf))
		conf := localConf
	conf.online := 0
	serverFound := 0
	LD_ReconnectAttemptCount := 0
	SetTimer, LibreDeckConnectionWatchdog, Off
	LibreDeckSaveConfig()
	if(!updateGui)
		return
	RefreshWifiIcon()
	if(WinExist("LibreDeck Network Settings"))
	{
		GuiControl, networkSettings:, OnlineChk, 0
		GuiControl, networkSettings:+cRed, NetworkStatusInfo
		if(statusText = "")
			statusText := LD_T("network.status_offline_after_failed_reconnect", "Connection failed twice. Offline mode enabled.")
		GuiControl, networkSettings:Text, NetworkStatusInfo, %statusText%
	}
}

crearGuiNetworkSettings:
	if(WinExist("LibreDeck Network Settings"))
	{
		WinActivate, LibreDeck Network Settings
	}
	else
	{
		interfaceList := LibreDeckDiscoveryBuildInterfaceList()
		if(conf.online)
			Gui networkSettings:Add, CheckBox, x16 y8 w120 h23 vOnlineChk checked, % LD_T("network.online_mode", "Online Mode")
		else
			Gui networkSettings:Add, CheckBox, x16 y8 w120 h23 vOnlineChk, % LD_T("network.online_mode", "Online Mode")
		Gui networkSettings:Add, Text, x16 y40 w43 h23 +0x200, % LD_T("network.ip", "IP:")
		Gui networkSettings:Add, Text, x16 y72 w43 h23 +0x200, % LD_T("network.port", "Port:")
		Gui networkSettings:Add, Text, x16 y104 w43 h23 +0x200, % LD_T("network.resource_port", "Res Port:")
		Gui networkSettings:Add, Text, x200 y40 w65 h23 +0x200, % LD_T("network.nickname", "Nickname:")
		Gui networkSettings:Add, Edit, +Center x64 y40 w120 h21 vIpTxt, % conf.ip
		Gui networkSettings:Add, Edit, +Center x64 y72 w120 h21 vPortTxt, % conf.port
		Gui networkSettings:Add, Edit, +Center x64 y104 w120 h21 vResourcesPortTxt, % conf.resourcesPort
		Gui networkSettings:Add, Edit, +Center x270 y40 w263 h21 vNicknameTxt, % LibreDeckProfileGetNickname(conf.ip, conf.port, conf.resourcesPort)
		Gui networkSettings:Add, Button, x16 y136 w80 h23 gSaveNetworkConfig, % LD_T("network.save_config", "SAVE CONFIG")
		Gui networkSettings:Add, Button, x104 y136 w80 h23 gConnectToServer, % LD_T("network.connect", "CONNECT")
		Gui networkSettings:Add, Text, x0 y168 w548 h2 +0x10 ; Separator
		Gui networkSettings:Add, Text, x16 y180 w95 h23 +0x200, % LD_T("network.interface", "Interface:")
		Gui networkSettings:Add, DropDownList, x88 y180 w445 vDiscoveryInterfaceChoice gNetworkDiscoveryInterfaceChanged, %interfaceList%
		Gui networkSettings:Add, Text, x16 y212 w95 h23 +0x200, % LD_T("network.broadcast", "Broadcast:")
		Gui networkSettings:Add, Edit, +Center x88 y212 w145 h21 vDiscoveryBroadcastTxt ReadOnly
		Gui networkSettings:Add, Text, x248 y212 w80 h23 +0x200, % LD_T("network.udp", "UDP:")
		Gui networkSettings:Add, Edit, +Center x285 y212 w70 h21 vDiscoveryPortTxt Number, % LD_DiscoveryPort
		Gui networkSettings:Add, Text, x368 y212 w72 h23 +0x200, % LD_T("network.local_udp", "Local UDP:")
		Gui networkSettings:Add, Edit, +Center x436 y212 w55 h21 vDiscoveryLocalUdpPortTxt Number, % LD_DiscoveryLocalUdpPort
		Gui networkSettings:Add, Button, x16 y244 w110 h23 gNetworkDiscoveryRefresh, % LD_T("network.discover", "DISCOVER")
		Gui networkSettings:Add, Text, x136 y244 w397 h23 +0x200 vNetworkDiscoveryStatus, % LD_T("network.discovery_ready", "Discovery ready")
		discoveryColumns := LD_T("network.servers_name", "Name") "|" LD_T("network.servers_ip", "IP") "|" LD_T("network.servers_port", "Port") "|" LD_T("network.servers_resource", "Res") "|" LD_T("network.servers_version", "Ver") "|" LD_T("network.servers_last_seen", "Last Seen")
		Gui networkSettings:Add, ListView, x16 y276 w517 h150 vNetworkDiscoveryServerList gNetworkDiscoveryServerSelected, %discoveryColumns%
		Gui networkSettings:Add, Text, x0 y438 w548 h2 +0x10 ; Separator
		Gui networkSettings:Add, Text, x16 y448 w150 h23 +0x200, % LD_T("network.saved_profiles", "Saved profiles:")
		Gui networkSettings:Add, Button, x178 y448 w85 h23 gNetworkProfileRename, % LD_T("network.profile_rename", "RENAME")
		Gui networkSettings:Add, Button, x270 y448 w85 h23 gNetworkProfileFavorite, % LD_T("network.profile_favorite", "FAVORITE")
		Gui networkSettings:Add, Button, x362 y448 w85 h23 gNetworkProfileDelete, % LD_T("network.profile_delete", "DELETE")
		Gui networkSettings:Add, Button, x454 y448 w79 h23 gNetworkProfileConnect, % LD_T("network.connect", "CONNECT")
		profileColumns := LD_T("network.profile_fav", "Fav") "|" LD_T("network.profile_nickname", "Nickname") "|" LD_T("network.servers_ip", "IP") "|" LD_T("network.servers_port", "Port") "|" LD_T("network.servers_resource", "Res") "|" LD_T("network.profile_last_connected", "Last Connected")
		Gui networkSettings:Add, ListView, x16 y474 w517 h120 vNetworkProfileList gNetworkProfileSelected, %profileColumns%
		Gui networkSettings:Add, Text, x0 y606 w548 h2 +0x10 ; Separator
		Gui networkSettings:Add, Text, x8 y607 w525 h23 +Center +0x200 vNetworkStatusInfo, % LD_T("network.status_default", "LibreDeck - Network Config")
		Gui networkSettings:Default
		Gui, ListView, NetworkDiscoveryServerList
		LV_ModifyCol(1, 145)
		LV_ModifyCol(2, 115)
		LV_ModifyCol(3, 55)
		LV_ModifyCol(4, 55)
		LV_ModifyCol(5, 45)
		LV_ModifyCol(6, 85)
		Gui, ListView, NetworkProfileList
		LV_ModifyCol(1, 35)
		LV_ModifyCol(2, 145)
		LV_ModifyCol(3, 105)
		LV_ModifyCol(4, 50)
		LV_ModifyCol(5, 45)
		LV_ModifyCol(6, 95)
		Gui networkSettings:Show, w548 h634, LibreDeck Network Settings
		LibreDeckProfilesRefreshList()
		gosub, NetworkDiscoveryInterfaceChanged
		gosub, NetworkDiscoveryRefresh
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
	if(LD_NetworkConfigSkipReload)
		mustReload := 0
	gosub, loadConfig ; This is needed because when we are online, folder config is the remote server's config, and we don't want to keep it when we switch back to local mode
	conf.online := OnlineChk
	conf.ip := IpTxt
	conf.port := PortTxt
	conf.resourcesPort := ResourcesPortTxt
	gosub, guardarConfigCambioOnline
	GuiControl, networkSettings:+cBlue, NetworkStatusInfo
	GuiControl, networkSettings:Text, NetworkStatusInfo, % LD_T("network.status_config_saved", "Config Saved!")
	if(mustReload)
	{
		reload
	}
return

ConnectToServer:
	GuiControlGet, OnlineChk, networkSettings:, OnlineChk
	if(!OnlineChk)
	{
		MsgBox, % LD_T("network.enable_online_first", "Enable online mode first!")
		return
	}
	GuiControlGet, IpTxt, networkSettings:, IpTxt
	GuiControlGet, PortTxt, networkSettings:, PortTxt
	GuiControlGet, ResourcesPortTxt, networkSettings:, ResourcesPortTxt
	GuiControlGet, NicknameTxt, networkSettings:, NicknameTxt
	GuiControl, networkSettings:+cBlack, NetworkStatusInfo
	GuiControl, networkSettings:Text, NetworkStatusInfo, % LD_T("network.status_connecting", "Connecting...")
	conf.ip := IpTxt
	conf.port := PortTxt
	conf.resourcesPort := ResourcesPortTxt
	if(!LibreDeckConnectWithRetry(IpTxt, PortTxt, LD_TCP_CONNECT_ATTEMPTS))
	{
		LibreDeckSwitchToOfflineMode(LD_T("network.status_offline_after_failed_reconnect", "Connection failed twice. Offline mode enabled."))
		GuiControl, networkSettings:+cRed, NetworkStatusInfo
		GuiControl, networkSettings:Text, NetworkStatusInfo, % LD_T("network.status_connect_failed_offline", "Could not connect. Offline mode enabled.")
	}
	else
	{
		serverFound := 1
		LD_ReconnectAttemptCount := 0
		SetTimer, LibreDeckConnectionWatchdog, 5000
		LD_NetworkConfigSkipReload := true
		gosub, SaveNetworkConfig
		LD_NetworkConfigSkipReload := false
		LibreDeckProfileSaveSuccessfulConnection(IpTxt, PortTxt, ResourcesPortTxt, NicknameTxt, LD_CurrentDiscoveredServerName)
		LibreDeckProfilesRefreshList()
		GuiControl, networkSettings:+cGreen, NetworkStatusInfo
		GuiControl, networkSettings:Text, NetworkStatusInfo, % LD_T("network.status_connected", "Connected to the server!")
		gosub, downloadServerProfile
	}
	gosub, setWifiIcon
return

networkSettingsguiClose:
networkSettingsguiEscape:
	StopLibreDeckDiscoveryClient()
	Gui, networkSettings:Destroy
return

NetworkDiscoveryInterfaceChanged:
	Gui, networkSettings:Submit, NoHide
	if(DiscoveryInterfaceChoice = "All interfaces")
	{
		LD_DiscoveryBroadcastIP := "All interfaces"
		GuiControl, networkSettings:, DiscoveryBroadcastTxt, All interfaces
		return
	}
	if(!LD_DiscoveryInterfaces.HasKey(DiscoveryInterfaceChoice))
		return
	selected := LD_DiscoveryInterfaces[DiscoveryInterfaceChoice]
	LD_DiscoveryBroadcastIP := LibreDeckDiscoveryCalculateBroadcast(selected.ip, selected.mask)
	GuiControl, networkSettings:, DiscoveryBroadcastTxt, %LD_DiscoveryBroadcastIP%
return

NetworkDiscoveryRefresh:
	Gui, networkSettings:Submit, NoHide
	if(LD_DiscoveryDiscovering)
		return
	if(!LibreDeckDiscoveryApplyClientSettings())
		return

	LD_DiscoveryDiscovering := true
	LD_DiscoveryServers := {}
	Gui, networkSettings:Default
	Gui, ListView, NetworkDiscoveryServerList
	LV_Delete()
	GuiControl, networkSettings:, NetworkDiscoveryStatus, % LD_T("network.discovery_discovering", "Discovering {target}...", {target: LD_DiscoveryBroadcastIP})

	message := "LIBREDECK_DISCOVER|name=" A_ComputerName
	sentCount := LibreDeckDiscoverySendDiscover(message)
	if(sentCount < 1)
	{
		err := LD_GetLastError()
		GuiControl, networkSettings:, NetworkDiscoveryStatus, % LD_T("network.discovery_send_error", "sendto error {error}", {error: err})
		LD_DiscoveryDiscovering := false
		return
	}
	SetTimer, NetworkDiscoveryFinish, % -LD_DISCOVERY_TIMEOUT_MS
return

NetworkDiscoveryFinish:
	LD_DiscoveryDiscovering := false
	Gui, networkSettings:Default
	Gui, ListView, NetworkDiscoveryServerList
	count := LV_GetCount()
	GuiControl, networkSettings:, NetworkDiscoveryStatus, % LD_T("network.discovery_found", "Found {count} server(s)", {count: count})
return

NetworkDiscoveryServerSelected:
	if(A_GuiEvent != "Normal" && A_GuiEvent != "DoubleClick")
		return
	row := A_EventInfo
	if(!row)
		return
	NetworkDiscoveryFillConnectionForm(row)
	if(A_GuiEvent = "DoubleClick")
	{
		gosub, ConnectToServer
	}
return

NetworkProfileSelected:
	if(A_GuiEvent != "Normal" && A_GuiEvent != "DoubleClick")
		return
	row := A_EventInfo
	if(!row)
		return
	NetworkProfileFillConnectionForm(row)
	if(A_GuiEvent = "DoubleClick")
		gosub, ConnectToServer
return

NetworkProfileConnect:
	row := NetworkProfileGetSelectedRow()
	if(!row)
		return
	NetworkProfileFillConnectionForm(row)
	gosub, ConnectToServer
return

NetworkProfileRename:
	row := NetworkProfileGetSelectedRow()
	if(!row)
		return
	NetworkProfileRenameSelected(row)
return

NetworkProfileFavorite:
	row := NetworkProfileGetSelectedRow()
	if(!row)
		return
	NetworkProfileSetFavorite(row)
return

NetworkProfileDelete:
	row := NetworkProfileGetSelectedRow()
	if(!row)
		return
	NetworkProfileDeleteSelected(row)
return

LibreDeckDiscoveryApplyClientSettings()
{
	global LD_DiscoveryInterfaces, LD_DiscoveryPort, LD_DiscoveryLocalUdpPort, LD_DiscoveryLocalIP, LD_DiscoveryBroadcastIP
	global DiscoveryInterfaceChoice, DiscoveryPortTxt, DiscoveryLocalUdpPortTxt

	Gui, networkSettings:Submit, NoHide

	if(DiscoveryInterfaceChoice != "All interfaces" && !LD_DiscoveryInterfaces.HasKey(DiscoveryInterfaceChoice))
	{
		GuiControl, networkSettings:+cRed, NetworkDiscoveryStatus
		GuiControl, networkSettings:, NetworkDiscoveryStatus, % LD_T("network.discovery_select_interface", "Select a network interface")
		return false
	}
	if(DiscoveryPortTxt < 1 || DiscoveryPortTxt > 65535)
	{
		GuiControl, networkSettings:+cRed, NetworkDiscoveryStatus
		GuiControl, networkSettings:, NetworkDiscoveryStatus, % LD_T("network.discovery_invalid_port", "Discovery UDP port must be 1-65535")
		return false
	}
	if(DiscoveryLocalUdpPortTxt < 0 || DiscoveryLocalUdpPortTxt > 65535)
	{
		GuiControl, networkSettings:+cRed, NetworkDiscoveryStatus
		GuiControl, networkSettings:, NetworkDiscoveryStatus, % LD_T("network.discovery_invalid_local_udp", "Local UDP must be 0-65535")
		return false
	}

	LD_DiscoveryPort := DiscoveryPortTxt
	LD_DiscoveryLocalUdpPort := DiscoveryLocalUdpPortTxt
	if(DiscoveryInterfaceChoice = "All interfaces")
	{
		LD_DiscoveryLocalIP := ""
		LD_DiscoveryBroadcastIP := "All interfaces"
	}
	else
	{
		selected := LD_DiscoveryInterfaces[DiscoveryInterfaceChoice]
		LD_DiscoveryLocalIP := selected.ip
		LD_DiscoveryBroadcastIP := LibreDeckDiscoveryCalculateBroadcast(selected.ip, selected.mask)
	}
	GuiControl, networkSettings:, DiscoveryBroadcastTxt, %LD_DiscoveryBroadcastIP%

	StopLibreDeckDiscoveryClient()
	if(!StartLibreDeckDiscoveryClient())
	{
		GuiControl, networkSettings:+cRed, NetworkDiscoveryStatus
		GuiControl, networkSettings:, NetworkDiscoveryStatus, % LD_T("network.discovery_socket_error", "Could not start discovery socket")
		return false
	}

	GuiControl, networkSettings:+cBlack, NetworkDiscoveryStatus
	return true
}

StartLibreDeckDiscoveryClient()
{
	global LD_DiscoverySocks, LD_DiscoverySock, LD_DiscoverySocketCallback, LD_DiscoveryWinsockStarted
	global LD_DiscoveryLocalUdpPort, LD_DiscoveryLocalIP, LD_DISCOVERY_SOCKET_MSG, LD_DISCOVERY_FD_READ
	global DiscoveryInterfaceChoice, LD_DiscoveryInterfaces

	if(!LD_DiscoveryWinsockStarted)
	{
		if(!LD_StartWinsock())
			return false
		LD_DiscoveryWinsockStarted := true
	}

	LD_DiscoverySocks := []
	if(DiscoveryInterfaceChoice = "All interfaces")
	{
		for label, selected in LD_DiscoveryInterfaces
			LibreDeckDiscoveryCreateClientSocket(selected.ip)
	}
	else
	{
		LibreDeckDiscoveryCreateClientSocket(LD_DiscoveryLocalIP)
	}

	if(LD_DiscoverySocks.MaxIndex() = "")
		return false

	LD_DiscoverySock := LD_DiscoverySocks[1].sock
	return true
}

LibreDeckDiscoveryCreateClientSocket(localIP)
{
	global LD_DiscoverySocks, LD_DiscoverySocketCallback, LD_DiscoveryLocalUdpPort, LD_DISCOVERY_SOCKET_MSG, LD_DISCOVERY_FD_READ

	sock := LD_CreateUdpSocket()
	if(sock = -1)
		return false
	if(!LD_Bind(sock, LD_DiscoveryLocalUdpPort, localIP))
	{
		LD_CloseSocket(sock)
		return false
	}
	if(!LD_SetBroadcast(sock, true))
	{
		LD_CloseSocket(sock)
		return false
	}
	if(LD_DiscoverySocketCallback = "")
		LD_DiscoverySocketCallback := Func("LibreDeckDiscoverySocketMessage")
	OnMessage(LD_DISCOVERY_SOCKET_MSG, LD_DiscoverySocketCallback)

	if(!LD_RegisterAsync(sock, LD_DISCOVERY_SOCKET_MSG, LD_DISCOVERY_FD_READ))
	{
		LD_CloseSocket(sock)
		return false
	}

	entry := {}
	entry.sock := sock
	entry.localIP := localIP
	LD_DiscoverySocks.Push(entry)
	return true
}

StopLibreDeckDiscoveryClient()
{
	global LD_DiscoverySocks, LD_DiscoverySock, LD_DiscoverySocketCallback, LD_DiscoveryDiscovering, LD_DISCOVERY_SOCKET_MSG

	SetTimer, NetworkDiscoveryFinish, Off
	LD_DiscoveryDiscovering := false
	if(LD_DiscoverySocks.MaxIndex() = "" && LD_DiscoverySock = -1)
		return

	if(LD_DiscoverySocketCallback != "")
		OnMessage(LD_DISCOVERY_SOCKET_MSG, LD_DiscoverySocketCallback, 0)
	for index, entry in LD_DiscoverySocks
	{
		LD_UnregisterAsync(entry.sock, LD_DISCOVERY_SOCKET_MSG)
		LD_CloseSocket(entry.sock)
	}
	LD_DiscoverySocks := []
	LD_DiscoverySock := -1
}

LibreDeckDiscoveryShutdown()
{
	global LD_DiscoveryWinsockStarted

	StopLibreDeckDiscoveryClient()
	if(LD_DiscoveryWinsockStarted)
	{
		DllCall("Ws2_32\WSACleanup")
		LD_DiscoveryWinsockStarted := false
	}
}

LibreDeckDiscoverySocketMessage(wParam, lParam, msg, hwnd)
{
	global LD_DiscoverySocks, LD_DiscoveryDiscovering, LD_DISCOVERY_FD_READ

	if(!LibreDeckDiscoveryIsKnownSocket(wParam))
		return
	if(LD_AsyncError(lParam))
		return
	if(LD_AsyncEvent(lParam) != LD_DISCOVERY_FD_READ)
		return

	received := LD_RecvOne(wParam, message, ip, port, fromAddr)
	if(received = -1)
		return

	if(InStr(message, "LIBREDECK_SERVER|") = 1)
		LibreDeckDiscoveryAddOrUpdateServer(ip, message)
}

LibreDeckDiscoveryIsKnownSocket(sock)
{
	global LD_DiscoverySocks
	for index, entry in LD_DiscoverySocks
		if(entry.sock = sock)
			return true
	return false
}

LibreDeckDiscoverySendDiscover(message)
{
	global LD_DiscoverySocks, LD_DiscoveryInterfaces, DiscoveryInterfaceChoice, LD_DiscoveryPort, LD_DiscoveryBroadcastIP

	sentCount := 0
	if(DiscoveryInterfaceChoice = "All interfaces")
	{
		for index, entry in LD_DiscoverySocks
		{
			for label, selected in LD_DiscoveryInterfaces
			{
				if(selected.ip != entry.localIP)
					continue
				broadcast := LibreDeckDiscoveryCalculateBroadcast(selected.ip, selected.mask)
				sent := LD_SendToIP(entry.sock, message, broadcast, LD_DiscoveryPort)
				if(sent != -1)
					sentCount++
			}
		}
	}
	else
	{
		sent := LD_SendToIP(LD_DiscoverySocks[1].sock, message, LD_DiscoveryBroadcastIP, LD_DiscoveryPort)
		if(sent != -1)
			sentCount := 1
	}
	return sentCount
}

LibreDeckDiscoveryAddOrUpdateServer(ip, message)
{
	global LD_DiscoveryServers

	if(!WinExist("LibreDeck Network Settings"))
		return

	name := LD_GetField(message, "name")
	tcpPort := LD_GetField(message, "tcp_port")
	resourcePort := LD_GetField(message, "resource_port")
	version := LD_GetField(message, "version")

	if(name = "")
		name := "(unnamed)"
	if(tcpPort = "")
		tcpPort := "?"
	if(resourcePort = "")
		resourcePort := "?"
	if(version = "")
		version := "?"

	FormatTime, now,, HH:mm:ss
	key := ip ":" tcpPort ":" resourcePort
	Gui, networkSettings:Default
	Gui, ListView, NetworkDiscoveryServerList
	if(LD_DiscoveryServers.HasKey(key))
	{
		row := LD_DiscoveryServers[key]
		LV_Modify(row, "", name, ip, tcpPort, resourcePort, version, now)
	}
	else
	{
		row := LV_Add("", name, ip, tcpPort, resourcePort, version, now)
		LD_DiscoveryServers[key] := row
	}

	count := LV_GetCount()
	GuiControl, networkSettings:+cBlack, NetworkDiscoveryStatus
	GuiControl, networkSettings:, NetworkDiscoveryStatus, % LD_T("network.discovery_receiving", "Receiving... {count} server(s)", {count: count})
}

NetworkDiscoveryFillConnectionForm(row)
{
	global

	Gui, networkSettings:Default
	Gui, ListView, NetworkDiscoveryServerList
	LV_GetText(selectedName, row, 1)
	LV_GetText(selectedIP, row, 2)
	LV_GetText(selectedPort, row, 3)
	LV_GetText(selectedResourcePort, row, 4)

	if(selectedIP = "" || selectedPort = "" || selectedPort = "?")
		return false

	GuiControl, networkSettings:, OnlineChk, 1
	GuiControl, networkSettings:, IpTxt, %selectedIP%
	GuiControl, networkSettings:, PortTxt, %selectedPort%
	if(selectedResourcePort != "" && selectedResourcePort != "?")
		GuiControl, networkSettings:, ResourcesPortTxt, %selectedResourcePort%
	LD_CurrentDiscoveredServerName := selectedName
	nickname := LibreDeckProfileGetNickname(selectedIP, selectedPort, selectedResourcePort)
	if(nickname = "")
		nickname := selectedName
	GuiControl, networkSettings:, NicknameTxt, %nickname%
	return true
}

LibreDeckDiscoveryBuildInterfaceList()
{
	global LD_DiscoveryInterfaces

	LD_DiscoveryInterfaces := {}
	list := "All interfaces||"

	try wmi := ComObjGet("winmgmts:\\.\root\cimv2")
	catch
		return ""

	query := "SELECT Description, IPAddress, IPSubnet FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled = True"
	for adapter in wmi.ExecQuery(query)
	{
		ips := adapter.IPAddress
		masks := adapter.IPSubnet
		if(!IsObject(ips) || !IsObject(masks))
			continue

		maxIndex := ips.MaxIndex()
		if(maxIndex = "")
			continue

		Loop, % maxIndex + 1
		{
			i := A_Index - 1
			ip := ips[i]
			mask := masks[i]
			if(!LibreDeckDiscoveryIsIPv4(ip) || !LibreDeckDiscoveryIsIPv4(mask))
				continue
			if(SubStr(ip, 1, 4) = "127.")
				continue

			description := adapter.Description
			label := ip " / " mask " - " description
			entry := {}
			entry.ip := ip
			entry.mask := mask
			entry.description := description
			LD_DiscoveryInterfaces[label] := entry

			list .= label "|"
		}
	}

	if(list = "All interfaces||")
		return "|"
	return RTrim(list, "|")
}

LibreDeckDiscoveryIsIPv4(ip)
{
	parts := StrSplit(ip, ".")
	if(parts.MaxIndex() != 4)
		return false

	for index, part in parts
	{
		if part is not integer
			return false
		if(part < 0 || part > 255)
			return false
	}
	return true
}

LibreDeckDiscoveryCalculateBroadcast(ip, mask)
{
	ipParts := StrSplit(ip, ".")
	maskParts := StrSplit(mask, ".")

	b1 := (ipParts[1] | (255 ^ maskParts[1])) & 255
	b2 := (ipParts[2] | (255 ^ maskParts[2])) & 255
	b3 := (ipParts[3] | (255 ^ maskParts[3])) & 255
	b4 := (ipParts[4] | (255 ^ maskParts[4])) & 255

	return b1 "." b2 "." b3 "." b4
}

LibreDeckProfileKey(ip, port, resourcePort)
{
	return ip ":" port ":" resourcePort
}

LibreDeckProfileGetNickname(ip, port, resourcePort)
{
	global conf

	if(!IsObject(conf) || !IsObject(conf.serverProfiles))
		return ""
	key := LibreDeckProfileKey(ip, port, resourcePort)
	if(conf.serverProfiles.HasKey(key))
		return conf.serverProfiles[key].nickname
	return ""
}

LibreDeckProfileSaveSuccessfulConnection(ip, port, resourcePort, nickname := "", discoveredName := "")
{
	global conf

	if(!IsObject(conf.serverProfiles))
		conf.serverProfiles := {}
	if(nickname = "")
		nickname := discoveredName
	if(nickname = "")
		nickname := ip ":" port

	FormatTime, now,, yyyy-MM-dd HH:mm:ss
	key := LibreDeckProfileKey(ip, port, resourcePort)
	profile := {}
	profile.nickname := nickname
	profile.name := discoveredName
	profile.ip := ip
	profile.port := port
	profile.resourcesPort := resourcePort
	profile.lastConnected := now
	conf.serverProfiles[key] := profile
	conf.lastServerProfile := key
	if(conf.favoriteServerProfile = "")
		conf.favoriteServerProfile := key
	LibreDeckSaveConfig()
}

LibreDeckApplyStartupProfile()
{
	global conf

	if(!IsObject(conf) || !IsObject(conf.serverProfiles) || !conf.online)
		return false

	key := ""
	if(conf.favoriteServerProfile != "" && conf.serverProfiles.HasKey(conf.favoriteServerProfile))
		key := conf.favoriteServerProfile
	if(conf.lastServerProfile != "" && conf.serverProfiles.HasKey(conf.lastServerProfile)) ; Last profile has priority over favorite server
		key := conf.lastServerProfile

	if(key = "")
		return false

	profile := conf.serverProfiles[key]
	conf.ip := profile.ip
	conf.port := profile.port
	conf.resourcesPort := profile.resourcesPort
	return true
}

LibreDeckProfileLabel(key)
{
	global conf
	label := ""
	if(conf.favoriteServerProfile = key)
		label := "*"
	if(conf.lastServerProfile = key)
		label .= "L"
	return label
}

NetworkProfileGetSelectedRow()
{
	Gui, networkSettings:Default
	Gui, ListView, NetworkProfileList
	row := LV_GetNext()
	if(!row)
		MsgBox,,% LD_T("network.select_profile_first_title", "LibreDeck Profiles"), % LD_T("network.select_profile_first", "Select a saved profile first.")
	return row
}

NetworkProfileGetKeyFromRow(row)
{
	Gui, networkSettings:Default
	Gui, ListView, NetworkProfileList
	LV_GetText(selectedIP, row, 3)
	LV_GetText(selectedPort, row, 4)
	LV_GetText(selectedResourcePort, row, 5)
	if(selectedIP = "" || selectedPort = "")
		return ""
	return LibreDeckProfileKey(selectedIP, selectedPort, selectedResourcePort)
}

NetworkProfileRenameSelected(row)
{
	global conf
	key := NetworkProfileGetKeyFromRow(row)
	if(key = "" || !conf.serverProfiles.HasKey(key))
		return
	currentNickname := conf.serverProfiles[key].nickname
	InputBox, newNickname, % LD_T("network.profile_nickname_title", "Profile Nickname"), % LD_T("network.profile_nickname_prompt", "Insert nickname for this LibreDeck server profile:"), , 420, 145,,,,,%currentNickname%
	if(ErrorLevel)
		return
	newNickname := Trim(newNickname)
	if(newNickname = "")
		return
	conf.serverProfiles[key].nickname := newNickname
	LibreDeckSaveConfig()
	LibreDeckProfilesRefreshList()
	GuiControl, networkSettings:+cBlue, NetworkStatusInfo
	GuiControl, networkSettings:Text, NetworkStatusInfo, % LD_T("network.status_profile_renamed", "Profile renamed")
}

NetworkProfileSetFavorite(row)
{
	global conf
	key := NetworkProfileGetKeyFromRow(row)
	if(key = "" || !conf.serverProfiles.HasKey(key))
		return
	conf.favoriteServerProfile := key
	LibreDeckSaveConfig()
	NetworkProfileFillConnectionForm(row)
	LibreDeckProfilesRefreshList()
	GuiControl, networkSettings:+cBlue, NetworkStatusInfo
	GuiControl, networkSettings:Text, NetworkStatusInfo, % LD_T("network.status_favorite_selected", "Favorite profile selected")
}

NetworkProfileDeleteSelected(row)
{
	global conf
	key := NetworkProfileGetKeyFromRow(row)
	if(key = "" || !conf.serverProfiles.HasKey(key))
		return
	nickname := conf.serverProfiles[key].nickname
	OnMessage(0x44, "OnMsgBox")
	MsgBoxBtn1 = Delete
	MsgBoxBtn2 = Cancel
	MsgBox 0x34, % LD_T("network.delete_profile_title", "Delete Profile?"), % LD_T("network.delete_profile_prompt", "Delete saved profile ""{nickname}""?", {nickname: nickname})
	OnMessage(0x44, "")
	IfMsgBox No
		return
	conf.serverProfiles.Delete(key)
	if(conf.favoriteServerProfile = key)
		conf.favoriteServerProfile := ""
	if(conf.lastServerProfile = key)
		conf.lastServerProfile := ""
	LibreDeckSaveConfig()
	LibreDeckProfilesRefreshList()
	GuiControl, networkSettings:+cBlue, NetworkStatusInfo
	GuiControl, networkSettings:Text, NetworkStatusInfo, % LD_T("network.status_profile_deleted", "Profile deleted")
}

LibreDeckSaveConfig()
{
	global conf, JSON
	FileDelete, ./conf/config.json
	FileAppend, % JSON.Dump(conf, 1), ./conf/config.json
}

LibreDeckProfilesRefreshList()
{
	global conf

	if(!WinExist("LibreDeck Network Settings"))
		return

	Gui, networkSettings:Default
	Gui, ListView, NetworkProfileList
	LV_Delete()
	if(!IsObject(conf.serverProfiles))
		return

	for key, profile in conf.serverProfiles
		LV_Add("", LibreDeckProfileLabel(key), profile.nickname, profile.ip, profile.port, profile.resourcesPort, profile.lastConnected)
}

NetworkProfileFillConnectionForm(row)
{
	global LD_CurrentDiscoveredServerName

	Gui, networkSettings:Default
	Gui, ListView, NetworkProfileList
	LV_GetText(nickname, row, 2)
	LV_GetText(selectedIP, row, 3)
	LV_GetText(selectedPort, row, 4)
	LV_GetText(selectedResourcePort, row, 5)
	if(selectedIP = "" || selectedPort = "")
		return false

	LD_CurrentDiscoveredServerName := ""
	GuiControl, networkSettings:, OnlineChk, 1
	GuiControl, networkSettings:, IpTxt, %selectedIP%
	GuiControl, networkSettings:, PortTxt, %selectedPort%
	GuiControl, networkSettings:, ResourcesPortTxt, %selectedResourcePort%
	GuiControl, networkSettings:, NicknameTxt, %nickname%
	return true
}

setWifiIcon:
	RefreshWifiIcon()
return

RefreshWifiIcon()
{
	global conf, serverFound, btnPics

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
}

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
		server_config := JSON.Load(URLToVar("http://" conf.ip ":" conf.resourcesPort "/resourcePack_info.txt"))
		serverMD5 := server_config.resourcePackMD5
		FileRead, localMD5, % "./resources/img/" conf.ip "/resourcePack_info.txt"
		localMD5 := JSON.Load(localMD5).resourcePackMD5
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
		incomingBackgroundChange := JSON.Load(incomingBackgroundChange)

		hasFolder := incomingBackgroundChange.HasKey("folderName") && incomingBackgroundChange.folderName != ""

		if (hasFolder && (!EnCarpeta || incomingBackgroundChange.folderName != CarpetaBoton))
			return

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
		incomingButtonChange := JSON.Load(incomingButtonChange)

		hasFolder := incomingButtonChange.HasKey("folderName") && incomingButtonChange.folderName != ""
		hasPage := incomingButtonChange.HasKey("page") && incomingButtonChange.page != ""

		shouldUpdate := false

		if (!hasFolder && !hasPage) {
			shouldUpdate := true
		} else if (hasFolder && hasPage) {
			shouldUpdate := EnCarpeta
				&& incomingButtonChange.folderName == CarpetaBoton
				&& incomingButtonChange.page == PaginaCarpeta
		} else if (hasPage) {
			shouldUpdate := !EnCarpeta
				&& incomingButtonChange.page == NumeroPagina
		} else if (hasFolder) {
			shouldUpdate := EnCarpeta
				&& incomingButtonChange.folderName == CarpetaBoton
		}

		if (shouldUpdate) {
			setButtonIcon(incomingButtonChange.buttonId, incomingButtonChange.imagePathOrName)
		}
	}
return


setButtonIcon(buttonId, imagePathOrName) {
	global
	if(EnCarpeta){
		curBtn := CarpetaBoton 15*PaginaCarpeta+buttonId ".png"
	}
	else
		curBtn := CarpetaBoton 15*NumeroPagina+buttonId ".png"
	
	if (btnPics[curBtn]) 
		DllCall("DeleteObject", "ptr", btnPics[curBtn]) ; Dispose image from memory
	btnPics[curBtn] := LoadPicture(imagePathOrName)
	GuiControl, Text, Boton%buttonId%, % btnPics[curBtn] ? "HBITMAP:*" btnPics[curBtn] : imagePathOrName
	if(conf.miniClient)
		GuiControl, MoveDraw, Boton%buttonId%, w49 h49
	else
		GuiControl, MoveDraw, Boton%buttonId%, w130 h130
}

; Notification examples at: plugins: notification_examples.ahk & backup_libredeck.ahk
showIncomingNotification:
	try {
		incomingNotification := JSON.Load(incomingNotification)
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
		incomingPageChange := JSON.Load(incomingPageChange)
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
		Menu ContextMenuGenerico, Check, % LD_T("app_menu.reactive_pages", "Reactive Pages")
	}
	else
	{
		Menu ContextMenuGenerico, UnCheck, % LD_T("app_menu.reactive_pages", "Reactive Pages")
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
		Menu LookForUpdatesMenu, UnCheck, % LD_T("tray.updates_on_boot", "On Boot")
	}
	else
	{
		conf.lookForUpdates := 1
		Menu LookForUpdatesMenu, Check, % LD_T("tray.updates_on_boot", "On Boot")
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
	showAboutScreen("LibreDeck v" ClientVersionNumber, LD_T("about.description", "A multi-purpose macro pannel tailored to be used both in single screen setups, multi screen, touch support and multi machine setups via sockets."))
return

openLibreDeckFolder:
	Run, % A_ScriptDir
return

loadConfig:
	FileRead, conf, ./conf/config.json
	global conf := JSON.Load(conf)
	if(!IsObject(conf.serverProfiles))
		conf.serverProfiles := {}
	if(conf.favoriteServerProfile = "")
		conf.favoriteServerProfile := ""
	if(conf.lastServerProfile = "")
		conf.lastServerProfile := ""
	if(conf.language = "")
		conf.language := "en_US"
	scriptEditorPath := conf.scriptEditorPath
	StringReplace, scriptEditorPath, scriptEditorPath, \, \\, All
	conf.scriptEditorPath := scriptEditorPath
return

LD_InitI18n()
{
	global conf, LD_i18n

	locale := conf.language
	if(locale = "")
		locale := "en_US"
	LD_i18n := new i18n(A_ScriptDir "\i18n", locale, ["en_US"])
	try LD_i18n.LoadDir(A_ScriptDir "\i18n")
	catch e
		LD_i18n := ""
}

LD_T(key, default := "", params := "")
{
	global LD_i18n

	if(IsObject(LD_i18n))
		return LD_i18n.t(key, params, default)
	if(default != "")
		return default
	return key
}

LD_BuildLanguageMenu()
{
	global LD_i18n, conf

	try Menu, LanguageMenu, DeleteAll
	count := 0
	if(IsObject(LD_i18n))
	{
		for code, _ in LD_i18n.locales
		{
			Menu, LanguageMenu, Add, %code%, ChangeLanguageFromTray
			count++
		}
	}
	if(count = 0)
	{
		Menu, LanguageMenu, Add, en_US, ChangeLanguageFromTray
		Menu, LanguageMenu, Add, es_ES, ChangeLanguageFromTray
	}
	LD_UpdateLanguageMenuChecks()
}

LD_UpdateLanguageMenuChecks()
{
	global LD_i18n, conf

	if(IsObject(LD_i18n))
	{
		for code, _ in LD_i18n.locales
			try Menu, LanguageMenu, UnCheck, %code%
	}
	else
	{
		try Menu, LanguageMenu, UnCheck, en_US
		try Menu, LanguageMenu, UnCheck, es_ES
	}
	try Menu, LanguageMenu, Check, % conf.language
}

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
