#SingleInstance, force
#Hotstring EndChars -\

; Always use folder where the script is
SetWorkingDir %A_ScriptDir%
Menu, Tray, Icon, .\\icons\vowels.ico

; https://web.archive.org/web/20100526232547/http://www.mknoedel.de:80/lexikon_ASCII-Code.htm

:?OC:ae::
  Send {ASC 0228}
return

:?OC:oe::
  Send {ASC 0246}
return

:?OC:ue::
  Send {ASC 0252}
return

:?OC:Ae::
  Send {ASC 0196}
return

:?OC:Oe::
  Send {ASC 0214}
return

:?OC:Ue::
  Send {ASC 0220}
return

:?OC:AE::
  Send {ASC 0196}
return

:?OC:OE::
  Send {ASC 0214}
return

:?OC:UE::
  Send {ASC 0220}
return

:?O:ss::
  Send {ASC 0223}
return