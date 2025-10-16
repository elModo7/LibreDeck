﻿lookForUpdates(silent := false){
	global ClientVersionNumber
	gitHubData := ParseJson(urlDownloadToVar("https://api.github.com/repos/elModo7/Nova-Macros/releases/latest"))
	gitHubVersion := gitHubData.tag_name
	versionDiff := VerCmp(gitHubVersion, ClientVersionNumber)
	if(versionDiff == "-1" && !silent){
		MsgBox 0x40, Nightly Build Detected, % "Your Nova Macros Client is more recent than the current public version:`n`nLocal: v" ClientVersionNumber "`nRemote: v" gitHubVersion
	}else if(versionDiff == "0" && !silent){
		MsgBox 0x40, Up to date, % "Nova Macros Client is up to date:`n`nLocal: v" ClientVersionNumber "`nRemote: v" gitHubVersion
	}else if(versionDiff == "1"){
		MsgBox 0x44, New version available!, % "There is a new Nova Macros Client version:`n`nLocal: v" ClientVersionNumber "`nRemote: v" gitHubVersion "`n`nDo you want to go to the downloads page now?"
		IfMsgBox Yes, {
			downloadLatestVersion()
		}
	}
}

downloadLatestVersion(){
	Run, https://github.com/elModo7/Nova-Macros/releases/latest
}