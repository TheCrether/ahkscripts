#Requires AutoHotkey v2
#SingleInstance Force

; Always use folder where the script is
SetWorkingDir(A_ScriptDir)

SetIcon(path) {
	; TODO if this is needed for compiled scripts or if you can skip it
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

global IsWindows11 := 0
if InStr(GetCommandOutput('powershell -WindowStyle Hidden -Command "(Get-WmiObject Win32_OperatingSystem).Caption"'), "Windows 11") {
	IsWindows11 := 1
}