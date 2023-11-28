;@Ahk2Exe-SetMainIcon .\icons\vowels.ico
;@Ahk2Exe-SetDescription vowels allows you to write german vowels on any keyboard layout

#Include <Base>
InstallKeybdHook()

; Always use folder where the script is
SetWorkingDir(A_ScriptDir)
try {
	TraySetIcon(".\icons\vowels.ico")
}

; https://www.compart.com/de/unicode/block

Hotstring(replacement) {
	OutputDebug(A_ThisHotkey . " ")
	OutputDebug(A_PriorKey . "`n")
	oldVal := SubStr(A_ThisHotkey, InStr(A_ThisHotkey, ":", , , 2) + 1)

	Send(replacement)
	ih := InputHook("L1 T3", "{Backspace}{Left}{Up}{Down}{Right}{End}{Home}{PgUp}{PgDn}{Enter}{Space}{Tab}")
	ih.Start()
	; maybe add listener if window was changed?
	ih.Wait()
	if ih.EndReason = "EndKey" {
		if ih.EndKey = "Backspace" {
			Send(oldVal)
		}
		Return
	}
	; switch SendLevel so that things like ue-ss- work (because otherwise the first s wouldn't be recognized)
	SendLevel(1)
	Send(ih.Input)
	SendLevel(0)
}

:?OCX*:ae-:: Hotstring("ä")
:?OCX*:oe-:: Hotstring("ö")
:?OCX*:ue-:: Hotstring("ü")
:?OCX*:Ae-:: Hotstring("Ä")
:?OCX*:Oe-:: Hotstring("Ö")
:?OCX*:Ue-:: Hotstring("Ü")
:?OCX*:ss-:: Hotstring("ß")
:?OCX*:Ss-:: Hotstring("ẞ")

:?OCX*:AE-:: Hotstring("Ä")
:?OCX*:OE-:: Hotstring("Ö")
:?OCX*:UE-:: Hotstring("Ü")
:?OCX*:SS-:: Hotstring("ẞ")
:?OCX*:AE_:: Hotstring("Ä")
:?OCX*:OE_:: Hotstring("Ö")
:?OCX*:UE_:: Hotstring("Ü")
:?OCX*:SS_:: Hotstring("ẞ")

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