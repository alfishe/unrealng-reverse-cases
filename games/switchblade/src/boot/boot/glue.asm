; --------------------------------------------------------------------------------------------------------------------
; glue.asm: The AY glue: the 128K's sound player entry, the menu's music / effects toggle, the 128K intro
;
; Copied from $40A4 to $853F-$85E0 by the bootstrap on a 128K, over the 48K version's effect player (the beeper). The
; game's sound interface stays the same: TuneRequest $8452, EffectRequest $8454 and the call to $853F from
; InterruptHandler; the glue pages bank 4 and drives its AY player (src/bank4), whose names are @const here. The menu
; entries GlueMenuInput, GlueSoundIcon and GlueIntro are reached only through the hook sites.
; --------------------------------------------------------------------------------------------------------------------

; One frame of the 128K sound: page bank 4, the requests and the player, the
; volume gate, page back
;
; Called by InterruptHandler `$8456` every frame. Bank 4 (`$14`) at `$C000`;
; GlueRequests; EffectBusy `$9BA3` = AY channel A's volume (`$D0A2`), so the
; footstep effect waits while channel A sounds; then `$7FFD` = Last7FFD `$8450`
; (the paging the interrupted code had).
;
; Witness: L1 47031 (c1, deaths, gameover, menu, opt2, rooms).
AyGlue:
  LD A,$14
  LD BC,$7FFD
  OUT (C),A
  CALL GlueRequests
  LD A,(AyChannelA+5)
  LD (EffectBusy),A
  LD A,(Last7FFD)
  LD BC,$7FFD
  OUT (C),A
  RET

; The tune and effect requests: start a tune, loop it, follow the jingle with
; the music, play an effect, or one frame
;
; - TuneRequest `$8452` = `$FF`: Silence when MusicState is not 0 (the game's
; stop, `$5C45`).
;
; - `$FE`: no request. Else the number (bit 7 = loop) goes to TuneState
; `$8453`, StartTune with A AND 15, and the request becomes `$FE`.
;
; - While a tune plays (MusicState not 0): `JP PlayFrame`.
;
; - When it has ended: TuneState bit 7 restarts it (the request is set again);
; tune 2 (the start jingle) is followed by `$81` (tune 1, looped, the in-game
; music) when SoundMode `$8455` is 0 (music).
;
; - Then EffectRequest `$8454` (`$FF` after reading it): none -> `JP PlayFrame`
; (the envelopes), else `JP PlayEffect` with A = the effect.
;
; Witness: L1 47031 (c1, deaths, gameover, menu, opt2, rooms).
GlueRequests:
  LD HL,TuneRequest
GlueTune:
  LD A,(HL)
  INC A
  JR Z,GlueStop
  INC A
  LD (HL),$FE
  INC HL
  JR Z,GlueTunePlaying
  DEC A
  DEC A
  LD (HL),A
  AND $0F
  CALL StartTune
GlueTunePlaying:
  LD A,(MusicState)
  OR A
  JP NZ,PlayFrame
  LD A,(HL)
  BIT 7,A
  DEC HL
  JR NZ,GlueRequestAgain
  CP $02
  JR NZ,GlueEffect
  LD A,(SoundMode)
  OR A
  JR NZ,GlueEffect
  LD A,$81
GlueRequestAgain:
  LD (HL),A
  JR GlueTune
GlueStop:
  LD A,(MusicState)
  OR A
  CALL NZ,Silence
GlueEffect:
  LD HL,EffectRequest
  LD A,(HL)
  LD (HL),$FF
  INC A
  JP Z,PlayFrame
  DEC A
  JP PlayEffect

; Hook sites 2 and 3: the fire test, and left / right choose music or effects
;
; Replaces `CALL $8529` (ReadInput) in ShowHighScores and TitleSequence.
; ReadInput, EI: Z (fire) returns Z. Else DecodeDirection `$850E`: no direction
; or no left / right (D = 0) returns NZ; right (D = +1) sets SoundMode `$8455`
; = 1 (effects), left 0 (music), and GlueSoundIcon shows it; returns NZ (A =
; 1).
;
; Witness: L1 7533 (c1, deaths, gameover, menu, opt2).
GlueMenuInput:
  CALL ReadInput
  EI
  RET Z
  CALL DecodeDirection
  JR NC,GlueNoFire
  LD A,D
  OR A
  JR Z,GlueNoFire
  JP P,GlueSetMode
  XOR A
GlueSetMode:
  LD (SoundMode),A

; Hook site 4: print the music or effects icon at Y $B8, X $1E by SoundMode
;
; SoundMode bit 0: EffectsIconText `$8225`, else MusicIconText `$821E`, through
; PrintString `$837B`. Then A = 1, NZ.
;
; Witness: L1 957 (c1, deaths, gameover, menu, opt2).
GlueSoundIcon:
  LD HL,EffectsIconText
  LD A,(SoundMode)
  RRA
  JR C,GlueSoundIconPrint
  LD HL,MusicIconText
GlueSoundIconPrint:
  CALL PrintString
  XOR A
; This entry point is used by the routine at GlueMenuInput.
GlueNoFire:
  INC A                   ; A + 1: NZ
  RET

; Hook site 5: the 128K intro (StoryPages in bank 4), then bank 0
;
; DI, bank 4 (`$14`) paged and kept in Last7FFD (so the interrupt's AyGlue
; pages it back), EI, StoryPages `$D3D0`; then DI, bank 0 (`$10`) and Last7FFD,
; EI. Called by NewGame `$5C9A` before every game.
;
; Witness: L1 8 (c1, deaths, gameover, menu, opt2).
GlueIntro:
  DI
  LD A,$14
  LD BC,$7FFD
  OUT (C),A
  LD (Last7FFD),A
  EI
  CALL StoryPages
  DI
  LD A,$10
  LD BC,$7FFD
  OUT (C),A
  LD (Last7FFD),A
  EI
  RET
