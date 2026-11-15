; --------------------------------------------------------------------------------------------------------------------
; mainloop.asm: The main loop: one pass a frame of play, the keys
; --------------------------------------------------------------------------------------------------------------------

  ORG $9585

; Build the room, then one pass of play a frame: the HUD, objects, bullets, the
; boss's explosion while BossDying $A268, the keys (ENTER restart, H pause,
; SPACE smart bomb), fire, Rex's moves (none while the boss dies) and the cells
; under him
;
; Changed from REX 1's MainLoop $9583 (src/game/mainloop.asm).
;
; Witness: L1 29 (c2, p2-room20, rzx-p2- x17).
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
  LD A,(BossDying)
  OR A
  CALL NZ,BossExplodes
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
  JP Z,MainFire
  XOR A
  LD (FireLatch),A
MainFire:
  CALL ReadFire           ; fire: FireWeapon
  CALL Z,FireWeapon
  CALL ReadFire
  JP Z,MainBossCheck
  XOR A
  LD (FireLatch),A
MainBossCheck:
  LD A,(BossDying)        ; while the boss dies, no walking
  OR A
  JP NZ,MainUp
MainRight:
  CALL ReadRight          ; right
  CALL Z,WalkRightKey
  CALL ReadLeft
  CALL Z,WalkLeftKey
MainUp:
  CALL ReadUp             ; up: the jump
  CALL Z,StartJump
  CALL RexJump
  CALL RexFall
  CALL RexWalk
  CALL CellsUnderRex
MainAnimate:
  CALL AnimateCells       ; the animated characters
  LD A,(PassToggle)
  XOR $01
  LD (PassToggle),A
  JP MainPass

; CALL SoundSilence: RET; no instruction reaches it (leftover, as in REX 1)
;
; Witness: L1 0 ().
SoundOffReturn:
  CALL SoundSilence
  RET
