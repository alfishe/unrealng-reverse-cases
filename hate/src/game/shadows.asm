; The ground height under the shadow being drawn
ShadowGround:
  DEFB $00

; Shadows into the playfield buffer, then the sprites
;
; Step 8 of the pass (docs/04-game-loop.md 4.3), before the blit. For every
; entry of the shadow list $FE64 it ANDs a shadow into the strips at the ground
; under the object, then jumps to $EAE3, which draws the sprite list $FF00 over
; it.
;
; Types 0-3 and 4-10: the shadow is first built as a mask in $6500 (68 bytes, 4
; strips of 17, or 33 bytes, 3 strips of 11; set to $FF = clear), from the
; shape tables below the image ($5CE0, $5DE8, $5EF0 for types 0-3; $5B60,
; $5BE0, $5C60 for 4-10), at an offset by the phase (+1). The Mask* helpers AND
; runs of shape bytes into it, strip by strip; each MaskStep* helper moves one
; profile byte (2 units along) further and shifts its run by the change of the
; ground height from ShadowGround, so the shadow follows the slope. The mask is
; then ANDed into the buffer from the entry's mask offset (+5), +4 strips, at
; the address +6/+7.
;
; Types 11-13 (ShadowTiny): 4 bytes a strip from $5B00, $5B20 or $5B40 (the
; ground level, rising by 1, or more over the next profile byte), 8 bytes a
; phase, ANDed straight into the buffer.
DrawShadows:
  LD HL,Im2Table+$0064
  LD (ShadowListPtr),HL
ShadowsLoop:
  LD HL,(ShadowListPtr)
  LD A,(HL)
  CP $FF
  JP Z,DrawSprites        ; the shadow list is done: the sprites
  INC L
  LD E,(HL)               ; E = +1 phase
  INC L
  LD C,(HL)               ; BC = +2, +3 the profile under the object
  INC L
  LD B,(HL)
  CP $04
  JR C,ShadowBigMask
  CP $0B
  JP C,ShadowMidMask
  JP ShadowTiny
ShadowBigMask:
  EX AF,AF'               ; types 0-3
  LD A,(BC)               ; the ground height where the shadow starts
  AND $1F
  LD (ShadowGround),A
  LD HL,SpriteScratch     ; the mask: 4 strips of 17 bytes, clear
  LD A,$FF
  LD D,$44
ClearBigMaskLoop:
  LD (HL),A
  INC L
  DEC D
  JR NZ,ClearBigMaskLoop
  EX AF,AF'
  LD HL,$5DE8             ; the shape: $5DE8 type 0, $5EF0 type 2, $5CE0 types
                          ; 1 and 3
  AND A
  JR Z,BigShapeChosen
  LD HL,$5EF0
  CP $02
  JR Z,BigShapeChosen
  LD HL,$5CE0
BigShapeChosen:
  LD A,E                  ; one sequence of runs a phase
  CP $03
  JP Z,BigMaskPhase3
  CP $02
  JP Z,BigMaskPhase2
  CP $01
  JP Z,BigMaskPhase1
  LD DE,SpriteScratch+$0002 ; phase 0
  CALL MaskRuns5x5
  LD D,$04
  CALL MaskStepRuns4x6
  LD D,$06
  CALL MaskStepRuns3x7x3
  LD D,$08
  CALL MaskStepRuns1x6x4
  LD D,$17
  CALL MaskStepRuns5x5
  LD D,$19
  CALL MaskStepRuns4x6
  JP ShadowBigApply
BigMaskPhase1:
  LD DE,$0040             ; phase 1
  ADD HL,DE
  LD DE,SpriteScratch+$0003
  CALL MaskRuns4x6
  LD D,$05
  CALL MaskStepRuns3x7x3
  LD D,$07
  CALL MaskStepRuns1x6x4
  LD D,$16
  CALL MaskStepRuns5x5
  LD D,$18
  CALL MaskStepRuns4x6
  LD D,$1A
  CALL MaskStepRuns3x7x3
  JR ShadowBigApply
BigMaskPhase2:
  LD DE,$0083             ; phase 2
  ADD HL,DE
  LD DE,SpriteScratch+$0004
  CALL MaskRuns3x7x3
  LD D,$06
  CALL MaskStepRuns1x6x4
  LD D,$15
  CALL MaskStepRuns5x5
  LD D,$17
  CALL MaskStepRuns4x6
  LD D,$19
  CALL MaskStepRuns3x7x3
  LD D,$1B
  CALL MaskStepRuns1x6x4
  JR ShadowBigApply
BigMaskPhase3:
  LD DE,$00C7             ; phase 3
  ADD HL,DE
  LD DE,SpriteScratch+$0005
  CALL MaskRuns1x6x4
  LD D,$14
  CALL MaskStepRuns5x5
  LD D,$16
  CALL MaskStepRuns4x6
  LD D,$18
  CALL MaskStepRuns3x7x3
  LD D,$1A
  CALL MaskStepRuns1x6x4
  LD D,$29
  CALL MaskStepRuns5x5
ShadowBigApply:
  LD HL,(ShadowListPtr)
  INC L
  INC L
  INC L                   ; C = +4 strips
  INC L
  LD C,(HL)               ; A = +5 the first mask byte
  INC L
  LD A,(HL)               ; DE = +6, +7 the buffer address
  INC L
  LD E,(HL)
  INC L
  LD D,(HL)
  INC L
  LD (ShadowListPtr),HL
  LD HL,SpriteScratch
  ADD A,L
  LD L,A
  EX DE,HL
BigApplyStripLoop:
  PUSH HL
  LD B,$04
BigApplyLineLoop:
  LD A,(DE)               ; 17 lines: buffer AND mask
  AND (HL)
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  AND (HL)
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  AND (HL)
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  AND (HL)
  LD (HL),A
  INC L
  INC E
  DJNZ BigApplyLineLoop
  LD A,(DE)
  AND (HL)
  LD (HL),A
  INC E
  POP HL
  DEC L
  DEC L
  DEC L
  DEC L                   ; the next strip: 4 lines lower, two pages on
  INC H
  INC H
  RES 6,H
  DEC C
  JR NZ,BigApplyStripLoop
  JP ShadowsLoop
ShadowMidMask:
  EX AF,AF'               ; types 4-10
  LD A,(BC)
  AND $1F                 ; the ground height where the shadow starts
  LD (ShadowGround),A
  LD HL,SpriteScratch     ; the mask: 3 strips of 11 bytes, clear
  LD A,$FF
  LD D,$21
ClearMidMaskLoop:
  LD (HL),A
  INC L
  DEC D
  JR NZ,ClearMidMaskLoop
  EX AF,AF'               ; the shape: $5B60 type 10, $5C60 types 8-9, $5BE0
                          ; types 4-7
  LD HL,$5B60
  CP $0A
  JR Z,MidShapeChosen
  LD HL,$5C60
  CP $08
  JR NC,MidShapeChosen
  LD HL,$5BE0
MidShapeChosen:
  LD A,E
  CP $03
  JP Z,MidMaskPhase3
  CP $02
  JP Z,MidMaskPhase2
  CP $01
  JP Z,MidMaskPhase1
  LD DE,$0040
  ADD HL,DE
  LD DE,SpriteScratch+$0002
  CALL MaskRuns3x5
  LD D,$04
  CALL MaskStepRuns2x6
  LD D,$0D
  CALL MaskStepRuns5x3
  LD D,$0F
  CALL MaskStepRuns4x4
  JR ShadowMidApply
MidMaskPhase1:
  LD DE,$0060
  ADD HL,DE
  LD DE,SpriteScratch+$0003
  CALL MaskRuns2x6
  LD D,$0C
  CALL MaskStepRuns5x3
  LD D,$0E
  CALL MaskStepRuns4x4
  LD D,$10
  CALL MaskStepRuns3x5
  JR ShadowMidApply
MidMaskPhase2:
  LD DE,SpriteScratch
  CALL MaskRuns5x3
  LD D,$02
  CALL MaskStepRuns4x4
  LD D,$04
  CALL MaskStepRuns3x5
  LD D,$06
  CALL MaskStepRuns2x6
  JR ShadowMidApply
MidMaskPhase3:
  LD DE,$0020
  ADD HL,DE
  LD DE,SpriteScratch+$0001
  CALL MaskRuns4x4
  LD D,$03
  CALL MaskStepRuns3x5
  LD D,$05
  CALL MaskStepRuns2x6
  LD D,$0E
  CALL MaskStepRuns5x3
ShadowMidApply:
  LD HL,(ShadowListPtr)
  INC L
  INC L
  INC L
  INC L
  LD C,(HL)
  INC L
  LD A,(HL)
  INC L
  LD E,(HL)
  INC L
  LD D,(HL)
  INC L
  LD (ShadowListPtr),HL
  LD HL,SpriteScratch
  ADD A,L
  LD L,A
  EX DE,HL
MidApplyStripLoop:
  PUSH HL                 ; 11 lines: buffer AND mask
  LD A,(DE)
  AND (HL)
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  AND (HL)
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  AND (HL)
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  AND (HL)
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  AND (HL)
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  AND (HL)
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  AND (HL)
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  AND (HL)
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  AND (HL)
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  AND (HL)
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  AND (HL)
  LD (HL),A
  INC E
  POP HL
  DEC L
  DEC L
  DEC L
  DEC L
  INC H
  INC H
  RES 6,H
  DEC C
  JR NZ,MidApplyStripLoop
  JP ShadowsLoop
ShadowTiny:
  LD A,(BC)               ; types 11-13
  AND $1F
  LD D,A
  INC BC                  ; the ground rise to the next profile byte
  LD A,(BC)
  AND $1F
  SUB D
  LD BC,$5B00             ; flat: $5B00
  AND A
  JR Z,TinyShapeChosen
  LD BC,$5B20             ; a rise of 1: $5B20
  CP $01
  JR Z,TinyShapeChosen
  LD BC,$5B40             ; any other change, a fall too: $5B40
TinyShapeChosen:
  LD A,E                  ; + 8 x phase
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,C
  LD C,A
  INC L
  LD A,(HL)
  EX AF,AF'
  INC L
  LD A,(HL)               ; + the skipped bytes (+5)
  ADD A,C
  LD C,A
  INC L
  LD E,(HL)
  INC L
  LD D,(HL)
  INC L
  LD (ShadowListPtr),HL
  LD L,C
  LD H,B
  EX AF,AF'
  LD B,A
TinyStripLoop:
  PUSH DE
  LD A,(DE)               ; 4 lines a strip: buffer AND shape
  AND (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  AND (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  AND (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  AND (HL)
  LD (DE),A
  INC HL
  POP DE
  DEC E
  DEC E
  DEC E
  DEC E
  INC D
  INC D
  RES 6,D
  DJNZ TinyStripLoop
  JP ShadowsLoop

; Next profile byte, then MaskRuns5x3
;
; The MaskStep* entries share one head: BC moves to the next profile byte; E =
; $6500 + D + (its ground height - ShadowGround), the mask position of the run
; in this strip, raised by the slope. They fall into the matching MaskRuns*
; entry.
MaskStepRuns5x3:
  LD A,(ShadowGround)     ; the ground height where the shadow starts
  LD E,A
  INC BC                  ; the next profile byte
  LD A,(BC)
  AND $1F
  SUB E                   ; its ground, relative
  ADD A,D                 ; + the run's place in the mask
  LD DE,SpriteScratch
  ADD A,E
  LD E,A

; AND 5 shape bytes into the mask at DE, then 3 more 7 on
;
; In: HL = the shape, DE = the mask in $6500. The MaskRuns* entries AND short
; runs of shape bytes into the mask: a run, a gap, a run (the gap is the step
; to the next strip of the mask), HL running on. This one: 5, a gap of 7, 3.
MaskRuns5x3:
  CALL MaskAnd5
  LD A,$07
  ADD A,E
  LD E,A
  JP MaskAnd3

; Next profile byte, then MaskRuns4x4
;
; Used by the routine at DrawShadows.
MaskStepRuns4x4:
  LD A,(ShadowGround)
  LD E,A
  INC BC
  LD A,(BC)
  AND $1F
  SUB E
  ADD A,D
  LD DE,SpriteScratch
  ADD A,E
  LD E,A

; AND 4 shape bytes, then 4 more 7 on
;
; Used by the routine at DrawShadows.
MaskRuns4x4:
  CALL MaskAnd4
  LD A,$07
  ADD A,E
  LD E,A
  JP MaskAnd4

; Next profile byte, then MaskRuns3x5
;
; Used by the routine at DrawShadows.
MaskStepRuns3x5:
  LD A,(ShadowGround)
  LD E,A
  INC BC
  LD A,(BC)
  AND $1F
  SUB E
  ADD A,D
  LD DE,SpriteScratch
  ADD A,E
  LD E,A

; AND 3 shape bytes, then 5 more 7 on
;
; Used by the routine at DrawShadows.
MaskRuns3x5:
  CALL MaskAnd3
  LD A,$07
  ADD A,E
  LD E,A
  JP MaskAnd5

; Next profile byte, then MaskRuns2x6
;
; Used by the routine at DrawShadows.
MaskStepRuns2x6:
  LD A,(ShadowGround)
  LD E,A
  INC BC
  LD A,(BC)
  AND $1F
  SUB E
  ADD A,D
  LD DE,SpriteScratch
  ADD A,E
  LD E,A

; AND 2 shape bytes, then 6 more 7 on
;
; Used by the routine at DrawShadows.
MaskRuns2x6:
  LD A,(DE)
  AND (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  AND (HL)
  LD (DE),A
  INC HL
  LD A,$07
  ADD A,E
  LD E,A
  JP MaskAnd6

; Next profile byte, then MaskRuns5x5
;
; Used by the routine at DrawShadows.
MaskStepRuns5x5:
  LD A,(ShadowGround)
  LD E,A
  INC BC
  LD A,(BC)
  AND $1F
  SUB E
  ADD A,D
  LD DE,SpriteScratch
  ADD A,E
  LD E,A

; AND 5 shape bytes, then 5 more 11 on
;
; Used by the routine at DrawShadows.
MaskRuns5x5:
  CALL MaskAnd5
  LD A,$0B
  ADD A,E
  LD E,A
  JP MaskAnd5

; Next profile byte, then MaskRuns4x6
;
; Used by the routine at DrawShadows.
MaskStepRuns4x6:
  LD A,(ShadowGround)
  LD E,A
  INC BC
  LD A,(BC)
  AND $1F
  SUB E
  ADD A,D
  LD DE,SpriteScratch
  ADD A,E
  LD E,A

; AND 4 shape bytes, then 6 more 11 on
;
; Used by the routine at DrawShadows.
MaskRuns4x6:
  CALL MaskAnd4
  LD A,$0B
  ADD A,E
  LD E,A
  JP MaskAnd6

; Next profile byte, then MaskRuns3x7x3
;
; Used by the routine at DrawShadows.
MaskStepRuns3x7x3:
  LD A,(ShadowGround)
  LD E,A
  INC BC
  LD A,(BC)
  AND $1F
  SUB E
  ADD A,D
  LD DE,SpriteScratch
  ADD A,E
  LD E,A

; AND 3 shape bytes, 7 more 11 on, 3 more 11 on
;
; Used by the routine at DrawShadows.
MaskRuns3x7x3:
  CALL MaskAnd3
  LD A,$0B
  ADD A,E
  LD E,A
  CALL MaskAnd7
  LD A,$0B
  ADD A,E
  LD E,A
  JP MaskAnd3

; Next profile byte, then MaskRuns1x6x4
;
; Used by the routine at DrawShadows.
MaskStepRuns1x6x4:
  LD A,(ShadowGround)
  LD E,A
  INC BC
  LD A,(BC)
  AND $1F
  SUB E
  ADD A,D
  LD DE,SpriteScratch
  ADD A,E
  LD E,A

; AND 1 shape byte, 6 more 12 on, 4 more 11 on
;
; Used by the routine at DrawShadows.
MaskRuns1x6x4:
  LD A,(DE)
  AND (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,$0C
  ADD A,E
  LD E,A
  CALL MaskAnd6
  LD A,$0B
  ADD A,E
  LD E,A
  JR MaskAnd4

; AND 7 shape bytes into the mask
;
; In: HL = the shape, DE = the mask. One chain of entries: MaskAnd7, MaskAnd6,
; MaskAnd5, MaskAnd4 and MaskAnd3 AND that many bytes (HL and E move on; E
; stays on the last byte).
MaskAnd7:
  LD A,(DE)
  AND (HL)
  LD (DE),A
  INC HL
  INC E

; AND 6 shape bytes into the mask
;
; Used by the routines at MaskRuns2x6, MaskRuns4x6 and MaskRuns1x6x4.
MaskAnd6:
  LD A,(DE)
  AND (HL)
  LD (DE),A
  INC HL
  INC E

; AND 5 shape bytes into the mask
;
; Used by the routines at MaskRuns5x3, MaskRuns3x5 and MaskRuns5x5.
MaskAnd5:
  LD A,(DE)
  AND (HL)
  LD (DE),A
  INC HL
  INC E

; AND 4 shape bytes into the mask
;
; Used by the routines at MaskRuns4x4, MaskRuns4x6 and MaskRuns1x6x4.
MaskAnd4:
  LD A,(DE)
  AND (HL)
  LD (DE),A
  INC HL
  INC E

; AND 3 shape bytes into the mask
;
; Used by the routines at MaskRuns5x3, MaskRuns3x5 and MaskRuns3x7x3.
MaskAnd3:
  LD A,(DE)
  AND (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  AND (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  AND (HL)
  LD (DE),A
  INC HL
  RET
