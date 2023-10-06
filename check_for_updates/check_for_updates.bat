@ECHO off
@REM call git ls-remote --exit-code http-origin 2> NUL
call git remote get-url http-origin 2> .error
IF "%ERRORLEVEL%" NEQ "0" (
	echo === 'git remote get-url http-origin' ended here === >> .error
	git remote add http-origin "https://github.com/TheCrether/ahkscripts"
) ELSE (
	del .error
)
git fetch --all 2> .error
IF "%ERRORLEVEL%" NEQ "0" (
	echo === 'git fetch --all' ended here >> .error
	exit
) ELSE (
	del .error
)
git rev-parse @ > .local.tmp
git rev-parse --remotes=http-origin "@{upstream}" > .remote.tmp

for /f "delims=" %%a in ('type .remote.tmp') do (
	set remote=%%a
)
@REM clean up .remote.tmp while we're at it
echo %remote% > .remote.tmp

@REM for some reason the output wouldn't work otherwise
>.base.tmp (
	git merge-base @ %remote%
)
