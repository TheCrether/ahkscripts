#SingleInstance, force
SetTitleMatchMode, 2

; Always use folder where the script is
SetWorkingDir %A_ScriptDir%
Menu, Tray, Icon, .\\icons\i3.ico

<^>!p::
^!p::
  Send {Media_Play_Pause}
return

<^>!Right::
^!Right::
  Send {Media_Next}
return

<^>!Left::
^!Left::
  Send {Media_Prev}
return

#+q::
  Send !{F4}
return

#+p::
  WinActivate, ahk_class Shell_TrayWnd
  Send !{F4}
return

#NoTrayIcon
#x::
  if (A_AhkPath != "") {
    SplitPath, A_AhkPath,, ahk_dir
    run %ahk_dir%\WindowSpy.ahk
  }
return

#a::
  WinActivate, Discord
return

#s::
  currMode := A_TitleMatchMode
  SetTitleMatchMode RegEx
  WinActivate, .+ ahk_exe Spotify.exe
  SetTitleMatchMode %currMode%
return

#c::WinActivate, Visual Studio Code

PrintScreen::
  Send #+s
return

#Enter::
  ; TODO implement opening of profiles when it goes stable
  processName := "WindowsTerminal.exe"
  if (WinExist("ahk_exe " . processName)){
    WinActivate
    Send ^+t
  } else {
    Run, wt
    Sleep 100
    if (WinExist("ahk_exe " . processName)) {
      WinActivate
    }
  }
return

drawDot(id) {
  OutputDebug, AAAA
  WinGetPos, WinX, WinY, WinW, WinH, A ; get the stats of the active window
  Gui, Draw%id%:New, +ToolWindow +AlwaysOnTop -SysMenu -Caption +Border
  Gui, Color, cFFF0F0

  ; variables
  DrawW := 10
  DrawH := 10
  DrawX := (WinX - 1)
  DrawY := (WinY - 1)

  ; show the gui
  Gui, Draw%id%:Show, NoActivate W%DrawW% H%DrawH% X%DrawX% Y%DrawY%, "Draw%id%"
}

EVENT_OBJECT_LOCATIONCHANGE := 0x800B

#t::
  global EVENT_OBJECT_LOCATIONCHANGE

  WinSet, AlwaysOnTop, TOGGLE, A
  WinGet, ExStyle, ExStyle, A
  WinGet, id, ID, A
  if (ExStyle & 0x8) { ; 0x8 is WS_EX_TOPMOST.
    ; drawDot(id)
  } else {
    OutputDebug, elses
    ; Gui, Draw%id%:Destroy
    ; WinClose, "Draw%id%"
  }
return

!+1::
  WinGetTitle, title, A
  WinGetPos, x, y, w, h
  WinMove, A,, x, y, 1000, 550
  WinSet, AlwaysOnTop, On
return

RestartExplorer( WaitSecs:=10 ) { ; requires OS Vista+    ; v2.10 by SKAN on CSC7/D39N
  Local PID, Explorer, ID:=WinExist("ahk_class Progman")  ; @ tiny.cc/restartexplorer2
  WinGet, PID, PID
  WinGet, Explorer, ProcessPath
  PostMessage, 0x5B4, 0, 0,, ahk_class Shell_TrayWnd ; WM_USER+436
  Process, WaitClose, %PID%, % ( PID ? WaitSecs : (WaitSecs:=0) )
  If (PID && !Errorlevel)
    Run, %Explorer%
  WinWait, ahk_class Progman,, %WaitSecs%
  Return (WinExist()!=ID)
}

#+r::
  RestartExplorer(10)
return
