#Requires AutoHotkey v2
#SingleInstance Force

; Always use folder where the script is
SetWorkingDir(A_ScriptDir)

SetIcon(path) {
	try {
		TraySetIcon(path)
	}
}

notificationHandlers := Map()

NINF_KEY := 1

WM_USER := 0x0400
NIN_BALLOONHIDE := WM_USER + 3
NIN_BALLOONSHOW := WM_USER + 2
NIN_BALLOONTIMEOUT := WM_USER + 4
NIN_BALLOONHIDE := WM_USER + 3
NIN_BALLOONUSERCLICK := WM_USER + 5
NIN_SELECT := WM_USER + 0
NIN_KEYSELECT := NIN_SELECT | NINF_KEY
NIN_POPUPCLOSE := WM_USER + 7
NIN_POPUPOPEN := WM_USER + 6

SetNotificationHandler(action := NIN_BALLOONUSERCLICK, function := () => {}) {
	global notificationHandlers
	notificationHandlers.Set(action, function)
}
RemoveNotificationHandler(action := NIN_BALLOONUSERCLICK) {
	global notificationHandlers
	notificationHandlers.Delete(action)
}

/**
 * NotificationHandler
 * @param wParam ?
 * @param lParam the kind of action
 * @param msg which event was activated (ex.: 0x404 -> a notification event)
 * @param hwnd the hwnd of the owner of the event
 */
NotificationHandler(wParam, lParam, msg, hwnd) {
	global notificationHandlers
	; from: https://docs.rs/winapi/latest/i686-pc-windows-msvc/winapi/um/shellapi/index.html
	; lParam:
	;		WM_USER = 0x400 = 1024
	; 	NIN_BALLOONHIDE = WM_USER + 3 = 0x403 = 1027
	; 	NIN_BALLOONSHOW = WM_USER + 2 = 0x402 = 1026
	; 	NIN_BALLOONTIMEOUT = WM_USER + 4 = 0x404 = 1028
	; 	NIN_BALLOONHIDE = WM_USER + 3 = 0x403 = 1027
	; 	NIN_BALLOONUSERCLICK = WM_USER + 5 = 0x405 = 1029
	; 	NIN_KEYSELECT = NIN_SELECT | NINF_KEY = 0x401 = 1025
	; 	NIN_POPUPCLOSE = WM_USER + 7 = 0x407 = 1031
	; 	NIN_POPUPOPEN = WM_USER + 6 = 0x406 = 1030
	; 	NIN_SELECT = WM_USER + 0 = 0x400 = 1024

	if hwnd != A_ScriptHwnd {
		return
	}
	OutputDebug(wParam . ' ' . lParam . ' ' . msg)

	f := notificationHandlers.Get(lParam, false)

	if !!f {
		f()
	}
}

; listen to notifications
OnMessage(0x404, NotificationHandler)

Notification(Text := '', Title := A_ScriptName, Options := 0, OnSelected := () => {}) {
	TrayTip(Text, Title, Options)

	SetNotificationHandler(NIN_BALLOONUSERCLICK, OnSelected)
}

reloadPaths := Map()

try {
	baseAHKPath := A_ScriptDir . "\Lib\Base.ahk"
	ModTime := FileGetTime(A_ScriptFullPath, "M")
	ModTimeBase := FileGetTime(baseAHKPath, "M")
	SetTimer(CheckTime, 10000)
} catch {
	SetTimer(CheckTime, 0)
}

CheckTime() {
	try {
		ModTime2 := FileGetTime(A_ScriptFullPath, "M")
		ModTimeBase2 := FileGetTime(baseAHKPath, "M")
		if DateDiff(ModTimeBase2, ModTimeBase, "Seconds") {
			; don't output Notification when reloading Base because this reloads mutliple scripts
			Reload
		} else if DateDiff(ModTime2, ModTime, "Seconds") > 1 {
			Notification("reloading " . A_ScriptName, A_ScriptName)
			Reload
		}
		for path, time in reloadPaths {
			time2 := FileGetTime(path, "M")
			if DateDiff(time2, time, "Seconds") {
				Notification(Format("Reloading {1} because of {2}", A_ScriptName, path), A_ScriptName)
				Reload
			}
		}
	} catch {
		SetTimer(CheckTime, 0)
	}
}

setupReloadPaths(paths*) {
	for path in paths {
		time := FileGetTime(path, "M")
		reloadPaths[path] := time
	}
}

GetCommandOutput(cmd) {
	before := A_DetectHiddenWindows
	DetectHiddenWindows(1)
	pid := 0
	Run(A_ComSpec, , "Hide", &pid)
	WinWait("ahk_pid " . pid)
	DllCall("AttachConsole", "UInt", pid)
	WshShell := ComObject("Wscript.Shell")
	exec := WshShell.Exec(cmd)
	output := exec.StdOut.ReadAll()
	DllCall("FreeConsole")
	ProcessClose(pid)
	DetectHiddenWindows(before)
	return output
}

ChangeDesktop(desktop) {
	beforeHiddenWindows := A_DetectHiddenWindows
	DetectHiddenWindows(1)
	desktopId := WinExist("desktop.ahk ahk_class AutoHotkey")
	PostMessage(0x5555, 0, desktop, , "ahk_id " . desktopId)
	Sleep(500)
	DetectHiddenWindows(beforeHiddenWindows)
}

global IsWindows11 := 0
if InStr(GetCommandOutput('powershell -WindowStyle Hidden -Command "(Get-WmiObject Win32_OperatingSystem).Caption"'), "Windows 11") {
	IsWindows11 := 1
}

; taken from AutoHotkey ShellRun.ahk
; runs a process through the explorer which splits it off from AutoHotkey
; For documentation about the parameters, refer to:
;  https://learn.microsoft.com/en-us/windows/win32/shell/shell-shellexecute
ShellRun(filePath, arguments?, directory?, operation?, show?) {
	static VT_UI4 := 0x13, SWC_DESKTOP := ComValue(VT_UI4, 0x8)
	ComObject("Shell.Application").Windows.Item(SWC_DESKTOP).Document.Application
		.ShellExecute(filePath, arguments?, directory?, operation?, show?)
}

ReplaceVariables(text, replaceMap := Map(), allowGlobalVariables := true) {
	if not replaceMap is Map {
		throw ValueError("replaceMap is not a map")
	}
	for key, val in replaceMap {
		if not InStr(key, "{") = 1 {
			key := "{" . key
		}
		if not InStr(key, "}") = StrLen(key) {
			key .= "}"
		}
		text := StrReplace(text, key, val)
	}
	if allowGlobalVariables {
		regex := "\{(\w[A-Za-z0-9_]+)\}"
		; TODO add support for indexed values?
		Found := RegExMatch(text, regex, &match)
		While Found > 0 and match.Count > 0 {
			try {
				varName := match[1]
				val := match[0]
				try val := %varName%

				text := StrReplace(text, match[0], val)

				Found := RegExMatch(text, regex, &match, match.Pos + StrLen(val))
			}
		}
	}
	return text
}

f := ReplaceVariables

OutputWindow(hwnd) {
	title := WinGetTitle("ahk_id " . hwnd)
	cla := WinGetClass("ahk_id " . hwnd)
	pname := WinGetProcessName("ahk_id " . hwnd)
	text := Format("hwnd: {1}`nt: {2}`nclass: {3}`nexe: {4}", hwnd, title, cla, pname)
	; MsgBox(text)
	OutputDebug(text . "`n====`n")
}

tryGetID(title, regex := false, detectHidden := false) {
	beforeMatchMode := A_TitleMatchMode
	beforeHidden := A_DetectHiddenWindows
	if regex {
		SetTitleMatchMode("RegEx")
	}
	if detectHidden {
		DetectHiddenWindows(true)
	}

	id := ""
	try {
		id := WinGetID(title)
	}

	SetTitleMatchMode(beforeMatchMode)
	DetectHiddenWindows(beforeHidden)

	return id
}

tryActivate(title, regex := false, detectHidden := false) {
	try {
		WinActivate(tryGetID(title, regex, detectHidden))
	} catch {
		OutputDebug(Format("(regex:{1})(detectHidden:{2}) can't find window with: {3}`n", regex, detectHidden, title))
	}
}

GetMonitorOfWindow(title, &n, &left, &top, &right, &bottom) {
	count := MonitorGetCount()
	nTemp := MonitorGetPrimary()
	MonitorGet(nTemp, &leftTemp, &topTemp, &rightTemp, &bottomTemp)
	Loop count {
		MonitorGet(A_Index, &leftTemp, &topTemp, &rightTemp, &bottomTemp)
		WinGetPos(&x, &y, &w, &h, title)
		if x >= leftTemp && x < rightTemp && y >= topTemp && y < bottomTemp {
			nTemp := A_Index
			break
		}
	}

	n := nTemp
	left := leftTemp
	top := topTemp
	right := rightTemp
	bottom := bottomTemp
}

/**
 * Normalize a path to a windows path (with no trailing '\' at the end)
 * @param path the path to normalize
 * @returns {String} the normalized path
 */
NormalizePath(path) {
	cc := DllCall("GetFullPathName", "str", path, "uint", 0, "ptr", 0, "ptr", 0, "uint")
	buf := Buffer(cc * 2)
	DllCall("GetFullPathName", "str", path, "uint", cc, "ptr", buf, "ptr", 0)
	str := StrGet(buf)
	if SubStr(str, -1, 1) == "\" {
		str := SubStr(str, 1, -1)
	}
	return str
}


/**
 * Convert a path
 * @param path the path to be converted
 * @param {true|false|String} backslash if this is true -> separator = '\', if false -> separator = '/', if it's string, replace with that string
 * @param {String} prefix prefix for the path after conversion
 * @param {String} suffix suffix for the path after conversion
 * @returns {String} the converted string with the prefix/suffix if given
 */
ConvertPath(path, backslash := false, prefix := '', suffix := '') {
	path := Trim(path, ' `t`'"')
	if (InStr(path, "vscode://")) {
		path := RegExReplace(path, "vscode://\w+/", "")
	}
	path := RegExReplace(path, "\w{2,}://+", "")
	path := StrReplace(path, "`r", "")
	path := NormalizePath(path)

	if Type(backslash) == "String" {
		path := StrReplace(path, "\", backslash)
	} else if !backslash {
		path := StrReplace(path, "\", "/")
	}

	path := prefix . path . suffix

	return path
}