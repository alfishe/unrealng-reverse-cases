; --------------------------------------------------------------------------------------------------------------------
; entry.asm: The entry, a new demo game
; --------------------------------------------------------------------------------------------------------------------

; The code block's entry (USR 35460): DI, keys (ControlXor 0), the tutor's room
; list from its start (TutorRooms $A2A2), the first room (NextTutorRoom), the
; tutor reset (TutorReset), then NewGame
;
; Changed from REX 1's GameEntry $947A (src/game/entry.asm).
;
; Witness: L1 1 (d1).
GameEntry:
  DI
  XOR A
  LD (ControlXor),A
  LD HL,TutorRooms
  LD (TutorRoomPtr),HL
  CALL NextTutorRoom
  CALL TutorReset

; A new demo game: the variables reset, 2 lives, 3 bombs, the gun, every weapon
; panel shown again; the HUD; no menu, no high score
;
; Changed from REX 1's NewGame $9498 (src/game/entry.asm).
;
; Witness: L1 7 (d1, demo-cycle).
NewGame:
  CALL InitDrones
  LD A,$08
  LD (FireDelay),A
  XOR A
  OUT ($FE),A
  LD (Immune),A
  XOR A
  LD (AnimCount1),A
  LD (AnimCount2),A
  LD (AnimCount4),A
  LD (AnimCount1),A
  LD (AnimCount3),A
  LD (RestartRoom),A
  LD (RestartFacing),A
  LD (SpeedUp),A
  LD (SpeedUpPhase),A
  LD (DoubleFireText),A
  LD (LaserText),A
  LD (MultipleText),A
  LD (SprayText),A
  LD (Dying),A
  XOR A
  LD (SweepPos),A
  LD (SweepDir),A
  LD HL,$0313
  LD (RandomSeed),HL
  LD A,$11
  LD (RandomSeed2),A
  LD HL,$0000
  LD (Score),HL
  LD (ExtraLifeCount),HL
  LD A,$02
  LD (Lives),A
  LD A,$07
  LD (HeatColour),A
  LD A,$03
  LD (Bombs),A
  LD HL,$0064
  LD (HeatCount),HL
  CALL StartWeapon
  LD A,$63
  LD (ShieldEnergy),A
  LD A,$05
  LD (ShieldDrainRate),A
  LD HL,ArrowPath
  LD (ArrowPathPtr),HL
  LD A,$01
  LD (WeaponIcon),A
  XOR A
  LD (HasDoubleFire),A
  LD (HasLaser),A
  LD (HasMultiple),A
  LD (HasSpray),A
  XOR A
  LD (RapidShotsOn),A
  LD (ArrowMoving),A
  LD (SmartBombOn),A
  LD (RexFrame),A
  LD (ShieldOn),A
  LD A,$78
  LD (RexX),A
  LD (RestartX),A
  LD A,$20
  LD (RexY),A
  LD (RestartY),A
  XOR A
  LD (RexFacing),A
  LD (Jumping),A
  LD (RexSpeed),A
  LD (FallSpeed),A
  XOR A
  LD (PowerCount),A
  LD A,$FF
  LD (FadeStepIndex),A
  LD A,$00
  CALL ClearScreen
  CALL DrawHud
  CALL ShowLives
  CALL SaveAttrs
  CALL SoundReset

; Build the room (first the room's tutor: TutorRoom0, 1, 2 or 4), then one pass
; of play a frame: Rex's moves come from the tutor's input script (TutorStep),
; the tutor's panels at their frames (TutorPanels), the arrow in room 4
; (TutorArrow), SPACE pauses (DemoPause)
;
; The key tests of part 1 (KeyFire, KeyLeft, ...) read TutorInput $6079 here
; (TutorKeyFire to TutorKeyShield); no ENTER, H or smart bomb key. The seed is
; reset at every room (RandomSeed $0313, RandomSeed2 $11, R = 3), so the demo
; plays the same each time. Room 3 starts the scripted spawn (TutorSpawn3
; $A318).
;
; Witness: L1 12 (d1, demo-cycle).
MainLoop:
  XOR A
  LD (PassToggle),A
  LD (ScriptSpawnStep),A
  LD A,(Room)
  CP $00
  CALL Z,TutorRoom0
  CP $01
  CALL Z,TutorRoom1
  CP $02
  CALL Z,TutorRoom2
  CP $04
  CALL Z,TutorRoom4
  LD HL,$0313
  LD (RandomSeed),HL
  LD A,$11
  LD (RandomSeed2),A
  LD A,$03
  LD R,A
  LD (SfxExplosion),A
  CALL ResetSweep
  LD HL,ObjectBufferOrigin
  LD (KillFlashPtr),HL
  CALL ReadExits
  LD HL,$5B95
  LD DE,$5B96
  LD BC,$02ED
  LD (HL),$00
  LDIR
  CALL DrawRoom
  CALL ClearPlayAttrs
  CALL ClearBuffer
  CALL DrawAnimCells
  CALL BufferToScreen
  CALL CopyAttrs
  CALL MakeObjects
  LD A,(Room)
  CP $03
  JP NZ,l_8BD6
  LD HL,TutorSpawn3
  CALL StartScriptSpawn
l_8BD6:
  CALL DrawHud
  CALL ShowShield
  CALL ShowHeat
  LD A,$01
  LD (RestartFacing),A
  LD HL,$0313
  LD (RandomSeed),HL
  LD A,$11
  LD (RandomSeed2),A
l_8BEF:
  CALL MoveBullets
  CALL MoveEnemyBullets
  CALL UpdateDrones
  CALL RexState
  CALL SparkleUpdate
  CALL SparkleDraw
  CALL UpdateObjects
  CALL SoundStep
  CALL TutorArrow
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
  CALL HeatStep
  CALL FadeStep
  CALL HudSweep
  CALL TutorPanels
  CALL TutorStep
  CALL TutorKeyShield
  CALL Z,ShieldToggle
  CALL TutorKeyShield
  JP Z,l_8C47
  XOR A
  LD (ShieldKeyLatch),A
l_8C47:
  LD BC,$7FFE
  IN A,(C)
  BIT 0,A
  CALL Z,DemoPause
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
  CALL TutorKeyFire       ; while Rex lives: fire
  CALL Z,FireWeapon
  CALL TutorKeyFire
  JP Z,MainRight
  XOR A
  LD (FireLatch),A
MainRight:
  CALL TutorKeyRight      ; right
  CALL Z,WalkRightKey
  CALL TutorKeyLeft
  CALL Z,WalkLeftKey
  CALL TutorKeyUp
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
  JP l_8BEF

; Leftover: CALL SoundSilence: RET after the main loop's JP; nothing reaches it
;
; Witness: L1 0 ().
MainLoopLeftover:
  CALL SoundSilence
  RET
