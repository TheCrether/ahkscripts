;@Ahk2Exe-SetMainIcon .\icons\check_for_updates.ico
;@Ahk2Exe-SetDescription check_for_updates checks for updates to ahkscripts

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
	if httpOriginCode != 0 {
		RunWait('git remote add http-origin "https://github.com/TheCrether/ahkscripts"', , "Hide")
	} else {
		RunWait('git remote set-url http-origin "https://github.com/TheCrether/ahkscripts"', , "Hide")
	}

	RunWait('git fetch http-origin', , "Hide")

	RunWait(A_ComSpec . ' /c ".\check_for_updates\check_for_updates.bat"', , "Hide")

	if FileExist(".\.error") && Trim(FileRead(".\.error")) {
		Result := MsgBox("There was an error while checking for updates.`nDo you want to look at the logs?", "ahkscripts", "Y/N")
		if Result == "Yes" {
			RunWait(Format('{1} /c "start .error"', A_ComSpec))
			FileDelete(".\.error")
			Return
		} else {
			FileDelete(".\.error")
			Return
		}
	}


	try {
		localRev := CleanString(FileRead(".\.local.tmp"))
		remoteRev := CleanString(FileRead(".\.remote.tmp"))
		baseRev := CleanString(FileRead(".\.base.tmp"))
	} catch {
		Notification("ahkscripts was not able to write temporary files. Aborting update-check")
		FileDelete(".\*.tmp")
		Return
	}
	FileDelete(".\*.tmp")
	if FileExist(".\error") {
		FileDelete(".\.error") ; .error gets created even if no error is thrown (thank batch?)
	}

	if localRev == remoteRev {
		Return
	}

	if localRev == baseRev {
		Notification("There is an update for ahkscripts available.`nDo you want to update?", "ahkscripts update available", 0, NotificationClicked.Bind(localRev, remoteRev))
	} else if remoteRev == baseRev {
		Notification("You need to push your changes`nRun 'git push' to update", "ahkscripts")
	}
}

NotificationClicked(localRev, remoteRev) {
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
	RemoveNotificationHandler(NIN_BALLOONUSERCLICK)
}

CheckForGitUpdate()
SetTimer(CheckForGitUpdate, 1000 * 60 * 60 * 12)

CheckForGitUpdateFromCtxMenu(*) {
	CheckForGitUpdate()
}

A_TrayMenu.Add("Check for updates manually", CheckForGitUpdateFromCtxMenu)