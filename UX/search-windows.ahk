#Requires AutoHotkey v2
#SingleInstance Force

Exit(*) => ExitApp()
OutputWindowText(hwnd) {
	title := WinGetTitle("ahk_id " . hwnd)
	cla := WinGetClass("ahk_id " . hwnd)
	pname := ""
	try {
		pname := WinGetProcessName("ahk_id " . hwnd)
	}
	text := Format("hwnd: {1}`nt: {2}`nclass: {3}`nexe: {4}", hwnd, title, cla, pname)
	return text
}
QueryWindows(*) {
	global editControl, text
	list := WinGetList(editControl.Value)
	if list.Length > 0 {
		str := ""
		for i in list {
			str .= OutputWindowText(i) . '`n`n'
		}
		text.Value := str
		text.Redraw()
	}
}

DetectHiddenWindows(1)
before := A_TitleMatchMode
SetTitleMatchMode("RegEx")

myGui := Gui("AlwaysOnTop +MinSize1000x20")
editControl := myGui.Add("Edit", "vMyEdit w1000")
editControl.OnEvent("Change", QueryWindows)
text := myGui.Add("Edit", "w1000 r80 HScroll")
exitBtn := myGui.Add("button", "w80", "Exit")
exitBtn.OnEvent("Click", Exit)
myGui.Show