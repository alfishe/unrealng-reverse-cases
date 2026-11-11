; A pair hit: jump through the handler table $C380
;
; Reached from the pair scan $E56F when the other record (HL, on the stack) is
; within the moving record's box. The same record is skipped ($E57F). Otherwise
; the moving record's type pair (IX+0 AND $0E) picks the row and the other's
; the column of the 7 x 8 word table at $C380, and the handler is entered with
; the other record's address on the stack. Handlers leave by $E57E (pop it and
; test the next record), $E57F (next, already popped), $E674 (the moving record
; is done: its new position is not stored, $E65F is skipped) or $E65F via
; $EBD1. docs/07-objects.md 7.6.
HitDispatch:
  POP HL                  ; the other record
  LD A,IXL
  CP L
  JR NZ,NotItself
  LD A,IXH                ; the record against itself: skip it
  CP H
  JP Z,PairScanStep
NotItself:
  PUSH HL
  LD A,(HL)               ; column: the other's type pair * 2
  AND $0E
  LD L,A
  LD A,(IX+$00)
  AND $0E
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,L
  LD L,A                  ; $C380 + row + column
  SET 7,L
  LD H,$C3
  LD A,(HL)
  INC L
  LD H,(HL)
  LD L,A
  JP (HL)                 ; the handler, the other record still on the stack

; Points, then both hit
;
; B tens of points ($EE87), then $EBD1. Entered with B = 21 (dome type 2), 32
; (dome type 3, after it released a pod), 14 (a missile or a jet) or 18 (a cube
; on its 4th hit). docs/10-gameplay-logic.md 10.7.
HitScore:
  CALL AddPoints

; Both records are hit
;
; Both records get bit 5 (hit) and the explosion counter +8 = $20; a moving one
; is slowed to speed 1. Sound request bit 1. Ends by storing the moving
; record's new position ($E65F). The table's cells for the player against the
; others (row 0, columns 0-4) and the others against the player (column 0) lead
; here. docs/07-objects.md 7.6.
HitBoth:
  POP HL                  ; the other record
  SET 5,(HL)
  LD A,$06
  ADD A,L
  LD L,A
  LD A,(HL)               ; a moving one slows to speed 1 while it explodes
  AND A
  JR Z,OtherExplodes
  LD (HL),$01
OtherExplodes:
  INC L                   ; +8: the explosion counter
  INC L
  LD (HL),$20
; This entry point is used by the routines at HitShotOnShot and
; HitPlayerOnStatic.
MovingHit:
  SET 5,(IX+$00)          ; the same for the moving record (entered here by
                          ; $EBFC and $EC01)
  LD A,(IX+$06)
  AND A
  JR Z,MovingExplodes
  LD (IX+$06),$01
MovingExplodes:
  LD (IX+$08),$20
  LD HL,SoundRequests     ; sound request bit 1: an explosion
  SET 1,(HL)
  JP StoreMove

; Handler: a shot against a shot (not run in the recordings)
;
; Reached through the table only (row 6, column 6). POP HL; SET 7,(HL); JR
; $EBE2. The other shot is removed and the moving one explodes as in $EBD1,
; sound bit 1.
HitShotOnShot:
  POP HL
  SET 7,(HL)
  JR MovingHit

; Handler: the player against a pad or a dish (not run)
;
; Row 0, column 7: POP HL; JR $EBE2. Only the player is hit (and explodes,
; sound bit 1); the pad or dish stays.
HitPlayerOnStatic:
  POP HL
  JR MovingHit

; Handler: a cube or pod against types 2-11 (not run)
;
; Row 5, columns 1-5: BIT 0,(IX+$00); JP NZ,$E57E; then falls into $EC0B. A pod
; goes on with the scan, a cube ends it. Nothing is hit.
HitBlockOnOther:
  BIT 0,(IX+$00)
  JP NZ,PairScanNext

; Handler: nothing happens
;
; POP HL; JP $E674: the pair has no effect and the moving record's scan ends
; for this pass. The most common handler (609 runs in the first recording).
; docs/07-objects.md 7.6.
HitNone:
  POP HL
  JP NextMover

; Handler: two missiles of types 4-5 turn round
;
; Both directions + 4 (mod 8). docs/07-objects.md 7.6.
HitTurnRound:
  LD A,(IX+$05)
  ADD A,$04
  AND $07
  LD (IX+$05),A
  POP HL
  LD A,$05
  ADD A,L
  LD L,A
  LD A,(HL)
  ADD A,$04
  AND $07
  LD (HL),A
  JP NextMover

; Handler: the player against a shot
;
; The player's own shots fly in direction 0 and are ignored ($E57E); any other
; shot hits both ($EBD1). docs/07-objects.md 7.6.
HitPlayerOnShot:
  POP HL
  PUSH HL
  LD A,$05
  ADD A,L
  LD L,A
  LD A,(HL)               ; the shot's direction: 0 is the player's own
  AND A
  JP Z,PairScanNext
  JP HitBoth

; Handler: a shot against the player (not run)
;
; Row 6, column 0, the mirror of $EC27: LD A,(IX+$05); AND A; JP Z,$E57E; JP
; $EBD1.
HitShotOnPlayer:
  LD A,(IX+$05)
  AND A
  JP Z,PairScanNext
  JP HitBoth

; Handler: a missile or a jet (types 4-9) against a shot
;
; A shot of the player (direction 0): 140 points and both hit. An enemy shot:
; ignored while the missile moves, else the shot is removed.
; docs/10-gameplay-logic.md 10.7.
HitTargetOnShot:
  POP HL
  PUSH HL
  LD A,$05
  ADD A,L
  LD L,A
  LD A,(HL)
  AND A
  LD B,$0E                ; 14 tens: 140 points
  JP Z,HitScore
  LD A,(IX+$06)           ; an enemy shot on a moving missile: no effect
  AND A
  JP NZ,PairScanNext
  POP HL
  SET 7,(HL)              ; on a standing one: the shot is removed
  JP NextMover

; Handler: a shot against a missile or a jet
;
; The mirror of $EC3F with the shot moving: a shot of the player scores 140 and
; both are hit; an enemy shot goes on past a moving target and is removed by a
; standing one. All five point awards of the first recording came this way.
; docs/07-objects.md 7.6.
HitShotOnTarget:
  LD A,(IX+$05)
  AND A
  LD B,$0E                ; 14 tens: 140 points
  JP Z,HitScore
  POP HL
  LD A,$06
  ADD A,L
  LD L,A
  LD A,(HL)
  AND A
  JP NZ,PairScanStep
  SET 7,(IX+$00)          ; an enemy shot on a standing target: removed
  JP NextMover

; Handler: a cube or a pod against a shot (not run)
;
; Row 5, column 6, the mirror of $ECAC with the cube moving: an enemy shot or a
; pod ends at $ECA6 (POP HL; SET 7,(HL): the shot is removed); a shot of the
; player counts a hit in the cube's +F, at the 4th it scores 180 ($EBCE, B =
; 18), otherwise the shot explodes (+6 = 0, +8 = $20) and sound request bit 2
; ($EC9E).
HitBlockOnShot:
  POP HL
  PUSH HL
  LD A,$05
  ADD A,L
  LD L,A
  LD A,(HL)
  AND A
  JR NZ,RemoveOtherRecord
  BIT 0,(IX+$00)
  JR NZ,RemoveOtherRecord
  LD A,(IX+$0F)
  INC A
  LD (IX+$0F),A
  CP $04
  LD B,$12
  JP NC,HitScore
  POP HL
  SET 5,(HL)
  LD A,$06
  ADD A,L
  LD L,A
  LD (HL),$00
  INC L
  INC L
  LD (HL),$20
  LD HL,SoundRequests
  SET 2,(HL)
  JP NextMover
RemoveOtherRecord:
  POP HL
  SET 7,(HL)
  JP NextMover

; Handler: a shot against a cube or a pod
;
; An enemy shot, or any shot on a pod, is removed ($ECDC). A shot of the player
; counts a hit in the cube's +F: the 4th scores 180 points and both are hit;
; hits 1-3 only explode the shot, with sound request bit 2. docs/07-objects.md
; 7.6, docs/10-gameplay-logic.md 10.7.
HitShotOnBlock:
  LD A,(IX+$05)
  AND A
  JP NZ,RemoveShot
  POP HL
  PUSH HL
  BIT 0,(HL)              ; the other is a pod: the shot just goes
  JR NZ,RemoveShot
  LD A,$0F                ; +F: the cube's hits
  ADD A,L
  LD L,A
  LD A,(HL)
  INC A
  LD (HL),A
  CP $04
  LD B,$12                ; 4th hit: 18 tens, 180 points
  JP NC,HitScore
  SET 5,(IX+$00)          ; hits 1-3: the shot explodes, the cube stays
  LD (IX+$06),$00
  LD (IX+$08),$20
  POP HL
  LD HL,SoundRequests     ; sound request bit 2
  SET 2,(HL)
  JP NextMover
RemoveShot:
  SET 7,(IX+$00)          ; the shot is removed
  POP HL
  JP NextMover

; The number of followers (the lives carried into the next round)
;
; The convoy behind the player, up to 4. A hit on the player costs the last one
; instead of the vehicle ($E262); the next round's lives are these ($D151
; copies them into $C2F9); the game start sets 4 ($CF36-$CF65); the round setup
; clears it after taking the lives ($D1DE). docs/07-objects.md 7.5,
; docs/10-gameplay-logic.md 10.4.
Followers:
  DEFB $00

; Where the next follower goes, along, from the player
;
; Added to a new follower's position: -10 at each round setup ($D1DE), then 6
; less for each follower ($ED25); a lost follower gives 6 back ($E262).
FollowerOffset:
  DEFW $FFF6

; The convoy: the leader's and the followers' +3 addresses
;
; Five words: $C003 (the player's position across), then the +3 address of each
; follower in the order they joined; $FF in the high byte marks an empty link
; (the round setup $D1DE fills the four with $FF, the image holds 0). $ECF3
; appends, $E7B9 copies along them, $E979 hits every follower in them.
ConvoyLinks:
  DEFW $C003,$0000,$0000,$0000,$0000

; The next free convoy link
ConvoyLinkEnd:
  DEFW $ECE9

; Handler: the player against a cube or a pod
;
; A cube hits both ($EBD1). A pod (type 11) joins the convoy: it takes the
; player's +1-+7 (position, across, height, direction, speed, behaviour), is
; put FollowerOffset behind, its +3 address is appended to the links, the
; offset grows by 6, $ECE4 counts it, and sound request bit 0 plays. The scan
; goes on. docs/07-objects.md 7.5.
HitPlayerOnPod:
  POP HL
  PUSH HL
  BIT 0,(HL)              ; bit 0 clear: a cube (10), both are hit
  JP Z,HitBoth
  POP HL
  PUSH HL
  LD E,IXL
  LD D,IXH
  INC E
  INC L
  EX DE,HL
  PUSH DE
  LD BC,$0007             ; the player's +1..+7 into the pod
  LDIR
  POP HL
  LD BC,(FollowerOffset)  ; along: behind the player by the offset
  LD E,(HL)
  INC L
  LD D,(HL)
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  LD (HL),D
  DEC L
  LD (HL),E
  INC L
  INC L
  LD DE,(ConvoyLinkEnd)   ; its +3 into the next convoy link
  EX DE,HL
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (ConvoyLinkEnd),HL
  LD HL,-6                ; the next one 6 further back
  ADD HL,BC
  LD (FollowerOffset),HL
  LD A,(Followers)        ; one more follower
  INC A
  LD (Followers),A
  LD HL,SoundRequests     ; sound request bit 0: a pod joins
  SET 0,(HL)
  JP PairScanNext

; Handler: a cube or a pod against the player (not run)
;
; Row 5, column 0, the mirror of $ECF3 with the pod moving: BIT 0,(IX+$00); JP
; Z,$EBD1, then the same join with IX and HL swapped, ending in sound request
; bit 0 ($ED79) and JP $E674.
HitBlockOnPlayer:
  BIT 0,(IX+$00)
  JP Z,HitBoth
  POP HL
  LD E,IXL
  LD D,IXH
  INC E
  INC L
  LD BC,$0007
  PUSH DE
  LDIR
  POP HL
  LD BC,(FollowerOffset)
  LD E,(HL)
  INC L
  LD D,(HL)
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  LD (HL),D
  DEC L
  LD (HL),E
  INC L
  INC L
  LD DE,(ConvoyLinkEnd)
  EX DE,HL
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (ConvoyLinkEnd),HL
  LD HL,-6                ; 6 further back
  ADD HL,BC
  LD (FollowerOffset),HL
  LD A,(Followers)
  INC A
  LD (Followers),A
  LD HL,SoundRequests
  SET 0,(HL)
  JP NextMover

; Handler: a dome against a shot (not run)
;
; Row 1, column 6, the mirror of $EDCA with the dome moving: an enemy shot
; passes a moving dome and is removed by a standing one; a shot of the player
; on a type 2 dome scores 210, on a type 3 dome it releases a pod into a free
; slot of $C060-$C090 ($EDB3) and scores 320.
HitDomeOnShot:
  POP HL
  PUSH HL
  LD A,$05
  ADD A,L
  LD L,A
  LD A,(HL)
  AND A
  JR Z,DomeHitByPlayer
  LD A,(IX+$06)
  AND A
  JP NZ,PairScanNext
  POP HL
  SET 7,(HL)
  JP NextMover
DomeHitByPlayer:
  BIT 0,(IX+$00)
  LD B,$15
  JP Z,HitScore
  LD HL,PodRecords
  LD DE,$0010
  LD B,$04
PodSlotLoop:
  BIT 7,(HL)
  JR NZ,PodFromDome
  ADD HL,DE
  DJNZ PodSlotLoop
  JP HitBoth
PodFromDome:
  LD (HL),$0B
  LD E,IXL
  LD D,IXH
  EX DE,HL
  LD BC,$0006
  INC E
  INC L
  LDIR
  EX DE,HL
  INC L
  LD (HL),$16
  LD B,$20
  JP HitScore

; Handler: a shot against a dome
;
; An enemy shot passes a moving dome and is removed by a standing one ($EDDC).
; A shot of the player on a dome of type 2: 210 points and both hit. On type 3:
; a pod (type 11) is written into the first free slot of $C060-$C090 at the
; dome's place (+1-+6), its +8 = $16, and 320 points; with no free slot, both
; are just hit. docs/07-objects.md 7.5.
HitShotOnDome:
  LD A,(IX+$05)
  AND A
  JR Z,ShotHitsDome       ; direction 0: the player's shot
  POP HL
  PUSH HL
  LD A,$06
  ADD A,L
  LD L,A
  LD A,(HL)
  AND A
  JP NZ,PairScanNext
  POP HL
  SET 7,(IX+$00)          ; an enemy shot on a standing dome: removed
  JP NextMover
ShotHitsDome:
  POP HL                  ; the player's shot
  PUSH HL
  BIT 0,(HL)              ; type 2: 21 tens, 210 points
  LD B,$15
  JP Z,HitScore
  LD HL,PodRecords        ; type 3: a free pod slot
  LD DE,$0010
  LD B,$04
PodSlotLoop2:
  BIT 7,(HL)
  JR NZ,ReleasePod
  ADD HL,DE
  DJNZ PodSlotLoop2
  JP HitBoth
ReleasePod:
  LD (HL),$0B             ; type 11 at the dome's place
  EX DE,HL
  POP HL
  PUSH HL
  LD BC,$0006
  INC E
  INC L
  LDIR
  EX DE,HL
  INC L
  LD (HL),$16
  LD B,$20                ; 32 tens: 320 points
  JP HitScore
