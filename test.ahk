 ; Easy to make GUIs
  Gui, Add, Text, , Enter your name
  Gui, Add, Edit, vName w150
  Gui, Add, Button, , OK
  Gui, Show
  Return
 
ButtonOK:
  Gui, Submit, Destroy
  MsgBox Hello %Name%
 Return
 
Esc::
GuiClose:
ExitApp