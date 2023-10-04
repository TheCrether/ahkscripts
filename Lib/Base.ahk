#Requires AutoHotkey v2
#SingleInstance Force

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
			; don't output TrayTip when reloading Base because this reloads mutliple scripts
			Reload
		} else if DateDiff(ModTime2, ModTime, "Seconds") > 1 {
			TrayTip("reloading " . A_ScriptName, , "Mute")
			Reload
		}
		for path, time in reloadPaths {
			time2 := FileGetTime(path, "M")
			if DateDiff(time2, time, "Seconds") {
				TrayTip(Format("Reloading {1} because of {2}", A_ScriptName, path))
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