;@Ahk2Exe-SetMainIcon .\icons\shortcuts.ico
;@Ahk2Exe-SetDescription shortcuts enables you to open folders files and scripts quickly

#Include <Base>
#Include <Jsons>

SetIcon(".\icons\shortcuts.ico")

home := EnvGet("USERPROFILE")
if home == "" {
	home := EnvGet("HOME")
}

filePath := home . "\shortcuts\shortcuts.json"
if not FileExist(filePath) {
	Notification(Format("no explorer-shortcuts.json normalMatch in {1} directory, not configuring any shortcuts", home), "", "Mute")
	ExitApp(1)
}

setupReloadPaths(filePath)

jsonFile := FileRead(filePath)
json := Jsons.Load(&jsonFile)

try {
	shortcuts := json["shortcuts"]
	if not shortcuts is Map {
		Notification("'shortcuts' isn't an object/map")
		ExitApp(1)
	}

	handlers := json["handlers"]
	if not handlers is Array {
		Notification("'handlers' isn't an object/map")
		ExitApp(1)
	}
} catch {
	Notification("no 'shortcuts' or 'handlers' field defined in " . filePath)
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

for handler in handlers {
	if handler.Has("formatStr") {
		handler["formatStr"] := StrReplace(handler["formatStr"], "{A_ComSpec}", A_ComSpec, false)
	} else {
		handler["formatStr"] := ""
	}
	if not handler.Has("name") {
		MsgBox("a handler is missing a name property")
		ExitApp(1)
	}
	if handler.Has("workingDir") {
		handler["workingDir"] := StrReplace(handler["workingDir"], "{A_ahkscripts}", A_ScriptDir)
	} else {
		handler["workingDir"] := ""
	}
	if not (handler.Has("match") or handler.Has("fileMatch") or (handler.Has("protocols") and handler["protocols"] is Array)) {
		MsgBox(Format("{1} handler wrongly configured", handler.Name))
		ExitApp(1)
	}
}

RunFile(path) {
	for handler in handlers {
		match := 0
		if handler.Has("protocols") {
			protocolMatcher := "^("
			for protocol in handler["protocols"] {
				protocol := RegExReplace(protocol, "([-[\]{}()*+?.,\\^$|#\s])", "\$1")
				protocolMatcher .= protocol . "|"
			}
			protocolMatcher := SubStr(protocolMatcher, 1, -1)
			protocolMatcher .= "):"
			protocolMatch := RegExMatch(path, protocolMatcher)

			if protocolMatch {
				path := RegExReplace(path, protocolMatcher, "")
			}
			match := match + protocolMatch
		}
		if handler.Has("fileMatch") {
			if FileExist(path) {
				match := match + RegExMatch(path, handler["fileMatch"])
			}
		}
		if handler.Has("match") {
			match := match + RegExMatch(path, handler["match"])
		}

		if not match {
			continue
		}

		if handler["formatStr"] {
			Run(Format(handler["formatStr"], path), handler["workingDir"]) ; TODO figure out how to start vs code without admin rights??
		} else {
			Run(path, handler["workingDir"])
		}
		Return true
	}

	; try opening path with start if nothing else works
	if FileExist(path) {
		Run(Format("{1} /c `"start {2}`"", A_ComSpec, path))
		Return true
	}

	Return false
}

RunPath(path, notificationOnError := true) {
	path := StrReplace(path, "{A_ahkscripts}", A_ScriptDir)
	path := StrReplace(path, "{A_ahkscripts_slash}", StrReplace(A_ScriptDir, "\", "/")) ; TODO dynamic replacement of global variables
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

	if not IsWindows11 {
		MsgBox("PC isn't Windows 11`nOpening multiple folders isn't currently supported")
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