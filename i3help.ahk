#SingleInstance, force
SetTitleMatchMode, 2

; Always use folder where the script is
SetWorkingDir %A_ScriptDir%
Menu, Tray, Icon, .\\icons\i3help.ico

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
#q::
	Send !{F4}
return

#+p::
	WinActivate, ahk_class Shell_TrayWnd
	Send !{F4}
return

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

PrintScreen::
	Send #+s
return

#Enter::
^!t::
	processName := "WindowsTerminal.exe"
	Run, wt --window 0 nt ; create new tab in terminal, if no terminal is opened yet, open one
return

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
