# ahkscripts

[![Compile AutoHotkey scripts](https://github.com/TheCrether/ahkscripts/actions/workflows/action.yml/badge.svg)](https://github.com/TheCrether/ahkscripts/actions/workflows/action.yml)

I press my i3 shortcuts too often Windows without a result. That's the one of the reasons I made this repo.

## What each file does

### `desktop.ahk`

This uses [Ciantic/VirtualDesktopAccessor][1], a DLL from where you can access Windows Desktop functions. I just put an already built [./VirtualDesktopAccessor.dll](./VirtualDesktopAccessor.dll) in this repository, but you can of course build one yourself.

I will refer to `n` as the desktop number, which is limited to 4 in my script, but you can easily use more by duplicating the necessary line at the bottom of the file

- `Win + n` to switch between desktop
- `Win + Shift + n` to move a window to a desktop
- `Win + Alt + n` to move a window to a desktop and also switch to the desktop

### `i3help.ahk`

It has the general shortcuts that I use. Example: `Win + a` to activate Discord

### `lulz.ahk`

Just a dumb thing that opens Opera lul

### `startall.ahk`

Starts my AutoHotkey scripts at once (useful for autostart)

### `vowels.ahk`

Has the hotstrings for when I use the US keyboard layout (most of the time now) instead of the German keyboard layout.

converts stuff like: `ae` to `ä` with the specified hot strings at the top

## `winhook.ahk`

This script comes from the AutoHotkey forums. It's a really cool script for listening to all kinds of window messages.
[Forum Link][2]

[1]: https://github.com/Ciantic/VirtualDesktopAccessor
[2]: https://www.autohotkey.com/boards/viewtopic.php?f=6&t=59149
