; --------------------------------------------------------------------------------------------------------------------
; driver.asm: the GS driver: the sounds the patched sites ask for, the level change, the card commands
;
; The game reaches every entry here through the stubs the installer put in Zynaps's memory ($FF1C-$FFD1, $B2F0, $A6AE,
; $B47F: src/disk/install.asm): each loads HL with an entry and calls CallDriver ($B466) or CallDriverFx ($B482),
; which page bank 1, call (HL) and page bank 0 back. CallDriverFx calls only in effects-only mode (EffectsOnly), so
; the entries reached through it are effects-only sounds.
;
; A sound is an FX number L, a note H and a channel C: PlayFx sends them as the firmware's #2E (select FX), #40 (note)
; and #80+C (play in channel C). Gate drops a sound while GateCountdown runs (the menu's EFFECTS TIMER sets its
; length) unless ZynapsState is $C0. Many sounds add 0-1 or 0-3 semitones from the R register.
;
; In effects-only mode on a card of 7 pages or more (CardPages) the start jingle and all 21 FX stay on the card from
; the first upload: the driver patches itself so that every FX number is one higher (the jingle keeps handle 1) and no
; later upload happens.
; --------------------------------------------------------------------------------------------------------------------

; Z set when Level is in the zero-ended list at HL; A = 0 at the end of the
; list (NZ)
;
; Used by the routine at BigEnemyHitSound.
LevelInList:
  LD A,(Level)
  LD E,A
l_C004:
  LD A,(HL)
  INC HL
  CP E
  RET Z
  OR A
  JR NZ,l_C004
  CP E
  RET

; the levels where BigEnemyHitSound plays FX 12 (7 and 11), zero-ended
Fx12Levels:
  DEFB $07,$0B,$00

; FX 18, note $3A, channel 3 (from the $9823 site, effects only)
ArenaBounceSound:
  LD HL,$3A12
  LD C,$03
  JP Gate

; the beeper request $B2F0's replacement: a sound chosen by where the object is
; in its path (DE) and the frames left (C)
;
; The installer's stub at $B2F0 enters here before Zynaps's own $9529, with DE
; = the object's path pointer (IY+$1D/+$1E, the next command of its path
; bytecode: Zynaps's RunPath $94CB), C = the frames its path command has left
; (IY+$1B) and B = the movement flags its caller gave PathOpAccelerate $9529 (C
; there). Path pointer $682C (path 2 + 6) with C = $0A: FX 16, note $3C; $68F9
; (path 23 + 5) with C = $12 or $685B (path 5 + 5) with C = $11: FX 20, note
; $28. Otherwise, with SATURNS on, SaturnSound; else PathSound. So a sound
; marks one moment of one path: a turn of a given enemy formation, not a kind
; of enemy. Each test returns Z when it played (or when nothing is to be
; played), NZ to go on.
ObjectSound:
  CALL Path682CSound
  RET Z
  CALL Path68F9Sound
  RET Z
  CALL Path685BSound
  RET Z
  LD A,(OptionSaturns)
  OR A
  JP NZ,SaturnSound

; by the path pointer DE: $6850 (path 4 + 4, or E = $EE) FX 19 note $28, $6846
; (path 3 + 4) FX 20 note $24, channel 3
PathSound:
  CALL Path6850Sound
  RET Z
  LD HL,$6846
  LD A,L
  XOR E
  RET NZ
  LD A,H
  XOR D
  RET NZ
  LD HL,$2414
  LD C,$03
  CALL Gate
  CP A
  RET

; FX 19, note $28, channel 3 when DE = $6850 or E = $EE
;
; Used by the routine at PathSound.
Path6850Sound:
  LD HL,$6850
  LD A,L
  XOR E
  JR Z,l_C04D
  LD A,E
  CP $EE
  RET NZ
l_C04D:
  LD A,H
  XOR D
  RET NZ
  LD HL,$2813
  LD C,$03
  JP Gate

; FX 20, note $28, channel 3 when DE = $685B and C = $11
;
; Used by the routine at ObjectSound.
Path685BSound:
  LD HL,$685B
  LD A,L
  XOR E
  RET NZ
  LD A,H
  XOR D
  RET NZ
  LD A,C
  CP $11
  JR Z,l_C074
  RET

; FX 20, note $28, channel 3 when DE = $68F9 and C = $12
;
; Used by the routine at ObjectSound.
Path68F9Sound:
  LD HL,$68F9
  LD A,L
  XOR E
  RET NZ
  LD A,H
  XOR D
  RET NZ
  LD A,C
  CP $12
  RET NZ
; This entry point is used by the routine at Path685BSound.
l_C074:
  LD HL,$2814             ; FX 20, note $28
  LD C,$03
  CALL Gate
  CP A
  RET

; FX 16, note $3C, channel 3 when DE = $682C and C = $0A
;
; Used by the routine at ObjectSound.
Path682CSound:
  LD HL,$682C
  LD A,L
  XOR E
  RET NZ
  LD A,H
  XOR D
  RET NZ
  LD A,C
  CP $0A
  RET NZ
  LD HL,$3C10
  LD C,$03
  CALL Gate
; This entry point is used by the routine at SaturnSound.
l_C093:
  CP A                    ; Z: played
  RET

; SATURNS on: path pointer $6820 (path 1's start) plays FX 21 (note $32, volume
; FxVolume / 4) when its object slot's B changed
;
; B is the movement flags the caller gave PathOpAccelerate $9529 (the $B2F0
; stub passes them). The slot (ObjectSlot from IY) has a counter in
; SlotCounters: while it runs, it is counted down and nothing plays; when B is
; the slot's last value nothing plays either. Otherwise the new value is kept,
; the counter set to 8 and FX 21 played in channel 3 with #41 (FX volume). In
; effects-only mode on a big card the FX number in the LD HL is patched to 22
; (LoadOncePatch2).
SaturnSound:
  LD HL,$6820
  LD A,L
  XOR E
  RET NZ
  LD A,H
  XOR D
  RET NZ
  PUSH BC
  LD HL,SlotCounters
  CALL ObjectSlot
  POP DE
  JR NC,l_C093
  LD A,(HL)
  OR A
  JR Z,l_C0AF
  DEC (HL)
  CP A
  RET
l_C0AF:
  LD HL,SlotValues
  ADD HL,BC
  LD A,(HL)
  CP D
  RET Z
  LD (HL),D
  LD HL,SlotCounters
  ADD HL,BC
  LD (HL),$08
SaturnFx:
  LD HL,$3215             ; FX 21, note $32 (22 after the load-once patch)
  LD A,L
  CALL SelectFx
  LD A,(FxVolume)
  RRCA
  RRCA
  AND $3F
  CALL SetFxVolume
  LD C,$03
  CALL Gate
  CP A
  RET

; the object at IY gone: its slot's last value cleared (from the $9954 site
; through $B47F)
ClearSlot:
  LD HL,SlotValues
  CALL ObjectSlot
  RET NC
  LD (HL),$00
  RET

; IY's object slot: (IY - $F398) / $2C, 0-6 with carry; no carry for an IY
; outside the 7 slots
;
; On carry HL = HL + the slot (the callers point HL at SlotValues or
; SlotCounters first).
ObjectSlot:
  LD E,IYL
  LD D,IYH
  EX DE,HL
  XOR A
  AND A
  LD BC,$F398
  SBC HL,BC
  JR C,l_C101
  LD BC,$002C
l_C0F0:
  SBC HL,BC
  JR C,l_C0FC
  INC A
  CP $07
  JP NZ,l_C0F0
  JR l_C101
l_C0FC:
  LD C,A
  EX DE,HL
  ADD HL,BC
  SCF
  RET
l_C101:
  AND A
  RET

; the last B each object slot played FX 21 with
SlotValues:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; each slot's countdown before FX 21 may play again
SlotCounters:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; from the $A0BA site (effects only): on levels 7 and 11 FX 12, else FX 13 or
; 14; channel 0
BigEnemyHitSound:
  LD HL,Fx12Levels
  CALL LevelInList
  JR Z,l_C130
  LD HL,$310D
  LD A,R
  LD C,A
  AND $01
  ADD A,L
  LD L,A
  LD A,C
  RLCA
  AND $03
  ADD A,H
  LD H,A
  LD C,$00
  JP Gate
l_C130:
  LD HL,$2C0C             ; levels 7, 11: FX 12, note $2C + 0-1
  LD A,R
  AND $01
  ADD A,H
  LD H,A
  LD C,$00
  JP Gate

; FX 17, channel 0: note $3C on level 4, else $28 (from the $9856 site, effects
; only)
DiveSound:
  LD A,(Level)
  CP $04
  LD C,$00
  JR Z,l_C14D
  LD HL,$2811
  JP Gate
l_C14D:
  LD HL,$3C11
  JP Gate

; from the $A0D5 site: music mode as ShipExplodesSound; effects only all four
; channels at once
;
; Effects only: FX 11 note $28 + 0-3 in channel 0, FX 8 note $2D in channel 1,
; FX 7 note $2C in channel 2, FX 11 one note higher in channel 3.
BigEnemyDestroyedSound:
  LD A,(EffectsOnly)
  OR A
  JR Z,ShipExplodesSound
  LD HL,$280B
  LD A,R
  AND $03
  ADD A,H
  LD H,A
  LD C,$00
  PUSH HL
  CALL Gate
  LD HL,$2D08
  LD C,$01
  CALL Gate
  LD HL,$2C07
  LD C,$02
  CALL Gate
  POP HL
  INC H
  LD C,$03
  JP Gate

; FX 15, note $2D + 0-1, channel 3, when D bit 7 is clear (from the $95E7 site,
; effects only)
SceneryBounceSound:
  LD A,D
  AND $80
  RET NZ
  LD HL,$2D0F
  LD A,R
  AND $01
  ADD A,H
  LD H,A
  LD C,$03
  JP Gate

; FX 4, note $30 + 0-1, channel 1 (beeper sound 1)
EnemyFireSound:
  LD HL,$3004
  LD A,R
  AND $01
  ADD A,H
  LD H,A
  JP GateChannel1

; FX 4, note $2A + 0-1 (the $9CA6 site)
PlasmaLaunchSound:
  LD HL,$2A04
  LD A,R
  AND $01
  ADD A,H
  LD H,A
; This entry point is used by the routines at MissileLaunchSound,
; PodAppearsSound and PlasmaBounceSound.
Channel1Or2:
  LD A,(EffectsOnly)            ; channel 1 in music mode, 2 in effects only
  OR A
  JP Z,GateChannel1
  LD C,$02
  JP Gate

; FX 5, note $32 + 0-1 (the $9CFA / $9D1F sites)
MissileLaunchSound:
  LD HL,$3205
  LD A,R
  AND $01
  ADD A,H
  LD H,A
  JR Channel1Or2

; FX 7, note $2C + 0-3: channel 1 in music mode, 0 in effects only (the $9FBE /
; $A034 sites)
ExplosionSound:
  LD HL,$2C07
  LD A,R
  AND $03
  ADD A,H
  LD H,A
  LD A,(EffectsOnly)
  OR A
  JR Z,GateChannel1
  LD C,$00
  JR Gate

; FX 8, note $2D, not gated: channel 1 in music mode, 0 in effects only (the
; $9B51 site)
;
; Used by the routine at BigEnemyDestroyedSound.
ShipExplodesSound:
  LD HL,$2D08
  LD A,(EffectsOnly)
  OR A
  LD C,$01
  JR Z,PlayFxFrom
  LD C,$00
  JR PlayFxFrom

; beeper sound 2: FX 10 note $32 if Player1LaserLevel >= 2, else FX 9 note $34;
; + 0-1
;
; SHOOTING (OptionShooting): bit 0 set (DISABLED) plays nothing. In music mode
; with bit 1 clear (NORMAL) the shot goes through PlayFxDefault in channel 1
; (#45 1, then #39: the firmware's own channel choice), else (CHANNEL, or
; effects only) Gate and channel 1.
ShotSound:
  LD A,(Player1LaserLevel)
  CP $02
  JR C,l_C1EB
  LD HL,$320A
  JR l_C1EE
l_C1EB:
  LD HL,$3409
l_C1EE:
  LD A,(OptionShooting)
  RRCA
  RET C
  LD E,A
  LD A,R
  AND $01
  ADD A,H
  LD H,A
  LD A,(EffectsOnly)
  OR A
  JR NZ,GateChannel1
  LD A,E
  RRCA
  JR C,GateChannel1
  LD B,$01
  JR PlayFxDefault

; beeper sound 4: FX 1, note $26 (channel 1, or 2 in effects only)
PodAppearsSound:
  LD HL,$2601
  JR Channel1Or2

; beeper sound 6: FX 3, note $32, channel 1
WeaponOnSound:
  LD HL,$3203
  JR GateChannel1

; beeper sound 3: FX 6, note $3C + 0-1 (channel 1, or 2 in effects only)
PlasmaBounceSound:
  LD HL,$3C06
  LD A,R
  AND $01
  ADD A,H
  LD H,A
  JR Channel1Or2

; beeper sound 5: FX 2, note $32 + 0-3, channel 1
NextWeaponSound:
  LD HL,$3202
  LD A,R
  AND $03
  ADD A,H
  LD H,A
  JR GateChannel1

; Gate with channel 1
;
; Used by the routines at EnemyFireSound, PlasmaLaunchSound, ExplosionSound,
; ShotSound, WeaponOnSound and NextWeaponSound.
GateChannel1:
  LD C,$01

; a sound through the gate: dropped while GateCountdown runs, unless
; ZynapsState is $C0
;
; When the sound passes, GateCountdown is set to the EFFECTS TIMER value (the
; LD A operand, written by the menu) and the sound plays (PlayFx).
Gate:
  LD A,(ZynapsState)
  CP $C0
  JR Z,PlayFxFrom
  LD A,(GateCountdown)
  OR A
  RET NZ
  LD A,$00                ; the EFFECTS TIMER (the menu writes the operand)
  LD (GateCountdown),A
; This entry point is used by the routine at ShipExplodesSound.
PlayFxFrom:
  NOP                     ; a NOP: the load-once patch makes it INC L (FX
                          ; number + 1)

; FX L at note H in channel C: #2E L, #40 H, #80+C with data L
PlayFx:
  LD A,L
  CALL SelectFx
  LD A,H
  CALL SetNote
  LD A,L
  OUT ($B3),A
  LD A,$80
  OR C
  OUT ($BB),A
  JP WaitCommand

; the same through the gate, played with the firmware's channel choice: #45 B
; (default volume), #39 L
;
; Used by the routine at ShotSound.
PlayFxDefault:
  LD A,(ZynapsState)
  CP $C0
  JR Z,PlayFxDefaultFrom
  LD A,(GateCountdown)
  OR A
  RET NZ
  LD A,$00
  LD (GateCountdown),A
PlayFxDefaultFrom:
  NOP                     ; a NOP: INC L after the load-once patch
  LD A,L
  CALL SelectFx
  LD A,H
  CALL SetNote
  LD A,B
  OUT ($B3),A
  LD A,$45
  OUT ($BB),A
  CALL WaitCommand
  LD A,L
  OUT ($B3),A
  LD A,$39
  OUT ($BB),A
  JP WaitCommand

; #32 (stop the module), then #3A with $FF (stop every FX): no caller
StopAll:
  LD A,$32
  OUT ($BB),A
  CALL WaitCommand
  LD A,$FF
  OUT ($B3),A
  LD A,$3A
  OUT ($BB),A
  JP WaitCommand

; FX L, note H, #48 with E, D, B: no caller
SetLoopStart:
  LD A,L
  CALL SelectFx
  LD A,H
  CALL SetNote
  LD A,E
  OUT ($B3),A
  LD A,$48
  OUT ($BB),A
  CALL WaitCommand
  LD A,D
  OUT ($B3),A
  CALL WaitData
  LD A,B
  OUT ($B3),A
  JP WaitData

; #49 with E, D, B, then #41 H and #80+C with L: no caller (follows
; SetLoopStart)
SetLoopEnd:
  LD A,E
  OUT ($B3),A
  LD A,$49
  OUT ($BB),A
  CALL WaitCommand
  LD A,D
  OUT ($B3),A
  CALL WaitData
  LD A,B
  OUT ($B3),A
  CALL WaitData
  LD A,H
  CALL SetFxVolume
  LD A,L
  OUT ($B3),A
  LD A,$80
  OR C
  OUT ($BB),A
  JR WaitCommand

; A to the data register, #2E (select FX)
;
; Used by the routines at SaturnSound, PlayFx, PlayFxDefault and SetLoopStart.
SelectFx:
  OUT ($B3),A
  LD A,$2E
  OUT ($BB),A
  JR WaitCommand

; A, #40 (FX note)
;
; Used by the routines at PlayFx, PlayFxDefault and SetLoopStart.
SetNote:
  OUT ($B3),A
  LD A,$40
  OUT ($BB),A
  JR WaitCommand

; A, #41 (FX volume)
;
; Used by the routines at SaturnSound and SetLoopEnd.
SetFxVolume:
  OUT ($B3),A
  LD A,$41
  OUT ($BB),A

; until the card has taken the command (status bit 0 clear)
;
; Used by the routines at PlayFx, PlayFxDefault, StopAll, SetLoopStart,
; SetLoopEnd, SelectFx, SetNote, StopModule, WarmReset, CardPages,
; SendFxVolume, PlayModule and FadeModule.
WaitCommand:
  IN A,($BB)
  RRCA
  RET NC
  JR WaitCommand

; until the card has taken the data byte (status bit 7 clear)
;
; Used by the routines at SetLoopStart and SetLoopEnd.
WaitData:
  IN A,($BB)
  RLCA
  RET NC
  JR WaitData

; data 1, #32: stop the module
;
; Used by the routine at LevelChange.
StopModule:
  LD A,$01
  OUT ($B3),A
  LD A,$32
  OUT ($BB),A
  JR WaitCommand

; the command $F3: the card emptied (the load-once patch makes this a RET)
;
; Used by the routines at CardPages and LevelChange.
WarmReset:
  LD A,$F3
  OUT ($BB),A
  JR WaitCommand

; #23: the card's 32 K pages; 7 or more in effects-only mode: the command $F3
; once, then the load-once patches
;
; The patches: RET at WarmReset and here, INC L ($2C) at PlayFxFrom and $C260
; (LoadOncePatch2) and 22 as SaturnSound's FX. From then on LevelChange uploads
; nothing.
CardPages:
  LD A,$23
  OUT ($BB),A
  CALL WaitCommand
  IN A,($B3)
  CP $07
  RET C
  LD A,(EffectsOnly)
  OR A
  RET Z
  CALL WarmReset
  LD A,$C9
  LD (WarmReset),A
  LD (CardPages),A
  LD A,$2C
  LD (PlayFxFrom),A
  JP LoadOncePatch2

; data_C327
data_C327:
  DEFB $C9

; #2B with FxVolume
;
; Used by the routine at LevelChange.
SendFxVolume:
  LD A,(FxVolume)
  OUT ($B3),A
  LD A,$2B
  OUT ($BB),A
  JR WaitCommand

; #2A with ModuleVolume (module volume), then data 1 and #31 (play the module)
;
; The LD A,(ModuleVolume) before the #31 has no effect.
PlayModule:
  LD A,(ModuleVolume)
  OUT ($B3),A
  LD A,$2A
  OUT ($BB),A
  CALL WaitCommand
  LD A,$01
  OUT ($B3),A
  LD A,(ModuleVolume)
  LD A,$31
  OUT ($BB),A
  JR WaitCommand

; Zynaps's wait between rounds ($A6AE stub): a delay, or in music mode the
; module faded out
RoundWait:
  LD A,(EffectsOnly)
  OR A
  JR NZ,Delay
  JP RoundWaitMusic

; #2A from A down to 0, a delay of 3000 loop steps between the steps
;
; Used by the routine at RoundWaitMusic.
FadeModule:
  LD E,A
l_C356:
  LD A,E
  OR A
  RET Z
  DEC E
  OUT ($B3),A
  LD A,$2A
  OUT ($BB),A
  CALL WaitCommand
  LD HL,$0BB8
l_C366:
  DEC HL
  LD A,L
  OR H
  JR NZ,l_C366
  JR l_C356

; a fixed delay of 65536 loop steps
;
; Used by the routines at RoundWait and RoundWaitMusic.
Delay:
  LD HL,$0000
l_C370:
  DEC HL
  LD A,L
  OR H
  RET Z
  JR l_C370

; BC bytes exchanged between HL and DE
;
; Used by the routines at SwapSavedArea and SwapLoader.
SwapBytes:
  PUSH BC
  LD A,(DE)
  LD B,(HL)
  LD (HL),A
  LD A,B
  LD (DE),A
  INC HL
  INC DE
  POP BC
  DEC BC
  LD A,B
  OR C
  JR NZ,SwapBytes
  RET

; the round start: when NextLevel is not Level, the sound of the next level,
; the start or the title
;
; From the $FF1C (round start) and $FF26 (game start, LoadKind = 1) stubs and
; the title ($AA33, LoadKind = 2). Interrupts go to IM 1 with I = $3F,
; StackArea is kept in bank 1 and the stack moved to LoaderStack; SwapSavedArea
; and SwapLoader put the loader at $61A8. CardPages and WarmReset (#23, the
; command $F3) start each load.
;
; LoadKind 1 (the game start): StopModule if the load-once patch is in, then
; LoaderStartFx (the jingle); with the patch in its CALL is turned into
; LoaderPlayStartFx. LoadKind 2 (the title, entered at $C38F past the level
; test): LoaderModule (it takes module 13 for LoadKind 2), PlayModule, Level =
; 0; with the patch in, LoaderModule becomes a RET. LoadKind 0 (a new level):
; Level = NextLevel, in music mode LoaderModule, then LoaderFx and SendFxVolume
; (with the patch in, LoaderFx becomes a RET), in music mode PlayModule.
;
; Everything is swapped back, the stack and StackArea restored and IM 2 set
; again.
LevelChange:
  DI
  LD A,(NextLevel)
  LD B,A
  LD A,(Level)
  CP B
  RET Z
  LD A,I
  PUSH AF
  PUSH IX
  IM 1
  LD A,$3F
  LD I,A
  LD (RestoreStack+1),SP  ; the stack pointer into the LD SP at RestoreStack
  LD HL,StackArea
  LD DE,StackAreaCopy
  LD BC,$0200
  LDIR
  LD SP,LoaderStack
  CALL SwapSavedArea
  CALL SwapLoader
  CALL CardPages
  CALL WarmReset
  LD A,(LoadKind)
  OR A
  JR Z,LoadLevel
  CP $02
  JR Z,LoadTitle
  LD A,(CardPages)
  CP $C9
  CALL Z,StopModule
PlayStartFx:
  CALL LoaderStartFx              ; the jingle: LoaderStartFx, or LoaderPlayStartFx
                          ; after the patch
  LD A,(CardPages)
  CP $C9
  JR NZ,LevelChangeDone
  LD HL,LoaderPlayStartFx
  LD (PlayStartFx+1),HL
  JR LevelChangeDone
LoadTitle:
  CALL LoaderModule              ; the title module
  CALL PlayModule
  XOR A
  LD (Level),A
  LD A,(CardPages)
  CP $C9
  JR NZ,LevelChangeDone
  LD (LoaderModule),A
  JR LevelChangeDone
LoadLevel:
  LD A,(NextLevel)            ; a new level
  LD (Level),A
  LD A,(EffectsOnly)
  OR A
  CALL Z,LoaderModule
  CALL LoaderFx
  CALL SendFxVolume
  LD A,(CardPages)
  CP $C9
  JR NZ,l_C40F
  LD (LoaderFx),A
l_C40F:
  LD A,(EffectsOnly)
  OR A
  CALL Z,PlayModule
LevelChangeDone:
  CALL SwapLoader         ; back: the loader and SavedArea swapped out again
  CALL SwapSavedArea
RestoreStack:
  LD SP,$0000             ; Zynaps's stack (the operand written at $C39A)
  LD DE,StackArea
  LD HL,StackAreaCopy
  LD BC,$0200
  LDIR
  POP IX
  POP AF
  LD I,A
  IM 2
  RET

; SavedArea <-> SavedAreaCopy
;
; Used by the routine at LevelChange.
SwapSavedArea:
  LD HL,SavedAreaCopy
  LD DE,SavedArea
  LD BC,$023B
  JP SwapBytes

; the 1049 bytes at $61A8 <-> LoaderCopy
;
; Used by the routine at LevelChange.
SwapLoader:
  LD HL,LoaderStartFx
  LD DE,LoaderCopy
  LD BC,$0419
  JP SwapBytes

; the level loader (src/disk/loader.ann), assembled for $61A8
LoaderCopy:
  INCBIN "build/disk/loader.bin",$0000,1049

; the load-once patch's tail: INC L at PlayFxDefaultFrom and FX 22 in
; SaturnSound
;
; Used by the routine at CardPages.
LoadOncePatch2:
  LD (PlayFxDefaultFrom),A
  LD A,$16
  LD (SaturnFx+1),A
  RET

; music mode: the module faded out (from ModuleVolume) when RoundWaitFrames is
; 2 and the level select is off, else Delay
;
; Used by the routine at RoundWait.
RoundWaitMusic:
  LD A,(RoundWaitFrames)
  CP $02
  JP NZ,Delay
  LD A,(LevelSelectCode)
  CP $06
  JP Z,Delay
  LD A,(ModuleVolume)
  JP FadeModule

; zeros
Spare:
  DEFS $2B

; the options menu (src/disk/menu.ann): it runs here, at $6D60 in Trush block
; 4, before the installer
MenuCopy:
  INCBIN "build/disk/menu.bin",$0000,1696
