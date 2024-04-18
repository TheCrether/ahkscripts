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

presence := "Available" ; Available, Busy, Do not disturb, Away, Out of Office
if A_Args.Length > 0 {
	presence := A_Args[1]
} else {
	res := InputBox("Enter the presence status you want`n(Available|Busy|Do not disturb|Away|Out of Office)", "zoom presence selector", , "Available")
	if res.Result != "Ok" {
		ExitApp(1)
	}
	presence := res.Value
}

uiaHandle := GetHandle("ahk_class ZPPTMainFrmWndClassEx ahk_exe Zoom.exe", true)
if !uiaHandle {
	OutputDebug("main window not found")
	return
}

e := RegExElement(uiaHandle, "split button", ".*Denis Imeri.*")
if !e {
	OutputDebug("profile button not found")
	return
}
DoClick(e)

uiaHandle := GetHandle("ahk_class ZPPTMainMenuWndClass")
if !uiaHandle {
	OutputDebug("menu window not found")
	return
}

e := ""
try e := uiaHandle.FindElement([{ LocalizedType: "menu item" }], , 2)
if !e {
	OutputDebug("status submenu button not found")
	return
}
DoClick(e)

uiaHandle := GetHandle("ahk_class ZPPTPresenceSubMenuWndClass")
if !uiaHandle {
	OutputDebug("presence submenu window not found")
	return
}

e := RegExElement(uiaHandle, "menu item", "i).*" . presence . ".*")
if !e {
	OutputDebug("presence button not found")
	return
}

; move to the right first to not trigger an other submenu
MouseGetPos(&x, &y)
loc := e.Location
MouseMove(loc.x, y)
e.Click("left")

ExitApp(0)