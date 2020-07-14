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
WinGetTitle, class, A
MsgBox, The active window's class is "%class%".
return

#a::
WinActivate, Discord
return

; #8::WinActivate, Spotify

; #1::WinActivate, Visual Studio Code

#d::
Send, !+d
return

#Hotstring EndChars -()[]{}:;'"/\,.?!t

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
