; LibreDeckButtonImage.ahk
; AutoHotkey v1 library for generating configurable PNG button images.
; Self-contained: uses Windows GDI+ directly, no Gdip_All.ahk required.
; Version: 0.1.1

; -----------------------------------------------------------------------------
; Public API
; -----------------------------------------------------------------------------

LD_ButtonImage_Start() {
    global LD_ButtonImage_GdipToken
    if (LD_ButtonImage_GdipToken)
        return true
    return LD_Gdip_Startup(LD_ButtonImage_GdipToken)
}

LD_ButtonImage_Shutdown() {
    global LD_ButtonImage_GdipToken
    if (LD_ButtonImage_GdipToken) {
        LD_Gdip_Shutdown(LD_ButtonImage_GdipToken)
        LD_ButtonImage_GdipToken := 0
    }
}

LD_ButtonImage_Render(outputPath, cfg := "") {
    if (!IsObject(cfg))
        cfg := {}

    if (!LD_ButtonImage_Start())
        return false

    width := LD_Cfg(cfg, "width", 144)
    height := LD_Cfg(cfg, "height", 144)
    styleName := StrLower(Trim(LD_Cfg(cfg, "style", "neon")))
    style := LD_ButtonImage_GetStyle(styleName)

    bgColor := LD_Color(LD_Cfg(cfg, "bgColor", style.bgColor))
    accentColor := LD_Color(LD_Cfg(cfg, "accentColor", style.accentColor))
    textColor := LD_Color(LD_Cfg(cfg, "textColor", style.textColor))
    valueColor := LD_Color(LD_Cfg(cfg, "valueColor", style.valueColor))
    borderColor := LD_Color(LD_Cfg(cfg, "borderColor", style.borderColor))
    shadowColor := LD_Color(LD_Cfg(cfg, "shadowColor", style.shadowColor))

    font := LD_Cfg(cfg, "font", "Segoe UI")
    titleSize := LD_Cfg(cfg, "titleSize", style.titleSize)
    valueSize := LD_Cfg(cfg, "valueSize", style.valueSize)
    subtitleSize := LD_Cfg(cfg, "subtitleSize", style.subtitleSize)
    border := LD_Cfg(cfg, "border", style.border)
    radius := LD_Cfg(cfg, "radius", style.radius)

    titleY := LD_Cfg(cfg, "titleY", style.titleY)
    valueY := LD_Cfg(cfg, "valueY", style.valueY)
    valueX := LD_Cfg(cfg, "valueX", style.valueX)
    subtitleY := LD_Cfg(cfg, "subtitleY", height - 35)

    title := LD_Cfg(cfg, "title", "")
    value := LD_Cfg(cfg, "value", "")
    subtitle := LD_Cfg(cfg, "subtitle", "")
    iconPath := LD_Cfg(cfg, "iconPath", "")
    progress := LD_Cfg(cfg, "progress", "")

    pBitmap := LD_Gdip_CreateBitmap(width, height)
    if (!pBitmap)
        return false

    G := LD_Gdip_GraphicsFromImage(pBitmap)
    LD_Gdip_SetSmoothingMode(G, 4)
    LD_Gdip_SetInterpolationMode(G, 7)
    LD_Gdip_GraphicsClear(G, bgColor)

    if (styleName = "glass")
        LD_DrawGlassLayer(G, width, height)

    if (shadowColor)
        LD_FillRoundedRect(G, 7, 8, width - 14, height - 14, radius, shadowColor)

    if (border > 0)
        LD_DrawRoundedRect(G, borderColor, border, 4, 4, width - 8, height - 8, radius)

    if (style.accentStrip)
        LD_FillRoundedRect(G, 10, height - 14, width - 20, 4, 2, accentColor)

    if (iconPath != "" && FileExist(iconPath)) {
        iconW := LD_Cfg(cfg, "iconW", style.iconW)
        iconH := LD_Cfg(cfg, "iconH", style.iconH)
        iconX := LD_Cfg(cfg, "iconX", (width - iconW) // 2)
        iconY := LD_Cfg(cfg, "iconY", style.iconY)
        LD_DrawImageFile(G, iconPath, iconX, iconY, iconW, iconH)
    }

    if (title != "")
        LD_DrawText(G, title, font, titleSize, textColor, 8, titleY, width - 16, 26, 1, 1, 1)

    if (value != "")
        LD_DrawText(G, value, font, valueSize, valueColor, 4, valueY, (valueX ? valueX : width - 8), 54, 1, 1, 1)

    if (subtitle != "")
        LD_DrawText(G, subtitle, font, subtitleSize, textColor, 8, subtitleY, width - 16, 22, 1, 1, 0)

    if (progress != "")
        LD_DrawProgress(G, progress, 14, height - 17, width - 28, 6, accentColor, 0x55333333)

    ok := LD_Gdip_SaveBitmapToFile(pBitmap, outputPath)

    LD_Gdip_DeleteGraphics(G)
    LD_Gdip_DisposeImage(pBitmap)

    return ok
}

LD_ButtonImage_RenderInventorySlot(outputPath, itemName, amount := "", iconPath := "", style := "resident") {
    cfg := {}
    cfg.style := style
    cfg.title := itemName
    cfg.value := amount
    cfg.iconPath := iconPath
    cfg.titleY := 96
    cfg.valueY := 108
    cfg.valueX := 50
    return LD_ButtonImage_Render(outputPath, cfg)
}

; -----------------------------------------------------------------------------
; Styles
; -----------------------------------------------------------------------------

LD_ButtonImage_GetStyle(name) {
    name := StrLower(Trim(name))
    s := {}

    s.bgColor := "0xFF101820"
    s.accentColor := "0xFF00FF99"
    s.textColor := "0xFFFFFFFF"
    s.valueColor := "0xFF00FF99"
    s.borderColor := "0xFF00FF99"
    s.shadowColor := "0x55000000"
    s.titleSize := 15
    s.valueSize := 34
    s.subtitleSize := 12
    s.border := 2
    s.radius := 14
    s.titleY := 20
    s.valueY := 56
    s.iconW := 76
    s.iconH := 76
    s.iconY := 28
    s.accentStrip := true

    if (name = "minimal") {
        s.bgColor := "0xFF202020"
        s.accentColor := "0xFFFFFFFF"
        s.valueColor := "0xFFFFFFFF"
        s.borderColor := "0xFF555555"
        s.shadowColor := "0x00000000"
        s.border := 1
        s.radius := 8
        s.accentStrip := false
    } else if (name = "resident") {
        s.bgColor := "0xFF090909"
        s.accentColor := "0xFFB8B8B8"
        s.textColor := "0xFFE8E8E8"
        s.valueColor := "0xFFFFD369"
        s.borderColor := "0xFF8F8F8F"
        s.shadowColor := "0x77000000"
        s.titleSize := 14
        s.valueSize := 22
        s.titleY := 90
        s.valueY := 102
        s.valueX := 50
        s.iconY := 18
        s.iconW := 78
        s.iconH := 78
        s.radius := 2
        s.accentStrip := false
    } else if (name = "warning") {
        s.bgColor := "0xFF220707"
        s.accentColor := "0xFFFF3030"
        s.textColor := "0xFFFFFFFF"
        s.valueColor := "0xFFFF3030"
        s.borderColor := "0xFFFF3030"
        s.titleSize := 14
        s.valueSize := 32
        s.accentStrip := true
    } else if (name = "glass") {
        s.bgColor := "0xFF141A22"
        s.accentColor := "0xFF7FDBFF"
        s.valueColor := "0xFF7FDBFF"
        s.borderColor := "0x88FFFFFF"
        s.shadowColor := "0x55000000"
        s.radius := 18
        s.accentStrip := true
    } else if (name = "pokemon") {
        s.bgColor := "0xFF1F2A44"
        s.accentColor := "0xFFFFCB05"
        s.textColor := "0xFFFFFFFF"
        s.valueColor := "0xFFFFCB05"
        s.borderColor := "0xFFFFCB05"
        s.titleSize := 15
        s.valueSize := 30
        s.accentStrip := true
    } else if (name = "dark") {
        s.bgColor := "0xFF050505"
        s.accentColor := "0xFF666666"
        s.textColor := "0xFFE0E0E0"
        s.valueColor := "0xFFFFFFFF"
        s.borderColor := "0xFF333333"
        s.shadowColor := "0x00000000"
        s.border := 1
        s.radius := 10
        s.accentStrip := false
    }

    return s
}

; -----------------------------------------------------------------------------
; Drawing helpers
; -----------------------------------------------------------------------------

LD_DrawProgress(G, value, x, y, w, h, fg, bg) {
    if (value < 0)
        value := 0
    if (value > 100)
        value := 100
    LD_FillRoundedRect(G, x, y, w, h, 3, bg)
    fillW := Floor(w * value / 100)
    if (fillW > 0)
        LD_FillRoundedRect(G, x, y, fillW, h, 3, fg)
}

LD_DrawGlassLayer(G, width, height) {
    LD_FillRoundedRect(G, 9, 9, width - 18, Floor(height / 2), 14, 0x22FFFFFF)
    LD_FillRoundedRect(G, 9, Floor(height / 2), width - 18, Floor(height / 2) - 9, 14, 0x22000000)
}

LD_DrawImageFile(G, path, x, y, w, h) {
    pImg := LD_Gdip_CreateBitmapFromFile(path)
    if (!pImg)
        return false
    LD_Gdip_DrawImage(G, pImg, x, y, w, h)
    LD_Gdip_DisposeImage(pImg)
    return true
}

LD_DrawText(G, text, fontName, size, color, x, y, w, h, align := 1, vAlign := 1, bold := 0) {
    pBrush := LD_Gdip_BrushCreateSolid(color)
    pFamily := LD_Gdip_FontFamilyCreate(fontName)
    if (!pFamily)
        pFamily := LD_Gdip_FontFamilyCreate("Arial")
    fontStyle := bold ? 1 : 0
    pFont := LD_Gdip_FontCreate(pFamily, size, fontStyle)
    pFormat := LD_Gdip_StringFormatCreate()
    LD_Gdip_SetStringFormatAlign(pFormat, align)
    LD_Gdip_SetStringFormatLineAlign(pFormat, vAlign)
    LD_Gdip_DrawString(G, text, pFont, pBrush, x, y, w, h, pFormat)
    LD_Gdip_DeleteStringFormat(pFormat)
    LD_Gdip_DeleteFont(pFont)
    LD_Gdip_DeleteFontFamily(pFamily)
    LD_Gdip_DeleteBrush(pBrush)
}

LD_FillRoundedRect(G, x, y, w, h, r, color) {
    pBrush := LD_Gdip_BrushCreateSolid(color)
    pPath := LD_Gdip_CreateRoundedRectPath(x, y, w, h, r)
    DllCall("gdiplus\GdipFillPath", "UPtr", G, "UPtr", pBrush, "UPtr", pPath)
    LD_Gdip_DeletePath(pPath)
    LD_Gdip_DeleteBrush(pBrush)
}

LD_DrawRoundedRect(G, color, lineWidth, x, y, w, h, r) {
    pPen := LD_Gdip_CreatePen(color, lineWidth)
    pPath := LD_Gdip_CreateRoundedRectPath(x, y, w, h, r)
    DllCall("gdiplus\GdipDrawPath", "UPtr", G, "UPtr", pPen, "UPtr", pPath)
    LD_Gdip_DeletePath(pPath)
    LD_Gdip_DeletePen(pPen)
}

LD_Gdip_CreateRoundedRectPath(x, y, w, h, r) {
    pPath := 0
    DllCall("gdiplus\GdipCreatePath", "Int", 0, "UPtrP", pPath)
    d := r * 2
    DllCall("gdiplus\GdipAddPathArc", "UPtr", pPath, "Float", x, "Float", y, "Float", d, "Float", d, "Float", 180, "Float", 90)
    DllCall("gdiplus\GdipAddPathArc", "UPtr", pPath, "Float", x + w - d, "Float", y, "Float", d, "Float", d, "Float", 270, "Float", 90)
    DllCall("gdiplus\GdipAddPathArc", "UPtr", pPath, "Float", x + w - d, "Float", y + h - d, "Float", d, "Float", d, "Float", 0, "Float", 90)
    DllCall("gdiplus\GdipAddPathArc", "UPtr", pPath, "Float", x, "Float", y + h - d, "Float", d, "Float", d, "Float", 90, "Float", 90)
    DllCall("gdiplus\GdipClosePathFigure", "UPtr", pPath)
    return pPath
}

; -----------------------------------------------------------------------------
; Config helpers
; -----------------------------------------------------------------------------

LD_Cfg(cfg, key, default := "") {
    if (IsObject(cfg) && cfg.HasKey(key))
        return cfg[key]
    return default
}

LD_Color(value) {
    if (value = "")
        return 0
    if value is integer
        return value + 0
    v := Trim(value)
    if (SubStr(v, 1, 1) = "#") {
        hex := SubStr(v, 2)
        if (StrLen(hex) = 6)
            return "0xFF" hex + 0
        if (StrLen(hex) = 8)
            return "0x" hex + 0
    }
    return v + 0
}

; -----------------------------------------------------------------------------
; Minimal GDI+ wrapper
; -----------------------------------------------------------------------------

LD_Gdip_Startup(ByRef pToken) {
    if !DllCall("GetModuleHandle", "Str", "gdiplus", "UPtr")
        DllCall("LoadLibrary", "Str", "gdiplus")
    VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0)
    NumPut(1, si, 0, "UInt")
    return DllCall("gdiplus\GdiplusStartup", "UPtrP", pToken, "UPtr", &si, "UPtr", 0) = 0
}

LD_Gdip_Shutdown(pToken) {
    return DllCall("gdiplus\GdiplusShutdown", "UPtr", pToken)
}

LD_Gdip_CreateBitmap(w, h) {
    pBitmap := 0
    DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", w, "Int", h, "Int", 0, "Int", 0x26200A, "UPtr", 0, "UPtrP", pBitmap)
    return pBitmap
}

LD_Gdip_CreateBitmapFromFile(path) {
    pBitmap := 0
    DllCall("gdiplus\GdipCreateBitmapFromFile", "WStr", path, "UPtrP", pBitmap)
    return pBitmap
}

LD_Gdip_GraphicsFromImage(pBitmap) {
    G := 0
    DllCall("gdiplus\GdipGetImageGraphicsContext", "UPtr", pBitmap, "UPtrP", G)
    return G
}

LD_Gdip_GraphicsClear(G, color) {
    return DllCall("gdiplus\GdipGraphicsClear", "UPtr", G, "UInt", color)
}

LD_Gdip_SetSmoothingMode(G, mode) {
    return DllCall("gdiplus\GdipSetSmoothingMode", "UPtr", G, "Int", mode)
}

LD_Gdip_SetInterpolationMode(G, mode) {
    return DllCall("gdiplus\GdipSetInterpolationMode", "UPtr", G, "Int", mode)
}

LD_Gdip_BrushCreateSolid(color) {
    pBrush := 0
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", color, "UPtrP", pBrush)
    return pBrush
}

LD_Gdip_CreatePen(color, width := 1) {
    pPen := 0
    DllCall("gdiplus\GdipCreatePen1", "UInt", color, "Float", width, "Int", 2, "UPtrP", pPen)
    return pPen
}

LD_Gdip_FontFamilyCreate(name) {
    pFamily := 0
    DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", name, "UPtr", 0, "UPtrP", pFamily)
    return pFamily
}

LD_Gdip_FontCreate(pFamily, size, style := 0) {
    pFont := 0
    DllCall("gdiplus\GdipCreateFont", "UPtr", pFamily, "Float", size, "Int", style, "Int", 2, "UPtrP", pFont)
    return pFont
}

LD_Gdip_StringFormatCreate() {
    pFormat := 0
    DllCall("gdiplus\GdipCreateStringFormat", "Int", 0, "Int", 0, "UPtrP", pFormat)
    return pFormat
}

LD_Gdip_SetStringFormatAlign(pFormat, align) {
    return DllCall("gdiplus\GdipSetStringFormatAlign", "UPtr", pFormat, "Int", align)
}

LD_Gdip_SetStringFormatLineAlign(pFormat, align) {
    return DllCall("gdiplus\GdipSetStringFormatLineAlign", "UPtr", pFormat, "Int", align)
}

LD_Gdip_DrawString(G, text, pFont, pBrush, x, y, w, h, pFormat) {
    VarSetCapacity(rect, 16, 0)
    NumPut(x, rect, 0, "Float")
    NumPut(y, rect, 4, "Float")
    NumPut(w, rect, 8, "Float")
    NumPut(h, rect, 12, "Float")
    return DllCall("gdiplus\GdipDrawString", "UPtr", G, "WStr", text, "Int", -1, "UPtr", pFont, "UPtr", &rect, "UPtr", pFormat, "UPtr", pBrush)
}

LD_Gdip_DrawImage(G, pBitmap, x, y, w, h) {
    return DllCall("gdiplus\GdipDrawImageRectI", "UPtr", G, "UPtr", pBitmap, "Int", x, "Int", y, "Int", w, "Int", h)
}

LD_Gdip_SaveBitmapToFile(pBitmap, path) {
    VarSetCapacity(clsid, 16, 0)
    ; PNG encoder CLSID: {557CF406-1A04-11D3-9A73-0000F81EF32E}
    DllCall("ole32\CLSIDFromString", "WStr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "UPtr", &clsid)
    return DllCall("gdiplus\GdipSaveImageToFile", "UPtr", pBitmap, "WStr", path, "UPtr", &clsid, "UPtr", 0) = 0
}

LD_Gdip_DeleteBrush(pBrush) {
    return DllCall("gdiplus\GdipDeleteBrush", "UPtr", pBrush)
}

LD_Gdip_DeletePen(pPen) {
    return DllCall("gdiplus\GdipDeletePen", "UPtr", pPen)
}

LD_Gdip_DeletePath(pPath) {
    return DllCall("gdiplus\GdipDeletePath", "UPtr", pPath)
}

LD_Gdip_DeleteFont(pFont) {
    return DllCall("gdiplus\GdipDeleteFont", "UPtr", pFont)
}

LD_Gdip_DeleteFontFamily(pFamily) {
    return DllCall("gdiplus\GdipDeleteFontFamily", "UPtr", pFamily)
}

LD_Gdip_DeleteStringFormat(pFormat) {
    return DllCall("gdiplus\GdipDeleteStringFormat", "UPtr", pFormat)
}

LD_Gdip_DeleteGraphics(G) {
    return DllCall("gdiplus\GdipDeleteGraphics", "UPtr", G)
}

LD_Gdip_DisposeImage(pBitmap) {
    return DllCall("gdiplus\GdipDisposeImage", "UPtr", pBitmap)
}

StrLower(str) {
    StringLower, str, str
    return str
}