; Version: 0.3.2
; Color param is deprecated!
#Include <talk>
nmMsg(nmMsg, time:=1, region:=0, color:="FFFFFF")
{
	detectHiddenWindowsPrev := A_DetectHiddenWindows
	DetectHiddenWindows, On
	if (WinExist("ahk_exe LibreDeck Client.exe")) {
		region := region ? "top" : "bottom"
		receiver := new talk("ahk_exe LibreDeck Client.exe")
		receiver.setVar("incomingNotification", "{""text"": """ nmMsg """, ""duration"": " time*1000 ", ""region"": """ region """}", 0)
		receiver.runlabel("showIncomingNotification", 0)
	}
	DetectHiddenWindows, % detectHiddenWindowsPrev
}
