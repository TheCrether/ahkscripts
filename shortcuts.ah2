#Include <Base>
#Include <JXON>

SetIcon(".\icons\shortcuts.ico")

home := EnvGet("USERPROFILE")
if home == "" {
	home := EnvGet("HOME")
}

filePath := home . "\shortcuts\shortcuts.json"
if not FileExist(filePath) {
	TrayTip(Format("no explorer-shortcuts.json found in {1} directory, not configuring any shortcuts", home), "", "Mute")
	ExitApp()
}

setupReloadPaths(filePath)

jsonFile := FileRead(filePath)
json := Jxon_Load(&jsonFile)

try {
	shortcuts := json["shortcuts"]
	if not shortcuts is Map {
		TrayTip("'shortcuts' isn't an object/map")
		ExitApp()
	}
} catch {
	TrayTip("no 'shortcuts' field defined in " . filePath)
	ExitApp()
}

shortcutMenu := Menu()
generateSubmenu(prev, subShortcuts) {
	submenu := Menu()
	for shortcut in subShortcuts {
		if subShortcuts[shortcut] is Array {
			if subShortcuts[shortcut].Length == 0 {
				continue
			}
			submenu.Add(shortcut, OpenShortcut.Bind(prev))
		} else if subShortcuts[shortcut] is String {
			if StrLen(subShortcuts[shortcut]) <= 1 {
				continue
			}
			submenu.Add(shortcut, OpenShortcut.Bind(prev))
		} else if subShortcuts[shortcut] is Map {
			submenu.Add(
				shortcut,
				generateSubmenu(
					Format("{1}.{2}", prev, shortcut),
					subShortcuts[shortcut]
				)
			)
		}
	}
	return submenu
}

for shortcut in shortcuts {
	if shortcuts[shortcut] is Array {
		if shortcuts[shortcut].Length == 0 {
			continue
		}
		shortcutMenu.Add(shortcut, OpenShortcut.Bind(""))
	} else if shortcuts[shortcut] is String {
		if StrLen(shortcuts[shortcut]) <= 1 {
			continue
		}
		shortcutMenu.Add(shortcut, OpenShortcut.Bind(""))
	} else if shortcuts[shortcut] is Map {
		shortcutMenu.Add(
			shortcut,
			generateSubmenu(shortcut, shortcuts[shortcut])
		)
	}
}

RunPath(path, skipExplorerCheck := false) {
	AhkFound := RegExMatch(path, ".*\.(ah2|ahk)$")
	Batch := RegExMatch(path, ".*\.bat$")
	Powershell := RegExMatch(path, ".*\.ps1$")
	if AhkFound > 0 {
		Run(path)
	} else if Batch > 0 {
		Run(Format("{1} /c '{2}'", A_ComSpec, path))
	} else if Powershell > 0 {
		Run(Format("powershell {1}", path))
	} else if not skipExplorerCheck {
		Run("C:\Windows\explorer.exe " . path)
	}
}

OpenShortcut(parentPath, name, itemPos, menuObj) {
	global shortcuts

	parentShortcuts := shortcuts
	split := StrSplit(parentPath, ".")
	for parent in split {
		parentShortcuts := parentShortcuts[parent]
	}

	paths := parentShortcuts[name]

	if paths is String {
		RunPath(paths)
		Return
	}

	if paths.Length == 1 {
		RunPath(paths[1])
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