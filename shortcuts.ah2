;@Ahk2Exe-SetMainIcon .\icons\shortcuts.ico
;@Ahk2Exe-SetDescription shortcuts enables you to open folders, files and scripts quickly

#Include <Base>
#Include <JXON>

SetIcon(".\icons\shortcuts.ico")

home := EnvGet("USERPROFILE")
if home == "" {
	home := EnvGet("HOME")
}

filePath := home . "\shortcuts\shortcuts.json"
if not FileExist(filePath) {
	Notification(Format("no explorer-shortcuts.json found in {1} directory, not configuring any shortcuts", home), "", "Mute")
	ExitApp()
}

setupReloadPaths(filePath)

jsonFile := FileRead(filePath)
json := Jxon_Load(&jsonFile)

try {
	shortcuts := json["shortcuts"]
	if not shortcuts is Map {
		Notification("'shortcuts' isn't an object/map")
		ExitApp()
	}
} catch {
	Notification("no 'shortcuts' field defined in " . filePath)
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

; add edit shortcuts.json
name := "edit shortcuts.json"
shortcuts[name] := filePath
shortcutMenu.Add() ; add separator
shortcutMenu.Add(name, OpenShortcut.Bind(""))

RunFile(path) {
	if not FileExist(path) {
		Return false
	}

	; TODO add directives to skip to specific launch types/launch with specific programs?

	AhkFound := RegExMatch(path, ".*\.(ah2|ahk)$")
	Batch := RegExMatch(path, ".*\.bat$")
	Powershell := RegExMatch(path, ".*\.ps1$")

	if AhkFound > 0 {
		Run(path)
	} else if Batch > 0 {
		Run(Format('{1} /c "{2}"', A_ComSpec, path))
	} else if Powershell > 0 {
		Run(Format("powershell {1}", path))
	} else {
		Run(Format('{1} /c "start {2}"', A_ComSpec, path))
	}

	Return true
}

RunPath(path, notificationOnError := true) {
	if DirExist(path) {
		Run("C:\Windows\explorer.exe " . path)
		Return true
	}

	successful := RunFile(path)
	if not successful and notificationOnError {
		Notification("'" . path . "' doesn't exist. Stopping shortcut execution for this path")
	}
	return successful
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

	folders := []
	files := []
	nonExist := []
	for path in paths {
		if DirExist(path) {
			folders.Push(path)
		} else if FileExist(path) {
			files.Push(path)
		} else {
			nonExist.Push(path)
		}
	}

	Send("#e")
	WinWaitActive("ahk_exe explorer.exe")
	Sleep(200)
	Loop folders.Length {
		folder := folders[A_Index]
		if A_Index > 1 {
			Send("^t")
			Sleep(500)
		}
		Send("^l")
		Sleep(300)
		SendText(folder)
		Sleep(400)
		Send("{Enter}")
		Sleep(300)
	}

	for file in files {
		; TODO workout a way to wait until file is opened
		; RunFile(file, false)
	}

	if nonExist.Length > 0 {
		txt := 'The following paths are non existent:`n'
		Loop nonExist.Length {
			txt := Format("{1}`n{2}", txt, nonExist[A_Index])
		}
		MsgBox(txt, Format("shortcuts.ah2 - {1}.{2}", parentPath, name))
	}
}

#+e:: {
	shortcutMenu.Show()
}