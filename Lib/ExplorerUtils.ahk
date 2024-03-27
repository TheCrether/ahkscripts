#Include ".\UIA\UIA.ahk"

global IsWindows11 := 0
if InStr(ExUtils._getCommandOutput('powershell -WindowStyle Hidden -Command "(Get-WmiObject Win32_OperatingSystem).Caption"'), "Windows 11") {
	IsWindows11 := 1
}

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
	; tab.Document.Folder.Items[i].Verbs / tab.Document.SelectedItems[i].Verbs:
	;		FolderItemVerbs: https://learn.microsoft.com/en-us/windows/win32/shell/folderitemverbs
	;		FolderItemVerb: https://learn.microsoft.com/en-us/windows/win32/shell/folderitemverb

	class Explorer extends ExUtils.BaseComObject {
		/**
		 * create a new instance of ExUtils.Explorer
		 * @param {ComObject} tab the ComObject for the explorer (same as ExUtils.Tab._obj)
		 */
		__New(webBrowser) {
			super.__New(webBrowser)
		}

		/** @type {String} */
		Path => this.ActiveTab.path
		/** @type {ExUtils.Tab} */
		ActiveTab => ExUtils.GetActiveTab(this.HWND)
		/** @type {Integer} */
		HWND => this._obj.hwnd

		/**
		 * Opens a new tab and navigates to a path (if specified).
		 * 
		 * Uses UIA to accomplish opening a new tab reliably
		 * @param {String | ExUtils.Folder | ExUtils.FolderItem} path = optional. IF specified, the explorer will try to navigate to the path, otherwise just open a new tab
		 */
		NewTab(path := "") {
			global IsWindows11
			if !IsWindows11 {
				throw TargetError("you are not on a windows 11 machine")
			}

			exEl := UIA.ElementFromHandle(this.HWND)
			exEl.FindElement([{ AutomationId: "AddButton" }]).Click()

			if (path != "") {
				if ExUtils._checkObjectType(path, "Folder(Item)?") {
					path := path.Path
				}
				if Type(path) != "String" {
					throw ValueError("path is not a string")
				}
				Sleep(250) ; maybe make this a while loop that wait until the specified explorer hwnd has more .Windows elements?
				tab := this.ActiveTab
				tab.Path := path
			}
		}
	}

	class Tab extends ExUtils.BaseComObject {
		/**
		 * create a new instance of ExUtils.Tab
		 * @param {ComObject} tab the ComObject for the tab (same as ExUtils.Explorer._obj)
		 */
		__New(tab) {
			super.__New(tab)
		}

		/** @type {ExUtils.Explorer} */
		Explorer => ExUtils.Explorer(this._obj)
		/** @type {ExUtils.FolderItems} */
		Items => this.Folder.Items
		/** @type {ExUtils.Folder} */
		Folder => ExUtils.Folder(this._obj.Document.Folder)

		/**
		 * you can set ExUtils.FolderItem and ExUtils.FolderItems to select items
		 * 
		 * The ComObject in the background will change when the selection changes (even if you save this property, the underlying object will change)
		 * @type {ExUtils.FolderItem | ExUtils.FolderItems}
		 */
		SelectedItems {
			get => ExUtils.FolderItems(this._obj.Document.SelectedItems)
			set => this.SelectItem(value, 4)
		}

		/** @type {String} */
		Path {
			get {
				switch Type(this._obj.Document) {
					case "ShellFolderView":
						return this.folder.path
					default: ; case "HTMLDocument"
						return ExUtils.PathFromURL(this._obj.LocationURL)
				}
			}
			set {
				path := value
				if ExUtils._checkObjectType(value, "Folder(Item)?") {
					path := value.Path
				}
				if Type(path) != "String" {
					throw ValueError("new path not a string")
				}
				this._obj.Navigate2(path) ; works on w11 too
			}
		}

		/**
		 * Selects one item or multiple items
		 * 
		 * MS Docs: https://learn.microsoft.com/en-us/windows/win32/shell/shellfolderview-selectitem
		 * @param {ExUtils.FolderItem | ExUtils.FolderItems} item a FolderItem or collection of FolderItems
		 * @param {Integer} action can be 0 or a combination of what actions should be executed.<br>
		 * 		example: SelectItem(item, 1 | 8) -> selects the item and ensures that it is displayed in the view
		 * 
		 * you can combine the following integers to (de-)select item(s):
		 * 
		 * 			0 = "Deselect the item(s),"
		 * 			1 = "Select the item(s) (default),"
		 * 			3 = "Put the item in edit mode,"
		 * 			4 = "Deselect all but the specified item(s),"
		 * 			8 = "Ensure the item(s) is displayed in the view,"
		 * 			16 = "Give the item the focus"
		 */
		SelectItem(item, action := 1) {
			; describe action (dwFlags)
			this._obj.Document.SelectItem(item._obj, action)
		}
	}

	class Folder extends ExUtils.BaseComObject {
		/**
		 * create a new instance of ExUtils.Folder
		 * @param {ComObject} tab the ComObject for the explorer (Folder ComObject)
		 */
		__New(folder) {
			super.__New(folder)
		}

		/** @type {ExUtils.FolderItems} */
		Items => ExUtils.FolderItems(this._obj.Items)

		/** @type {String} */
		Path => this.FolderItem.Path

		/** @type {ExUtils.Folder} */
		Parent => ExUtils.Folder(this._obj.ParentFolder)

		/** @type {Integer} */
		OfflineStatus => this._obj.OfflineStatus

		/** @type {ExUtils.FolderItem} */
		FolderItem => ExUtils.FolderItem(this._obj.Self)

		/** @type {Integer} */
		IsLink => this.FolderItem.IsLink

		/** @type {Integer} */
		ModifyDate => this.FolderItem.ModifyDate

		/**
		 * Copies file(s)/folder(s) to this objects folder
		 * 
		 * MS docs: https://learn.microsoft.com/en-us/windows/win32/shell/folder-copyhere
		 * @param {String | ExUtils.FolderItem | ExUtils.FolderItems} item the item(s) to be copied. Can be a filename or a FolderItem(s) object
		 * @param {Integer} options the options for the transfer. Can be 0 or a combination of the following integers:<br>
		 * 	Example: folder.CopyHere(item, 16 | 256) -> Always responds "Yes to All" and show a progress box without file names
		 * 
		 * 		4 = "Do not display a progress dialog box"
		 * 		8 = "Give the file being operated on a new name in a move, copy, or rename operation if a file with the target name already exists."
		 * 		16 = "Respond with "Yes to All" for any dialog box that is displayed."
		 * 		64 = "Preserve undo information, if possible."
		 * 		128 = "Perform the operation on files only if a wildcard file name (*.*) is specified."
		 * 		256 = "Display a progress dialog box but do not show the file names."
		 * 		512 = "Do not confirm the creation of a new directory if the operation requires one to be created."
		 * 		1024 = "Do not display a user interface if an error occurs."
		 * 		2048 = "Do not copy the security attributes of the file."
		 * 		4096 = "Only operate in the local directory. Do not operate recursively into subdirectories."
		 * 		8192 = "Do not copy connected files as a group. Only copy the specified files."
		 */
		CopyHere(item, options := 0) {
			check := ExUtils._checkObjectType(item, "FolderItems?")

			if Type(item) != "String" and !check {
				throw ValueError("item not a string, FolderItem or FolderItems object")
			}

			if check {
				item := item._obj
			}

			this._obj.CopyHere(item, options)
		}

		/**
		 * Moves file(s)/folder(s) to this objects folder
		 * 
		 * MS docs: https://learn.microsoft.com/en-us/windows/win32/shell/folder-copyhere
		 * @param {String | ExUtils.FolderItem | ExUtils.FolderItems} item the item(s) to be copied. Can be a filename or a FolderItem(s) object
		 * @param {Integer} options the options for the transfer. Can be 0 or a combination of the following integers:<br>
		 * 	Example: folder.MoveHere(item, 16 | 256) -> Always responds "Yes to All" and show a progress box without file names
		 * 
		 * 		4 = "Do not display a progress dialog box"
		 * 		8 = "Give the file being operated on a new name in a move, copy, or rename operation if a file with the target name already exists."
		 * 		16 = "Respond with "Yes to All" for any dialog box that is displayed."
		 * 		64 = "Preserve undo information, if possible."
		 * 		128 = "Perform the operation on files only if a wildcard file name (*.*) is specified."
		 * 		256 = "Display a progress dialog box but do not show the file names."
		 * 		512 = "Do not confirm the creation of a new directory if the operation requires one to be created."
		 * 		1024 = "Do not display a user interface if an error occurs."
		 * 		2048 = "Do not copy the security attributes of the file."
		 * 		4096 = "Only operate in the local directory. Do not operate recursively into subdirectories."
		 * 		8192 = "Do not move connected files as a group. Only copy the specified files."
		 */
		MoveHere(item, options := 0) {
			check := ExUtils._checkObjectType(item, "FolderItems?")

			if Type(item) != "String" && !check {
				throw ValueError("item not a string, FolderItem or FolderItems object")
			}

			if check == "ExUtils" {
				item := item._obj
			}

			this._obj.MoveHere(item, options)
		}

		/**
		 * gets an item in the folder by its name
		 * 
		 * throws an exception if the item can't be found
		 * @param itemName the name of the item in the folder
		 * @returns {ExUtils.FolderItem} the FolderItem
		 */
		GetItem(itemName) {
			for item in this.Items {
				if (item.Name == itemName) {
					return item
				}
			}

			throw TargetError("Item " . itemName . " could not be found in " . this.Path)
		}

		/**
		 * Retrieves details of a FolderItem
		 * 
		 * MS docs: https://learn.microsoft.com/en-us/windows/win32/shell/folder-getdetailsof
		 * @param {ExUtils.FolderItem} folderItem the FolderItem where information should be retrieved
		 * @param {String | Integer} detail which information/column should be retrieved (iColumn). Can be supplied in number form or as a string.
		 * 
		 * possible values:
		 * 
		 * 	 0 = "name" -> "name of the item"
		 * 	 1 = "size" -> "size of the item with suffix (KB...)"
		 * 	 2 = "type" -> "type of the item (example: AutoHotkey Script)"
		 * 	 3 = "modified" -> "last modified date and time of the time"
		 * 	 4 = "attributes" -> "attributes of the item"
		 * 	-1 = "tip" -> "info tip information (the info when hovering over an item): type, size and date modified in one block"
		 * 
		 * @returns {String} the specified detail
		 */
		GetDetailsOf(folderItem, detail := 0) {
			; type checking
			check := ExUtils._checkObjectType(folderItem, "FolderItem")
			if !check {
				throw ValueError("folderItem is not a FolderItem")
			}

			if Type(detail) != "String" && Type(detail) != "Integer" {
				throw ValueError("details is not a String or Integer")
			}

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

			obj := folderItem
			if check == "ExUtils" {
				obj := folderItem._obj
			}

			return this._obj.GetDetailsOf(folderItem._obj, detail)
		}

		/**
		 * Creates a new folder with the specified name
		 * 
		 * MS docs: https://learn.microsoft.com/en-us/windows/win32/shell/folder-newfolder
		 * @param {String} name the name of the new folder
		 * @param {Integer} options an optional parameter which is not currently used by Windows
		 */
		NewFolder(name, options := 0) {
			this._obj.NewFolder(name, options)
		}

		/**
		 * Synchronizes all offline files in the folder
		 * 
		 * MS Docs: https://learn.microsoft.com/en-us/windows/win32/shell/folder2-synchronize
		 */
		Synchronize() {
			this._obj.Synchronize()
		}
	}

	class FolderItems extends ExUtils.Collection {
		/**
		 * create a new instance of ExUtils.FolderItems
		 * @param {ComObject} tab the ComObject for the folder items collection (FolderItems ComObject)
		 */
		__New(folderItems) {
			super.__New(folderItems)
		}

		/**
		 * list of verbs common to all folder items
		 * @type {ExUtils.FolderItemVerbs}
		 */
		Verbs => ExUtils.FolderItemVerbs(this._obj.Verbs)

		/**
		 * Gets the FolderItem at the specified index
		 * @param i the index of the element that should be returned (starts at 1)
		 * @returns {ExUtils.FolderItem} the wrapped FolderItem
		 */
		__Item[i] {
			get => ExUtils.FolderItem(super[i])
		}

		/**
		 * Enumeration method for FolderItems so you can iterate through the items with a for-loop
		 * @param n the number of arguments for the enumeration
		 * @returns {Enumerator<ExUtils.FolderItem> | Enumerator<Integer, ExUtils.FolderItem>} returns the FolderItem for one argument and prepends the index of the FolderItem for two arguments
		 */
		__Enum(n) {
			return super.__Enum(n)
		}

		/**
		 * filters a FolderItems collection (does not return a new FolderItems object)
		 * 
		 * MS Docs: https://learn.microsoft.com/en-us/windows/win32/shell/folderitems3-filter
		 * @param {Integer} flags can be a combination of the following flags:<br>
		 * 	0x10 = "Windows 7 and later. The calling application is checking for the existence of child items in the folder."<br>
		 *  0x20 = "Include items that are folders in the enumeration."<br>
		 *  0x40 = "Include items that are not folders in the enumeration."<br>
		 *  0x80 = "Include hidden items in the enumeration. This does not include hidden system items. (To include hidden system items, use 0x10000.)"<br>
		 *  0x100 = "No longer used; always assumed. IShellFolder::EnumObjects can return without validating the enumeration object. Validation can be postponed until the first call to IEnumIDList::Next. Use this flag when a user interface might be displayed prior to the first IEnumIDList::Next call. For a user interface to be presented, hwnd must be set to a valid window handle."<br>
		 *  0x200 = "The calling application is looking for printer objects."<br>
		 *  0x800 = "Include items with accessible storage and their ancestors, including hidden items."<br>
		 *  0x1000 = "Windows 7 and later. Child folders should provide a navigation enumeration."<br>
		 *  0x2000 = "Windows Vista and later. The calling application is looking for resources that can be enumerated quickly."<br>
		 *  0x4000 = "Windows Vista and later. Obsolete. Do not use."<br>
		 *  0x8000 = "Windows Vista and later. The calling application is monitoring for change notifications. This means that the enumerator does not have to return all results. Items can be reported through change notifications."<br>
		 *  0x10000 = "Windows 7 and later. Include hidden system items in the enumeration. This value does not include hidden non-system items. (To include hidden non-system items, use SHCONTF_INCLUDEHIDDEN.)""
		 * 
		 * @param {String} filter the wildcard filter to be applied (ex: *.txt)
		 */
		Filter(flags, filter := "*") {
			; TODO Filter test
			if Type(flags) != "Integer" {
				throw ValueError("flags is not an Integer object")
			}
			if Type(filter) != "String" {
				throw ValueError("filter is not a String object")
			}

			this._obj.Filter(flags, filter)
		}

		/**
		 * Executes a FolderItemVerb on a collection of FolderItems (filtered etc.)
		 * 
		 * MS docs: https://learn.microsoft.com/en-us/windows/win32/shell/folderitems2-invokeverbex
		 * @param {String | ExUtils.FolderItemVerb} verb the verb that should be executed. Can be a string or a ExUtils.FolderItemVerb object
		 * @param {String} args optional. arguments for the verb that is being executed
		 */
		InvokeVerbEx(verb, args := "") {
			check := ExUtils._checkObjectType(verb, "FolderItemVerb")
			if !check and Type(name) != "String" {
				throw ValueError("verb not a String or ExUtils.FolderItemVerb")
			}

			name := verb
			if check {
				name := verb.Name
			}

			this._obj.InvokeVerbEx(name, args)
		}
	}

	class FolderItem extends ExUtils.BaseComObject {
		/**
		 * create a new instance of ExUtils.FolderItem
		 * @param {ComObject} tab the ComObject for the folder item (FolderItem ComObject)
		 */
		__New(folderItem) {
			super.__New(folderItem)
		}

		/** @type {String} */
		Name {
			get => this._obj.Name
			set => this._obj.Name := value
		}

		/** @type {String} */
		Path => this._obj.Path

		/** @type {Integer} */
		IsFolder => this._obj.IsFolder

		/** @type {Integer} */
		IsLink => this._obj.IsLink

		/** @type {String} */
		Type => this._obj.Type

		/** @type {ExUtils.Folder} */
		Parent => ExUtils.Folder(this._obj.Parent)

		/** @type {ExUtils.FolderItems} */
		Items => this.Folder.Items

		/** @type {String} */
		ModifyTime => this._obj.ModifyDate

		/** @type {Integer} */
		Size => this._obj.Size

		/** @type {ExUtils.FolderItemVerbs} */
		Verbs => ExUtils.FolderItemVerbs(this._obj.Verbs)

		/** @type {ExUtils.Folder} */
		Folder {
			get {
				if !this.isFolder {
					throw TargetError("not a folder")
				}
				return ExUtils.Folder(this._obj.GetFolder)
			}
		}

		/**
		 * Invokes the specified verb on the folder item
		 * 
		 * MS docs: https://learn.microsoft.com/en-us/windows/win32/shell/folderitem-invokeverb
		 * @param {String | ExUtils.FolderItemVerb} verb the verb to be exectued. Can be the name or the FolderItemVerb object Possible verbs can be retrieved through FolderItem.Verbs
		 */
		InvokeVerb(verb := "") {
			check := ExUtils._checkObjectType(verb, "FolderItemVerb")
			if !check and Type(name) != "String" {
				throw ValueError("verb not a String or FolderItemVerb")
			}

			name := verb
			if check {
				name := verb.Name
			}
			this._obj.InvokeVerb(name)
		}

		/**
		 * invokes the "edit" verb on an item
		 */
		InvokeEdit() {
			this.InvokeVerb("edit")
		}

		/**
		 * invokes the "open" verb on an item and opens the default application (or the application select if none is defined)
		 */
		Open() {
			this.InvokeVerb("open")
		}
	}

	class FolderItemVerbs extends ExUtils.Collection {
		/**
		 * create a new instance of ExUtils.FolderItemVerbs
		 * @param {ComObject} tab the ComObject for the folder item verbs collection (FolderItemVerbs ComObject)
		 */
		__New(verbs) {
			super.__New(verbs)
		}

		/**
		 * Gets the FolderItem at the specified index
		 * @param i the index of the element that should be returned (starts at 1)
		 * @returns {ExUtils.FolderItemVerb} the wrapped FolderItemVerb
		 */
		__Item[i] {
			get => ExUtils.FolderItemVerb(super[i])
		}

		/**
		 * Enumeration method for FolderItems so you can iterate through the items with a for-loop
		 * @param n the number of arguments for the enumeration
		 * @returns {Enumerator<ExUtils.FolderItemVerb> | Enumerator<Integer, ExUtils.FolderItemVerb>} returns the FolderItemVerb for one argument and prepends the index of the FolderItemVerb for two arguments
		 */
		__Enum(n) {
			return super.__Enum(n)
		}
	}

	class FolderItemVerb extends ExUtils.BaseComObject {
		/**
		 * create a new instance of ExUtils.FolderItemVerb
		 * @param {ComObject} tab the ComObject for the verb (FolderItemVerb ComObject)
		 */
		__New(verb) {
			super.__New(verb)
		}

		/** @type {String} */
		Name => this._obj.Name

		/**
		 * Executes a verb on the FolderItem associated with the verb
		 * 
		 * MS docs: https://learn.microsoft.com/en-us/windows/win32/shell/folderitemverb-doit
		 */
		Dolt() {
			this._obj.Dolt()
		}
	}

	/**
	 * Get the current explorer
	 * @param {Integer} hwnd optional. the handle of an explorer window. Defaults to the current window
	 * @returns {ExUtils.Explorer} an Explorer object for the current explorer window
	 */
	static GetCurrentExplorer(hwnd := WinExist("A")) {
		return this.GetActiveTab().explorer
	}

	/**
	 * Get the active tab
	 * @param {Integer} hwnd optional. the handle of an explorer window. Defaults to the current window
	 * @returns {ExUtils.Tab} a Tab object for the active tab
	 */
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

	/**
	 * Get the current path
	 * @param {Integer} hwnd optional. the handle of an explorer window. Defaults to the current window
	 * @returns {String} the current path
	 */
	static GetCurrentPath(hwnd := WinExist("A")) {
		return this.GetActiveTab(hwnd).path
	}

	/**
	 * Get the current folder
	 * @param {Integer} hwnd optional. the handle of an explorer window. Defaults to the current window
	 * @returns {ExUtils.Folder} a Folder object for the current folder
	 */
	static GetCurrentFolder(hwnd := WinExist("A")) {
		return this.GetActiveTab(hwnd).Folder
	}

	/**
	 * Copy the current path into the clipboard
	 * @param {Integer} hwnd optional. the handle of an explorer window. Defaults to the current window
	 */
	static CopyCurrentPath(hwnd := WinExist("A")) {
		path := this.GetCurrentPath(hwnd)
		A_Clipboard := path
	}

	/**
	 * Get the currently selected items
	 * @param {Integer} hwnd optional. the handle of an explorer window. Defaults to the current window
	 * @returns {ExUtils.FolderItems} a FolderItems collection
	 */
	static SelectedItems(hwnd := WinExist("A")) {
		tab := this.GetActiveTab(hwnd)
		return tab.SelectedItems
	}

	/**
	 * Converts an URL into a filepath
	 * 
	 * example: file:///C:/temp -> C:\temp
	 * @param {String} url the URL to be convreted into a filepath
	 */
	static PathFromURL(url) {
		VarSetStrCapacity(&fPath, Sz := 2084)
		DllCall("shlwapi\PathCreateFromUrl", "Str", url, "Str", fPath, "UIntP", Sz, "UInt", 0)
		return fPath
	}

	/**
	 * Converts a filepath to an URL
	 * 
	 * example: C:\temp -> file:///C:/temp
	 * @param {String} fPath the filepath to be converted into an URL
	 */
	static URLFromPath(fPath) {
		VarSetStrCapacity(&url, Sz := 2084)
		DllCall("shlwapi\UrlCreateFromPath", "Str", fPath, "Str", url, "UIntP", Sz, "UInt", 0)
		return url
	}

	/**
	 * get a Folder object by it's path
	 * 
	 * throws a TargetError if the folder can't be found
	 * @param {String} path the path to get a Folder object. Can be one of the special folders: https://learn.microsoft.com/en-us/windows/win32/api/shldisp/ne-shldisp-shellspecialfolderconstants
	 * @returns {ExUtils.Folder} the Folder object
	 */
	static GetFolder(path) {
		; https://learn.microsoft.com/en-us/windows/win32/shell/ishelldispatch-namespace
		shell := ComObject("Shell.Application") ; TODO wrap in IShellDispatch?
		obj := shell.NameSpace(path)
		if !obj {
			throw TargetError("no folder could be found at this path")
		}

		return ExUtils.Folder(obj)
	}

	/**
	 * get a FolderItem by its path
	 * 
	 * throws a TargetError if the folder or the item can't be found
	 * @param {String} path the path of the item
	 * @returns {ExUtils.FolderItem} the FolderItem object
	 */
	static GetFolderItem(path) {
		SplitPath(path, &itemname, &dir)
		return ExUtils.GetFolder(path).GetItem(itemname)
	}

	/**
	 * get a Folder object through a file dialog
	 * 
	 * throws a TargetError if no folder was selected
	 * @param {Integer} ownerHwnd the handle to the parent window of the dialog box. can be 0 (no parent)
	 * @param {String} title the title of the select dialog
	 * @param {Number} options can be a combination of the `ulFlags` field of the BrowseInfoA structure: https://learn.microsoft.com/en-us/windows/win32/api/shlobj_core/ns-shlobj_core-browseinfoa
	 * @param {String} rootFolder the folder where to start from and from where the user can not navigate higher than the specified folder. Defaults to the list of drives<br>(special constants: https://learn.microsoft.com/en-us/windows/win32/api/shldisp/ne-shldisp-shellspecialfolderconstants)
	 * @returns {ExUtils.Folder} the Folder object
	 */
	static GetFolderByDialog(ownerHwnd := 0, title := "Select a folder", options := 0x10 | 0x40, rootFolder := "ssfDRIVES") {
		shell := ComObject("Shell.Application") ; TODO wrap in IShellDispatch
		obj := shell.BrowseForFolder(ownerHwnd, title, options, rootFolder)
		if !obj {
			throw TargetError("no folder was selected")
		}

		return ExUtils.Folder(obj)
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

	/**
	 * gets the class name of an object
	 * @param {Object} obj the object
	 * @returns {String} the class name
	 */
	static _typeOf(obj) {
		if (comClass := ComObjType(obj, "Class")) != "" {
			return comClass
		}
		try { ; `object is Object` is not checked because it can be false for prototypes.
			if ObjHasOwnProp(obj, "__Class") {
				return "Prototype"
			}
		}
		while obj := ObjGetBase(obj) {
			if ObjHasOwnProp(obj, "__Class") {
				return obj.__Class
			}
		}
		return "Object"
	}

	/**
	 * 
	 * @param {Object} obj the object to check
	 * @param {String} objType the name of the type (can be a regex string)
	 * @returns {"ExUtils" | "Com" | false} false if not the correct type, "Com" if it is a ComObject or "ExUtils" if is a wrapped objet
	 */
	static _checkObjectType(obj, objType) {
		_type := ExUtils._typeOf(obj)
		if _type == RegExMatch(_type, "ExUtils\." . objType . "$") {
			return "ExUtils"
		} else if RegExMatch(_type, ".*" . objType . "$") {
			return "Com"
		}
		return false
	}

	class BaseComObject {
		/**
		 * The inner ComObject
		 * @type {ComObject}
		 * */
		_obj := ""

		/**
		 * constructor a simple com object wrapper
		 * @param {ComObject} obj the com object to be set as this._ob
		 */
		__New(obj) {
			this._obj := obj
		}
	}

	class Collection extends ExUtils.BaseComObject {
		/** @type {Integer} */
		Length => this._obj.Count

		/**
		 * Gets the collection item at the specified index
		 * @param i the index of the element that should be returned (starts at 1)
		 * @returns {ComObject} the unwrapped ComObject
		 */
		__Item[i] {
			get => this._obj.Item(i - 1)
		}

		/**
		 * Enumeration method for a collection so you can iterate through the items with a for-loop
		 * @param {Integer} n the number of arguments for the enumeration
		 * @returns {Enumerator<ComObject> | Enumerator<Integer, ComObject>} returns the collection item for one argument and prepends the index of the collection item for two arguments
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

	/**
	 * Executes a command and returns the command output
	 * @param {String} cmd the command to execute
	 * @returns {String} the command output
	 */
	static _getCommandOutput(cmd) {
		before := A_DetectHiddenWindows
		DetectHiddenWindows(1)
		pid := 0
		Run(A_ComSpec, , "Hide", &pid)
		WinWait("ahk_pid " . pid)
		DllCall("AttachConsole", "UInt", pid)
		WshShell := ComObject("Wscript.Shell")
		exec := WshShell.Exec(cmd)
		output := exec.StdOut.ReadAll()
		DllCall("FreeConsole")
		ProcessClose(pid)
		DetectHiddenWindows(before)
		return output
	}
}

; debugging purposes
; ExUtils.toCopy := ""
#HotIf WinActive('ahk_exe explorer.exe') and A_ScriptName == "ExplorerUtils.ahk"
$#^l:: {
	ExUtils.GetCurrentExplorer().NewTab("C:\temp")
}
#HotIf