; This is also an example of the new notification system (3.7.6+)
; This script only works when run from LibreDeck Client!
#NoEnv
#Include lib/talk.ahk
DetectHiddenWindows, On
useTooltips := 0

if (!WinExist("LibreDeck Client"))
	useTooltips := 1 ; If LibreDeck is not open, then use tooltips

if (!useTooltips) {
	receiver := new talk("ahk_exe LibreDeck Client.exe") ; "Case Sensitive string of receiver script's WinTitle"
}
previousWorkingDir := A_WorkingDir
SetWorkingDir, %A_ScriptDir%
; Coge la fecha y hora
FormatTime, CurrentDateTime,, yyyyMMdd_HHmm
; Get Parent Folder Full Path
FolderParent := SubStr(A_ScriptDir, 1, InStr(SubStr(A_ScriptDir,1,-1), "\", 0, 0)-1)
LibreDeckFolder := SubStr(FolderParent, 1, InStr(SubStr(FolderParent,1,-1), "\", 0, 0)-1)
BackupFolder := SubStr(LibreDeckFolder, 1, InStr(SubStr(LibreDeckFolder,1,-1), "\", 0, 0)-1)
if (useTooltips)
	ToolTip, Creating LibreDeck Backup:`nThis might take a while...
else {
	receiver.setVar("incomingNotification", "{""text"": ""Creating LibreDeck Backup, be patient..."", ""duration"": 0, ""region"": ""bottom""}")
	receiver.runlabel("showIncomingNotification")
}

FileRead, libreDeckClientFile, % previousWorkingDir "\LibreDeck Client.ahk"
Loop, Parse, % libreDeckClientFile, `r`n
{
	if (Instr(A_LoopField, "global ClientVersionNumber := ")) {
		version := Trim(SubStr(A_LoopField, Instr(A_LoopField, "ClientVersionNumber := ") + 23, 50))
		StringReplace, version, % version, ",,All
		break
	}
}

RunWait, ..\lib\7za.exe a "%LibreDeckFolder%\LibreDeck %version% %CurrentDateTime%.7z" -m0=LZMA2 -mx=5 -mmt=on -aoa -mfb=64 "%FolderParent%",, Hide
if (useTooltips)
	ToolTip, Backup Created Successfully!
else {
	receiver.setVar("incomingNotification", "{""text"": ""Backup Created Successfully!"", ""duration"": 1000, ""region"": ""bottom""}")
	receiver.runlabel("showIncomingNotification")	
}	
;~ MsgBox, Backup creada con éxito! `nRuta de la carpeta comprimido: `n"%LibreDeckFolder%\LibreDeck %CurrentDateTime%.7z"
Run, explorer.exe /select`,"%LibreDeckFolder%\LibreDeck %version% %CurrentDateTime%.7z"
Sleep, 1000
ExitApp