#Requires AutoHotkey v2
#SingleInstance Force
DetectHiddenWindows(true)

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

#Include "..\Lib\UIA\UIA.ahk"

GetHandle(title, activate := false) {
	id := tryGetID(title, true, true)

	if !id {
		OutputDebug("main window not found")
		return ""
	}

	if activate {
		WinActivate("ahk_id " . id)
	}

	return UIA.ElementFromHandle(id)
}

RegExElement(uiaHandle, lType, match) {
	Loop {
		try {
			e := uiaHandle.FindElement([{ LocalizedType: lType }], , A_Index)
			if RegExMatch(e.Name, match) {
				return e
			}
		}
	}
	return ""
}

DoClick(e) {
	e.Click("left")
	Sleep(200)
}

status := "Available" ; Available, Busy, Do not disturb, Away, Out of Office
if A_Args.Length > 0 {
	status := A_Args[1]
} else {
	res := InputBox("Enter the status you want`n(Verfügbar|Abwesend|Nicht Stören|Homeoffice|Business Trip)", "3cx status selector", , "Verfügbar")
	if res.Result != "Ok" {
		ExitApp(1)
	}
	status := res.Value
}

uiaHandle := GetHandle("3CX.* ahk_exe msedge.exe", true)
if !uiaHandle {
	OutputDebug("main window not found")
	return
}

e := ""
try e := uiaHandle.FindElement([{ ClassName: "avatar ms-1" }])
if !e {
	OutputDebug("profile pic not found")
	return
}

dropdown := ""
try dropdown := uiaHandle.FindElement([{
	LocalizedType: "menu",
	ClassName: "dropdown-menu dropdown-menu-right black-menu ng-star-inserted show"
}])
if !dropdown {
	DoClick(e)
}

e := RegExElement(uiaHandle, "group", "i).*" . status . ".*")
if !e {
	OutputDebug("status " . status . " element not found")
	return
}
DoClick(e)
ExitApp(0)