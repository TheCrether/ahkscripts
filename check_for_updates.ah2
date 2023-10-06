#Include <Base>

if A_IsCompiled {
	; TODO check github tags
	ExitApp
}

SetIcon(".\icons\check_for_updates.ico")
; setupReloadPaths("./check_for_updates.bat")

CleanString(str) {
	return Trim(RegExReplace(str, "[`r`n]+", ""))
}

CheckForGitUpdate() {
	SetWorkingDir(A_ScriptDir)
	RunWait(A_ComSpec . ' /c ".\check_for_updates\check_for_updates.bat"', , "Hide")
	; https://stackoverflow.com/a/3278427 checking git status

	if FileExist(".\.error") && Trim(FileRead(".\.error")) {
		Result := MsgBox("There was an error while checking for updates.`nDo you want to look at the logs or should they be deleted?", "ahkscripts", "Y/N")
		if Result == "Yes" {
			; TODO open .error file with the default editor
			; with RunWait?
			Return
		} else {
			FileDelete(".\.error")
			Return
		}
	}


	localRev := CleanString(FileRead(".\.local.tmp"))
	remoteRev := CleanString(FileRead(".\.remote.tmp"))
	baseRev := CleanString(FileRead(".\.base.tmp"))
	FileDelete(".\*.tmp")
	if FileExist(".\error") {
		FileDelete(".\.error") ; .error gets created even if no error is thrown (thank batch?)
	}

	if localRev == remoteRev {
		Return
	}

	if localRev == baseRev {
		Result := MsgBox("There is an update for ahkscripts available.`nDo you want to 'git pull' and update?", "ahkscripts update available", "YesNo")
		if Result == "Yes" {
			Result := MsgBox("Do you want to look at the changes before updating?", "Have a look?", "YesNo")
			if Result := "No" {
				RunWait(A_ComSpec . ' /c "git pull & pause"')
				Return
			}
			; TODO display list of changes
			; RunWait(A_ComSpec . ' /c ".\check_for_updates\look_at_git_diff"')
			RunWait(Format('{1} /c "echo To quit the difference view, press `'Q`'. You can navigate with your arrow buttons or with VIM-like bindings (hjkl) & pause & git diff {2} {3}', A_ComSpec, localRev, remoteRev))
		}
	} else if remoteRev == baseRev {
		Notification("You need to push your changes`nRun 'git push' to update", "ahkscripts")
	}
}

CheckForGitUpdate()
SetTimer(CheckForGitUpdate, 1000 * 60 * 60 * 24)