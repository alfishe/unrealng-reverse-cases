; --------------------------------------------------------------------------------------------------------------------
; gamevars.asm: The game's variables in bank 5 below the entry
; --------------------------------------------------------------------------------------------------------------------

; Game variables: the completion flags, world values, the control device
GameVars:
  DEFB $00
MissionsDone:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; ten flags, one per mission 1-10
  DEFB $00                                 ; (MissionCompleteScreen writes
                                           ; $6799 + mission, EncodePassword
                                           ; reads all ten); the first nine all
                                           ; non-zero unlock Grand Finale
                                           ; (LoadMissionIfAllowed $759A)
WorldVars:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00
ControlDevice:
  DEFB $04                ; the chosen device 0-4 (ReadControls)
RepeatY:
  DEFB $00                ; frames to the next Y step (DecodeDirections,
                          ; docs/05-controls.md 5.3)
LastDirections:
  DEFB $00,$00            ; the last direction bits
RepeatX:
  DEFB $00                ; frames to the next X step
MousePos:
  DEFB $00,$00            ; the mouse's X and Y (ReadMouse)
MouseDelta:
  DEFB $00                ; shared: the mouse delta (ReadMouse) and the polygon
                          ; fill's bottom row (FillPolygon, bank 3)
