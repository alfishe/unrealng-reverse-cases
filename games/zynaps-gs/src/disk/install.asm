; install.asm: the installer at the head of Trush block 4 ($61A8-$64B2), with the stubs and trampolines it copies
; into Zynaps's memory. docs/03-build-and-load.md 3.4-3.5, docs/09-sound.md 9.2 and 9.4.
;
; The boot's JP Install comes here after the options menu. The installer:
;   1. fills in the sector and track of the loader's records (FillRecords);
;   2. copies the stubs over parts of Zynaps the GS version does not use (the beeper crackle at $AA28, the title
;      tune's player at $B446 and its data at $FF1C, the wait routine $A6AE, the beeper request $B2F0) and puts the
;      title stub at $5B00;
;   3. copies the GS driver file ($64B3, 4 K) to bank 1 $C000, and the $5B00-$5D3A area to bank 1 $D190 (the copy
;      the driver swaps back after a level load);
;   4. points 25 places in Zynaps at the stubs (the patch list below);
;   5. moves Zynaps's $5C00-$73FF (kept at $C800-$DFFF in the block, because the installer, the driver file and
;      the menu lie at $61A8-$73FF) down to $5C00, clears $C800-$DFFF and starts Zynaps at $B200 (Mover).
;
; Each stub runs at its own address (DISP); this file assembles them in the order the block carries them.
;
;   sjasmplus src/disk/install.asm   ->  build/disk/install.bin (779 bytes, $61A8-$64B2)

  DEVICE ZXSPECTRUM128

; the GS driver's entries (bank 1, src/disk/driver.ann)
ArenaBounceSound       EQU $C010
ObjectSound     EQU $C018
PathSound       EQU $C02B
ClearSlot       EQU $C0D5
BigEnemyHitSound       EQU $C113
DiveSound       EQU $C13E
BigEnemyDestroyedSound       EQU $C153
SceneryBounceSound       EQU $C17F
EnemyFireSound       EQU $C191
PlasmaLaunchSound       EQU $C19D
MissileLaunchSound       EQU $C1B2
ExplosionSound       EQU $C1BD
ShipExplodesSound       EQU $C1D0
ShotSound       EQU $C1DF
PodAppearsSound       EQU $C208
WeaponOnSound       EQU $C20D
PlasmaBounceSound       EQU $C212
NextWeaponSound       EQU $C21D
RoundWait       EQU $C34C
LevelChange     EQU $C385
LoadSound       EQU $C38F  ; LevelChange past its "same level" test

; Zynaps (the routines and variables the stubs go back to; the names of src/game/game.ann)
LevelOrder      EQU $8003  ; the order of the 12 levels; SetLevelStart reads it (LD B,(HL) at $B073)
RasterLines     EQU $80B0  ; the menu raster's line count, written by LevelStart at $AF51
LockMask        EQU $80E2  ; the homing lock's collision bit; the big enemy's death zeroes it at $A0D5
ClearScreen     EQU $858B  ; fade out, clear the screen
ClearHitGrid    EQU $91C6  ; RoundSetup's first call ($B03E)
PathOpAccelerate EQU $9529 ; path command 0; the two path movers $9694, $9747 call it (through $B2F0 here)
DirectionTo     EQU $989F  ; the direction to the player; PathOpAimPlayer calls it at $969D
KillPlayer      EQU $9B5F  ; the ship destroyed, after the Invulnerable test at $9B4C
PlaceAtPlayer   EQU $9CB0  ; a new homing missile or seeker at the ship ($9CFA, $9D1F)
StartExplosionQuiet EQU $A2A5 ; StartExplosion past its beeper noise set-up ($A293-$A2A4)
PlayInterruptPass EQU $AA49 ; the play interrupt after the beeper crackle's patterns ($AA28-$AA48)
CreditsPage     EQU $B095  ; the title page with the scores (the 48K plays the title tune here)
HiScoreHold     EQU $B0EE  ; HiScorePage's 500-frame wait for fire
MainLoop        EQU $B200  ; the game's top loop (the 48K's GameEntry goes to Start $B6FF first)
MainLoopTitle   EQU $B203  ; the title pages in turn
MainLoopGame    EQU $B20C  ; fire: a new game
; the patch sites: an operand (the address + 1 of the instruction) or the instruction (CALL written over it)
SiteTitleLoop   EQU $B209  ; JP NC,MainLoopTitle (the GS image has JP for the 48K's JR)
SiteTitleTune   EQU $B0BF  ; CALL $B446: the 48K's title tune (with the key test)
SiteTitle       EQU $B203  ; CALL CreditsPage
SiteNextLevel   EQU $B075  ; LD DE,8 after LD B,(HL) / INC B: the next level in B
SiteRoundStart  EQU $B03E  ; CALL ClearHitGrid
SiteGameStart   EQU $AF51  ; LD ($80B0),A: "PREPARE FOR COMBAT"
SiteShipHitExplode EQU $9BE6 ; CALL $A293 (the GS image already has CALL StartExplosionQuiet)
SiteShipHit     EQU $9B51  ; JP KillPlayer
SiteExplodeA    EQU $9FBE  ; CALL $A293
SiteExplodeB    EQU $A034  ; CALL $A293 (the GS image: CALL StartExplosionQuiet)
SiteSound1      EQU $A1C4  ; CALL $B2F0 with A = 1 (beeper sound 1)
SiteObject12    EQU $9CA6  ; LD (IX+$12),A
SiteObjectA     EQU $9CFA  ; CALL PlaceAtPlayer
SiteObjectB     EQU $9D1F  ; CALL PlaceAtPlayer
SiteSound3      EQU $9EA5  ; CALL $B2F0, A = 3
SiteSound2      EQU $9C77  ; CALL $B2F0, A = 2
SiteSound4      EQU $A31D  ; CALL $B2F0, A = 4
SiteSound5      EQU $A226  ; CALL $B2F0, A = 5
SiteSound6      EQU $A21F  ; CALL $B2F0, A = 6
Site95E7        EQU $95E7  ; LD HL,0
SiteA0BA        EQU $A0BA  ; DEC (IY+$0D)
SiteA0D5        EQU $A0D5  ; LD ($80E2),A
Site9823        EQU $9823  ; LD HL,0
SiteSpriteA     EQU $9694  ; CALL PathOpAccelerate
SiteSpriteB     EQU $9747  ; CALL PathOpAccelerate
Site9856        EQU $9856  ; LD (IY+$1B),1
Site969D        EQU $969D  ; CALL DirectionTo
Site9954        EQU $9954  ; LD L,(IY+0)
SiteA0BD        EQU $A0BD  ; the GS image's CALL NZ,0 where the 48K set the beeper crackle's three patterns
Site9859        EQU $9859  ; the last byte of the 4-byte LD (IY+$1B),1 that the 3-byte CALL leaves
SiteSound0      EQU $ABF1  ; CALL $B2F0 with A = 0 (beeper sound 0): three NOPs

; memory
RecordsInBlock  EQU $6B0B  ; the loader's FxRecords inside the driver file in this block (bank 1 $C658, loader $63B6)
TRDOS_SECTOR    EQU $5CF4  ; TR-DOS: the sector and track after the last read (here: past Trush block 4)
DriverFile      EQU $64B3  ; the GS driver file in this block (src/disk/driver.ann)
SavedArea       EQU $5B00  ; $5B00-$5D3A: kept in bank 1 for the driver's level loads
SavedAreaCopy   EQU $D190
ZynapsLow       EQU $C800  ; Zynaps's $5C00-$73FF as the block carries it
PAGE_ROM48      EQU $10    ; port $7FFD values (the 48 ROM): bank 0, bank 1, bank 7
PAGE_BANK1      EQU $11
PAGE_BANK7      EQU $17

  ORG $61A8
; --------------------------------------------------------------------------------------------------------------------
; Install: Trush block 4 has unpacked $61A8-$FFFF and the menu has run; the boot jumps here.
Install:
  DI
  CALL FillRecords
  LD SP,$5C00
; the beeper crackle's code at $AA28: 33 bytes cleared, the gate stub over its first 32
  LD HL,GateStubAt
  PUSH HL
  LD D,H
  LD E,L
  INC DE
  LD BC,32
  LD (HL),0
  LDIR
  POP DE
  LD HL,GateStub
  LD C,32
  LDIR
; the other stubs: each copy takes the stub's bytes (and for two of them the next byte, of no use there)
  LD HL,TitleStub
  LD DE,TitleStubAt
  LD C,32
  LDIR
  LD HL,ObjectSoundStub
  LD DE,ObjectSoundStubAt
  LD C,28
  LDIR
  LD HL,WaitStub
  LD DE,WaitStubAt
  LD C,8
  LDIR
  LD HL,HookStubs
  LD DE,HookStubsAt
  LD C,HookStubsEnd-HookStubs
  LDIR
  LD DE,TrampolinesAt     ; HL is at Trampolines: they follow the hook stubs
  LD C,TrampolinesEnd-Trampolines
  LDIR
; the driver file to bank 1 $C000 (4 K: its $F4D bytes and $B3 of Zynaps after them), and SavedArea's copy
  LD BC,$7FFD
  LD A,PAGE_BANK1
  OUT (C),A
  LD DE,$C000             ; HL is at DriverFile
  LD BC,$1000
  LDIR
  LD HL,SavedArea
  LD DE,SavedAreaCopy
  LD BC,$023B
  LDIR
  LD BC,$7FFD
  LD A,PAGE_ROM48
  OUT (C),A
; the patches: the operands of 25 CALLs and JPs in Zynaps (docs/09-sound.md 9.4)
  LD HL,TitleStubAt
  LD (SiteTitleLoop+1),HL ; the title loop's JP NC: the title stub (the loading screen, then the attract loop)
  LD HL,KeyWait
  LD (SiteTitleTune+1),HL ; the title page: a key wait in place of the 48K's title tune
  LD HL,TitleEntry
  LD (SiteTitle+1),HL     ; the title page: the title module first
  LD HL,NextLevelHook
  LD (SiteNextLevel+1),HL ; the next level to NextLevel (LD DE,8 made CALL below)
  LD HL,RoundStartHook
  LD (SiteRoundStart+1),HL ; the round start: the level's sound
  LD HL,GameStartHook
  LD (SiteGameStart+1),HL ; "PREPARE FOR COMBAT": the jingle
  LD HL,StartExplosionQuiet
  LD (SiteShipHitExplode+1),HL ; (the GS image has it already)
  LD HL,ShipHitHook
  LD (SiteShipHit+1),HL   ; the ship hit: FX 8
  LD HL,ExplodeHook
  LD (SiteExplodeA+1),HL
  LD (SiteExplodeB+1),HL
  LD HL,EnemyFireHook
  LD (SiteSound1+1),HL
  LD HL,PlasmaLaunchHook
  LD (SiteObject12+1),HL
  LD HL,MissileLaunchHook
  LD (SiteObjectA+1),HL
  LD (SiteObjectB+1),HL
  LD HL,PlasmaBounceHook
  LD (SiteSound3+1),HL
  LD HL,ShotHook
  LD (SiteSound2+1),HL
  LD HL,PodAppearsHook
  LD (SiteSound4+1),HL
  LD HL,NextWeaponHook
  LD (SiteSound5+1),HL
  LD HL,WeaponOnHook
  LD (SiteSound6+1),HL
  LD HL,SceneryBounceHook
  LD (Site95E7+1),HL
  LD HL,BigEnemyHitHook
  LD (SiteA0BA+1),HL
  LD HL,BigEnemyDestroyedHook
  LD (SiteA0D5+1),HL
  LD HL,ArenaBounceHook
  LD (Site9823+1),HL
  LD HL,ObjectSoundStubAt
  LD (SiteSpriteA+1),HL   ; the two calls of $9529: the object's sound first
  LD (SiteSpriteB+1),HL
  LD HL,DiveHook
  LD (Site9856+1),HL
  LD HL,AimPlayerHook
  LD (Site969D+1),HL
  LD HL,SlotGoneHook
  LD (Site9954+1),HL
; CALL over the instructions the hooks take the place of
  LD A,$CD
  LD (Site9954),A
  LD (Site9856),A
  LD (Site9823),A
  LD (Site95E7),A
  LD (SiteObject12),A
  LD (SiteObjectB),A      ; (SiteObjectA, the other CALL $9CB0, was a CALL already: only its operand changed)
  LD (SiteA0D5),A
  LD (SiteA0BA),A
  LD (SiteNextLevel),A
  LD (SiteGameStart),A
; NOPs: the GS image's CALL NZ,0, the rest of the LD (IY+$1B),1, the beeper sound 0's CALL
  XOR A
  LD H,A
  LD L,A
  LD (SiteA0BD),A
  LD (Site9859),A
  LD (SiteSound0),A
  LD (SiteSound0+1),HL
  LD HL,Mover
  LD DE,MoverAt
  LD BC,30                ; the mover and 3 bytes after it
  LDIR
  JP MoverAt

; --------------------------------------------------------------------------------------------------------------------
; Mover (run at $5BCC, below the stack): Zynaps's $5C00-$73FF to its place, $C800-$DFFF cleared, Zynaps started.
Mover:
  DISP $5BCC
MoverAt:
  LD HL,ZynapsLow
  LD DE,$5C00
  LD BC,$1800
  LDIR
  LD HL,ZynapsLow
  LD DE,ZynapsLow+1
  LD BC,$17FF
  LD (HL),0
  LDIR
  JP MainLoop
  ENT

; --------------------------------------------------------------------------------------------------------------------
; GateStub (run at $AA28, inside the routine whose beeper crackle shift registers it replaces): GateCountdown
; counted down to 0 once a call (the driver's Gate sets it), then the routine goes on at PlayInterruptPass. TitleEntry:
; the title page's module, loaded once (LoadKind 2), then the title page.
GateStub:
  DISP $AA28
GateStubAt:
  LD A,0                  ; GateCountdown: the operand
GateCountdown EQU $-1
  OR A
  JR Z,PlayInterruptPass
  DEC A
  LD (GateCountdown),A
  JR PlayInterruptPass
TitleEntry:
  LD A,(LoadKind)
  CP 2
  LD A,2
  LD (LoadKind),A
  LD HL,LoadSound
  DI
  CALL NZ,CallDriver      ; not again while LoadKind is 2 (the attract loop comes back here)
  EI
  JP CreditsPage
  ENT

; --------------------------------------------------------------------------------------------------------------------
; FillRecords: the sector and track of every loader record, from the sector after this block on (TRDOS_SECTOR):
; the records lie on the disk one after another. Runs here, on the records of the driver file's loader copy.
FillRecords:
  LD HL,$0100             ; overwritten below: a leftover (with the three NOPs)
  NOP
  NOP
  NOP
  LD IX,RecordsInBlock
  LD HL,(TRDOS_SECTOR)    ; L = the sector, H = the track
  LD DE,6
.record:
  LD A,(IX+0)             ; the sectors (0: the end)
  OR A
  RET Z
  LD (IX+2),L
  LD (IX+3),H
  ADD A,L                 ; the next record's sector: L + A, 16 a track
  LD C,A
  AND $0F
  LD L,A
  LD A,C
  AND $F0
  RRCA
  RRCA
  RRCA
  RRCA
  ADD A,H
  LD H,A
  ADD IX,DE
  JR .record

; --------------------------------------------------------------------------------------------------------------------
; TitleStub (run at $5B00): the title loop's JP NC lands here: the title routine, the loading screen from bank 7,
; then the trampoline's attract test.
TitleStub:
  DISP $5B00
TitleStubAt:
  CALL ClearScreen
  DI
  LD BC,$7FFD
  LD A,PAGE_BANK7
  OUT (C),A
  PUSH BC
  LD HL,$C000
  LD DE,$4000
  LD BC,$1B00
  LDIR
  POP BC
  LD A,PAGE_ROM48
  OUT (C),A
  EI
  JP Attract
  ENT

; --------------------------------------------------------------------------------------------------------------------
; ObjectSoundStub (run at $B2F0, the 48K's beeper request): the two calls of PathOpAccelerate come here first.
; The driver's ObjectSound gets the object's path pointer (IY+$1D) in DE, the caller's C (the movement flags) in B
; and the frames its path command has left (IY+$1B) in C (written into CallDriverFx's LD BC); then
; PathOpAccelerate as before.
ObjectSoundStub:
  DISP $B2F0
ObjectSoundStubAt:
  LD HL,ObjectSound
  PUSH AF
  LD A,C
  LD (DriverBC+1),A       ; B = the caller's C
  LD A,(IY+$1B)
  LD (DriverBC),A         ; C = the object's byte at IY+$1B
  LD E,(IY+$1D)
  LD D,(IY+$1E)
  CALL CallDriverFx
  POP AF
  JP PathOpAccelerate
  ENT

; --------------------------------------------------------------------------------------------------------------------
; WaitStub (run at $A6AE, the 48K's "wait A frames"): the wait between rounds is the driver's RoundWait. The GS image
; has the other callers of $A6AE replaced by HALT loops of their own.
WaitStub:
  DISP $A6AE
WaitStubAt:
  DI
  LD HL,RoundWait
  JP CallDriver
  ENT

; --------------------------------------------------------------------------------------------------------------------
; HookStubs (run at $FF1C, over the 48K's title tune data): each the instruction it replaced at its site, and the
; driver entry. Through CallDriver always; through CallDriverFx only in effects-only mode.
HookStubs:
  DISP $FF1C
HookStubsAt:
RoundStartHook:           ; $B03E CALL $91C6: the round start's level sound, then $91C6
  LD HL,LevelChange
  CALL CallDriver
  DI
  JP ClearHitGrid
GameStartHook:            ; $AF51 LD ($80B0),A: the game start (LoadKind 1: the jingle)
  DI
  LD HL,LevelChange
  LD (RasterLines),A
  LD A,1
  LD (LoadKind),A
  CALL CallDriver
  XOR A
  LD (LoadKind),A
  EI
  RET
ExplodeHook:              ; $9FBE, $A034 CALL $A293: FX 7, then the explosion without the beeper crackle
  LD HL,ExplosionSound
  CALL CallDriver
  JP StartExplosionQuiet
ShipHitHook:              ; $9B51 JP $9B5F: FX 8, then the ship hit
  LD HL,ShipExplodesSound
  CALL CallDriver
  JP KillPlayer
MissileLaunchHook:               ; $9CFA, $9D1F CALL $9CB0: FX 5, then $9CB0
  LD HL,MissileLaunchSound
  CALL CallDriver
  JP PlaceAtPlayer
PlasmaLaunchHook:             ; $9CA6 LD (IX+$12),A: FX 4
  LD HL,PlasmaLaunchSound
  CALL CallDriver
  LD (IX+$12),A
  RET
EnemyFireHook:               ; $A1C4 the beeper request, sound 1: FX 4
  PUSH HL
  LD HL,EnemyFireSound
HookCall:
  CALL CallDriver
  POP HL
  RET
PlasmaBounceHook:               ; sound 3: FX 6
  PUSH HL
  LD HL,PlasmaBounceSound
  JR HookCall
ShotHook:               ; sound 2: the shot (FX 9 / 10)
  PUSH HL
  LD HL,ShotSound
  JR HookCall
WeaponOnHook:               ; sound 6: FX 3
  PUSH HL
  LD HL,WeaponOnSound
  JR HookCall
PodAppearsHook:               ; sound 4: FX 1
  PUSH HL
  LD HL,PodAppearsSound
  JR HookCall
NextWeaponHook:               ; sound 5: FX 2
  PUSH HL
  LD HL,NextWeaponSound
  JR HookCall
NextLevelHook:            ; $B075 LD DE,8: the level in B is the next one
  LD A,B
  LD (NextLevel),A
  LD DE,8
  RET
SceneryBounceHook:                 ; $95E7 LD HL,0: effects only
  LD HL,SceneryBounceSound
  CALL CallDriverFx
  LD HL,0
  RET
BigEnemyHitHook:                 ; $A0BA DEC (IY+$0D): the sound unless it reached 0 (effects only)
  DEC (IY+$0D)
  RET Z
  LD HL,BigEnemyHitSound
  JP CallDriverFx
BigEnemyDestroyedHook:                 ; $A0D5 LD ($80E2),A
  LD HL,BigEnemyDestroyedSound
  LD (LockMask),A
  JP CallDriver
ArenaBounceHook:                 ; $9823 LD HL,0: effects only
  LD HL,ArenaBounceSound
  CALL CallDriverFx
  LD HL,0
  RET
DiveHook:                 ; $9856 LD (IY+$1B),1: effects only
  PUSH HL
  LD HL,DiveSound
  CALL CallDriverFx
  POP HL
  LD (IY+$1B),1
  RET
AimPlayerHook:                 ; $969D CALL $989F: effects only, with the object's path pointer in DE
  LD HL,PathSound
  LD E,(IY+$1D)
  LD D,(IY+$1E)
  CALL CallDriverFx
  JP DirectionTo
  ENT
HookStubsEnd:

; --------------------------------------------------------------------------------------------------------------------
; Trampolines (run at $B446, over the 48K's title tune player): the attract test, the key wait, the variables, and
; the two calls into bank 1.
Trampolines:
  DISP $B446
TrampolinesAt:
Attract:                  ; after TitleStub: the 48K's attract test, then the title loop or a game
  CALL HiScoreHold
  JP NC,MainLoopTitle
  JP MainLoopGame
KeyWait:                  ; the title page: up to 250 x 2 frames for a key (any half-row); carry when pressed
  LD B,250
.wait:
  XOR A
  IN A,($FE)
  CPL
  AND $1F
  SCF
  RET NZ
  HALT
  HALT
  DJNZ .wait
  AND A
  RET
FxVolume:       DB $40    ; #2B
ModuleVolume:   DB $30    ; #2A (set by the loader for each level)
Level:          DB 0      ; the level whose sound is on the card
NextLevel:      DB 0
LoadKind:       DB 0      ; 0 a level, 1 the game start, 2 the title
OptionSaturns:  DB 1      ; the menu's options (written by the menu before this block is installed)
OptionShooting: DB 0
CallDriver:               ; HL called in bank 1 when SoundOn is not 0; AF, BC, DE kept
  PUSH DE
  PUSH BC
  PUSH AF
  LD BC,$7FFD
  LD A,PAGE_BANK1
  OUT (C),A
  PUSH BC
  LD A,1                  ; SoundOn
SoundOn EQU $-1
  OR A
  CALL NZ,JumpHL
  POP BC
  LD A,PAGE_ROM48
  OUT (C),A
  JR CallDone
JumpHL:
  JP (HL)
SlotGoneHook:             ; $9954 LD L,(IY+0): the object's slot freed in the driver
  LD HL,ClearSlot
CallDriverFx:             ; HL called in bank 1 in effects-only mode only, with BC = DriverBC; then LD L,(IY+0)
  PUSH DE
  PUSH BC
  PUSH AF
  LD A,0                  ; EffectsOnly (the menu's key 1 / 2)
EffectsOnly EQU $-1
  OR A
  JR Z,FxSkip
  LD BC,$7FFD
  LD A,PAGE_BANK1
  OUT (C),A
  PUSH BC
  LD A,(SoundOn)
  OR A
  LD BC,0                 ; DriverBC: written by ObjectSoundStub
DriverBC EQU $-2
  CALL NZ,JumpHL
  POP BC
  LD A,PAGE_ROM48
  OUT (C),A
FxSkip:
  LD L,(IY+0)             ; the instruction SlotGoneHook replaced (harmless for the other callers: HL is free)
CallDone:
  POP AF
  POP BC
  POP DE
  RET
  ENT
TrampolinesEnd:

  ASSERT $ == DriverFile
  ASSERT GateStubAt+32 == PlayInterruptPass-1
  SAVEBIN "build/disk/install.bin",Install,$-Install
