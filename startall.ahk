#SingleInstance, force

; Always use folder where the script is
SetWorkingDir %A_ScriptDir%

Run, i3help.ahk
Run, desktop.ahk
Run, vowels.ahk
ExitApp