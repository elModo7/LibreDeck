; OS Version ...: > Windows 10
; Requires AutoHotkeyU32
;@Ahk2Exe-SetName LibreDeck Server
;@Ahk2Exe-SetDescription Macro Panel Server
;@Ahk2Exe-SetVersion 0.6.0
;@Ahk2Exe-SetCopyright 2026`, elModo7
;@Ahk2Exe-SetOrigFilename LibreDeck Server.exe
; INITIALIZE
; *******************************
#SingleInstance,Force
SetBatchLines, -1
#NoEnv
#Persistent
global versionNumber := "0.6.0"
global clientVersion := versionNumber " - elModo7 / VictorDevLog " A_YYYY
global LD_ServerDiscoverySock := -1
global LD_ServerDiscoverySocketCallback := ""
global LD_ServerDiscoveryWinsockStarted := false
global LD_SERVER_DISCOVERY_SOCKET_MSG := 0x9988
global LD_SERVER_DISCOVERY_FD_READ := 1
#Include <Socket>
#Include <LibreDeckDiscovery>
#Include <JSON>
#Include <MD5>
#Include <SplashScreen>
#Include <aboutScreen>
rutaSplash = ./resources/img/splash.png
SplashScreen(rutaSplash, 3000, 545, 160, 0, 0, true)
GuiControl, splashScreen:, splashTxt, % "Reading config..."

if(!FileExist("./conf/server_config.json"))
{
	conf := {}
	conf.builtin_ahk := 1
	conf.port := 7778
	conf.totalResourceSize := 0
	conf.resourcePackMD5 := "MD5HashGoesHere"
    conf.resourceSharePort := 7779
    conf.startWithWindows := 1
	gosub, guardarConfig
}
FileRead, conf, ./conf/server_config.json
global conf := ParseJson(conf)
gosub, guardarConfigShared
contextcolor() ; Dark Theme

; TRAY MENU
; *******************************
Menu, tray, NoStandard
Menu, tray, tip, % "LibreDeck Server v" versionNumber "`n`nPorts:`nsever: " conf.port "`nresources: " conf.resourceSharePort
Menu, tray, Add, Run LibreDeck client, runClient
Menu tray, Icon, Run LibreDeck client, .\resources\img\ico\libredeck.ico
Menu, tray, Add, Use built-in AHK, toggleBuiltInAhk
Menu, tray, Add, Update Resource Pack Now, 7zImageButtons
Menu tray, Icon, Update Resource Pack Now, .\resources\img\ico\windows\compressed_folder.ico
Menu, tray, Add, Set custom Port, setPort
Menu tray, Icon, Set custom Port, .\resources\img\ico\windows\network2.ico
Menu, tray, add, Open LibreDeck Folder, openLibreDeckFolder
Menu, tray, Icon, Open LibreDeck Folder, .\resources\img\ico\windows\folder.ico
Menu, tray, Add, Run on Startup, startWithWindows
Menu tray, Icon, Run on Startup, .\resources\img\ico\windows\window_possition.ico
Menu, tray, add
Menu, tray, add, % "v" clientVersion, showAboutScreen
Menu, tray, Icon, % "v" clientVersion, .\resources\img\ico\windows\info.ico
Menu, tray, Add, Restart Server, restart
Menu tray, Icon, Restart Server, .\resources\img\ico\windows\refresh.ico
Menu, tray, add, Exit, Exit
Menu tray, Icon, Exit, .\resources\img\ico\windows\close3.ico
if(conf.builtin_ahk)
{
	Menu tray, Check, Use built-in AHK
}
else
{
	Menu tray, UnCheck, Use built-in AHK
}
if(conf.startWithWindows)
{
	Menu, tray, Check, Run on Startup
}
else
{
	Menu, tray, Uncheck, Run on Startup
}

; Create zip for sharing to clients
gosub, 7zImageButtons
gosub, startWebServer

; Start Networking
global myTcp := new SocketTCP()
myTcp.bind("0.0.0.0", conf.port)
myTcp.listen() ; Escucha
myTcp.onAccept := Func("OnTCPAccept")
StartLibreDeckDiscoveryServer()
Gui, SplashScreen:Destroy
Return

toggleBuiltInAhk:
	if(conf.builtin_ahk)
	{
		conf.builtin_ahk := 0
		Menu tray, UnCheck, Use built-in AHK
	}
	else
	{
		conf.builtin_ahk := 1
		Menu tray, Check, Use built-in AHK
	}
	gosub, guardarConfig
return

guardarConfig:
	FileDelete, ./conf/server_config.json
	FileAppend, % JSON_Beautify(BuildJson(conf)), ./conf/server_config.json
return

guardarConfigShared:
	FileRead, shared_conf, ./resources/shared/resourcePack_info.txt
	FileRead, client_conf, ./conf/config.json
	client_conf := ParseJson(client_conf)
	shared_conf := ParseJson(shared_conf)
	shared_conf.folderButtons := client_conf.folderButtons
	FileDelete, ./resources/shared/resourcePack_info.txt
	FileAppend, % JSON_Beautify(BuildJson(shared_conf)), ./resources/shared/resourcePack_info.txt
return

OnExit, Exit
Exit:
	StopLibreDeckDiscoveryServer(true)
	gosub, killPreviousInstance
ExitApp

MoverVentana:
    PostMessage, 0xA1, 2,,, A
Return

OnTCPRecvServer(this)
{
    global Client
    data := ParseJson(this.RecvText())
    try
    {
        Client.sendText(data.BotonVisual)
        scriptPath := ResolveButtonScriptPath(data.FicheroEjecutar)
        if(scriptPath != "" && FileExist(scriptPath))
        {
            if(conf.builtin_ahk)
			{
                Run, % A_ScriptDir "\lib\autohotkey.exe """ scriptPath """", % A_ScriptDir
			}
			else
			{
                Run, % """" scriptPath """", % A_ScriptDir
			}
        }
    }
}

ResolveButtonScriptPath(scriptPath)
{
	StringReplace, scriptPath, scriptPath, /, \, All
	if(scriptPath = "")
		return ""
	if(InStr(scriptPath, "..") || InStr(scriptPath, ":") || SubStr(scriptPath, 1, 8) != "buttons\" || SubStr(scriptPath, -3) != ".ahk")
		return ""
	return A_ScriptDir "\" scriptPath
}

OnTCPAccept(this)
{
    global Client
    Client := this.accept()
    Client.onRecv := func("OnTCPRecvServer")
    Client.sendText("LibreDeck Server")
}

StartLibreDeckDiscoveryServer()
{
	global LD_ServerDiscoverySock, LD_ServerDiscoverySocketCallback, LD_ServerDiscoveryWinsockStarted
	global LD_SERVER_DISCOVERY_SOCKET_MSG, LD_SERVER_DISCOVERY_FD_READ

	if(!LD_ServerDiscoveryWinsockStarted)
	{
		if(!LD_StartWinsock())
			return false
		LD_ServerDiscoveryWinsockStarted := true
	}

	LD_ServerDiscoverySock := LD_CreateUdpSocket()
	if(LD_ServerDiscoverySock = -1)
		return false
	if(!LD_Bind(LD_ServerDiscoverySock, 37921))
	{
		LD_CloseSocket(LD_ServerDiscoverySock)
		LD_ServerDiscoverySock := -1
		return false
	}

	if(LD_ServerDiscoverySocketCallback = "")
		LD_ServerDiscoverySocketCallback := Func("LibreDeckDiscoveryServerSocketMessage")
	OnMessage(LD_SERVER_DISCOVERY_SOCKET_MSG, LD_ServerDiscoverySocketCallback)
	if(!LD_RegisterAsync(LD_ServerDiscoverySock, LD_SERVER_DISCOVERY_SOCKET_MSG, LD_SERVER_DISCOVERY_FD_READ))
	{
		OnMessage(LD_SERVER_DISCOVERY_SOCKET_MSG, LD_ServerDiscoverySocketCallback, 0)
		LD_CloseSocket(LD_ServerDiscoverySock)
		LD_ServerDiscoverySock := -1
		return false
	}
	return true
}

StopLibreDeckDiscoveryServer(cleanWinsock := false)
{
	global LD_ServerDiscoverySock, LD_ServerDiscoverySocketCallback, LD_ServerDiscoveryWinsockStarted, LD_SERVER_DISCOVERY_SOCKET_MSG

	if(LD_ServerDiscoverySock != -1)
	{
		if(LD_ServerDiscoverySocketCallback != "")
			OnMessage(LD_SERVER_DISCOVERY_SOCKET_MSG, LD_ServerDiscoverySocketCallback, 0)
		LD_UnregisterAsync(LD_ServerDiscoverySock, LD_SERVER_DISCOVERY_SOCKET_MSG)
		LD_CloseSocket(LD_ServerDiscoverySock)
		LD_ServerDiscoverySock := -1
	}
	if(cleanWinsock && LD_ServerDiscoveryWinsockStarted)
	{
		DllCall("Ws2_32\WSACleanup")
		LD_ServerDiscoveryWinsockStarted := false
	}
}

LibreDeckDiscoveryServerSocketMessage(wParam, lParam, msg, hwnd)
{
	global LD_ServerDiscoverySock, LD_SERVER_DISCOVERY_FD_READ, conf, versionNumber

	if(wParam != LD_ServerDiscoverySock)
		return
	if(LD_AsyncError(lParam))
		return
	if(LD_AsyncEvent(lParam) != LD_SERVER_DISCOVERY_FD_READ)
		return

	received := LD_RecvOne(LD_ServerDiscoverySock, message, ip, port, fromAddr)
	if(received = -1)
		return

	if(InStr(message, "LIBREDECK_DISCOVER") = 1)
	{
		response := "LIBREDECK_SERVER|version=" versionNumber "|name=" A_ComputerName "|tcp_port=" conf.port "|resource_port=" conf.resourceSharePort
		LD_SendToAddr(LD_ServerDiscoverySock, response, fromAddr)
	}
}

7zImageButtons:
    Run, % """" A_ScriptDir "/lib/autohotkey.exe"" " """" A_ScriptDir """/lib/compress_and_md5.ahk""", A_ScriptDir
return

restart:
    Reload
return

FileMD5(filename)
{
    return CalcFileHash(filename, 0x8003, 64 * 1024)
}

setPort:
    InputBox, port, Port to Use, Insert Port to use for the server:
    if(Trim(port) != "" && Trim(port) >= 1 && Trim(port) <= 65535)
    {
		InputBox, resourceSharePort, File Port to Use, Insert Port to use for button images:
		if(Trim(resourceSharePort) != "" && Trim(resourceSharePort) >= 1 && Trim(resourceSharePort) <= 65535 && Trim(port) != Trim(resourceSharePort))
		{
			conf.port := Trim(port)
			conf.resourceSharePort := Trim(resourceSharePort)
			gosub, guardarConfig
		}
		else
		{
			MsgBox, You didn't set a port or it was invalid (valid range 1-65535)!`nAlso make sure that file port and server port are different!
		}
    }
    else
    {
        MsgBox, You didn't set a port or it was invalid (valid range 1-65535)!
    }
return

startWebServer:
	gosub, killPreviousInstance
	Run, % "./lib/httpsrv.exe -d 0 -v 0 -p " conf.resourceSharePort " -r """ A_ScriptDir "\resources\shared""",, Hide
return

killPreviousInstance:
	process = httpsrv.exe
	Process, Exist, %process%
	if	pid :=	ErrorLevel
	{
		Loop
		{
			WinClose, ahk_pid %pid%, , 5
			if	ErrorLevel
				Process, Close, %pid%
			Process, Exist, %process%
		}	Until	!pid :=	ErrorLevel
	}
return

startWithWindows:
	conf.startWithWindows := !conf.startWithWindows
	gosub, guardarConfig
	if(conf.startWithWindows)
	{
		FileCreateShortcut, %A_ScriptFullPath%, %A_AppData%\Microsoft\Windows\Start Menu\Programs\Startup\LibreDeck Server.lnk, %A_ScriptDir%, LibreDeck Server Software
		Menu, tray, Check, Run on Startup
	}
	else
	{
		FileDelete, %A_AppData%\Microsoft\Windows\Start Menu\Programs\Startup\LibreDeck Server.lnk
		Menu, tray, Uncheck, Run on Startup
	}
return

showAboutScreen:
	showAboutScreen("LibreDeck Server v" versionNumber, "A multi-purpose RPC server for triggering scripts remotely on the running host via RAW TCP sockets.")
return

openLibreDeckFolder:
	Run, % A_ScriptDir
return

runClient:
	clienteExecutable := "LibreDeck Client.exe"
	previousDetectHiddenWindows := A_DetectHiddenWindows
	IfWinNotExist, ahk_exe %clienteExecutable%
	{
		DetectHiddenWindows, On
		IfWinExist, ahk_exe %clienteExecutable%
		{
			WinShow, ahk_exe %clienteExecutable%
			WinActivate, ahk_exe %clienteExecutable%
		}
		else
		{
			Run, "%A_ScriptDir%\LibreDeck Client.exe"
		}
	}
	else
	{
		WinShow, ahk_exe %clienteExecutable%
		WinActivate, ahk_exe %clienteExecutable%
	}
	DetectHiddenWindows, % previousDetectHiddenWindows
return

contextcolor(color:=2)
{
	static uxtheme := DllCall("GetModuleHandle", "str", "uxtheme", "ptr")
	static SetPreferredAppMode := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 135, "ptr")
	static FlushMenuThemes := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 136, "ptr")
	DllCall(SetPreferredAppMode, "int", color)
	DllCall(FlushMenuThemes)
}
