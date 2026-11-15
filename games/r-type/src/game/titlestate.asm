; --------------------------------------------------------------------------------------------------------------------
; titlestate.asm: The star task's switches and the Kempston probe
; --------------------------------------------------------------------------------------------------------------------

; Switch the star task on (task 0 of TaskTable)
;
; A = 1, then StarsSet writes it to the task's switch byte (TaskTable + 2).
;
; Witness: L1 38 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, gameover,
; hiscore, hiscore-typed, l2-l8).
StarsOn:
  LD A,$01

; StarsSet
;
; Used by the routine at StarsOff.
StarsSet:
  LD (TaskTable+$0002),A  ; write A to the star task's switch
  RET

; Switch the star task off
;
; Witness: L1 58 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, ending,
; gameover, hiscore, hiscore-typed, l1-l7).
StarsOff:
  XOR A
  JR StarsSet

; Point the star task at the play's star states
;
; Writes 0 into the star phase operand, patches the star step to LD A,2 and
; points the star task's state pointer at $7380.
;
; Witness: L1 17 (c1, ending, gameover, hiscore, l1-l7).
PlayStars:
  XOR A
  LD (l_BECA+$0001),A
  LD HL,l_BF11+$0013
  LD (HL),$3E
  INC HL
  LD (HL),$02
  LD HL,TitleStars
  LD (StarTask+$0005),HL
  RET

; Point the star task at the title's star states
;
; Writes $3C into the star phase operand, patches the star step to LD A,8 / LD
; (HL),A and points the state pointer at $80D8.
;
; Witness: L1 38 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, gameover,
; hiscore, hiscore-typed, l2-l8).
TitleStarsOn:
  LD A,$3C
  LD (l_BECA+$0001),A
  LD HL,l_BF11+$0013
  LD (HL),$08
  INC HL
  LD (HL),$77
  LD HL,PlayStarStates
  LD (StarTask+$0005),HL
  RET

; Look for a Kempston joystick: read port $1F up to 255 times
;
; Stores the low four bits of the first non-zero read in KempstonAbsent, or 0
; when all 255 reads were 0 (a Kempston at rest). The 48K's floating bus reads
; non-zero, so 0 means "a Kempston is there". Called once from the entry.
;
; Witness: L1 1 (c1).
ProbeKempston:
  LD E,$FF
  LD BC,$001F
l_73F1:
  IN A,(C)
  AND $0F
  JR NZ,l_73FA
  DEC E
  JR NZ,l_73F1
l_73FA:
  LD (KempstonAbsent),A
  RET

; The pixel shadow, third third, pixel line 4 (from $7400)
ShadowLine4:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00

; the title page's lines: BLAST OFF AND STRIKE / THE EVIL BYDO EMPIRE / PRESS
; FIRE TO PLAY / 'ENTER' SELECTS KEYS / (c) 1987 BY IREM CORP.
TitleTexts:
  INCBIN "res/texts/title.bin",$0000,99

; "ENTER YOUR NAME PILOT $"
EnterNameText:
  INCBIN "res/texts/enter-name.bin",$0000,23

; the last control read: bit 0 up, 1 down, 2 left, 3 right, 4 fire, 5 detach
ControlBits:
  DEFB $00
ControlMethod:
  DEFB $04                ; 1 Interface 2, 2 keys, 3 Kempston, 4 Sinclair /
                          ; cursor, as the title's fire picked it
ControlVector:
  DEFB $2D,$8B            ; the reader of the control method, taken from
                          ; ControlVectors

; zeros
ShadowLine4Tail:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00

; "TODAY'S BEST PILOTS"
BestPilotsText:
  INCBIN "res/texts/best-pilots.bin",$0000,19

; four tables of 9 bytes: the next direction of a reflected laser by the cells
; around it (BounceShot)
ForceShotTurns:
  DEFB $00,$00,$06,$00,$FF,$02,$FF,$01,$05
  DEFB $00,$00,$05,$00,$FF,$01,$01,$02,$06
  DEFB $00,$00,$02,$00,$01,$06,$FF,$05,$01
  DEFB $00,$00,$01,$00,$01,$05,$01,$06,$02

; The blocks ClearPlayState zeroes at every start: address, length, ...; a zero
; word ends it
;
; $4000 6144 (the screen), $7E00 640 (SolidMap), $8100 640, $8501 252
; (EnemySlots), $7AD7 28 (HitList), $5EB4 332 (the shots, missiles and
; explosions), $8386 109 (EnemyShots and the ship's records), $71D4 12
; (ForceShotsA/B), $7DF9 7 (LevelVars).
ClearList:
  INCBIN "res/tables/clear-list.bin",$0000,38

; the objects of each explosion kind and step, DrawExplosions
ExplosionFrames:
  DEFB $51,$50,$4F,$4E,$4D,$4C,$4B,$4B
  DEFB $57,$56,$55,$54,$53,$52,$4B,$4B
  DEFB $57,$56,$55,$54,$53,$52,$4B,$4B

; zeros, then the pixel shadow's line 5 from $7600
ShadowLine5:
  DEFB $61,$61,$5F,$5F,$5F,$5E,$5E,$5E
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00
