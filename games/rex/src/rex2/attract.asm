; --------------------------------------------------------------------------------------------------------------------
; attract.asm: Building a room and the attract mode
; --------------------------------------------------------------------------------------------------------------------

  ORG $A939

; Build the room Room $A251: exits and objects, the map drawn, the buffer
; shown, the room's objects made (no scripted spawn in part 2)
;
; Changed from REX 1's BuildRoom $A89D (src/game/codepanel.asm).
;
; Witness: L1 32 (c2, p2-room20, rzx-p2- x17).
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
  CALL ShowShield
  LD A,$01
  LD (RestartFacing),A
  RET

; The attract mode's rooms: 6, 17, 1, 20, 10, 23, 29, 32, then $FF (again)
;
; As REX 1's AttractRooms $A90C (src/game/codepanel.asm).
AttractRooms:
  DEFB $05,$11,$01,$14,$0A,$17,$13,$FF

; The attract mode: each room of AttractRooms shown 200 passes with its objects
; moving (no Rex, no conveyor rolls); fire starts a game
;
; Changed from REX 1's Attract $A915 (src/game/codepanel.asm).
;
; Witness: L1 3 (c2).
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
  CALL AnimateCells
  LD A,(PassToggle)
  XOR $01
  LD (PassToggle),A
  JP AttractPass
