@ECHO off
echo To quit the difference view, press 'Q'. You can navigate with your arrow buttons or with VIM-like bindings (hjkl)
pause
cd temp-ahkscripts
git diff --find-renames %1 %2
cd ..