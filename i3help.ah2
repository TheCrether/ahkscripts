#Include <Base>
#Include "./reloadOnEnvChange.ahk"
SetTitleMatchMode(2)
setupReloadOnEnvChange()

SetIcon(".\icons\i3help.ico")

<^>!p::
^!p::
{
	Send("{Media_Play_Pause}")
}

<^>!Right::
^!Right::
{
	Send("{Media_Next}")
}

<^>!Left::
^!Left::
{
	Send("{Media_Prev}")
}

#+q::
#q::
{
	Send("!{F4}")
}

#+p:: {
	WinActivate("ahk_class Shell_TrayWnd")
	Send("!{F4}")
}

#x::
{
	if (A_AhkPath != "") {
		SplitPath(A_AhkPath, , &ahk_dir)
		ahk_dir := StrReplace(ahk_dir, "\v2", "")
		Run(ahk_dir . "\UX\WindowSpy.ahk")
	}
}

tryToActivate(title) {
	try {
		WinActivate(title)
	}
}

#a:: tryToActivate("Discord")

#s:: tryToActivate("ahk_exe Spotify.exe")

PrintScreen:: Send("#+s")

#Enter::
^!t::
{
	; processName := "WindowsTerminal.exe"
	Run("wt") ; create new tab in terminal, if no terminal is opened yet, open one
}

#t::
{
	WinSetAlwaysOnTop(-1, "A")
	ExStyle := WinGetExStyle("A")
	id := WinGetID("A")
	if (ExStyle & 0x8) { ; 0x8 is WS_EX_TOPMOST.
		; drawDot(id)
	} else {
		OutputDebug("elses")
		; Gui, Draw%id%:Destroy
		; WinClose, "Draw%id%"
	}
}

!+1::
{
	title := WinGetTitle("A")
	WinGetPos(&x, &y, &w, &h)
	WinMove(x, y, 1000, 550, "A")
	WinSetAlwaysOnTop(1)
}