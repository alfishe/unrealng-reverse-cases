; --------------------------------------------------------------------------------------------------------------------
; player.asm: The player: the keys, the moves, digging, pushing, the special cells
;
; PlayerStep $8556 tries the direction keys in the order left, right, up, down; the first that moves the player sets
; KeyMoved $FD80 and ends the step, so a pass moves the player at most one cell. PlayerIndex $FD9C is the player's
; cell (0-599); PlayerFacing $FD86 is the player's code: 3 right, 4 left. The key sites are self-modified (see the
; keys module).
;
; A move into earth (6) or empty (0) moves the player; earth sets DugEarth $E857 (the dig noise). A wall (5), a closed
; exit (1) and the cave's edge block. A boulder (2) moves left or right when the cell beyond is empty (PushBoulder
; $E81F); never up or down. A gem (7) is taken (CollectGem $8595). The codes 8-$0F have their handlers through
; LeftSpecial $94D6, RightSpecial $9494, UpSpecial $9414, DownSpecial $93CE. With the fire key held (FireStep $8878)
; the direction key acts on the next cell without moving the player.
; --------------------------------------------------------------------------------------------------------------------

  ORG $83C3

; The left key: move or act to the left
;
; The key site LD A,row ($83C4) / AND mask ($83CA) is written by RedefineKeys
; $8C30 and the control choice. Pressed: PlayerFacing = 4, KeyMoved = $FF;
; column 0 stops; the exit (1) only when ExitOpen (then CaveDone); the wall
; test BlockWall $E869, boulders PushBoulder $E81F, the codes > 6 LeftSpecial
; $94D6 (which takes gems and the other specials, continuation MoveLeft); then
; MoveLeft $8428.
;
; Witness: L1 42086 (c1, hiscore, lives, timer, rzx x32).
TryLeft:
  LD A,$DF
  OUT ($FF),A
  IN A,($FE)
  AND $02
  RET NZ
  LD HL,PlayerFacing
  LD (HL),$04
  LD HL,KeyMoved
  LD (HL),$FF
  LD HL,(PlayerIndex)
  LD B,$14
  LD DE,$001E
TryLeftLoop:
  SBC HL,DE
  RET Z
  DJNZ TryLeftLoop
  LD HL,(PlayerIndex)
  DEC HL
  LD DE,CaveGrid
  ADD HL,DE
  LD A,$01
  CP (HL)
  JR NZ,TryLeftSkip
  LD A,(ExitOpen)
  OR A
  RET Z
  LD A,$FF
  LD (CaveDone),A
  RET
TryLeftSkip:
  LD A,$02
  CP (HL)
  JR NZ,TryLeftSkip2
  LD HL,(PlayerIndex)
  DEC HL
  LD B,$14
  LD DE,$001E
TryLeftLoop2:
  SBC HL,DE
  RET Z
  DJNZ TryLeftLoop2
  LD HL,(PlayerIndex)
  DEC HL
  DEC HL
  LD DE,CaveGrid
  ADD HL,DE
  XOR A
  CALL PushBoulder
  NOP
  JR MoveLeft
TryLeftSkip2:
  CALL BlockWall
  NOP
  LD A,$06
  CP (HL)
  JP C,LeftSpecial

; Move the player one cell left (the old cell 0)
;
; Witness: L1 4365 (c1, rzx x32).
MoveLeft:
  LD HL,(PlayerIndex)
  DEC HL
  LD (PlayerIndex),HL
  INC HL
  LD DE,CaveGrid
  ADD HL,DE
  LD (HL),$00
  RET

; The right key: move or act to the right
;
; As TryLeft $83C3 with PlayerFacing = 3, column 29 the edge, RightSpecial
; $9494 (continuation MoveRight), MoveRight $849E.
;
; Witness: L1 36883 (c1, hiscore, lives, timer, rzx x32).
TryRight:
  LD A,$DF
  OUT ($FF),A
  IN A,($FE)
  AND $01
  RET NZ
  LD HL,PlayerFacing
  LD (HL),$03
  LD HL,KeyMoved
  LD (HL),$FF
  LD HL,(PlayerIndex)
  INC HL
  LD B,$15
  LD DE,$001E
TryRightLoop:
  SBC HL,DE
  RET Z
  DJNZ TryRightLoop
  LD HL,(PlayerIndex)
  INC HL
  LD DE,CaveGrid
  ADD HL,DE
  LD A,$01
  CP (HL)
  JR NZ,TryRightSkip
  LD A,(ExitOpen)
  OR A
  RET Z
  LD A,$FF
  LD (CaveDone),A
  RET
TryRightSkip:
  LD A,$02
  CP (HL)
  JR NZ,TryRightSkip2
  LD HL,(PlayerIndex)
  INC HL
  INC HL
  LD B,$15
  LD DE,$001E
TryRightLoop2:
  SBC HL,DE
  RET Z
  DJNZ TryRightLoop2
  LD HL,(PlayerIndex)
  INC HL
  INC HL
  LD DE,CaveGrid
  ADD HL,DE
  XOR A
  CALL PushBoulder
  NOP
  JR MoveRight
TryRightSkip2:
  CALL BlockWall
  NOP
  LD A,$06
  CP (HL)
  JP C,RightSpecial

; Move the player one cell right
;
; Witness: L1 4761 (c1, rzx x32).
MoveRight:
  LD HL,(PlayerIndex)
  INC HL
  LD (PlayerIndex),HL
  DEC HL
  LD DE,CaveGrid
  ADD HL,DE
  LD (HL),$00
  RET

; The up key: move or act upward
;
; As TryLeft, row 0 the edge; boulders block; UpSpecial $9414, MoveUp $84E6.
;
; Witness: L1 31376 (c1, hiscore, lives, timer, rzx x32).
TryUp:
  LD A,$FB
  OUT ($FF),A
  IN A,($FE)
  AND $01
  RET NZ
  LD HL,KeyMoved
  LD (HL),$FF
  LD HL,(PlayerIndex)
  LD DE,$001E
  SBC HL,DE
  RET C
  LD DE,CaveGrid
  ADD HL,DE
  LD A,$01
  CP (HL)
  JR NZ,TryUpSkip
  LD A,(ExitOpen)
  OR A
  RET Z
  LD A,$FF
  LD (CaveDone),A
  RET
TryUpSkip:
  LD A,$02
  CP (HL)
  RET Z
  CALL BlockWall
  NOP
  LD A,$06
  CP (HL)
  JP C,UpSpecial

; Move the player one row up
;
; Witness: L1 3803 (rzx x32).
MoveUp:
  LD HL,(PlayerIndex)
  LD DE,$001E
  SBC HL,DE
  LD (PlayerIndex),HL
  ADD HL,DE
  LD DE,CaveGrid
  ADD HL,DE
  LD (HL),$20
  RET

; The down key: move or act downward
;
; Row 19 the edge; DownSpecial $93CE, MoveDown $8535.
;
; Witness: L1 26738 (c1, hiscore, lives, timer, rzx x32).
TryDown:
  LD A,$FD
  OUT ($FF),A
  IN A,($FE)
  AND $01
  RET NZ
  LD HL,KeyMoved
  LD (HL),$FF
  LD HL,(PlayerIndex)
  LD DE,$023A
  SBC HL,DE
  RET NC
  LD DE,CaveGrid+$001E
  LD HL,(PlayerIndex)
  ADD HL,DE
  LD A,$01
  CP (HL)
  JR NZ,TryDownSkip
  LD A,(ExitOpen)
  OR A
  RET Z
  LD A,$FF
  LD (CaveDone),A
  RET
TryDownSkip:
  LD A,$02
  CP (HL)
  RET Z
  CALL BlockWall
  NOP
  LD A,$06
  CP (HL)
  JP C,DownSpecial

; Move the player one row down
;
; Witness: L1 4052 (c1, rzx x32).
MoveDown:
  LD HL,(PlayerIndex)
  LD DE,$001E
  ADD HL,DE
  LD (PlayerIndex),HL
  SBC HL,DE
  LD DE,CaveGrid
  ADD HL,DE
  LD (HL),$20
  RET

  ORG $8556

; One player step: the four keys in turn until one moves the player
;
; ClearStepFlags $E858 (DugEarth, KeyMoved, BoulderPushed 0). PlayerIndex 0
; skips only TryLeft (JR Z,PlayerStepSkip lands on the TryRight call; no
; recording has it). TryLeft, TryRight, TryUp, TryDown, each only while
; KeyMoved is not $FF; DigNoiseIfDug $E860.
;
; Witness: L1 42098 (c1, hiscore, lives, timer, rzx x32).
PlayerStep:
  CALL ClearStepFlags
  LD (HL),$00
  LD A,(PlayerIndex+$0001)
  LD HL,PlayerIndex
  OR (HL)
  JR Z,PlayerStepSkip
  CALL TryLeft
  LD HL,KeyMoved
  LD A,$FF
  CP (HL)
  JR Z,PlayerStepSkip2
PlayerStepSkip:
  CALL TryRight
  LD HL,KeyMoved
  LD A,$FF
  CP (HL)
  JR Z,PlayerStepSkip2
  CALL TryUp
  LD HL,KeyMoved
  LD A,$FF
  CP (HL)
  JR Z,PlayerStepSkip2
  CALL TryDown
  LD HL,KeyMoved
  LD A,$FF
  CP (HL)
  JR Z,PlayerStepSkip2
  RET
PlayerStepSkip2:
  CALL DigNoiseIfDug
  RET

; Take a gem: the points, the count, the exit
;
; AddGemValue $8376, ShowScore $8342, CountGem $8394; when ExitOpen became $FF,
; ExitOpenSound $9072.
;
; Witness: L1 1692 (c1, rzx x32).
CollectGem:
  CALL AddGemValue
  CALL ShowScore
  CALL CountGem
  LD HL,ExitOpen
  LD A,$FF
  CP (HL)
  RET NZ
  CALL ExitOpenSound
  NOP
  NOP
  NOP
  NOP
  RET

  ORG $8759

; The fire key chooses FireStep, else PlayerStep
;
; The fire key's site (LD A,$7F at $8759, AND $04 at $875F: SPACE half row, bit
; 2 = M) is written by RedefineKeys $8C30.
;
; Witness: L1 43776 (c1, hiscore, lives, timer, rzx x32).
KeysStep:
  LD A,$7F
  OUT ($FF),A
  IN A,($FE)
  AND $04
  JR Z,KeysStepSkip
  CALL PlayerStep
  RET
KeysStepSkip:
  CALL FireStep
  RET

; Fire left: act on the left cell without moving
;
; Earth: DigInPlace $E7FE. An object: CollectLeft $9621. A boulder:
; FireLeftBoulder $879F.
;
; Witness: L1 1678 (rzx x23).
FireLeft:
  LD A,$DF
  OUT ($FF),A
  IN A,($FE)
  AND $02
  RET NZ
  LD HL,(PlayerIndex)
  LD B,$15
  LD DE,$001E
FireLeftLoop:
  SBC HL,DE
  RET Z
  DJNZ FireLeftLoop
  LD HL,(PlayerIndex)
  LD DE,CaveGrid-1
  ADD HL,DE
  LD A,(HL)
  CP $06
  JR NZ,FireLeftSkip
  LD (HL),$20
  CALL DigInPlace
  RET
FireLeftSkip:
  CP $06
  JR C,FireLeftBoulder
  PUSH HL
  CALL CollectLeft
  POP HL
  RET

; Leftover: 2 bytes, never run
FireLeftPad:
  DEFB $00,$00

; Fire left on a boulder: push it when the cell beyond is empty
;
; The boulder not in column 0 (the test is on PlayerIndex - 1) and the cell
; beyond it 0: the boulder moves there ($87BA), its old cell gets $20 ($87BD),
; ThudSound $8228. BoulderPushed is not written.
;
; Witness: L1 304 (rzx x15); the push $87BA ran 30 times (rzx x6: rzx09, 16,
; 24, 26, 27, 28; work/stage2/execs.json).
FireLeftBoulder:
  CP $02
  RET NZ
  LD HL,(PlayerIndex)
  DEC HL
  LD B,$15
  LD DE,$001E
FireLeftBoulderLoop:
  SBC HL,DE
  RET Z
  DJNZ FireLeftBoulderLoop
  LD HL,(PlayerIndex)
  LD DE,CaveGrid-2
  ADD HL,DE
  XOR A
  CP (HL)
  RET NZ
  LD (HL),$02
  INC HL
  LD (HL),$20
  CALL ThudSound
  RET

; Fire right: act on the right cell without moving
;
; Witness: L1 1678 (rzx x23).
FireRight:
  LD A,$DF
  OUT ($FF),A
  IN A,($FE)
  AND $01
  RET NZ
  LD HL,(PlayerIndex)
  INC HL
  LD B,$15
  LD DE,$001E
FireRightLoop:
  SBC HL,DE
  RET Z
  DJNZ FireRightLoop
  LD HL,(PlayerIndex)
  LD DE,CaveGrid+$0001
  ADD HL,DE
  LD A,(HL)
  CP $06
  JR NZ,FireRightSkip
  LD (HL),$20
  CALL DigInPlace
  RET
FireRightSkip:
  CP $06
  JR C,FireRightSkip2
  PUSH HL
  CALL CollectRight
  POP HL
  NOP
  NOP
  RET
FireRightSkip2:
  CP $02
  RET NZ
  LD HL,(PlayerIndex)
  INC HL
  INC HL
  LD B,$15
  LD DE,$001E
FireRightLoop2:
  SBC HL,DE
  RET Z
  DJNZ FireRightLoop2
  LD HL,(PlayerIndex)
  LD DE,CaveGrid+$0002
  ADD HL,DE
  XOR A
  CP (HL)
  RET NZ
  LD (HL),$02
  DEC HL
  LD (HL),$20
  CALL ThudSound
  RET

; Fire up: act on the cell above without moving
;
; Witness: L1 1678 (rzx x23).
FireUp:
  LD A,$FB
  OUT ($FF),A
  IN A,($FE)
  AND $01
  RET NZ
  LD HL,(PlayerIndex)
  LD DE,$001E
  SBC HL,DE
  RET C
  LD DE,CaveGrid
  ADD HL,DE
  LD A,(HL)
  CP $06
  JR NZ,FireUpSkip
  LD (HL),$20
  CALL DigInPlace
  RET
FireUpSkip:
  CP $06
  RET C
  PUSH HL
  CALL CollectUp
  POP HL
  NOP
  NOP
  RET

; Fire down: act on the cell below without moving
;
; Witness: L1 1678 (rzx x23).
FireDown:
  LD A,$FD
  OUT ($FF),A
  IN A,($FE)
  AND $01
  RET NZ
  LD HL,(PlayerIndex)
  LD DE,$023A
  SBC HL,DE
  RET NC
  LD DE,CaveGrid+$001E
  LD HL,(PlayerIndex)
  ADD HL,DE
  LD A,(HL)
  CP $06
  JR NZ,FireDownSkip
  LD (HL),$20
  CALL DigInPlace
  RET
FireDownSkip:
  CP $06
  RET C
  PUSH HL
  CALL CollectDown
  POP HL
  NOP
  NOP
  RET

; The fire key held: each direction key acts on the next cell
;
; Witness: L1 1678 (rzx x23).
FireStep:
  CALL FireLeft
  CALL FireRight
  CALL FireUp
  CALL FireDown
  RET

  ORG $914C

; Walked into a force field (9): blocked, 12 TimerSteps at once (3 bar pixels)
;
; Witness: L1 11 (rzx x5).
ForceField:
  LD B,$0C
ForceFieldLoop:
  PUSH BC
  CALL TimerStep
  LD A,(CaveOver)
  CP $FF
  JR NZ,ForceFieldSkip
  POP BC
  RET
ForceFieldSkip:
  POP BC
  DJNZ ForceFieldLoop
  RET

; The special cell above the player: its handler
;
; HL = the cell above (code $07-$0F, UpSpecialCheck $93C7). Gem: CollectGem
; $8595, MoveUp $84E6; jelly bean JellyBean $91F7; force field ForceField
; $914C; anti-gravity arrow AntiGravTake $A7C7; switch box: RET (blocks);
; potion: TakePotion $91C9, then the tests go on; teleporter TeleportUp $926E;
; bubble BubbleUp $934F; fire WalkIntoFire $91AE (PlayerKilled $7FFD = $FF,
; Continue $9410).
;
; Known only from the code: the fire test $9194 and the tail $919A never ran:
; no build walked up into fire or a potion. The tail is reached after a potion
; taken from above: CALL Z,TakePotion returns with HL at the $FF that ends
; LifeTune, every later test fails, CP $0F leaves carry, and SBC gives
; PlayerIndex - 30: the player moves up into the potion's cell, by luck of the
; carry. WalkIntoFire itself ran in the stage 2 recording death-fire (frame
; 279, from LeftSpecial $94D6, TryLeft's dispatcher: cave 4, one step left into
; fire).
;
; Witness: L1 517 (rzx x32).
UpSpecialCell:
  LD A,$07
  CP (HL)
  JR NZ,UpSpecialCellSkip
  CALL CollectGem
  JP MoveUp
UpSpecialCellSkip:
  LD A,$08
  CP (HL)
  JP Z,JellyBean
  LD A,$09
  CP (HL)
  JP Z,ForceField
  LD A,$0A
  CP (HL)
  JP Z,AntiGravTake
  LD A,$0B
  CP (HL)
  RET Z
  NOP
  NOP
  LD A,$0C
  CP (HL)
  CALL Z,TakePotion
  LD A,$0D
  CP (HL)
  JP Z,TeleportUp
  LD A,$0E
  CP (HL)
  JP Z,BubbleUp
  LD A,$0F
  CP (HL)
  JP Z,WalkIntoFire
  LD HL,(PlayerIndex)
  INC HL
  LD DE,$001E
  SBC HL,DE
  LD (PlayerIndex),HL
  ADD HL,DE
  LD DE,CaveGrid
  ADD HL,DE
  LD (HL),$20
  RET
; This entry point is used by the routines at DownSpecial, RightSpecial and
; LeftSpecial.
WalkIntoFire:
  LD A,$FF
  LD (PlayerKilled),A
  JP Continue

; Leftover: JP $84E6, never run
ForceFieldPad:
  DEFB $C3,$E6,$84

  ORG $91C1

; The extra-life tune: PlayTune LifeTune $AC5F
;
; Witness: L1 6 (rzx x6).
PotionTune:
  LD HL,LifeTune
  CALL PlayTune
  DI
  RET

; The potion ($0C): a life (up to 9), its tune, 20 points
;
; Witness: L1 6 (rzx x6).
TakePotion:
  LD A,(Lives)
  CP $09
  JR Z,TakePotionSkip
  INC A
TakePotionSkip:
  LD (Lives),A
  CALL ShowCounters
  CALL PotionScore
  RET

; Shift a set pixel into the time bar from the left
;
; Witness: L1 4224 (rzx x23).
TimeBarRefillStep:
  LD HL,Screen+4800
  LD B,$04
TimeBarRefillStepLoop:
  PUSH BC
  PUSH HL
  LD B,$20
  NOP
  NOP
  NOP
  SCF
TimeBarRefillStepLoop2:
  RR (HL)
  INC HL
  DJNZ TimeBarRefillStepLoop2
  NOP
  POP HL
  LD BC,$0100
  ADD HL,BC
  POP BC
  DJNZ TimeBarRefillStepLoop
  RET

  ORG $926E

; A teleporter above: erase it, go to the next teleporter
;
; Witness: L1 16 (rzx x11).
TeleportUp:
  CALL TeleportOutEffect
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  CALL MoveUp
  LD DE,$001E
  SBC HL,DE
  LD (HL),$20
  ADD HL,DE
  LD BC,$0258
  LD HL,CaveGrid
  LD A,$0D
  CPIR
  LD A,B
  OR C
  RET Z
  DEC HL
  LD DE,CaveGrid
  SBC HL,DE
  LD (PlayerIndex),HL
  CALL WindowOrigin
  LD HL,(ViewOrigin)
  CALL DrawWindow
  CALL TeleportInEffect
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  CALL BarColours
  RET

; Leftover: two BEEPER calls (32 bytes), never run
TeleportUpPad:
  DEFB $21,$40,$01,$11,$01,$00,$E5,$CD
  DEFB $B5,$03,$E1,$2D,$20,$F5,$F3,$C9
  DEFB $21,$80,$00,$11,$01,$00,$E5,$CD
  DEFB $B5,$03,$E1,$2D,$20,$F5,$F3,$C9

  ORG $934F

; Push a bubble up: into earth or empty it moves, into fire it bursts
;
; Witness: L1 206 (rzx x16).
BubbleUp:
  PUSH HL
  LD DE,CaveGrid+$001E
  SBC HL,DE
  POP HL
  RET C
  PUSH HL
  LD DE,$001E
  SBC HL,DE
  LD A,(HL)
  CP $06
  JR Z,BubbleUpSkip2
  OR A
  JR Z,BubbleUpSkip2
  CP $0F
  JR Z,BubbleUpSkip
  POP HL
  RET
BubbleUpSkip:
  CALL BubbleBurst
  POP HL
  JP Continue
BubbleUpSkip2:
  LD (HL),$0E
  POP HL
  JP Continue

; A bubble pushed into fire: the cell becomes $10 (the burst), BubbleScore
;
; Witness: L1 136 (rzx x21).
BubbleBurst:
  LD (HL),$10
  CALL BubbleScore
  RET

  ORG $93B6

; The burst bubble: RaspSound, 100 points
;
; Witness: L1 136 (rzx x21).
BubbleScore:
  CALL RaspSound
  LD B,$64
  CALL AddPoints
  CALL ShowScore
  RET

; Leftover: 5 bytes, never run
BubbleScorePad:
  DEFB $00,$00,$00,$00,$00

; A cell code above $0F above the player blocks; else UpSpecialCell
;
; Witness: L1 523 (rzx x32).
UpSpecialCheck:
  LD A,$0F
  CP (HL)
  RET C
  JP UpSpecialCell

; The cell below is a special: its handler
;
; Witness: L1 1120 (c1, rzx x32).
DownSpecial:
  PUSH HL
  LD HL,MoveDown
  LD (Continuation),HL
  POP HL
  LD A,$07
  CP (HL)
  JR NZ,DownSpecialSkip
  CALL CollectGem
  JP MoveDown
DownSpecialSkip:
  LD A,$08
  CP (HL)
  JP Z,JellyBean
  LD A,$09
  CP (HL)
  JP Z,ForceField
  LD A,$0A
  CP (HL)
  JP Z,AntiGravTake
  LD A,$0B
  CP (HL)
  RET Z
  LD A,$0C
  CP (HL)
  JP Z,PotionDown
  LD A,$0D
  CP (HL)
  JP Z,TeleportDown
  LD A,$0E
  CP (HL)
  JP Z,BubbleDown
  LD A,$0F
  CP (HL)
  JP Z,WalkIntoFire
  RET

; JP (HL): the stored continuation Continuation $FD87
;
; Witness: L1 1608 (c1, rzx x28).
Continue:
  LD HL,(Continuation)
  JP (HL)

; The cell above is a special: its handler
;
; Witness: L1 523 (rzx x32).
UpSpecial:
  PUSH HL
  LD HL,MoveUp
  LD (Continuation),HL
  POP HL
  JP UpSpecialCheck

; A teleporter below: MoveUp, erase it, go to the next teleporter
;
; It calls MoveUp $84E6 ($942B), not MoveDown, then writes $20 into the cell
; below. With no teleporter found (or only one in cell 599: the test is on BC
; after CPIR, $9440) it returns with the player one row above where he stood.
;
; Witness: L1 11 (rzx x8).
TeleportDown:
  CALL TeleportOutEffect
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  CALL MoveUp
  LD DE,$001E
  ADD HL,DE
  LD (HL),$20
  SBC HL,DE
  LD BC,$0258
  LD HL,CaveGrid
  LD A,$0D
  CPIR
  LD A,B
  OR C
  RET Z
  DEC HL
  LD DE,CaveGrid
  SBC HL,DE
  LD (PlayerIndex),HL
  CALL WindowOrigin
  LD HL,(ViewOrigin)
  CALL DrawWindow
  CALL TeleportInEffect
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  CALL BarColours
  RET

; The potion below: TakePotion, then continue
;
; Witness: L1 6 (rzx x6).
PotionDown:
  CALL TakePotion
  JP Continue

; Push a bubble down
;
; Witness: L1 592 (c1, rzx x21).
BubbleDown:
  PUSH HL
  LD DE,CaveGrid+$023A
  SBC HL,DE
  POP HL
  RET NC
  PUSH HL
  LD DE,$001E
  ADD HL,DE
  NOP
  LD A,(HL)
  CP $06
  JR Z,BubbleDownSkip2
  OR A
  JR Z,BubbleDownSkip2
  CP $0F
  JR Z,BubbleDownSkip
  POP HL
  RET
BubbleDownSkip:
  CALL BubbleBurst
  POP HL
  JP Continue
BubbleDownSkip2:
  LD (HL),$0E
  POP HL
  JP Continue

; The cell to the right is a special (TryRight $8437): its handler,
; continuation MoveRight
;
; Witness: L1 959 (c1, rzx x32).
RightSpecial:
  PUSH HL
  LD HL,MoveRight
  LD (Continuation),HL
  POP HL
  LD A,$07
  CP (HL)
  JR NZ,RightSpecialSkip
  CALL CollectGem
  JP MoveRight
RightSpecialSkip:
  LD A,$08
  CP (HL)
  JP Z,JellyBean
  LD A,$09
  CP (HL)
  JP Z,ForceField
  LD A,$0A
  CP (HL)
  JP Z,AntiGravTake
  LD A,$0B
  CP (HL)
  RET Z
  LD A,$0C
  CP (HL)
  JP Z,PotionDown
  LD A,$0D
  CP (HL)
  JP Z,TeleportRight
  LD A,$0E
  CP (HL)
  JP Z,BubbleRight
  LD A,$0F
  CP (HL)
  JP Z,WalkIntoFire
  RET

; The cell to the left is a special (TryLeft $83C3): its handler, continuation
; MoveLeft
;
; Witness: L1 847 (rzx x32).
LeftSpecial:
  PUSH HL
  LD HL,MoveLeft
  LD (Continuation),HL
  POP HL
  LD A,$07
  CP (HL)
  JR NZ,LeftSpecialSkip
  CALL CollectGem
  JP MoveLeft
LeftSpecialSkip:
  LD A,$08
  CP (HL)
  JP Z,JellyBean
  LD A,$09
  CP (HL)
  JP Z,ForceField
  LD A,$0A
  CP (HL)
  JP Z,AntiGravTake
  LD A,$0B
  CP (HL)
  RET Z
  LD A,$0C
  CP (HL)
  JP Z,PotionDown
  LD A,$0D
  CP (HL)
  JP Z,TeleportLeft
  LD A,$0E
  CP (HL)
  JP Z,BubbleLeft
  LD A,$0F
  CP (HL)
  JP Z,WalkIntoFire
  RET

; A teleporter to the right
;
; Witness: L1 18 (rzx x10).
TeleportRight:
  CALL TeleportOutEffect
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  CALL MoveRight
  INC HL
  LD (HL),$20
  DEC HL
  NOP
  NOP
  NOP
  NOP
  LD BC,$0258
  LD HL,CaveGrid
  LD A,$0D
  CPIR
  LD A,B
  OR C
  RET Z
  DEC HL
  LD DE,CaveGrid
  SBC HL,DE
  LD (PlayerIndex),HL
  CALL WindowOrigin
  LD HL,(ViewOrigin)
  CALL DrawWindow
  CALL TeleportInEffect
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  CALL BarColours
  RET

; A teleporter to the left
;
; Witness: L1 13 (rzx x9).
TeleportLeft:
  CALL TeleportOutEffect
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  CALL MoveLeft
  DEC HL
  LD (HL),$20
  INC HL
  NOP
  NOP
  NOP
  NOP
  LD BC,$0258
  LD HL,CaveGrid
  LD A,$0D
  CPIR
  LD A,B
  OR C
  RET Z
  DEC HL
  LD DE,CaveGrid
  SBC HL,DE
  LD (PlayerIndex),HL
  CALL WindowOrigin
  LD HL,(ViewOrigin)
  CALL DrawWindow
  CALL TeleportInEffect
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  CALL BarColours
  RET

; Push a bubble right
;
; Witness: L1 499 (rzx x19).
BubbleRight:
  PUSH HL
  LD DE,CaveGrid-1
  SBC HL,DE
  LD DE,$001E
  LD B,$15
BubbleRightLoop:
  SBC HL,DE
  JR NZ,BubbleRightSkip
  POP HL
  RET
BubbleRightSkip:
  DJNZ BubbleRightLoop
  POP HL
  PUSH HL
  INC HL
  LD A,(HL)
  CP $06
  JR Z,BubbleRightSkip3
  OR A
  JR Z,BubbleRightSkip3
  CP $0F
  JR Z,BubbleRightSkip2
  POP HL
  RET
BubbleRightSkip2:
  CALL BubbleBurst
  POP HL
  JP Continue
BubbleRightSkip3:
  LD (HL),$0E
  NOP
  JP BubbleRightMove

; Push a bubble left
;
; Witness: L1 380 (rzx x20).
BubbleLeft:
  PUSH HL
  LD DE,CaveGrid
  SBC HL,DE
  LD DE,$001E
  LD B,$15
BubbleLeftLoop:
  SBC HL,DE
  JR NZ,BubbleLeftSkip
  POP HL
  RET
BubbleLeftSkip:
  DJNZ BubbleLeftLoop
  POP HL
  PUSH HL
  DEC HL
  LD A,(HL)
  CP $06
  JR Z,BubbleLeftSkip3
  OR A
  JR Z,BubbleLeftSkip3
  CP $0F
  JR Z,BubbleLeftSkip2
  POP HL
  RET
BubbleLeftSkip2:
  CALL BubbleBurst
  POP HL
  JP Continue
BubbleLeftSkip3:
  LD (HL),$0E
  NOP
  JP BubbleLeftMove

; Take the object at the saved cell (the fire key): gem, jelly bean, potion,
; arrow
;
; Witness: L1 302 (rzx x23).
CollectObject:
  CALL CollectAntiGrav
  NOP
  NOP
  NOP
  CP $07
  JP Z,CollectGem
  CP $08
  JP Z,JellyBean
  CP $0C
  JP Z,TakePotion
  CP $0A
  JP Z,AntiGravStartScan

; RET
;
; Witness: L1 24 (rzx x11).
CollectNone:
  RET

; Fire left on an object: take it
;
; Witness: L1 126 (rzx x18).
CollectLeft:
  CP $0F
  RET Z
  CP $0D
  RET Z
  CP $0B
  RET Z
  CP $09
  RET Z
  PUSH HL
  CALL CollectObject
  POP HL
  LD A,(HL)
  CP $0E
  JR Z,CollectLeftSkip
  LD (HL),$20
  RET
CollectLeftSkip:
  PUSH HL
  LD HL,CollectLeftClear
  LD (Continuation),HL
  POP HL
  LD (SavedCell),HL
  JP BubbleLeft

; The saved cell becomes $20
;
; Witness: L1 1 (rzx x1).
CollectLeftClear:
  LD HL,(SavedCell)
  LD (HL),$20
  RET

; Fire right on an object: take it
;
; Witness: L1 94 (rzx x16).
CollectRight:
  CP $0F
  RET Z
  CP $0D
  RET Z
  CP $0B
  RET Z
  CP $09
  RET Z
  PUSH HL
  CALL CollectObject
  POP HL
  LD A,(HL)
  CP $0E
  JR Z,CollectRightSkip
  LD (HL),$20
  RET
CollectRightSkip:
  PUSH HL
  LD HL,CollectRightClear
  LD (Continuation),HL
  POP HL
  LD (SavedCell),HL
  JP BubbleRight

; The saved cell becomes $20
;
; Witness: L1 2 (rzx x1).
CollectRightClear:
  LD HL,(SavedCell)
  LD (HL),$20
  RET

; Fire up on an object: take it
;
; Witness: L1 37 (rzx x18).
CollectUp:
  CP $0F
  RET Z
  CP $0D
  RET Z
  CP $0B
  RET Z
  CP $09
  RET Z
  PUSH HL
  CALL CollectObject
  POP HL
  LD A,(HL)
  CP $0E
  JR Z,CollectUpSkip
  LD (HL),$20
  RET
CollectUpSkip:
  PUSH HL
  LD HL,CollectUpClear
  LD (Continuation),HL
  POP HL
  LD (SavedCell),HL
  JP BubbleUp

; The saved cell becomes $20
;
; Witness: L1 1 (rzx x1).
CollectUpClear:
  LD HL,(SavedCell)
  LD (HL),$20
  RET

; Fire down on an object: take it
;
; Witness: L1 55 (rzx x18).
CollectDown:
  CP $0F
  RET Z
  CP $0D
  RET Z
  CP $0B
  RET Z
  CP $09
  RET Z
  PUSH HL
  CALL CollectObject
  POP HL
  LD A,(HL)
  CP $0E
  JR Z,CollectDownSkip
  LD (HL),$20
  RET
CollectDownSkip:
  PUSH HL
  LD HL,CollectDownClear
  LD (Continuation),HL
  POP HL
  LD (SavedCell),HL
  JP BubbleDown

; The saved cell becomes $20
;
; Witness: L1 2 (rzx x2).
CollectDownClear:
  LD HL,(SavedCell)
  LD (HL),$20
  RET

; Leftover: 43 bytes, never run
CollectPad:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00

  ORG $9980

; Mark the cell beyond a bubble pushed right
;
; The bubble is already written ($95CF). The cell beyond its new place gets $20
; when it is 0; when the new place is in column 29 the loop ends with HL = 0
; and the $20 goes to $0000 (the ROM, no effect). Then Continue $9410.
;
; Witness: L1 400 (rzx x19).
BubbleRightMove:
  LD DE,CaveGrid-1
  SBC HL,DE
  LD DE,$001E
  LD B,$15
BubbleRightMoveLoop:
  SBC HL,DE
  JR NZ,BubbleRightMoveSkip
  JR BubbleRightMoveSkip2
BubbleRightMoveSkip:
  DJNZ BubbleRightMoveLoop
  POP HL
  PUSH HL
  INC HL
  INC HL
  LD A,(HL)
  OR A
  JR NZ,BubbleRightMoveSkip3
BubbleRightMoveSkip2:
  LD (HL),$20
BubbleRightMoveSkip3:
  POP HL
  JP Continue

; Mark the cell beyond a bubble pushed left
;
; The bubble is already written ($9600). The cell beyond its new place gets $20
; when it is 0; when the new place is in column 0 the loop ends with HL = 0 and
; the $20 goes to $0000 (the ROM, no effect). Then Continue $9410.
;
; Witness: L1 306 (rzx x18).
BubbleLeftMove:
  LD DE,CaveGrid
  SBC HL,DE
  LD DE,$001E
  LD B,$15
BubbleLeftMoveLoop:
  SBC HL,DE
  JR NZ,BubbleLeftMoveSkip
  JR BubbleLeftMoveSkip2
BubbleLeftMoveSkip:
  DJNZ BubbleLeftMoveLoop
  POP HL
  PUSH HL
  DEC HL
  DEC HL
  LD A,(HL)
  OR A
  JR NZ,BubbleLeftMoveSkip3
BubbleLeftMoveSkip2:
  LD (HL),$20
BubbleLeftMoveSkip3:
  POP HL
  JP Continue

  ORG $A63E

; Take the anti-gravity arrow with the fire key
;
; Witness: L1 302 (rzx x23).
CollectAntiGrav:
  LD HL,CollectNone
  LD (Continuation),HL
  CP $0F
  RET C
  POP HL
  POP HL
  POP BC
  RET

  ORG $E7FE

; The fire key on earth: dig it without moving, with a noise
;
; Witness: L1 167 (rzx x16).
DigInPlace:
  LD A,$01
  LD (NoiseBurstPitch+$0001),A
  CALL NoiseBurst
  LD A,$02
  LD (NoiseBurstPitch+$0001),A
  CALL NoiseBurst
  LD A,$04
  LD (NoiseBurstPitch+$0001),A
  CALL NoiseBurst
  LD A,$0A
  LD (NoiseBurstPitch+$0001),A
  CALL NoiseBurst
  RET

; Push a boulder left or right when the cell beyond is empty
;
; Witness: L1 434 (c1, rzx x29).
PushBoulder:
  CP (HL)
  JR Z,PushBoulderSkip
  POP AF
  RET
PushBoulderSkip:
  LD (HL),$02
  PUSH AF
  LD A,$FF
  LD (BoulderPushed),A
  POP AF
  RET

; $FF when a boulder was pushed this pass (the thud)
BoulderPushed:
  DEFB $00

; KeyMoved and BoulderPushed 0
;
; Witness: L1 42098 (c1, hiscore, lives, timer, rzx x32).
ClearMoveFlags:
  LD HL,KeyMoved
  LD (HL),$00
  LD HL,BoulderPushed
  LD (HL),$00
  RET

  ORG $E857

; $FF when the player dug earth this pass
DugEarth:
  DEFB $00

; DugEarth 0, then ClearMoveFlags
;
; Witness: L1 42098 (c1, hiscore, lives, timer, rzx x32).
ClearStepFlags:
  LD HL,DugEarth
  LD (HL),$00
  JP ClearMoveFlags

  ORG $E869

; A wall stops the move (the return address dropped); earth sets DugEarth
;
; Witness: L1 19281 (c1, rzx x32).
BlockWall:
  LD A,$05
  CP (HL)
  JR NZ,BlockWallSkip
  POP AF
  RET
BlockWallSkip:
  LD A,$06
  CP (HL)
  JR NZ,BlockWallDone
  LD A,$FF
  LD (DugEarth),A
BlockWallDone:
  RET
