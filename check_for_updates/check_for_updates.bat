@ECHO off
git rev-parse @ > .local.tmp

RMDIR /S /Q temp-ahkscripts
git clone "https://github.com/TheCrether/ahkscripts" temp-ahkscripts 2> .error
IF "%ERRORLEVEL%" NEQ "0" (
	echo === 'git clone "https://github.com/TheCrether/ahkscripts" temp-ahkscripts' ended here === >> .error
	exit
) ELSE (
	del .error
)

cd temp-ahkscripts
git rev-parse @ > ..\.remote.tmp
cd ..
RMDIR /S /Q temp-ahkscripts

for /f "delims=" %%a in ('type .remote.tmp') do (
	set remote=%%a
)

@REM for some reason the output wouldn't work otherwise
>.base.tmp (
	git merge-base @ %remote%
)
