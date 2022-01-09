; this script is based on the example script from here: https://github.com/Ciantic/VirtualDesktopAccessor
#SingleInstance, force
#InstallKeybdHook

; Always use folder where the script is
SetWorkingDir %A_ScriptDir%
Menu, Tray, Icon, .\\icons\desktop.ico

DetectHiddenWindows, On
hwnd:=WinExist("ahk_pid " . DllCall("GetCurrentProcessId","Uint"))
hwnd+=0x1000<<32

if (FileExist(".\VirtualDesktopAccessor.dll") == "") {
	MsgBox, I couldn't find a VirtualDesktopAccessor.dll in the same directory as the script! `n Exiting!
	Return
}

hDesktopDLL := DllCall("LoadLibrary", Str, ".\VirtualDesktopAccessor.dll", "Ptr")

getProc(funcname) {
  global hDesktopDLL
  return DllCall("GetProcAddress", Ptr, hDesktopDLL, AStr, funcname, "Ptr")
}

GoToDesktopNumberProc := getProc("GoToDesktopNumber")
GetCurrentDesktopNumberProc := GetProc("GetCurrentDesktopNumber")
IsWinOnCurrVirtualDesktopProc := GetProc("IsWindowOnCurrentVirtualDesktop")
MoveWinToDesktopNumberProc := GetProc("MoveWindowToDesktopNumber")
RegisterPostMessageHookProc := GetProc("RegisterPostMessageHook")
UnregisterPostMessageHookProc := GetProc("UnregisterPostMessageHook")
IsPinnedProc := GetProc("IsPinnedWindow")
RestartDesktopDLLProc := GetProc("RestartVirtualDesktopAccessor")
GetWinDesktopNumberProc := GetProc("GetWindowDesktopNumber")
GetDesktopCountProc := GetProc("GetDesktopCount")
activeWindowByDesktop := {}

; Restart the virtual desktop accessor when Explorer.exe crashes, or restarts (e.g. when coming from fullscreen game)
explorerRestartMsg := DllCall("user32\RegisterWindowMessage", "Str", "TaskbarCreated")
OnMessage(explorerRestartMsg, "OnExplorerRestart")
OnExplorerRestart(wParam, lParam, msg, hwnd) {
  global RestartDesktopDLLProc, GenerateDynamicHotkeys
	GenerateDynamicHotkeys()
  DllCall(RestartDesktopDLLProc, UInt, result)
}

MoveCurrentWindowToDesktop(number, move) {
	global GetCurrentDesktopNumberProc, MoveWinToDesktopNumberProc, GoToDesktopNumberProc, activeWindowByDesktop

	current := DllCall(GetCurrentDesktopNumberProc, UInt)


	WinGet, activeHwnd, ID, A
	activeWindowByDesktop[number] := activeHwnd ; Do not activate
	DllCall(MoveWinToDesktopNumberProc, UInt, activeHwnd, UInt, number)
  if (move) {
    GoToDesktopNumber(number)
	  ; DllCall(GoToDesktopNumberProc, UInt, number)
  }

  WinActivate, ahk_class Shell_TrayWnd
}

GoToDesktopNumber(num) {
	global GetCurrentDesktopNumberProc, GoToDesktopNumberProc, IsPinnedProc, activeWindowByDesktop

	; Store the active window of old desktop, if it is not pinned
	WinGet, activeHwnd, ID, A
	current := DllCall(GetCurrentDesktopNumberProc, UInt)
	isPinned := DllCall(IsPinnedProc, UInt, activeHwnd)
	; if (isPinned == 0) {
		activeWindowByDesktop[current] := activeHwnd
	; }

	; Try to avoid flashing task bar buttons, deactivate the current window if it is not pinned
	if (isPinned != 1) {
		WinActivate, ahk_class Shell_TrayWnd
	}

	; Change desktop
	DllCall(GoToDesktopNumberProc, Int, num)
	return
}

dCount := DllCall(GetDesktopCountProc, Int)

; Windows 10 desktop changes listener
DllCall(RegisterPostMessageHookProc, Int, hwnd, Int, 0x1400 + 30)
OnMessage(0x1400 + 30, "VWMess")
VWMess(wParam, lParam, msg, hwnd) { ; wParam is the old desktop and lParam is the new desktop
	global IsWinOnCurrVirtualDesktopProc, IsPinnedProc, activeWindowByDesktop, dCount, GetDesktopCountProc

	currentDCount := DllCall(GetDesktopCountProc, Int)
	; OutputDebug % dCount "vwness"
	if (dCount != currentDCount) {
		GenerateDynamicHotkeys()
	}

	if (wParam == lParam) return ; no reason to try to focus any window if the desktop stayed the same
	; Try to restore active window from memory (if it's still on the desktop and is not pinned)
	WinGet, activeHwnd, ID, A
	isPinned := DllCall(IsPinnedProc, UInt, activeHwnd)
	oldHwnd := activeWindowByDesktop[lParam]
	isOnDesktop := DllCall(IsWinOnCurrVirtualDesktopProc, UInt, oldHwnd, Int)
  WinGetClass, class, A
	if (isOnDesktop == 1 && isPinned != 1 && class == "Shell_TrayWnd") {
		WinActivate, ahk_id %oldHwnd%
	}
}

GenerateDynamicHotkeys() {
	global dCount, GetDesktopCountProc
	i := 0
	while i < dCount { ; the limit of 9 desktops is not applied here in order to clear any unnecessary hotkeys
		key := % "#" i+1
		keyShift := % "#+" i+1
		keyAlt := % "#^" i+1
		l := "d" . i+1
		; turn off all previous hotkeys (in order to not have too many if a desktop was removed) and ignore if the hotkey does not exist
		Hotkey, %key%, Off, UseErrorLevel
		Hotkey, %keyShift%, Off, UseErrorLevel
		Hotkey, %keyAlt%, Off, UseErrorLevel
		i := i + 1
	}

	; dynamic creation of hotkeys for number of desktops
	dCount := DllCall(GetDesktopCountProc, Int)
	OutputDebug % dCount
	i := 0
	while i < dCount && i < 10 { ; limit to 9 desktops, as no one probably needs more than that and because I do not want to implement that now lol
		key := % "#" i+1
		keyShift := % "#+" i+1
		keyAlt := % "#^" i+1
		l := "d" . i+1
		; turn the hotkeys on (if they were disabled by the "Off" before, they need to be explicitly enabled again (consult Hotkeydocumentation))
		Hotkey, %key%, On, UseErrorLevel
		Hotkey, %keyShift%, On, UseErrorLevel
		Hotkey, %keyAlt%, On, UseErrorLevel
		; set our label for the dynamic key invocation
		Hotkey, %key%, dynamicKey
		Hotkey, %keyShift%, dynamicKey
		Hotkey, %keyAlt%, dynamicKey
		i := i + 1
	}
}

GenerateDynamicHotkeys() ; initalisation

dynamicKey:
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
Return

; manual keys if necessary

; Switching desktops:
; Win + n = Switch to desktop n
; #1::GoToDesktopNumber(0)
; #2::GoToDesktopNumber(1)
; #3::GoToDesktopNumber(2)
; #4::GoToDesktopNumber(3)

; Moving windows:
; Win + Shift + n = Move current window to desktop n
; #+1::MoveCurrentWindowToDesktop(0, false)
; #+2::MoveCurrentWindowToDesktop(1, false)
; #+3::MoveCurrentWindowToDesktop(2, false)
; #+4::MoveCurrentWindowToDesktop(3, false)

; move windows and move to desktop
; Win + Ctrl + n = move window to desktop n and move to desktop n
; #^1::MoveCurrentWindowToDesktop(0, true)
; #^2::MoveCurrentWindowToDesktop(1, true)
; #^3::MoveCurrentWindowToDesktop(2, true)
; #^4::MoveCurrentWindowToDesktop(3, true)

; restart the windows explorer if the desktop does not react correctly and set the
RestartExplorer( WaitSecs:=10 ) { ; requires OS Vista+    ; v2.10 by SKAN on CSC7/D39N
  Local PID, Explorer, ID:=WinExist("ahk_class Progman")  ; @ tiny.cc/restartexplorer2
  WinGet, PID, PID
  WinGet, Explorer, ProcessPath
  PostMessage, 0x5B4, 0, 0,, ahk_class Shell_TrayWnd ; WM_USER+436
  Process, WaitClose, %PID%, % ( PID ? WaitSecs : (WaitSecs:=0) )
  If (PID && !Errorlevel)
    Run, %Explorer%
  WinWait, ahk_class Progman,, %WaitSecs%
  Return (WinExist()!=ID)
}

#+r::
  RestartExplorer()
  ; Reload ; so the new explorer process is in the new script
return

#^r::
  global GenerateDynamicHotkeys
  GenerateDynamicHotkeys()
return