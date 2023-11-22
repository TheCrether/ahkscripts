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
		Notification("'handlers' isn't an array")
		ExitApp(1)
	}
} catch {
	Notification("no 'shortcuts' or 'handlers' field defined in " . filePath)
	ExitApp(1)
}

addFromWildcards(shortcuts, submenu, prev) {
	wildcards := shortcuts["_wildcards"]
	if wildcards is String {
		wildcards := [wildcards]
	}
	if not wildcards is Array {
		MsgBox(Format('"{1}._wildcards" is not an array or string', prev))
		ExitApp(1)
	}

	prevPath := home . "\shortcuts\" . StrReplace(prev, ".", "\") . "\*"
	loop files prevPath {
		fileName := A_LoopFileName
		for wildcard in wildcards {
			if not RegExMatch(fileName, wildcard) {
				continue
			}

			; get shortcut name
			content := FileRead(A_LoopFileFullPath, "UTF-8 m1024 `n")
			matchOutput := ""
			if RegExMatch(content, "sh-name:([^;`n]+)", &matchOutput) and matchOutput.Count > 0 {
				name := matchOutput[1]
			} else {
				name := StrReplace(A_LoopFileName, "." . A_LoopFileExt, "")
			}

			; add to shortcuts
			shortcuts[name] := A_LoopFileFullPath
			submenu.Add(name, OpenShortcut.Bind(prev))
		}
	}
}

generateSubmenu(prev, shortcuts) {
	submenu := Menu()
	wildcards := false
	for name, shortcut in shortcuts {
		if name = "_wildcards" {
			wildcards := true
		}
		else if shortcut is Array and shortcut.Length > 0 {
			submenu.Add(name, OpenShortcut.Bind(prev))
		}
		else if shortcut is String and StrLen(shortcut) > 1 {
			submenu.Add(name, OpenShortcut.Bind(prev))
		}
		else if shortcut is Map {
			newPrev := prev
			if InStr(prev, ".") {
				prev .= "."
			}
			newPrev .= name
			submenu.Add(
				name,
				generateSubmenu(
					newPrev,
					shortcut
				)
			)
		} else {
			MsgBox(Format('"{1}.{2}" is not a valid shortcut definition', prev, name))
			ExitApp(1)
		}
	}
	if wildcards {
		addFromWildcards(shortcuts, submenu, prev)
	}
	return submenu
}

shortcutMenu := generateSubmenu("", shortcuts)

; add edit shortcuts.json
name := "edit shortcuts.json"
shortcuts[name] := filePath
shortcutMenu.Add() ; add separator
shortcutMenu.Add(name, OpenShortcut.Bind(""))

ReloadProc(name, pos, menu) {
	Reload
}
shortcutMenu.Add("reload", ReloadProc)

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
			formatted := StrSplit(Format(handler["formatStr"], path), " ", , 2)
			if formatted.Length > 1 {
				ShellRun(formatted[1], formatted[2], handler["workingDir"])
			} else {
				ShellRun(formatted[1], handler["workingDir"])
			}
		} else {
			Run(path, handler["workingDir"])
		}
		Return true
	}

	; try opening path with start if nothing else works
	if FileExist(path) {
		ShellRun(A_ComSpec, Format("/c `"start {1}`"", path))
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
			if not RunPath(path, false) {
				nonExist.Push(path)
			}
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