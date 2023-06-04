#Requires AutoHotkey v2
#SingleInstance force
#HotString EndChars -\

; Always use folder where the script is
SetWorkingDir(A_ScriptDir)
TraySetIcon(".\icons\vowels.ico")

; https://www.compart.com/de/unicode/block

:?OC:ae::
{
	Send("{U+00E4}")
}

:?OC:oe::
{
	Send("{U+00F6}")
}

:?OC:ue::
{
	Send("{U+00FC}")
}

:?OC:Ae::
{
	Send("{U+00C4}")
}

:?OC:Oe::
{
	Send("{U+00D6}")
}

:?OC:Ue::
{
	Send("{U+00DC}")
}

:?OC:AE::
{
	Send("{U+00C4}")
}

:?OC:OE::
{
	Send("{U+00D6}")
}

:?OC:UE::
{
	Send("{U+00DC}")
}

:?O:ss::
{
	Send("{U+00DF}")
}