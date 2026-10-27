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
global fullFilePath, workingDir, fileName, runAsAdmin, LD_SG_WindowTitle
global switchIfExist := 1
LD_SG_WindowTitle := LD_SG_T("script_gen_window.run_file.title", "Run File generator")
SkinForm(Apply, A_ScriptDir . "\lib\them.dll", A_ScriptDir . "\lib\tm")
OnExit, GetOut

Gui Add, Edit, vfullFilePath x16 y8 w365 h21
Gui Add, Edit, vworkingDir x80 y40 w301 h21
Gui Add, Text, x16 y40 w62 h23 +0x200, % LD_SG_T("script_gen_window.working_dir", "Working Dir:")
Gui Add, Button, gSelectFile x384 y7 w80 h23, % LD_SG_T("script_gen_window.run_file.select_file", "Select File")
Gui Add, CheckBox, vswitchIfExist gswitchIfExist x16 y72 w191 h23 +Checked, % LD_SG_T("script_gen_window.run_file.switch_if_open", "Switch to app if it is already open")
Gui Add, CheckBox, vrunAsAdmin grunAsAdmin x16 y96 w120 h23, % LD_SG_T("script_gen_window.force_admin", "Force run as admin")
Gui Font, Bold
Gui Add, Button, x16 y120 w246 h28 gDetect, % LD_SG_T("script_gen_window.detect_open_program", "+ Detect already open program")
Gui Add, Button, gcreateMacro x360 y120 w104 h28, % LD_SG_T("script_gen_window.apply", "APPLY")

Gui Show, w472 h157, %LD_SG_WindowTitle%
Return

Detect:
	MsgBox,,% LD_SG_T("script_gen_window.select_window_title", "Select Window"), % LD_SG_T("script_gen_window.run_file.select_window_prompt", "1) Activate a window of the program you want this macro to run `n2) Press ENTER")
	Hotkey, Enter, DetectOpenProgram, On
return

DetectOpenProgram:
	winget, appPath, processpath, a
	SplitPath, appPath, fileName, workingDir
	fullFilePath := appPath
	Hotkey, Enter, DetectOpenProgram, Off
	GuiControl,,fullFilePath, % fullFilePath
	GuiControl,,workingDir, % workingDir
	WinActivate, %LD_SG_WindowTitle%
return

SelectFile:
	FileSelectFile, fullFilePath,, %A_Desktop%, % LD_SG_T("script_gen_window.run_file.select_file_dialog", "Select file to run")
	if(fullFilePath != "")
	{
		GuiControl,,fullFilePath, % fullFilePath
		SplitPath, fullFilePath, fileName, workingDir
		GuiControl,,workingDir, % workingDir
	}
Return

switchIfExist:
	GuiControlGet, switchIfExist,,switchIfExist
Return

runAsAdmin:
	GuiControlGet, runAsAdmin,,runAsAdmin
Return

createMacro:
	if(fullFilePath = "")
	{
		MsgBox 0x10, % LD_SG_T("script_gen_window.error_title", "Error"), % LD_SG_T("script_gen_window.run_file.no_file_path", "No file path selected!")
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
	if(!switchIfExist && !runAsAdmin)
	{
		src =
		(
#NoEnv
#SingleInstance, Force
SetBatchLines, -1
#NoTrayIcon
SetWorkingDir %workingDir%
Run, %fullFilePath%
		)
	}
	else if(switchIfExist && !runAsAdmin)
	{
		src =
		(
#NoEnv
#SingleInstance, Force
SetBatchLines, -1
#NoTrayIcon
SetWorkingDir %workingDir%

global Executable := "%fileName%"

IfWinExist, ahk_exe `%Executable`%
{
	WinActivate, ahk_exe `%Executable`%
}
else
{
	Run, "%fullFilePath%"
}
		)
	}
	else if(switchIfExist && runAsAdmin)
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

global Executable := "%fileName%"

IfWinExist, ahk_exe `%Executable`%
{
	WinActivate, ahk_exe `%Executable`%
}
else
{
	Run, "%fullFilePath%"
}
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
