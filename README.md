# ahkscripts

[![Compile AutoHotkey scripts](https://github.com/TheCrether/ahkscripts/actions/workflows/action.yml/badge.svg)](https://github.com/TheCrether/ahkscripts/actions/workflows/action.yml)

I press my i3 shortcuts too often on my Windows machines without a result. That's the one of the reasons I made this repo.

## Prerequisites

- [AutoHotkey](https://www.autohotkey.com/)
  - Version: any **v2** version

## What each file does

### `desktop.ahk`

This uses [Ciantic/VirtualDesktopAccessor][1], a DLL from where you can access Windows Desktop functions. I just put an already built [./VirtualDesktopAccessor.dll](./VirtualDesktopAccessor.dll) in this repository, but you free to build one yourself.

I will refer to `n` as the desktop number, which is limited to 9 in my script because the hotkeys are dynamically created for the number of available desktops (on startup and on addition/removal of desktops) and I can only create shortcuts for 1-9 automatically (key 1 to key 9).

- `Win + n` to switch between desktop
- `Win + Shift + n` to move a window to a desktop
- `Win + Alt + n` to move a window to a desktop and also switch to the desktop

Additionally, it can restart the explorer with `Win + Shift + r` and can rotate your main display:

- `Win + F1` for a normal horizontal display
- `Win + F2` to rotate 90° degrees counterclockwise (normal vertical display)
- `Win + F3` to rotate 180° degrees counterclockwise (flipped horizontal display)
- `Win + F4` to rotate 270° degrees counterclockwise (flipped vertical display)

### `i3help.ahk`

It has the general shortcuts that I use like media control, focusing windows, setting windows to be always-on-top. Example: `Win + a` to activate Discord

### `startall.ahk`

Starts my AutoHotkey scripts at once (useful for autostart)

### `vowels.ahk`

Has the hotstrings for when I use the US keyboard layout (most of the time now) instead of the German keyboard layout.

converts stuff like: `ae` to `ä` with the specified hot strings triggers at the top

## `winhook.ahk`

This script comes from the AutoHotkey forums. It's a really cool script for listening to all kinds of window messages.
[Forum Link][2]

[1]: https://github.com/Ciantic/VirtualDesktopAccessor
[2]: https://www.autohotkey.com/boards/viewtopic.php?f=6&t=59149
