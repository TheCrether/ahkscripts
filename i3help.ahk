#SingleInstance, force
SetTitleMatchMode, 2

<^>!p::
^!p::
Send {Media_Play_Pause}

<^>!Right::
^!Right::
Send {Media_Next}

<^>!Left::
^!Left::
Send {Media_Prev}

#+q::Send !{F4}

#x::
WinGetTitle, class, A
MsgBox, The active window's class is "%class%".

#9::WinActivate, Discord

#8::WinActivate, Spotify

#1::WinActivate, Visual Studio Code

#d::Send, !+d