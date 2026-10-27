; Version 1.1
/* Changelog
	1.1: Add quotes to command definition
*/
#SingleInstance Force
#NoEnv
SetBatchLines -1
#Include lib\cJSON.ahk
#Include lib\i18n.ahk
#Include lib\script_generator\i18n_helper.ahk
LD_SG_InitI18n()
global buttonPath = %0%
if(SubStr(buttonPath, -3) != ".ahk")
	buttonPath := buttonPath ".ahk"
SplitPath, buttonPath,, buttonDir
if(buttonDir != "")
	FileCreateDir, %buttonDir%
global workingDir, command, runAsAdmin, hideCmd, runAsCmd, keepCmdOpen, LD_SG_WindowTitle
LD_SG_WindowTitle := LD_SG_T("script_gen_window.run_cmd.title", "Run Cmd generator")
SkinForm(Apply, A_ScriptDir . "\lib\them.dll", A_ScriptDir . "\lib\tm")
OnExit, GetOut

Gui Add, Edit, vcommand x16 y8 w365 h21
Gui Add, Edit, vworkingDir x80 y40 w301 h21
Gui Add, Text, x16 y40 w62 h23 +0x200, % LD_SG_T("script_gen_window.working_dir", "Working Dir:")
Gui Add, CheckBox, vhideCmd ghideCmd x16 y72 w191 h23, % LD_SG_T("script_gen_window.run_cmd.hide_cmd", "Hide cmd.exe or program")
Gui Add, CheckBox, vrunAsAdmin grunAsAdmin x16 y96 w120 h23, % LD_SG_T("script_gen_window.force_admin", "Force run as admin")
Gui Add, CheckBox, vrunAsCmd grunAsCmd x16 y120 w160 h23, % LD_SG_T("script_gen_window.run_cmd.run_from_cmd", "Run from cmd.exe window")
Gui Add, CheckBox, vkeepCmdOpen gkeepCmdOpen x16 y144 w160 h23 Disabled, % LD_SG_T("script_gen_window.run_cmd.keep_cmd_open", "Keep cmd.exe open")
Gui Font, Bold
Gui Add, Button, gcreateMacro x278 y136 w104 h28, % LD_SG_T("script_gen_window.apply", "APPLY")

Gui Show, w395 h178, %LD_SG_WindowTitle%
Return

hideCmd:
	GuiControlGet, hideCmd,,hideCmd
Return

runAsAdmin:
	GuiControlGet, runAsAdmin,,runAsAdmin
Return

runAsCmd:
	GuiControlGet, runAsCmd,,runAsCmd
	if(runAsCmd){
		GuiControl, Enable, keepCmdOpen
	}else{
		GuiControl, Disable, keepCmdOpen
	}
Return

keepCmdOpen:
	GuiControlGet, keepCmdOpen,,keepCmdOpen
Return

createMacro:
	GuiControlGet, command,,command
	GuiControlGet, workingDir,,workingDir
	if(command = "")
	{
		MsgBox 0x10, % LD_SG_T("script_gen_window.error_title", "Error"), % LD_SG_T("script_gen_window.run_cmd.no_command", "No command selected!")
		return
	}
	else if(workingDir = "")
	{
		workingDir := A_Desktop
	}
	if FileExist(buttonPath)
	{
		OnMessage(0x44, "OnMsgBox")
		MsgBox 0x34, % LD_SG_T("script_gen_window.overwrite_title", "Overwrite?"), % LD_SG_T("script_gen_window.overwrite_prompt", "This button already has a macro file`, do you want to overwrite it?`n`nPrevious function will be lost!")
		OnMessage(0x44, "")

		IfMsgBox Yes, {
			Generar()
		}
	}
	else
	{
		Generar()
	}
Return

Generar()
{
	if(runAsCmd)
	{
		if(keepCmdOpen)
			compsec := "cmd /k"
		else
			compsec := "cmd /c"
		command := """" command """"
	}
	else
	{
		compsec := ""
	}
	if(hideCmd)
	{
		hideCmdTxt := ",,Hide"
	}
	else
	{
		hideCmdTxt := ""
	}
	if(!runAsAdmin)
	{
		src =
		(
#NoEnv
#SingleInstance, Force
SetBatchLines, -1
#NoTrayIcon
SetWorkingDir %workingDir%
Run, %compsec% "%command%"%hideCmdTxt%
		)
	}
	else if(runAsAdmin)
	{
		src =
		(
#NoEnv
#SingleInstance, Force
SetBatchLines, -1
#NoTrayIcon
if not A_IsAdmin
{
   DllCall("shell32\ShellExecute", uint, 0, str, "RunAs", str, A_ScriptFullPath, str, params , str, A_WorkingDir, int, 1)
}
SetWorkingDir %workingDir%
Run, %compsec% "%command%"%hideCmdTxt%
)
	}
	FileDelete, % buttonPath
	FileAppend, %src%, % buttonPath
	ExitApp
}

GetOut:
GuiEscape:
GuiClose:
	SkinForm(0)
    ExitApp
	
OnMsgBox() {
    DetectHiddenWindows, On
    Process, Exist
    If (WinExist("ahk_class #32770 ahk_pid " . ErrorLevel)) {
        ControlSetText Button1, % LD_SG_T("script_gen_window.overwrite_button", "Overwrite")
        ControlSetText Button2, % LD_SG_T("script_gen_window.cancel_button", "CANCEL")
    }
}

SkinForm(Param1 = "Apply", DLL = "", SkinName = ""){
	if(Param1 = Apply){
		DllCall("LoadLibrary", str, DLL)
		DllCall(DLL . "\USkinInit", Int,0, Int,0, AStr, SkinName)
	}else if(Param1 = 0){
		DllCall(DLL . "\USkinExit")
		}
}
