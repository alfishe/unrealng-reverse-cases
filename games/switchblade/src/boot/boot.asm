; Switchblade, Gremlin Graphics 1991: TZX block 5's first $146 bytes, loaded to $4000 (into the screen): the
; bootstrap $4000-$40A3 and the 162-byte AY glue $40A4-$4145, which the bootstrap copies to $853F on a 128K.
; Written by kit/mkgame.py from src/boot/boot.ann and the recordings; edit boot.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; Constants: addresses outside this image, ROM entries, ports (@const)
MusicState         EQU $C006  ; bank 4: $FF a tune playing, 1 dying away, 0 stopped (src/bank4)
PlayEffect         EQU $C011  ; bank 4: start sound effect A
StartTune          EQU $C0D7  ; bank 4: start tune A
PlayFrame          EQU $C17D  ; bank 4: one frame of the player
AyChannelA         EQU $D09D  ; bank 4: the AY record of channel A (+5 the volume)
Silence            EQU $D182  ; bank 4: silence the AY
StoryPages         EQU $D3D0  ; bank 4: the 128K intro story

; Addresses outside this image (@equ in the annotations)
ResidentSource EQU $4146  ; block 5's bytes for $5C00-$6B4C (the game's start code, src/game)
PanelSource    EQU $5093  ; block 5's bytes for $FF01-$FFFE (the game's panel code)
GlobalsInit    EQU $5C00  ; the game's lowest address: the copy's target and the top of the stack
NewGameIntroHook EQU $5C9A  ; hook site 5: three NOPs in NewGame
GameEntry      EQU $5CFA  ; the game's entry
GameEntryIntro EQU $5CFD  ; hook site 1: CALL Intro48 in GameEntry
MusicIconText  EQU $821E  ; the note icon's text record
EffectsIconText EQU $8225  ; the effects icon's text record
PrintString    EQU $837B  ; the game's print routine
Last7FFD       EQU $8450  ; the last value written to $7FFD, which the glue restores
TuneRequest    EQU $8452  ; the game's sound variables (src/game, $8450-$8455)
TuneState      EQU $8453  ; the tune playing, bit 7 = loop
EffectRequest  EQU $8454  ; the effect to start, $FF none
SoundMode      EQU $8455  ; 0 music, 1 effects (128K)
InterruptHandler EQU $8456  ; the game's IM 2 handler
DecodeDirection EQU $850E  ; D = right +1 / left -1, NC when no direction
ReadInput      EQU $8529  ; Z = fire pressed
EffectBusy     EQU $9BA3  ; the operand the footstep effect tests: the AY channel A volume on a 128K
ShowHighScoresHook EQU $A6EF  ; hook site 2: CALL ReadInput in ShowHighScores
TitleColourHook EQU $A75C  ; hook site 4: three NOPs in TitleSequence after the clear
TitleStepHook  EQU $A76F  ; hook site 3: CALL ReadInput in TitleSequence
Im2Jump        EQU $FDFD  ; JP InterruptHandler, the target of every IM 2 vector
Im2Table       EQU $FE00  ; 257 bytes $FD: the IM 2 vector table for I = $FE
PanelWeapon    EQU $FF01  ; the game's panel code (over the tape loader)

; the bootstrap: $4000-$40A3
  ORG $4000
  INCLUDE "boot/boot.asm"  ; The bootstrap: IM 2, the copies of the game's resident parts, the 128K hooks and glue

; the AY glue: $40A4-$4145, run at $853F
  ORG $40A4
  DISP $853F
  INCLUDE "boot/glue.asm"  ; The AY glue: the 128K's sound player entry, the menu's music / effects toggle, the 128K intro
  ENT

  SAVEBIN "boot.bin",$4000,326
