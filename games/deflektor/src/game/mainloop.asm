; --------------------------------------------------------------------------------------------------------------------
; mainloop.asm: The main loop: the level's set-up and the pass
;
; SetUpLevel $843C prints the level number, clears the pass's flags, the gremlin records and the explosion slots,
; reads the level's settings, puts back the score saved at the level's start, builds the level ($891A) and wipes it
; onto the screen ($8CA2), resets the bars ($A52F: CHARGING LASER), counts the cells and mirrors, finds the laser and
; the cursor's first place ($8AC1), then runs MainLoop.
;
; MainLoop $854A is one pass: the keys ($97F0), $999F, the grid drawn into the buffers ($8960); while the laser
; charges no beam is traced (in the demo every pass shows the next level instead); else the beam is traced from the
; laser (TraceBeam $8ED6); $9A57, $99C6, the gremlins ($AB9F), the play area copied to the screen ($8C10); then
; PassEnd: the overload ($A683) and a life lost (LoseLife), the energy ($A613), the receiver reached (LevelComplete),
; the receiver's door blown when the last cell burns (OpenReceiver), the burning cells' explosions. The pass never
; waits for the frame: 4.85 frames a pass in the RZX run.
;
; LevelComplete $87D4: CONTACT!, the screen turned magenta, the remaining energy counted into the score (10 points a
; bar pixel), 500 points a life left, the score saved, the lives back to three, then the next level, the ending after
; level 60, or the title after the third practice level.
; --------------------------------------------------------------------------------------------------------------------

  ORG $81B8

; Seven explosion slots of 4 bytes: the cell's grid address (high, low), y, x;
; high byte 0 = free
;
; A burning cell (BeamBurn at `$8F43`: the six first slots looked at, the
; seventh taken when all are full) or the receiver's door (OpenReceiver at
; `$8B7D`, the first slot written backwards from `$81BB`). PassEnd `$85AE` (at
; `$85F1`) steps each slot's cell through the codes `$57`, `$58-$5C` (one a
; pass) and empties it at `$5D` (CellsLeft - 1, the slot freed). SetUpLevel
; clears the 28 bytes (`$84E1`).
;
; Zero in the image (a work area); read and written in every recording with a
; level; `$81D1-$81D3` (the seventh slot's low, y, x) were written but never
; read back.
ExplosionSlots:
  DEFB $00,$00,$00,$00    ; slot 1 (also the receiver's door)
  DEFB $00,$00,$00,$00    ; slots 2-7
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00

  ORG $81FF

; The level slot being played: 0-59 the levels, 60-62 practice P1-P3 (60 after
; the last level: the ending)
;
; Set by NewGame (`$8426`, 0 or `$3C`), counted up by LevelComplete (`$87E9`,
; `$87ED`) and by the demo (`$8562`, `$8566`), compared by LevelCompletePause
; (`$8875`: 60 the ending, 63 the end of practice); read by SetUpLevel
; (`$843C`, `$84C6`: the digits and LevelSettings), BuildLevel `$891A`
; (LevelData + `$87` x Level) and ResetBars (`$A567`); changed by the dormant
; cheat LevelCheat `$9832`.
Level:
  DEFB $00

  ORG $8374

; The x (half-cells) of the cell HighlightCell colours: the laser's centre, or
; the receiver's
;
; Written by FindLaser (`$8AE2`, the laser's centre) and by the beam at the
; receiver (`$8F9E`, before LevelDone); read by HighlightCell `$8FCA`
; (`$8FD6`). 0 in the image, as are all the variables to `$8381`.
HighlightX:
  DEFB $00

; The y (half-cells) of the highlighted cell
;
; Written at `$8AE8` and `$8FA4`, read by HighlightCell (`$8FCA`).
HighlightY:
  DEFB $00

; The beam's start x: the half-cell in front of the laser
;
; Written by FindLaser (`$8B02`), read by MainLoop (`$857B`) to start
; TraceBeam.
BeamStartX:
  DEFB $00

; The beam's start y
;
; Written by FindLaser (`$8B12`), read by MainLoop (`$8581`).
BeamStartY:
  DEFB $00

; The laser's direction 0, 4, 8 or 12; $FF: no laser, or the energy drained (no
; beam)
;
; Written by FindLaser (`$8ADB` `$FF`, `$8AF3` the direction) and EnergyDrained
; (`$A67F`, `$FF`); read by MainLoop (`$8571`).
BeamStartDirection:
  DEFB $00

; $FF while the demo runs (the options panel's 5), else 0
;
; Cleared by TitleLoop (`$840D`), set by OptionsMenu (`$A7D0`); read by the
; main loop (`$8559`: the next level once charged), PauseGame (`$973A`),
; ReadKeys (`$9819`: DEMO ABORTED) and ResetBars (`$A561`: the DEMO message).
DemoFlag:
  DEFB $00

; The number of mirrors $01-$10 in the level (turning ones not counted)
;
; Counted by SetUpLevel (`$8537`); read by ChargeLaser (`$A598`): with 30 or
; more the charge scrambles each mirror with a chance of 1 in 8, else 1 in 2.
MirrorCount:
  DEFB $00

; Set when a cell starts to explode this pass: PassEnd plays BurnSound
;
; Set at `$8603`, read at `$8650` (BurnSound), cleared at `$85BC`.
BurnSoundFlag:
  DEFB $00

; Set by CursorFire when a gremlin is killed: PassEnd plays GremlinSound
;
; Cleared by SetUpLevel (`$84B0`) and PassEnd (`$85B9`), read by PassEnd
; (`$85AE`), set by CursorFire (`$9ADE`).
GremlinSoundFlag:
  DEFB $00

; The lives left (3 at a new game and after each level)
;
; Set to 3 by NewGame (`$841B`) and LevelCompletePause (`$8872`), counted down
; by LoseLife (`$86A6`-`$86AA`, `$86CD`), read by LevelCompletePause (`$882A`,
; the bonus).
Lives:
  DEFB $00

; $FF once the energy bar is down to its last byte: the beam flashes
;
; Cleared by SetUpLevel (`$84AA`), set by DrainEnergy (`$A623`); read by
; MainLoop (`$8587`), which then sets BeamGlyphSet from bit 3 of FrameCounter.
EnergyCritical:
  DEFB $00

; Counted up by the interrupt every frame (the game path)
;
; InterruptHandler `$A32A` (`$A33C`, `$A340`); read by MainLoop (`$858D`) for
; the beam's flashing.
FrameCounter:
  DEFB $00

; The cells ($40) left to burn; $FF after the receiver's door is opened
;
; Counted by SetUpLevel (`$853B`), counted down by PassEnd (`$861D`) when an
; explosion ends; 0 makes PassEnd call OpenReceiver (`$85DB`), which sets it to
; `$FF` (`$8B97`).
CellsLeft:
  DEFB $00

; 0 or $40: the offset of the glyph set in BeamGlyphBytes ($40 the flashing
; set)
;
; Written by MainLoop (`$8598`: `$40` on the frames with bit 3 of FrameCounter
; set while EnergyCritical, else 0); read by BeamVertex (`$90C7`) and the
; outgoing pass (`$91E3`) as the low byte added to `$8000` + 4 x direction.
BeamGlyphSet:
  DEFB $00

  ORG $843C

; Set up the level in Level $81FF and play it: digits, flags, settings, score,
; build, wipe, counts, laser
;
; From LevelPanel (falls in), the demo's next level (`$856B`) and LoseLife
; (`$86D1`, the level again after a life lost).
;
; 1. The LEVEL digits: A = Level + 1 split into tens (B) and units; for the
; practice slots (Level >= 60) B = 10, the glyph P, and the units Level - 59
; (P1-P3). Each digit is eight lines of LevelDigits `$88B0` + 8 x digit, drawn
; on lines 4-7 of character row 20 and lines 0-3 of row 21 (`$5486` / `$50A6`
; for the tens, the next column for the units): LEVEL 01 in the panel.
;
; 2. Clears the cursor's cell `$96C3` / `$96C4`, LevelDone, LifeLost,
; BeamOnMine, BeamInLaser, the energy-critical flag `$837E`, SoundFlags `$A8A6`
; and the gremlin-sound flag `$837C`.
;
; 3. The eight gremlin records at `$AB63` (6 bytes each): byte 0 = `$41`,
; `$4B`, `$55` ... (`$41` + 10 k), byte 1 = 0.
;
; 4. LevelSettings: byte 0 to `$A63C` (the energy rate operand), byte 1 to
; `$AB95` (the gremlin count). In practice the saved score is cleared
; (`$9B30`).
;
; 5. The seven explosion slots `$81B8-$81D3` cleared; the score `$9B3E` (five
; digits) = the score saved at the level's start `$9B44`, so a level begun
; again after a life lost starts from the score it began with; the score's
; field on the screen (lines 3-7 of row 21, columns 26-31) cleared, its left
; edge pixel kept.
;
; 6. BuildLevel `$891A` (the grid, the character map, the buffers); `$9B0A`
; prints the score, `$9B53` the high score; WipeInPlayArea `$8CA2` brings the
; play area onto the screen; `$A52F` resets the overload and energy bars, sets
; the charging flag `$A509` and the message CHARGING LASER (DEMO in the demo).
;
; 7. Counts the level's bytes: D = the cells (`$40`), E = the mirrors
; (`$01-$10`; turning mirrors, bit 7 set, are not counted). MirrorCount `$837A`
; = E (the charging's scramble `$A598` turns fewer mirrors when there are 30 or
; more); CellsLeft `$8380` = D; the points of a burnt cell (the operand of `LD
; B,n` at CellPoints `$8F62`) = 12 (120 points), or 3 (30 points) when the
; level has 30 or more cells (levels 4, 9, 14 ... 59: 110-120 cells; 38, 58,
; 60).
;
; 8. FindLaser `$8AC1`, then MainLoop.
;
; Run at every level start of every play recording (165 in all).
;
; Witness: L1 196 (c1, c1g, cheat, controls, energy, energy-out, hof, kempston,
; menu, mine, overload, L x20, rzx x59).
SetUpLevel:
  LD A,(Level)
  CP $3C
  JR C,SetUpLevelDecimal
  SUB $3B                 ; the practice slots: P and the slot - 59
  LD B,$0A
  JR SetUpLevelDigits
SetUpLevelDecimal:
  INC A                   ; A = Level + 1, B = its tens
  LD BC,$000A
SetUpLevelTensLoop:
  CP C
  JR C,SetUpLevelDigits
  SUB C
  INC B
  JR SetUpLevelTensLoop
SetUpLevelDigits:
  EX AF,AF'               ; the tens glyph: LevelDigits + 8 x B
  LD A,B
  ADD A,A
  ADD A,A
  ADD A,A
  LD C,A
  LD B,$00
  LD HL,LevelDigits
  ADD HL,BC
  LD B,$04
  LD DE,Screen+5254             ; lines 4-7 of row 20, column 6
SetUpLevelTensTop:
  LD A,(HL)
  LD (DE),A
  INC D
  INC HL
  DJNZ SetUpLevelTensTop
  LD B,$04
  LD DE,Screen+4262             ; lines 0-3 of row 21
SetUpLevelTensBottom:
  LD A,(HL)
  LD (DE),A
  INC D
  INC HL
  DJNZ SetUpLevelTensBottom
  EX AF,AF'               ; the units glyph to column 7
  ADD A,A
  ADD A,A
  ADD A,A
  LD C,A
  LD B,$00
  LD HL,LevelDigits
  ADD HL,BC
  LD B,$04
  LD DE,Screen+5255
SetUpLevelUnitsTop:
  LD A,(HL)
  LD (DE),A
  INC D
  INC HL
  DJNZ SetUpLevelUnitsTop
  LD B,$04
  LD DE,Screen+4263
SetUpLevelUnitsBottom:
  LD A,(HL)
  LD (DE),A
  INC D
  INC HL
  DJNZ SetUpLevelUnitsBottom
  XOR A                   ; the pass's flags cleared
  LD (CursorX),A
  LD (CursorY),A
  LD (LevelDone),A
  LD (LifeLost),A
  LD (BeamOnMine),A
  LD (BeamInLaser),A
  LD (EnergyCritical),A
  LD (SoundFlags),A
  LD (GremlinSoundFlag),A
  LD HL,Gremlins          ; the gremlin records: byte 0 = $41 + 10 k, byte 1 =
                          ; 0
  LD DE,$0005
  LD A,$41
  LD B,$08
SetUpLevelGremlinLoop:
  LD (HL),A
  INC HL
  LD (HL),$00
  ADD HL,DE
  ADD A,$0A
  DJNZ SetUpLevelGremlinLoop
  LD A,(Level)            ; the level's settings: the energy rate
                          ; (self-modifying) and the gremlin count
  ADD A,A
  LD E,A
  LD D,$00
  LD HL,LevelSettings
  ADD HL,DE
  LD A,(HL)
  LD (EnergyRate+$0001),A ; the operand of CP n at $A63B
  INC HL
  LD A,(HL)
  LD (GremlinCount),A
  LD A,(PracticeFlag)     ; practice: no score carried
  AND A
  CALL NZ,ClearSavedScore
  LD HL,ExplosionSlots    ; the seven explosion slots cleared (28 bytes)
  LD B,$1C
  XOR A
SetUpLevelSlotsLoop:
  LD (HL),A
  INC L
  DJNZ SetUpLevelSlotsLoop
  LD HL,SavedScore        ; the score = the score saved at the level's start
  LD DE,ScoreDigits
  LD BC,$0005
  LDIR
  LD HL,Screen+5050             ; the score's field on the screen cleared (5 lines)
  LD C,$05
SetUpLevelScoreLine:
  LD B,$05
  LD (HL),$80
SetUpLevelScoreByte:
  INC L
  LD (HL),A
  DJNZ SetUpLevelScoreByte
  LD L,$BA
  INC H
  DEC C
  JR NZ,SetUpLevelScoreLine
  CALL BuildLevel         ; build, print the scores, wipe in, the bars
  CALL PrintScore
  CALL PrintHighScore
  CALL WipeInPlayArea
  CALL ResetBars
  LD A,$0C                ; 12 points (x10) a burnt cell
  LD (CellPoints+$0001),A
  LD DE,$0000             ; count the cells (D) and the mirrors (E) in the
                          ; level's 135 bytes
  LD HL,(LevelAddress)
  LD B,$87
SetUpLevelCountLoop:
  LD A,(HL)
  CP $40
  JR NZ,SetUpLevelNotCell
  INC D
  JR SetUpLevelCountNext
SetUpLevelNotCell:
  DEC A                   ; codes 1-16: a mirror
  CP $10
  JR NC,SetUpLevelCountNext
  INC E
SetUpLevelCountNext:
  INC HL
  DJNZ SetUpLevelCountLoop
  LD A,E
  LD (MirrorCount),A
  LD A,D
  LD (CellsLeft),A
  CP $1E                  ; 30 or more cells: 3 points (x10) a cell
  JR C,SetUpLevelLaser
  LD A,$03
  LD (CellPoints+$0001),A
SetUpLevelLaser:
  CALL FindLaser          ; the laser, the beam's start, the cursor's first
                          ; cell

; One pass of play: keys, cursor, grid, beam, gremlins, the screen; then
; PassEnd
;
; 1. `$97F0` (the keys and the controls), `$999F`, RenderGrid `$8960` (the grid
; into the character map, the marked characters into the buffers).
;
; 2. While the laser charges (`$A509` nonzero) no beam is traced. In the demo
; (`$8379` set) the pass instead waits a Delay and goes on to the next level
; (`$855F`): every level in turn, shown for one pass while it charges, then
; TitleLoop after the 60th (`$856E`); the `menu` recording runs `$855F` 60
; times and `$856E` once.
;
; 3. Else, unless FindLaser found no laser (`$8378` = `$FF`), the beam's start:
; direction `$8ECB` = `$8378`, x `$8ECD` = `$8376`, y `$8ECE` = `$8377` (the
; half-cell in front of the laser); the beam's graphics bank `$8381` = `$40` in
; every other 8-frame spell of FrameCounter while the energy is critical
; (`$837E`), else 0: the beam flickers; TraceBeam `$8ED6`.
;
; 4. `$9A57`, `$99C6`, the gremlins `$AB9F` (not while charging), CopyPlayArea
; `$8C10`; then PassEnd.
;
; The pass takes 4.85 frames on average in the RZX run (WALKTHROUGH 1).
;
; Witness: L1 111157 (c1, c1g, cheat, controls, energy, energy-out, hof,
; kempston, menu, mine, overload, L x20, rzx x59).
MainLoop:
  CALL ReadKeys
  CALL MarkCursorCells
  CALL RenderGrid
  LD A,(LaserCharging)    ; the laser charging?
  AND A
  JR Z,MainLoopBeam
  LD A,(DemoFlag)         ; the demo: show the next level
  AND A
  JR Z,MainLoopRest
MainLoopDemoNext:
  CALL Delay
  LD A,(Level)
  INC A
  LD (Level),A
  CP $3C
  JP C,SetUpLevel
  JP TitleLoop            ; the demo after level 60: the title
MainLoopBeam:
  LD A,(BeamStartDirection) ; no laser: no beam
  CP $FF
  JR Z,MainLoopRest
  LD (BeamDirection),A    ; the beam's start: direction, x, y (half-cells)
  LD A,(BeamStartX)
  LD (BeamX),A
  LD A,(BeamStartY)
  LD (BeamY),A
  LD A,(EnergyCritical)   ; energy critical: the beam's second graphics set in
                          ; alternate 8-frame spells
  AND A
  JR Z,MainLoopBeamBank
  LD A,(FrameCounter)
  LD B,A
  XOR A
  BIT 3,B
  JR Z,MainLoopBeamBank
  LD A,$40
MainLoopBeamBank:
  LD (BeamGlyphSet),A
  CALL TraceBeam
MainLoopRest:
  CALL CursorFire         ; $9A57, $99C6, the gremlins, the screen
  CALL DrawCursor
  LD A,(LaserCharging)
  AND A
  CALL Z,UpdateGremlins
  CALL CopyPlayArea

; The pass's second half: sounds, overload, life lost, energy, contact, the
; last cell, the explosions
;
; Falls in from MainLoop.
;
; 1. The gremlin sound: when `$837C` is set (at `$9ADE`, where the gremlin
; record on the cursor's cell is reset), PlaySound `$A8C0` with `$81ED`;
; `$837C` and the burn-sound flag `$837B` cleared.
;
; 2. `$A683` (the overload: the beam on a mine or back in the laser fills the
; OVERLOAD bar); LifeLost set: LoseLife `$866A`. `$A613` (the charging, then
; the energy drain); LevelDone set (the beam reached the receiver):
; LevelComplete `$87D4`.
;
; 3. SoundFlags bit 3 off. CellsLeft `$8380` = 0 (the last cell burnt):
; OpenReceiver `$8B3F` (the element in front of the receiver starts to
; explode), PlaySound ReceiverOpenSound, 25 points (250).
;
; 4. The explosions: each of the seven 4-byte slots at `$81B8` (the grid
; address, high byte first, then y and x in half-cells; high byte 0 = free) is
; a cell burning. The cell's code: a code below `$58` (the cell just hit)
; becomes `$57` and sets `$837B`; then one step a pass, `$58` to `$5C`
; (SoundFlags bit 3 while `$58`-`$59`), and at `$5D` the cell is emptied (code
; 0), the slot freed and CellsLeft decremented. Each step marks the cell's four
; characters (DrawMarks `$E300`) with 2, to be drawn twice.
;
; 5. A new explosion this pass (`$837B` set): PlaySound `$81D4`. Back to
; MainLoop.
;
; An entry of its own: the `gameover` recording starts from a snapshot taken
; inside CopyPlayArea (called at `$85AB`), so its L1 marks a routine root at
; the return address.
;
; Witness: L1 111052 (c1, c1g, cheat, controls, energy, energy-out, gameover,
; hof, kempston, menu, mine, overload, L x20, rzx x59).
PassEnd:
  LD A,(GremlinSoundFlag)
  LD HL,GremlinSound
  AND A
  CALL NZ,PlaySound
  XOR A
  LD (GremlinSoundFlag),A
  LD (BurnSoundFlag),A
  CALL UpdateOverload     ; the overload bar; a full bar sets LifeLost
  LD A,(LifeLost)
  AND A
  JP NZ,LoseLife
  CALL DrainEnergy        ; the charging and the energy bar; LevelDone set by
                          ; the beam
  LD A,(LevelDone)
  AND A
  JP NZ,LevelComplete
  LD A,(SoundFlags)       ; SoundFlags bit 3 off
  RES 3,A
  LD (SoundFlags),A
  LD A,(CellsLeft)        ; the last cell burnt: open the receiver
  AND A
  JR NZ,PassEndExplosions
  CALL OpenReceiver
  LD HL,ReceiverOpenSound
  CALL PlaySound
  LD B,$19                ; 25 points (250)
  CALL AddScore
PassEndExplosions:
  LD B,$07                ; the seven explosion slots
  LD HL,ExplosionSlots
PassEndSlotLoop:
  LD A,(HL)
  AND A
  JR Z,PassEndSlotFree
  LD D,A
  INC L
  LD E,(HL)
  DEC L
  LD A,(DE)               ; the cell's code: below $58 it starts at $57
  CP $58
  JR NC,PassEndStep
  LD A,$57
  LD (BurnSoundFlag),A
PassEndStep:
  INC A                   ; the next explosion frame
  CP $5A
  JR NC,PassEndStepped
  EX AF,AF'               ; frames $58-$59: SoundFlags bit 3
  LD A,(SoundFlags)
  SET 3,A
  LD (SoundFlags),A
  EX AF,AF'
PassEndStepped:
  CP $5D                  ; $5D: the cell is gone
  JR C,PassEndMark
  LD A,(CellsLeft)
  DEC A
  LD (CellsLeft),A
  XOR A
  LD (HL),A
PassEndMark:
  LD (DE),A               ; store the code, mark the cell's four characters (2)
  INC L
  INC L
  LD A,(HL)
  DEC A
  INC L
  EX DE,HL
  LD L,A                  ; DrawMarks + 32 (y - 1) + x - 1
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,(DE)
  DEC A
  ADD A,L
  LD L,A
  PUSH BC
  LD BC,DrawMarks
  ADD HL,BC
  LD A,$02
  LD (HL),A
  INC L
  LD (HL),A
  LD BC,$001F
  ADD HL,BC
  LD (HL),A
  INC L
  LD (HL),A
  POP BC
  EX DE,HL
  JR PassEndSlotNext
PassEndSlotFree:
  INC L
  INC L
  INC L
PassEndSlotNext:
  INC L
  DJNZ PassEndSlotLoop
  LD A,(BurnSoundFlag)    ; a new explosion: the burn sound
  AND A
  JP Z,MainLoop
  LD HL,BurnSound
  CALL PlaySound
  JP MainLoop

; Two PlaySound records: the receiver's door blown, and the life-lost sound
;
; A PlaySound `$A8C0` record: type 1 (a sweep, `$A85E`), then four bytes B, C,
; D, E: E notes of C half-periods each, the half-period D (delay loops) changed
; by B after each note.
;
; ReceiverOpenSound: PassEnd `$85E7` (B `$0F`, C 4, D `$14`, 35 notes).
; LifeLostSound `$8665`: LoseLife (`$8680` once, `$86C1` 36 times) (B `$19`, C
; 6, D 6, 10 notes).
ReceiverOpenSound:
  DEFB $01,$0F,$04,$14,$23
LifeLostSound:
  DEFB $01,$19,$06,$06,$0A ; type 1, B $19, C 6, D 6, E 10

  ORG $87D4

; The beam reached the receiver: CONTACT!, the next level number, then the
; bonus
;
; From PassEnd (`$85D0`) when LevelDone `$8ED2` is set (BeamStep at `$8FA9`).
; SoundFlags = 0; MessageNumber `$A104` = `$18`, MessageText = `$A16C`
; (CONTACT!); PlaySound `$81F7`; Level + 1; a Delay, then LevelCompletePause.
;
; Run 18 times, the 18 levels our RZX replay completes (WALKTHROUGH 6.1).
;
; Witness: L1 38 (L x20, rzx x18).
LevelComplete:
  XOR A
  LD (SoundFlags),A
  LD A,$18
  LD (MessageNumber),A
  LD HL,ContactMessage
  LD (MessageText),HL
  LD HL,ContactSound
  CALL PlaySound
  LD A,(Level)            ; the next level
  INC A
  LD (Level),A
  CALL Delay

; Two more Delays, the play area magenta, the energy and lives bonus, then the
; next level
;
; 1. Two Delays (with LevelComplete's, about 36 frames); the play area's 640
; attributes = `$03` (magenta ink on black).
;
; 2. The energy bonus: while the energy bar (`$A507`, the byte the drain has
; reached) has pixels: 10 points (`$9AF3`, B = 1), a short tone (`$A843`, HL =
; `$0A3C`), and one pixel shifted out of the bar's byte on its three lines
; (`SLA`, as the drain does at `$A646`); an empty byte moves the pointer one
; byte left, down to `$54F1`, the bar's first.
;
; 3. The lives bonus: for each life left, from the last: two Delays, its bar
; hollowed (as LoseLifeDrained does), 500 points (`$9AF3`, B = `$32`),
; PlaySound `$81ED`, then `$A843` with the HL PlaySound leaves.
;
; 4. Four Delays; the score is saved as the next level's start score (`$9B3E`
; to `$9B44`); Lives = 3: every level starts with three lives (LevelPanel
; redraws the three bars).
;
; 5. Level 60 (after the 60th level): TheEnd. Level 63 (after the third
; practice level): TitleLoop. Else LevelPanel, the next level.
;
; An entry of its own: 42 of the RZX segments start from a snapshot taken at
; the level change (`$81FF` written at `$87ED`), inside the Delay called at
; `$87F0`, so their L1s mark a routine root at the return address. Run 78 times
; (all 60 RZX segments: the 42 roots and the 18 completions).
;
; Witness: L1 115 (ending, hof, L x20, rzx x60).
LevelCompletePause:
  CALL Delay
  CALL Delay
  LD HL,Attributes             ; the play area magenta
  LD DE,Attributes+1
  LD (HL),$03
  LD BC,$027F
  LDIR
LevelCompleteEnergy:
  LD B,$01                ; 10 points, a tone, a pixel off the energy bar
  CALL AddScore
  LD HL,$0A3C
  CALL TwoTone
  LD HL,(EnergyBarPointer) ; shift one pixel out of the bar's byte, three lines
  LD A,(HL)
  SLA A
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  DEC H
  DEC H
  AND A
  JR NZ,LevelCompleteEnergy
  DEC L                   ; the byte empty: the pointer one byte left
  LD (EnergyBarPointer),HL
  LD A,L
  CP $F1
  JR NC,LevelCompleteEnergy
  LD A,(Lives)            ; 500 points a life left
  LD B,A
LevelCompleteLife:
  LD A,B
  PUSH BC
  CALL Delay
  CALL Delay
  DEC A                   ; the life's bar hollowed
  LD HL,Screen+5290
  ADD A,A
  ADD A,L
  LD L,A
  LD B,$03
LevelCompleteHollow:
  LD (HL),$40
  INC L
  LD (HL),$01
  DEC L
  INC H
  DJNZ LevelCompleteHollow
  LD B,$32                ; 500 points, a sound
  CALL AddScore
  LD HL,GremlinSound
  CALL PlaySound
  CALL TwoTone
  POP BC
  DJNZ LevelCompleteLife
  CALL Delay              ; the score saved, three lives
  CALL Delay
  CALL Delay
  CALL Delay
  LD DE,SavedScore
  LD HL,ScoreDigits
  LD BC,$0005
  LDIR
  LD A,$03
  LD (Lives),A
  LD A,(Level)            ; after level 60: the ending; after practice P3: the
                          ; title
  CP $3C
  JP Z,TheEnd
  CP $3F
  JP Z,TitleLoop
  JP LevelPanel
TheEnd:
  DI                      ; The ending: the full-screen buffer cleared, the
                          ; ending's screen ($A8CE), two sounds, keys released,
                          ; $AD79
  LD HL,CharMap+512             ; clear $E200-$FCFF: the full-screen buffer's
                          ; attributes and pixels
  LD DE,CharMap+513
  LD (HL),$00
  LD BC,$1AFF
  LDIR
  CALL EndingScreen       ; the ending's text and picture, copied to the screen
  LD HL,ChargedSound
  CALL PlaySound
  LD HL,ChargedSound
  CALL PlaySound
TheEndKeys:
  XOR A                   ; wait until no key is held
  IN A,($FE)
  CPL
  AND $1F
  JR NZ,TheEndKeys
  CALL TitleTune          ; $AD79, then the title
  JP TitleLoop

  ORG $8908

; Wait 255 x 255 DJNZ loops (about 12 frames, interrupts as they are)
;
; C = 255 outer passes of B = 255 `DJNZ`: about 845 000 T-states, 12 frames of
; 69 888 T. Leaves A and HL alone, BC = 0.
;
; Callers: NewGame (twice), the demo (`$855F`), LoseLife (`$86CA`),
; LevelComplete and LevelCompletePause (seven times a level and two for each
; life left), `$9DE1`, the title `$A729-$A732` (four), the ending `$A8D9`,
; `$A943`, `$A963-$A96C`.
;
; Witness: L1 1373 (c1, c1g, controls, ending, energy, energy-out, gameover,
; hof, kempston, menu, mine, overload, L x20, rzx x60).
Delay:
  LD C,$FF

; DelayOuter
;
; Used by the routine at DelayInner.
DelayOuter:
  LD B,$FF

; DelayInner
DelayInner:
  DJNZ DelayInner
  DEC C
  JR NZ,DelayOuter
  RET
