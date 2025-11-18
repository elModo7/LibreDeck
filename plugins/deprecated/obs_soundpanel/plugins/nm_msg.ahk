global txtNMMsg
nmMsg(nmMsg,time)
{
	WinGetPos,X,Y,,,LibreDeck Client
	nfX := X
	nfY := Y + 500
	Gui nmMsg:+ToolWindow -Caption +AlwaysOnTop
	Gui nmMsg:Color, Black
	Gui nmMsg:Font, s24 c0xFFFF80, Press Start 2P
	Gui nmMsg:Add, Text, vtxtNMMsg x24 y48 w1024 h60 +0x200 +Center +BackgroundTrans, % nmMsg
	Gui nmMsg:Show, x%nfX% y%nfY% w1024 h159,msgLibreDeck
	WinSet, TransColor, Black,msgLibreDeck
	Loop, % time
	{
		GuiControl, nmMsg: +cfb0505 +Redraw, txtNMMsg
		Sleep, 100
		GuiControl, nmMsg: +cfb7607 +Redraw, txtNMMsg
		Sleep, 100
		GuiControl, nmMsg: +cf4ea07 +Redraw, txtNMMsg
		Sleep, 100
		GuiControl, nmMsg: +c61f205 +Redraw, txtNMMsg
		Sleep, 100
		GuiControl, nmMsg: +c00f6cb +Redraw, txtNMMsg
		Sleep, 100
	}
	Gui, Destroy
}