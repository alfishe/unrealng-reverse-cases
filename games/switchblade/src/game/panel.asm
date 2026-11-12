; --------------------------------------------------------------------------------------------------------------------
; panel.asm: Energy, lives, score and the panel
;
; The panel code lies over the tape loader's page ($FF00-$FFFF, copied by the bootstrap from $5093). The main loop
; calls PanelWeapon $FF01 and PanelMeters $FF64 on every pass: each value is compared with its shown copy, and only a
; change is drawn.
; --------------------------------------------------------------------------------------------------------------------

  ORG $9615

; Take A from Hiro's vitality; at zero a life is lost
;
; A = the damage. Callers: HurtHiro `$988A` (4, 8 from kind `$2D`) and the
; fall-damage slot `$920A` (2 a step); the two POKE files' "Invincibility" puts
; `RET` here (38421).
;
; Nothing happens while `$6651` is set (the energy ball of the invulnerability
; pickup, or the 170 frames after a lost life). The pending combat move `$6650`
; is cancelled. Vitality `$6642` - A; above zero it is stored.
;
; **At zero or below** (`$962A`, deaths 4 runs, gameover 1; not during the end,
; `$6652` set): SpawnShield `$9962` with 170 frames (`$AA`): the manual's
; invulnerability after a lost life; 10 bytes from `$5C00` reload `$6642-$664B`
; (vitality `$20`, the meters' shown copies, the combat speed-ups `$6644` = 1,
; the power meter and its minimum 0, the weapon `$664B` = 0, the fist) or,
; during a boss fight (`$9A59` set), only 7: the weapon and its bullets
; `$6649-$664B` stay (the manual: Hiro keeps his weapon against a boss). Lives
; `$664D` - 1 (BCD); below zero `JP $5C42`, the game over (gameover frame
; 2429). Else the lives' digits `$6664-$6665` (BcdToDigits `$9A11`) and `JP
; $8365` (the panel's numbers).
;
; The lives as BCD: the last life shows 00 and the game ends when it is lost.
; ZXDB's "Infinite Lives" (`$964B`) misses this release; `$964E` = 0 (the 1 of
; `SUB $01`) gives it (WALKTHROUGH 6.3).
;
; Witness: L1 827 (deaths, gameover, hiscore, play48, rooms, rzx x60, rzxroom
; x7).
LoseEnergy:
  LD C,A
  LD A,(Invulnerable)     ; the energy ball on: no loss
  OR A
  RET NZ
  LD (FireRequest),A      ; cancel the pending combat move
  LD HL,Vitality
  LD A,(HL)
  SUB C                   ; vitality - damage
  JR Z,LoseLife
  JP M,LoseLife
  LD (HL),A               ; still alive
  RET
LoseLife:
  LD A,(EndFlags)         ; vitality gone: not during the end sequence
  OR A
  RET NZ
  LD BC,$00AA             ; the energy ball for 170 frames
  CALL SpawnShield
  LD BC,$000A             ; 10 bytes to reload ...
  LD A,(RunActorSteps+$000E)
  OR A
  JR Z,LoseLifeReload
  LD BC,$0007             ; ... 7 in a boss fight: weapon and bullets kept
LoseLifeReload:
  LD HL,GlobalsInit       ; $5C00 -> $6642-$664B
  LD DE,Vitality
  LDIR
  LD HL,Lives             ; lives - 1, BCD
  LD A,(HL)
  SUB $01
  DAA
  LD (HL),A
  JP M,GameOver           ; below zero: the game over
  LD DE,LivesDigits       ; the lives' two digits
  LD B,$01
  CALL BcdToDigits
  JP PrintScore           ; print the panel's numbers

  ORG $99E7

; Add the score record E to the score
;
; E = a record of the score table in Hiro's page (`$5D82`, 4 bytes: a score
; sprite number, then three BCD bytes, the high first): `$82` 50, `$86` 100,
; `$8A` 200, `$8E` 400, `$92` 700, `$96` 1000, `$9A` 2000, `$9E` 5000, `$A2`
; 7000 (sprite numbers 1-9); then without a sprite `$A6` 50, `$AA` 100, `$AE`
; 200, `$B2` 250, `$B6` 300, `$BA` 350, `$BE` 5000, `$C2` 10000, `$C6` 50000,
; `$CA` 20000, `$CE` 10 (the snapshot `c1/end.szx`). The sprite number goes to
; (IY+$39) of the actor taken or killed. The three bytes are added to
; `$6654-$6656` with DAA, the carry into `$6653`; BcdToDigits `$9A11` writes
; the 8 digits `$665B-$6662`. deaths 1 run.
;
; The enemies' values (their +$0B) match the manual: 50 spikelice, 100 cybats /
; mansnakes / spidorbs, 200, 250, 300, 350, 5000 the giants.
;
; Witness: L1 130 (bossgate, deaths, havok, play48, throw, rzx x47, rzxroom
; x9).
AddScore:
  PUSH BC
  PUSH DE
  PUSH HL
  LD D,$5D                ; the record in Hiro's page
  LD A,(DE)
  INC E
  INC E
  INC E
  LD (IY+$39),A           ; the score sprite to the actor
  LD HL,Score+$0003       ; the three BCD bytes, low first
  XOR A
  LD B,$03
AddScoreLoop:
  LD A,(DE)
  ADC A,(HL)
  DAA
  LD (HL),A
  DEC L
  DEC E
  DJNZ AddScoreLoop
  LD A,B                  ; the carry into the top byte
  ADC A,(HL)
  DAA
  LD (HL),A
  LD B,$04                ; the 8 digits
  LD DE,ScoreDigits
  CALL BcdToDigits
  POP HL
  POP DE
  POP BC
  RET

; Write B BCD bytes at HL as 2B ASCII digits at DE
;
; HL = the BCD bytes, high first; DE = the text. Out: HL, DE past them.
; Callers: AddScore (the score, 4 bytes to `$665B`), LoseEnergy and
; LetterPickup (the lives, 1 byte to `$6664`).
;
; Witness: L1 609 (bossgate, deaths, havok, play48, throw, rzx x63, rzxroom
; x10).
BcdToDigits:
  LD A,(HL)
  RRA
  RRA
  RRA
  RRA
  AND $0F
  ADD A,$30
  LD (DE),A
  INC DE
  LD A,(HL)
  AND $0F
  ADD A,$30
  LD (DE),A
  INC DE
  INC HL
  DJNZ BcdToDigits
  RET

  ORG $FF01

; The weapon bar and the fragment count, when they change
;
; WeaponCount `$6649` against WeaponCountShown: on a change it is stored; at 0
; the default weapon comes back (`$98F3` with HL = WeaponDefaultItem `$5DF8`).
; The bar: 16 bytes at `$7F0D` (the pixel rows of glyphs `$85`/`$86`): 16 -
; count rows cleared, then count rows of `$0E` (count >= 9) or `$E0`, shifted
; one place on odd rows; StatusLine printed (`$836B`). The status line is
; printed tall at the aligned Y `$B8`, so row 7 of glyphs `$85`/`$86` is never
; drawn: units 1 and 9 of the bar are invisible (doc 08, 8.8).
;
; Witness: L1 2036417 (bossgate, deaths, gameover, havok, hiscore, menu,
; play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
PanelWeapon:
  LD HL,WeaponCount
  LD A,(HL)
  INC L
  CP (HL)
  JR Z,PanelFragments
  LD (HL),A
  OR A
  JR NZ,PanelWeaponBar
  LD HL,WeaponDefaultItem
  CALL SetWeapon
  XOR A
PanelWeaponBar:
  LD HL,MeterGlyphs
  LD B,A
  LD A,$10
  SUB B
  JR Z,PanelWeaponFill
PanelWeaponClear:
  LD (HL),$00
  INC HL
  DEC A
  JR NZ,PanelWeaponClear
PanelWeaponFill:
  LD A,B
  OR A
  JR Z,PanelWeaponPrint
PanelWeaponRow:
  LD E,$0E
  LD A,B
  CP $09
  JR NC,PanelWeaponShift
  LD E,$E0
PanelWeaponShift:
  RRA
  JR C,PanelWeaponStore
  RR E
PanelWeaponStore:
  LD (HL),E
  INC HL
  DJNZ PanelWeaponRow
PanelWeaponPrint:
  CALL PrintPanelLine
PanelFragments:
  LD HL,Fragments         ; Fragments $664E against FragmentsShown: sound 5,
                          ; the count's 6 glyph codes from $7F17 + 6n, print
                          ; $82D5
  LD A,(HL)
  INC HL
  CP (HL)
  RET Z
  LD (HL),A
  OR A
  RET Z
  LD A,(Fragments)
  LD B,A
  LD A,$05
  LD (EffectRequest),A
  LD HL,MeterGlyphs+$000A
  LD DE,$0006
PanelFragmentsIndex:
  ADD HL,DE
  DJNZ PanelFragmentsIndex
  LD C,E
  LD DE,FirebladeGlyphs
  LDIR
  LD HL,FirebladePanelText
  JP PrintString

; The charge and energy meters, when they change
;
; Charge `$6645` / ChargeShown to the meter at `$51F8`, Vitality `$6642` /
; VitalityShown to `$51E0`, each through DrawMeter.
;
; Witness: L1 2036423 (bossgate, deaths, gameover, havok, hiscore, menu,
; play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x71, rzxroom x18).
PanelMeters:
  LD HL,Charge
  LD A,(HL)
  INC HL
  CP (HL)
  JR Z,PanelMetersEnergy
  LD DE,Screen+4600
  CALL DrawMeter
PanelMetersEnergy:
  LD HL,Vitality
  LD A,(HL)
  INC HL
  CP (HL)
  RET Z
  LD DE,Screen+4576

; Draw a meter of value A (0-$20) at the screen DE: 8 bytes x 6 pixel rows from
; MeterStrip
;
; Stores A at (HL), the shown copy. MeterPartial `$FFC2` = `$FF`; C = `$BB`
; (full, `$20`), `$C3` (empty, 0), or `$C2` - A / 4 with MeterPartial =
; MeterGradient[A AND 3]. The 8 bytes from `$FF00` + C are a window on
; MeterStrip: full bytes, the partial one, empty ones. Six rows (D + 1 a row).
;
; The entries `$FF90`, `$FF94`, `$FFB2` are split off because the tape loader's
; LD-EDGE routines and its end lie at these addresses while it runs.
;
; Witness: L1 10240 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x15).
DrawMeter:
  LD (HL),A
  LD A,$FF
  LD (MeterPartial),A
  LD C,$BB
  LD A,(HL)
  CP $20
  JR Z,DrawMeterWindow
  LD C,$C3
  OR A
  JR Z,DrawMeterWindow
  AND $03

; MeterGradient[A AND 3]
;
; Witness: L1 784281 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, rzx x70, rzxroom x15).
DrawMeterPartial:
  LD BC,MeterGradient
  ADD A,C

; MeterPartial = the gradient byte; C = $C2 - A / 4
;
; Witness: L1 1567338 (bossgate, deaths, gameover, havok, hiscore, menu,
; play48, rooms, throw, c x2, opt x3, rzx x70, rzxroom x15).
DrawMeterGradient:
  LD C,A
  LD A,(BC)
  LD (MeterPartial),A
  LD A,(HL)
  SRL A
  SRL A
  LD C,A
  LD A,$C2
  SUB C
  LD C,A
; This entry point is used by the routine at DrawMeter.
DrawMeterWindow:
  LD H,$FF
  LD L,C
  LD B,$06
; This entry point is used by the routine at DrawMeterNext.
DrawMeterRow:
  PUSH HL
  PUSH DE
  PUSH BC
  LD BC,$0008
  LDIR
  POP BC
  POP DE

; The next pixel row
;
; Witness: L1 61447 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x70, rzxroom x15).
DrawMeterNext:
  POP HL
  INC D
  DJNZ DrawMeterRow
  RET

; A meter's partial byte for A AND 3 = 0-3 ($55, $D5, $F5, $FD)
MeterGradient:
  INCBIN "res/graphics/panel-meter.bin",$0000,4
MeterStrip:
  INCBIN "res/graphics/panel-meter.bin",$0004,7
MeterPartial:
  INCBIN "res/graphics/panel-meter.bin",$000B,1
MeterEmpty:
  INCBIN "res/graphics/panel-meter.bin",$000C,8

; The panel's attribute row (32 bytes) at $5AE0: the meters, EXTRA, the weapon
; bar, BONUS
PanelAttrs:
  INCBIN "res/graphics/panel-attrs.bin",$0000,32

; Panel attributes to $5AE0; $88AE = Room; Z when in room 4
;
; Called by NewGame `$5CE7` (and the room change). The Z result picks the play
; window's colour (`$46` in room 4, the start room, else 7).
;
; Witness: L1 14 (deaths, gameover, havok, hiscore, menu, play48, throw, c x1,
; opt x3, rzx x1, rzxroom x1).
PanelAttrsRoom:
  LD HL,PanelAttrs
  LD DE,Attributes+736
  LD BC,$0020
  LDIR
  LD A,(Room)
  LD (DrawCellLayers+$0012),A
  CP $04
; This entry point is used by the routine at GlyphBytesAsCode.
PanelAttrsRoomEnd:
  RET                     ; also the target of GlyphBytesAsCode's JP PE (bytes
                          ; read as code)

; The byte after the panel code (0 in the image): not part of the bootstrap's
; copy ($FF01-$FFFE), no reader found
PanelEnd:
  INCBIN "res/leftovers/panel-end.bin",$0000,1
