@ECHO off
git rev-parse @ > .local.tmp
for /f "delims=" %%a in ('type .local.tmp') do (
	set local=%%a
)

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
git merge-base %local% @ > ..\.base.tmp
cd ..
RMDIR /S /Q temp-ahkscripts