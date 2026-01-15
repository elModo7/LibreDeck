#NoEnv
#SingleInstance Force
SetBatchLines, -1
#NoTrayIcon
#Include ./lib/JSON.ahk
#Include ./lib/MD5.ahk
; Imports y setworkingdir para modo standalone
;~ SetWorkingDir, % SubStr(A_ScriptDir, 1, InStr(SubStr(A_ScriptDir,1,-1), "\", 0, 0)-1) ; WorkingDir -> Parent Folder
;~ #Include JSON.ahk
;~ #Include MD5.ahk
FileRead, conf, ./conf/server_config.json
FileRead, client_conf, ./conf/config.json
global conf := ParseJson(conf)
global client_conf := ParseJson(client_conf)
gosub, 7zImageButtons
ExitApp

7zImageButtons:
    totalResourceSize := 0
    ToolTip, % "Calculating resource count..."
    Loop, Files, ./resources/img/*.png
    {
        totalResourceSize += A_LoopFileSize
    }
    if(totalResourceSize != conf.totalResourceSize)
    {
        conf.totalResourceSize := totalResourceSize
        FileDelete, % A_WorkingDir "\resources\shared\resourcePack.7z"
    }
    if(!FileExist(A_WorkingDir "\resources\shared\resourcePack.7z") || (conf.resourcePackMD5 !=  FileMD5(A_WorkingDir "\resources\shared\resourcePack.7z")))
    {
        ToolTip, % "Compressing..."
        RunWait, % A_WorkingDir "\lib\7za.exe a """ A_WorkingDir "\resources\shared\resourcePack.7z"" -m0=LZMA2 -mx=9 -mmt=on -aoa -mfb=64 """ A_WorkingDir "\resources\img\*.png""",, Hide
        RunWait, % A_WorkingDir "\lib\7za.exe a """ A_WorkingDir "\resources\shared\resourcePack.zip"" -tzip -mx=9 -mmt=on -aoa """ A_WorkingDir "\resources\img\*.png""",, Hide
        FileRead, conf, ./conf/server_config.json
        global conf := ParseJson(conf)
        conf.folderButtons := client_conf.folderButtons
        conf.totalResourceSize := totalResourceSize
        conf.resourcePackMD5 := FileMD5(A_WorkingDir "\resources\shared\resourcePack.7z")
        gosub, guardarConfig
    }
    ExitApp
return

guardarConfig:
	FileDelete, ./conf/server_config.json
    FileDelete, ./resources/shared/resourcePack_info.txt
	FileAppend, % JSON_Beautify(BuildJson(conf)), ./conf/server_config.json
    resourcePackData := {}
    resourcePackData.totalResourceSize := conf.totalResourceSize
    resourcePackData.resourcePackMD5 := conf.resourcePackMD5
    resourcePackData.folderButtons := conf.folderButtons
	FileAppend, % JSON_Beautify(BuildJson(resourcePackData)), ./resources/shared/resourcePack_info.txt
return


FileMD5(filename)
{
    return CalcFileHash(filename, 0x8003, 64 * 1024)
}