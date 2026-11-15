; --------------------------------------------------------------------------------------------------------------------
; tutor.asm: The Tutor Mode: each room's set-up, the panels at their frames, the input scripts, the room list
;
; DEMO plays rooms 4, 1, 0 and 2 (TutorRooms $A2A2) with Rex driven by an input script (TutorStep $9F82:
; [input][count] pairs; the key tests TutorKeyFire to TutorKeyShield read TutorInput $6079). Each room's tutor
; (TutorRoom0-4) puts Rex at his place with his weapons and power, shows its opening panel and starts its script;
; TutorPanels $9810 counts the passes (TutorFrame $6083) and at fixed frames opens a panel of TutorTexts $A431
; (TutorPanel: the screen saved, the boxed text, a fixed count, the screen back), changes the power or the weapon,
; switches the shield, drops a smart bomb, kills Rex or ends the room. After room 2 the credits and a new demo game.
; The random seed is reset at every room, so the demo is the same every time; SPACE pauses (DemoPause).
; --------------------------------------------------------------------------------------------------------------------

; A tutor panel: the screen saved, the sound off, the B text records at IX
; boxed (PanelOpen), a count of 33000, the screen back (PanelClose)
;
; Witness: L1 10 (demo-cycle).
TutorPanel:
  CALL PanelOpen
  LD BC,33000
  JP PanelClose

; A tutor panel with a count of 65000
;
; Witness: L1 3 (d1, demo-cycle).
TutorPanelLong:
  CALL PanelOpen
  LD BC,65000
  JP PanelClose

; A tutor panel with a count of 20000
;
; Witness: L1 8 (demo-cycle).
TutorPanelShort:
  CALL PanelOpen
  LD BC,$4E20
  JP PanelClose

; The screen saved (SaveScreen), the sound off, the records at IX boxed
; (PrintBoxed)
;
; Witness: L1 21 (d1, demo-cycle).
PanelOpen:
  PUSH IX
  PUSH BC
  CALL SaveScreen
  CALL SoundSilence
  POP BC
  POP IX
  CALL PrintBoxed
  RET

; The count BC (Delay), the buffer and attributes back on the screen, the sound
; on; from $963D a panel with the ammunition flash (FlashTwoCells)
;
; Witness: L1 21 (d1, demo-cycle).
PanelClose:
  CALL Delay
  CALL BufferToScreen
  CALL CopyAttrs
  CALL SoundReset
  RET

; TutorPanelFlash
;
; Used by the routine at TutorPanels.
TutorPanelFlash:
  PUSH IX                 ; a panel, the count 10000, then the flash of two
                          ; cells at $5809 (FlashTwoCells)
  PUSH BC
  CALL SaveScreen
  CALL SoundSilence
  POP BC
  POP IX
  CALL PrintBoxed
  LD BC,$2710
  CALL Delay
  CALL SoundReset
  CALL FlashTwoCells
  CALL BufferToScreen
  CALL CopyAttrs
  RET

; A tutor panel, the count 40000, then the power bar's colours shown
; (PowerColours)
;
; Witness: L1 3 (d1, demo-cycle).
TutorPanelPower:
  PUSH IX
  PUSH BC
  CALL SaveScreen
  CALL SoundSilence
  POP BC
  POP IX
  CALL PrintBoxed
  LD BC,40000
  CALL Delay
  CALL SoundReset
  CALL PowerColours
  CALL BufferToScreen
  CALL CopyAttrs
  RET

; Leftover: a panel, then five flashes of the HUD cell $5817; nothing calls it
;
; Witness: L1 0 ().
PanelLeftover:
  PUSH IX
  PUSH BC
  CALL SaveScreen
  CALL SoundSilence
  POP BC
  POP IX
  CALL PrintBoxed
  LD BC,$4E20
  CALL Delay
  CALL SoundReset
  LD B,$05
l_969B:
  PUSH BC
  LD HL,$5817
  LD (HL),$01
  LD BC,$1388
  CALL Delay
  LD (HL),$07
  LD BC,$1388
  CALL Delay
  POP BC
  DJNZ l_969B
  CALL BufferToScreen
  CALL CopyAttrs
  RET

; Room 0's tutor: the panel YOU HAVE NOW SEEN THE HARDWARE (TutorText0), the
; scripted spawn TutorSpawn0 $A2C4, three weapons held, power 5, Rex at (136,
; 72), its input script TutorScript0 $B057, the spray panel shown, Rex appears,
; TutorReset
;
; Witness: L1 1 (demo-cycle).
TutorRoom0:
  PUSH AF
  LD IX,TutorText0
  LD B,$03
  CALL PrintBoxed
  LD BC,50000
  CALL Delay
  LD HL,TutorSpawn0
  CALL StartScriptSpawn
  LD A,$01
  LD (HasDoubleFire),A
  LD (HasLaser),A
  LD (HasMultiple),A
  LD A,$05
  LD (PowerLevel),A
  LD HL,TutorScript0
  LD (TutorScriptPtr),HL
  LD A,$88
  LD (RexX),A
  LD (RestartX),A
  LD A,$48
  LD (RexY),A
  LD (RestartY),A
  LD A,$01
  LD (SprayText),A
  CALL Materialise
  CALL TutorReset
  POP AF
  RET

; Room 1's tutor: NEXT AN EXPLANATION OF THE FIVE WEAPON SYSTEMS (TutorText1),
; Rex at (120, 32), power 4, TutorScript1 $B1E7
;
; Witness: L1 3 (d1, demo-cycle).
TutorRoom1:
  PUSH AF
  LD IX,TutorText1
  LD B,$03
  CALL PrintBoxed
  LD BC,50000
  CALL Delay
  LD HL,TutorScript1
  LD (TutorScriptPtr),HL
  LD A,$78
  LD (RexX),A
  LD (RestartX),A
  LD A,$20
  LD (RexY),A
  LD (RestartY),A
  LD A,$04
  LD (PowerLevel),A
  CALL Materialise
  CALL TutorReset
  POP AF
  RET

; Room 2's tutor, once (TutorDone $6087): Rex at (8, 144), power 4, all four
; weapons, AND FINALLY A FEW GUIDELINES (TutorText2), the scripted spawn $A2FE,
; TutorScript2 $B5C7
;
; Witness: L1 2 (demo-cycle).
TutorRoom2:
  PUSH AF
  LD A,(TutorDone)
  OR A
  JP NZ,l_979A
  LD HL,TutorScript2
  LD (TutorScriptPtr),HL
  LD A,$08
  LD (RexX),A
  LD (RestartX),A
  LD A,$90
  LD (RexY),A
  LD (RestartY),A
  LD A,$04
  LD (PowerLevel),A
  LD A,$01
  LD (HasDoubleFire),A
  LD (HasLaser),A
  LD (HasMultiple),A
  LD (HasSpray),A
  LD (RexPresent),A
  XOR A
  LD (SparkleMode),A
  LD (SparkleOn),A
  LD (SparkleTimer),A
  LD (Vanishing),A
  LD A,(SparkleMode)
  OR A
  JP NZ,TutorRoom2Done
  LD IX,TutorText2
  LD B,$04
  CALL PrintBoxed
  LD BC,60000
  CALL Delay
TutorRoom2Done:
  LD HL,TutorSpawn2       ; shown already: nothing
  CALL StartScriptSpawn
  CALL TutorReset
  LD A,$01
  LD (TutorDone),A
l_979A:
  POP AF
  RET

; Room 4's tutor, the demo's first room: YOU ARE ABOUT TO SEE A DEMO OF REX
; (TutorIntro), FIRST A SHORT PROLOGUE (TutorPrologue), Rex at (112, 176),
; power 4, TutorScript4 $B833
;
; Witness: L1 2 (d1, demo-cycle).
TutorRoom4:
  PUSH AF
  LD IX,TutorIntro
  LD B,$05
  CALL PrintBoxed
  LD BC,50000
  CALL Delay
  LD IX,TutorPrologue
  LD B,$05
  CALL PrintBoxed
  LD BC,60000
  CALL Delay
  LD HL,TutorScript4
  LD (TutorScriptPtr),HL
  LD A,$70
  LD (RexX),A
  LD (RestartX),A
  LD A,$B0
  LD (RexY),A
  LD (RestartY),A
  LD A,$04
  LD (PowerLevel),A
  LD A,$01
  LD (RexPresent),A
  XOR A
  LD (SparkleMode),A
  LD (SparkleOn),A
  LD (SparkleTimer),A
  LD (Vanishing),A
  CALL TutorReset
  POP AF
  RET

; Z if the tutor's frame TutorFrame $6083 = DE
;
; Witness: L1 81240 (d1, demo-cycle).
AtFrame:
  LD HL,(TutorFrame)
  AND A
  SBC HL,DE
  JP Z,l_97FB
  LD A,$01
  CP $00
  RET
l_97FB:
  LD A,$00
  CP $00
  RET

; Leftover: the tutor frame printed as digits (a debugging aid); nothing calls
; it
;
; Witness: L1 0 ().
ShowFrameLeftover:
  LD HL,(TutorFrame)
  CALL ToDigits
  LD E,$1E
  LD L,$08
  LD B,$05
  CALL PrintDigits
  RET

; Each pass: TutorFrame + 1, then the room's events at their frames: panels
; (TutorPanel*), power changes, the shield, a smart bomb, deaths (TutorDie) and
; the end (TutorNextRoom); room 0 here, room 1 TutorEvents1, rooms 2-3
; TutorEvents2, rooms 4-5 TutorEvents4
;
; Room 0: REX MUST FIRST COLLECT WEAPONS at frame 25, AN EXTRA BONUS at 190,
; power drops at 250, 340, 430, THE LASER CAN at 345, power 3 and a drop at
; 600, a death at 710, the next room at 750.
;
; Witness: L1 6752 (d1, demo-cycle).
TutorPanels:
  LD HL,(TutorFrame)
  INC HL
  LD (TutorFrame),HL
  LD A,(Room)
  CP $00
  JP Z,l_9839
  CP $01
  JP Z,TutorEvents1
  CP $02
  JP Z,TutorEvents2
  CP $03
  JP Z,TutorEvents2
  CP $04
  JP Z,TutorEvents4
  CP $05
  JP Z,TutorEvents4
  RET
l_9839:
  LD IX,TutorTexts
  LD B,$03
  LD DE,$0019
  CALL AtFrame
  JP Z,TutorPanelFlash
  LD IX,TextBonus
  LD B,$04
  LD DE,$00BE
  CALL AtFrame
  JP Z,TutorPanel
  LD DE,$00FA
  CALL AtFrame
  CALL Z,PowerDrain
  LD DE,$0154
  CALL AtFrame
  CALL Z,PowerDrain
  LD DE,$01AE
  CALL AtFrame
  CALL Z,PowerDrain
  LD IX,TextLaser
  LD B,$03
  LD DE,$0159
  CALL AtFrame
  JP Z,TutorPanel
  LD DE,$0258
  CALL AtFrame
  CALL Z,PowerDrain
  LD DE,$0258
  CALL AtFrame
  CALL Z,TutorPower3
  LD DE,$02C6
  CALL AtFrame
  CALL Z,TutorDie
  LD DE,$02EE
  CALL AtFrame
  JP Z,TutorNextRoom
  RET

; Room 1's events: REX STARTS WITH THE STANDARD ISSUE (34), EACH WEAPON HAS A
; POWER STATUS (15), the weapons one by one with their power stepped
; (TutorWeapon*), the spray panels 3, 5, 7 WAY, 4 DIRECTIONAL, FULL 8 WAY
; (743-1081), a death at 1310, the next room at 1340; from $9979 rooms 2 and
; 3's: the shield, the bubbles, the beam pads, the recharger, the question
; marks, the walls, the exits, the scanners, falling, smart bombs
;
; Witness: L1 1948 (d1, demo-cycle).
TutorEvents1:
  LD IX,TextStandard
  LD B,$06
  LD DE,$0022
  CALL AtFrame
  CALL Z,TutorPanelLong
  LD IX,TextPower
  LD B,$07
  LD DE,$000F
  CALL AtFrame
  CALL Z,TutorPanelPower
  LD DE,$0082
  CALL AtFrame
  CALL Z,PowerDrain
  LD DE,$0154
  CALL AtFrame
  CALL Z,PowerDrain
  LD DE,$01EF
  CALL AtFrame
  CALL Z,TutorPowerDrop
  LD DE,$023D
  CALL AtFrame
  CALL Z,TutorPower5
  CALL AtFrame
  CALL Z,TutorPowerUp
  LD DE,$029E
  CALL AtFrame
  CALL Z,TutorPowerDrop
  LD IX,TextSpray3
  LD B,$01
  LD DE,$02E7
  CALL AtFrame
  CALL Z,TutorPanelShort
  LD DE,$0320
  CALL AtFrame
  CALL Z,TutorPowerUp
  LD IX,TextSpray5
  LD B,$01
  LD DE,$0321
  CALL AtFrame
  CALL Z,TutorPanelShort
  LD DE,$0361
  CALL AtFrame
  CALL Z,TutorPowerUp
  LD IX,TextSpray7
  LD B,$01
  LD DE,$0362
  CALL AtFrame
  CALL Z,TutorPanelShort
  LD DE,$03AC
  CALL AtFrame
  CALL Z,TutorPowerUp
  LD IX,TextSpray4
  LD B,$01
  LD DE,$03AD
  CALL AtFrame
  CALL Z,TutorPanelShort
  LD DE,$0438
  CALL AtFrame
  CALL Z,TutorPowerUp
  LD IX,TextSpray8
  LD B,$01
  LD DE,$0439
  CALL AtFrame
  CALL Z,TutorPanelShort
  LD DE,$051E
  CALL AtFrame
  CALL Z,TutorDie
  LD DE,$053C
  CALL AtFrame
  JP Z,TutorNextRoom
  RET
; This entry point is used by the routine at TutorPanels.
TutorEvents2:
  LD IX,TextShield        ; rooms 2 and 3
  LD B,$04
  LD DE,$00AA
  CALL AtFrame
  CALL Z,TutorPanel
  LD IX,TextBubbles
  LD B,$04
  LD DE,$011C
  CALL AtFrame
  CALL Z,TutorPanel
  LD IX,TextBeamPads
  LD B,$02
  LD DE,$0169
  CALL AtFrame
  CALL Z,TutorPanelShort
  LD IX,TextRecharge
  LD B,$02
  LD DE,$0195
  CALL AtFrame
  CALL Z,TutorPanelShort
  LD IX,TextQuestion
  LD B,$04
  LD DE,$01B6
  CALL AtFrame
  CALL Z,TutorPanel
  LD IX,TextWalls
  LD B,$02
  LD DE,$01C6
  CALL AtFrame
  CALL Z,TutorPanelShort
  LD IX,TextExits
  LD B,$03
  LD DE,$021C
  CALL AtFrame
  CALL Z,TutorPanel
  LD DE,$02E0
  CALL AtFrame
  JP Z,SmartBomb
  LD IX,TextSmartBombs
  LD B,$05
  LD DE,$02DC
  CALL AtFrame
  CALL Z,TutorPanel
  LD IX,TextScanners
  LD B,$04
  LD DE,$027D
  CALL AtFrame
  JP Z,TutorPanel
  LD DE,$027E
  CALL AtFrame
  JP Z,FlashPlay
  LD DE,$028A
  CALL AtFrame
  JP Z,ShieldFlip
  LD DE,$02C6
  CALL AtFrame
  JP Z,ShieldFlip
  LD IX,TextFalling
  LD B,$04
  LD DE,$0339
  CALL AtFrame
  CALL Z,TutorPanel
  LD IX,TextTeleport
  LD B,$03
  LD DE,$0370
  CALL AtFrame
  CALL Z,TutorPanel
  LD DE,$03AC
  CALL AtFrame
  JP Z,TutorNextRoom
  RET

; Rooms 4 and 5's events: the shield on and off (150, 172, 455, 470), a smart
; bomb at 930, a death at 1030, the next room at 1060; from $9A8C FlashPlay:
; the play area's attributes made bright five times (the smart bomb's flash)
;
; Witness: L1 3114 (d1, demo-cycle).
TutorEvents4:
  LD DE,$0096
  CALL AtFrame
  JP Z,ShieldFlip
  LD DE,$00AC
  CALL AtFrame
  JP Z,ShieldFlip
  LD DE,$01C7
  CALL AtFrame
  JP Z,ShieldFlip
  LD DE,$01D6
  CALL AtFrame
  JP Z,ShieldFlip
  LD DE,$03A2
  CALL AtFrame
  JP Z,SmartBomb
  LD DE,$0406
  CALL AtFrame
  JP Z,TutorDie
  LD DE,$0424
  CALL AtFrame
  JP Z,TutorNextRoom
  RET
; This entry point is used by the routine at TutorEvents1.
FlashPlay:
  LD B,$05                ; five flashes of the play area: BrightenAttr over
                          ; rows and columns
l_9A8E:
  PUSH BC
  LD HL,$5901
  LD B,$1E
l_9A94:
  CALL BrightenAttr
  DJNZ l_9A94
  LD HL,$5874
  LD B,$15
l_9A9E:
  CALL BrightenAttr
  LD DE,$001F
  ADD HL,DE
  DJNZ l_9A9E
  LD BC,$0BB8
  CALL Delay
  CALL CopyAttrs
  LD BC,$0BB8
  CALL Delay
  POP BC
  DJNZ l_9A8E
  RET

; The attribute at HL bright unless 0; HL + 1
;
; Changed from REX 1's SpawnFindFree $C9E5 (src/game/rooms.asm).
;
; Witness: L1 255 (demo-cycle).
BrightenAttr:
  LD A,(HL)
  OR A
  JP Z,SpawnNextRecord
  OR $08
  LD (HL),A
SpawnNextRecord:
  INC HL
  RET

; The power drained (PowerDrain) and set to 1
;
; Witness: L1 2 (demo-cycle).
TutorPowerDrop:
  CALL PowerDrain
  LD A,$01
  LD (PowerLevel),A
  RET

; Power + 1, the drones again (InitDrones)
;
; Witness: L1 4 (demo-cycle).
TutorPowerUp:
  LD HL,PowerLevel
  INC (HL)
  CALL InitDrones
  RET

; Power 5, the drones again
;
; Witness: L1 1 (demo-cycle).
TutorPower5:
  LD A,$05
  LD (PowerLevel),A
  CALL InitDrones
  RET

; The power bar's five colours shown in turn at $5801 (Fill2x2)
;
; Witness: L1 3 (d1, demo-cycle).
PowerColours:
  LD B,$05
  LD C,$03
l_9AE2:
  LD A,C
  LD HL,$5801
  CALL Fill2x2
  PUSH BC
  LD BC,$1388
  CALL Delay
  POP BC
  INC C
  DJNZ l_9AE2
  RET

; The 2 x 2 cells at $5809 flashed five times (white, blue)
;
; Witness: L1 1 (demo-cycle).
FlashTwoCells:
  LD B,$05
l_9AF7:
  PUSH BC
  LD A,$07
  LD HL,$5809
  CALL Fill2x2
  LD BC,$07D0
  CALL Delay
  LD A,$01
  LD HL,$5809
  CALL Fill2x2
  LD BC,$07D0
  CALL Delay
  POP BC
  DJNZ l_9AF7
  RET

; A into the 2 x 2 attributes at HL
;
; Witness: L1 25 (d1, demo-cycle).
Fill2x2:
  LD (HL),A
  INC HL
  LD (HL),A
  LD DE,$001F
  ADD HL,DE
  LD (HL),A
  INC HL
  LD (HL),A
  RET

; Rex dies (RexDies), keeping A
;
; Witness: L1 5 (d1, demo-cycle).
TutorDie:
  PUSH AF
  CALL RexDies
  POP AF
  RET

; The end of a room's script: after room 2 the credits ALL SOFTWARE SOUND AND
; VISION BY THE LIGHT (TutorCredits), then NextTutorRoom and a new demo game
; (NewGame)
;
; Witness: L1 6 (d1, demo-cycle).
TutorNextRoom:
  LD A,(Room)
  CP $02
  JP NZ,l_9B52
  CALL SoundSilence
  CALL ClearPlayAttrs
  CALL ClearBuffer
  CALL BufferToScreen
  LD IX,TutorCredits
  LD B,$04
  CALL PrintBoxed
  LD BC,60000
  CALL Delay
  LD BC,50000
  CALL Delay
l_9B52:
  CALL NextTutorRoom
  POP BC
  JP NewGame

; Power 3
;
; Witness: L1 1 (demo-cycle).
TutorPower3:
  LD A,$03
  LD (PowerLevel),A
  RET

; Power 0, PowerCount 0, then 40 power gains of $FF (the bar runs up), power 5
;
; Witness: L1 11 (d1, demo-cycle).
PowerDrain:
  XOR A
  LD (PowerLevel),A
  LD (PowerCount),A
  LD B,$28
l_9B68:
  PUSH BC
  LD A,$FF
  CALL PowerGain
  POP BC
  DJNZ l_9B68
  LD A,$05
  LD (PowerLevel),A
  RET

; The tutor frame 0, the script's first count, TutorInput $FF (nothing
; pressed), TutorDone 0
;
; Witness: L1 8 (d1, demo-cycle).
TutorReset:
  LD HL,$0000
  LD (TutorFrame),HL
  LD HL,(TutorScriptPtr)
  LD A,(HL)
  LD (TutorCount),A
  XOR A
  LD (TutorUnused),A
  LD (TutorDone),A
  LD A,$FF
  LD (TutorInput),A
  RET

; The next room of TutorRooms $A2A2 into Room ($FF: the list again)
;
; Witness: L1 7 (d1, demo-cycle).
NextTutorRoom:
  LD HL,(TutorRoomPtr)
l_9B94:
  LD A,(HL)
  CP $FF
  JP NZ,l_9BA3
  LD HL,TutorRooms
  LD (TutorRoomPtr),HL
  JP l_9B94
l_9BA3:
  LD (Room),A
  INC HL
  LD (TutorRoomPtr),HL
  RET

; The play area's attributes ($5860-$5AFF) to 0
;
; Witness: L1 13 (d1, demo-cycle).
ClearPlayAttrs:
  LD HL,$5860
  LD DE,$5861
  LD BC,$029F
  LD (HL),$00
  LDIR
  RET
