; --------------------------------------------------------------------------------------------------------------------
; ending.asm: GAME OVER's text
;
; GAME OVER (the code is GameOver, $7E1E, in MainLoopPause) shows this text twice: falling into the view and then
; printed on the screen.
;
; The Fat Guy's end (LevelsDone = 5): BonusTally adds 100 000, then 5000 for each bullet and 10 000 for each detonator
; left, TallyLives 100 000 for each life, each with an effect and a pause, and ShowEndText shows "AND SO RICK SAVES
; THE DAY ...". The other end (level 4 done without level 5 open, or level 5 done in a game that did not start at
; level 1): Congratulations shows "CONGRATULATIONS YOU HAVE COMPLETED LEVEL n HOWEVER ...". Both wait 2500 frames or
; fire, then go through GAME OVER to the control menu.
; --------------------------------------------------------------------------------------------------------------------

  ORG $7EC8

; "GAME  OVER", $FF the end
;
; Read by DropText (from $7E8B) and PrintText (from $7E94). The font holds the
; digits first: a character is drawn as glyph (code - $34), so letters are
; plain ASCII and a digit is stored 4 higher.
GameOverText:
  INCBIN "res/texts/game-over.bin",$0000,11

  ORG $86E0

; The Fat Guy's end: 100 000, then the bullets and detonators counted
;
; The code bytes: LD HL,$7F11 / CALL $7ED3 (Points100000); then while
; ammunition ($8B3C) is not 0: one off, Points5000 ($7F05), effect 4 ($7A97),
; the HUD's ammunition ($79D1), 10 frames ($7A53); then while detonators
; ($8B3D) are not 0: one off, Points10000 ($7F0B), the HUD's detonators
; ($79DF), effect 5, 15 frames; then TallyLives. Jumped to from MainLoopPause
; ($7DB3). Not executed in the L1 builds: the RZX run went through it before
; frame 23 000, and rzx-l5-23000 starts in TallyLives.
;
; Witness: L1 0 ().
BonusTally:
  LD HL,Points100000      ; LD HL,$7F11 / CALL $7ED3: 100 000
  CALL AddScore
TallyBullets:
  LD A,(Ammunition)       ; the bullets: LD A,($8B3C) / AND A / JP Z,$8707
  AND A
  JP Z,TallyDetonators
  DEC A                   ; DEC A / LD ($8B3C),A / LD HL,$7F05 / CALL $7ED3:
                          ; 5000
  LD (Ammunition),A
  LD HL,Points5000
  CALL AddScore
  LD A,$04                ; LD A,4 / CALL $7A97 / CALL $79D1 / LD C,10 / CALL
                          ; $7A53 / JP $86E6
  CALL PlayEffect
  CALL DrawAmmo
  LD C,$0A
  CALL WaitFrames
  JP TallyBullets
TallyDetonators:
  LD A,(Detonators)       ; the detonators: LD A,($8B3D) / AND A / JP Z,$8728
  AND A
  JP Z,TallyLives
  DEC A                   ; DEC A / LD ($8B3D),A / LD HL,$7F0B / CALL $7ED3: 10
                          ; 000
  LD (Detonators),A
  LD HL,Points10000
  CALL AddScore
  CALL DrawDetonators     ; CALL $79DF / LD A,5 / CALL $7A97 / LD C,15 / CALL
                          ; $7A53 / JP $8707
  LD A,$05
  CALL PlayEffect
  LD C,$0F
  CALL WaitFrames
  JP TallyDetonators

; Each life left: 100 000 points, an effect, 20 frames; then the Fat Guy's end
; text
;
; While lives ($8B3B) are not 0: one off, Points100000 (AddScore), the HUD's
; lives ($79C3), effect 10 ($7A97), 20 frames. Then tune 10 ($7AAD) and
; ShowEndText with FatGuyEndText.
;
; Evidence: rzx-l5-23000 6 runs (5 lives counted, the 6th pass to TallyDone),
; the ending text on its screens (stage 1: the RZX run's level 5, frames 23
; 200-26 500).
;
; Witness: L1 12 (rzx-l5-23000).
TallyLives:
  LD A,(Lives)
  AND A
  JP Z,TallyDone
  DEC A
  LD (Lives),A
  LD HL,Points100000
  CALL AddScore
  CALL DrawLives
  LD A,$0A
  CALL PlayEffect
  LD C,$14
  CALL WaitFrames
  JP TallyLives
TallyDone:
  LD A,$0A                ; tune 10, the Fat Guy's end text
  CALL StartTune
  LD HL,FatGuyEndText
  JP ShowEndText

; The other end: the level's digit into the text, tune 0
;
; The code bytes LD A,($7EF1) / ADD A,$34 / LD ($87CD),A (the level as a text
; digit, stored 4 higher) / XOR A / CALL $7AAD (tune 0) / LD HL,$87A0
; (CongratulationsText), falling into ShowEndText. Jumped to from MainLoopPause
; at $7DBB (level 5 done before five levels in this game) and $7DC7 (level 4
; done with level 5 closed). Not executed in any recording: complete level 4 in
; a game that has not opened level 5 (from level 2, 3 or 4) to run it.
;
; Evidence: end-congrats (stage 2: the RZX run's level 4 end with POKE
; LevelsDone ($7EF2) = 0, so Level5Open stays clear) once: "CONGRATULATIONS ...
; YOU HAVE COMPLETED LEVEL 4" on its screens.
;
; Witness: L1 2 (end-congrats).
Congratulations:
  LD A,(Level)            ; the level's digit into the text
  ADD A,$34
  LD (CompletedLevelDigit),A
  XOR A                   ; tune 0
  CALL StartTune
  LD HL,CongratulationsText

; An end text: the view cleared, then each line falls into place
;
; HL = the list (CongratulationsText or FatGuyEndText). FontCellsMode, $796F
; (HL kept), then ShowEndTextLoop.
;
; Evidence: rzx-l5-23000 once.
;
; Witness: L1 4 (end-congrats, rzx-l5-23000).
ShowEndText:
  CALL FontCellsMode
  PUSH HL
  CALL DrawHud
  POP HL

; A line of the end text: column, row, text
;
; A record: +0 the column (E), +1 the row in pixels (D), the text to $FF;
; DropText with A = $FF. A record starting with $FF ends the list:
; EndTextPause.
;
; Evidence: 6 runs in 2 builds (rzx-l5-23000 5, rzx-l5-24000-poke 1).
;
; Witness: L1 26 (end-congrats, rzx-l5-23000, rzx-l5-24000-poke).
ShowEndTextLoop:
  LD A,(HL)
  CP $FF
  JP Z,EndTextPause
  LD E,A
  INC HL
  LD D,(HL)
  INC HL
  LD A,$FF
  CALL DropText

; Past the line's $FF to the next record
;
; HL + 1, then ShowEndTextLoop.
;
; Evidence: rzx-l5-23000 (the four lines).
;
; Witness: L1 22 (end-congrats, rzx-l5-23000, rzx-l5-24000-poke).
ShowEndTextNext:
  INC HL
  JP ShowEndTextLoop

; 2500 frames or fire
;
; BC = 2500, then EndTextWait.
;
; Evidence: 2 runs in 2 builds (rzx-l5-23000, rzx-l5-24000-poke).
;
; Witness: L1 6 (end-congrats, rzx-l5-23000, rzx-l5-24000-poke).
EndTextPause:
  LD BC,2500

; A frame; fire, SPACE or ENTER ends the wait
;
; Frame wait (C = 1), $7229; a key or BC = 0: EndTextExit.
;
; Evidence: 4512 runs in 3 builds (rzx-l5-23000 2256, rzx-l5-24000-poke 2000,
; rzx-l5-26000-poke 256): no recording reaches the end of the wait or a key.
;
; Witness: L1 11612 (end-congrats, rzx-l5-23000, rzx-l5-24000-poke,
; rzx-l5-26000-poke).
EndTextWait:
  PUSH BC
  LD C,$01
  CALL WaitFrames
  CALL TestFireKeys
  POP BC
  JP Z,EndTextExit
  DEC BC
  LD A,B
  OR C
  JP NZ,EndTextWait

; After an end text: GAME OVER and the control menu
;
; The code bytes CALL $88B1 (FontCellsMode) / CALL $7EB3 (LevelCellsMode) /
; CALL $796F / JP $7E1E (GameOver: the "GAME  OVER" box, then the control
; menu). Not executed in any recording (rzx-l5-26000-poke ends inside
; EndTextWait).
;
; Witness: L1 0 ().
EndTextExit:
  CALL FontCellsMode
  CALL LevelCellsMode
  CALL DrawHud
  JP GameOver

; The other end's text: records of column, row, text
;
; Records: +0 the column, +1 the row in pixels, the text, $FF; a $FF record
; ends the list. The digit at $87CD is written by Congratulations (Level +
; $34). Shown by ShowEndText.
CongratulationsText:
  INCBIN "res/texts/end-congratulations.bin",$0000,45
CompletedLevelDigit:
  INCBIN "res/texts/end-congratulations.bin",$002D,112

; The Fat Guy's end text: records of column, row, text
;
; "AND SO RICK SAVES THE DAY / BY DEFEATING THE FAT GUY AND / HIS FLEET OF
; ROBOT STARSHIPS / WHAT WILL RICK DO NEXT", in the same records as
; CongratulationsText. Shown by TallyLives through ShowEndText (rzx-l5-23000).
FatGuyEndText:
  INCBIN "res/texts/end-fat-guy.bin",$0000,116
