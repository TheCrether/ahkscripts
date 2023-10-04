@ECHO off
git fetch
git rev-parse @ > .local.tmp
git rev-parse "@{upstream}" > .remote.tmp
git merge-base @ "@{upstream}" > .base.tmp
