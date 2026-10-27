class Socket
{
  static __eventMsg := 0x9987
  
  __New(s=-1)
  {
    static init
    if (!init)
    {
      DllCall("LoadLibrary", "str", "ws2_32", "ptr")
      VarSetCapacity(wsadata, 394+A_PtrSize)
      DllCall("ws2_32\WSAStartup", "ushort", 0x0000, "ptr", &wsadata)
      DllCall("ws2_32\WSAStartup", "ushort", NumGet(wsadata, 2, "ushort"), "ptr", &wsadata)
      OnMessage(Socket.__eventMsg, "SocketEventProc")
      init := 1
    }
    this.socket := s
  }
  __Delete()
  {
    this.disconnect()
  }
  __Get(k, v)
  {
    if (k="size")
      return this.msgSize()
  }
  connect(host, port, timeoutMs="")
  {
    if (this.socket!=-1)
      return 0
    if (!(faddr := next := this.__getAddrInfo(host, port)))
    {
      this.errorNM := "Could not connect to the server " host ":" port " - Enabling Offline Mode"
      return 0
    }
    while (next)
    {
      sockaddrlen := NumGet(next+0, 16, "uint")
      sockaddr := NumGet(next+0, 16+(2*A_PtrSize), "ptr")
      if ((this.socket := DllCall("ws2_32\socket", "int", NumGet(next+0, 4, "int"), "int", this.__socketType, "int", this.__protocolId, "ptr"))!=-1)
      {
        this.errorNM := ""
        if ((timeoutMs != "" && this.__connectWithTimeout(sockaddr, sockaddrlen, timeoutMs)) || (timeoutMs = "" && (r := DllCall("ws2_32\WSAConnect", "ptr", this.socket, "ptr", sockaddr, "uint", sockaddrlen, "ptr", 0, "ptr", 0, "ptr", 0, "ptr", 0, "int"))=0))
        {
          this.errorNM := ""
          DllCall("ws2_32\freeaddrinfo", "ptr", faddr)
          return Socket.__eventProcRegister(this, 0x21)
        }
        if(this.errorNM = "")
          this.errorNM := "Could not connect to the server " host ":" port " - Enabling Offline Mode"
        this.disconnect()
      }
      next := NumGet(next+0, 16+(3*A_PtrSize), "ptr")
    }
    this.lastError := DllCall("ws2_32\WSAGetLastError")
    return 0
  }
  __connectWithTimeout(sockaddr, sockaddrlen, timeoutMs)
  {
    VarSetCapacity(nonblocking, 4, 0)
    NumPut(1, nonblocking, 0, "uint")
    DllCall("ws2_32\ioctlsocket", "ptr", this.socket, "uint", 0x8004667E, "ptr", &nonblocking)
    if (DllCall("ws2_32\WSAConnect", "ptr", this.socket, "ptr", sockaddr, "uint", sockaddrlen, "ptr", 0, "ptr", 0, "ptr", 0, "ptr", 0, "int")=0)
      return 1
    lastError := DllCall("ws2_32\WSAGetLastError")
    if (lastError != 10035 && lastError != 10036)
    {
      this.lastError := lastError
      return 0
    }

    fdOffset := (A_PtrSize=8) ? 8 : 4
    VarSetCapacity(writefds, fdOffset + A_PtrSize, 0)
    VarSetCapacity(exceptfds, fdOffset + A_PtrSize, 0)
    NumPut(1, writefds, 0, "uint")
    NumPut(this.socket, writefds, fdOffset, "ptr")
    NumPut(1, exceptfds, 0, "uint")
    NumPut(this.socket, exceptfds, fdOffset, "ptr")
    VarSetCapacity(timeout, 8, 0)
    NumPut(Floor(timeoutMs / 1000), timeout, 0, "long")
    NumPut(Mod(timeoutMs, 1000) * 1000, timeout, 4, "long")
    ready := DllCall("ws2_32\select", "int", 0, "ptr", 0, "ptr", &writefds, "ptr", &exceptfds, "ptr", &timeout, "int")
    if(ready <= 0)
    {
      this.lastError := (ready = 0) ? 10060 : DllCall("ws2_32\WSAGetLastError")
      this.errorNM := "Connection timed out"
      return 0
    }

    VarSetCapacity(sockError, 4, 0)
    optLen := 4
    if(DllCall("ws2_32\getsockopt", "ptr", this.socket, "int", 0xFFFF, "int", 0x1007, "ptr", &sockError, "int*", optLen, "int") != 0)
    {
      this.lastError := DllCall("ws2_32\WSAGetLastError")
      return 0
    }
    sockError := NumGet(sockError, 0, "int")
    if(sockError != 0)
    {
      this.lastError := sockError
      return 0
    }
    return 1
  }
  bind(host, port)
  {
    if ((this.socket!=-1) || (!(faddr := next := this.__getAddrInfo(host, port))))
      return 0
    while (next)
    {
      sockaddrlen := NumGet(next+0, 16, "uint")
      sockaddr := NumGet(next+0, 16+(2*A_PtrSize), "ptr")
      if ((this.socket := DllCall("ws2_32\socket", "int", NumGet(next+0, 4, "int"), "int", this.__socketType, "int", this.__protocolId, "ptr"))!=-1)
      {
        if (DllCall("ws2_32\bind", "ptr", this.socket, "ptr", sockaddr, "uint", sockaddrlen, "int")=0)
        {
          DllCall("ws2_32\freeaddrinfo", "ptr", faddr)
          return Socket.__eventProcRegister(this, 0x29)
        }
        this.disconnect()
      }
      next := NumGet(next+0, 16+(3*A_PtrSize), "ptr")
    }
    this.lastError := DllCall("ws2_32\WSAGetLastError")
    return 0
  }
  listen(backlog=32)
  {
    return (DllCall("ws2_32\listen", "ptr", this.socket, "int", backlog)=0) ? 1 : 0
  }
  accept()
  {
    if ((s := DllCall("ws2_32\accept", "ptr", this.socket, "ptr", 0, "int", 0, "ptr"))!=-1)
    {
      newsock := new Socket(s)
      newsock.__protocolId := this.__protocolId
      newsock.__socketType := this.__socketType
      Socket.__eventProcRegister(newsock, 0x21)
      return newsock
    }
    return 0
  }
  disconnect()
  {
    Socket.__eventProcUnregister(this)
    DllCall("ws2_32\closesocket", "ptr", this.socket, "int")
    this.socket := -1
    return 1
  }
  msgSize()
  {
    VarSetCapacity(argp, 4, 0)
    if (DllCall("ws2_32\ioctlsocket", "ptr", this.socket, "uint", 0x4004667F, "ptr", &argp)!=0)
      return 0
    return NumGet(argp, 0, "int")
  }
  send(addr, length)
  {
    if ((r := DllCall("ws2_32\send", "ptr", this.socket, "ptr", addr, "int", length, "int", 0, "int"))<=0)
      return 0
    return r
  }
  sendText(msg, encoding="UTF-8")
  {
    VarSetCapacity(buffer, length := (StrPut(msg, encoding)*(((encoding="utf-16")||(encoding="cp1200")) ? 2 : 1)))
    StrPut(msg, &buffer, encoding)
    return this.send(&buffer, length)
  }
  recv(byref buffer, wait=1)
  {
    while ((wait) && ((length := this.msgSize())=0))
      sleep, 100
    if (length)
    {
      VarSetCapacity(buffer, length)
      if ((r := DllCall("ws2_32\recv", "ptr", this.socket, "ptr", &buffer, "int", length, "int", 0))<=0)
        return 0
      return r
    }
    return 0
  }
  recvText(wait=1, encoding="UTF-8")
  {
    if (length := this.recv(buffer, wait))
      return StrGet(&buffer, length, encoding)
    return
  }
  __getAddrInfo(host, port)
  {
    a := ["127.0.0.1", "0.0.0.0", "255.255.255.255", "::1", "::", "FF00::"]
    conv := {localhost:a[1], addr_loopback:a[1], inaddr_loopback:a[1], addr_any:a[2], inaddr_any:a[2], addr_broadcast:a[3]
    , inaddr_broadcast:a[3], addr_none:a[3], inaddr_none:a[3], localhost6:a[4], addr_loopback6:a[4], inaddr_loopback6:a[4]
    , addr_any6:a[5], inaddr_any:a[5], addr_broadcast6:a[6], inaddr_broadcast6:a[6], addr_none6:a[6], inaddr_none6:a[6]}
    if (conv[host])
      host := conv[host]
    VarSetCapacity(hints, 16+(4*A_PtrSize), 0)
    NumPut(this.__socketType, hints, 8, "int")
    NumPut(this.__protocolId, hints, 12, "int")
    if ((r := DllCall("ws2_32\getaddrinfo", "astr", host, "astr", port, "ptr", &hints, "ptr*", next))!=0)
    {
      this.lastError := DllCall("ws2_32\WSAGetLastError")
      return 0
    }
    return next
  }
  __eventProcRegister(obj, msg)
  {
    a := SocketEventProc(0, 0, "register", 0)
    a[obj.socket] := obj
    return (DllCall("ws2_32\WSAAsyncSelect", "ptr", obj.socket, "ptr", A_ScriptHwnd, "uint", Socket.__eventMsg, "uint", msg)=0) ? 1 : 0
  }
  __eventProcUnregister(obj)
  {
    a := SocketEventProc(0, 0, "register", 0)
    a.remove(obj.socket)
    return (DllCall("ws2_32\WSAAsyncSelect", "ptr", obj.socket, "ptr", A_ScriptHwnd, "uint", 0, "uint", 0)=0) ? 1 : 0
  }
}
SocketEventProc(wParam, lParam, msg, hwnd)
{
  global Socket
  static a := []
  Critical
  if (msg="register")
    return a
  if (msg=Socket.__eventMsg)
  {
    if (!isobject(a[wParam]))
      return 0
    if ((lParam & 0xFFFF) = 1)
      return a[wParam].onRecv(a[wParam])
    else if ((lParam & 0xFFFF) = 8)
      return a[wParam].onAccept(a[wParam])
    else if ((lParam & 0xFFFF) = 32)
    {
      a[wParam].socket := -1
      return a[wParam].onDisconnect(a[wParam])
    }
    return 0
  }
  return 0
}

class SocketTCP extends Socket
{
  static __protocolId := 6 ;IPPROTO_TCP
  static __socketType := 1 ;SOCK_STREAM
}

class SocketUDP extends Socket
{
  static __protocolId := 17 ;IPPROTO_UDP
  static __socketType := 2 ;SOCK_DGRAM

  enableBroadcast()
  {
    VarSetCapacity(optval, 4, 0)
    NumPut(1, optval, 0, "uint")
    if (DllCall("ws2_32\setsockopt", "ptr", this.socket, "int", 0xFFFF, "int", 0x0020, "ptr", &optval, "int", 4)=0)
      return 1
    return 0
  }
  disableBroadcast()
  {
    VarSetCapacity(optval, 4, 0)
    if (DllCall("ws2_32\setsockopt", "ptr", this.socket, "int", 0xFFFF, "int", 0x0020, "ptr", &optval, "int", 4)=0)
      return 1
    return 0
  }
}
