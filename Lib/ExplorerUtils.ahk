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
		/** @var {ComObject} _obj */
		_obj := ""

		/**
		 * create a new instance of ExUtils.Explorer
		 * @param {ComObject} tab the ComObject for the explorer (same as ExUtils.Tab._obj)
		 */
		__New(webBrowser) {
			this._obj := webBrowser
		}

		/** @var {String} Path */
		Path => this.ActiveTab.path
		/** @var {ExUtils.Tab} ActiveTab */
		ActiveTab => ExUtils.GetActiveTab(this._obj.hwnd)

		/**
		 * Opens a new tab and navigates to a path (if specified)
		 * @param {String} path = optional. IF specified, the explorer will try to navigate to the path, otherwise just open a new tab
		 */
		NewTab(path := "") {
			; TODO find better way to make everything through actual code
			; Navigate? Navigate2? with _blank? -> ahk: no, test in PowerShell?
			; clicking the '+' Control?

			; TODO test
			id := "ahk_id " . this._obj.hwnd
			WinActivate(id)
			WinWaitActive(id)

			Send("^t")
			Sleep(250)

			tab := this.ActiveTab
			tab.Path := path
		}
	}

	class Tab {
		/** @var {ComObject} _obj */
		_obj := ""

		/**
		 * create a new instance of ExUtils.Tab
		 * @param {ComObject} tab the ComObject for the tab (same as ExUtils.Explorer._obj)
		 */
		__New(tab) {
			this._obj := tab
		}

		/** @var {ExUtils.Explorer} Explorer */
		Explorer => ExUtils.Explorer(this._obj)
		/** @var {ExUtils.FolderItems} Items */
		Items => this.Folder.Items
		/** @var {ExUtils.Folder} Folder */
		Folder => ExUtils.Folder(this._obj.Document.Folder)

		/** @var {ExUtils.FolderItems} SelectedItems
		 * you can set ExUtils.FolderItem and ExUtils.FolderItems to select items
		 */
		SelectedItems {
			get => ExUtils.FolderItems(this._obj.Document.SelectedItems)
			set => this.SelectItem(value)
		}

		/** @var {String} Path */
		Path {
			get {
				switch Type(this._obj.Document) {
					case "ShellFolderView":
						return this.folder.path
					default: ; case "HTMLDocument"
						return ExUtils.PathFromURL(this._obj.LocationURL)
				}
			}
			set => this._obj.Navigate2(value) ; works on w11 too
		}

		/**
		 * Selects one item or multiple items
		 * MS Docs: https://learn.microsoft.com/en-us/windows/win32/shell/shellfolderview-selectitem
		 * @param {ExUtils.FolderItem | ExUtils.FolderItems} item a FolderItem or collection of FolderItems
		 * @param {Integer} action a combination of what actions should be executed.
		 * 		example: SelectItem(item, 1 | 8) -> selects the item and ensures that it is displayed in the view
		 * 		you can combine the following integers to (de-)select item(s):
		 * 
		 * 			0 = Deselect the item(s),
		 * 			1 = Select the item(s) (default),
		 * 			3 = Put the item in edit mode,
		 * 			4 = Deselect all but the specified item(s),
		 * 			8 = Ensure the item(s) is displayed in the view,
		 * 			16 = Give the item the focus
		 */
		SelectItem(item, action := 1) {
			; describe action (dwFlags)
			this._obj.Document.SelectItem(item._obj, action)
		}
	}

	class Folder {
		/** @var {ComObject} _obj */
		_obj := ""

		/**
		 * create a new instance of ExUtils.Folder
		 * @param {ComObject} tab the ComObject for the explorer (Folder ComObject)
		 */
		__New(folder) {
			this._obj := folder
		}

		/** @var {ExUtils.FolderItems} Items */
		Items => ExUtils.FolderItems(this._obj.Items)

		/** @var {String} Path */
		Path => this.FolderItem.Path

		/** @var {ExUtils.Folder} Parent */
		Parent => ExUtils.Folder(this._obj.ParentFolder)

		/** @var {Integer} OfflineStatus */
		OfflineStatus => this._obj.OfflineStatus

		/** @var {ExUtils.FolderItem} FolderItem */
		FolderItem => ExUtils.FolderItem(this._obj.Self)

		/** @var {Integer} IsLink */
		IsLink => this.FolderItem.IsLink

		/** @var {Integer} ModifyDate */
		ModifyDate => this.FolderItem.ModifyDate

		CopyHere(item, options := 0) {
			; TODO copyHere
			; document the vOptions
		}

		MoveHere(item, options := 0) {
			; TODO MoveHere
			; document the vOptions bits too
		}

		/**
		 * Retrieves details of a FolderItem
		 * MS docs: https://learn.microsoft.com/en-us/windows/win32/shell/folder-getdetailsof
		 * @param folderItem the FolderItem where information should be retrieved
		 * @param detail which information/column should be retrieved (iColumn). Can be supplied in number form or as a string.
		 * 
		 * possible values:
		 * 
		 * 	 0 = "name" -> name of the item
		 * 	 1 = "size" -> size of the item with suffix (KB...)
		 * 	 2 = "type" -> type of the item (example: AutoHotkey Script)
		 * 	 3 = "modified" -> last modified date and time of the time
		 * 	 4 = "attributes" -> attributes of the item
		 * 	-1 = "tip" -> info tip information (the info when hovering over an item): type, size and date modified in one block
		 * 
		 * @returns {String} the specified detail
		 */
		GetDetailsOf(folderItem, detail := 0) {
			; TODO try GetDetailsOf
			; document the detail (iColumn) options
			if Type(detail) == "String" {
				detail := StrLower(detail)
			}

			detail := (detail == 0) || (detail == "name") ? 0 ; retrieve the name
				: (detail == 1) || (detail == "size") ? 1 ; retrieve the size
					: (detail == 2) || (detail == "type") ? 2 ; retrieve the type
					: (detail == 3) || (detail == "modified") ? 3 ; retrieve the last modified date and time
					: (detail == 4) || (detail == "attributes") ? 4 ; retrieve the attrbutes
					: (detail == -1) || (detail == "tip") ? -1 ; retrieve the info tip information
					: 0 ; retrieve the name as default

			return this._obj.GetDetailsOf(folderItem._obj, detail)
		}

		/**
		 * Creates a new folder with the specified name
		 * MS docs: https://learn.microsoft.com/en-us/windows/win32/shell/folder-newfolder
		 * @param {String} name the name of the new folder
		 * @param {Integer} options an optional parameter which is not currently used by Windows
		 */
		NewFolder(name, options := 0) {
			this._obj.NewFolder(name, options)
		}

		/**
		 * Synchronizes all offline files in the folder
		 * MS Docs: https://learn.microsoft.com/en-us/windows/win32/shell/folder2-synchronize
		 */
		Synchronize() {
			this._obj.Synchronize()
		}
	}

	class FolderItems {
		/** @var {ComObject} _obj */
		_obj := ""

		/**
		 * create a new instance of ExUtils.FolderItems
		 * @param {ComObject} tab the ComObject for the folder items collection (FolderItems ComObject)
		 */
		__New(folderItems) {
			this._obj := folderItems
		}

		/** @var {Integer} Length */
		Length => this._obj.Count

		/**
		 * Gets the FolderItem at the specified index
		 * @param i the index of the element that should be returned (starts at 1)
		 * @returns {ExUtils.FolderItem} the wrapped FolderItem
		 */
		__Item[i] {
			get => ExUtils.FolderItem(this._obj.Item(i - 1))
		}

		/**
		 * Enumeration method for FolderItems so you can iterate through the items with a for-loop
		 * @param n the number of arguments for the enumeration
		 * @returns {((&item) => Integer) | (&i, &item) => Integer} returns the FolderItem for one argument and prepends the index of the FolderItem for two arguments
		 */
		__Enum(n) {
			index := 1 ; start at 1 because __Item is implemented to start at 1
			end := this.Length

			switch n {
				case 1: return (&item) => ((index <= end) && (  ; guard
					item := this[index],                         ; yield
					index += 1,                                  ; do block
					True                                         ; continue?
				))

				case 2: return (&i, &item) => ((index <= end) && (
					i := index
					item := this[index],
					index += 1,
					True
				))
			}
		}
	}

	class FolderItem {
		/** @var {ComObject} _obj */
		_obj := ""

		/**
		 * create a new instance of ExUtils.FolderItem
		 * @param {ComObject} tab the ComObject for the folder item (FolderItem ComObject)
		 */
		__New(folderItem) {
			this._obj := folderItem
		}

		/** @var {String} Name */
		Name => this._obj.Name

		/** @var {String} Path */
		Path => this._obj.Path

		/** @var {Integer} IsFolder */
		IsFolder => this._obj.IsFolder

		/** @var {Integer} IsLink */
		IsLink => this._obj.IsLink

		/** @var {String} Type */
		Type => this._obj.Type

		/** @var {ExUtils.Folder} Parent */
		Parent => ExUtils.Folder(this._obj.Parent)

		/** @var {ExUtils.FolderItems} Items */
		Items => this.Folder.Items

		/** @var {String} ModifyDate */
		ModifyTime => this._obj.ModifyDate

		/** @var {Integer} Size */
		Size => this._obj.Size

		/** @var {ExUtils.Folder} Folder */
		Folder {
			get {
				if !this.isFolder {
					throw TargetError("not a folder")
				}
				return ExUtils.Folder(this._obj.GetFolder)
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

	/**
	 * Converts an URL into a filepath
	 * 
	 * example: file:///C:/temp -> C:\temp
	 * @param url the URL to be convreted into a filepath
	 */
	static PathFromURL(url) {
		VarSetStrCapacity(&fPath, Sz := 2084)
		DllCall("shlwapi\PathCreateFromUrl", "Str", url, "Str", fPath, "UIntP", Sz, "UInt", 0)
		return fPath
	}

	/**
	 * Debug output for ComObject classes/interfaces
	 * @param {ComObject} obj the ComObject to be checked
	 */
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
	; folder.NewFolder("hallo")
	; OutputDebug(folder.Parent.Path)
	; tab := ExUtils.GetActiveTab()
	; tab._obj.ExecWB(1, 0)
	; OutputDebug(ControlGetFocus("A"))
	; MsgBox(ControlGetClassNN(ControlGetFocus("A")))
	; controls := WinGetControls("A")
	; for c in controls {
	; 	OutputDebug(c . '`n')
	; }
	; OutputDebug(ControlGetText("Microsoft.UI.Content.DesktopChildSiteBridge2"))
	; for item in tab.Items {
	; 	if item.Name == "ImagePut.ahk" {
	; tab.SelectItem(item, 1 | 4 | 16)
	; OutputDebug(tab.Folder.GetDetailsOf(item, 0) . '`n--`n')
	; OutputDebug(tab.Folder.GetDetailsOf(item, 1) . '`n--`n')
	; OutputDebug(tab.Folder.GetDetailsOf(item, 2) . '`n--`n')
	; OutputDebug(tab.Folder.GetDetailsOf(item, 3) . '`n--`n')
	; OutputDebug(tab.Folder.GetDetailsOf(item, 4) . '`n--`n')
	; OutputDebug(tab.Folder.GetDetailsOf(item, -1) . '`n')

	; 		OutputDebug(tab.Folder.GetDetailsOf(item, "name") . '`n--`n')
	; 		OutputDebug(tab.Folder.GetDetailsOf(item, "size") . '`n--`n')
	; 		OutputDebug(tab.Folder.GetDetailsOf(item, "type") . '`n--`n')
	; 		OutputDebug(tab.Folder.GetDetailsOf(item, "modified") . '`n--`n')
	; 		OutputDebug(tab.Folder.GetDetailsOf(item, "attributes") . '`n--`n')
	; 		OutputDebug(tab.Folder.GetDetailsOf(item, "tip") . '`n')
	; 	}
	; }

	; tab._obj.GetClassInfo(&test)
	; ExUtils._msgInfo(test)
	; for item in tab.SelectedItems {
	; par := item.parent
	; ExUtils._msgInfo(item._obj.Parent)
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
	; explorer._obj.Navigate2("C:\temp\dlm", 65536, "_blank")
	; OutputDebug(explorer.activeTab.path)
	; Sleep(2000)
	; OutputDebug(explorer.activeTab.path)
	; f := tab.selectedItems._obj
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