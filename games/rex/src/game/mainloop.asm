; --------------------------------------------------------------------------------------------------------------------
; mainloop.asm: The main loop: one pass a frame of play, the keys
;
; MainLoop builds the current room (BuildRoom $A89D) and loops at MainPass $9586. A pass moves the bullets
; (MoveBullets $B64E, MoveEnemyBullets $B645), the drones (UpdateDrones $A639), Rex's death or sparkle (RexState
; $969B, SparkleUpdate $9D71, SparkleDraw $9E02), the objects (UpdateObjects $BA5C), the sound (SoundStep $D68C,
; twice), draws the animated cells (DrawAnimCells $B33E), copies the back buffer to the screen (BufferToScreen $A28A)
; and clears it (ClearBuffer $B205), then the collisions (EnemyBulletsHitRex $D1B9), the power bar (PowerBar $B96B),
; the spawners (SpawnScripted $C978, SpawnRandom $C9CA), the smart bomb (SmartBombStep $9786), the kill flash
; (KillFlashFade $9992), the fade (FadeStep $9A4C) and the HUD sweep (HudSweep $A0C4).
;
; Then the keys: down toggles the shield, ENTER restarts (NewGame), H pauses, SPACE fires a smart bomb; while Rex
; lives, fire, right, left and up (jump), then the jump, the fall and the walk, and the cells under Rex. Last the
; animated characters are rotated. There is no frame wait: interrupts stay off, so the game's speed is its work.
; --------------------------------------------------------------------------------------------------------------------

  ORG $9583

; Build the room, then one pass of play a frame (MainPass)
;
; The room change (ChangeRoom $C95A) and the life lost jump back here. The keys
; are the readers $A477-$A4DB: down ShieldToggle $967F, fire FireWeapon $B372,
; right WalkRight $CFDA, left WalkLeft $CFF6, up StartJump $D0C2; ENTER ($BFFE
; bit 0) NewGame, H ($BFFE bit 4) Pause $A4E7, SPACE ($7FFE bit 0) SmartBomb
; $9751. ENTER, H and SPACE are fixed keys; the other five follow the menu's
; choice (DEFINE, Kempston, Cursor, Sinclair).
;
; Witness: L1 73 (c1, p1-cursor, p1-define, p1-kempston, p1-room x5, rzx-p1-
; x30).
MainLoop:
  CALL BuildRoom
MainPass:
  CALL MoveBullets        ; one pass: bullets, drones, Rex, objects, sound,
                          ; draw, collisions, HUD
  CALL MoveEnemyBullets
  CALL UpdateDrones
  CALL RexState
  CALL SparkleUpdate
  CALL SparkleDraw
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
  CALL SmartBombStep
  CALL KillFlashFade
  CALL FadeStep
  CALL HudSweep
  CALL ReadDown
  CALL Z,ShieldToggle
  CALL ReadDown
  JP Z,MainKeys
  XOR A
  LD (ShieldKeyLatch),A
MainKeys:
  LD BC,$BFFE             ; the fixed keys: ENTER, H, SPACE
  IN A,(C)
  BIT 0,A
  JP Z,NewGame
  LD BC,$BFFE
  IN A,(C)
  BIT 4,A
  CALL Z,Pause
  LD BC,$7FFE
  IN A,(C)
  BIT 0,A
  CALL Z,SmartBomb
  LD A,(RexX)
  LD (SpriteX),A
  LD A,(RexY)
  LD (SpriteY),A
  LD A,(RexFacing)
  CALL CellPointer
  LD (RexCellPtr),HL
  LD A,(Dying)
  OR A
  JP NZ,MainAnimate
  LD A,(RapidShotsOn)
  OR A
  JP Z,MainRexKeys
  XOR A
  LD (FireLatch),A
MainRexKeys:
  CALL ReadFire           ; while Rex lives: fire
  CALL Z,FireWeapon
  CALL ReadFire
  JP Z,MainRight
  XOR A
  LD (FireLatch),A
MainRight:
  CALL ReadRight          ; right
  CALL Z,WalkRightKey
  CALL ReadLeft
  CALL Z,WalkLeftKey
  CALL ReadUp
  CALL Z,StartJump
  CALL RexJump
  CALL RexFall
  CALL RexWalk
  CALL CellsUnderRex
MainAnimate:
  LD HL,AnimChar111       ; the animated characters: RRC, RLC, rolls
  LD B,$08
MainRrcLoop:
  RRC (HL)                ; rotate each line of character 111 right
  INC HL
  DJNZ MainRrcLoop
  LD HL,AnimChar143
  LD B,$08
MainRlcLoop:
  RLC (HL)                ; rotate each line of character 143 left
  RLC (HL)
  INC HL
  DJNZ MainRlcLoop
  LD HL,AnimChar28
  CALL RollCharLeft
  LD HL,AnimChar11
  CALL RollCharRight
  LD HL,AnimChar26
  CALL RollCharLeft
  CALL AnimateCells
  LD A,(PassToggle)
  XOR $01
  LD (PassToggle),A
  JP MainPass

; CALL SoundSilence: RET; no instruction reaches it (leftover)
;
; Four bytes between the main loop's JP and ShieldToggle. No jump or call names
; $967B (known only from the code).
;
; Witness: L1 0 ().
SoundOffReturn:
  CALL SoundSilence
  RET
