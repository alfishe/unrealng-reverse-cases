; --------------------------------------------------------------------------------------------------------------------
; codepanel.asm: The end of part 1: the access code for part 2
;
; Room exit 99 (the lift out of the complex) ends part 1 at CodePanel. The code is 16 digits that carry the game into
; part 2, in the places 0 double fire, 1 score thousands, 2 spray, 3 lives, 4 laser, 5 score hundreds, 6 multiple, 7
; score units, 8 shield units, 9 score tens, 10 bombs, 11 shield tens, 12 score ten-thousands, each written 9 - digit;
; 13-15 the checksum's units, hundreds and tens (the sum of the 13 shown digits). The panel shows CODE: and the
; digits, waits for fire and starts a new game.
; --------------------------------------------------------------------------------------------------------------------

  ORG $A7CE

; The end of part 1: the CODE panel with the access code, then a new game
;
; Reached only from ChangeRoom $C95A when the exit leads to room 99. The digits
; go into CodeText $A884 at the places $A88C-$A89B. No stage 1 recording
; reached it; p1-code does (room 31's exit to 99, the panel shown, fire, a new
; game in room 0).
;
; Witness: L1 1 (p1-code).
CodePanel:
  LD HL,(Score)
  CALL ToDigits
  LD A,(Digits+$0004)
  LD (CodeDigits+$000C),A
  LD A,(Digits+$0003)
  LD (CodeDigits+$0001),A
  LD A,(Digits+$0002)
  LD (CodeDigits+$0005),A
  LD A,(Digits+$0001)
  LD (CodeDigits+$0009),A
  LD A,(Digits)
  LD (CodeDigits+$0007),A
  LD A,(Lives)
  LD L,A
  LD H,$00
  CALL ToDigits
  LD A,(Digits)
  LD (CodeDigits+$0003),A
  LD A,(HasDoubleFire)
  ADD A,$30
  LD (CodeDigits),A
  LD A,(HasLaser)
  ADD A,$30
  LD (CodeDigits+$0004),A
  LD A,(HasMultiple)
  ADD A,$30
  LD (CodeDigits+$0006),A
  LD A,(HasSpray)
  ADD A,$30
  LD (CodeDigits+$0002),A
  LD A,(ShieldEnergy)
  LD L,A
  LD H,$00
  CALL ToDigits
  LD A,(Digits+$0001)
  LD (CodeDigits+$000B),A
  LD A,(Digits)
  LD (CodeDigits+$0008),A
  LD A,(Bombs)
  LD L,A
  LD H,$00
  CALL ToDigits
  LD A,(Digits)
  LD (CodeDigits+$000A),A
  LD B,$0D
  LD E,$00
  LD (Temp1),HL
  LD HL,CodeDigits
CodeDigitsLoop:
  LD C,(HL)               ; each digit: 9 - digit, the checksum summed
  LD A,$39
  SUB C
  ADD A,$30
  LD (HL),A
  SUB $30
  ADD A,E
  LD E,A
  INC HL
  DJNZ CodeDigitsLoop
  LD L,E
  LD H,$00
  CALL ToDigits
  LD A,(Digits+$0002)
  LD (CodeDigits+$000E),A
  LD A,(Digits+$0001)
  LD (CodeDigits+$000F),A
  LD A,(Digits)
  LD (CodeDigits+$000D),A
  LD IX,CodeText
  LD B,$01
  CALL PrintBoxed
  CALL WaitFire
  JP NewGame

; The CODE panel: [attribute 6][column 6][line $50] "CODE:" and 16 places for
; the digits, 0
CodeText:
  INCBIN "res/texts/rex1-code.bin",$0000,8
CodeDigits:
  ; $A88C the 16 places: 0 double fire, 1 score thousands, 2 spray, 3
  ;   lives, 4 laser, 5 score hundreds, 6 multiple, 7 score units, 8 shield
  ;   units, 9 score tens, 10 bombs, 11 shield tens, 12 score
  ;   ten-thousands, each written 9 - digit; 13-15 the checksum's units,
  ;   hundreds and tens (the sum of the 13 shown digits)
  INCBIN "res/texts/rex1-code.bin",$0008,17

; Build the room Room $A0B8: exits and objects, the map drawn, the buffer
; shown, the room's objects made, the scripted spawn
;
; ResetSweep $A133, RoomExits ReadExits $C8EF, DrawRoom $C745, ClearBuffer /
; DrawAnimCells / BufferToScreen, CopyAttrs $C8BF, MakeObjects $CB52; rooms 2,
; 3, 4, 6 and 20 start the scripted spawn (StartScriptSpawn $C965); ShowShield.
;
; Witness: L1 80 (c1, p1-cursor, p1-define, p1-kempston, p1-rooms238,
; p1-speedup, p1-room x5, rzx-p1- x30).
BuildRoom:
  LD A,$03
  LD (SfxExplosion),A
  CALL ResetSweep
  LD HL,ObjectBufferOrigin
  LD (KillFlashPtr),HL
  CALL ReadExits
  LD HL,$5B60
  LD DE,$5B61
  LD BC,$02ED
  LD (HL),$00
  LDIR
  CALL DrawRoom
  LD HL,$5860
  LD DE,$5861
  LD BC,$029F
  LD (HL),$00
  LDIR
  CALL ClearBuffer
  CALL DrawAnimCells
  CALL BufferToScreen
  CALL CopyAttrs
  CALL MakeObjects
  XOR A
  LD (PassToggle),A
  LD (ScriptSpawnStep),A
  LD A,(Room)
  CP $02
  JR Z,BuildRoomScript
  CP $03
  JR Z,BuildRoomScript
  CP $04
  JR Z,BuildRoomScript
  CP $06
  JP Z,BuildRoomScript
  CP $14
  JP Z,BuildRoomScript
  JP BuildRoomShield
BuildRoomScript:
  LD HL,ScriptSpawn       ; the scripted spawn
  CALL StartScriptSpawn
BuildRoomShield:
  CALL ShowShield         ; the shield figure
  LD A,$01
  LD (RestartFacing),A
  RET

; The attract mode's rooms: 6, 17, 1, 20, 10, 23, 29, 32, then $FF (again)
AttractRooms:
  INCBIN "res/tables/rex1-attract-rooms.bin",$0000,9

; The attract mode: each room of AttractRooms shown 199 passes (AttractTimer
; 200, decremented before the test) with its objects moving (no Rex); fire
; starts a game
;
; Entered from WaitFireOrAttract $97C3's timeout. AttractFlag $A0C2 = 1 while
; it runs.
;
; Witness: L1 1 (c1).
Attract:
  LD A,$C8
  LD (AttractTimer),A
AttractRoom:
  LD A,(AttractFlag)      ; the next room of the list
  LD E,A
  LD D,$00
  LD HL,AttractRooms
  ADD HL,DE
  LD A,(HL)
  CP $FF
  JP NZ,AttractShow
  XOR A
  LD (AttractFlag),A
  JP AttractRoom
AttractShow:
  LD (Room),A             ; build and show it
  LD A,(AttractFlag)
  INC A
  LD (AttractFlag),A
  CALL BuildRoom
AttractPass:
  LD A,(AttractTimer)     ; one pass of the room
  DEC A
  OR A
  JP Z,Attract
  LD (AttractTimer),A
  CALL MoveEnemyBullets
  CALL UpdateObjects
  CALL SoundStep
  CALL DrawAnimCells
  CALL BufferToScreen
  CALL ClearBuffer
  CALL SoundStep
  CALL EnemyBulletsHitRex
  CALL PowerBar
  CALL SpawnScripted
  CALL SpawnRandom
  CALL KillFlashFade
  CALL FadeStep
  CALL HudSweep
  CALL ReadFire
  JP Z,NewGame
  LD HL,AnimChar111
  LD B,$08
AttractRrc:
  RRC (HL)                ; the animated characters, as in the main loop
  INC HL
  DJNZ AttractRrc
  LD HL,AnimChar143
  LD B,$08
AttractRlc:
  RLC (HL)
  RLC (HL)
  INC HL
  DJNZ AttractRlc
  LD HL,AnimChar28
  CALL RollCharDown
  LD HL,AnimChar11
  CALL RollCharUp
  LD HL,AnimChar26
  CALL RollCharDown
  CALL AnimateCells
  LD A,(PassToggle)
  XOR $01
  LD (PassToggle),A
  JP AttractPass
