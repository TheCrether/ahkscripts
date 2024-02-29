#Requires AutoHotkey v2
#SingleInstance Force

; Always use folder where the script is
SetWorkingDir(A_ScriptDir)

SetIcon(path) {
	try {
		TraySetIcon(path)
	}
}

Notification(Text := '', Title := A_ScriptName, Options := 0) {
	TrayTip(Text, Title, Options)
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
	desktopId := WinExist("desktop.ah2 ahk_class AutoHotkey")
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