; --------------------------------------------------------------------------------------------------------------------
; options.asm: The selections: one or two players
;
; MenuKeys reads the keys 1, 2 and 3 of the title: one player, two players, the key definition. SelectPlayers stores
; the number in $7F9B and shows the selections screen with a colour bar sweeping the chosen line.
; --------------------------------------------------------------------------------------------------------------------

; Read the menu keys 1-3
;
; 1: SelectOnePlayer, 2: SelectTwoPlayers, 3: RedefineKeys. Registers kept.
; Used by the title loop (CreditsPage).
MenuKeys:
  PUSH AF
  PUSH HL
  PUSH DE
  PUSH BC
  LD A,$F7                ; 1, 2, 3 are bits 0-2 of $F7FE
  IN A,($FE)
  RRA
  CALL NC,SelectOnePlayer
  RRA
  CALL NC,SelectTwoPlayers
  RRA
  CALL NC,RedefineKeys
  POP BC
  POP DE
  POP HL
  POP AF
  RET

; Select the one player game
;
; A = 1, then as SelectTwoPlayers.
SelectOnePlayer:
  PUSH AF
  LD A,$01
  JR SelectPlayers

; Select the two player game
;
; SelectPlayers with A = 2.
;
; Stores A in $7F9B, clears the screen, colours $82A7 (48 lines) into $FC20 and
; $82D7 (64 lines) into $FC50, 112 raster lines, message 19 (SELECTIONS, 1
; PLAYER, 2 PLAYERS). Then 8 x 16 steps of 2 frames: the bar $82E0 expanded
; twice (32 lines) a line higher each step under the chosen line ($FC68 one
; player, $FC88 two), about 5 seconds. Then WaitMenuRasterEnd and ClearScreen.
SelectTwoPlayers:
  PUSH AF
  LD A,$02
; This entry point is used by the routine at SelectOnePlayer.
SelectPlayers:
  LD (Players),A          ; A: the players
  CALL ClearScreen
  CALL ClearColourBuffer
  LD HL,ColoursTop
  LD DE,MenuColours
  LD (RasterTable),DE
  LD B,$30
  CALL ExpandColours
  LD HL,ColoursHighlight
  LD DE,MenuColours+$0030
  LD B,$40
  CALL ExpandColours
  LD A,$70
  LD (RasterLines),A
  CALL SetMenuRaster
  LD HL,ColoursBar        ; the bar's colours
  LD (RasterList),HL
  LD DE,MenuColours+$0048 ; under 1 PLAYER
  LD A,(Players)
  DEC A
  JR Z,SelectPlayersShow
  LD DE,MenuColours+$0068 ; under 2 PLAYERS
SelectPlayersShow:
  LD A,$13                ; SELECTIONS
  CALL PrintMessage
  LD B,$08
SelectPlayersSweep:
  PUSH BC
  PUSH DE
  LD B,$10
SelectPlayersStep:
  HALT                    ; every 2 frames
  HALT
  PUSH BC
  PUSH DE
  LD B,$10
  CALL ExpandNextColours
  LD B,$10
  CALL ExpandNextColours
  POP DE
  DEC DE                  ; a line higher
  POP BC
  DJNZ SelectPlayersStep
  POP DE
  POP BC
  DJNZ SelectPlayersSweep
  CALL WaitMenuRasterEnd
  CALL ClearScreen
  POP AF
  RET
