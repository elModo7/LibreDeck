lookForUpdates(silent := false){
	global ClientVersionNumber, JSON
	gitHubData := JSON.Load(urlDownloadToVar("https://api.github.com/repos/elModo7/LibreDeck/releases/latest"))
	gitHubVersion := gitHubData.tag_name
	versionDiff := VerCmp(gitHubVersion, ClientVersionNumber)
	if(versionDiff == "-1" && !silent){
		MsgBox 0x40, % LD_TR("updates.nightly_title", "Nightly Build Detected"), % LD_TR("updates.nightly_message", "Your LibreDeck Client is more recent than the current public version:`n`nLocal: v{local}`nRemote: v{remote}", {local: ClientVersionNumber, remote: gitHubVersion})
	}else if(versionDiff == "0" && !silent){
		MsgBox 0x40, % LD_TR("updates.up_to_date_title", "Up to date"), % LD_TR("updates.up_to_date_message", "LibreDeck Client is up to date:`n`nLocal: v{local}`nRemote: v{remote}", {local: ClientVersionNumber, remote: gitHubVersion})
	}else if(versionDiff == "1"){
		MsgBox 0x44, % LD_TR("updates.available_title", "New version available!"), % LD_TR("updates.available_message", "There is a new LibreDeck Client version:`n`nLocal: v{local}`nRemote: v{remote}`n`nDo you want to go to the downloads page now?", {local: ClientVersionNumber, remote: gitHubVersion})
		IfMsgBox Yes, {
			downloadLatestVersion()
		}
	}
}

LD_TR(key, default := "", params := "")
{
	try
		return LD_T(key, default, params)
	catch
		return default
}

downloadLatestVersion(){
	Run, https://github.com/elModo7/LibreDeck/releases/latest
}
