#Include <Base>

if A_IsCompiled {
	; TODO check github tags
	ExitApp
}

SetIcon(".\icons\check_for_updates.ico")
setupReloadPaths(".\check_for_updates\check_for_updates.bat", ".\check_for_updates\look_at_git_diff.bat")

CleanString(str) {
	return Trim(RegExReplace(str, "[`r`n]+", ""))
}

CheckForGitUpdate() {
	SetWorkingDir(A_ScriptDir)

	httpOriginCode := RunWait("git remote get-url http-origin", , "Hide")
	if not httpOriginCode { ; httpOriginCode != 0
		RunWait('git remote add http-origin "https://github.com/TheCrether/ahkscripts"', , "Hide")
	} else {
		RunWait('git remote set-url http-origin "https://github.com/TheCrether/ahkscripts"', , "Hide")
	}

	RunWait('git fetch http-origin', , "Hide")

	RunWait(A_ComSpec . ' /c ".\check_for_updates\check_for_updates.bat"', , "Hide")
	; https://stackoverflow.com/a/3278427 checking git status

	if FileExist(".\.error") && Trim(FileRead(".\.error")) {
		Result := MsgBox("There was an error while checking for updates.`nDo you want to look at the logs?", "ahkscripts", "Y/N")
		if Result == "Yes" {
			; TODO open .error file with the default editor
			; with RunWait?
			RunWait(Format('{1} /c "start .error"', A_ComSpec))
			FileDelete(".\.error")
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
		Result := MsgBox("There is an update for ahkscripts available.`nDo you want to update?", "ahkscripts update available", "YesNo")
		if Result == "Yes" {
			Result := MsgBox("Do you want to look at the changes before updating?", "ahkscripts update", "YesNo")
			if Result == "Yes" {
				RunWait(Format('{1} /c ".\check_for_updates\look_at_git_diff.bat {2} {3}"', A_ComSpec, localRev, remoteRev))
				Result := MsgBox("Do you want to update?", "ahkscripts", "YesNo")
				if Result == "Yes" {
					RunWait(A_ComSpec . ' /c "git pull http-origin master & pause"')
				}
			} else {
				RunWait(A_ComSpec . ' /c "git pull http-origin master & pause"')
			}
		}
	} else if remoteRev == baseRev {
		Notification("You need to push your changes`nRun 'git push' to update", "ahkscripts")
	}
}

CheckForGitUpdate()
SetTimer(CheckForGitUpdate, 1000 * 60 * 60 * 12)