; --------------------------------------------------------------------------------------------------------------------
; elements.asm: The elements: cells, mines, prisms, gremlins, the energy and the overload
;
; The two bars of the panel are counters drawn as screen bytes: a pointer into the screen (EnergyBarPointer $A507,
; OverloadBarPointer $A50A) and the bits of the byte it points at, the same byte in three pixel rows (scan lines 4-6:
; overload $54B1-$54B8, row 21 columns 17-24; energy $54F1-$54F8, row 23 columns 17-24; 64 steps each). ResetBars
; $A52F empties both at each level start; ChargeLaser $A57A fills the energy bar two steps a pass while it scrambles
; the mirrors; DrainEnergy $A613 takes a step every rate frames (the level's byte from $8385, self-modified into the
; CP at EnergyRate $A63B); UpdateOverload $A683 adds a step a pass with the beam in the laser, four with the beam on a
; mine, and takes one back otherwise.
;
; The gremlins (UpdateGremlins $AB9F, up to 8, GremlinCount $AB95 the level's second byte from $8385) appear on empty
; cells after a delay, walk a character a pass and stop on mirrors to turn them at random; the cursor's fire on a
; turned mirror kills one ($9AB6: the delay set to $C8, a score bonus).
; --------------------------------------------------------------------------------------------------------------------

  ORG $9A57

; Fire: the square cursor, and a gremlin in the cell under the cursor is killed
; (160 points each)
;
; Called each pass by the main loop (`$859E`). Fire is the control bits' bit 4
; (`$96C5`) or read again by the method (keyboard: any key of the bottom rows;
; Sinclair: 5 or 0; Kempston: bit 4 of port `$1F`; Protek: 0). With fire:
; CursorMode `$96C6` = 7, and the gremlin records (`$AB63`, 6 bytes each,
; `$AB95` of them, the count the level set-up copies from the second byte of
; its `$8385` pair) are searched for one whose cell address (+4, +5) is the
; cursor cell's. Each found one is killed: +0 = `$C8`, +1 = 0, +5 = 0 (no
; cell), `$837C` = `$FF` (the main loop then plays the effect `$81ED`), and the
; score gets 16 tens for it (`AddScore` `$9AF3`).
;
; Recordings: `$9AC5` 117 180 runs in 53 RZX segments; a gremlin was hit
; (`$9AD1`) 120 times in 43 segments.
;
; Witness: L1 111061 (c1, c1g, cheat, controls, energy, energy-out, hof,
; kempston, menu, mine, overload, L x20, rzx x59).
CursorFire:
  LD A,(ControlBits)
  BIT 4,A
  JP NZ,CursorFireHeld
  LD A,(ControlMethod)
  CP $01
  JP Z,CursorFireSinclair
  CP $02
  JP Z,CursorFireKempston
  CP $03
  JP Z,CursorFireProtek
  LD A,$7E                ; the keyboard: the two bottom half-rows
  IN A,($FE)
  CPL
  AND $1F
  JP NZ,CursorFireHeld
  RET
CursorFireSinclair:
  LD A,$F7                ; Sinclair: 5 or 0
  IN A,($FE)
  BIT 4,A
  JP Z,CursorFireHeld
  LD A,$EF
  IN A,($FE)
  BIT 0,A
  JP Z,CursorFireHeld
  RET
CursorFireKempston:
  IN A,($1F)              ; Kempston: bit 4
  BIT 4,A
  JP NZ,CursorFireHeld
  RET
CursorFireProtek:
  LD A,$EF                ; Protek: 0
  IN A,($FE)
  BIT 0,A
  RET NZ
CursorFireHeld:
  LD A,$07                ; the square cursor
  LD (CursorMode),A
  LD A,(CursorX)          ; HL = the cursor cell's grid address
  LD C,A
  LD A,(CursorY)
  LD B,A
  LD A,$12
  INC B
CursorFireRow:
  ADD A,$11
  DJNZ CursorFireRow
  ADD A,C
  LD L,A
  LD H,$FD
  LD A,(GremlinCount)     ; no gremlins on this level: done
  AND A
  RET Z
  LD B,A
  LD C,$00
  LD DE,$0006
  LD IX,Gremlins
CursorFireGremlin:
  LD A,(IX+$04)           ; a gremlin record (6 bytes): its cell at +4, +5
  CP L
  JR NZ,CursorFireNext
  LD A,(IX+$05)
  CP H
  JR NZ,CursorFireNext
  XOR A                   ; killed: +0 = $C8, +1 = 0, no cell, the effect
  LD (IX+$00),$C8
  LD (IX+$01),A
  LD (IX+$05),A
  LD A,$FF
  LD (GremlinSoundFlag),A
  INC C
CursorFireNext:
  ADD IX,DE
  DJNZ CursorFireGremlin
  LD A,C                  ; 16 tens of points for each gremlin killed
  ADD A,A
  RET Z
  ADD A,A
  ADD A,A
  ADD A,A
  LD B,A
  CALL AddScore
  RET

  ORG $A506

; Frames since the last energy step: InterruptHandler counts it, DrainEnergy
; compares it with the rate
;
; Counted at `$A335` every frame of play (not in the menu); reset by
; DrainEnergy (`$A63F`) at each step and at the end of charging (`$A5FC`); the
; pause saves and restores it (`$9751`, `$97E6`).
EnergyTick:
  DEFB $00

; The energy bar's screen byte: $54F1-$54F8 (row 23 columns 17-24, scan line 4;
; drawn in lines 4-6)
;
; ResetBars sets `$54F1`; ChargeLaser moves it right to `$54F8`; DrainEnergy
; moves it left; `$54F0` is empty (ENERGY DRAINED), `$54F1` one byte left
; (critical), `$54F2` two bytes left (ENERGY LOW). The level-complete count
; `$8811` drains the rest for the bonus.
EnergyBarPointer:
  DEFW $0000

; $FF while the laser charges at a level start (ChargeLaser), then 0
;
; Set by ResetBars, cleared at the end of ChargeLaser (`$A5FF`). The main loop
; (`$8553`, `$85A4`) skips the beam and the gremlins while it is set; in the
; demo the level is left as soon as it is charged (`$8559`).
LaserCharging:
  DEFB $00

; The overload bar's screen byte: $54B1-$54B8 (row 21 columns 17-24, scan line
; 4; drawn in lines 4-6), full at $54B9
;
; ResetBars sets `$54B1`; OverloadAddStep moves it right; at `$54B9` the bar is
; full and a life is lost (not in practice); CoolOverload moves it left down to
; `$54B1`. The `mine` and `overload` recordings start with it poked to `$54B8`
; and the bar full.
OverloadBarPointer:
  DEFW $0000

  ORG $A52F

; At each level start: both bars empty, the pointers, LaserCharging on,
; CHARGING LASER (or DEMO)
;
; Clears the 8 bytes of the overload bar (`$54B1`) and of the energy bar
; (`$54F1`) in their three pixel rows, OverloadBarPointer = `$54B1`,
; EnergyBarPointer = `$54F1`, LaserCharging = `$FF`, MessageNumber = 1, and
; MessageText = ChargingMessage; in the demo (`$8379` set) DemoMessage on level
; 0 only (on later demo levels the message is left as it is).
;
; Called by `$843C` (at `$8515`) at each level start and restart after a lost
; life. Evidence: 164 runs (all recordings but `gameover`).
;
; Witness: L1 196 (c1, c1g, cheat, controls, energy, energy-out, hof, kempston,
; menu, mine, overload, L x20, rzx x59).
ResetBars:
  LD HL,Screen+5297
  LD (OverloadBarPointer),HL
  XOR A
  LD B,$08
ClearOverloadLoop:
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  DEC H
  DEC H
  INC L
  DJNZ ClearOverloadLoop
  LD HL,Screen+5361             ; the energy bar
  LD B,$08
ClearEnergyLoop:
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  DEC H
  DEC H
  INC L
  DJNZ ClearEnergyLoop
  LD HL,Screen+5361             ; the energy pointer, LaserCharging $FF,
                          ; MessageNumber 1
  LD (EnergyBarPointer),HL
  LD A,$FF
  LD (LaserCharging),A
  LD A,$01
  LD (MessageNumber),A
  LD A,(DemoFlag)         ; the demo: DEMO on its first level only
  AND A
  JR Z,ResetBarsCharging
  LD A,(Level)
  AND A
  RET NZ
  LD HL,DemoMessage
  LD (MessageText),HL
  RET
ResetBarsCharging:
  LD HL,ChargingMessage   ; CHARGING LASER
  LD (MessageText),HL
  RET

; A pass of the laser's charge: turn the mirrors at random, the energy bar + 2
; steps; full: the play starts
;
; From DrainEnergy while LaserCharging is set, once a pass. For each of the 9 x
; 15 cells of the grid (`$FD23`, 17 bytes a row) that holds a mirror
; (`$01-$10`) it draws a random pair from `$8E15` (C = its H): bit 0 set turns
; the mirror (with 30 mirrors or more on the level, `$837A`, bits 1 and 2 must
; be set too: 1 in 8 rather than 1 in 2), bit 3 chooses the way (+1 or -1 of 16
; angles, kept in `$01-$10`), and the cell's four characters are marked for
; redraw in DrawMarks (`$E321`, 2 a mark). So every level starts with its
; mirrors scrambled.
;
; Then SoundFlags bit 4 (the charge's tone, every frame) and two bits into the
; energy bar (`SCF; RRA` twice: it fills from the left); a full byte moves
; EnergyBarPointer right. At `$54F9` the bar is full: the pointer back to
; `$54F8`, EnergyTick and LaserCharging 0, MessageText = BlankMessage,
; SoundFlags 0, and the sound `$81F2` (PlaySound, 18 frames).
;
; 32 passes a level start (8 bytes of 4 steps): `rzx-011752` frames 230-382.
;
; Evidence: 3328 runs (104 level starts x 32).
;
; Witness: L1 4352 (c1, c1g, cheat, controls, energy, energy-out, hof,
; kempston, menu, mine, overload, L x20, rzx x59).
ChargeLaser:
  LD HL,DrawMarks+33
  LD DE,LevelGrid+35
  LD C,$09
ChargeRowLoop:
  LD B,$0F
ChargeCellLoop:
  PUSH BC
  PUSH HL
  PUSH DE
  CALL Random
  LD C,H                  ; C = the random byte's high half
  POP DE
  POP HL
  LD A,(DE)               ; a mirror ($01-$10)? bit 0 of the random byte?
  DEC A
  CP $10
  JR NC,ChargeNextCell
  EX AF,AF'
  BIT 0,C
  JR Z,ChargeNextCell
  LD A,(MirrorCount)      ; 30 mirrors or more: bits 1 and 2 as well
  CP $1E
  JR C,ChargeTurn
  BIT 1,C
  JR Z,ChargeNextCell
  BIT 2,C
  JR Z,ChargeNextCell
ChargeTurn:
  BIT 3,C                 ; bit 3: one way or the other
  JR Z,ChargeTurnBack
  EX AF,AF'
  INC A
  AND $0F
  INC A
  JR ChargeStore
ChargeTurnBack:
  EX AF,AF'
  DEC A
  AND $0F
  INC A
ChargeStore:
  LD (DE),A               ; the new angle; the cell's 2 x 2 characters marked
                          ; for redraw
  PUSH HL
  LD BC,$001F
  LD A,$02
  LD (HL),A
  INC L
  LD (HL),A
  ADD HL,BC
  LD (HL),A
  INC L
  LD (HL),A
  POP HL
ChargeNextCell:
  INC DE
  INC HL
  INC HL
  POP BC
  DJNZ ChargeCellLoop
  PUSH DE                 ; the next row: marks + 34 (2 rows of 32 less the 30
                          ; done), grid + 2 (the guards)
  LD DE,$0022
  ADD HL,DE
  POP DE
  INC DE
  INC DE
  DEC C
  JR NZ,ChargeRowLoop
  LD A,(SoundFlags)       ; SoundFlags bit 4; the energy bar two steps on
  SET 4,A
  LD (SoundFlags),A
  LD HL,(EnergyBarPointer)
  LD A,(HL)
  SCF
  RRA
  SCF
  RRA
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  CP $FF
  RET NZ
  INC L                   ; the byte full: the next one; $54F9 = the bar full
  LD A,L
  LD (EnergyBarPointer),A
  CP $F9
  RET C
  DEC A                   ; charged: the play starts
  LD (EnergyBarPointer),A
  XOR A
  LD (EnergyTick),A
  LD (LaserCharging),A
  LD HL,BlankMessage
  LD (MessageText),HL
  XOR A
  LD (SoundFlags),A
  LD HL,ChargedSound
  CALL PlaySound
  RET

; Each pass: the charge while LaserCharging, else critical / low / drained and
; a step every rate frames
;
; Called by the main loop `$854A` at `$85C9`, once a pass. While LaserCharging
; is set: ChargeLaser. Else:
;
; - EnergyBarPointer at `$54F1` (one byte left): `$837E` = `$FF` (the main loop
; then flashes the beam with bit 3 of FrameCounter, `$8587`) and ENERGY LEVEL
; CRITICAL (MessageNumber `$0C`) unless a more urgent one is shown;
;
; - EnergyTick below the rate (the operand of `CP` at EnergyRate `$A63B`,
; written by the level set-up `$84D2` from the table `$8385`): return. Else
; EnergyTick = 0 and the bar loses a step (`SLA` of its byte in three rows: it
; shrinks from the right); an empty byte moves the pointer left: at `$54F2`
; ENERGY LOW (`$0A`), at `$54F0` EnergyDrained.
;
; So a level lasts 64 steps of `rate` frames (level 1: `$5A` = 90, 5760 frames,
; 115 s, plus the pass's wait). `energy`: charged at about frame 690, drained
; at 6450. The POKE "Infinite Energy" (`$A63D`, `RET C` made `RET`) stops it
; here.
;
; Evidence: 90 776 runs.
;
; Witness: L1 110999 (c1, c1g, cheat, controls, energy, energy-out, hof,
; kempston, menu, mine, overload, L x20, rzx x59).
DrainEnergy:
  LD A,(LaserCharging)
  AND A
  JP NZ,ChargeLaser
  LD A,(EnergyBarPointer) ; one byte left: critical
  CP $F1
  JR NZ,DrainEnergyTick
  LD A,$FF
  LD (EnergyCritical),A
  LD A,(MessageNumber)
  CP $0C
  JR NC,DrainEnergyTick
  LD A,$0C
  LD (MessageNumber),A
  LD HL,EnergyCriticalMessage
  LD (MessageText),HL
DrainEnergyTick:
  LD A,(EnergyTick)
EnergyRate:
  CP $64                  ; CP n: n is the level's energy rate (frames a step),
                          ; written by the level set-up $84D2
  RET C
  XOR A                   ; a step: the bar's byte shifted left in its three
                          ; rows
  LD (EnergyTick),A
  LD HL,(EnergyBarPointer)
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
  RET NZ
  DEC L                   ; the byte empty: the pointer one left; $54F0
                          ; drained, $54F2 low
  LD (EnergyBarPointer),HL
  LD A,L
  CP $F0
  JR Z,EnergyDrained
  CP $F2
  RET NZ
  LD A,(MessageNumber)    ; ENERGY LOW, unless a more urgent message
  CP $0A
  RET NC
  LD A,$0A
  LD (MessageNumber),A
  LD HL,EnergyLowMessage
  LD (MessageText),HL
  RET
EnergyDrained:
  LD A,$17                ; ENERGY DRAINED: LifeLost $8ED3 = $FF, $8378 = $FF
                          ; (the laser off)
  LD (MessageNumber),A
  LD HL,DrainedMessage
  LD (MessageText),HL
  LD A,$FF
  LD (LifeLost),A
  LD (BeamStartDirection),A
  RET

; Each pass: the beam on a mine (MINE ALERT, 4 steps), in the laser (OVERLOAD,
; 1 step), else cool down
;
; Called by the main loop at `$85BF`. BeamOnMine `$8ED4` (set by the beam
; `$8F6C`): MessageNumber `$13`, MineAlertMessage, then OverloadStep and three
; more OverloadAddStep. BeamInLaser `$8ED5`: SoundFlags bit 2 on and bit 1 off,
; OVERLOAD (`$12`) unless a more urgent message other than MINE ALERT is shown,
; OverloadStep. Neither: CoolOverload.
;
; Evidence: 90 821 runs; MINE ALERT 1753 (`mine`, `gameover`, 46 RZX segments),
; OVERLOAD (`$A6A6`) in `overload` and the RZX segments.
;
; Witness: L1 111052 (c1, c1g, cheat, controls, energy, energy-out, gameover,
; hof, kempston, menu, mine, overload, L x20, rzx x59).
UpdateOverload:
  LD A,(BeamOnMine)
  AND A
  JR Z,OverloadBeamInLaser
  LD A,$13                ; on a mine: MINE ALERT and four steps
  LD (MessageNumber),A
  LD HL,MineAlertMessage
  LD (MessageText),HL
  CALL OverloadStep
  CALL OverloadAddStep
  CALL OverloadAddStep
  JP OverloadAddStep
OverloadBeamInLaser:
  LD A,(BeamInLaser)      ; the beam back in the laser?
  AND A
  JR Z,CoolOverload
  LD A,(SoundFlags)       ; the overload tone on, the mine's off
  SET 2,A
  RES 1,A
  LD (SoundFlags),A
  LD A,(MessageNumber)
  CP $13
  JR Z,OverloadShowMessage
  CP $12
  JR NC,OverloadStep
OverloadShowMessage:
  LD A,$12                ; OVERLOAD
  LD (MessageNumber),A
  LD HL,OverloadMessage
  LD (MessageText),HL

; Clear BeamOnMine and BeamInLaser for the next pass, then one step
;
; The beam sets the two flags again on each pass it meets a mine or the laser.
; Evidence: 8226 runs.
;
; Witness: L1 9139 (gameover, hof, mine, overload, L x20, rzx x55).
OverloadStep:
  XOR A
  LD (BeamInLaser),A
  LD (BeamOnMine),A

; One step on the overload bar; full ($54B9): LifeLost, unless practice
;
; Returns at once when the bar is full (OverloadBarPointer `$54B9`). The POKE
; "Infinite Time" turns this `RET Z` at `$A6D3` into `RET`: the bar never
; fills. Else one bit into the byte (`SCF; RRA` in three rows: it fills from
; the left); a full byte moves the pointer right; at `$54B9` LifeLost `$8ED3` =
; `$FF` unless PracticeFlag `$8407` is set.
;
; Evidence: 13 485 runs; full (`$A6EE`) 41 times (`mine`, `overload`,
; `gameover`, 24 RZX segments).
;
; Witness: L1 15400 (gameover, hof, mine, overload, L x20, rzx x55).
OverloadAddStep:
  LD HL,(OverloadBarPointer)
  LD A,L
  CP $B9
  RET Z
  LD A,(HL)
  SCF
  RRA
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  DEC H
  DEC H
  CP $FF
  RET NZ
  INC L
  LD (OverloadBarPointer),HL
  LD A,L
  CP $B9
  RET NZ
  LD A,(PracticeFlag)     ; full: a life lost, but not in practice
  AND A
  RET NZ
  LD A,$FF
  LD (LifeLost),A
  RET

; Neither mine nor laser: the two tones off, OVERLOAD / MINE ALERT taken off,
; one step back
;
; From UpdateOverload. SoundFlags bits 1 and 2 cleared; MessageNumber `$12` or
; `$13`: 0 and BlankMessage. The bar's byte shifted left (a step back); an
; empty byte moves OverloadBarPointer left, not below `$54B1`.
;
; Evidence: 82 595 runs.
;
; Witness: L1 101913 (c1, c1g, cheat, controls, energy, energy-out, hof,
; kempston, menu, mine, overload, L x20, rzx x59).
CoolOverload:
  LD A,(SoundFlags)
  AND $F9
  LD (SoundFlags),A
  LD A,(MessageNumber)
  CP $13
  JR Z,CoolOverloadQuiet
  CP $12
  JR NZ,CoolOverloadStep
CoolOverloadQuiet:
  XOR A                   ; the message off
  LD (MessageNumber),A
  LD HL,BlankMessage
  LD (MessageText),HL
CoolOverloadStep:
  LD HL,(OverloadBarPointer)
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
  RET NZ
  LD A,L
  CP $B1
  RET Z
  DEC L
  LD (OverloadBarPointer),HL
  RET

  ORG $AAE3

; The gremlin: four frames of 16 x 16 pixels (2 bytes a row), a dithered blob
; that wobbles
;
; DrawGremlin ORs frame GremlinPhase / 32 (`$AAE3` + GremlinPhase) into the
; pixel buffer. Evidence: read in 54 RZX segments.
GremlinFrames:
  DEFB $05,$00            ; frame 0
  DEFB $2A,$A0
  DEFB $55,$50
  DEFB $2A,$A8
  DEFB $55,$54
  DEFB $AA,$AA
  DEFB $55,$54
  DEFB $AA,$AA
  DEFB $55,$55
  DEFB $2A,$AA
  DEFB $55,$55
  DEFB $2A,$AA
  DEFB $15,$54
  DEFB $0A,$AA
  DEFB $05,$54
  DEFB $00,$A0
GremlinFrame1:
  DEFB $02,$A0            ; frame 1
  DEFB $15,$54
  DEFB $2A,$A8
  DEFB $15,$54
  DEFB $2A,$AA
  DEFB $55,$54
  DEFB $2A,$AA
  DEFB $55,$54
  DEFB $2A,$AA
  DEFB $55,$54
  DEFB $2A,$AA
  DEFB $55,$54
  DEFB $2A,$A8
  DEFB $15,$54
  DEFB $2A,$A8
  DEFB $05,$40
GremlinFrame2:
  DEFB $00,$50            ; frame 2
  DEFB $02,$AA
  DEFB $05,$54
  DEFB $0A,$AA
  DEFB $15,$55
  DEFB $2A,$AA
  DEFB $55,$55
  DEFB $2A,$AA
  DEFB $55,$54
  DEFB $AA,$AA
  DEFB $55,$54
  DEFB $AA,$A8
  DEFB $55,$50
  DEFB $2A,$A0
  DEFB $55,$40
  DEFB $0A,$00
GremlinFrame3:
  DEFB $00,$00            ; frame 3
  DEFB $05,$50
  DEFB $2A,$AA
  DEFB $55,$54
  DEFB $2A,$AA
  DEFB $55,$55
  DEFB $AA,$AA
  DEFB $55,$55
  DEFB $AA,$AA
  DEFB $55,$55
  DEFB $AA,$AA
  DEFB $55,$54
  DEFB $2A,$AA
  DEFB $55,$54
  DEFB $0A,$A0
  DEFB $00,$00

; Eight gremlin records of 6 bytes: delay, turns, X, Y, the cell's address
;
; +0 delay: the passes (counted every other pass) until it appears; 0 when it
; walks; `$FF` would park it (no writer found). Set by the level set-up `$84B3`
; to `$41`, `$4B`, `$55` ... (`$41` + 10 x n) with +1 = 0, and by the cursor's
; kill (`$9AD2`) to `$C8`.
;
; +1 turns: while not 0 the gremlin stands on a mirror and turns it a step a
; pass (GremlinTurnMirror).
;
; +2, +3 X, Y: the place in characters of the play area, 0-28 and 0-16 (a cell
; is 2 x 2; even values are on a cell).
;
; +4, +5 the grid address (`$FDxx`) of the cell it stands on, +5 = 0 between
; cells. The cursor's fire (`$9AC5`) compares it with the turned mirror's cell.
;
; Only GremlinCount (0-8) of them are used. Evidence: written in every level
; start; read in 54 RZX segments.
Gremlins:
  DEFB $00,$00,$00,$00,$00,$00 ; gremlin 0
  DEFB $00,$00,$00,$00,$00,$00 ; gremlin 1
  DEFB $00,$00,$00,$00,$00,$00 ; gremlin 2
  DEFB $00,$00,$00,$00,$00,$00 ; gremlin 3
  DEFB $00,$00,$00,$00,$00,$00 ; gremlin 4
  DEFB $00,$00,$00,$00,$00,$00 ; gremlin 5
  DEFB $00,$00,$00,$00,$00,$00 ; gremlin 6
  DEFB $00,$00,$00,$00,$00,$00 ; gremlin 7

; GremlinMove's new X before it is accepted
GremlinNewX:
  DEFB $00

; GremlinMove's new Y
GremlinNewY:
  DEFB $00

; The level's number of gremlins, 0-8: the second byte of its pair in $8385
; ($84D7)
;
; Read by UpdateGremlins and the cursor's kill `$9AB6`. Values in the table:
; 0-5 and 8 (level 1: 0; level 3: 2).
GremlinCount:
  DEFB $00

; The animation frame x 32: + $20 each pass (0, $20, $40, $60); bit 5 clear:
; the delays count
GremlinPhase:
  DEFB $00

; The four moves (dX, dY): right, down, left, up
;
; GremlinMove picks one at random (`$8E15` L AND 3).
GremlinSteps:
  DEFB $01,$00
  DEFB $00,$01
  DEFB $FF,$00
  DEFB $00,$FF

; Each pass: count the waiting gremlins down, make them appear, walk or turn
; the others, draw them
;
; Called by the main loop (`$85A8`) when the laser is charged. GremlinPhase +
; `$20` (the next frame, `RES 7`). For each of GremlinCount records (IX =
; Gremlins, 6 bytes each): delay `$FF`: skip; delay not 0: on passes with
; GremlinPhase bit 5 clear count it down, at 0 GremlinAppear; delay 0: turns
; left: GremlinTurnMirror, else GremlinMove, then DrawGremlin.
;
; So the first gremlin appears 2 x 65 passes after the charge (`rzx-011752`,
; level 3: the charge ends at frame 382, the first GremlinAppear at 850), the
; next ones 20 passes apart.
;
; Evidence: 87 502 runs; GremlinAppear in 54 RZX segments.
;
; Witness: L1 106709 (c1, c1g, cheat, controls, energy, energy-out, hof,
; kempston, menu, mine, overload, L x20, rzx x59).
UpdateGremlins:
  LD A,(GremlinPhase)
  ADD A,$20
  RES 7,A
  LD (GremlinPhase),A
  LD IX,Gremlins
  LD A,(GremlinCount)
  AND A
  RET Z
  LD B,A
GremlinLoop:
  PUSH BC
  LD A,(IX+$00)
  AND A
  JR Z,GremlinActive
  CP $FF
  JR Z,GremlinNext
  LD B,A                  ; waiting: count down on every other pass
  LD A,(GremlinPhase)
  BIT 5,A
  JR NZ,GremlinNext
  LD A,B
  DEC A
  LD (IX+$00),A
  AND A
  JR NZ,GremlinNext
  CALL GremlinAppear
  JR GremlinNext
GremlinActive:
  LD A,(IX+$01)           ; turns left: turn the mirror, else walk
  AND A
  JR Z,GremlinWalk
  CALL GremlinTurnMirror
  JR GremlinShow
GremlinWalk:
  CALL GremlinMove
GremlinShow:
  CALL DrawGremlin
GremlinNext:
  LD BC,$0006
  ADD IX,BC
  POP BC
  DJNZ GremlinLoop
  RET

; A random empty cell in columns 3-10, rows 0-7: the gremlin is there; BEWARE
; OF THE GREMLINS
;
; X = 2 x ((L AND 7) + 3), Y = 2 x (H AND 7) from `$8E15`; the cell `$FD12 + 17
; x (row + 1) + column`. Not empty: delay = 1 (another try on the next counted
; pass). Empty: GremlinsMessage (MessageNumber 4) unless a more urgent one is
; shown, and DrawGremlin.
;
; Evidence: 4910 runs (54 RZX segments); the message 253 times.
;
; Witness: L1 5139 (hof, L x18, rzx x54).
GremlinAppear:
  CALL Random
  LD A,L
  AND $07
  ADD A,$03
  LD C,A
  ADD A,A
  LD (IX+$02),A
  LD A,H
  AND $07
  LD B,A
  ADD A,A
  LD (IX+$03),A
  LD A,$12                ; the cell's address: $FD12 + 17 x (row + 1) + column
  INC B
GremlinCellRowLoop:
  ADD A,$11
  DJNZ GremlinCellRowLoop
  ADD A,C
  LD L,A
  LD H,$FD
  LD A,(HL)
  AND A
  JR Z,GremlinWarn
  LD A,$01                ; taken: try again next time
  LD (IX+$00),A
  RET
GremlinWarn:
  LD A,(MessageNumber)
  CP $04
  JP NC,DrawGremlin
  LD A,$04
  LD (MessageNumber),A
  LD HL,GremlinsMessage
  LD (MessageText),HL
  JP DrawGremlin

; One turn of the mirror under the gremlin: +1 or -1 of 16 angles at random
;
; Turns - 1; the cell at +4/+5 gets (code AND `$0F`) + 1 (one way) or (code - 2
; AND `$0F`) + 1 (the other), by bit 0 of `$8E15`'s L. The beam and the redraw
; see the new angle on the next pass.
;
; Evidence: 11 188 runs (52 RZX segments).
;
; Witness: L1 12407 (hof, L x15, rzx x52).
GremlinTurnMirror:
  DEC A
  LD (IX+$01),A
  CALL Random
  LD A,L
  LD L,(IX+$04)
  LD H,(IX+$05)
  BIT 0,A
  JR Z,GremlinTurnBack
  LD A,(HL)
  AND $0F
  INC A
  LD (HL),A
  RET
GremlinTurnBack:
  LD A,(HL)
  DEC A
  DEC A
  AND $0F
  INC A
  LD (HL),A
  RET

; A step in a random direction, inside the play area, onto a free cell or
; between cells
;
; New X = X + dX below 29, new Y = Y + dY below 17 (GremlinSteps). On a cell
; (both even): the cell's address to +4/+5; an empty cell, a cell `$40` or a
; mine `$41`: go; a mirror (`$01-$10`): go and stand, turns = `$8E33` AND 7;
; anything else: no step. Between cells: +5 = 0 and the four characters under
; the new place (CharMap `$E000` + 32 x (Y + 1) + X + 1) must each be below
; `$31` or `$74-$7B`, else no step.
;
; Evidence: 97 827 runs (54 RZX segments).
;
; Witness: L1 112465 (hof, L x18, rzx x54).
GremlinMove:
  LD C,(IX+$02)
  LD B,(IX+$03)
  CALL Random
  LD A,L
  AND $03
  ADD A,A
  LD HL,GremlinSteps
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,(HL)
  ADD A,C
  CP $1D
  RET NC
  LD (GremlinNewX),A      ; the new X
  LD C,A
  LD D,A
  INC HL                  ; the new Y
  LD A,(HL)
  ADD A,B
  CP $11
  RET NC
  LD (GremlinNewY),A
  LD B,A
  SRL B                   ; both even: on a cell
  JR C,GremlinBetweenCells
  SRL C
  JR C,GremlinBetweenCells
  LD A,$12
  INC B
GremlinMoveRowLoop:
  ADD A,$11
  DJNZ GremlinMoveRowLoop
  ADD A,C
  LD L,A
  LD H,$FD
  LD (IX+$04),L
  LD (IX+$05),H
  LD A,(HL)               ; empty, $40, $41: go; a mirror: go and turn; else
                          ; stay
  AND A
  JP Z,GremlinCommit
  CP $40
  JP Z,GremlinCommit
  CP $41
  JP Z,GremlinCommit
  CP $11
  RET NC
  LD A,(RandomSeed+$0001) ; a mirror: 0-7 turns
  AND $07
  LD (IX+$01),A
  JP GremlinCommit
GremlinBetweenCells:
  LD (IX+$05),$00         ; the four characters under it: below $31 or $74-$7B
  INC D
  INC A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,L
  ADD A,D
  LD L,A
  LD A,$E0
  ADD A,H
  LD H,A
  LD A,(HL)
  CP $31
  JR C,GremlinCharRight
  CP $74
  RET C
  CP $7C
  RET NC
GremlinCharRight:
  INC L
  LD A,(HL)
  CP $31
  JR C,GremlinCharBelow
  CP $74
  RET C
  CP $7C
  RET NC
GremlinCharBelow:
  LD BC,$001F
  ADD HL,BC
  LD A,(HL)
  CP $31
  JR C,GremlinCharBelowRight
  CP $74
  RET C
  CP $7C
  RET NC
GremlinCharBelowRight:
  INC L
  LD A,(HL)
  CP $31
  JR C,GremlinCommit
  CP $74
  RET C
  CP $7C
  RET NC
GremlinCommit:
  LD A,(GremlinNewX)      ; the new place
  LD (IX+$02),A
  LD A,(GremlinNewY)
  LD (IX+$03),A
  RET

; Mark the gremlin's 2 x 2 characters for redraw and OR its frame into the
; pixel buffer
;
; DrawMarks `$E300` + 32 x (Y + 1) + X + 1 (and the three next to it) = 2; the
; frame (`$AAE3` + GremlinPhase) ORed into PixelBuffer `$E900` + 256 x (Y + 1)
; + X + 1, 16 rows of 2 bytes. The +1 is the play area's border character.
;
; Evidence: 109 267 runs.
;
; Witness: L1 125184 (hof, L x18, rzx x54).
DrawGremlin:
  LD C,(IX+$02)
  INC C
  LD B,(IX+$03)
  INC B
  LD L,B
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,L
  ADD A,C
  LD L,A
  LD A,$E3
  ADD A,H
  LD H,A
  LD A,$02
  LD (HL),A
  INC L
  LD (HL),A
  LD DE,$001F
  ADD HL,DE
  LD (HL),A
  INC L
  LD (HL),A
  LD HL,GremlinFrames     ; the frame
  LD A,(GremlinPhase)
  LD E,A
  LD D,$00
  ADD HL,DE
  EX DE,HL
  LD HL,PixelBuffer
  ADD HL,BC
  LD A,$10
  LD BC,$001F
DrawGremlinLoop:
  EX AF,AF'
  LD A,(DE)
  OR (HL)
  LD (HL),A
  INC L
  INC DE
  LD A,(DE)
  OR (HL)
  LD (HL),A
  INC DE
  ADD HL,BC
  EX AF,AF'
  DEC A
  JR NZ,DrawGremlinLoop
  RET

; 51 bytes of 0 that no recording reads or writes
;
; No instruction in the image addresses them.
UnusedAD46:
  DEFS $33
