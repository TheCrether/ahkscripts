#Requires AutoHotkey v2
#SingleInstance Force

try {
	baseAHKPath := A_ScriptDir . "\Base.ahk"
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
		If (DateDiff(ModTime2, ModTime, "Seconds") > 1 or DateDiff(ModTimeBase2, ModTimeBase, "Seconds")) {
			Reload
		}
	} catch {
		SetTimer(CheckTime, 0)
	}
}