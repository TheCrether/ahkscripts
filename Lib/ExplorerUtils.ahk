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
		; TODO properties

		_webBrowser := ""

		__New(webBrowser) {
			this._webBrowser := webBrowser
		}
		Path => this.ActiveTab.path

		ActiveTab => ExUtils.GetActiveTab(this._webBrowser.hwnd)

		NewTab(path) {
			; TODO
			; Navigate? Navigate2? wihh _blank?
		}
	}

	class Tab {
		; TODO properties

		_tab := ""

		__New(tab) {
			this._tab := tab
		}

		Explorer => ExUtils.Explorer(this._tab)
		Items => this.Folder.items
		Folder => ExUtils.Folder(this._tab.Document.Folder)

		SelectedItems {
			get => ExUtils.FolderItems(this._tab.Document.SelectedItems)
			set {
				; TODO implement selecting items
				; value
			}
		}

		Path {
			get {
				switch Type(this._tab.Document) {
					case "ShellFolderView":
						return this.folder.path
					default: ; case "HTMLDocument"
						return ExUtils.PathFromURL(this._tab.LocationURL)
				}
			}
			set {
				this._tab.Navigate2(value) ; works on w11 too
			}
		}

		SelectItem(item, action := 1) {
			; TODO SelectItem
			; describe action (dwFlags)
		}
	}

	class Folder {
		; TODO properties

		_folder := ""

		__New(folder) {
			this._folder := folder
		}

		Items => ExUtils.FolderItems(this._folder.Items)
		Path => this.FolderItem.Path
		Parent => ExUtils.Folder(this._folder.ParentFolder)
		OfflineStatus => this._folder.OfflineStatus
		FolderItem => ExUtils.FolderItem(this._folder.Self)
		IsLink => this.FolderItem.IsLink
		ModifyDate => this.FolderItem.ModifyDate

		CopyHere(item, options := 0) {
			; TODO copyHere
			; document the vOptions
		}

		MoveHere(item, options := 0) {
			; TODO MoveHere
			; document the vOptions bits too
		}

		GetDetailsOf(folderItem, detail) {
			; TODO GetDetailsOf
			; document the detail (iColumn) options
		}

		NewFolder(name, options := 0) {
			this._folder.NewFolder(name) ; TODO check
		}

		Synchronize() {
			this._folder.Synchronize()
		}
	}

	class FolderItems {
		_folderItems := ""

		__New(folderItems) {
			this._folderItems := folderItems
		}

		Length => this._folderItems.Count

		__Item[i] {
			get => ExUtils.FolderItem(this._folderItems.Item(i - 1))
		}

		__Enum(n) {
			index := 1 ; start at 1 because __Item is implemented to start at 1
			end := this.Length

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
		_folderItem := ""

		__New(folderItem) {
			this._folderItem := folderItem
		}

		Path => this._folderItem.Path
		IsFolder => this._folderItem.IsFolder
		IsLink => this._folderItem.IsLink
		Type => this._folderItem.Type
		Parent => ExUtils.Folder(this._folderItem.Parent)
		Items => this.Folder.Items
		ModifyTime => this._folderItem.ModifyDate
		Size => this._folderItem.Size

		Folder {
			get {
				if !this.isFolder {
					throw TargetError("not a folder")
				}
				return ExUtils.Folder(this._folderItem.GetFolder)
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

	static GetCurrentFolder(hwnd := WinExist("A")) {
		return this.GetActiveTab().Folder
	}

	static CopyCurrentPath(hwnd := WinExist("A")) {
		path := this.GetCurrentPath(hwnd)
		A_Clipboard := path
	}

	static SelectedItems(hwnd := WinExist("A")) {
		tab := this.GetActiveTab(hwnd)
		return tab.SelectedItems
	}

	static PathFromURL(url) { ; TODO test
		VarSetStrCapacity(&fPath, Sz := 2084)
		DllCall("shlwapi\PathCreateFromUrl", "Str", url, "Str", fPath, "UIntP", Sz, "UInt", 0)
		return fPath
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
}

; debugging purposes
#HotIf WinActive('ahk_exe explorer.exe')
$#^l:: {
	; folder := ExUtils.GetCurrentFolder()
	; OutputDebug(folder.Parent.Path)
	; tab := ExUtils.GetActiveTab()
	; tab._tab.GetClassInfo(&test)
	; ExUtils._msgInfo(test)
	; for item in tab.SelectedItems {
	; par := item.parent
	; ExUtils._msgInfo(item._folderItem.Parent)
	; for item2 in item.Parent.Items {
	; 	OutputDebug(item2.Parent.Path)
	; }
	; if item.isFolder {
	; 	for i2 in item.items {
	; 		OutputDebug(i2.path)
	; 	}
	; }
	; }
	; tab.path := "C:\temp"
	; explorer := ExUtils.GetCurrentExplorer()
	; explorer._webBrowser.Navigate2("C:\temp\dlm", 65536, "_blank")
	; OutputDebug(explorer.activeTab.path)
	; Sleep(2000)
	; OutputDebug(explorer.activeTab.path)
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