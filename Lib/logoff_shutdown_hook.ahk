#Requires AutoHotkey v2

SetupShutdownLogoffHook(Fn, events := "both") {
	OnMessage(0x0011, On_WM_QUERYENDSESSION)
	DllCall("kernel32.dll\SetProcessShutdownParameters", "UInt", 0x4FF, "UInt", 0)
	OnMessage(0x0011, On_WM_QUERYENDSESSION)
	On_WM_QUERYENDSESSION(wParam, lParam, *)
	{
		ENDSESSION_LOGOFF := 0x80000000
		if (lParam & ENDSESSION_LOGOFF) { ; User is logging off.
			EventType := "logoff"
		} else { ; System is either shutting down or restarting.
			EventType := "shutdown"
		}

		if events = EventType or events = "both" {
			Fn()
		}
		return true
	}
}