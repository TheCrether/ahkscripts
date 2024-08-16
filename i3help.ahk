;@Ahk2Exe-SetMainIcon .\icons\i3help.ico
;@Ahk2Exe-SetDescription i3help provides some useful shortcuts

#Include <Base>
#Include <reload_env_on_change>
#Include <ImagePut>
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
	ComObject("Shell.Application").ShutdownWindows
}

#x:: {
	if (A_AhkPath != "") {
		SplitPath(A_AhkPath, &_, &ahk_dir)
		ahk_dir := StrReplace(ahk_dir, "\v2", "")
		Run(ahk_dir . "\UX\WindowSpy.ahk")
	}
}

#+x:: {
	Run(A_ScriptDir . "\UX\search-windows.ahk")
}

#a:: tryActivate(".* - Discord ahk_class Chrome_WidgetWin_1 ahk_exe Discord.exe", true, true)

#s:: tryActivate("ahk_class Chrome_WidgetWin_1 ahk_exe Spotify.exe", false, true)

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
	tryActivate("ahk_exe WindowsTerminal.exe")
}

#t:: {
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

!+1:: {
	; get the dimensions of the monitor
	GetMonitorOfWindow("A", &n, &left, &top, &right, &bottom)
	monHeight := bottom - top

	; Get current window's dimension
	WinGetPos(&x, &y, &w, &h, "A")

	; calculate the new height and base the width on the ratio
	ratio := w / h
	newWinHeight := Integer(monHeight * 0.38) ; make the window around 38% of the height
	newWinWidth := Integer(newWinHeight * ratio)

	; also calculate the position
	newX := right - newWinWidth - 25
	newY := bottom - newWinHeight - 25

	; resize the window
	WinMove(newX, newY, newWinWidth, newWinHeight, "A")
	WinSetAlwaysOnTop(1, "A")
}

#+a:: {
	x := -1, y := -1
	beforeCoordMode := CoordMode("Mouse", "Screen")
	if IsWindows11 {
		primary := MonitorGetPrimary()
		MonitorGet(primary, &_, &_, &x, &y)
		y -= 10
		x -= 20
	} else {
		winX := -1, winY := -1
		WinGetPos(&winX, &winY, &_, &_, "ahk_class Shell_TrayWnd")
		ControlGetPos(&x, &y, &_, &_, "TrayButton2", "ahk_class Shell_TrayWnd")
		x += winX + 5
		y += winY + 5
	}
	Click(x . " " . y)
	CoordMode("Mouse", beforeCoordMode)
	; ControlClick("TrayButton2", "ahk_class Shell_TrayWnd")
}

#m:: {
	; check if window was already minimized
	style := WinGetStyle("A")
	if style & 0x20000000 {
		WinActivate("A")
	} else {
		WinMinimize("A")
	}
}

#Include <ExplorerUtils>
setupReloadPaths(A_ScriptDir . '\Lib\ExplorerUtils.ahk')

; better check if an image is in the clipboard
isImageInClipboard := false
inClipboard := 0
ClipboardChanged(ct) {
	global isImageInClipboard, inClipboard
	inClipboard := ct
	isImageInClipboard := ct == 2
}
OnClipboardChange(ClipboardChanged)

#HotIf WinActive('ahk_exe explorer.exe')
$^v:: {
	if not isImageInClipboard {
		Send("^v")
		return
	}

	try {
		ImagePutExplorer(ClipboardAll)
	} catch {
		Send("^v")
	}
}

$^+c:: {
	; get paths of selected items without quotes
	items := ExUtils.SelectedItems()
	str := ""
	if items.Length == 0 {
		str := ExUtils.GetCurrentPath()
	}
	for item in items {
		str .= (str ? '`n' : '') . item.Path
	}
	A_Clipboard := str
	ToolTip("copied:`n" . str)
	SetTimer(() => ToolTip(), -2000)
}

$^e:: {
	items := ExUtils.SelectedItems()
	for item in items {
		item.InvokeVerb("edit")
	}
}

$^+v:: {
	global inClipboard
	; check if text in clipboard
	if inClipboard == 1 {
		current := ExUtils.GetCurrentPath()
		path := GetNewFilePath(current, 'paste.txt')
		FileAppend(A_Clipboard, path, "UTF-8")
	}
}
#HotIf

pathActions := Map(
	"1 backlash (\)", [true],
	"2 slash (/)", [false],
	"3 escaped backslash (\\)", ["\\"],
	"4 file:///...", [false, "file:///"],
	"5 obsidian file:///", [true, "file:///"],
	"6 vscode://file", [false, "vscode://file/"]
)
pathMenu := Menu()

for action in pathActions {
	pathMenu.Add(action, PathAction)
}

PathAction(name, *) {
	action := pathActions[name]

	str := ""

	paths := StrSplit(A_Clipboard, "`n")
	for path in paths {
		path := StrReplace(path, '`r', '')
		str .= (str ? '`n' : '') . ConvertPath(path, action*)
	}

	A_Clipboard := str
	ToolTip("converted path(s) to:`n" . str)
	SetTimer(() => ToolTip(), -2000)
}

$^!v:: {
	clipboard := A_Clipboard
	if Type(clipboard) != "String" or !Trim(clipboard) {
		return
	}

	pathMenu.Show()
}

#HotIf IsWindows11
#k:: {
	Run("ms-settings:bluetooth")
}
#HotIf