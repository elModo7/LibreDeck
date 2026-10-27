; Version: 0.1
; Author: elModo7 / VictorDevLog
; https://github.com/elModo7
class i18n
{
    __New(baseDir := "", defaultLocale := "", fallbackLocale := "en_US")
    {
        this.baseDir := baseDir
        this.locales := {}               ; code => full json object
        this.translations := {}          ; code => translations object
        this.defaultLocale := defaultLocale
        this.locale := defaultLocale
        this.fallback := []              ; ordered list of fallback locales
        if (fallbackLocale != "")
            this.SetFallback(fallbackLocale)
    }

    ; --- Loading -------------------------------------------------------------

    LoadFile(filePath)
    {
        jsonText := this._ReadUtf8(filePath)
        data := JSON.Load(jsonText)

        code := data.language_code
        if (code = "")
            throw Exception("I18n.LoadFile: missing language_code in " . filePath)

        if (!IsObject(data.translations))
            throw Exception("I18n.LoadFile: missing translations object in " . filePath)

        this.locales[code] := data
        this.translations[code] := data.translations

        ; Set a sensible default locale the first time we load something
        if (this.locale = "")
            this.SetLocale(code)

        return code
    }

    LoadDir(dirPath := "", pattern := "*.json")
    {
        if (dirPath = "")
            dirPath := this.baseDir
        if (dirPath = "")
            throw Exception("I18n.LoadDir: dirPath/baseDir is empty")

        Loop, Files, % dirPath . "\" . pattern, F
            this.LoadFile(A_LoopFileFullPath)

        return this.AvailableLocales()
    }

    ; --- Locale selection ----------------------------------------------------

    SetLocale(code)
    {
        this.locale := code
        if (this.defaultLocale = "")
            this.defaultLocale := code
        return code
    }

    ; Accepts any mix of: SetFallback("en_US") OR SetFallback(["en_US","es_ES"])
    SetFallback(fallback)
    {
        this.fallback := []
        if (IsObject(fallback)) {
            for _, c in fallback
                if (c != "")
                    this.fallback.Push(c)
        } else if (fallback != "") {
            this.fallback.Push(fallback)
        }
        return this.fallback
    }

    AvailableLocales()
    {
        out := []
        for code, _ in this.translations
            out.Push(code)
        return out
    }

    ; --- Translation ---------------------------------------------------------

    ; t("key") -> string
    ; t("key", {name:"Jaime"}) -> replaces {name}
    ; t("key", ["a","b"]) -> uses Format() positional: {1} {2} ...
    ; t("missing", "", "Default text") -> returns default
    t(key, params := "", default := "")
    {
        val := this._Get(key, this.locale)
        if (val = "")
            val := this._Get(key, this.defaultLocale)

        if (val = "") {
            for _, fb in this.fallback {
                val := this._Get(key, fb)
                if (val != "")
                    break
            }
        }

        if (val = "")
            return (default != "" ? default : key)

        return this._Interpolate(val, params)
    }

    Has(key, locale := "")
    {
        if (locale = "")
            locale := this.locale
        return (this._Get(key, locale) != "")
    }

    ; --- Internals -----------------------------------------------------------

    _Get(key, locale)
    {
        if (key = "" || locale = "")
            return ""

        tr := this.translations[locale]
        if (!IsObject(tr))
            return ""

        if (tr.HasKey(key))
            return tr[key]

        ; Supports nested keys like "menu.file.open" if translations are nested objects.
        if (InStr(key, ".")) {
            cur := tr
            Loop, Parse, key, .
            {
                part := A_LoopField
                if (!IsObject(cur) || !cur.HasKey(part))
                    return ""
                cur := cur[part]
            }
            return (IsObject(cur) ? "" : cur)
        }

        return ""
    }

    _Interpolate(text, params)
    {
        if (!IsObject(params))
            return text

        ; Array -> positional formatting via Format() if the text has {1} {2} ...
        if (this._IsArray(params)) {
            try 
                return Format(text, params*)
            catch 
                return text
        }

        ; Map/object -> {name} replacement
        out := text
        for k, v in params
            out := StrReplace(out, "{" . k . "}", v)
        return out
    }

    _IsArray(obj)
    {
        return (IsObject(obj) && obj.HasKey(1))
    }

    _ReadUtf8(filePath)
    {
        ; Read as UTF-8 (codepage 65001). Works with accents/ñ/etc.
        ;~ FileRead, txt, *P65001 %filePath%
        FileRead, txt, %filePath%
        if (ErrorLevel)
            throw Exception("I18n: failed to read file: " . filePath)
        return txt
    }
}
