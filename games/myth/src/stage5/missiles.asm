; --------------------------------------------------------------------------------------------------------------------
; missiles.asm: Dameron's missiles: 8 records of 6 bytes at $7000
;
; A missile record (HudPicture $7000 + 6n, n = 0-7; $FF at +0 free): +0 the column, +1 the line (from line 48:
; ScreenLineTable + $60), +2 the kind, +3 the frame or the path, +4 the step. Kinds: 1 a fireball (3 x 16, frames
; 0-3), 2 an arcing shot along ArcSteps0-3 (MoveCurvedShot $9DC6), 3 a bolt (3 x 9, frames 8-11), 4 a burst (3 x 24,
; frames $13-$17, placed by NextDameronForm $A0C4 when a form is beaten). Frame n is at SpriteBank $B3BA + the word n
; of SpriteFrameOffsets $938E (SpriteFrameAddress $9378). Every missile is tested against the hero first
; (CheckShotHitsHero $A33E: C = 9 damage); kinds 1-3 move one column left every other pass and are freed at column -1
; (FreeShot $A015).
;
; The shot records are at HudPicture $7000: 8 of 6 bytes (+0 the byte column, $FF free; +1 the play-area line; +2 the
; kind: 1 straight FireballMissile $8080, 2 curved MoveCurvedShot, 3 BoltMissile $834E, 4 an explosion BurstMissile
; $819D; +3 and +4 per kind). UpdateDameronMissiles $804A runs them every pass, CheckShotHitsHero first.
; --------------------------------------------------------------------------------------------------------------------

  ORG $7F10

; Free Dameron's missiles: fill $7000-$707F with $FF
;
; 128 bytes of $FF (LDIR), more than the 8 records x 6 bytes
; UpdateDameronMissiles reads (FindFreeMissile may write a ninth record at
; MissilesEnd $7030, inside this area). Called once by StageEntry.
;
; Witness: L1 3 (ending, rzx-r5, s5-right).
ClearMissiles:
  LD HL,HudPicture
  LD DE,HudPicture+$0001
  LD BC,$007F
  LD (HL),$FF
  LDIR
  RET

  ORG $804A

; Run each of the 8 missile records at $7000 that is not free
;
; IX = HudPicture $7000, 6 bytes a record; UpdateMissile for each with +0 not
; $FF. Every pass from MainLoop.
;
; Witness: L1 11696 (ending, rzx-r5, s5-right).
UpdateDameronMissiles:
  LD IX,HudPicture
  LD B,$08
UpdateDameronMissilesNext:
  PUSH BC
  LD A,(IX+$00)
  CP $FF
  JP Z,UpdateMissilesSkip
  CALL UpdateMissile
UpdateMissilesSkip:
  LD BC,$0006
  ADD IX,BC
  POP BC
  DJNZ UpdateDameronMissilesNext
  RET

; One missile: hurt the hero if it is on it, then move and draw it by its kind
;
; CheckShotHitsHero $A33E first (the hero's column X / 8 equal to +0 and the
; hero's line - $20 - the missile's line from -7 to 13: DamageHero with C = 9).
; Then by the kind +2: 1 FireballMissile, 2 MoveCurvedShot $9DC6 (the arcing
; shot), 3 BoltMissile, 4 BurstMissile; others return.
;
; Witness: L1 14710 (ending, rzx-r5, s5-right).
UpdateMissile:
  CALL CheckShotHitsHero
  LD A,(IX+$02)
  CP $01
  JP Z,FireballMissile
  CP $02
  JP Z,MoveCurvedShot
  CP $03
  JP Z,BoltMissile
  CP $04
  JP Z,BurstMissile
  RET

; Kind 1: a fireball flying left one column every other pass; 3 bytes x 16
; lines, frames 0-3
;
; On even passes the column +0 - 1; at -1 the record is freed (FreeShot $A015).
; The frame PassCounter AND 3 (SpriteFrameAddress $9378), drawn at
; ScreenLineTable[$30 + line] + column, 3 bytes a line, the second character
; row at + $20 from the first's top. Launched by DameronFire in form 0.
;
; Witness: L1 8132 (ending, rzx-r5, s5-right).
FireballMissile:
  LD A,(PassCounter)
  AND $01
  JP NZ,FireballMissileDraw
  LD A,(IX+$00)
  DEC A
  CP $FF
  JP Z,FreeShot
  LD (IX+$00),A
FireballMissileDraw:
  LD C,(IX+$01)
  LD B,$00
  LD IY,ScreenLineTable+96
  ADD IY,BC
  ADD IY,BC
  LD BC,$0010
  LD A,(IY+$00)
  ADD A,(IX+$00)
  LD L,A
  LD H,(IY+$01)
  LD A,(PassCounter)
  AND $03
  CALL SpriteFrameAddress
  LD C,H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD H,C
  LD A,L
  ADD A,$20
  LD L,A
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  RET

; Kind 4: a burst standing in place: frames $13-$17 twice with effect 0
; between, then freed
;
; On even passes the step +4 + 1 (from $FF). Steps $64 and up: nothing (the
; first pass). Steps 0-4: the frame +3 = the step; step 5: PlaySoundVector E =
; 0; steps 5-9 not drawn; 10-14: the frame = the step - 10; 15: freed (FreeShot
; $A015). Drawn as frame +3 + $13, 3 bytes x 24 lines. Placed by
; NextDameronForm $A0C4 (21 places, $A10D-$A335) when a form is beaten.
;
; Witness: L1 1187 (ending, rzx-r5).
BurstMissile:
  LD A,(PassCounter)
  AND $01
  JP NZ,BurstMissileStep
  INC (IX+$04)
BurstMissileStep:
  LD A,(IX+$04)
  CP $64
  RET NC
  LD (IX+$03),A
  CP $05
  JP C,BurstMissileDraw
  CP $05
  JP NZ,BurstMissileLate
  LD DE,$0000
  CALL PlaySoundVector
BurstMissileLate:
  CP $0F                  ; steps 5 and on: free at 15, hidden under 10, else
                          ; the step - 10
  JP Z,FreeShot
  CP $0A
  RET C
  SUB $0A
  LD (IX+$03),A
BurstMissileDraw:
  LD C,(IX+$01)
  LD B,$00
  LD IY,ScreenLineTable+96
  ADD IY,BC
  ADD IY,BC
  LD BC,$0010
  LD A,(IY+$00)
  ADD A,(IX+$00)
  LD L,A
  LD H,(IY+$01)
  LD A,(IX+$03)
  ADD A,$13
  CALL SpriteFrameAddress
  LD C,H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD H,C
  LD BC,$0020
  ADD HL,BC
  LD C,H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD H,C
  LD BC,$0020
  ADD HL,BC
  LD C,H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  RET

; Kind 3: a bolt flying left one column every other pass; 3 bytes x 9 lines,
; frames 8-11
;
; As FireballMissile with the frame (PassCounter AND 3) + 8 and 9 lines.
; Launched by DameronFire in forms 1 and 2.
;
; Witness: L1 3438 (ending, rzx-r5).
BoltMissile:
  LD A,(PassCounter)
  AND $01
  JP NZ,BoltMissileDraw
  LD A,(IX+$00)
  DEC A
  CP $FF
  JP Z,FreeShot
  LD (IX+$00),A
BoltMissileDraw:
  LD C,(IX+$01)
  LD B,$00
  LD IY,ScreenLineTable+96
  ADD IY,BC
  ADD IY,BC
  LD BC,$0010
  LD A,(IY+$00)
  ADD A,(IX+$00)
  LD L,A
  LD H,(IY+$01)
  LD A,(PassCounter)
  AND $03
  ADD A,$08
  CALL SpriteFrameAddress
  LD C,H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD H,C
  LD A,L
  ADD A,$20
  LD L,A
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  RET

; The arcing shot's line step a pass, path 0: -4 x 4 ... +5, $64 ends (23
; bytes)
;
; Read by MoveCurvedShot $9DC6 (kind 2) at ArcSteps + the step +4 for the path
; +3 = 0: the line +1 changes by the signed byte; $64 holds the last step (+4 -
; 1 and read again). Paths 0-3 are chosen by DameronFire in form 3
; ((PassCounter / 16) AND 3).
ArcSteps0:
  DEFB $FC,$FC,$FC,$FC,$FD,$FD,$FD,$FE
  DEFB $FE,$FF,$00,$01,$02,$02,$03,$03
  DEFB $03,$04,$04,$04,$04,$05,$64

; Path 1: -4 ... +5, $64 ends (18 bytes)
;
; As ArcSteps0, for +3 = 1.
ArcSteps1:
  DEFB $FC,$FD,$FD,$FE,$FE,$FF,$FF,$FF
  DEFB $00,$01,$01,$01,$02,$02,$03,$04
  DEFB $05,$64

; Path 2: -3 ... +5, $64 ends (14 bytes)
;
; As ArcSteps0, for +3 = 2.
ArcSteps2:
  DEFB $FD,$FE,$FE,$FF,$FF,$00,$01
  DEFB $01,$02,$02,$03,$04,$05,$64

; Path 3: -3, -2 x 4, -1 x 8, 0, +1 x 8 ... +5, $64 ends (34 bytes)
;
; As ArcSteps0, for +3 = 3 (the longest, flattest arc).
ArcSteps3:
  DEFB $FD,$FE,$FE,$FE,$FE,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$00,$01,$01
  DEFB $01,$01,$01,$01,$01,$01,$02,$02
  DEFB $02,$02,$03,$03,$03,$04,$04,$04
  DEFB $05,$64

  ORG $8C6C

; IX = the first free missile record ($FF at +0) of the 8 at $7000; NZ either
; way
;
; Found: A = 0, CP 1, so NZ. None free: the loop ends with IX = MissilesEnd
; $7030 (a ninth record past the table, inside the 128 bytes ClearMissiles
; fills) and NZ from the last CP $FF. So the callers' RET Z never returns; with
; all 8 records busy a new missile is written at MissilesEnd $7030, which
; UpdateDameronMissiles never reads. Called by DameronFire and NextDameronForm
; $A0C4 (21 calls).
;
; Witness: L1 445 (ending, rzx-r5, s5-right).
FindFreeMissile:
  LD IX,HudPicture
  LD B,$08
  LD DE,$0006
FindFreeMissileNext:
  LD A,(IX+$00)
  CP $FF
  JP Z,FindFreeMissileFound
  ADD IX,DE
  DJNZ FindFreeMissileNext
  RET
FindFreeMissileFound:
  LD A,$00
  CP $01
  RET

  ORG $9DC6

; Move and draw a curved shot (kind 2): leftwards, its line along one of four
; paths
;
; IX = the record. On even passes (PassCounter $FE4D bit 0 clear) X - 1; X
; leaving 0 frees it (FreeShot). Every pass +4 + 1 and the step = path[+4], the
; path by +3: 0 ArcSteps0 $840B, 1 ArcSteps1 $8422, 2 ArcSteps2 $8434, else
; ArcSteps3 $8442; a step $64 is the path's end (the index goes back one: the
; last step repeats). Y + the step; $A0 and up frees it. Drawn straight onto
; the screen: the column X written into the three ADD A,n at
; CurvedShotColumn1-3, the lines from ScreenLinePlay + 2Y; the frame
; CurvedShotFrames[PassCounter AND 3] (4-7) by SpriteFrameAddress; 3 lines of 3
; zero bytes above, the 16 lines of 3 bytes, 3 zero lines below (it wipes its
; own trail up and down).
;
; Jumped to from $8072 (kind 2).
;
; Witness: L1 1953 (ending, rzx-r5).
MoveCurvedShot:
  LD A,(PassCounter)
  AND $01
  JP NZ,CurvedShotStep
  LD A,(IX+$00)
  DEC A
  CP $FF
  JP Z,FreeShot
  LD (IX+$00),A
CurvedShotStep:
  INC (IX+$04)
CurvedShotRead:
  LD C,(IX+$04)           ; the path's step at +4; $64 = hold
  LD B,$00
  LD HL,ArcSteps0
  LD A,(IX+$03)
  CP $00
  JP Z,CurvedShotAdd
  LD HL,ArcSteps1
  CP $01
  JP Z,CurvedShotAdd
  LD HL,ArcSteps2
  CP $02
  JP Z,CurvedShotAdd
  LD HL,ArcSteps3
CurvedShotAdd:
  ADD HL,BC
  LD A,(HL)
  CP $64
  JP NZ,CurvedShotMove
  DEC (IX+$04)
  JP CurvedShotRead
CurvedShotMove:
  LD A,(IX+$01)
  ADD A,(HL)
  CP $A0
  JP NC,FreeShot
  LD (IX+$01),A
  LD C,(IX+$01)
  LD B,$00
  LD IY,ScreenLinePlay
  ADD IY,BC
  ADD IY,BC
  LD BC,$0010
  LD A,(IX+$00)
  LD (CurvedShotColumn2+$0001),A
  LD (CurvedShotColumn1+$0001),A
  LD (CurvedShotColumn3+$0001),A
  LD A,(PassCounter)
  AND $03
  LD C,A
  LD B,$00
  LD HL,CurvedShotFrames
  ADD HL,BC
  LD A,(HL)
  CALL SpriteFrameAddress
  LD B,$03
CurvedShotClearTop:
  LD A,(IY+$00)
CurvedShotColumn1:
  ADD A,$00               ; ADD A,n: n = the column, written at $9E2F
  LD L,A
  LD H,(IY+$01)
  LD (HL),$00
  INC L
  LD (HL),$00
  INC L
  LD (HL),$00
  INC IY
  INC IY
  DJNZ CurvedShotClearTop
  LD B,$10
CurvedShotDrawLine:
  LD A,(IY+$00)
CurvedShotColumn2:
  ADD A,$00               ; ADD A,n: n = the column, written at $9E2C
  LD L,A
  LD H,(IY+$01)
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC IY
  INC IY
  DJNZ CurvedShotDrawLine
  LD B,$03
CurvedShotClearBottom:
  LD A,(IY+$00)
CurvedShotColumn3:
  ADD A,$00               ; ADD A,n: n = the column, written at $9E32
  LD L,A
  LD H,(IY+$01)
  LD (HL),$00
  INC L
  LD (HL),$00
  INC L
  LD (HL),$00
  INC IY
  INC IY
  DJNZ CurvedShotClearBottom
  RET

; The curved shot's frames: 4, 5, 6, 7, then 7, 6, 5, 4
;
; MoveCurvedShot reads the first four ($9E3D, PassCounter AND 3); the second
; four, the ping-pong's way back, are read by no code.
CurvedShotFrames:
  DEFB $04,$05,$06,$07
  DEFB $07,$06,$05,$04

  ORG $9F57

; Add a missile to the first eight slots of the missile records $75E0
;
; In: D column, E line, C type, B and A its parameters. 16 records of 6 bytes:
; +0 column ($FF free), +1 line, +2 type, +3 $FF, +4 B, +5 A. The search starts
; after the slot of MissileCursor $FE38 (round robin over 8). A = $FA puts a
; Random byte in +5. Out: Z when the eight slots are full, else NZ. As in stage
; 1 at $B28D, the same code. No caller in stage 5's code (no CALL, JP or word
; names $9F57: work/stage2/stage5/B-raw.py).
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
AddMissile:
  PUSH BC
  PUSH DE
  PUSH AF
  LD BC,HeroShots
  JP AddMissileFrom

; Add a missile to the slots 8-15 ($7610) of the missile records
;
; As in stage 1 at $B296, the same code. No caller in stage 5's code (no CALL,
; JP or word names $9F60: work/stage2/stage5/B-raw.py).
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
AddMissileHigh:
  PUSH BC
  PUSH DE
  PUSH AF
  LD BC,HeroShots6

; Add a missile to the eight slots from BC
;
; Reached by AddMissile's JP; AddMissileHigh runs into it. As stage 1's
; AddMissileFrom $B29C.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
AddMissileFrom:
  LD D,$00
AddMissileSearch:
  LD A,(MissileCursor)
  INC A
  AND $07
  LD (MissileCursor),A
  SLA A
  LD L,A
  SLA A
  ADD A,L
  LD L,A
  LD H,$00
  ADD HL,BC
  INC D
  LD A,D
  CP $08
  JP Z,AddMissileFull
  LD A,(HL)
  CP $FF
  JP NZ,AddMissileSearch
  POP AF
  POP DE
  POP BC
  LD (HL),D
  INC HL
  LD (HL),E
  INC HL
  LD (HL),C
  INC HL
  LD (HL),$FF
  INC HL
  LD (HL),B
  INC HL
  LD (HL),A
  CP $FA
  RET NZ
  PUSH HL
  CALL Random
  POP HL
  LD (HL),A
  LD A,$01
  CP $02
  RET
AddMissileFull:
  POP AF
  POP DE
  POP BC

; A = 1, Z set: the "yes" exit of the tests
;
; As in stage 1 at $B2DC, the same code. Only AddMissileFull runs into it; no
; CALL, JP or word names $9FA8.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
ReturnZ:
  LD A,$01
  CP $01
  RET

; A = 1, Z clear: the "no" exit of the tests
;
; As in stage 1 at $B2E1, the same code. No caller in stage 5's code (no CALL,
; JP or word names $9FAD: work/stage2/stage5/B-raw.py).
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
ReturnNZ:
  LD A,$01
  CP $00
  RET

; Run the handler of every missile in use in the records $75E0
;
; The 16 records (6 bytes each, IY): a record whose +0 is not $FF calls
; MissileHandlers[+2] through the CALL at MissileCall, whose operand it writes.
; IX is kept. As stage 1's UpdateMissiles $B2E6, with a one-word handler table.
; No caller in stage 5's code (no CALL, JP or word names $9FB2:
; work/stage2/stage5/B-raw.py).
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
UpdateMissiles:
  PUSH IX
  LD B,$10
  LD IY,HeroShots
  LD DE,$0006
UpdateMissilesLoop:
  LD A,(IY+$00)
  CP $FF
  JP Z,UpdateMissilesNext
  PUSH BC
  LD L,(IY+$02)
  SLA L
  LD H,$00
  LD BC,MissileHandlers
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (MissileCall+$0001),DE
MissileCall:
  CALL $0000              ; CALL nn: nn = the missile's handler, written at
                          ; $9FD5
  POP BC
  LD DE,$0006
UpdateMissilesNext:
  ADD IY,DE
  DJNZ UpdateMissilesLoop
  POP IX
  RET

; The handler of missile type 0: $7EE2
;
; One word; a type 1 or more would read BufferAddressHL's code bytes as the
; handler. Read only by UpdateMissiles ($9FCD).
MissileHandlers:
  DEFW AbortGame

  ORG $A015

; Free the shot record IX (+0 = $FF)
;
; Jumped to by the shots and explosions when they end: $808E (a straight shot
; past column 0), $81C3 (an explosion's last frame), $835C, MoveCurvedShot
; $9DD4 and $9E13.
;
; Witness: L1 422 (ending, rzx-r5, s5-right).
FreeShot:
  LD (IX+$00),$FF
  RET

  ORG $A33E

; Damage the hero by 9 when the shot IX meets him
;
; Called for every used shot record by UpdateMissile $8065 each pass. The
; hero's column = HeroRecord $BA7E / 8 must equal +0; d = HeroLine $BA7F - $20
; - (+1) (his line less the shot's); a hit when -7 <= d <= 13: DamageHero $7EDA
; with C = 9 (EnergyChange $FE53 - 9). The shot is not freed.
;
; In s5-right the column matched 391 times, the line never: no shot hit the
; hero; ending: 32 hits (CheckShotHitsDamage $A361), 5 lives lost.
;
; Witness: L1 14710 (ending, rzx-r5, s5-right).
CheckShotHitsHero:
  LD A,(HeroRecord)
  SRL A
  SRL A
  SRL A
  CP (IX+$00)
  RET NZ
  LD A,(HeroLine)
  SUB $20
  SUB (IX+$01)
  JP NC,CheckShotHitsBelow
  NEG
  CP $08
  RET NC
  JP CheckShotHitsDamage
CheckShotHitsBelow:
  CP $0E                  ; d >= 0: a hit under 14
  RET NC
CheckShotHitsDamage:
  LD C,$09
  CALL DamageHero
  RET
