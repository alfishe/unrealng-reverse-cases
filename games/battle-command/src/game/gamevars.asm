; --------------------------------------------------------------------------------------------------------------------
; gamevars.asm: The game's variables in bank 5 below the entry
; --------------------------------------------------------------------------------------------------------------------

; Game variables: the completion flags, world values, the control device
GameVars:
  DEFB $00
MissionsDone:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; nine flags, one per mission 1-9:
                                           ; all non-zero unlock Grand Finale
                                           ; (LoadMissionIfAllowed $759A)
WorldVars:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00
ControlDevice:
  DEFB $04                ; the chosen device 0-4 (ReadControls)
RepeatX:
  DEFB $00                ; frames to the next X step
LastDirections:
  DEFB $00,$00            ; the last direction bits
RepeatY:
  DEFB $00
MousePos:
  DEFB $00,$00            ; the mouse's X and Y (ReadMouse)
MouseDelta:
  DEFB $00
