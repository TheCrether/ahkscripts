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
		Sleep(100)
	}

	return UIA.ElementFromHandle(id)
}

/**
 * 
 * @param {UIA.IUIAutomationElement} uiahandle
 * @param type
 * @param match
 * @returns {String}
 */
GetElementByAutomationId(uiaHandle, lType, automationId) {
	element := ""
	try element := uiaHandle.FindElement([{ LocalizedType: lType, AutomationId: automationId }])
	return element
	; elements := uiaHandle.FindElement([{ LocalizedType: lType }])
	; Loop {
	; 	try {
	; 		e := uiaHandle.FindElement([{ Type: lType }], , A_Index)
	; 		; if StrLen(e.GetPropertyValue("title")) > 0 {
	; 		if StrLen(e.Name) > 0 {
	; 			OutputDebug(e.Name . " " e.GetPropertyValue("title"))
	; 		}
	; 		if RegExMatch(e.Name, match) {
	; 			return e
	; 		}
	; 	}
	; }
	; return ""
}

DoClick(e) {
	e.Click("left")
	Sleep(200)
}

statusMapping := Map()
statusMapping["verfügbar"] := "Available"
statusMapping["abwesend"] := "Away"
statusMapping["nicht stören"] := "Outofoffice"
statusMapping["homeoffice"] := "Custom1"
statusMapping["business trip"] := "Custom2"

status := "Verfügbar" ; Verfügbar, Abwesend, Nicht Stören, Homeoffice, Business Trip
if A_Args.Length > 0 {
	status := A_Args[1]
} else {
	res := InputBox("Enter the status you want`n(Verfügbar|Abwesend|Nicht Stören|Homeoffice|Business Trip)", "3cx status selector", , "Verfügbar")
	if res.Result != "Ok" {
		ExitApp(1)
	}
	status := res.Value
}

status := StrLower(status)
status := statusMapping[status]

uiaHandle := GetHandle("3CX.* ahk_exe msedge.exe", true)
if !uiaHandle {
	OutputDebug("main window not found")
	return
}


e := ""
try e := uiaHandle.FindElement([{ ClassName: "avatar-size-", MatchMode: "substring" }])
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

e := GetElementByAutomationId(uiaHandle, "group", "menu" . status)
if !e {
	OutputDebug("status " . status . " element not found")
	return
}
DoClick(e)
ExitApp(0)