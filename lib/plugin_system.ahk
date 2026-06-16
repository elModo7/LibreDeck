BuildMenusFromPlugin(plugin) {
    global LD_ScriptGeneratorMenus

    if (!IsObject(LD_ScriptGeneratorMenus))
        LD_ScriptGeneratorMenus := {}

    for _, menuDef in plugin.menus
        if (menuDef.name = "scriptGenerator")
            LD_ScriptGeneratorMenus[menuDef.name] := true

    for _, reg in plugin.register_in
        if (reg.menu = "scriptGenerator" && reg.submenu != "")
            LD_ScriptGeneratorMenus[reg.submenu] := true

    for _, menuDef in plugin.menus
        BuildSubmenu_(menuDef)

    for _, reg in plugin.register_in
        RegisterSubmenu_(reg)
}

BuildSubmenu_(menuDef, scriptGeneratorChild := false) {
    global LD_ScriptGeneratorMenus, LD_ScriptGeneratorMenuHandlers

    if (!IsObject(LD_ScriptGeneratorMenuHandlers))
        LD_ScriptGeneratorMenuHandlers := {}

    menuName := menuDef.name
    if (!menuName) {
        MsgBox, 16, Error, Missing "name" in a menu.
        return
    }
    wrapScriptGeneratorCommands := scriptGeneratorChild || LD_ScriptGeneratorMenus[menuName]

    try Menu, %menuName%, Delete

    for _, item in menuDef.items
    {
        type := item.type
        if (type = "command") {
            labelText := item.label
            handler   := item.handler
            if (!labelText) {
                MsgBox, 16, Error, Missing "label" in an item from %menuName%.
                continue
            }
            if (wrapScriptGeneratorCommands) {
                LD_ScriptGeneratorMenuHandlers[menuName "|" labelText] := handler
                Menu, %menuName%, Add, %labelText%, ScriptGeneratorMenuCommand
            } else {
                Menu, %menuName%, Add, %labelText%, %handler%
            }
            iconDef := GetItemIconOrDefault(menuDef, item)
            ApplyIcon(menuName, labelText, iconDef)
        }
        else if (type = "separator") {
            Menu, %menuName%, Add
        }
        else if (type = "submenu") {
            if IsObject(item.submenu) {
                BuildSubmenu_(item.submenu, wrapScriptGeneratorCommands)
                labelText := item.label ? item.label : item.submenu.name
                if (labelText) {
                    Menu, %menuName%, Add, %labelText%, % ":" item.submenu.name
                    iconPath := item.icon ? item.icon : item.submenu.icon_default
                    if (iconPath)
                        Menu, %menuName%, Icon, %labelText%, %iconPath%
                }
            }
        }
        else {
            ; Ignore unknown type
        }
    }
}

RegisterSubmenu_(reg) {
    parentMenu := reg.menu
    showLabel  := reg.label
    subName    := reg.submenu
    if (!parentMenu || !showLabel || !subName) {
        MsgBox, 16, Error, register_in mal formado. Se requiere "menu", "label" y "submenu".
        return
    }

    Menu, %parentMenu%, Add, %showLabel%, :%subName%
    ApplyIcon(parentMenu, showLabel, reg.icon)
}

ApplyIcon(menuName, itemLabel, iconDef) {
    if (!iconDef)
        return
    if IsObject(iconDef) {
        file := iconDef.file
        idx  := iconDef.index
        if (file = "")
            return
        if (idx = "")
            idx := 0
        Menu, %menuName%, Icon, %itemLabel%, %file%, %idx%
    } else {
        Menu, %menuName%, Icon, %itemLabel%, %iconDef%
    }
}

GetItemIconOrDefault(menuDef, item) {
    return item.HasKey("icon") ? item.icon
         : (menuDef.HasKey("icon_default") ? menuDef.icon_default : "")
}

SortPluginsByPriority(ByRef arr) {
    ; simple stable-ish bubble sort (N is tiny here)
    n := arr.MaxIndex()
    if (n <= 1)
        return
    loop % n-1 {
        swapped := false
        loop % n-A_Index {
            i := A_Index
            j := i+1
            if (ComparePlugins(arr[i], arr[j]) > 0) {
                tmp := arr[i], arr[i] := arr[j], arr[j] := tmp
                swapped := true
            }
        }
        if (!swapped)
            break
    }
}

ComparePlugins(a, b) {
    pa := GetPrioritySafe(a)
    pb := GetPrioritySafe(b)
    if (pa < pb)
        return -1
    if (pa > pb)
        return 1

    an := a.HasKey("plugin") ? a.plugin : ""
    bn := b.HasKey("plugin") ? b.plugin : ""
    StringLower, an, an
    StringLower, bn, bn
    if (an < bn)
        return -1
    if (an > bn)
        return 1
    return 0
}

GetPrioritySafe(p) {
    pr := (IsObject(p) && p.HasKey("priority")) ? p.priority+0 : 1000  ; default 1000
    if (pr < 0)
        pr := 0
    else if (pr > 1000)
        pr := 1000
    return pr
}
