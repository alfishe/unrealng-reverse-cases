; --------------------------------------------------------------------------------------------------------------------
; fatguy.asm: Level 5's own code: the Fat Guy
;
; Level 5 ends with the Fat Guy (section 7): its exit $42 from section 6 sets LevelHookOn $8A24 to 20, and while it is
; nonzero the game hands the section's objects to this code: SetupSection calls LevelHookA ($C206) in place of the map
; entry scan, UpdateObjects calls LevelHookB ($C209) in place of the trap and enemy updates. The Fat Guy is five trap
; records moved together along one path; he takes 20 hits of the bullet or the blast (LevelHookOn counts them; a death
; of Rick sets it back to 20, $93E2), shoots one shot at a time at Rick, and kills him by touch or by the shot. At the
; last hit he gives 5000 points and falls apart: the records get paths and blast animations that the normal trap code
; then plays, since LevelHookOn is 0 again.
;
; Witnessed only in rzx-l5-20000-poke and rzx-l5-22000-poke (the Fat Guy's fight; the kill in the second).
; --------------------------------------------------------------------------------------------------------------------

; Put the Fat Guy into the first five trap records
;
; For each of the five records of FatGuyParts (8 bytes each) the trap record
; TrapRecords + 24k: +0 = $11 (alive, behaviour $10), +6 = $60 (no trigger
; test, freed at the path's end), the step count +$0E = 0, +7 and +8 from the
; part's +0/+1, the sprite +4/+5, the path +$0F/+$10 and the animation
; +$0A/+$0B. Then the body (record 0) at x $B0, y $0090 with FatGuyPath as its
; path. The other records' paths and animations only play after the kill
; (UpdateTrap); until then FatGuyUpdate places them.
;
; Witness: L1 2 (rzx-l5-20000-poke).
FatGuyStart:
  LD B,$05
  LD DE,$0018
  LD HL,FatGuyParts
  LD IX,TrapRecords
FatGuyStartLoop:
  LD (IX+$00),$11         ; one part: alive, behaviour $10, no trigger test
  LD (IX+$06),$60
  LD (IX+$0E),$00
  LD A,(HL)               ; +7 / +8: the size, for the parts 1-4 the offset
                          ; from the body
  LD (IX+$07),A
  INC HL
  LD A,(HL)
  LD (IX+$08),A
  INC HL
  LD A,(HL)               ; +4/+5: the sprite
  LD (IX+$04),A
  INC HL
  LD A,(HL)
  LD (IX+$05),A
  INC HL
  LD A,(HL)               ; +$0F/+$10: the path played after the kill
  LD (IX+$0F),A
  INC HL
  LD A,(HL)
  LD (IX+$10),A
  INC HL
  LD A,(HL)               ; +$0A/+$0B: the animation played after the kill
  LD (IX+$0A),A
  INC HL
  LD A,(HL)
  LD (IX+$0B),A
  INC HL
  ADD IX,DE
  DJNZ FatGuyStartLoop
  LD A,$B0                ; the body at x $B0, y $90
  LD (TrapRecords+1),A
  LD HL,$0090
  LD (TrapRecords+2),HL
  LD HL,FatGuyPath        ; the body's path while he lives
  LD (TrapRecords+15),HL
  RET

; The Fat Guy's five records: x offset or width, y offset or height, sprite,
; path, animation
;
; 8 bytes a part, read by FatGuyStart: +0 the width (record +7), +1 the height
; (+8): for the parts 1-4 FatGuyPlacePart reads them as the offset from the
; body; +2/+3 the sprite address; +4/+5 the path after the kill; +6/+7 the
; animation after the kill.
FatGuyParts:
  INCBIN "res/level/fat-guy.bin",$0000,40

; The paths the five parts fly off on after the kill (the trap path format)
;
; Count and step pairs, then 0 and the loop address. Each piece jumps (y steps
; -8 to -2), then falls 8 pixels a pass; parts 1 and 3 drift left, 0, 2 and 4
; right, until UpdateTrap frees them off the view or at the loop point (+6 bit
; 5).
FatGuyPiecePaths:
  INCBIN "res/level/fat-guy.bin",$0028,97

; The pieces' animation: frames $22-$25 (sprites 20-23, the blast), looped
;
; One script entered at four places (parts 0 and 4 at $F8C5, 1 at $F8C7, 2 at
; $F8C9, 3 at $F8CB): frames $22, $22, $23, $23, $24, $24, $25, $25, then $FF
; and the jump back to $F8C5.
FatGuyPieceAnims:
  INCBIN "res/level/fat-guy.bin",$0089,11

; A pass of the Fat Guy: move, place the parts, the hits, the touch, the shot
;
; The body (TrapRecords) one step along its path (FatGuyMove), the four other
; parts placed at their offsets from it (FatGuyPlacePart), part 4's sprite
; switched between 43 and 44 every pass (its +9 toggled). The box for the hits
; is part 1's x and y, 48 x 42 (the four lower parts): the bullet in it
; (BulletHits) is spent and counts a hit; the detonator's blast at fuse 4-9
; (BlastHits) counts a hit on every such pass (FatGuyHit). Then the same box
; against Rick (TouchesRick): JP KillRick. Then the shot: FatGuyShoot,
; FatGuyShotMove with IX = EnemyRecords.
;
; Witness: 524 runs (rzx-l5-20000-poke 377, rzx-l5-22000-poke 147); hits 14,
; all from the blast ($F940; the bullet branch $F922 never ran); the touch
; never killed (the JP C at $F946 never jumped).
;
; Witness: L1 524 (rzx-l5-20000-poke, rzx-l5-22000-poke).
FatGuyUpdate:
  LD IX,TrapRecords
  CALL FatGuyMove
  LD IX,TrapRecords+24
  CALL FatGuyPlacePart
  LD IX,TrapRecords+48
  CALL FatGuyPlacePart
  LD IX,TrapRecords+72
  CALL FatGuyPlacePart
  LD IX,TrapRecords+96
  CALL FatGuyPlacePart
  LD HL,Sprites+43*128      ; part 4's sprite: 43 or 44 by its +9
  LD A,(TrapRecords+105)
  XOR $01
  LD (TrapRecords+105),A
  JP Z,FatGuyLegsStore
  LD HL,Sprites+44*128
FatGuyLegsStore:
  LD (TrapRecords+100),HL
  LD HL,(TrapRecords+26)           ; the hit box: part 1's y and x, 48 wide, 42 high
  LD A,(TrapRecords+25)
  LD E,A
  LD BC,$2A30
  LD A,(BulletRecord)
  AND A
  JP Z,FatGuyBlastTest
  PUSH HL
  PUSH DE
  CALL BulletHits
  POP DE
  POP HL
  JP NC,FatGuyBlastTest
  XOR A
  LD (BulletRecord),A
  CALL FatGuyHit
FatGuyBlastTest:
  LD A,(DetonatorFuse)            ; the blast hurts at fuse 4-9
  CP $0A
  JP NC,FatGuyTouchTest
  CP $04
  JP C,FatGuyTouchTest
  PUSH HL
  PUSH DE
  CALL BlastHits
  POP DE
  POP HL
  JP NC,FatGuyTouchTest
  CALL FatGuyHit
FatGuyTouchTest:
  CALL TouchesRick              ; the same box against Rick
  JP C,KillRick
  CALL FatGuyShoot        ; the shot
  LD IX,EnemyRecords
  CALL FatGuyShotMove
  RET

; A hit: one off LevelHookOn; at 0 the Fat Guy dies
;
; Effect 9; LevelHookOn - 1. Not 0: return. 0: 5000 points (AddScore with
; Points5000), effects 5 and 10; the body's path becomes FatGuyPiecePaths and
; its animation FatGuyPieceAnims (the other parts already hold theirs); the
; enemy record EnemyRecords takes the body's x and y as a dying enemy (+$14 =
; $FF, +0 = 1, the vertical speed +$0E/+$0F = $FB00, -5.0: KillEnemy's jump).
; With LevelHookOn 0 the next pass of UpdateObjects runs the trap and enemy
; updates again: the five parts fly off and blow up, the enemy record falls.
;
; Witness: 14 runs (rzx-l5-20000-poke 6, rzx-l5-22000-poke 8); the kill once
; ($F961, rzx-l5-22000-poke).
;
; Witness: L1 14 (rzx-l5-20000-poke, rzx-l5-22000-poke).
FatGuyHit:
  LD A,$09
  CALL PlayEffect
  LD A,(LevelHookOn)
  DEC A
  LD (LevelHookOn),A
  RET NZ
  LD HL,Points5000             ; LevelHookOn reached 0: the Fat Guy dies
  CALL AddScore
  LD A,$05
  CALL PlayEffect
  LD A,$0A
  CALL PlayEffect
  LD HL,FatGuyPiecePaths  ; the pieces' path and animation for the body
  LD (TrapRecords+15),HL
  LD HL,FatGuyPieceAnims
  LD (TrapRecords+10),HL
  LD A,(TrapRecords+1)            ; a dying enemy at the body's place
  LD (EnemyRecords+1),A
  LD HL,(TrapRecords+2)
  LD (EnemyRecords+2),HL
  XOR A
  DEC A
  LD (EnemyRecords+20),A
  LD A,$01
  LD (EnemyRecords),A
  LD HL,$FB00             ; -5.0 in 8.8: the dying jump
  LD (EnemyRecords+14),HL
  RET

; One step of the trap record at IX along its path (no effects, no view test)
;
; UpdateTrap's path step without the $FF effects, the off-view tests and the
; waits: +$0E counts the passes of the current pair (count, step); when it
; reaches the count the next pair is taken, and a 0 count jumps to the address
; after it. The step: the high nibble added to x, the low nibble (signed) to
; the 16-bit y, 7 meaning 8. Only the body (TrapRecords) is moved so.
;
; Witness: L1 524 (rzx-l5-20000-poke, rzx-l5-22000-poke).
FatGuyMove:
  LD L,(IX+$0F)
  LD H,(IX+$10)
  LD A,(IX+$0E)
  CP (HL)
  JP C,FatGuyPathStep
  INC HL                  ; the pair is done: the next one
  INC HL
  LD A,(HL)
  AND A
  JP NZ,FatGuyPathStore
  INC HL
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
FatGuyPathStore:
  LD (IX+$0F),L
  LD (IX+$10),H
  XOR A
FatGuyPathStep:
  INC A                   ; one more pass of this pair
  LD (IX+$0E),A
  INC HL
  LD A,(HL)               ; the x step: the high nibble, 7 meaning 8
  SRA A
  SRA A
  SRA A
  SRA A
  CP $07
  JP NZ,FatGuyStoreX
  INC A
FatGuyStoreX:
  LD C,A
  LD A,(IX+$01)
  ADD A,C
  LD (IX+$01),A
  LD B,$00
  LD A,(HL)               ; the y step: the low nibble, signed
  AND $0F
  BIT 3,A
  JP Z,FatGuyStepY
  DEC B
  OR $F0
FatGuyStepY:
  CP $07
  JP NZ,FatGuyStoreY
  INC A
FatGuyStoreY:
  LD C,A
  LD L,(IX+$02)
  LD H,(IX+$03)
  ADD HL,BC
  LD (IX+$02),L
  LD (IX+$03),H
  RET

; Passes before the Fat Guy may shoot again (50 after a shot)
;
; Set to 50 by FatGuyShoot at each shot, counted down by it; 0 in the image.
FatGuyShotDelay:
  DEFB $00

; Start a shot at Rick when the delay is over and no shot flies
;
; FatGuyShotDelay counts down to 0 first. Then, when EnemyRecords +0 is 0 (no
; shot): the delay = 50, the record on (+0 = 1), the shot at x = the body's x -
; 24, y = the body's y + 52 (8 bits; +3 = 0). The aim: B = Rick's y + 10 - the
; shot's x, C = Rick's x + 12 - the shot's y (as written, x and y are crossed:
; with the Fat Guy on the right and Rick level with him the shot still goes
; left at Rick; to check on screen); both are halved together (SRA) until C is
; within 1-3 (or -4 to -1) and B within -4 to 3. A difference past -128 is
; halved once and made negative first ($FA3D).
;
; Witness: 525 runs; 11 shots ($FA05); the branch for C positive ($FA46, Rick
; to the right of the shot) never ran.
;
; Witness: L1 525 (rzx-l5-20000-poke, rzx-l5-22000-poke).
FatGuyShoot:
  LD A,(FatGuyShotDelay)
  AND A
  JP Z,FatGuyShotNew
  DEC A
  LD (FatGuyShotDelay),A
  RET
FatGuyShotNew:
  LD A,(EnemyRecords)            ; no delay left: is a shot flying?
  AND A
  RET NZ
  LD (EnemyRecords+3),A
  LD A,$32
  LD (FatGuyShotDelay),A
  LD A,$01
  LD (EnemyRecords),A
  LD A,(TrapRecords+2)            ; y = the body's y + 52, x = the body's x - 24
  ADD A,$34
  LD C,A
  LD (EnemyRecords+2),A
  LD A,(TrapRecords+1)
  SUB $18
  LD (EnemyRecords+1),A
  LD B,A
  LD A,(RickY)            ; B: Rick's y + 10 - the shot's x
  ADD A,$0A
  SUB B
  LD B,A
  LD A,(RickX)            ; C: Rick's x + 12 - the shot's y
  ADD A,$0C
  SUB C
  LD C,A
  JP M,AimLeftLoop
  JP NC,AimRightLoop
  SRA B                   ; a borrow past -128: halve once, keep it negative
  SRA C
  SET 7,C
  JP AimLeftLoop
AimRightLoop:
  LD A,C                  ; C positive: halve until C < 4 and B in -4..3 (not
                          ; executed in any recording)
  CP $04
  JP NC,AimRightHalve
  LD A,B
  AND A
  JP P,AimRightDownTest
  CP $FC
  JP NC,FatGuyShotAimed
  JP AimRightHalve
AimRightDownTest:
  CP $04
  JP C,FatGuyShotAimed
AimRightHalve:
  SRA B
  SRA C
  JP AimRightLoop
AimLeftLoop:
  LD A,C                  ; C negative: halve until C >= -4 and B in -4..3
  CP $FC
  JP C,AimLeftHalve
  LD A,B
  AND A
  JP P,AimLeftDownTest
  CP $FC
  JP NC,FatGuyShotAimed
  JP AimLeftHalve
AimLeftDownTest:
  CP $04
  JP C,FatGuyShotAimed
AimLeftHalve:
  SRA B
  SRA C
  JP AimLeftLoop

; 01 F8 00: LD BC,$00F8, not executed in any recording (no jump reaches it)
;
; Three bytes between the halving loop's JP and FatGuyShotAimed: an instruction
; of an older build.
FatGuyShootLeftover:
  DEFB $01,$F8,$00

; FatGuyShoot, continued: the steps and the shot's sprite
;
; The x step C into EnemyRecords +7, the y step B into +8, the sprite 62 into
; +4/+5.
;
; Witness: 11 runs (rzx-l5-20000-poke 8, rzx-l5-22000-poke 3).
;
; Witness: L1 11 (rzx-l5-20000-poke, rzx-l5-22000-poke).
FatGuyShotAimed:
  LD A,C
  LD (EnemyRecords+7),A
  LD A,B
  LD (EnemyRecords+8),A
  LD HL,Sprites+62*128
  LD (EnemyRecords+4),HL
  RET

; Move the shot in the record at IX (EnemyRecords): Rick, the walls, the edge
;
; Nothing when its +0 is 0. x += +7: from $F8 on the shot ends (+0 = 0). y (the
; low byte at +2 only) += +8. Then a 1 x 1 box at x + 4, y + 4 against Rick
; (TouchesRick: KillRick, the one recorded death by $FACB) and the point's
; flags (ProbePoint): bit 1 (a wall or a solid object) ends the shot.
;
; Witness: 525 runs; the shot moved 335 passes, left the view 2 times ($FAA6),
; hit a wall 7 times ($FAD7); KillRick from $FACB once (rzx-l5-20000-poke or
; -22000-poke, the caller list of $93D0).
;
; Witness: L1 525 (rzx-l5-20000-poke, rzx-l5-22000-poke).
FatGuyShotMove:
  LD A,(EnemyRecords)
  AND A
  RET Z
  LD A,(EnemyRecords+1)
  ADD A,(IX+$07)
  CP $F8
  JP C,FatGuyShotOn
  XOR A
  LD (EnemyRecords),A
  RET
FatGuyShotOn:
  LD (EnemyRecords+1),A
  LD E,A
  LD A,(EnemyRecords+2)
  ADD A,(IX+$08)
  LD (EnemyRecords+2),A
  LD L,A
  LD H,$00
  INC HL                  ; the point x + 4, y + 4: a 1 x 1 box against Rick
  INC HL
  INC HL
  INC HL
  LD A,E
  ADD A,$04
  LD E,A
  PUSH HL
  PUSH DE
  LD BC,$0101
  CALL TouchesRick
  CALL C,KillRick
  POP DE
  POP HL
  CALL ProbePoint              ; a wall at the point ends the shot
  AND $02
  RET Z
  XOR A
  LD (EnemyRecords),A
  RET

; Put the part at IX at its offset (+7, +8) from the body
;
; x = the body's x + (IX+7) (8 bits), y = the body's y + (IX+8). Called four
; times a pass by FatGuyUpdate (parts 1-4).
;
; Witness: 2099 runs from each of $F8DB, $F8E2, $F8E9, $F8F0.
;
; Witness: L1 2099 (rzx-l5-20000-poke, rzx-l5-22000-poke).
FatGuyPlacePart:
  LD A,(TrapRecords+1)
  ADD A,(IX+$07)
  LD (IX+$01),A
  LD HL,(TrapRecords+2)
  LD C,(IX+$08)
  LD B,$00
  ADD HL,BC
  LD (IX+$02),L
  LD (IX+$03),H
  RET

; The Fat Guy's path while he lives (FatGuyMove's format)
;
; Count and step pairs: 24 passes still, small steps up and right ($1F, $2E,
; $1D, $1C, $0C), back ($FC, $FD, $EE, $FF), 24 still, a loop down and left and
; back ($F0 ... $10), then 0 and the jump to FatGuyPath ($FB30).
FatGuyPath:
  INCBIN "res/level/fat-guy-path.bin",$0000,63

; 461 zero bytes to the block's end $FCFF
;
; Read by no code.
FreeTail:
  DEFS $01CD
