#Requires AutoHotkey v2
#SingleInstance force

; Always use folder where the script is
SetWorkingDir(A_ScriptDir)

Run(".\i3help.ah2")
Run(".\desktop.ah2")
Run(".\vowels.ah2")
ExitApp