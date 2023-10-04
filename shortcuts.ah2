#Include <Base>
#Include <JXON>
home := EnvGet("USERPROFILE")
if home == "" {
	home := EnvGet("HOME")
}

filePath := home . "\shortcuts\shortcuts.json"
if not FileExist(filePath) {
	TrayTip(Format("no explorer-shortcuts.json found in {1} directory, not configuring any shortcuts", home), "", "Mute")
	Return
}

setupReloadPaths(filePath)

jsonFile := FileRead(filePath)
json := Jxon_Load(&jsonFile)

try {
	shortcuts := json["shortcuts"]
	if not shortcuts is Map {
		TrayTip("'shortcuts' isn't an object/map")
		Return
	}
} catch {
	TrayTip("no 'shortcuts' field defined in " . filePath)
	Return
}

shortcutMenu := Menu()
for shortcut in shortcuts {
	if shortcuts[shortcut] is Array {
		if shortcuts[shortcut].Length == 0 {
			continue
		}
	} else if shortcuts[shortcut] is String {
		if StrLen(shortcuts[shortcut]) <= 1 {
			continue
		}
	}
	shortcutMenu.Add(shortcut, OpenShortcut)
}
OpenShortcut(name, itemPos, menuObj) {
	paths := shortcuts[name]

	if paths is String {
		Found := RegExMatch(paths, ".*(ah2|ahk)$")
		if Found > 0 { ; run ahkscript
			Run(paths)
		} else {
			Run("C:\Windows\explorer.exe " . paths)
		}
		Return
	}

	if paths.Length == 1 {
		Run("C:\Windows\explorer.exe " . paths[1])
		Return
	}
	Send("#e")
	WinWaitActive("ahk_exe explorer.exe")
	Sleep(200)
	Loop paths.Length {
		if A_Index > 1 {
			Send("^t")
			Sleep(500)
		}
		Send("^l")
		Sleep(300)
		SendText(paths[A_Index])
		Sleep(400)
		Send("{Enter}")
		Sleep(300)
	}
}

#+e:: {
	shortcutMenu.Show()
}