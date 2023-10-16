;@Ahk2Exe-SetMainIcon .\icons\i3help.ico
;@Ahk2Exe-SetDescription i3help provides some useful shortcuts

#Include <Base>
#Include <reload_env_on_change>
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
	wtPath := RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\wt.exe", "Path", "")
	if wtPath != "" {
		path := EnvGet("Path")
		path := wtPath . ";" . path
		EnvSet("Path", path)
	}
	; processName := "WindowsTerminal.exe"
	Run("wt") ; create new tab in terminal, if no terminal is opened yet, open one
	WinWait("ahk_exe WindowsTerminal.exe")
	Sleep(400)
	tryToActivate("ahk_exe WindowsTerminal.exe")
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

#Include <WinHook>

FortiTray(Win_Hwnd, Win_Title, Win_Class, Win_Exe, Win_Event) {
	; MsgBox(Format("{1}`n{2}`n{3}`n{4}`n{5}", Win_Hwnd, Win_Title, Win_Class, Win_Exe, Win_Event))
	Sleep(100)
	tryToActivate("ahk_id " . Win_Hwnd)
}

WinHook.Shell.Add(FortiTray, "Security Alert", , "FortiTray.exe", 1)