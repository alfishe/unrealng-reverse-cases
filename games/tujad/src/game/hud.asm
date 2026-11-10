; --------------------------------------------------------------------------------------------------------------------
; hud.asm: The timers, the pause, the frame wait, the weapons, a new game, the HUD
; --------------------------------------------------------------------------------------------------------------------

; Count down the fast drain after an enemy's touch
;
; Every interrupt: while TouchTimer is not 0 it counts down; at 0 EnergyReload
; and EnergyTimer go back to $FA (one energy step every 250 interrupts, 5 s).
; L1 54 825 calls, 49 ends.
DrainTimer:
  LD HL,TouchTimer
  XOR A
  CP (HL)
  RET Z
  DEC (HL)
  RET NZ
  LD A,$FA
  LD (EnergyReload),A
  LD (EnergyTimer),A
  RET

; Clear the play area's pixels (screen rows 6-23)
;
; $90 lines of 32 bytes from $40C0. Callers: DrawRoom with A not 0, the menu,
; ProgressScreen. L1 146.
ClearPlayArea:
  LD HL,Screen+192
  LD B,$90
ClearPlayAreaLine:
  PUSH BC
  PUSH HL
  LD B,$20
ClearPlayAreaByte:
  LD (HL),$00
  INC L
  DJNZ ClearPlayAreaByte
  POP HL
  INC H
  LD A,H
  AND $07
  JR NZ,ClearPlayAreaNext
  LD A,L
  ADD A,$20
  LD L,A
  JR C,ClearPlayAreaNext
  LD A,H
  SUB $08
  LD H,A
ClearPlayAreaNext:
  POP BC
  DJNZ ClearPlayAreaLine
  RET

; ENTER pauses and resumes
;
; ENTER pressed after a release (KeyLatches bit 1) toggles Controls bit 5; the
; routine loops while bit 5 is set. MainLoop calls it after WaitFrame's DI and
; PauseLoop never enables interrupts, so while paused no interrupt is taken: no
; sprite is drawn, the scroller stops and EnergyTick does not count. Witness:
; c1, ENTER held at 15240-15250 and 15350-15360 (exec $7949); no exec of
; Interrupt $95D0 or EnergyTick $7AB6 in 15241-15359; EnergyTimer $64 and
; Energy $97 at the start of 15241, 15300 and 15359. L1 18 582 calls, 2 toggles
; (c1).
Pause:
  LD HL,KeyLatches
  LD BC,$BFFE
PauseLoop:
  IN A,(C)
  BIT 0,A
  LD A,(Controls)
  JR NZ,PauseReleased
  BIT 1,(HL)
  JR Z,PauseLoop
  RES 1,(HL)
  XOR $20
  LD (Controls),A
  JR PauseLoop
PauseReleased:
  SET 1,(HL)
  BIT 5,A
  JR NZ,PauseLoop
  RET

; End the sprite list, wait for the interrupt to draw it, start a new list
;
; Writes the zero word at SpriteListEnd, sets SpriteListEnd = SpriteList, EI,
; NOP, HALT; the interrupt XORs every queued sprite; DI; SpriteListEnd =
; SpriteList. MainLoop calls it twice a pass (L1 37 159 calls).
WaitFrame:
  LD HL,(SpriteListEnd)
  LD (HL),$00
  INC HL
  LD (HL),$00
  LD HL,SpriteList
  LD (SpriteListEnd),HL
  EI
  NOP
  HALT
  DI
  LD HL,SpriteList
  LD (SpriteListEnd),HL
  RET

; SPACE: the next weapon with ammunition
;
; Every interrupt while no shot is in flight. SPACE ($7EFE bit 0) pressed after
; a release (KeyLatches bit 0): Weapons shifts right to the next weapon whose
; Ammo is not 0, past weapon 3 back to weapon 0 ($80), and ShowWeapon. L1 54
; 824 calls, 47 changes.
WeaponSelect:
  LD A,(Shot)
  CP $00
  RET NZ
  LD HL,KeyLatches
  LD BC,$7EFE
  IN A,(C)
  BIT 0,A
  JR NZ,WeaponSelectReleased
  BIT 0,(HL)
  RET Z
  RES 0,(HL)
  LD HL,Weapons
  BIT 7,(HL)
  JR Z,WeaponSelect1
  LD A,(Ammo)
  CP $00
  JR NZ,WeaponSelectNext
  SRL (HL)
WeaponSelect1:
  BIT 6,(HL)
  JR Z,WeaponSelect2
  LD A,(Ammo+$0001)
  CP $00
  JR NZ,WeaponSelectNext
  SRL (HL)
WeaponSelect2:
  BIT 5,(HL)
  JR Z,WeaponSelectBasic
  LD A,(Ammo+$0002)
  CP $00
  JR NZ,WeaponSelectNext
WeaponSelectBasic:
  LD (HL),$80
  JR WeaponSelectShow
WeaponSelectNext:
  SRL (HL)
WeaponSelectShow:
  CALL ShowWeapon
  RET
WeaponSelectReleased:
  SET 0,(HL)
  RET

; The weapon's icon and ammunition on the HUD
;
; The 16 x 16 icon (HudIcons + 32 x weapon, Blit16 at $4422) with its colour
; ($47, $43, $44, $46) on 2 x 4 cells, then the ammunition at $4082 (PrintBcd)
; or, for weapon 0, two blank characters. L1 58.
ShowWeapon:
  LD A,(Weapons)
  BIT 7,A
  JR Z,ShowWeapon1
  LD C,$47
  LD DE,HudIcons
  LD HL,$0000
ShowWeapon1:
  BIT 6,A
  JR Z,ShowWeapon2
  LD C,$43
  LD DE,IconWeapon1
  LD HL,Ammo
ShowWeapon2:
  BIT 5,A
  JR Z,ShowWeapon3
  LD C,$44
  LD DE,IconWeapon2
  LD HL,Ammo+$0001
ShowWeapon3:
  BIT 4,A
  JR Z,ShowWeaponIcon
  LD C,$46
  LD DE,IconWeapon3
  LD HL,Ammo+$0002
ShowWeaponIcon:
  PUSH HL
  LD HL,Screen+1058
  PUSH HL
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD B,$04
ShowWeaponColour:
  LD (HL),C
  INC L
  LD (HL),C
  LD A,L
  ADD A,$1F
  LD L,A
  DJNZ ShowWeaponColour
  POP HL
  CALL Blit16
  POP HL
  LD A,H
  OR L
  JR NZ,ShowWeaponAmmo
  LD DE,BlankGraphic
  LD HL,Screen+130
  CALL Print8
  LD HL,Screen+131
  CALL Print8
  RET
ShowWeaponAmmo:
  LD A,(HL)
  LD HL,Screen+130
  CALL PrintBcd
  RET

; A new game: the rooms dealt, the work space reset, room $54
;
; ClearScreen; InitRooms $7BCC (every item present, the objects reset);
; ScrambleRooms an odd number of times, 1 to 31 (Random OR 1 AND $1F: 16
; possible counts; each call rotates the 64 non-weapon item kinds one slot
; along the rooms: 16 possible deals for the first game after loading;
; InitRooms does not undo the rotation, so a later game rotates on);
; ExhaustRows to EdFlagsEnd zeroed; Room = $54 (the control room); PlaceDroid;
; InitialVars copied; DrawHud $8AE8; DrawRoom with A = $FF. L1 4 new games, 34
; scrambles.
NewGame:
  CALL ClearScreen
  CALL InitRooms
  CALL Random
  OR $01
  AND $1F
  LD B,A
NewGameScramble:
  PUSH BC
  CALL ScrambleRooms
  POP BC
  DJNZ NewGameScramble
  LD HL,ExhaustRows
  LD DE,ExhaustRows+$0001
  LD BC,$00A6
  LD (HL),$00
  LDIR
  LD A,$54
  LD (Room),A
  CALL PlaceDroid
  LD HL,InitialVars
  LD DE,ControlsLatch
  LD BC,$001C
  LDIR
  CALL DrawHud
  LD A,$FF
  CALL DrawRoom
  RET

; Put the droid at the room's start position
;
; DroidFlags $40 (facing right) or $41 when the droid graphics are mirrored
; (byte 4 of DroidGraphics is not $70); x and y from StartPositions + 2 x Room;
; frame 8, width 2; Shot = 0. L1 59 (4 new games, 55 lives).
PlaceDroid:
  LD A,(DroidGraphics+$0004)
  CP $70
  LD A,$40
  JR Z,PlaceDroidFacing
  LD A,$41
PlaceDroidFacing:
  LD (DroidFlags),A
  LD HL,StartPositions
  LD A,(Room)
  SLA A
  LD D,$00
  LD E,A
  ADD HL,DE
  LD A,(HL)
  LD (DroidVars),A
  INC HL
  LD A,(HL)
  LD (DroidY),A
  LD A,$08
  LD (DroidFrame),A
  LD A,$02
  LD (DroidWidth),A
  XOR A
  LD (Shot),A
  RET

; Clear the pixels, the attributes to 7 (white ink on black)
;
; L1 8.
ClearScreen:
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$17FF
  LD (HL),$00
  LDIR
  INC HL
  INC DE
  LD (HL),$07
  LD BC,$02FF
  LDIR
  RET

; Count the energy down one every EnergyTimer interrupts
;
; Every interrupt (L1 54 825). When EnergyTimer reaches 0 it reloads from
; EnergyReload ($FA: 5 s a step; $0A under the shield, 0.2 s; after an enemy's
; touch each touching pass sets EnergyTimer back to 10, so the 5 fast steps
; come 10-50 interrupts after the last touch), Energy - 1 (BCD) printed at
; $4088; at 11 the message WARNING ENERGY LOW. EnergyTimer 0 stops it (the win
; and the game over set it to 0). L1 378 steps.
EnergyTick:
  XOR A
  LD HL,EnergyTimer
  CP (HL)
  RET Z
  DEC (HL)
  RET NZ
  LD A,(EnergyReload)
  LD (HL),A
  LD A,(Energy)
  CP $11
  JR NZ,EnergyTickStep
  LD HL,MsgEnergyLow
  CALL QueueMessage
  LD A,(Energy)
EnergyTickStep:
  SUB $01
  DAA
  LD (Energy),A
  LD HL,Screen+136
  CALL PrintBcd
  RET

; The droid shaken apart: its image shifted out a pixel a line, eight times,
; with a falling sweep
;
; KeyLatches bit 7 (no fire) while it runs. The droid's image lines are shifted
; right and left alternately (as DrawRoom's wipe) 8 times, each with FallSweep
; $7F5D. DroidGraphic = BlankGraphic. L1 55.
DeathEffect:
  LD HL,KeyLatches
  SET 7,(HL)
  LD BC,(DroidVars)
  CALL ScreenAddr
  EX DE,HL
  LD A,(DroidWidth)
  INC A
  LD C,A
  LD B,$08
DeathEffectStep:
  PUSH BC
  PUSH HL
  LD B,$14
DeathEffectLine:
  PUSH BC
  PUSH HL
  LD B,C
DeathEffectRight:
  SRL (HL)
  INC L
  DJNZ DeathEffectRight
  POP HL
  INC H
  LD A,H
  AND $07
  JR NZ,DeathEffectLeftLine
  LD A,L
  ADD A,$20
  LD L,A
  JR C,DeathEffectLeftLine
  LD A,H
  SUB $08
  LD H,A
DeathEffectLeftLine:
  PUSH HL
  LD B,C
DeathEffectLeft:
  SLA (HL)
  INC L
  DJNZ DeathEffectLeft
  POP HL
  INC H
  LD A,H
  AND $07
  JR NZ,DeathEffectNext
  LD A,L
  ADD A,$20
  LD L,A
  JR C,DeathEffectNext
  LD A,H
  SUB $08
  LD H,A
DeathEffectNext:
  POP BC
  DJNZ DeathEffectLine
  CALL FallSweep
  POP HL
  POP BC
  DJNZ DeathEffectStep
  LD DE,BlankGraphic
  LD (DroidGraphic),DE
  LD HL,KeyLatches
  RES 7,(HL)
  RET

; Print a BCD byte as two digits, after one click
;
; In: A the byte, HL the screen address. A leading 0 is a space (ROM font
; $3D00); the digits come from Font (Font - $100 + 8 x code). Before the first
; digit only, a click of 50 passes (OUT, XOR $10, OUT: 50 speaker edges 42 T
; apart, 41.7 kHz, 2100 T); the second digit has none. Print8 $8A79 prints. L1
; 549.
PrintBcd:
  PUSH AF
  AND $F0
  SRL A
  SRL A
  SRL A
  SRL A
  LD DE,$3D00
  CP $00
  JR Z,PrintBcdClick
  ADD A,$30
  PUSH HL
  LD HL,Font-$0100
  LD D,$00
  LD E,A
  SLA E
  SLA E
  SLA E
  RL D
  ADD HL,DE
  EX DE,HL
  POP HL
PrintBcdClick:
  XOR A
  LD B,$32
PrintBcdClickLoop:
  OUT ($FE),A
  XOR $10
  OUT ($FE),A
  DJNZ PrintBcdClickLoop
  CALL Print8
  INC L
  POP AF
  AND $0F
  ADD A,$30
  PUSH HL
  LD HL,Font-$0100
  LD D,$00
  LD E,A
  SLA E
  SLA E
  SLA E
  RL D
  ADD HL,DE
  EX DE,HL
  POP HL
  CALL Print8
  RET
