;@Ahk2Exe-SetMainIcon .\icons\vowels.ico
;@Ahk2Exe-SetDescription vowels allows you to write german vowels on any keyboard layout

#Include <Base>
#HotString EndChars -\
InstallKeybdHook()

; Always use folder where the script is
SetWorkingDir(A_ScriptDir)
try {
	TraySetIcon(".\icons\vowels.ico")
}

; https://www.compart.com/de/unicode/block

; :?OC:ae::
; {
; 	Send("{U+00E4}")
; }

; :?OC:oe::
; {
; 	Send("{U+00F6}")
; }

; :?OC:ue::
; {
; 	Send("{U+00FC}")
; }

; :?OC:Ae::
; {
; 	Send("{U+00C4}")
; }

; :?OC:Oe::
; {
; 	Send("{U+00D6}")
; }

; :?OC:Ue::
; {
; 	Send("{U+00DC}")
; }

; :?OC:AE::
; {
; 	Send("{U+00C4}")
; }

; :?OC:OE::
; {
; 	Send("{U+00D6}")
; }

; :?OC:UE::
; {
; 	Send("{U+00DC}")
; }

; :?O:ss::
; {
; 	Send("{U+00DF}")
; }

umlaute := Map("u", "ü", "a", "ä", "o", "ö", "s", "ß", "U", "Ü", "U", "Ä", "O", "Ö", "S", "ẞ")

#u:: {
	active := "none"
	try {
		active := WinGetID("A")
	}
	Send("{U+00A8}+{Left}")
	ih := InputHook("L1")
	ih.Start()
	; maybe add listener if window was changed?
	ih.Wait()
	if ih.EndReason = "Stopped" {
		Return
	}
	nowActive := ""
	try {
		nowActive := WinGetID("A")
	}
	if active != nowActive {
		Return
	}
	umlaut := umlaute.Get(ih.Input, "")
	; Send("{Backspace}")
	if umlaut {
		SendText(umlaut)
	} else {
		SendText(ih.Input)
	}
}