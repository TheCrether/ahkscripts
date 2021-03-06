; this script is based on the example script from here: https://github.com/Ciantic/VirtualDesktopAccessor
#SingleInstance, force

; Always use folder where the script is
SetWorkingDir %A_ScriptDir%
Menu, Tray, Icon, .\\icons\desktop.ico

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

; Windows 10 desktop changes listener
DllCall(RegisterPostMessageHookProc, Int, hwnd, Int, 0x1400 + 30)
OnMessage(0x1400 + 30, "VWMess")
VWMess(wParam, lParam, msg, hwnd) {
	global IsWinOnCurrVirtualDesktopProc, IsPinnedProc, activeWindowByDesktop

	; Try to restore active window from memory (if it's still on the desktop and is not pinned)
	WinGet, activeHwnd, ID, A
	isPinned := DllCall(IsPinnedProc, UInt, activeHwnd)
	oldHwnd := activeWindowByDesktop[lParam]
	isOnDesktop := DllCall(IsWinOnCurrVirtualDesktopProc, UInt, oldHwnd, Int)
  WinGetClass, class, A
	if (isOnDesktop == 1 && isPinned != 1 && class == "Shell_TrayWnd") {
		WinActivate, ahk_id %oldHwnd%
	}

	; desktopNumber := lParam + 1
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
  RestartExplorer(10)
	Reload ; so the new explorer process is in the new script
return