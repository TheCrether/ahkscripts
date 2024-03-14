class ExUtils {
	static GetCurrentExplorerTab(hwnd := WinExist("A")) {
		; script from Lexikos: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=109907
		activeTab := 0
		try activeTab := ControlGetHwnd("ShellTabWindowClass1", hwnd) ; File Explorer (Windows 11)
		catch
			try activeTab := ControlGetHwnd("TabWindowClass1", hwnd) ; IE
		for w in ComObject("Shell.Application").Windows {
			if w.hwnd != hwnd
				continue
			if activeTab { ; The window has tabs, so make sure this is the right one.
				static IID_IShellBrowser := "{000214E2-0000-0000-C000-000000000046}"
				shellBrowser := ComObjQuery(w, IID_IShellBrowser, IID_IShellBrowser)
				ComCall(3, shellBrowser, "uint*", &thisTab := 0)
				if thisTab != activeTab
					continue
			}
			return w
		}
		return false
	}

	static GetCurrentExplorerPath(hwnd := WinExist("A")) {
		tab := this.GetCurrentExplorerTab(hwnd)
		if tab {
			switch Type(tab.Document) {
				case "ShellFolderView":
					return tab.Document.Folder.Self.Path
				default: ; case "HTMLDocument"
					return tab.LocationURL
			}
		}
		; this should never happen
		throw TargetError("No explorer available")
	}

	; TODO w11 add tab with path?
	; TODO copy path of current folder
	; TODO
}