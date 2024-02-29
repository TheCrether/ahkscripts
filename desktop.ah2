;@Ahk2Exe-SetMainIcon .\icons\desktop.ico
;@Ahk2Exe-SetDescription desktop.ah2 for managing your desktops

#Include <Base>
; this script is based on the example script from here: https://github.com/Ciantic/VirtualDesktopAccessor
InstallKeybdHook()

SetIcon(".\icons\desktop.ico")

DetectHiddenWindows(true)
hwnd := WinExist("ahk_pid " . DllCall("GetCurrentProcessId", "Uint"))
hwnd += 0x1000 << 32

if (!IsWindows11 and not FileExist(".\Lib\VirtualDesktopAccessor.dll")) or
	(IsWindows11 and not FileExist(".\Lib\VirtualDesktopAccessor11.dll")) {
		MsgBox("I couldn't find a VirtualDesktopAccessor.dll in the Lib directory! `n Exiting!")
		ExitApp()
}

hDesktopDLL := ""
if IsWindows11 {
	hDesktopDLL := DllCall("LoadLibrary", "Str", ".\Lib\VirtualDesktopAccessor11.dll", "Ptr")
	try {
		desktopCount := DllCall(GetProc("GetDesktopCount"), "Int")
	} catch {
		Notification("can't load VirtualDesktopAccessor11.dll, tried windows 11 version", "", "Mute")
		ExitApp()
	}
} else {
	hDesktopDLL := DllCall("LoadLibrary", "Str", ".\Lib\VirtualDesktopAccessor.dll", "Ptr")
	try {
		desktopCount := DllCall(GetProc("GetDesktopCount"), "Int")
	} catch {
		Notification("can't load VirtualDesktopAccessor.dll, tried windows 10 version", "", "Mute")
		ExitApp()
	}
}

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
GetWinDesktopNumberProc := GetProc("GetWindowDesktopNumber")
GetDesktopCountProc := GetProc("GetDesktopCount")
activeWindowByDesktop := Map()

MoveWindowToDesktop(hwnd, number, moveWith := false) {
	try {
		DllCall(MoveWinToDesktopNumberProc, "UInt", hwnd, "UInt", number)
		if (moveWith) {
			GoToDesktopNumber(number)
		}

		WinActivate("ahk_class Shell_TrayWnd")
	}
}

MoveCurrentWindowToDesktop(number, moveWith := false) {
	global GetCurrentDesktopNumberProc, MoveWinToDesktopNumberProc, GoToDesktopNumberProc, activeWindowByDesktop

	try {
		activeHwnd := WinGetID("A")
		activeWindowByDesktop[number] := activeHwnd ; Do not activate
		MoveWindowToDesktop(activeHwnd, number, moveWith)
	}
}

GoToDesktopNumber(num) {
	global GetCurrentDesktopNumberProc, GoToDesktopNumberProc, IsPinnedProc, activeWindowByDesktop

	; Store the active window of old desktop, if it is not pinned
	current := DllCall(GetCurrentDesktopNumberProc, "UInt")
	activeHwnd := ""
	try {
		activeHwnd := WinGetID("A")
	}
	if (activeHwnd != "") {
		activeWindowByDesktop[current] := activeHwnd
	}

	; stop if the desktop is already active
	if (current == num) {
		return
	}

	; Try to avoid flashing task bar buttons, deactivate the current window if it is not pinned
	isPinned := 0
	try {
		if (activeHwnd != "") {
			isPinned := DllCall(IsPinnedProc, "UInt", activeHwnd)
		}
	}
	if (isPinned != 1) {
		try {
			WinActivate("ahk_class Shell_TrayWnd")
		}
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

	; no reason to try to focus any window if the desktop stayed the same
	if (wParam == lParam) {
		return
	}
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
		try {
			WinActivate("ahk_id " . oldHwnd)
		}
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
	; OutputDebug(dCount)
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

	Notification("(Re-)Generated Desktop Hotkeys", "Generated Hotkeys for " i " desktops")
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

OnMessage(0x5555, DesktopMessage)

DesktopMessage(wParam, lParam, msg, hwnd) {
	; Notification(Format("Message {1} arrived:`nWPARAM: {2}`nLPARAM: {3}", msg, wParam, lParam))
	; change desktop
	if wParam == 0 {
		GoToDesktopNumber(lParam)
	}
}

#Include <WinHook>

MoveToDesktopHook(desktop, Win_Hwnd, Win_Title, Win_Class, Win_Exe, Win_Event) {
	Sleep(100)
	MoveWindowToDesktop(Win_Hwnd, desktop)
}

GeneralHook(Action, Win_Hwnd, Win_Title, Win_Class, Win_Exe, Win_Event) {
	Action := StrLower(Action)
	Switch Action, "Off" {
		Case "focus":
			WinActivate("ahk_id " . Win_Hwnd)
		default:
			Notification("Action '" . Action . "' is not a general hook`nWindow: " . Win_Title)
	}
}

defaultMoveLock := A_Temp . "\ahkscripts.default-move.done"
hooks := []

AddDefaultMoveHook(desktop, wTitle := "", wClass := "", wExe := "", hosts := [], extraEvents := Map(), excludeTitle := "") {
	hook := AddHook(MoveToDesktopHook.Bind(desktop), wTitle, wClass, wExe, hosts, extraEvents, excludeTitle)
	hook.desktop := desktop
}

AddHook(fn, wTitle := "", wClass := "", wExe := "", hosts := [], extraEvents := Map(), excludeTitle := "") {
	hook := {
		fn: fn,
		wTitle: wTitle,
		wClass: wClass,
		wExe: wExe,
		extraEvents: extraEvents,
		excludeTitle: excludeTitle
	}
	if Type(hosts) = "String" {
		hosts := Trim(hosts)
		if hosts = "" {
			hosts := []
		} else {
			hosts := [hosts]
		}
	}
	if hosts.Length == 0 {
		hooks.Push(hook)
	}
	for host in hosts {
		if InStr(A_ComputerName, host) {
			hooks.Push(hook)
			break
		}
	}
	return hook
}

ExecDefaultMoveHooks(force, ctxMenuArgs*) {
	if force or not FileExist(defaultMoveLock) {
		for hook in hooks {
			if not hook.HasProp("desktop") {
				continue
			}
			title := ""
			if hook.wTitle {
				title := hook.wTitle
			}
			if hook.wClass {
				title .= " ahk_class " . hook.wClass
			}
			if hook.wExe {
				title .= " ahk_exe " . hook.wExe . " "
			}
			list := WinGetList(Trim(title))
			for i in list {
				OutputWindow(i)
			}
			try {
				if hwnd := WinGetID(Trim(title)) {
					MoveWindowToDesktop(hwnd, hook.desktop)
				}
			}
		}
		FileAppend("done", defaultMoveLock)
	}
}

SetupWindowHooks() {
	ExecDefaultMoveHooks(false)
	A_TrayMenu.Add("Execute default hooks", ExecDefaultMoveHooks.Bind(true))

	for hook in hooks {
		WinHook.Shell.Add(hook.fn, hook.wTitle, hook.wClass, hook.wExe, 1, hook.excludeTitle)
		for extraEvent, Fn in hook.extraEvents {
			WinHook.Shell.Add(Fn, hook.wTitle, hook.wClass, hook.wExe, extraEvent, hook.excludeTitle)
		}
	}
}

DebugWindowEvent(Win_Hwnd, Win_Title, Win_Class, Win_Exe, Win_Event) {
	OutputDebug(Format("hwnd: {1}`ntitle: {2}`nClass: {3}`nExe: {4}`nEvent: {5}`n", Win_Hwnd, Win_Title, Win_Class, Win_Exe, Win_Event))
}

AddDefaultMoveHook(2, "Discord", "Chrome_WidgetWin_1", "Discord.exe")
AddDefaultMoveHook(2, "", "", "Spotify.exe")
; WORK
AddDefaultMoveHook(1, "", "", "Element.exe", "IMD")
AddDefaultMoveHook(1, "", "ZPPTMainFrmWndClassEx", "Zoom.exe", "IMD")
AddDefaultMoveHook(1, "3CX.*", , "msedge.exe", "IMD")
AddDefaultMoveHook(1, "", "", "OUTLOOK.EXE", "IMD", , "(Nachricht|Message|Besprechung|Meeting|Erinnerung)")

AddHook(GeneralHook.Bind("focus"), "(Nachricht|Message|Besprechung|Meeting|Erinnerung)", "", "OUTLOOK.EXE", "IMD")
;WORK end
;own pcs
AddDefaultMoveHook(1, "", "TscShellContainerClass", "mstsc.exe", "CRETHER")
AddDefaultMoveHook(0, "", "", "Element.exe", "CRETHER")
AddDefaultMoveHook(0, "", "ZPPTMainFrmWndClassEx", "Zoom.exe", "CRETHER")
AddDefaultMoveHook(0, "3CX - Alle Gruppen - 3CX", , "msedge.exe", "CRETHER")
;own pcs end

; sleep because somehow discord often starts at the same time as this, and the default move doesn't work XD
Sleep(250)
SetupWindowHooks()
#Include <logoff_shutdown_hook>
onLogOff() {
	try {
		FileDelete(defaultMoveLock)
	}
}
SetupShutdownLogoffHook(onLogOff, "both")
; Restart the virtual desktop accessor when Explorer.exe crashes, or restarts (e.g. when coming from fullscreen game)
; explorerRestartMsg := DllCall("user32\RegisterWindowMessage", "Str", "TaskbarCreated")
; OnMessage(explorerRestartMsg, OnExplorerRestart)
; OnExplorerRestart(wParam, lParam, msg, hwnd) {
; 	global RestartDesktopDLLProc, GenerateDynamicHotkeys
; 	GenerateDynamicHotkeys()
; 	MsgBox(wParam)
; 	DllCall(RestartDesktopDLLProc, "UInt", wParam)
; }
