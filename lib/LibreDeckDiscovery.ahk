/*
    LibreDeckDiscovery.ahk
    AutoHotkey v1
*/

LD_StartWinsock() {
    global LD_WSAData
    VarSetCapacity(LD_WSAData, 512, 0)
    return DllCall("Ws2_32\WSAStartup", "UShort", 0x0202, "Ptr", &LD_WSAData, "Int") = 0
}

LD_CreateUdpSocket() {
    return DllCall("Ws2_32\socket", "Int", 2, "Int", 2, "Int", 17, "Ptr")
}

LD_Bind(sock, port, ip := "0.0.0.0") {
    VarSetCapacity(addr, 16, 0)
    NumPut(2, addr, 0, "UShort")
    NumPut(LD_htons(port), addr, 2, "UShort")

    if (ip = "" || ip = "0.0.0.0")
        ipValue := 0
    else
        ipValue := DllCall("Ws2_32\inet_addr", "AStr", ip, "UInt")

    NumPut(ipValue, addr, 4, "UInt")
    return DllCall("Ws2_32\bind", "Ptr", sock, "Ptr", &addr, "Int", 16, "Int") = 0
}

LD_SetBroadcast(sock, enabled := true) {
    value := enabled ? 1 : 0
    return DllCall("Ws2_32\setsockopt", "Ptr", sock, "Int", 0xFFFF, "Int", 0x20, "IntP", value, "Int", 4, "Int") = 0
}

LD_RegisterAsync(sock, msg, events) {
    return DllCall("Ws2_32\WSAAsyncSelect", "Ptr", sock, "Ptr", A_ScriptHwnd, "UInt", msg, "Int", events, "Int") = 0
}

LD_UnregisterAsync(sock, msg) {
    return DllCall("Ws2_32\WSAAsyncSelect", "Ptr", sock, "Ptr", A_ScriptHwnd, "UInt", msg, "Int", 0, "Int") = 0
}

LD_SendToIP(sock, text, ip, port) {
    VarSetCapacity(addr, 16, 0)
    NumPut(2, addr, 0, "UShort")
    NumPut(LD_htons(port), addr, 2, "UShort")
    ipValue := DllCall("Ws2_32\inet_addr", "AStr", ip, "UInt")
    NumPut(ipValue, addr, 4, "UInt")
    return LD_SendToAddr(sock, text, addr)
}

LD_SendToAddr(sock, text, ByRef addr) {
    bytes := StrPut(text, "UTF-8") - 1
    VarSetCapacity(buffer, bytes + 1, 0)
    StrPut(text, &buffer, bytes + 1, "UTF-8")
    return DllCall("Ws2_32\sendto", "Ptr", sock, "Ptr", &buffer, "Int", bytes, "Int", 0, "Ptr", &addr, "Int", 16, "Int")
}

LD_RecvOne(sock, ByRef text, ByRef ip, ByRef port, ByRef addr) {
    VarSetCapacity(buffer, 2048, 0)
    VarSetCapacity(addr, 16, 0)
    addrLen := 16
    received := DllCall("Ws2_32\recvfrom", "Ptr", sock, "Ptr", &buffer, "Int", 2047, "Int", 0, "Ptr", &addr, "IntP", addrLen, "Int")

    if (received = -1)
        return -1

    text := StrGet(&buffer, received, "UTF-8")
    ipValue := NumGet(addr, 4, "UInt")
    ip := DllCall("Ws2_32\inet_ntoa", "UInt", ipValue, "AStr")
    netPort := NumGet(addr, 2, "UShort")
    port := LD_ntohs(netPort)
    return received
}

LD_CloseSocket(sock) {
    return DllCall("Ws2_32\closesocket", "Ptr", sock, "Int")
}

LD_GetLastError() {
    return DllCall("Ws2_32\WSAGetLastError", "Int")
}

LD_AsyncEvent(lParam) {
    return lParam & 0xFFFF
}

LD_AsyncError(lParam) {
    return (lParam >> 16) & 0xFFFF
}

LD_htons(value) {
    return DllCall("Ws2_32\htons", "UShort", value, "UShort")
}

LD_ntohs(value) {
    return DllCall("Ws2_32\ntohs", "UShort", value, "UShort")
}

LD_GetField(message, fieldName) {
    parts := StrSplit(message, "|")
    for index, part in parts {
        eqPos := InStr(part, "=")
        if (!eqPos)
            continue
        key := SubStr(part, 1, eqPos - 1)
        value := SubStr(part, eqPos + 1)
        if (key = fieldName)
            return value
    }
    return ""
}
