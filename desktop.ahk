; this script is based on the example script from here: https://github.com/Ciantic/VirtualDesktopAccessor
#SingleInstance, force
DetectHiddenWindows, On
hwnd:=WinExist("ahk_pid " . DllCall("GetCurrentProcessId","Uint"))
hwnd+=0x1000<<32

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
IsPinnedProc := DllCall("IsPinnedWindow")
RestartDesktopDLLProc := DllCall("RestartVirtualDesktopAccessor")
PinProc := DllCall("RestartVirtualDesktopAccessor")
GetWinDesktopNumberProc := DllCall("GetWindowDesktopNumberProc")
activeWindowByDesktop := {}

; Restart the virtual desktop accessor when Explorer.exe crashes, or restarts (e.g. when coming from fullscreen game)
explorerRestartMsg := DllCall("user32\RegisterWindowMessage", "Str", "TaskbarCreated")
OnMessage(explorerRestartMsg, "OnExplorerRestart")
OnExplorerRestart(wParam, lParam, msg, hwnd) {
    global RestartDesktopDLLProc
    DllCall(RestartDesktopDLLProc, UInt, result)
}

MoveCurrentWindowToDesktop(number, move) {
	global MoveWinToDesktopNumberProc, GoToDesktopNumberProc, activeWindowByDesktop
	WinGet, activeHwnd, ID, A
	activeWindowByDesktop[number] := 0 ; Do not activate
	DllCall(MoveWinToDesktopNumberProc, UInt, activeHwnd, UInt, number)
  if (move) {
	  DllCall(GoToDesktopNumberProc, UInt, number)
  }
}

GoToDesktopNumber(num) {
	global GetCurrentDesktopNumberProc, GoToDesktopNumberProc, IsPinnedProc, activeWindowByDesktop

	; Store the active window of old desktop, if it is not pinned
	WinGet, activeHwnd, ID, A
	current := DllCall(GetCurrentDesktopNumberProc, UInt)
	isPinned := DllCall(IsPinnedProc, UInt, activeHwnd)
	if (isPinned == 0) {
		activeWindowByDesktop[current] := activeHwnd
	}

	; Try to avoid flashing task bar buttons, deactivate the current window if it is not pinned
	if (isPinned != 1) {
		WinActivate, ahk_class Shell_TrayWnd
	}

	; Change desktop
	DllCall(GoToDesktopNumberProc, Int, num)
	return
}

; Windows 10 desktop changes listener
DllCall(RegisterPostMessageHookProc, Int, hwnd, Int, 0x1400 + 30)
OnMessage(0x1400 + 30, "VWMess")
VWMess(wParam, lParam, msg, hwnd) {
	global IsWinOnCurrVirtualDesktopProc, IsPinnedProc, activeWindowByDesktop

	desktopNumber := lParam + 1

	; Try to restore active window from memory (if it's still on the desktop and is not pinned)
	WinGet, activeHwnd, ID, A
	isPinned := DllCall(IsPinnedProc, UInt, activeHwnd)
	oldHwnd := activeWindowByDesktop[lParam]
	isOnDesktop := DllCall(IsWinOnCurrVirtualDesktopProc, UInt, oldHwnd, Int)
	if (isOnDesktop == 1 && isPinned != 1) {
		WinActivate, ahk_id %oldHwnd%
	}

	; Menu, Tray, Icon, Icons/icon%desktopNumber%.ico

	; When switching to desktop 1, set background pluto.jpg
	; if (lParam == 0) {
		; DllCall("SystemParametersInfo", UInt, 0x14, UInt, 0, Str, "C:\Users\Jarppa\Pictures\Backgrounds\saturn.jpg", UInt, 1)
	; When switching to desktop 2, set background DeskGmail.png
	; } else if (lParam == 1) {
		; DllCall("SystemParametersInfo", UInt, 0x14, UInt, 0, Str, "C:\Users\Jarppa\Pictures\Backgrounds\DeskGmail.png", UInt, 1)
	; When switching to desktop 7 or 8, set background DeskMisc.png
	; } else if (lParam == 2 || lParam == 3) {
		; DllCall("SystemParametersInfo", UInt, 0x14, UInt, 0, Str, "C:\Users\Jarppa\Pictures\Backgrounds\DeskMisc.png", UInt, 1)
	; Other desktops, set background to DeskWork.png
	; } else {
		; DllCall("SystemParametersInfo", UInt, 0x14, UInt, 0, Str, "C:\Users\Jarppa\Pictures\Backgrounds\DeskWork.png", UInt, 1)
	; }
}

; Switching desktops:
; Win + n = Switch to desktop n
#1::GoToDesktopNumber(0)
#2::GoToDesktopNumber(1)
#3::GoToDesktopNumber(2)
#4::GoToDesktopNumber(3)

; Moving windows:
; Win + Shift + n = Move current window to desktop n
#+1::MoveCurrentWindowToDesktop(0, false)
#+2::MoveCurrentWindowToDesktop(1, false)
#+3::MoveCurrentWindowToDesktop(2, false)
#+4::MoveCurrentWindowToDesktop(3, false)

; move windows and move to desktop
; Win + Ctrl + n = move window to desktop n and move to desktop n
#^1::MoveCurrentWindowToDesktop(0, true)
#^2::MoveCurrentWindowToDesktop(1, true)
#^3::MoveCurrentWindowToDesktop(2, true)
#^4::MoveCurrentWindowToDesktop(3, true)
