global LD_SG_i18n := ""

LD_SG_InitI18n()
{
	global LD_SG_i18n

	rootDir := A_WorkingDir
	if(!FileExist(rootDir "\conf\config.json"))
		rootDir := RegExReplace(A_ScriptDir, "\\lib\\script_generator$")

	locale := "en_US"
	if(FileExist(rootDir "\conf\config.json"))
	{
		FileRead, configJson, % rootDir "\conf\config.json"
		try
		{
			config := JSON.Load(configJson)
			if(config.language != "")
				locale := config.language
		}
	}

	LD_SG_i18n := new i18n(rootDir "\i18n", locale, ["en_US"])
	try LD_SG_i18n.LoadDir(rootDir "\i18n")
	catch e
		LD_SG_i18n := ""
}

LD_SG_T(key, default := "", params := "")
{
	global LD_SG_i18n

	if(IsObject(LD_SG_i18n))
		return LD_SG_i18n.t(key, params, default)
	if(default != "")
		return default
	return key
}
