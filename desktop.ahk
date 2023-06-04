#Requires AutoHotkey v2
; this script is based on the example script from here: https://github.com/Ciantic/VirtualDesktopAccessor
#SingleInstance force
InstallKeybdHook()

; Always use folder where the script is
SetWorkingDir(A_ScriptDir)
TraySetIcon(".\icons\desktop.ico")

DetectHiddenWindows(true)
hwnd := WinExist("ahk_pid " . DllCall("GetCurrentProcessId", "Uint"))
hwnd += 0x1000 << 32

if (FileExist(".\VirtualDesktopAccessor.dll") == "") {
	MsgBox("I couldn't find a VirtualDesktopAccessor.dll in the same directory as the script! `n Exiting!")
	Return
}

hDesktopDLL := DllCall("LoadLibrary", "Str", ".\VirtualDesktopAccessor.dll", "Ptr")

GetProc(funcname) {
	global hDesktopDLL
	return DllCall("GetProcAddress", "Ptr", hDesktopDLL, "AStr", funcname, "Ptr")
}

GoToDesktopNumberProc := GetProc("GoToDesktopNumber")
GetCurrentDesktopNumberProc := GetProc("GetCurrentDesktopNumber")
IsWinOnCurrVirtualDesktopProc := GetProc("IsWindowOnCurrentVirtualDesktop")
MoveWinToDesktopNumberProc := GetProc("MoveWindowToDesktopNumber")
RegisterPostMessageHookProc := GetProc("RegisterPostMessageHook")
UnregisterPostMessageHookProc := GetProc("UnregisterPostMessageHook")
IsPinnedProc := GetProc("IsPinnedWindow")
; RestartDesktopDLLProc := GetProc("RestartVirtualDesktopAccessor")
GetWinDesktopNumberProc := GetProc("GetWindowDesktopNumber")
GetDesktopCountProc := GetProc("GetDesktopCount")
activeWindowByDesktop := Map()

MoveCurrentWindowToDesktop(number, move) {
	global GetCurrentDesktopNumberProc, MoveWinToDesktopNumberProc, GoToDesktopNumberProc, activeWindowByDesktop

	current := DllCall(GetCurrentDesktopNumberProc, "UInt")

	activeHwnd := WinGetID("A")
	activeWindowByDesktop[number] := activeHwnd ; Do not activate
	DllCall(MoveWinToDesktopNumberProc, "UInt", activeHwnd, "UInt", number)
	if (move) {
		GoToDesktopNumber(number)
		; DllCall(GoToDesktopNumberProc, UInt, number)
	}

	WinActivate("ahk_class Shell_TrayWnd")
}

GoToDesktopNumber(num) {
	global GetCurrentDesktopNumberProc, GoToDesktopNumberProc, IsPinnedProc, activeWindowByDesktop

	; Store the active window of old desktop, if it is not pinned
	activeHwnd := WinGetID("A")
	current := DllCall(GetCurrentDesktopNumberProc, "UInt")

	; stop if the desktop is already active
	if (current == num) {
		return
	}

	activeWindowByDesktop[current] := activeHwnd

	; Try to avoid flashing task bar buttons, deactivate the current window if it is not pinned
	isPinned := DllCall(IsPinnedProc, "UInt", activeHwnd)
	if (isPinned != 1) {
		WinActivate("ahk_class Shell_TrayWnd")
	}

	; Change desktop
	DllCall(GoToDesktopNumberProc, "Int", num)
	return
}

dCount := DllCall(GetDesktopCountProc, "Int")

; Windows 10 desktop changes listener
DllCall(RegisterPostMessageHookProc, "Int", hwnd, "Int", 0x1400 + 30)
OnMessage(0x1400 + 30, VWMess)
VWMess(wParam, lParam, msg, hwnd) { ; wParam is the old desktop and lParam is the new desktop
	global IsWinOnCurrVirtualDesktopProc, IsPinnedProc, activeWindowByDesktop, dCount, GetDesktopCountProc, GetCurrentDesktopNumberProc

	currentDCount := DllCall(GetDesktopCountProc, "Int")
	; OutputDebug % dCount "vwness"
	if (dCount != currentDCount) {
		GenerateDynamicHotkeys()
	}

	if (wParam == lParam) {
		return
	} ; no reason to try to focus any window if the desktop stayed the same
	if (lParam == "__Item") {
		lParam := DllCall(GetCurrentDesktopNumberProc, "Int")
	}
	; Try to restore active window from memory (if it's still on the desktop and is not pinned)
	activeHwnd := WinGetID("A")
	isPinned := DllCall(IsPinnedProc, "Int", activeHwnd)
	oldHwnd := activeWindowByDesktop.Get(lParam, -1)
	isOnDesktop := DllCall(IsWinOnCurrVirtualDesktopProc, "Int", oldHwnd, "Int")
	winClass := WinGetClass("A")
	if (isOnDesktop == 1 && isPinned != 1 && winClass == "Shell_TrayWnd" && oldHwnd != -1) {
		WinActivate("ahk_id " . oldHwnd)
	}
}

tryHotkeyOff(key, action) {
	try {
		Hotkey(key, action, "Off")
	}
}

dynamicKey(a) {
	desktop := -1
	method := "goto"
	if (StrLen(A_ThisHotkey) == 2) {
		desktop := SubStr(A_ThisHotkey, 2) * 1 ; get number from a switching desktop hotkey (win+n)
	} else if (StrLen(A_ThisHotkey) == 3) {
		desktop := SubStr(A_ThisHotkey, 3) * 1 ; get number from a move or move-goto desktop hotkey (win+shift+n or win+ctrl+n)
		if (SubStr(A_ThisHotkey, 1, 2) == "#+") {
			method := "move" ; change method to move
		} else {
			method := "move-goto" ; change methode to move-goto
		}
	} else {
		Return
	}

	desktop := desktop - 1 ; subtract one because desktop programatically is 0-indexed
	Switch method {
		case "goto": GoToDesktopNumber(desktop)
		case "move": MoveCurrentWindowToDesktop(desktop, false)
		case "move-goto": MoveCurrentWindowToDesktop(desktop, true)
	}
}

GenerateDynamicHotkeys() {
	global dCount, GetDesktopCountProc
	i := 0
	while i < dCount { ; the limit of 9 desktops is not applied here in order to clear any unnecessary hotkeys
		key := "#" . i + 1
		keyShift := "#+" . i + 1
		keyAlt := "#^" . i + 1
		l := "d" . i + 1
		; turn off all previous hotkeys (in order to not have too many if a desktop was removed) and ignore if the hotkey does not exist
		tryHotkeyOff(key, "Off")
		tryHotkeyOff(keyShift, "Off")
		tryHotkeyOff(keyAlt, "Off")
		i := i + 1
	}

	; dynamic creation of hotkeys for number of desktops
	dCount := DllCall(GetDesktopCountProc, "Int")
	OutputDebug(dCount)
	i := 0
	while i < dCount && i < 10 { ; limit to 9 desktops, as no one probably needs more than that and because I do not want to implement that now lol
		key := "#" . i + 1
		keyShift := "#+" . i + 1
		keyAlt := "#^" . i + 1
		l := "d" . i + 1
		; turn the hotkeys on (if they were disabled by the "Off" before, they need to be explicitly enabled again (consult Hotkeydocumentation))
		; tryHotkey(key, "On")
		; tryHotkey(keyShift, "On")
		; tryHotkey(keyAlt, "On")
		; set our label for the dynamic key invocation
		Hotkey(key, dynamicKey.Bind(), "On")
		Hotkey(keyShift, dynamicKey.Bind(), "On")
		Hotkey(keyAlt, dynamicKey.Bind(), "On")
		i := i + 1
	}

	TrayTip("(Re-)Generated Desktop Hotkeys", "Generated Hotkeys for " i " desktops", "Mute")
}

GenerateDynamicHotkeys() ; initalisation

; manual keys if necessary

; Switching desktops:
; Win + n = Switch to desktop n
; #1::GoToDesktopNumber(0)

; Moving windows:
; Win + Shift + n = Move current window to desktop n
; #+1::MoveCurrentWindowToDesktop(0, false)

; move windows and move to desktop
; Win + Ctrl + n = move window to desktop n and move to desktop n
; #^1::MoveCurrentWindowToDesktop(0, true)

; restart the windows explorer if the desktop does not react correctly and set the
RestartExplorer(WaitSecs := 10) { ; requires OS Vista+    ; v2.10 by SKAN on CSC7/D39N
	Local PID, Explorer, ID := WinExist("ahk_class Progman") ; @ tiny.cc/restartexplorer2
	PID := WinGetPID()
	Explorer := WinGetProcessPath()
	PostMessage(0x5B4, 0, 0, , "ahk_class Shell_TrayWnd") ; WM_USER+436
	ErrorLevel := ProcessWaitClose(PID, (PID ? WaitSecs : (WaitSecs := 0)))
	If (PID && !Errorlevel) {
		Run(Explorer)
	}
	WinWait("ahk_class Progman", "", WaitSecs)
	Return (WinExist() != ID)
}

#+r::
{
	RestartExplorer()
	; Reload ; so the new explorer process is in the new script
}

#^r::
{
	global GenerateDynamicHotkeys
	GenerateDynamicHotkeys()
}

; Rotate screen to 0 degrees (normal horizontal), 90 degrees (vertical), 180 degrees (horizontal upside down), 270 degrees (vertical upside down)
#F1:: scrRotate(0)
#F2:: scrRotate(90)
#F3:: scrRotate(180)
#F4:: scrRotate(270)

scrRotate(param := "") {
	if !(string(param) ~= "^(?i:0|3|6|9|12|90|180|270|360|default|d|t|r|b|l)$") {
		MsgBox("Valid parameters are: 0,3/6/9/12/90/180/270/360/default/d/t/r/b/l")
		return
	}
	mode := (param = 0) || (param = 12) || (param = 360) || (param = "t") ? 0 ; normal horizontal
		: (param = 9) || (param = 90) || (param = "r") ? 1 ; 90° counterclockwise
			: (param = 6) || (param = 180) || (param = "b") ? 2 ; 180° counterclockwise
				: (param = 3) || (param = 270) || (param = "l") ? 3 ; 270° counterclockwise
					: (param = "default") || (param = "d") ? 0 : 0 ; normal horizontal
	DEVMODE := Buffer(220, 0)
	NumPut("short", 220, DEVMODE, 68)										; dmSize
	DllCall("EnumDisplaySettingsW", "ptr", 0, "int", -1, "ptr", DEVMODE)

	width := NumGet(DEVMODE, 172, "uint")
	height := NumGet(DEVMODE, 176, "uint")

	NumPut("int", width, DEVMODE, 176)
	NumPut("int", height, DEVMODE, 172)
	NumPut("int", mode, DEVMODE, 84)										; dmDisplayOrientation
	DllCall("ChangeDisplaySettingsW", "ptr", DEVMODE, "uint", 0)
}

; Restart the virtual desktop accessor when Explorer.exe crashes, or restarts (e.g. when coming from fullscreen game)
; explorerRestartMsg := DllCall("user32\RegisterWindowMessage", "Str", "TaskbarCreated")
; OnMessage(explorerRestartMsg, OnExplorerRestart)
; OnExplorerRestart(wParam, lParam, msg, hwnd) {
; 	global RestartDesktopDLLProc, GenerateDynamicHotkeys
; 	GenerateDynamicHotkeys()
; 	MsgBox(wParam)
; 	DllCall(RestartDesktopDLLProc, "UInt", wParam)
; }
