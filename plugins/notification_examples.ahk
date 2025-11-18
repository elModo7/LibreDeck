; LibreDeck (3.7.6+)
#NoEnv
#SingleInstance Force
#Include ..\lib\talk.ahk
detectHiddenWindowsPrev := A_DetectHiddenWindows
DetectHiddenWindows, On
if (!WinExist("ahk_exe LibreDeck Client.exe")) {
	MsgBox 0x10, Client not found!, LibreDeck Client was not found!
	ExitApp
}

receiver := new talk("LibreDeck Client.exe")

nmMsg("Bottom Notification Example", 0)
Sleep, 2000
nmMsg("Top Notification Example", 0, 1)
Sleep, 2000
nmMsg("Removing top notification", 0)
receiver.runlabel("removeNotificationTop") ; Remove top notification
Sleep, 2000
nmMsg("Removing all notifications in 2 secs", 0, 1)
Sleep, 2000
receiver.runlabel("removeNotifications") ; Remove notifications
Sleep, 2000
nmMsg("Changing Page to 2", 0)
receiver.setVar("incomingPageChange", "{""pageNumber"": 1, ""isFolder"": 0, ""folderName"": """"}")
receiver.runlabel("remotePageChange")
Sleep, 2000
nmMsg("Change random button icon", 0)
Loop, 25
{
	Random, randomPng, 1, 15
	Random, randomButton, 1, 15
	receiver.setVar("incomingButtonChange", "{""imagePathOrName"": """ randomPng ".png"", ""buttonId"": " randomButton "}")
	receiver.runlabel("setButtonIconRemote") ; Set a random button to a random png (does NOT change button action!)
	Sleep, 50
}
nmMsg("Changing Page to OBS", 0)
receiver.setVar("incomingPageChange", "{""pageNumber"": 0, ""isFolder"": 1, ""folderName"": ""OBS""}")
receiver.runlabel("remotePageChange")
Sleep, 2000
receiver.runlabel("setBackground")
nmMsg("Changing Background...", 0)
Sleep, 500
receiver.setVar("incomingBackgroundChange", "{""imagePathOrName"": ""resources/img/backgrounds/background2.png""}")
receiver.runlabel("setBackground")
Sleep, 2000
receiver.setVar("incomingBackgroundChange", "{""imagePathOrName"": ""resources/img/backgrounds/background3.png""}")
receiver.runlabel("setBackground")
Sleep, 2000
nmMsg("Reverting...", 0)
receiver.setVar("incomingPageChange", "{""pageNumber"": 0, ""isFolder"": 0, ""folderName"": """"}")
receiver.runlabel("remotePageChange")
receiver.setVar("incomingBackgroundChange", "{""imagePathOrName"": ""background.png""}")
receiver.runlabel("setBackground")
receiver.runlabel("refreshButtons")
Sleep, 500
nmMsg("Test Done!", 0)
Sleep, 1000
receiver.runlabel("removeNotifications")
ExitApp

; This is nm_msg.ahk -> referenced here due to relative includes conflict
nmMsg(nmMsg, time:=1, region:=0, color:="FFFFFF")
{
	global receiver
	detectHiddenWindowsPrev := A_DetectHiddenWindows
	DetectHiddenWindows, On
	if (WinExist("ahk_exe LibreDeck Client.exe")) {
		region := region ? "top" : "bottom"
		;~ receiver := new talk("LibreDeck Client")
		receiver.setVar("incomingNotification", "{""text"": """ nmMsg """, ""duration"": " time*1000 ", ""region"": """ region """}")
		receiver.runlabel("showIncomingNotification")
	}
	DetectHiddenWindows, % detectHiddenWindowsPrev
}