; --------------------------------------------------------------------------------------------------------------------
; missionflow.asm: The mission's start, the play loops of the three views, the play keys
;
; StartMission $694B sets the play state from the mission block's header ($DBD9-$DBDA), draws the panel through bank 7
; ($74AA), and then runs PlayLoop $6A0C until the flag at $6A6D (the operand of LD A,0 at $6A6C) says the view
; changes. The views each have their own loop: the 3D view (PlayLoop), the Dragonfly's flight view ($6AB9, after its
; launch), the status view ($6BC7) and the damage board ($6C93, key D). The loops call the same world, object and
; enemy steps; only the drawing differs.
;
; The key codes come from the interrupt's keyboard scan (ScanKeyboard $8910) in KeyCode $8979 with the new-key flag in
; bit 1 of KeyFlags $8978.
;
; A mission's goal hook (the block's word at $DBE1, called from $6A66 every pass) sets the flag $68E8 when the goal
; objects are destroyed. Then PickupAnnounce $DB71 prints the message once, and the Helicarrier at the pad ($7E89 /
; $7E8C) takes the player away: mission complete through $67EE ($7040), the reason of a failure in $7BF9 and $7047.
; --------------------------------------------------------------------------------------------------------------------

; Start the loaded mission: the play state from the header, the panel, the
; counters, then PlayLoop
;
; Reads the mission block's header (`$DBDA` -> `$BBF2`, `$DBD9` -> `$BBFA`),
; clears `$BC33`, sets the 3D view's blit (`$83E6` = `$8999`), draws the panel
; (`DrawBank7Picture` `$74AA` with DE = `$DD75`), resets the view parameters at
; `$9A6C`-`$9ABB`, calls the bank-6 set-up `$D521`, the weapon bars (`$7336`,
; `$73BA`), `$C632`, `$AE42`; clears the play flags (`$8459`, `$6A6D`, `$87E0`,
; `$D689`, `$D4B8`), prints `$D520` if `$7578` is set, then runs `$BA4A`,
; `$CEAB` and the play keys and falls into PlayLoop.
;
; Witness: L1 27 (death, m2erbe, missions, play, play2).
StartMission:
  CALL PageBank0
  CALL PageShadowScreen
  LD A,$C9
  LD (BlinkLamp),A
  LD HL,(MissionHeader+$0015)
  LD (ActivateMissionObjects+$0001),HL
  LD A,(MissionHeader+$0014)
  LD B,A
  LD (ActivateMissionObjects+$0009),A
  XOR A
  LD (l_BBFB+$0038),A
  LD HL,ViewBlitFront
  LD (MenuJobs+$0007),HL
  LD DE,MissionHeader+$01B0
  CALL DrawBank7Picture
  LD A,(NightKey+$0001)
  AND A
  CALL NZ,NightBoxSelect
  LD HL,$0080
  LD (l_9A9E+$0005),HL
  LD L,$31
  LD (l_9A9E+$001D),HL
  LD L,$00
  LD (l_9A85+$0009),HL
  LD (l_9A9E+$0015),HL
  LD HL,$0190
  LD (l_9A5E+$000E),HL
  CALL PanelSetup
  CALL SaveBank
  CALL PageBank6
  LD A,$FF
  LD (HelicarrierData+$0046),A
  LD A,(l_D584+$001E)
  CPL
  LD (l_D584+$001E),A
  LD A,(HelicarrierData+$0076)
  CPL
  LD (HelicarrierData+$0076),A
  CALL RestoreBank
  CALL UpdateAmmoBars
  CALL PageBank6
  CALL DrawSlotIcons
  CALL PageBank0
  CALL RefreshWeaponPanel
  CALL ResetSegmentWalk
  LD A,$04
  LD (StepFrames),A
  LD A,$FF
  LD (l_884C+$000B),A
  XOR A
  LD (BlinkWarning),A
  LD (ViewChangeFlag+$0001),A
  LD (MessageTimer+$000A),A
  LD (SoundGate),A
  LD (BoundaryCheck),A
  LD A,(AwolState)
  AND A
  JR Z,l_69EA
  LD HL,AwolWarningText+$0001
  CALL PrintString
l_69EA:
  LD A,(l_BA1F+$0008)
  AND A
  PUSH AF
  CALL ToggleRearView
  POP AF
  LD A,(ToggleBinoculars+$0001)
  AND A
  PUSH AF
  CALL SetBinoculars
  POP AF
  JR Z,l_6A04
  LD A,(l_CEC9+$000B)
  CALL ShowBinocularZoom
l_6A04:
  LD A,(NightKey+$0001)
  XOR $FF
  CALL ToggleNight

; One frame of the 3D view: draw, keys, world, objects, enemies, HUD; loop
; until the view changes
;
; Calls in order: `$DB71`, the 3D frame (`$9882`), the play keys (`PlayKeys`
; `$6B3B`), `$B9F6`, the clipping marks (`ClearClipRow` `$6A9D`), `$BAAC`, the
; world (`$AD45`, `$AEA0`), `$BBF1`, `$BD98`, Bank3Step `$72A3` (bank 3
; DrawDebris / MoveAllDebris), CameraSinCosAgain `$BA40`, DrawRadar `$C05E`,
; DrawObjectsInOrder `$BF53`, CollisionPass `$C7BC` and DrawSightOverlay
; `$C4CD` (bank 0), `$988D`, the message timer (`$7D5D`), the weapon bars
; (`$7327`), the object table (`$C026`), `$6B1D`, the mission's goal hook
; (`CALL LoopHook` at `$6A66`, its operand patched by the mission load: Blast
; Em Mission `$EB60`; LoopHook `$6A9C` is a `RET` in the image) and `$7256`,
; until the view flag `$6A6D` is non-zero; then the next view's loop through
; `$6A99`.
;
; Witness: L1 410 (death, m2erbe, missions, play, play2).
PlayLoop:
  CALL PickupAnnounce
  CALL StartViewPass
  CALL PlayKeys
  CALL SetCamera
  CALL ClearClipRow
  CALL GroundDots
  CALL SegmentVisibility
  CALL SetupClipWindow
  CALL ActivateMissionObjects
  CALL TransformObjects
  CALL Bank3Step
  CALL CameraSinCosAgain
  CALL DrawRadar
  CALL DrawObjectsInOrder
  XOR A
  LD (PlayerStep+$0001),A
  LD (FirstFrameHook),A
  CALL CollisionPass
  CALL DrawSightOverlay
  LD A,$00
  CALL NoAction
  LD A,$01
  CALL NoAction
  LD A,$02
  CALL NoAction
  LD A,$03
  CALL NoAction

; PlayLoopTail
PlayLoopTail:
  CALL RequestViewBlit    ; the second half of the frame, also run alone after
                          ; a view change
  CALL MessageOnce
  CALL UpdateSlotBars
  CALL RunObjectHandlers
  CALL FlickerPlayer
  CALL LoopHook
  CALL FirstFrameHook
ViewChangeFlag:
  LD A,$00                ; LD A,n: n ($6A6D) non-zero ends the loop
  AND A
  JR Z,PlayLoop
  XOR A
  LD (MessageTimer+$0001),A
  LD (PickupAnnounce),A
  LD HL,BlinkLamp
  LD A,(HL)
  LD (StartMission+$0007),A
  LD A,$C9
  LD (HL),A
  LD (BlinkWarning),A
  LD (BoundaryCheck),A
  CALL PageBank6
  LD HL,l_BFEB+$0015
  LD (SkeetFire+$0037),HL

; NextView
;
; Used by the routines at DragonflyViewLoop, StatusLoop, BriefPage and
; DamageLoop.
NextView:
  XOR A
  LD (ViewChangeFlag+$0001),A
  LD (l_884C+$000B),A
  LD HL,l_C408+$0001
  PUSH HL

; LoopHook
;
; Used by the routine at PlayLoopTail.
LoopHook:
  RET                     ; a RET the menus patch ; clear the flag and return
                          ; into the loop $6A99 names (default the title menu
                          ; $C409)

; Fill the 32 bytes $90F1-$9110 with $FF
;
; The row of the back buffer `$90F1` (its line 75 + 16) set to `$FF` once a
; frame of every view loop, before the world is drawn. Witness: L1 3626 (death,
; m2erbe, missions, play, play2).
ClearClipRow:
  LD HL,BackBuffer+$0600
  LD D,H
  LD E,L
  INC DE
  LD (HL),$FF
  LD BC,$001F
  LDIR
  RET

; Fill 24 character rows of 6 bytes of the screen through ScreenRowFill
;
; A = 0, C = 2, D = 6, E = `$18`, then `JP $6D22`. Called from bank 6 `$C53F` /
; `$D521`. Witness: L1 41 (death, m2erbe, missions, play, play2).
FillPanelRows:
  LD A,$FF
  EX AF,AF'
  XOR A
  LD C,$02
  EXX
  LD D,$06
  LD E,$18
  JP ScreenRowFill

; The Dragonfly's flight view: the monitor frame from bank 7, the narrow blit,
; then the world and objects seen from the Dragonfly
;
; Entered only from LaunchDragonfly (`$C30F`, `LD HL,$6AB9` into NextView),
; after the camera `$B9F4` points at the Dragonfly's record; ScreenList node
; `$7572` names it, but no transition word leads there. Draws the monitor frame
; (`DrawBank7Picture` with DE = `$F9CD`), sets the blit to `$8A98`, then per
; frame `$9882`, `$B9F6`, `ClearClipRow`, `$BAAC`, `$AD45`, `$AEA0`, `$BBF1`,
; `$BD98`, `$BA40`, `$BF53`, `$C7BC`, `$C4CD`, `$988D`, `$C026`, `$7256` until
; `$6A6D`; then the 3D blit again and `NextView`.
;
; Witness: L1 1 (play).
DragonflyViewLoop:
  CALL PageBank0
  CALL PageShadowScreen
  XOR A
  LD (FirstFrameHook),A
  LD DE,MissionHeader+$1E08
  CALL DrawBank7Picture
  LD HL,ViewBlitNarrow
  LD (MenuJobs+$0007),HL
l_6ACF:
  CALL StartViewPass
  CALL SetCamera
  CALL ClearClipRow
  CALL GroundDots
  CALL SegmentVisibility
  CALL SetupClipWindow
  CALL ActivateMissionObjects
  CALL TransformObjects
  CALL CameraSinCosAgain
  CALL DrawObjectsInOrder
  CALL CollisionPass
  CALL DrawSightOverlay
  CALL RequestViewBlit
  CALL RunObjectHandlers
  CALL FirstFrameHook
  LD A,(ViewChangeFlag+$0001)
  AND A
  JR Z,l_6ACF
  XOR A
  LD (MessageTimer+$0001),A
  LD A,$C9
  LD (BlinkWarning),A
  CALL PageBank6
  LD HL,ViewBlitFront
  LD (MenuJobs+$0007),HL
  LD HL,l_BFEB+$0015
  LD (SkeetFire+$0037),HL
  JP NextView

; Toggle the low nibble of object 0's byte +7 from a random number while $68BD
; is below 16
;
; HL = `$75F7` (object 0, +7): if the byte is non-zero, XOR its low nibble with
; a random nibble (`$67D0` -> `$A779`). Runs while `$68BD` < 16 (the damage of
; the tank? known only from the code). Witness: L1 3601 (death, m2erbe,
; missions, play, play2).
FlickerPlayer:
  LD A,(GaugeRecords+$0012)
  CP $10
  RET NC
  LD HL,PlayerSpeed
  LD A,(HL)
  AND A
  RET Z
  LD C,A
  CALL ApiVector06
  AND $0F
  XOR C
  LD (HL),A
  RET

; Page bank 6, call its panel set-up $D521, page bank 0 back
;
; Witness: L1 27 (death, m2erbe, missions, play, play2).
PanelSetup:
  CALL PageBank6
  CALL PanelAttributes
  JP PageBank0

; The play keys: a new key code in $8979 jumps to its action
;
; Returns unless bit 1 of `$8978` is set and the code differs from the last
; (`$6B45`, the operand of `LD C,0`). E: `$843F` (the quit prompt), K and J:
; the selected weapon's aim pair (the `JP` targets `$6B55` and `$6B50`, patched
; by SelectWeapon from `$7B89` + 8 x type, words 0 and 1; `$6BB0` NoAction in
; the image), M: the status view (`$705A`), D: the damage board (`$6BC2`), 1-4:
; weapons (bank 6 `$C53F`), H: `$D52E`, N: `$87FC`, R: `$BA45`, B: `$CEA7`, Z:
; `$CEE5`, C: remembered in `$6B45`.
;
; Witness: L1 3602 (death, m2erbe, missions, play, play2).
PlayKeys:
  LD A,(KeyState)
  AND $02
  RET Z
  LD A,(KeyCode)
  LD C,$00
  CP C
  RET Z
  CP $45
  JP Z,QuitKey
  CP $4A
  JP Z,NoAction
  CP $4B
  JP Z,NoAction
  CP $4D
  JP Z,ScreenZero
  CP $44
  JP Z,SelectDamage
  CP $31
  JP Z,SelectWeapon
  CP $32
  JP Z,SelectWeapon
  CP $33
  JP Z,SelectWeapon
  CP $34
  JP Z,SelectWeapon
  CP $48
  JP Z,PlaceHelicarrier
  CP $4E
  JP Z,NightKey
  CP $52
  JP Z,RearViewOff
  CP $42
  JP Z,ToggleBinoculars
  CP $5A
  JP Z,CycleBinocularZoom
  CP $43
  RET NZ
  LD (PlayKeys+$000A),A
  RET

; The keys of the damage board (called only from DamageLoop $6CB9): B to the
; status view $6BC7, C back to the 3D view, D the damage board again
;
; Witness: L1 3 (play).
DamageKeys:
  LD A,(KeyState)
  AND $02
  RET Z
  LD A,(PlayKeys+$000A)
  LD C,A
  LD A,(KeyCode)
  CP C
  RET Z
  CP $42
  JR Z,l_6BBD
  CP $43
  JR Z,SelectPlay
  CP $44
  JR Z,SelectDamage

; A RET: the action of the keys with nothing to do
;
; Witness: L1 14403 (death, m2erbe, missions, play, play2).
NoAction:
  RET
; This entry point is used by the routine at DamageKeys.
SelectPlay:
  LD HL,StartMission

; SelectLoop
;
; Used by the routine at SelectDamage.
SelectLoop:
  LD (NextView+$0008),HL  ; HL = the loop to run next ($6A99), A remembered,
                          ; then the view flag set
  LD (PlayKeys+$000A),A
  JP SetViewFlag
; This entry point is used by the routine at DamageKeys.
l_6BBD:
  LD HL,StatusLoop
  JR SelectLoop

; The key D: HL = $6C93, the damage board's loop, then SelectLoop
;
; Witness: L1 1 (play).
SelectDamage:
  LD HL,DamageLoop
  JR SelectLoop

; The status view's loop: the panel through bank 7 and the status texts, no 3D
; frame
;
; Pages bank 6 for `$DBB6`, draws `DrawBank7Picture` DE = `$D325`, prints the
; help texts (`$6C8B`), sets the blit to `$DBBD`, then per frame the mission
; clock (`PrintClock` `$7E3A`), the world and objects and bank 6's `$DB15`,
; `$D3C9`, `$E5BE`, `$C0F7`, the keys (`StatusKeys` `$6C60`) until `$6A6D`.
;
; Witness: L1 10 (play, play2).
StatusLoop:
  CALL PageBank6
  CALL SetStatusBlit
  CALL PageShadowScreen
  LD DE,SpectreCode+$0001
  CALL DrawBank7Picture
  CALL PrintStatusHelp
  LD A,$4D
  LD (StatusKeys+$000A),A
  LD HL,PickupText+$0026
  LD (MenuJobs+$0007),HL
  LD A,$FF
  LD (MessageTimer+$000A),A
  LD (AwolState+$0002),A
  XOR A
  LD (PointerShown+$0001),A
  LD (PointerTick+$000A),A
  LD (FirstFrameHook),A
  LD (BriefPageOnce),A
  CALL PageBank6
  CALL StatusMapFrame
l_6BFF:
  CALL PrintClock
  CALL PageBank0
  CALL SetCamera
  CALL SegmentVisibility
  CALL ActivateMissionObjects
  CALL TransformObjects
  CALL CameraSinCosAgain
  CALL RunObjectHandlers
  CALL CollisionPass
  CALL PageBank6
  CALL StatusMap
  CALL StatusViewMessage
  CALL BlinkMarker
  CALL PrintStatusGrid
  CALL StatusKeys
  LD A,(ViewChangeFlag+$0001)
  AND A
  JR Z,l_6BFF
  XOR A
  LD (MessageTimer+$000A),A
  LD (PointerShown+$0001),A
  LD A,$3A
  LD (CopyPointer),A
  LD (PointerTick+$000A),A
  JP NextView

; The console's BRIEF page (node $7544, key B in the status view): the briefing
; text once ($6C56), then the clock and keys loop
;
; Witness: L1 1 (play).
BriefPage:
  CALL BriefPageOnce
l_6C47:
  CALL PrintClock
  CALL StatusKeys
  LD A,(ViewChangeFlag+$0001)
  AND A
  JR Z,l_6C47
  JP NextView

; A NOP patched to RET after the first call of $70B6; StatusLoop ($6BF6) puts
; the NOP back on each visit
;
; Witness: L1 1 (play).
BriefPageOnce:
  NOP
  CALL BriefPageText
  LD A,$C9
  LD (BriefPageOnce),A
  RET

; The keys of the status view: C to the 3D view, B and M to $704E / $705E, then
; the help texts
;
; Witness: L1 530 (play, play2).
StatusKeys:
  LD A,(KeyState)
  AND $02
  RET Z
  LD A,(KeyCode)
  CP $00
  LD (StatusKeys+$000A),A
  RET Z
  CP $43
  JP Z,ScreenZero
  CP $42
  JR Z,l_6C80
  CP $4D
  RET NZ
  CALL ScreenTwo
  JR l_6C83
l_6C80:
  CALL ScreenEight
l_6C83:
  LD HL,ScreenRowTable+$00B0
  LD A,$1A
  CALL InvertPanelA

; Print the help text $6550 with attribute $1A through $B7AE
;
; Witness: L1 10 (play, play2).
PrintStatusHelp:
  LD HL,ScreenRowTable+$0050
  LD A,$1A
  JP InvertPanelA

; The damage board's loop (key D): PicDamageBoard from bank 7 at $C000, the
; weapon icons and bars, then world and objects
;
; Witness: L1 1 (play).
DamageLoop:
  CALL PageShadowScreen
  LD A,$C9
  LD (MessageOnce),A
  LD (MessageTimer+$000A),A
  LD DE,l_BFEB+$0015
  CALL DrawBank7Picture
  CALL PageBank6
  CALL DrawDamagePanel
  CALL DrawSlotBarsLow
  CALL PageBank0Main
l_6CB0:
  CALL DrawSlotBars
  CALL CopyHudGlyphs+$0001
  CALL PageBank0
  CALL DamageKeys
  CALL SetCamera
  CALL SegmentVisibility
  CALL ActivateMissionObjects
  CALL TransformObjects
  CALL CameraSinCosAgain
  CALL RunObjectHandlers
  CALL CollisionPass
  CALL PageBank6
  CALL StatusViewMessage
  LD A,(ViewChangeFlag+$0001)
  AND A
  JR Z,l_6CB0
  XOR A
  LD (MessageTimer+$0001),A
  JP NextView

  ORG $CE68

; A development loader for "MISSHDR:0:" that nothing calls
;
; `$CE68`-`$CEA3`: IX = `$CE93`, DE = 17, LD-BYTES through `$86C1` with A =
; `$FF`, and the 10-byte name "MISSHDR:0:". No routine calls it; a leftover of
; the development.
DevMissionLoader:
  DEFB $00
TerrainType:
  DEFB $00,$DD,$21,$93,$CE,$11,$11,$00 ; TerrainCollision stores the terrain
  DEFB $3E,$FF,$37,$F3,$CD,$C1,$86,$06 ; type here, PlayerStep reads it (a byte
  DEFB $0A,$21,$FF,$FF,$2B,$7C,$B5,$20 ; of the dead loader reused)
  DEFB $FB,$10,$F6,$DD,$21,$C5,$DB,$11
  DEFB $00,$00,$3E,$FF,$37,$CD,$C1,$86
  DEFB $FB,$C9,$03,$4D,$49,$53,$53,$48
  DEFB $44,$52,$3A,$30,$3A,$00,$00,$00
  DEFB $00,$00,$00

  ORG $D52E

; Once (the RET / NOP gate $D52E), on the key H: call the Helicarrier, which
; then flies to the pad
;
; `$D52E` is `NOP` until it has run, then `RET` (`$D531` writes it; the mission
; load `$8598` clears it). Record 21 (`$7ADC`) gets type `$8C` at the pad
; `$7E89` / `$7E8C` (the block header's 12 bytes at `$DBF1` copied to `$7E82`).
;
; Witness: L1 2 (play).
PlaceHelicarrier:
  NOP
  LD A,$C9
  LD (PlaceHelicarrier),A ; writes the RET at $D52E
  XOR A
  LD (BlinkLamp),A
  LD IX,HelicarrierRecord
  PUSH IX
  CALL ApiVector05
  POP HL
  INC HL
  LD D,H
  LD E,L
  INC HL
  LD (l_C96D+$0006),HL
  LD A,$02
  LD (RegisterCollision+$0005),A
  LD A,$8C
  CALL ApiVector03
  CALL ApiVector04
  LD A,(PlayerHeading)
  INC DE
  INC DE
  INC DE
  PUSH DE
  CALL ApiVector14
  LD E,A
  LD D,$00
  AND A
  JP P,l_D568
  DEC D
l_D568:
  LD HL,(MissionParams+$0007)
  SRA D
  RR E
  SRA D
  RR E
  ADD HL,DE
  EX DE,HL
  POP HL
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  PUSH HL
  EX AF,AF'
  LD E,A
  LD D,$00
  AND A
  JP P,l_D584
  DEC D
l_D584:
  LD HL,(MissionParams+$000A)
  SRA D
  RR E
  SRA D
  RR E
  ADD HL,DE
  EX DE,HL
  POP HL
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  LD BC,$0008
  LD HL,(WorldVars+$0005)
  CALL AbsHL
  EX DE,HL
  LD HL,(MissionParams+$0007)
  CALL AbsHL
  AND A
  SBC HL,DE
  AND A
  SBC HL,BC
  RET NC
  LD HL,(WorldVars+$0008)
  CALL AbsHL
  EX DE,HL
  LD HL,(MissionParams+$000A)
  CALL AbsHL
  AND A
  SBC HL,DE
  AND A
  SBC HL,BC
  RET NC
  LD (IX+$31),$1A
  LD (IX+$32),$DB

; Copy the Helicarrier's state byte
;
; `$D5D7` = (IY+$31) (play2: 15 runs).
;
; Witness: L1 15 (play2).
CopyHelicarrierState:
  LD A,(IY+$31)
  LD (HelicarrierData+$0007),A
  RET

; The Helicarrier's data
;
; The Helicarrier's model and state bytes; `$D5D7` is CopyHelicarrierState's
; store.
HelicarrierData:
  DEFB $00,$C9,$D5,$00,$F7,$67,$20,$00
  DEFB $08,$01,$29,$A6,$40,$A6,$A6,$5F
  DEFB $F8,$59,$00,$A9,$A9,$61,$F8,$58
  DEFB $25,$A2,$41,$A2,$A2,$5E,$F8,$57
  DEFB $01,$A5,$A5,$60,$F8,$56,$26,$A7
  DEFB $42,$A6,$A6,$5D,$F8,$55,$02,$A7
  DEFB $A7,$5C,$F8,$54,$22,$A3,$43,$A2
  DEFB $A2,$5B,$F8,$53,$03,$A3,$A3,$5A
  DEFB $F8,$52,$FF,$02,$18,$24,$05,$00
  DEFB $08,$A4,$84,$80,$7C,$98,$88,$98
  DEFB $74,$6C,$70,$9C,$8C,$9C,$60,$58
  DEFB $64,$A0,$90,$A0,$54,$4C,$50,$A4
  DEFB $94,$0C,$08,$00,$08,$04,$01,$A4
  DEFB $84,$80,$94,$01,$08,$04,$01,$7C
  DEFB $98,$88,$78,$02,$08,$04,$01,$98
  DEFB $74,$6C,$88,$03,$08,$04,$01,$70
  DEFB $9C,$8C,$68,$04,$08,$04,$01,$9C
  DEFB $60,$58,$8C,$05,$08,$04,$01,$64
  DEFB $A0,$90,$5C,$06,$08,$04,$01,$A0
  DEFB $54,$4C,$90,$07,$08,$04,$01,$50
  DEFB $A4,$94,$48,$FF

  ORG $DA8C

; Bytes before the Helicarrier's collision handler: a small table, then a CPL
; loop over $6760
;
; `$DA8C`-`$DA9E` data; `$DA9F`: `LD HL,$6760` / `LD B,8` / CPL each byte / RET
; (no recording runs it).
HelicarrierTemplate:
  DEFB $08,$07,$03,$05,$60,$80,$68,$09
  DEFB $08,$04,$01,$6C,$70,$68,$64,$00
  DEFB $9F,$DA,$FF,$21,$60,$67,$06,$08
  DEFB $7E,$2F,$77,$23,$10,$FA,$C9

; The Helicarrier's collision handler: the tank drives into the parked
; Helicarrier
;
; Three branches on the hitter IY: +3 bit 7 clear (not the player's family) ->
; HitTest `$67DC`; else the goal flag `$68E8` set -> `$67EE` (mission
; complete); else ScreenSix `$7047` and `$7BF9` = `$CC94` (failure). There is
; no parked test.
;
; Witness: m1complete frame 21558, m4complete 21299, one run each, then `$67EE`
; (work/stage2/complete-NOTES.md).
HelicarrierHit:
  LD A,(IY+$03)
  AND $80
  JP Z,ApiVector10
  LD A,(GoalFlag)
  AND A
  JP NZ,ApiVector16
  CALL ScreenSix
  LD HL,l_CC56+$003E
  LD (FailReason),HL
  RET

; The arrival's turn over the pad: heading + 8 a pass until within 8 of +$31,
; then the descent
;
; +`$22` += 8; |+`$22` - +`$31`| (`$67D6`) below 8 makes HelicarrierDescent
; `$DADE` the step. Witness: m1complete 17109-17205 (11 runs).
HelicarrierTurn:
  LD A,(IX+$22)
  ADD A,$08
  LD (IX+$22),A
  SUB (IX+$31)
  CALL ApiVector08
  CP $08
  RET NC
  LD (IX+$18),$DE
  LD (IX+$19),$DA
  RET

; The Helicarrier's landing: down 8 a step to the pad, then parked
;
; The height goes 104, 96, ... 24 (one step a pass), then the handler `$6BB0`
; parks it. Witness: m1complete frames 17213-17311 (10 runs), m4complete
; 15510-15575 (10).
HelicarrierDescent:
  LD L,(IX+$05)
  LD H,(IX+$06)
  LD BC,$0008
  AND A
  SBC HL,BC
  LD (IX+$05),L
  LD (IX+$06),H
  AND A
  LD DE,$0020
  SBC HL,DE
  RET NC
  LD (IX+$18),$B0
  LD (IX+$19),$6B
  RET

; The Helicarrier's set-up
;
; Clears `$6760`-`$6763`, `$FF` to `$6764`-`$6767`, the handler +$18/+$19 =
; `$DB24` (play: 1 run).
;
; Witness: L1 1 (play).
HelicarrierInit:
  LD HL,FaceFlags+$0038
  LD B,$04
l_DB05:
  LD (HL),$00
  INC HL
  DJNZ l_DB05
  LD B,$04
l_DB0C:
  LD (HL),$FF
  INC HL
  DJNZ l_DB0C
  LD (IX+$18),$24

; The Helicarrier handler's high byte
;
; `LD (IX+$19),$DB` / `RET`, the handler's high byte.
;
; Witness: L1 1 (play).
SetHelicarrierHandler:
  LD (IX+$19),$DB
  RET

; Code whose address PlaceHelicarrier writes into +$31/+$32; no recording runs
; it
;
; `LD IY,$75F0` / `LD HL,$67A8` / `EXX` / `JR $DB2C` into HelicarrierWait with
; the player as the target. PlaceHelicarrier stores `$DB1A` when |pad| -
; |camera| is below 8 on both axes; whether anything jumps to it is SUSPECTED
; (docs/10-gameplay-logic.md 10.9).
HelicarrierCode:
  LD IY,ObjectTable
  LD HL,WorldVars+$0005
  EXX
  JR l_DB2C

; The Helicarrier waits for the player
;
; Flies the Helicarrier to the pad: IY = the pseudo-record `$7E65` (its X / Y
; at `$7E88` / `$7E8B` are the pad), TurnToward, MoveObject; when the
; Helicarrier itself (not the tank) is within 3 units of X >> 8 and Y >> 8 (768
; world units) of the pad on both axes, the arrival at `$DB61` (play: 27 runs;
; m1complete 16239-17099, 85 runs).
;
; Witness: L1 27 (play).
HelicarrierWait:
  LD IY,l_7E56+$000F
  LD HL,MissionParams+$0007
  EXX
; This entry point is used by the routine at HelicarrierCode.
l_DB2C:
  CALL TurnToward
  CALL ApiVector00
  EXX
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  INC HL
  PUSH HL
  EX DE,HL
  LD BC,$0003
  LD E,(IX+$24)
  LD D,(IX+$25)
  AND A
  SBC HL,DE
  CALL M,NegHL
  AND A
  SBC HL,BC
  POP HL
  RET NC
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD L,(IX+$27)
  LD H,(IX+$28)
  AND A
  SBC HL,DE
  CALL M,NegHL
  AND A
  SBC HL,BC
  RET NC
HelicarrierArrival:
  LD (IX+$18),$C4         ; the arrival over the pad: the record's handler
                          ; becomes HelicarrierTurn $DAC4 (m1complete 17099,
                          ; m4complete 15435)
  LD (IX+$19),$DA
  LD A,(IY+$22)
  CPL
  LD (IX+$31),A
  RET

; Announce the pickup once the goal is met
;
; A NOP / RET gate at `$DB71`. When `$68E8` (the goal flag) is set: `$DB77`
; writes `RET` at `$DB71` and prints "MISSION:COMPLETE:PROCEED:TO:PICKUP"
; (`$DB97`). Runs once per 3D frame.
;
; Witness: L1 3483 (death, m2erbe, missions, play, play2).
PickupAnnounce:
  NOP
  LD A,(GoalFlag)
  AND A
  RET Z
PickupMessage:
  LD A,$C9                ; writes RET at $DB71, the blit ViewBlitLow, prints
                          ; $DB97 (m1complete 16138, m4complete 14215)
  LD (PickupAnnounce),A
  LD HL,ViewBlitLow
  LD (MenuJobs+$0007),HL
  LD A,$FF
  EX AF,AF'
  LD A,$20
  LD BC,$0000
  EXX
  LD D,A
  LD E,$08
  CALL ScreenRowFill
  LD HL,PickupText
  JP PrintString

; The pickup text
;
; PrintString: `$07` codes and "MISSION:COMPLETE:PROCEED:TO:"; the word
; "PICKUP" from `$DBB6` on is taken as code by the walk (bank 6 CALL target
; `$DBB6` from `$6BCA`).
PickupText:
  DEFB $07,$22,$04,$4D,$49,$53,$53,$49
  DEFB $4F,$4E,$3A,$43,$4F,$4D,$50,$4C
  DEFB $45,$54,$45,$3A,$50,$52,$4F,$43
  DEFB $45,$45,$44,$3A,$54,$4F,$3A,$50
  DEFB $49,$43,$4B,$55,$50,$FF,$00,$00
  DEFB $00,$00,$00,$00,$00,$00

; The mission block: the header $DBC5-$DBFF, the vertices, segments, objects,
; templates, code and models (zeros in the image: side 2 loads it)
;
; LoadMissionBlock `$855B` loads the block here; every reader indexes from
; `$DBC5` (header fields `$DBC5-$DBE9`, docs/07-objects.md 7.2,
; src/res/missions/README.md). The part a reload restores ends at the header's
; word (`$FB3F` for Blast Em Mission); the rows `$FC00-$FF7F` above are the 3D
; engine's work rows.
MissionHeader:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$FC,$FC,$3F,$3F,$00
  DEFB $80,$00,$01,$3F,$80,$FC,$01,$3F
  DEFB $80,$FC,$01,$3F,$80,$FC,$01,$3F
  DEFB $80,$FC,$01,$3F,$80,$FC,$01,$3F
  DEFB $00,$FC,$00,$3F,$00,$FC,$00,$3F
  DEFB $80,$FC,$01,$3F,$80,$FC,$01,$3F
  DEFB $80,$FC,$01,$3F,$80,$FC,$01,$3F
  DEFB $80,$FC,$01,$00,$80,$00,$01,$FC
  DEFB $FC,$3F,$3F,$07,$05,$03,$0D,$40
  DEFB $41,$4D,$4D,$3A,$08,$27,$C5,$FF
  DEFB $07,$10,$03,$4D,$41,$4E,$55,$41
  DEFB $4C,$FF,$07,$10,$03,$3A,$41,$55
  DEFB $54,$4F,$3A,$FF,$07,$10,$03,$3A
  DEFB $4F,$46,$46,$3A,$3A,$FF,$07,$10
  DEFB $03,$0D,$40,$08,$F8,$FD,$3A,$08
  DEFB $FC,$B8,$FF,$00,$07,$10,$03,$08
  DEFB $F5,$CF,$FF,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$8F,$FE,$02,$04
  DEFB $00,$0E,$01,$04,$01,$00,$04,$08
  DEFB $0C,$FF

; l_FE8F
l_FE8F:
  LD HL,$000A
  LD (MissionHeader+$213B),HL
; This entry point is used by the routine at DrawBank7Picture.
  LD (MissionHeader+$213D),HL
  LD (MissionHeader+$223B),HL
  LD (MissionHeader+$2241),HL
  LD L,H
  LD (data_FEBB+$0045),HL
  LD (data_FEBB+$0047),HL
  LD (data_FEBB+$0049),HL
  LD (data_FEBB+$004B),HL
  LD HL,data_FEBB+$013B
  LD (MissionHeader+$223D),HL
  LD (MissionHeader+$213F),HL
  LD (MissionHeader+$223F),HL
  LD (MissionHeader+$2141),HL
  RET

; data_FEBB
data_FEBB:
  DEFB $02,$03,$00,$10,$80,$01,$02,$C0
  DEFB $FF,$00,$FF,$AB,$40,$0C,$08,$02
  DEFB $03,$44,$05,$00,$01,$88,$90,$8C
  DEFB $0C,$01,$00,$07,$03,$06,$88,$90
  DEFB $8C,$14,$01,$00,$07,$03,$09,$8C
  DEFB $90,$88,$FF,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$02,$04,$00
  DEFB $13,$01,$04,$07,$00,$04,$08,$0C
  DEFB $FF,$02,$04,$00,$13,$01,$04,$08
  DEFB $00,$04,$08,$0C,$FF,$02,$04,$00
  DEFB $10,$80,$01,$82,$03,$C0,$FF,$01
  DEFB $03,$82,$4B,$00,$81,$4A,$8B,$4C
  DEFB $8A,$8C,$44,$0C,$8B,$8C,$47,$02
  DEFB $81,$4E,$81,$8E,$45,$0E,$82,$8E
  DEFB $46,$FF,$02,$08,$00,$13,$02,$04
  DEFB $01,$00,$04,$08,$0C,$04,$00,$10
  DEFB $14,$18,$1C,$FF,$07,$78,$11,$54
  DEFB $41,$4E,$4B,$3A,$48,$49,$54,$FF
  DEFB $07,$78,$11,$43,$4F,$4C,$4C,$49
  DEFB $44,$45,$44,$FF,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00
