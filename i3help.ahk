#SingleInstance, force
SetTitleMatchMode, 2

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

#x::
  WinGet, name, ProcessName, A
  WinGetClass, class, A
  MsgBox, The active window's name is "%name%". Class: "%class%"
return

#a::
  WinActivate, Discord
return

#c::WinActivate, Visual Studio Code

#d::
  Send, !+d
return

#Hotstring EndChars -()[]{}\,

; https://web.archive.org/web/20100526232547/http://www.mknoedel.de:80/lexikon_ASCII-Code.htm

:?OC:ae::
  Send {ASC 0228}
return

:?OC:oe::
  Send {ASC 0246}
return

:?OC:ue::
  Send {ASC 0252}
return

:?OC:AE::
  Send {ASC 0196}
return

:?OC:OE::
  Send {ASC 0214}
return

:?OC:UE::
  Send {ASC 0220}
return

:?O:ss::
  Send {ASC 0223}
return

PrintScreen::
  Send #+s
return

#Enter::
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

; TODO implement opening of profiles when it goes stable
