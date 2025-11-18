; Version: 0.3.1
; Color param is deprecated!
#Include talk.ahk
nmMsg(nmMsg, time:=1, region:=0, color:="FFFFFF")
{
	detectHiddenWindowsPrev := A_DetectHiddenWindows
	DetectHiddenWindows, On
	if (WinExist("ahk_exe LibreDeck Client.exe")) {
		region := region ? "top" : "bottom"
		receiver := new talk("LibreDeck Client.exe")
		receiver.setVar("incomingNotification", "{""text"": """ nmMsg """, ""duration"": " time*1000 ", ""region"": """ region """}")
		receiver.runlabel("showIncomingNotification")
	}
	DetectHiddenWindows, % detectHiddenWindowsPrev
}