#NoEnv
#SingleInstance,Force
global WindowsKey, Edt1, Edt2
global buttonPath = %0%
if(SubStr(buttonPath, -3) != ".ahk")
	buttonPath := buttonPath ".ahk"
SplitPath, buttonPath,, buttonDir
if(buttonDir != "")
	FileCreateDir, %buttonDir%
global delay
SkinForm(Apply, A_ScriptDir . "\lib\them.dll", A_ScriptDir . "\lib\tm")
OnExit, GetOut
WindowsKey := 0

Gui, +hwndHw
Gui, Color, , 44444444
Gui, Font, s14 cffff00 TAhoma
Gui,Add,Hotkey, W280 x-990 y6 vEdt1 gEdt1 hwndHedt1
Gui,Add,Edit, x10 y6 w350 gEdt2 vEdt2 hwndHedt2 Background00ffff, None
Gui, Font, s10 c000000 TAhoma
Gui Font, Bold
Gui Add, CheckBox, x16 y48 w190 h23 gWindowsKey vWindowsKey, Windows Key Pressed
Gui Add, Button, x260 y104 w95 h30 gCreate, APPLY
Gui Add, Text, x16 y80 w90 h23 +0x200, Custom Key:
Gui, Font, s10 cffff00 TAhoma
Gui Add, Edit, vcustomKey gcustomKey x110 y80 w120 h21 ; Custom Key
Gui, Font, s10 c000000 TAhoma
Gui Add, Text, x16 y112 w70 h23 +0x200, Delay (s):
Gui, Font, s10 cffff00 TAhoma
Gui Add, Edit, vdelay x90 y112 w47 h21 +Number ; Delay
Gui,Show, w370 h142, Generate Macro

GuiControl, Focus, Edt1
;~ OnMessage(0x133, "Focus_Hk") ; Auto Focus Hotkey Field
;~ SetTimer, FcEdt, 250
return

Focus_Hk() {
    GuiControl, Focus, Edt1
}

customKey:
    GuiControlGet, customKey,,customKey
    GuiControl,,Edt2, % customKey
    GuiControl,,Edt1, % customKey
return

;~ FcEdt:
    ;~ if !WinActive("ahk_id " Hw)
        ;~ GuiControl, Focus, Edt2
;~ return

Edt2:
    ControlGetFocus, focusedControl, A
    if(focusedControl = "Edit1")
    {
        GuiControl, Focus, Edt1
    }
return

Edt1:
    GuiControlGet, Ehk,, Edt1
    StringUpper, Ehk, Ehk , T
    Ehk:=StrReplace(Ehk, "`+", "Shift + "), Ehk:=StrReplace(Ehk, "`!", "Alt + "), Ehk:=StrReplace(Ehk, "`^", "Ctrl + ")
    if Ehk
        GuiControl,, Edt2, % Ehk
    else GuiControl,, Edt2, None
Return

WindowsKey:
    WindowsKey := !WindowsKey
return

Create:
    if FileExist(buttonPath)
	{
		OnMessage(0x44, "OnMsgBox")
		MsgBox 0x34, Overwrite?, This button already has a macro file`, do you want to overwrite it?`n`nPrevious function will be lost!
		OnMessage(0x44, "")

		IfMsgBox Yes, {
			Generar()
		}
	}
	else
	{
		Generar()
	}
return

Generar()
{
    Gui, Submit, NoHide
    Key := SubStr(Edt1, StrLen(Edt1), 1)
    if(Key = "+")
    {
        StringTrimRight, EdtNoPlusKey, Edt, 1
        plusKey := 1
    }
    else
    {
        plusKey := 0
    }
    if(!plusKey)
    {
        mas := InStr(Edt1,"+",0,0)
        acento := InStr(Edt1,"^",0,0)
        admiracion := InStr(Edt1,"!",0,0)
        if(mas > acento && mas > admiracion)
        {
            Modificadores := SubStr(Edt1, 1, mas)
        }
        else if(acento > mas && acento > admiracion)
        {
            Modificadores := SubStr(Edt1, 1, acento)
        }
        else if(admiracion > acento && admiracion > mas)
        {
            Modificadores := SubStr(Edt1, 1, admiracion)
        }
        if(mas = 0 && acento = 0 && admiracion = 0 && WindowsKey = 0)
        {
            hayModificadores := 0
        }else
        {
            hayModificadores := 1
        }
        StringReplace, Key, Edt1, %Modificadores%,,All
        Key = {%Key%}
    }
    else
    {
        mas := InStr(EdtNoPlusKey,"+",0,0)
        acento := InStr(EdtNoPlusKey,"^",0,0)
        admiracion := InStr(EdtNoPlusKey,"!",0,0)
        if(mas > acento && mas > admiracion)
        {
            Modificadores := SubStr(EdtNoPlusKey, 1, mas)
        }
        else if(acento > mas && acento > admiracion)
        {
            Modificadores := SubStr(EdtNoPlusKey, 1, acento)
        }
        else if(admiracion > acento && admiracion > mas)
        {
            Modificadores := SubStr(EdtNoPlusKey, 1, admiracion)
        }
        if(mas = 0 && acento = 0 && admiracion = 0 && WindowsKey = 0)
        {
            hayModificadores := 0
        }else
        {
            hayModificadores := 1
        }
        Key := "+"
    }
    
    strModificadoresDown := ""
    strModificadoresUp := ""
    if(Instr(Modificadores, "!"))
    {
        alt := 1
        strModificadoresDown := strModificadoresDown "{Alt Down}"
        strModificadoresUp := strModificadoresUp "{Alt Up}"
    }
    else
    {
        alt := 0
    }
    if(Instr(Modificadores, "^"))
    {
        control := 1
        strModificadoresDown := strModificadoresDown "{Control Down}"
        strModificadoresUp := strModificadoresUp "{Control Up}"
    }
    else
    {
        control := 0
    }
    if(Instr(Modificadores, "+"))
    {
        shift := 1
        strModificadoresDown := strModificadoresDown "{Shift Down}"
        strModificadoresUp := strModificadoresUp "{Shift Up}"
    }
    else
    {
        shift := 0
    }
    if(WindowsKey)
    {
        strModificadoresDown := strModificadoresDown "{LWin Down}"
        strModificadoresUp := strModificadoresUp "{LWin Up}"
    }
    if(delay != "")
    {
        delay := "Sleep, " delay*1000
    }
    if(!hayModificadores)
    {
		src =
		(Ltrim
            #NoEnv
            #SingleInstance, Force
            SetBatchLines, -1
            #NoTrayIcon
            %delay%
            Send, %Key%
        )
    }
    else
    {
        src =
		(Ltrim
            #NoEnv
            #SingleInstance, Force
            SetBatchLines, -1
            #NoTrayIcon
            %delay%
            Send, %strModificadoresDown%
            Sleep, 30
            Send, %Key%
            Sleep, 30
            Send, %strModificadoresUp%
            Sleep, 30
        )
    }
    FileDelete, % buttonPath
	FileAppend, %src%, % buttonPath
	ExitApp
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
GuiClose:
    SkinForm(0)
	ExitApp
