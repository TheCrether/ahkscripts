;@Ahk2Exe-SetMainIcon .\icons\vowels.ico
;@Ahk2Exe-SetDescription vowels allows you to write german vowels on any keyboard layout

#Include <Base>
#HotString EndChars -
InstallKeybdHook()

; Always use folder where the script is
SetWorkingDir(A_ScriptDir)
try {
	TraySetIcon(".\icons\vowels.ico")
}

; https://www.compart.com/de/unicode/block

Hotstring(replacement) {
	OutputDebug(A_ThisHotkey)
	oldVal := SubStr(A_ThisHotkey, InStr(A_ThisHotkey, ":", , , 2) + 1)

	Send(replacement)
	ih := InputHook("L1 T1", "{Backspace}")
	ih.Start()
	; maybe add listener if window was changed?
	ih.Wait()
	if ih.EndReason = "EndKey" {
		Send(oldVal . "-")

		Return
	}

	Send(ih.Input)
}

:?OC:ae:: {
	Hotstring("ä")
}
:?OC:oe:: {
	Hotstring("ö")
}
:?OC:ue:: {
	Hotstring("ü")
}
:?OC:Ae:: {
	Hotstring("Ä")
}
:?OC:Oe:: {
	Hotstring("Ö")
}
:?OC:Ue:: {
	Hotstring("Ü")
}
:?OC:AE:: {
	Hotstring("Ä")
}
:?OC:OE:: {
	Hotstring("Ö")
}
:?OC:UE:: {
	Hotstring("Ü")
}
:?OC:ss:: {
	Hotstring("ß")
}
:?OC:Ss:: {
	Hotstring("ẞ")
}
:?OC:SS:: {
	Hotstring("ẞ")
}

umlaute := Map("u", "ü", "a", "ä", "o", "ö", "s", "ß", "U", "Ü", "U", "Ä", "O", "Ö", "S", "ẞ")

#u:: {
	active := "none"
	try {
		active := WinGetID("A")
	}
	Send("{U+00A8}")
	ih := InputHook("L1", "{Enter}{Esc}{Backspace}")
	ih.Start()
	; maybe add listener if window was changed?
	ih.Wait()
	if ih.EndReason = "Stopped" {
		Return
	}
	if ih.EndReason = "EndKey" {
		if ih.EndKey != "Backspace"
			Send("{Backspace}")
	}
	nowActive := ""
	try {
		nowActive := WinGetID("A")
	}
	if active != nowActive {
		Return
	}
	OutputDebug(ih.Input . " " . Ord(ih.Input))
	umlaut := umlaute.Get(ih.Input, "")
	; Send("{Backspace}")
	if umlaut {
		Send("{Backspace}")
		SendText(umlaut)
	} else {
		Send(ih.Input)
	}
}