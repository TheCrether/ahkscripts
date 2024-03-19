class ExUtils {
	; Windows Documentation Links in the explorer context:
	; tab:
	; 	IWebBrowser2: https://learn.microsoft.com/en-us/previous-versions/windows/internet-explorer/ie-developer/platform-apis/aa752127(v=vs.85)
	; tab.Document:
	; 	ShellFolderView: https://learn.microsoft.com/en-us/windows/win32/shell/shellfolderview
	; tab.Document.Folder:
	;		ShellFolderView.Folder: https://learn.microsoft.com/en-us/windows/win32/shell/shellfolderview-folder
	; 	Folder: https://learn.microsoft.com/en-us/windows/win32/shell/folder
	;		Folder2: https://learn.microsoft.com/en-us/windows/win32/shell/folder2-object
	;		Folder3 (win11): https://microsoft.github.io/windows-docs-rs/doc/windows/Win32/UI/Shell/struct.Folder3.html
	; tab.Document.Folder.Self
	;		Folder2.Self: https://learn.microsoft.com/en-us/windows/win32/shell/folder2-self
	;		FolderItem: https://learn.microsoft.com/en-us/windows/win32/shell/folderitem
	; tab.Document.SelectedItems:
	;		ShellFolderView.SelectedItems: https://learn.microsoft.com/en-us/windows/win32/shell/shellfolderview-selecteditems
	;		FolderItems: https://learn.microsoft.com/en-us/windows/win32/shell/folderitems
	;		FolderItems2: https://learn.microsoft.com/en-us/windows/win32/shell/folderitems2-object
	;		FolderItems3: https://learn.microsoft.com/en-us/windows/win32/shell/folderitems3-object
	;		FolderItem: https://learn.microsoft.com/en-us/windows/win32/shell/folderitem

	class Explorer {
		_webBrowser := ""

		__New(webBrowser) {
			this._webBrowser := webBrowser
		}

		activeTab => ExUtils.Tab(ExUtils.GetActiveTab(this._webBrowser.hwnd)) ; TODO test

		NewTab(path) {
			; TODO
			; Navigate? Navigate2? wihh _blank?
		}
	}

	class Tab {
		_tab := ""

		__New(tab) {
			this._tab := tab
		}

		folder => ExUtils.Folder(this._tab.Document.Folder)

		selectedItems {
			get => ExUtils.FolderItems(this._tab.Document.SelectedItems)
			set {
				; TODO implement selecting items
				; value
			}
		}

		items => this.folder.items

		path {
			get {
				switch Type(this._tab.Document) {
					case "ShellFolderView":
						return this.folder.path
					default: ; case "HTMLDocument"
						return this._tab.LocationURL
				}
			}
			set {
				; TODO implement navigating
				; this._tab.Navigate(value)
				this._tab.Navigate2(value) ; check if this works on w11
			}
		}

		explorer => ExUtils.Explorer(this._tab)
	}

	class Folder {
		_folder := ""

		__New(folder) {
			this._folder := folder
		}

		items => ExUtils.FolderItems(this._folder.Items)

		path => this._folder.Self.Path
	}

	class FolderItems {
		; TODO
		_folderItems := ""

		__New(folderItems) {
			this._folderItems := folderItems
		}

		__Item[i] {
			get => ExUtils.FolderItem(this._folderItems.Item(i - 1))
		}

		__Enum(n) {
			index := 1 ; start at 1 because __Item is implemented to start at 1
			end := this._folderItems.Count

			switch n {
				case 1: return (&item) => ((index <= end) && (  ; guard
					item := this[index],                         ; yield
					index += 1,                                  ; do block
					True                                         ; continue?
				))

				case 2: return (&item, &path) => ((index <= end) && (
					item := this[index],
					path := item.path,
					index += 1,
					True
				))
			}
		}
	}

	class FolderItem {
		folderItem := ""

		__New(folderItem) {
			this.folderItem := folderItem
		}

		; TODO implement properties

		path => this.folderItem.Path
		isFolder => this.folderItem.IsFolder
		isLink => this.folderItem.IsLink
		type => this.folderItem.Type
		parent => ExUtils.Folder(this.folderItem.Parent)
		items {
			get {
				if this.isFolder {
					return ExUtils.Folder(this.folderItem.GetFolder).items
				}
				throw TargetError("not a folder")
			}
		}
	}

	static GetCurrentExplorer(hwnd := WinExist("A")) {
		return this.GetActiveTab().explorer
	}

	static GetActiveTab(hwnd := WinExist("A")) {
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
			return this.Tab(w)
		}
		; TODO think what might be the best: false, traytip, error?
		; return false
		throw TargetError("No explorer focused")
	}

	static GetCurrentPath(hwnd := WinExist("A")) {
		return this.GetActiveTab(hwnd).path
	}

	static CopyCurrentPath(hwnd := WinExist("A")) {
		path := this.GetCurrentPath(hwnd)
		A_Clipboard := path
	}

	static SelectedItems(hwnd := WinExist("A")) {
		tab := this.GetActiveTab(hwnd)
		return tab.SelectedItems
	}

	static _msgInfo(obj) {
		text :=
			(
				"Variant type:`t" ComObjType(obj) "
    Interface name:`t" ComObjType(obj, "Name") "
    Interface ID:`t" ComObjType(obj, "IID") "
    Class name:`t" ComObjType(obj, "Class") "
    Class ID (CLSID):`t" ComObjType(obj, "CLSID")
			)
		OutputDebug(text . "`n")
	}

	; TODO w11 add tab with path?
	; TODO wrap all the different things in classes?
}

; debugging purposes
#HotIf WinActive('ahk_exe explorer.exe')
$#^l:: {
	tab := ExUtils.GetActiveTab()
	for item in tab.SelectedItems {
		; par := item.parent
		; ExUtils._msgInfo(item.folderItem)
		if item.isFolder {
			for i2 in item.items {
				OutputDebug(i2.path)
			}
		}
	}
	; tab.path := "C:\temp"
	; f := tab.selectedItems._folderItems
	; a := f.Item(2)
	; OutputDebug(a.Path)
	; OutputDebug("asdf")
	; OutputDebug(tab.selectedItems[1])
	; tab.selectedItems := "asdf"
	; OutputDebug(ExUtils.GetCurrentPath())
	; tab := ExUtils.GetActiveTab()
	; items := []
	; for item in tab.SelectedItems {
	; 	OutputDebug(item.Path)
	; }
	; OutputDebug(tab.Document.PopupItemMenu(items[1]) . "`n")
}
#HotIf