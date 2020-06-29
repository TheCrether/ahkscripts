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

#9::
WinActivate, Discord
return

; #8::WinActivate, Spotify

; #1::WinActivate, Visual Studio Code

#d::
Send, !+d
return