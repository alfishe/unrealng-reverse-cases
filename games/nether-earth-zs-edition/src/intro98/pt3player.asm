; --------------------------------------------------------------------------------------------------------------------
; pt3player.asm: PT 3 Player v1.0 by Nick of GDC: the compiled tune's player
;
; The player Pro Tracker 3.x writes in front of a compiled tune ("PT 3 Player v1.0 by Nick of GDC" at +$0B), with the
; module right after it at +$E21 ($CE21, module pt3tune). The block starts with it: the REM loader reads the block to
; $C000 and the intro (IntroMain) CALLs Pt3Init at $C000 once (r98 frame 2048), its interrupt IntroInterrupt CALLs
; Pt3PlayEntry every frame (2155 times, frames 2049-4203) and IntroEnd CALLs Pt3StopEntry once (frame 4203). Entries:
; Pt3Init +0 (LD HL,Pt3Module; the module set up, every channel muted, the AY written silent; DI, returns with
; interrupts off), Pt3PlayEntry +5 (JP Pt3Play: one frame; interrupts off, it uses SP as a data pointer and IYL as a
; scratch, IY = $5C3A again on return), Pt3StopEntry +8 (JP Pt3Stop: the three volumes 0, the registers written once).
;
; How it works (a frame): 1. the three channel ticks (ChAMute..., ChBMute..., ChCMute...): sample line, volume
; (VolumeTable), noise / envelope offset, mixer, ornament, tone (NoteTable) + slide, on-off; the envelope slide; 2.
; WriteAy: registers 0-12 from the AY block at a page start (L = the register number), 13 only when a new envelope
; type was set (EnvType); 3. the pattern reading, spread over three frames by RowFrame: channel A's row two frames
; before the row, B's one frame before, C's on the row's frame. A and B are decoded into a staging area (the operands
; of the blocks from ChANewNoteJr on, each block skipped by a JR / JP whose displacement the decoder clears), C
; applies its row at once; the staged A and B blocks run right after C's decode, so all three channels change on the
; same frame. RowFrame is reloaded with the delay there: the player needs a delay of 3 or more (COOL WINTER's is 5).
;
; The channel bytes (the decoders ChADecode, ChBDecode, ChCDecode; B = $10, C = $20 step the accumulator through the
; ranges with ADD and the carry): $F0-$FF ornament n + the next byte: sample * 2 (envelope off, ornament from its
; start); $D1-$EF sample n-$D0 (for the next note); $D0 the row ends, nothing new; $C1-$CF volume n-$C0; $C0 sound
; off, the row ends; $B2-$BF envelope type n-$B1 + period (2 bytes, high first); $B1 + byte: rows to skip; $B0
; envelope off; $50-$AF note n-$50, the row ends; $40-$4F ornament n-$40; $11-$1F envelope type n-$10 + period (2
; bytes) + sample * 2; $10 envelope off + sample * 2; $20-$3F noise base n-$20 in channel B (A and C take them as
; $11-$1F, a quirk of this player); $01-$09 an effect: its routine's address (ChAEffects...) is pushed and runs after
; the row's note, its parameters follow the row's bytes (1 gliss: delay, step word; 2 portamento: delay, distance
; word, step word; 3 sample offset; 4 ornament offset; 5 on-off: off frames, on frames; 8 envelope slide: delay, step
; word; 9 delay; 6 and 7 do nothing: $0052, a RET in the 48 K BASIC ROM, which is paged in while the intro runs, $7FFD
; = $10); $00 at the start of channel A's row: the pattern ends, the next position.
;
; Against the signature R/signatures/sound/ay-players/pro-tracker-3/nick-gdc-1.0 (Advanced Nether Earth's copy at the
; same address $C000): 3557 of the player's 3617 bytes are equal; 60 differ, in two places. (1) VolumeTable
; ($C100-$C1FF, 50 bytes): here it is Ivan Roshin's volume table in its Pro Tracker 3.3x-3.4x form (row v, column l: v
; = 0 gives 0, else l * (v + 1) / 16 rounded down), the signature's is the 3.5x+ form (l * (v * 17 + (v > 6)) / 256
; rounded to nearest). The module after it says "ProTracker 3.3 compilation": the tracker writes the table that fits
; the version it compiles for (Bulba's player builds the same two forms at init, chosen by the version digit); this
; player never builds it, it plays with the one in the file. (2) AyPad ($C2F6-$C2FF, 10 bytes): the text "-VORONEZH-"
; here, zeros in the signature; no code reads these bytes (no read in the window). Everything else, the code and the
; note table included, is the same bytes; the variables in the operands and SamplePtrs / OrnamentPtrs are zero in the
; file in both (Pt3Init fills them: 130 bytes of $C048-$C0FF change at frame 2048).
;
; Known bug (from the code, as in the signature's copy): channel B's on-off effect (ChBEffOnOff) sets ChBOnOffJp to
; jump to itself, so the player would hang on a row that applies it to channel B; the window played COOL WINTER for
; 2155 frames with no hang.
; --------------------------------------------------------------------------------------------------------------------

; the module set up: LD HL,Pt3Module, into InitModule
;
; Entry +0 of the compiled player. HL = Pt3Module ($CE21, the tune right after
; the player), then InitModule: the pointers, the delay, every channel muted
; and the AY written silent (through InitState into Pt3Stop). Returns with
; interrupts off (InitModule's DI). Called once by IntroMain (r98 frame 2048).
Pt3Init:
  LD HL,Pt3Module
  JR InitModule

; entry +5: JP Pt3Play, one frame of the tune
;
; Called by IntroInterrupt every frame (2155 times, r98 frames 2049-4203), with
; interrupts off.
Pt3PlayEntry:
  JP Pt3Play

; entry +8: JP Pt3Stop, the AY silent
;
; Called once by IntroEnd (frame 4203) when a key ended the intro.
Pt3StopEntry:
  JP Pt3Stop

; " PT 3 Player v1.0 by Nick of GDC " (33 bytes, never read)
PlayerId:
  DEFM " PT 3 Player v1.0 by Nick of GDC "

; HL = the module
;
; HL = the module. The module address into every reader's operand, the delay,
; the position pointers (the start and the loop), the pattern table, the 48
; sample and ornament pointers (offsets + the address) copied to SamplePtrs /
; OrnamentPtrs; then InitState.
InitModule:
  DI
  LD (InitPositions+$0001),HL
  LD (InitPatterns+$0001),HL
  LD (InitPointerBase+$0001),HL
  LD (ModuleAddr+$0001),HL
  LD BC,$0064             ; +100: the delay
  ADD HL,BC
  LD A,(HL)
  LD (Delay+$0001),A
  INC HL
  INC HL
  LD E,(HL)
  INC HL
  LD D,B
  PUSH HL
InitPositions:
  LD HL,$0000
  LD C,$C9                ; +201: the position list
  ADD HL,BC
  LD (PositionPtr+$0001),HL
  ADD HL,DE
  LD (LoopPositionPtr+$0001),HL
  POP HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD (InitSp+$0001),SP
  LD SP,HL
InitPatterns:
  LD HL,$0000
  ADD HL,BC
  LD (PatternTable+$0001),HL
  LD DE,SamplePtrs
  LD A,$30                ; 32 sample + 16 ornament pointers
InitPointerLoop:
  POP BC
InitPointerBase:
  LD HL,$0000
  ADD HL,BC
  EX DE,HL
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  EX DE,HL
  DEC A
  JR NZ,InitPointerLoop
InitSp:
  LD SP,$0000
  LD A,$F0                ; volume 15 (its row of VolumeTable)
  LD (ChAVolume+$0001),A
  LD (ChBVolume+$0001),A
  LD (ChCVolume+$0001),A
  LD HL,(OrnamentPtrs)
  LD (ChCOrnamentPtr+$0001),HL
  LD (ChAOrnamentPtr+$0001),HL
  LD (ChBOrnamentPtr+$0001),HL
  LD HL,(SamplePtrs)
  LD (ChANewSample+$0001),HL
  LD (ChBNewSample+$0001),HL
  LD A,$03                ; RowFrame: A decoded on the next frame
  JP InitState

; 32 sample pointers (module address added by InitModule); at a page offset
; $A0: the decoders index ...
;
; 32 sample pointers (module address added by InitModule); at a page offset
; $A0: the decoders index it by the low byte
SamplePtrs:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; 16 ornament pointers, right after the samples (page offset $E0)
;
; 16 ornament pointers, right after the samples (page offset $E0)
OrnamentPtrs:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; 16 x 16 bytes at a page start: [channel volume * 16 + sample level] -> the AY
; volume (3.3x-3.4x form)
;
; 16 x 16 bytes at a page start: [channel volume * 16 + sample level] -> the AY
; volume. Pro Tracker 3.3x-3.4x's form of Ivan Roshin's table (row v, column l:
; 0 for v = 0, else l * (v + 1) / 16 rounded down; row 1 = 0 x 8, 1 x 8; row 2
; = 0 x 6, 1 x 5, 2 x 5), written by the tracker for this 3.3 module; the
; signature's copy holds the 3.5x+ form (50 of the 256 bytes differ). Its first
; byte (0) is also the "end of pattern" InitState points channel A at.
VolumeTable:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01
  DEFB $00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02
  DEFB $00,$00,$00,$00,$01,$01,$01,$01,$02,$02,$02,$02,$03,$03,$03,$03
  DEFB $00,$00,$00,$00,$01,$01,$01,$02,$02,$02,$03,$03,$03,$04,$04,$04
  DEFB $00,$00,$00,$01,$01,$01,$02,$02,$03,$03,$03,$04,$04,$04,$05,$05
  DEFB $00,$00,$00,$01,$01,$02,$02,$03,$03,$03,$04,$04,$05,$05,$06,$06
  DEFB $00,$00,$01,$01,$02,$02,$03,$03,$04,$04,$05,$05,$06,$06,$07,$07
  DEFB $00,$00,$01,$01,$02,$02,$03,$03,$04,$05,$05,$06,$06,$07,$07,$08
  DEFB $00,$00,$01,$01,$02,$03,$03,$04,$05,$05,$06,$06,$07,$08,$08,$09
  DEFB $00,$00,$01,$02,$02,$03,$04,$04,$05,$06,$06,$07,$08,$08,$09,$0A
  DEFB $00,$00,$01,$02,$03,$03,$04,$05,$06,$06,$07,$08,$09,$09,$0A,$0B
  DEFB $00,$00,$01,$02,$03,$04,$04,$05,$06,$07,$08,$08,$09,$0A,$0B,$0C
  DEFB $00,$00,$01,$02,$03,$04,$05,$06,$07,$07,$08,$09,$0A,$0B,$0C,$0D
  DEFB $00,$00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E
  DEFB $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F

; 96 tone periods (words, notes C-1 .. B-8 of the tracker), at a page start:
; PT3's tone table #1 ...
;
; 96 tone periods (words, notes C-1 .. B-8 of the tracker), at a page start:
; PT3's tone table #1 (Sound Tracker's, $0EF8 for the lowest note), the only
; one this player has. The effect tables follow it in the same page (the
; decoders index them by the low byte).
NoteTable:
  DEFB $F8,$0E,$10,$0E,$60,$0D,$80,$0C,$D8,$0B,$28,$0B,$88,$0A,$F0,$09
  DEFB $60,$09,$E0,$08,$58,$08,$E0,$07,$7C,$07,$08,$07,$B0,$06,$40,$06
  DEFB $EC,$05,$94,$05,$44,$05,$F8,$04,$B0,$04,$70,$04,$2C,$04,$FD,$03
  DEFB $BE,$03,$84,$03,$58,$03,$20,$03,$F6,$02,$CA,$02,$A2,$02,$7C,$02
  DEFB $58,$02,$38,$02,$16,$02,$F8,$01,$DF,$01,$C2,$01,$AC,$01,$90,$01
  DEFB $7B,$01,$65,$01,$51,$01,$3E,$01,$2C,$01,$1C,$01,$0A,$01,$FC,$00
  DEFB $EF,$00,$E1,$00,$D6,$00,$C8,$00,$BD,$00,$B2,$00,$A8,$00,$9F,$00
  DEFB $96,$00,$8E,$00,$85,$00,$7E,$00,$77,$00,$70,$00,$6B,$00,$64,$00
  DEFB $5E,$00,$59,$00,$54,$00,$4F,$00,$4B,$00,$47,$00,$42,$00,$3F,$00
  DEFB $3B,$00,$38,$00,$35,$00,$32,$00,$2F,$00,$2C,$00,$2A,$00,$27,$00
  DEFB $25,$00,$23,$00,$21,$00,$1F,$00,$1D,$00,$1C,$00,$1A,$00,$19,$00
  DEFB $17,$00,$16,$00,$15,$00,$13,$00,$12,$00,$11,$00,$10,$00,$0F,$00

; The effect routines of the three channels, effects 1-9 (6 and 7 unused:
; $0052, a RET in the 48 K ...
;
; The effect routines of the three channels, effects 1-9 (6 and 7 unused:
; $0052, a RET in the 48 K ROM).
ChAEffects:
  DEFW ChAEffGliss
  DEFW ChAEffPorta
  DEFW ChAEffSampleOffset
  DEFW ChAEffOrnOffset
  DEFW ChAEffOnOff
  DEFW $0052
  DEFW $0052
  DEFW EffEnvSlide
  DEFW EffDelay
ChBEffects:
  DEFW ChBEffGliss
  DEFW ChBEffPorta
  DEFW ChBEffSampleOffset
  DEFW ChBEffOrnOffset
  DEFW ChBEffOnOff
  DEFW $0052
  DEFW $0052
  DEFW EffEnvSlide
  DEFW EffDelay
ChCEffects:
  DEFW ChCEffGliss
  DEFW ChCEffPorta
  DEFW ChCEffSampleOffset
  DEFW ChCEffOrnOffset
  DEFW ChCEffOnOff
  DEFW $0052
  DEFW $0052
  DEFW EffEnvSlide
  DEFW EffDelay

; "-VORONEZH-": 10 bytes up to the page start the AY block needs, never read
;
; The text "-VORONEZH-" (the town of the player's authors, Nick of GDC: "Golden
; Disk, Voronezh" in ANE's source of the player; who put it here is not known;
; ANE's copy holds zeros here). WriteAy needs the AY block at a page start, so
; these bytes are padding: no code reads or writes them (none in the window).
AyPad:
  DEFM "-VORONEZH-"

; The AY block, at a page start (WriteAy uses L as the register number):
; registers 0-12
;
; The AY block, at a page start (WriteAy uses L as the register number):
; registers 0-12.
AyToneA:
  DEFB $00,$00
AyToneB:
  DEFB $00,$00
AyToneC:
  DEFB $00,$00
AyUnused:
  DEFB $00,$00            ; registers 6 and 7: WriteAy takes IXH and IXL
                          ; instead
AyVolumeA:
  DEFB $00
AyVolumeB:
  DEFB $00
AyVolumeC:
  DEFB $00
AyEnvPeriod:
  DEFB $00,$00
AyEnvTypeUnused:
  DEFB $00                ; register 13: written from EnvType, not from here

; the channels' start values: RowFrame 3, every row skip counter 1 (decode on
; the first frame), the ...
;
; the channels' start values: RowFrame 3, every row skip counter 1 (decode on
; the first frame), the channels muted, the envelope masks off, RowCounter -1,
; channel A's pattern pointer at a 0 byte (VolumeTable's first) so that the
; first frame reads position 0. Falls into Pt3Stop.
InitState:
  LD (ChCSamplePtr+$0001),HL
  LD (RowFrame+$0001),A
  LD A,$01
  LD (ChARowSkip+$0001),A
  LD (ChBRowSkip+$0001),A
  LD (ChCRowSkip+$0001),A
  LD A,$FF
  LD (ChAMute+$0001),A
  LD (ChCMute+$0001),A
  LD (ChBMute+$0001),A
  LD L,A
  LD H,A
  LD (RowCounter+$0001),HL
  LD A,$0F
  LD (ChAEnvMask+$0001),A
  LD (ChBEnvMask+$0001),A
  LD (ChCEnvMask+$0001),A
  LD HL,VolumeTable
  LD (ChAPatternPtr+$0001),HL

; the three volumes 0, then WriteAy with RestoreIy patched to RET (only the AY
; write)
;
; the three volumes 0, then WriteAy with RestoreIy patched to RET (only the AY
; write).
Pt3Stop:
  XOR A
  LD (AyVolumeA),A
  LD (AyVolumeB),A
  LD (AyVolumeC),A
  LD A,$C9
  LD (RestoreIy),A
  CALL WriteAy
  LD A,$FD
  LD (RestoreIy),A
  RET

; one frame
;
; one frame. IYL = 0 (the envelope offset of the samples), IX = the noise of
; the last frame (IXH) and the mixer 0 (IXL); SP saved in PlaySp (the ticks
; read with POP). NoiseMixer+3 = IXH: the noise is kept from frame to frame.
Pt3Play:
  LD IYL,$00
NoiseMixer:
  LD IX,$0000
  LD (PlaySp+$0001),SP

; Channel A, one tick: the sample line, the volume, the noise or envelope
; offset, the mixer bits, the ...
;
; Channel A, one tick: the sample line, the volume, the noise or envelope
; offset, the mixer bits, the ornament, the tone and its slide. Runs every
; frame; the channel's state lives in the operands of these instructions (each
; label names the value its operand holds). Out: the tone in the AY block, the
; volume in AyVolumeA (0 when muted), the mixer bits ORed into IXL, the noise
; into IXH, the envelope offset added to IYL.
;
; ChAMute: 0 while the channel sounds, $FF when it is off ($C0, before the
; first note, or the on-off effect's off phase).
ChAMute:
  LD A,$FF
  LD H,A
  INC A
  JP Z,ChAStoreVolume
ChASamplePtr:
  LD SP,$0000
  POP DE
ChASamplePos:
  LD A,$00
  LD L,A
  INC A
  CP D
  JR NZ,ChASampleStep
  LD A,E
ChASampleStep:
  LD (ChASamplePos+$0001),A
  LD A,L
  ADD A,A
  ADD A,A
  LD L,A
  ADD HL,SP
  LD SP,HL
  POP DE
  LD A,D
  AND $0F
  LD L,A
  LD A,E
  AND A
  JP P,ChAVolSlide
  AND $40
  LD A,($C3A4)
  JP NZ,ChAVolSlideUp
  DEC A
  CP $F0
  JR NZ,ChAVolSlideSet
  INC A
  JP ChAVolSlideSet
ChAVolSlideUp:
  INC A
  CP $10
  JR NZ,ChAVolSlideSet
  DEC A
ChAVolSlideSet:
  LD (ChAVolSlide+$0001),A
ChAVolSlide:
  LD A,$00
  ADD A,L
  JP P,ChALevelHigh
  XOR A
  JP ChAVolume
ChALevelHigh:
  CP $10
  JR C,ChAVolume
  LD A,$0F
ChAVolume:
  ADD A,$00
  LD H,$C1
  LD L,A
  LD A,(HL)
  SRL E
  JR C,ChAEnvMask
  OR $10
ChAEnvMask:
  AND $0F
  EX AF,AF'
  LD A,D
  LD L,A
  RLCA
  JR C,ChAEnvOffset
  LD H,A
ChANoiseAcc:
  LD A,$00
  ADD A,E
  BIT 5,L
  JR Z,ChANoiseSet
  LD (ChANoiseAcc+$0001),A
ChANoiseSet:
  LD IXH,A
  LD A,H
  JP ChAMixer
ChAEnvOffset:
  LD H,A
  LD A,E
  AND $1F
  CP $10
  JR C,ChAEnvOffsetAcc
  OR $F0
ChAEnvOffsetAcc:
  ADD A,$00
  BIT 5,L
  JR Z,ChAEnvOffsetAdd
  LD (ChAEnvOffsetAcc+$0001),A
ChAEnvOffsetAdd:
  ADD A,IYL
  LD IYL,A
  LD A,H
ChAMixer:
  RLCA
  RLCA
  RLCA
  AND $09
  LD IXL,A
  POP BC
  LD A,L
ChAToneAcc:
  LD HL,$0000
  ADD HL,BC
  AND $40
  JR Z,ChAOrnament
  LD (ChAToneAcc+$0001),HL
ChAOrnament:
  EX DE,HL
ChAOrnamentPtr:
  LD SP,$0000
  POP BC
ChAOrnamentPos:
  LD A,$00
  LD L,A
  INC A
  CP B
  JR NZ,ChAOrnamentStep
  LD A,C
ChAOrnamentStep:
  LD (ChAOrnamentPos+$0001),A
  LD H,$00
  ADD HL,SP
  LD L,(HL)
  LD H,$C2
ChANote:
  LD A,$00
  ADD A,L
  ADD A,A
  LD L,A
  LD SP,HL
  POP HL
  ADD HL,DE
ChAToneSlide:
  LD DE,$0000
  ADD HL,DE
  LD (AyToneA),HL
ChAGlissCount:
  LD A,$00
  DEC A
  JP M,ChATickEnd
  JR NZ,ChAGlissStore
ChAGlissStep:
  LD HL,$0000
  ADD HL,DE
  LD (ChAToneSlide+$0001),HL
ChAPortaJr:
  JR ChAGlissReload
  EX DE,HL
ChAPortaDistance:
  LD HL,$0000
  JR NC,ChAPortaSub
  ADD HL,DE
  JP ChAPortaTest
ChAPortaSub:
  SBC HL,DE
ChAPortaTest:
  INC H
  JR NZ,ChAGlissReload
ChAPortaNote:
  LD A,$00
  LD (ChANote+$0001),A
  XOR A
  LD (ChAGlissCount+$0001),A
  LD L,A
  LD (ChAToneSlide+$0001),HL
  JP ChATickEnd
ChAGlissReload:
  LD A,$00
ChAGlissStore:
  LD (ChAGlissCount+$0001),A
ChATickEnd:
  EX AF,AF'
ChAStoreVolume:
  LD (AyVolumeA),A
ChAOnOffCount:
  LD A,$00
  DEC A
  JP M,ChBMute
  JR NZ,ChAOnOffStore
  LD A,($C364)
  XOR $FF
  LD (ChAMute+$0001),A
  JP Z,ChAOnTime
ChAOffTime:
  LD A,$00
  JP ChAOnOffStore
ChAOnTime:
  LD A,$00
ChAOnOffStore:
  LD (ChAOnOffCount+$0001),A

; Channel B, one tick: the sample line, the volume, the noise or envelope
; offset, the mixer bits, the ...
;
; Channel B, one tick: the sample line, the volume, the noise or envelope
; offset, the mixer bits, the ornament, the tone and its slide. Runs every
; frame; the channel's state lives in the operands of these instructions (each
; label names the value its operand holds). Out: the tone in the AY block, the
; volume in AyVolumeB (0 when muted), the mixer bits ORed into IXL, the noise
; into IXH, the envelope offset added to IYL.
;
; ChBMute: 0 while the channel sounds, $FF when it is off ($C0, before the
; first note, or the on-off effect's off phase).
ChBMute:
  LD A,$FF
  LD H,A
  INC A
  JP Z,ChBStoreVolume
ChBSamplePtr:
  LD SP,$0000
  POP DE
ChBSamplePos:
  LD A,$00
  LD L,A
  INC A
  CP D
  JR NZ,ChBSampleStep
  LD A,E
ChBSampleStep:
  LD (ChBSamplePos+$0001),A
  LD A,L
  ADD A,A
  ADD A,A
  LD L,A
  ADD HL,SP
  LD SP,HL
  POP DE
  LD A,D
  AND $0F
  LD L,A
  LD A,E
  AND A
  JP P,ChBVolSlide
  AND $40
  LD A,($C4C0)
  JP NZ,ChBVolSlideUp
  DEC A
  CP $F0
  JR NZ,ChBVolSlideSet
  INC A
  JP ChBVolSlideSet
ChBVolSlideUp:
  INC A
  CP $10
  JR NZ,ChBVolSlideSet
  DEC A
ChBVolSlideSet:
  LD (ChBVolSlide+$0001),A
ChBVolSlide:
  LD A,$00
  ADD A,L
  JP P,ChBLevelHigh
  XOR A
  JP ChBVolume
ChBLevelHigh:
  CP $10
  JR C,ChBVolume
  LD A,$0F
ChBVolume:
  ADD A,$00
  LD H,$C1
  LD L,A
  LD A,(HL)
  SRL E
  JR C,ChBEnvMask
  OR $10
ChBEnvMask:
  AND $0F
  EX AF,AF'
  LD A,D
  LD L,A
  RLCA
  JR C,ChBEnvOffset
  LD H,A
ChBNoiseAcc:
  LD A,$00
  ADD A,E
  BIT 5,L
  JR Z,ChBNoiseSet
  LD (ChBNoiseAcc+$0001),A
ChBNoiseSet:
  LD IXH,A
  LD A,H
  JP ChBMixer
ChBEnvOffset:
  LD H,A
  LD A,E
  AND $1F
  CP $10
  JR C,ChBEnvOffsetAcc
  OR $F0
ChBEnvOffsetAcc:
  ADD A,$00
  BIT 5,L
  JR Z,ChBEnvOffsetAdd
  LD (ChBEnvOffsetAcc+$0001),A
ChBEnvOffsetAdd:
  ADD A,IYL
  LD IYL,A
  LD A,H
ChBMixer:
  RLCA
  RLCA
  RLCA
  RLCA
  AND $12
  OR IXL
  LD IXL,A
  POP BC
  LD A,L
ChBToneAcc:
  LD HL,$0000
  ADD HL,BC
  AND $40
  JR Z,ChBOrnament
  LD (ChBToneAcc+$0001),HL
ChBOrnament:
  EX DE,HL
ChBOrnamentPtr:
  LD SP,$0000
  POP BC
ChBOrnamentPos:
  LD A,$00
  LD L,A
  INC A
  CP B
  JR NZ,ChBOrnamentStep
  LD A,C
ChBOrnamentStep:
  LD (ChBOrnamentPos+$0001),A
  LD H,$00
  ADD HL,SP
  LD L,(HL)
  LD H,$C2
ChBNote:
  LD A,$00
  ADD A,L
  ADD A,A
  LD L,A
  LD SP,HL
  POP HL
  ADD HL,DE
ChBToneSlide:
  LD DE,$0000
  ADD HL,DE
  LD (AyToneB),HL
ChBGlissCount:
  LD A,$00
  DEC A
  JP M,ChBTickEnd
  JR NZ,ChBGlissStore
ChBGlissStep:
  LD HL,$0000
  ADD HL,DE
  LD (ChBToneSlide+$0001),HL
ChBPortaJr:
  JR ChBGlissReload

; channel B's portamento step (ChBPortaJr cleared)
;
; Reached when the row's portamento effect cleared ChBPortaJr's displacement:
; the slide so far against ChBPortaDistance; once the tone has covered the
; distance, ChBPortaNote becomes the note and the slide ends. Not run in the
; window: known from the code only.
ChBPortaRun:
  EX DE,HL
ChBPortaDistance:
  LD HL,$0000
  JR NC,ChBPortaSub
  ADD HL,DE
  JP ChBPortaTest
ChBPortaSub:
  SBC HL,DE
ChBPortaTest:
  INC H
  JR NZ,ChBGlissReload
ChBPortaNote:
  LD A,$00
  LD (ChBNote+$0001),A
  XOR A
  LD (ChBGlissCount+$0001),A
  LD L,A
  LD (ChBToneSlide+$0001),HL
  JP ChBTickEnd

; channel B's gliss counter reloaded
;
; The gliss / portamento delay back into ChBGlissCount (its operand set by the
; row's effect), then the tick's end. A jump target of ChBPortaJr and
; ChBPortaTest. Not run in the window: known from the code only.
ChBGlissReload:
  LD A,$00
; This entry point is used by the routine at ChBMute.
ChBGlissStore:
  LD (ChBGlissCount+$0001),A
; This entry point is used by the routines at ChBMute and ChBPortaRun.
ChBTickEnd:
  EX AF,AF'
; This entry point is used by the routine at ChBMute.
ChBStoreVolume:
  LD (AyVolumeB),A
ChBOnOffCount:
  LD A,$00
  DEC A
  JP M,ChCMute
  JR NZ,ChBOnOffStore
  LD A,($C480)
  XOR $FF
  LD (ChBMute+$0001),A
  JP Z,ChBOnTime
ChBOffTime:
  LD A,$00
  JP ChBOnOffStore
ChBOnTime:
  LD A,$00
ChBOnOffStore:
  LD (ChBOnOffCount+$0001),A

; Channel C, one tick: the sample line, the volume, the noise or envelope
; offset, the mixer bits, the ...
;
; Channel C, one tick: the sample line, the volume, the noise or envelope
; offset, the mixer bits, the ornament, the tone and its slide. Runs every
; frame; the channel's state lives in the operands of these instructions (each
; label names the value its operand holds). Out: the tone in the AY block, the
; volume in AyVolumeC (0 when muted), the mixer bits ORed into IXL, the noise
; into IXH, the envelope offset added to IYL.
;
; ChCMute: 0 while the channel sounds, $FF when it is off ($C0, before the
; first note, or the on-off effect's off phase).
ChCMute:
  LD A,$FF
  LD H,A
  INC A
  JP Z,ChCStoreVolume
ChCSamplePtr:
  LD SP,$0000
  POP DE
ChCSamplePos:
  LD A,$00
  LD L,A
  INC A
  CP D
  JR NZ,ChCSampleStep
  LD A,E
ChCSampleStep:
  LD (ChCSamplePos+$0001),A
  LD A,L
  ADD A,A
  ADD A,A
  LD L,A
  ADD HL,SP
  LD SP,HL
  POP DE
  LD A,D
  AND $0F
  LD L,A
  LD A,E
  AND A
  JP P,ChCVolSlide
  AND $40
  LD A,($C5DF)
  JP NZ,ChCVolSlideUp
  DEC A
  CP $F0
  JR NZ,ChCVolSlideSet
  INC A
  JP ChCVolSlideSet
ChCVolSlideUp:
  INC A
  CP $10
  JR NZ,ChCVolSlideSet
  DEC A
ChCVolSlideSet:
  LD (ChCVolSlide+$0001),A
ChCVolSlide:
  LD A,$00
  ADD A,L
  JP P,ChCLevelHigh
  XOR A
  JP ChCVolume
ChCLevelHigh:
  CP $10
  JR C,ChCVolume
  LD A,$0F
ChCVolume:
  ADD A,$00
  LD H,$C1
  LD L,A
  LD A,(HL)
  SRL E
  JR C,ChCEnvMask
  OR $10
ChCEnvMask:
  AND $0F
  EX AF,AF'
  LD A,D
  LD L,A
  RLCA
  JR C,ChCEnvOffset
  LD H,A
ChCNoiseAcc:
  LD A,$00
  ADD A,E
  BIT 5,L
  JR Z,ChCNoiseSet
  LD (ChCNoiseAcc+$0001),A
ChCNoiseSet:
  LD IXH,A
  LD A,H
  JP ChCMixer
ChCEnvOffset:
  LD H,A
  LD A,E
  AND $1F
  CP $10
  JR C,ChCEnvOffsetAcc
  OR $F0
ChCEnvOffsetAcc:
  ADD A,$00
  BIT 5,L
  JR Z,ChCEnvOffsetAdd
  LD (ChCEnvOffsetAcc+$0001),A
ChCEnvOffsetAdd:
  ADD A,IYL
  LD IYL,A
  LD A,H
ChCMixer:
  RRCA
  RRCA
  RRCA
  AND $24
  OR IXL
  LD IXL,A
  POP BC
  LD A,L
ChCToneAcc:
  LD HL,$0000
  ADD HL,BC
  AND $40
  JR Z,ChCOrnament
  LD (ChCToneAcc+$0001),HL
ChCOrnament:
  EX DE,HL
ChCOrnamentPtr:
  LD SP,$0000
  POP BC
ChCOrnamentPos:
  LD A,$00
  LD L,A
  INC A
  CP B
  JR NZ,ChCOrnamentStep
  LD A,C
ChCOrnamentStep:
  LD (ChCOrnamentPos+$0001),A
  LD H,$00
  ADD HL,SP
  LD L,(HL)
  LD H,$C2
ChCNote:
  LD A,$00
  ADD A,L
  ADD A,A
  LD L,A
  LD SP,HL
  POP HL
  ADD HL,DE
ChCToneSlide:
  LD DE,$0000
  ADD HL,DE
  LD (AyToneC),HL
ChCGlissCount:
  LD A,$00
  DEC A
  JP M,ChCTickEnd
  JR NZ,ChCGlissStore
ChCGlissStep:
  LD HL,$0000
  ADD HL,DE
  LD (ChCToneSlide+$0001),HL
ChCPortaJr:
  JR ChCGlissReload

; channel C's portamento step (ChCPortaJr cleared)
;
; As ChBPortaRun, for channel C. Not run in the window: known from the code
; only.
ChCPortaRun:
  EX DE,HL
ChCPortaDistance:
  LD HL,$0000
  JR C,ChCPortaAdd
  SBC HL,DE
  JP ChCPortaTest
ChCPortaAdd:
  ADD HL,DE
ChCPortaTest:
  INC H
  JR NZ,ChCGlissReload
ChCPortaNote:
  LD A,$00
  LD (ChCNote+$0001),A
  XOR A
  LD (ChCGlissCount+$0001),A
  LD L,A
  LD (ChCToneSlide+$0001),HL
  JP ChCTickEnd

; channel C's gliss counter reloaded
;
; As ChBGlissReload, for channel C. Not run in the window: known from the code
; only.
ChCGlissReload:
  LD A,$00
; This entry point is used by the routine at ChCMute.
ChCGlissStore:
  LD (ChCGlissCount+$0001),A
; This entry point is used by the routines at ChCMute and ChCPortaRun.
ChCTickEnd:
  EX AF,AF'
; This entry point is used by the routine at ChCMute.
ChCStoreVolume:
  LD (AyVolumeC),A
ChCOnOffCount:
  LD A,$00
  DEC A
  JP M,EnvSlideAcc
  JR NZ,ChCOnOffStore
  LD A,($C59F)
  XOR $FF
  LD (ChCMute+$0001),A
  JP Z,ChCOnTime
ChCOffTime:
  LD A,$00
  JP ChCOnOffStore
ChCOnTime:
  LD A,$00
ChCOnOffStore:
  LD (ChCOnOffCount+$0001),A

; The envelope: EnvPeriod (set by the row) + the samples' offsets (IYL, low
; byte only) + the slide ...
;
; The envelope: EnvPeriod (set by the row) + the samples' offsets (IYL, low
; byte only) + the slide (EnvSlideAcc, stepped by EnvSlideStep every
; EnvSlideReload frames: effect 8) into AyEnvPeriod.
EnvSlideAcc:
  LD DE,$0000
EnvPeriod:
  LD HL,$0000
  LD A,IYL
  ADD A,L
  LD L,A
  ADD HL,DE
  LD (AyEnvPeriod),HL
EnvSlideCount:
  LD A,$00
  DEC A
  JP M,PlaySp
  JR NZ,EnvSlideStore
EnvSlideStep:
  LD HL,$0000
  ADD HL,DE
  LD (EnvSlideAcc+$0001),HL
EnvSlideReload:
  LD A,$00
EnvSlideStore:
  LD (EnvSlideCount+$0001),A
PlaySp:
  LD SP,$0000

; the AY registers 0-12 from the block AyToneA at a page start (L = the
; register number; B = $FF ...
;
; the AY registers 0-12 from the block AyToneA at a page start (L = the
; register number; B = $FF selects, B = $BF writes): tones, noise (IXH +
; NoiseBase), mixer (IXL), volumes, envelope period; register 13 only when
; EnvType holds a new type (then cleared).
WriteAy:
  LD DE,$FFBF
  LD BC,$FFFD
  LD HL,AyToneA
  OUT (C),L
  LD B,E
  OUTI
  LD B,D
  OUT (C),L
  LD B,E
  OUTI
  LD B,D
  OUT (C),L
  LD B,E
  OUTI
  LD B,D
  OUT (C),L
  LD B,E
  OUTI
  LD B,D
  OUT (C),L
  LD B,E
  OUTI
  LD B,D
  OUT (C),L
  LD B,E
  OUTI
  LD B,D
  OUT (C),L
  LD A,IXH
  LD (NoiseMixer+$0003),A
NoiseBase:
  ADD A,$00
  LD B,E
  OUT (C),A
  INC L
  LD B,D
  OUT (C),L
  LD A,IXL
  LD B,E
  OUT (C),A
  INC L
  LD B,D
  OUT (C),L
  LD B,E
  OUTI
  LD B,D
  OUT (C),L
  LD B,E
  OUTI
  LD B,D
  OUT (C),L
  LD B,E
  OUTI
  LD B,D
  OUT (C),L
  LD B,E
  OUTI
  LD B,D
  OUT (C),L
  LD B,E
  OUTI
EnvType:
  LD A,$00
  OR A
  JR Z,RestoreIy
  LD B,D
  OUT (C),L
  LD B,E
  OUT (C),A
  XOR A
  LD (EnvType+$0001),A

; IY = $5C3A for the ROM's interrupt (Pt3Stop patches this opcode to RET)
;
; IY = $5C3A for the ROM's interrupt (Pt3Stop patches this opcode to RET). Then
; the row scheduler: RowFrame counts down from the delay: 2 -> channel A's row,
; 1 -> B's, 0 -> C's (and the staged A and B applied, RowFrame reloaded); above
; 2 nothing.
RestoreIy:
  LD IYL,$3A              ; IY back to the ROM's $5C3A (patched to RET by
                          ; Pt3Stop)
RowFrame:
  LD A,$03
  DEC A
  LD (RowFrame+$0001),A
  JP Z,ChCRowSkip
  DEC A
  JP Z,ChBRowSkip
  DEC A
  RET NZ

; Channel A's row (two frames before the row)
;
; Channel A's row (two frames before the row). First every staging JR / JP of A
; is set to skip (H, L, E, A: the displacements); unless ChARowSkip ran out,
; done. Else the skips go to the alternate set (EXX / EX AF,AF'), B' = 0: each
; decoded command clears its block's skip (H' note, L' volume, A' ornament /
; envelope, E' gliss / portamento), C' = the old note (portamento). A 0 at the
; row's start: the next position (PositionPtr, $FF -> LoopPositionPtr), its
; pattern's three channel pointers (+ the module address) into ChAPatternPtr,
; ChBPatternPtr, ChCPatternPtr, the noise base 0.
ChARowSkip:
  LD A,$01
  DEC A
  LD (ChARowSkip+$0001),A
  LD HL,$2D05
  LD E,$22
  LD B,A
  LD A,H
  LD (ChANewNoteJr+$0001),A
  LD A,L
  LD (ChAVolumeJr+$0001),A
  LD A,E
  LD (ChAGlissJr+$0001),A
  LD A,$17
  LD (ChAOrnEnvJr+$0001),A
  RET NZ
  EXX
  EX AF,AF'
ChAPatternPtr:
  LD DE,$0000
  LD A,(DE)
  AND A
  JR NZ,ChAReadRow
  LD (PositionSp+$0001),SP
PositionPtr:
  LD HL,$0000
  LD A,(HL)
  ADD A,A
  JR NC,PositionStep
LoopPositionPtr:
  LD HL,$0000
  LD A,(HL)
  ADD A,A
PositionStep:
  INC HL
  LD (PositionPtr+$0001),HL
  LD E,A
  XOR A
  LD (NewNoiseBase+$0001),A
  LD D,A
PatternTable:
  LD HL,$0000
  ADD HL,DE
  LD SP,HL
  POP HL
ModuleAddr:
  LD BC,$0000
  ADD HL,BC
  EX DE,HL
  POP HL
  ADD HL,BC
  LD (ChBPatternPtr+$0001),HL
  POP HL
  ADD HL,BC
  LD (ChCPatternPtr+$0001),HL
PositionSp:
  LD SP,$0000
ChAReadRow:
  CALL ChADecode
  LD (ChAPatternPtr+$0001),DE
ChARowSkipLen:
  LD A,$00
  LD (ChARowSkip+$0001),A
  EXX
  LD A,H
  LD (ChANewNoteJr+$0001),A
  LD A,L
  LD (ChAVolumeJr+$0001),A
  EX AF,AF'
  LD (ChAOrnEnvJr+$0001),A
  LD A,E
  LD (ChAGlissJr+$0001),A
  RET

; DE = channel A's bytes; decodes one row (the ranges in the module header
; above) into the staging operands; ...
;
; DE = channel A's bytes; decodes one row (the ranges in the module header
; above) into the staging operands; ends on a note, $D0 or $C0 (RET runs the
; pushed effect routines, which read their parameters from DE). Out: DE = the
; next row.
ChADecode:
  LD H,$C0

; B = $10, C = $20, then the next byte
;
; Re-entered by the commands that change the H register (sample, ornament): the
; range steps reloaded (331 entries in the window).
ChADecodeLimits:
  LD BC,$1020             ; B = $10, C = $20: the steps of the byte ranges

; the next byte of channel A's row through the ranges
;
; One byte of the row: ADD steps through the ranges (module header above) and
; jumps to its command; an effect number pushes its routine from ChAEffects
; (526 entries).
ChADecodeByte:
  LD A,(DE)
  INC DE
  ADD A,B
  JP C,ChAOrnSampleCmd
  ADD A,C
  JP C,ChASampleCmd
  ADD A,B
  JP C,ChAVolumeCmd
  ADD A,B
  JP C,ChAEnvCmd
  ADD A,$60
  JP C,ChANoteCmd
  ADD A,B
  JP C,ChAOrnamentCmd
  ADD A,$30
  JP C,ChAEnvSampleCmd
  ADD A,B
  ADD A,A
  ADD A,$BE
  LD L,A
  LD H,$C2
  LD A,(HL)
  INC L
  LD H,(HL)
  LD L,A
  PUSH HL
  LD A,($C41B)
  EXX
  LD C,A
  EXX
  JP ChADecodeByte

; Channel A's effects (ChAEffects), run after the row's note, DE at their
; parameters: ChAEffGliss ...
;
; Channel A's effects (ChAEffects), run after the row's note, DE at their
; parameters: ChAEffGliss (1): delay, step word; ChAEffPorta (2): delay,
; distance word, step word (the note stays the old one until the slide has
; covered the distance, then ChANewPortaNote); ChAEffSampleOffset (3),
; ChAEffOrnOffset (4): the start position; ChAEffOnOff (5): off frames, on
; frames. EffEnvSlide (8): delay, step word; EffDelay (9): the delay (shared by
; the channels).
ChAEffGliss:
  EX DE,HL
  LD A,(HL)
  LD (ChANewGlissDelay+$0001),A
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (ChANewGlissStep+$0001),DE
  LD A,$1F
  LD (ChANewPortaJr+$0001),A
  EX DE,HL
  EXX
  LD E,B
  EXX
  RET

; effect 2 on channel A: portamento
;
; DE at delay, distance word, step word: staged into ChANewGlissDelay,
; ChANewPortaDistance, ChANewGlissStep; ChANewPortaJr cleared (the tick runs
; ChAPortaRun); the new note kept in ChANewPortaNote and the old one (C')
; played until the slide arrives. Ran twice in the window (COOL WINTER uses
; portamento on channel A).
ChAEffPorta:
  EX DE,HL
  LD A,(HL)
  LD (ChANewGlissDelay+$0001),A
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (ChANewPortaDistance+$0001),DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (ChANewGlissStep+$0001),DE
  XOR A
  LD (ChANewPortaJr+$0001),A
  LD A,($CB3B)
  LD (ChANewPortaNote+$0001),A
  EXX
  LD A,C
  LD E,B
  EXX
  LD (ChANewNote+$0001),A
  EX DE,HL
  RET

; effect 3 on channel A: the sample's start position
;
; The position byte into ChANewSamplePos; ChASampleOffJp retargeted to it, so
; the once-only block runs on the row's frame. Not run in the window: known
; from the code only.
ChAEffSampleOffset:
  LD A,(DE)
  INC DE
  LD (ChANewSamplePos+$0001),A
  LD A,$50
  LD (ChASampleOffJp+$0001),A
  RET

; effect 4 on channel A: the ornament's start position
;
; The position byte into ChANewOrnamentPos; ChAOrnOffJp retargeted to it, so
; the once-only block runs on the row's frame. Not run in the window: known
; from the code only.
ChAEffOrnOffset:
  LD A,(DE)
  INC DE
  LD (ChANewOrnamentPos+$0001),A
  LD A,$5D
  LD (ChAOrnOffJp+$0001),A
  RET

; effect 5 on channel A: on-off
;
; DE at off frames, on frames: staged into ChANewOffTime / ChANewOnTime;
; ChAOnOffJp retargeted to ChAOnOffApply. Not run in the window: known from the
; code only.
ChAEffOnOff:
  LD A,(DE)
  LD (ChANewOffTime+$0001),A
  INC DE
  LD A,(DE)
  INC DE
  LD (ChANewOnTime+$0001),A
  LD A,$8C
  LD (ChAOnOffJp+$0001),A
  RET

; effect 8 (any channel): the envelope slide
;
; DE at delay, step word: into NewEnvSlideDelay / NewEnvSlideStep; EnvSlideJr
; cleared so NewEnvSlideStep runs once on the row's frame. Not run in the
; window: known from the code only.
EffEnvSlide:
  EX DE,HL
  LD A,(HL)
  LD (NewEnvSlideDelay+$0001),A
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (NewEnvSlideStep+$0001),DE
  EX DE,HL
  XOR A
  LD (EnvSlideJr+$0001),A
  RET

; effect 9 (any channel): the tune's delay
;
; The byte at DE into Delay, the frames per row from the next row on. Not run
; in the window: known from the code only.
EffDelay:
  LD A,(DE)
  INC DE
  LD (Delay+$0001),A
  RET

; Channel A's commands (the jumps of ChADecodeByte; A = the byte less the
; range's start): the sample ...
;
; Channel A's commands (the jumps of ChADecodeByte; A = the byte less the
; range's start): the sample and ornament numbers index SamplePtrs /
; OrnamentPtrs by the low byte (H = HIGH SamplePtrs).
ChAOrnSampleCmd:
  ADD A,A
  ADD A,$E0
  LD L,A
  LD C,(HL)
  INC L
  LD B,(HL)
  LD (ChANewOrnament+$0001),BC
  LD A,(DE)
  INC DE
  ADD A,$A0
  LD L,A
  LD C,(HL)
  INC L
  LD B,(HL)
  LD (ChANewSample+$0001),BC
  XOR A
  EX AF,AF'
  LD A,$0F
  LD (ChANewEnvMask+$0001),A
  JP ChADecodeLimits

; $D0-$EF on channel A: the row's end ($D0) or a sample
;
; Z ($D0): the row ends with nothing new (ChARowEnd); else the sample's pointer
; from SamplePtrs into ChANewSample, then ChADecodeLimits (54 entries).
ChASampleCmd:
  JR Z,ChARowEnd
  ADD A,A
  ADD A,$A0
  LD L,A
  LD C,(HL)
  INC L
  LD B,(HL)
  LD (ChANewSample+$0001),BC
  JP ChADecodeLimits
ChARowEnd:
  RET
; This entry point is used by the routine at ChAVolumeCmd.
ChASoundOff:
  LD A,$2F
  LD (ChANoteOnOp),A
  EXX
  LD H,B
  EXX
  RET
; This entry point is used by the routine at ChAEnvCmd.
ChAEnvOff:
  EX AF,AF'
  LD A,$0F
  LD (ChANewEnvMask+$0001),A
  JP ChADecodeByte
; This entry point is used by the routine at ChAEnvCmd.
ChASkipCmd:
  LD A,(DE)
  INC DE
  LD (ChARowSkipLen+$0001),A
  JP ChADecodeByte

; $C0-$CF on channel A: sound off or the channel volume
;
; Z ($C0): ChASoundOff; else volume * 16 into ChANewVolume (a row of
; VolumeTable), L' = 0 clears the volume block's skip (127 entries).
ChAVolumeCmd:
  JR Z,ChASoundOff
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  LD (ChANewVolume+$0001),A
  EXX
  LD L,B
  EXX
  JP ChADecodeByte

; $B0-$BF on channel A: envelope off, row skip, or an envelope
;
; $B0: ChAEnvOff; $B1: ChASkipCmd; else the envelope type and its period (2
; bytes, high first) into NewEnvType / NewEnvPeriod, the envelope mask on (66
; entries).
ChAEnvCmd:
  JR Z,ChAEnvOff
  DEC A
  JR Z,ChASkipCmd
  LD (NewEnvType+$0001),A
  LD A,(DE)
  INC DE
  LD (NewEnvPeriod+$0002),A
  LD A,(DE)
  INC DE
  LD (NewEnvPeriod+$0001),A
  LD A,$1F
  LD (ChANewEnvMask+$0001),A
  XOR A
  EX AF,AF'
  JP ChADecodeByte

; $50-$AF on channel A: a note, the row ends
;
; The note into ChANewNote, ChANoteOnOp = NOP (sounds), H' = 0 clears the note
; block's skip; RET runs any pushed effect (247 entries).
ChANoteCmd:
  LD (ChANewNote+$0001),A
  XOR A
  LD (ChANoteOnOp),A
  EXX
  LD H,B
  EXX
  RET

; $40-$4F on channel A: an ornament
;
; The ornament's pointer from OrnamentPtrs into ChANewOrnament, A' = 0 (the
; ornament block runs), then ChADecodeLimits (20 entries).
ChAOrnamentCmd:
  ADD A,A
  ADD A,$E0
  LD L,A
  LD C,(HL)
  INC L
  LD B,(HL)
  LD (ChANewOrnament+$0001),BC
  XOR A
  EX AF,AF'
  JP ChADecodeLimits
ChAEnvOffSample:
  LD A,$0F
  LD (ChANewEnvMask+$0001),A
  JP ChAEnvSampleSet
; This entry point is used by the routine at ChADecodeByte.
ChAEnvSampleCmd:
  JR Z,ChAEnvOffSample
  LD (NewEnvType+$0001),A
  LD A,(DE)
  INC DE
  LD (NewEnvPeriod+$0002),A
  LD A,(DE)
  INC DE
  LD (NewEnvPeriod+$0001),A
  LD A,$1F
  LD (ChANewEnvMask+$0001),A
ChAEnvSampleSet:
  XOR A
  EX AF,AF'
  LD A,(DE)
  INC DE
  ADD A,$A0
  LD L,A
  LD C,(HL)
  INC L
  LD B,(HL)
  LD (ChANewSample+$0001),BC
  JP ChADecodeLimits

; Channel B's row (one frame before the row): as channel A's (ChARowSkip),
; without the positions
;
; Channel B's row (one frame before the row): as channel A's (ChARowSkip),
; without the positions.
ChBRowSkip:
  LD A,$01
  DEC A
  LD (ChBRowSkip+$0001),A
  LD HL,$2D05
  LD E,$22
  LD B,A
  LD A,H
  LD (ChBNewNoteJr+$0001),A
  LD A,L
  LD (ChBVolumeJr+$0001),A
  LD A,E
  LD (ChBGlissJr+$0001),A
  LD A,$17
  LD (ChBOrnEnvJr+$0001),A
  RET NZ
  EXX
  EX AF,AF'
ChBPatternPtr:
  LD DE,$0000
  CALL ChBDecode
  LD (ChBPatternPtr+$0001),DE
ChBRowSkipLen:
  LD A,$00
  LD (ChBRowSkip+$0001),A
  EXX
  LD A,H
  LD (ChBNewNoteJr+$0001),A
  LD A,L
  LD (ChBVolumeJr+$0001),A
  EX AF,AF'
  LD (ChBOrnEnvJr+$0001),A
  LD A,E
  LD (ChBGlissJr+$0001),A
  RET

; as ChADecode; channel B also takes $20-$3F, the noise base (ChBNoiseCmd)
;
; as ChADecode; channel B also takes $20-$3F, the noise base (ChBNoiseCmd).
ChBDecode:
  LD H,$C0

; as ChADecodeLimits, for channel B
;
; 87 entries in the window.
ChBDecodeLimits:
  LD BC,$1020

; as ChADecodeByte, for channel B
;
; 101 entries in the window.
ChBDecodeByte:
  LD A,(DE)
  INC DE
  ADD A,B
  JP C,ChBOrnSampleCmd
  ADD A,C
  JP C,ChBSampleCmd
  ADD A,B
  JP C,ChBVolumeCmd
  ADD A,B
  JP C,ChBEnvCmd
  ADD A,$60
  JP C,ChBNoteCmd
  ADD A,B
  JP C,ChBOrnamentCmd
  ADD A,C
  JP C,ChBNoiseCmd
  ADD A,B
  JP C,ChBEnvSampleCmd
  ADD A,B
  ADD A,A
  ADD A,$D0
  LD L,A
  LD H,$C2
  LD A,(HL)
  INC L
  LD H,(HL)
  LD L,A
  PUSH HL
  LD A,($C53A)
  EXX
  LD C,A
  EXX
  JP ChBDecodeByte

; Channel B's effects (ChBEffects): as channel A's
;
; Channel B's effects (ChBEffects): as channel A's. ChBEffOnOff's jump is wrong
; (the known bug in the module header).
ChBEffGliss:
  EX DE,HL
  LD A,(HL)
  LD (ChBNewGlissDelay+$0001),A
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (ChBNewGlissStep+$0001),DE
  LD A,$1F
  LD (ChBNewPortaJr+$0001),A
  EX DE,HL
  EXX
  LD E,B
  EXX
  RET

; effect 2 on channel B: portamento
;
; As ChAEffPorta, into channel B's staging. Not run in the window: known from
; the code only.
ChBEffPorta:
  EX DE,HL
  LD A,(HL)
  LD (ChBNewGlissDelay+$0001),A
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (ChBNewPortaDistance+$0001),DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (ChBNewGlissStep+$0001),DE
  XOR A
  LD (ChBNewPortaJr+$0001),A
  LD A,($CBCC)
  LD (ChBNewPortaNote+$0001),A
  EXX
  LD A,C
  LD E,B
  EXX
  LD (ChBNewNote+$0001),A
  EX DE,HL
  RET

; effect 3 on channel B: the sample's start position
;
; As ChAEffSampleOffset, through ChBSampleOffJp to ChBNewSamplePos. Not run in
; the window: known from the code only.
ChBEffSampleOffset:
  LD A,(DE)
  INC DE
  LD (ChBNewSamplePos+$0001),A
  LD A,$6A
  LD (ChBSampleOffJp+$0001),A
  RET

; effect 4 on channel B: the ornament's start position
;
; As ChAEffOrnOffset, through ChBOrnOffJp to ChBNewOrnamentPos. Not run in the
; window: known from the code only.
ChBEffOrnOffset:
  LD A,(DE)
  INC DE
  LD (ChBNewOrnamentPos+$0001),A
  LD A,$77
  LD (ChBOrnOffJp+$0001),A
  RET

; effect 5 on channel B: on-off (with the known bug)
;
; As ChAEffOnOff, but the byte written into ChBOnOffJp is LOW ChBOnOffJp ($1A),
; not LOW ChBNewOnTime ($1D): the staged JP would jump to itself and the player
; would hang (the bug in the module header). Not run in the window: known from
; the code only.
ChBEffOnOff:
  LD A,(DE)
  LD (ChBNewOffTime+$0001),A
  INC DE
  LD A,(DE)
  INC DE
  LD (ChBNewOnTime+$0001),A
  LD A,$1A                ; BUG: the JP's own address (LOW ChBNewOnTime meant)
  LD (ChBOnOffJp+$0001),A
  RET

; Channel B's commands: as channel A's; ChBNoiseCmd: the noise base for the row
;
; Channel B's commands: as channel A's; ChBNoiseCmd: the noise base for the
; row.
ChBNoiseCmd:
  LD (NewNoiseBase+$0001),A
  JP ChBDecodeByte

; as ChAOrnSampleCmd, for channel B
;
; 7 entries in the window.
ChBOrnSampleCmd:
  ADD A,A
  ADD A,$E0
  LD L,A
  LD C,(HL)
  INC L
  LD B,(HL)
  LD (ChBNewOrnament+$0001),BC
  LD A,(DE)
  INC DE
  ADD A,$A0
  LD L,A
  LD C,(HL)
  INC L
  LD B,(HL)
  LD (ChBNewSample+$0001),BC
  XOR A
  EX AF,AF'
  LD A,$0F
  LD (ChBNewEnvMask+$0001),A
  JP ChBDecodeLimits
; This entry point is used by the routine at ChBDecodeByte.
ChBSampleCmd:
  JR Z,ChBRowEnd
  ADD A,A
  ADD A,$A0
  LD L,A
  LD C,(HL)
  INC L
  LD B,(HL)
  LD (ChBNewSample+$0001),BC
  JP ChBDecodeLimits
ChBRowEnd:
  RET
; This entry point is used by the routine at ChBVolumeCmd.
ChBSoundOff:
  LD A,$2F
  LD (ChBNoteOnOp),A
  EXX
  LD H,B
  EXX
  RET
; This entry point is used by the routine at ChBEnvCmd.
ChBEnvOff:
  EX AF,AF'
  LD A,$0F
  LD (ChBNewEnvMask+$0001),A
  JP ChBDecodeByte
; This entry point is used by the routine at ChBEnvCmd.
ChBSkipCmd:
  LD A,(DE)
  INC DE
  LD (ChBRowSkipLen+$0001),A
  JP ChBDecodeByte

; as ChAVolumeCmd, for channel B
;
; 7 entries in the window.
ChBVolumeCmd:
  JR Z,ChBSoundOff
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  LD (ChBNewVolume+$0001),A
  EXX
  LD L,B
  EXX
  JP ChBDecodeByte

; as ChAEnvCmd, for channel B
;
; 7 entries in the window.
ChBEnvCmd:
  JR Z,ChBEnvOff
  DEC A
  JR Z,ChBSkipCmd
  LD (NewEnvType+$0001),A
  LD A,(DE)
  INC DE
  LD (NewEnvPeriod+$0002),A
  LD A,(DE)
  INC DE
  LD (NewEnvPeriod+$0001),A
  LD A,$1F
  LD (ChBNewEnvMask+$0001),A
  XOR A
  EX AF,AF'
  JP ChBDecodeByte

; as ChANoteCmd, for channel B
;
; 54 entries in the window.
ChBNoteCmd:
  LD (ChBNewNote+$0001),A
  XOR A
  LD (ChBNoteOnOp),A
  EXX
  LD H,B
  EXX
  RET

; as ChAOrnamentCmd, for channel B
;
; 26 entries in the window.
ChBOrnamentCmd:
  ADD A,A
  ADD A,$E0
  LD L,A
  LD C,(HL)
  INC L
  LD B,(HL)
  LD (ChBNewOrnament+$0001),BC
  XOR A
  EX AF,AF'
  JP ChBDecodeLimits
ChBEnvOffSample:
  LD A,$0F
  LD (ChBNewEnvMask+$0001),A
  JP ChBEnvSampleSet
; This entry point is used by the routine at ChBDecodeByte.
ChBEnvSampleCmd:
  JR Z,ChBEnvOffSample
  LD (NewEnvType+$0001),A
  LD A,(DE)
  INC DE
  LD (NewEnvPeriod+$0002),A
  LD A,(DE)
  INC DE
  LD (NewEnvPeriod+$0001),A
  LD A,$1F
  LD (ChBNewEnvMask+$0001),A
ChBEnvSampleSet:
  XOR A
  EX AF,AF'
  LD A,(DE)
  INC DE
  ADD A,$A0
  LD L,A
  LD C,(HL)
  INC L
  LD B,(HL)
  LD (ChBNewSample+$0001),BC
  JP ChBDecodeLimits

; Channel C's row (on the row's frame): decoded straight into the tick's
; operands (ChCDecode), then ...
;
; Channel C's row (on the row's frame): decoded straight into the tick's
; operands (ChCDecode), then the staged rows of A and B applied (from
; ChANewNoteJr), the envelope, the delay.
ChCRowSkip:
  LD A,$01
  DEC A
  LD (ChCRowSkip+$0001),A
  JP NZ,ChANewNoteJr
ChCPatternPtr:
  LD DE,$0000
  CALL ChCDecode
  LD (ChCPatternPtr+$0001),DE
ChCRowSkipLen:
  LD A,$00
  LD (ChCRowSkip+$0001),A

; The staged row of channel A, applied after channel C's decode
;
; The staged row of channel A, applied after channel C's decode. Each block is
; skipped by its JR unless the decoder cleared the displacement: ChANewNoteJr:
; a note or sound off: the tick's state cleared (slides, positions,
; accumulators), ChANoteOnOp (NOP: the note sounds, CPL: muted), ChANewNote,
; ChANewSample; ChAVolumeJr: the channel volume (ChANewVolume = volume * 16, a
; row of VolumeTable); ChAOrnEnvJr: ornament or envelope: the ornament from its
; start, the envelope slide cleared, ChANewOrnament, ChANewEnvMask; ChAGlissJr:
; gliss / portamento (delay, distance, step, the JR of the tick's test);
; ChAOnOffJp: the on-off effect (JP to ChAOnOffApply, which sets the JP back to
; skip).
ChANewNoteJr:
  JR ChAVolumeJr
  XOR A
  LD (ChAEnvOffsetAcc+$0001),A
  LD (ChAGlissCount+$0001),A
  LD (ChASamplePos+$0001),A
  LD (ChAOrnamentPos+$0001),A
  LD (ChANoiseAcc+$0001),A
  LD (ChAVolSlide+$0001),A
  LD (ChAOnOffCount+$0001),A
  LD H,A
  LD L,A
  LD (ChAToneSlide+$0001),HL
  LD (ChAToneAcc+$0001),HL
ChANoteOnOp:
  CPL
  LD (ChAMute+$0001),A
ChANewNote:
  LD A,$00
  LD (ChANote+$0001),A
ChANewSample:
  LD HL,$0000
  LD (ChASamplePtr+$0001),HL
ChAVolumeJr:
  JR ChAOrnEnvJr
ChANewVolume:
  LD A,$00
  LD (ChAVolume+$0001),A
ChAOrnEnvJr:
  JR ChAGlissJr
  XOR A
  LD (ChAOrnamentPos+$0001),A
  LD L,A
  LD H,A
  LD (EnvSlideAcc+$0001),HL
  LD (EnvSlideCount+$0001),A
ChANewOrnament:
  LD HL,$0000
  LD (ChAOrnamentPtr+$0001),HL
ChANewEnvMask:
  LD A,$00
  LD (ChAEnvMask+$0001),A
ChAGlissJr:
  JR ChAOnOffJp
ChANewPortaNote:
  LD A,$00
  LD (ChAPortaNote+$0001),A
ChANewGlissDelay:
  LD A,$00
  LD (ChAGlissCount+$0001),A
  LD (ChAGlissReload+$0001),A
ChANewPortaDistance:
  LD HL,$0000
  LD (ChAPortaDistance+$0001),HL
ChANewGlissStep:
  LD HL,$0000
  LD (ChAGlissStep+$0001),HL
ChANewPortaJr:
  LD A,$00
  LD (ChAPortaJr+$0001),A
  XOR A
  LD (ChAOnOffCount+$0001),A
ChAOnOffJp:
  JP ChBNewNoteJr

; channel A's on-off effect applied once
;
; Entered through ChAOnOffJp when ChAEffOnOff set it: the gliss and the slide
; cleared, ChAOnOffJp set back to skip, the on and off times (ChANewOnTime,
; ChANewOffTime) into the tick, the counter at the on time. Not run in the
; window: known from the code only.
ChAOnOffApply:
  XOR A
  LD (ChAGlissCount+$0001),A
  LD L,A
  LD H,A
  LD (ChAToneSlide+$0001),HL
  LD A,$A7                ; this block runs once: skip it again
  LD (ChAOnOffJp+$0001),A
ChANewOnTime:
  LD A,$00
  LD (ChAOnTime+$0001),A
  LD (ChAOnOffCount+$0001),A
ChANewOffTime:
  LD A,$00
  LD (ChAOffTime+$0001),A

; The staged row of channel B: as channel A's
;
; The staged row of channel B: as channel A's.
ChBNewNoteJr:
  JR ChBVolumeJr
  XOR A
  LD (ChBEnvOffsetAcc+$0001),A
  LD (ChBGlissCount+$0001),A
  LD (ChBSamplePos+$0001),A
  LD (ChBOrnamentPos+$0001),A
  LD (ChBNoiseAcc+$0001),A
  LD (ChBVolSlide+$0001),A
  LD (ChBOnOffCount+$0001),A
  LD H,A
  LD L,A
  LD (ChBToneSlide+$0001),HL
  LD (ChBToneAcc+$0001),HL
ChBNoteOnOp:
  CPL
  LD (ChBMute+$0001),A
ChBNewNote:
  LD A,$00
  LD (ChBNote+$0001),A
ChBNewSample:
  LD HL,$0000
  LD (ChBSamplePtr+$0001),HL
ChBVolumeJr:
  JR ChBOrnEnvJr
ChBNewVolume:
  LD A,$00
  LD (ChBVolume+$0001),A
ChBOrnEnvJr:
  JR ChBGlissJr
  XOR A
  LD (ChBOrnamentPos+$0001),A
  LD L,A
  LD H,A
  LD (EnvSlideAcc+$0001),HL
  LD (EnvSlideCount+$0001),A
ChBNewOrnament:
  LD HL,$0000
  LD (ChBOrnamentPtr+$0001),HL
ChBNewEnvMask:
  LD A,$00
  LD (ChBEnvMask+$0001),A
ChBGlissJr:
  JR ChBOnOffJp

; channel B's staged gliss / portamento block
;
; Run when ChBGlissJr's displacement was cleared by a gliss or portamento row:
; the porta note, delay, distance, step and the JR of the tick's test
; (ChBNewPortaJr) into channel B's tick. Not run in the window: known from the
; code only.
ChBNewPortaNote:
  LD A,$00
  LD (ChBPortaNote+$0001),A
ChBNewGlissDelay:
  LD A,$00
  LD (ChBGlissCount+$0001),A
  LD (ChBGlissReload+$0001),A
ChBNewPortaDistance:
  LD HL,$0000
  LD (ChBPortaDistance+$0001),HL
ChBNewGlissStep:
  LD HL,$0000
  LD (ChBGlissStep+$0001),HL
ChBNewPortaJr:
  LD A,$00
  LD (ChBPortaJr+$0001),A
  XOR A
  LD (ChBOnOffCount+$0001),A

; channel B's on-off jump: JP EnvSlideJr unless set
;
; Its low byte is the target: EnvSlideJr normally (431 entries, every row of
; the window); ChBEffOnOff writes LOW ChBOnOffJp ($1A) here instead of LOW
; ChBNewOnTime, so the JP would jump to itself (the known bug in the module
; header).
ChBOnOffJp:
  JP EnvSlideJr

; channel B's on-off effect applied once (never reached, see ChBOnOffJp)
;
; As ChAOnOffApply for channel B; ChBEffOnOff's bug means no row can reach it.
; Not run in the window: known from the code only.
ChBNewOnTime:
  LD A,$00
  LD (ChBOnTime+$0001),A
  LD (ChBOnOffCount+$0001),A
ChBNewOffTime:
  LD A,$00
  LD (ChBOffTime+$0001),A
  XOR A
  LD (ChBGlissCount+$0001),A
  LD L,A
  LD H,A
  LD (ChBToneSlide+$0001),HL
  LD A,$38                ; this block runs once: skip it again
  LD (ChBOnOffJp+$0001),A

; Once-only blocks, entered when a row set them (their JR / JP retargeted, the
; block retargets it ...
;
; Once-only blocks, entered when a row set them (their JR / JP retargeted, the
; block retargets it back): the envelope slide (EnvSlideJr), the sample and
; ornament offsets of A and B (ChASampleOffJp ...). Then the row's envelope
; (NewEnvType: 0 = none, NewEnvPeriod), RowFrame reloaded with Delay, the noise
; base, RowCounter + 1 (the rows played, from 0).
EnvSlideJr:
  JR ChASampleOffJp

; the envelope slide set up once (effect 8)
;
; Entered when EffEnvSlide cleared EnvSlideJr: the step and the delay into
; EnvSlideStep, EnvSlideCount, EnvSlideReload, EnvSlideJr set back to skip. Not
; run in the window: known from the code only.
NewEnvSlideStep:
  LD HL,$0000
  LD (EnvSlideStep+$0001),HL
NewEnvSlideDelay:
  LD A,$00
  LD (EnvSlideCount+$0001),A
  LD (EnvSlideReload+$0001),A
  LD A,$13                ; this block runs once: skip it again
  LD (EnvSlideJr+$0001),A

; the once-only jumps: channel A's sample offset unless set
;
; JP ChAOrnOffJp normally (431 entries); ChAEffSampleOffset retargets it to
; ChANewSamplePos.
ChASampleOffJp:
  JP ChAOrnOffJp

; channel A's sample position set once (effect 3)
;
; The position into ChASamplePos, ChASampleOffJp set back to skip. Not run in
; the window: known from the code only.
ChANewSamplePos:
  LD A,$00
  LD (ChASamplePos+$0001),A
  LD A,$5A
  LD (ChASampleOffJp+$0001),A

; channel A's ornament offset unless set
;
; JP ChBSampleOffJp normally (431 entries); ChAEffOrnOffset retargets it to
; ChANewOrnamentPos.
ChAOrnOffJp:
  JP ChBSampleOffJp

; channel A's ornament position set once (effect 4)
;
; The position into ChAOrnamentPos, ChAOrnOffJp set back to skip. Not run in
; the window: known from the code only.
ChANewOrnamentPos:
  LD A,$00
  LD (ChAOrnamentPos+$0001),A
  LD A,$67
  LD (ChAOrnOffJp+$0001),A

; channel B's sample offset unless set
;
; JP ChBOrnOffJp normally (431 entries); ChBEffSampleOffset retargets it to
; ChBNewSamplePos.
ChBSampleOffJp:
  JP ChBOrnOffJp

; channel B's sample position set once (effect 3)
;
; As ChANewSamplePos, for channel B. Not run in the window: known from the code
; only.
ChBNewSamplePos:
  LD A,$00
  LD (ChBSamplePos+$0001),A
  LD A,$74
  LD (ChBSampleOffJp+$0001),A

; channel B's ornament offset unless set
;
; JP NewEnvType normally (431 entries); ChBEffOrnOffset retargets it to
; ChBNewOrnamentPos.
ChBOrnOffJp:
  JP NewEnvType

; channel B's ornament position set once (effect 4)
;
; As ChANewOrnamentPos, for channel B. Not run in the window: known from the
; code only.
ChBNewOrnamentPos:
  LD A,$00
  LD (ChBOrnamentPos+$0001),A
  LD A,$81
  LD (ChBOrnOffJp+$0001),A

; the row's end: envelope, delay, noise base, row counter
;
; The envelope type the row set (0 = none) into EnvType and, if any,
; NewEnvPeriod into EnvPeriod; RowFrame reloaded from Delay, the noise base,
; RowCounter + 1 (431 entries: the rows of the window).
NewEnvType:
  LD A,$00
  LD (EnvType+$0001),A
  AND A
  JR Z,Delay
NewEnvPeriod:
  LD HL,$0000
  LD (EnvPeriod+$0001),HL
  XOR A
  LD (NewEnvType+$0001),A
Delay:
  LD A,$03
  LD (RowFrame+$0001),A
NewNoiseBase:
  LD A,$00
  LD (NoiseBase+$0001),A
RowCounter:
  LD HL,$FFFF
  INC HL
  LD (RowCounter+$0001),HL
  RET

; as ChADecode, but into channel C's tick at once (no staging)
;
; as ChADecode, but into channel C's tick at once (no staging).
ChCDecode:
  LD H,$C0

; as ChADecodeLimits, for channel C
;
; 578 entries in the window.
ChCDecodeLimits:
  LD BC,$1020

; as ChADecodeByte, for channel C
;
; 598 entries in the window.
ChCDecodeByte:
  LD A,(DE)
  INC DE
  ADD A,B
  JP C,ChCOrnSampleCmd
  ADD A,C
  JP C,ChCSampleCmd
  ADD A,B
  JP C,ChCVolumeCmd
  ADD A,B
  JP C,ChCEnvCmd
  ADD A,$60
  JP C,ChCNoteCmd
  ADD A,B
  JP C,ChCOrnamentCmd
  ADD A,$30
  JP C,ChCEnvSampleCmd
  ADD A,B
  ADD A,A
  ADD A,$E2
  LD L,A
  LD H,$C2
  LD A,(HL)
  INC L
  LD H,(HL)
  LD L,A
  PUSH HL
  LD A,($C658)
  EXX
  LD C,A
  EXX
  JP ChCDecodeByte

; Channel C's effects (ChCEffects): as channel A's, applied at once
;
; Channel C's effects (ChCEffects): as channel A's, applied at once.
ChCEffGliss:
  EX DE,HL
  LD A,(HL)
  LD (ChCGlissCount+$0001),A
  LD (ChCGlissReload+$0001),A
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (ChCGlissStep+$0001),DE
  LD A,$1F
  LD (ChCPortaJr+$0001),A
  XOR A
  LD (ChCOnOffCount+$0001),A
  EX DE,HL
  RET

; effect 2 on channel C: portamento, applied at once
;
; As ChAEffPorta, but straight into channel C's tick (ChCGlissCount,
; ChCGlissReload, ChCPortaDistance, ...). Not run in the window: known from the
; code only.
ChCEffPorta:
  EX DE,HL
  LD A,(HL)
  LD (ChCGlissCount+$0001),A
  LD (ChCGlissReload+$0001),A
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (ChCPortaDistance+$0001),DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (ChCGlissStep+$0001),DE
  XOR A
  LD (ChCOnOffCount+$0001),A
  LD (ChCPortaJr+$0001),A
  LD A,($C658)
  LD (ChCPortaNote+$0001),A
  EXX
  LD A,C
  EXX
  LD (ChCNote+$0001),A
  EX DE,HL
  RET

; effect 3 on channel C: the sample's start position, at once
;
; The position byte straight into ChCSamplePos (channel C has no staging). Not
; run in the window: known from the code only.
ChCEffSampleOffset:
  LD A,(DE)
  INC DE
  LD (ChCSamplePos+$0001),A
  RET

; effect 4 on channel C: the ornament's start position, at once
;
; The position byte straight into ChCOrnamentPos. Not run in the window: known
; from the code only.
ChCEffOrnOffset:
  LD A,(DE)
  INC DE
  LD (ChCOrnamentPos+$0001),A
  RET

; effect 5 on channel C: on-off, at once
;
; Off and on frames straight into ChCOffTime / ChCOnTime, the counter at the on
; time, the gliss and the slide cleared. Not run in the window: known from the
; code only.
ChCEffOnOff:
  LD A,(DE)
  LD (ChCOffTime+$0001),A
  INC DE
  LD A,(DE)
  INC DE
  LD (ChCOnTime+$0001),A
  LD (ChCOnOffCount+$0001),A
  XOR A
  LD (ChCGlissCount+$0001),A
  LD L,A
  LD H,A
  LD (ChCToneSlide+$0001),HL
  RET

; Channel C's commands: as channel A's, applied at once (ChCNoteCmd clears the
; tick's state)
;
; Channel C's commands: as channel A's, applied at once (ChCNoteCmd clears the
; tick's state).
ChCOrnSampleCmd:
  ADD A,A
  ADD A,$E0
  LD L,A
  LD C,(HL)
  INC L
  LD B,(HL)
  LD (ChCOrnamentPtr+$0001),BC
  LD A,(DE)
  INC DE
  ADD A,$A0
  LD L,A
  LD C,(HL)
  INC L
  LD B,(HL)
  LD (ChCSamplePtr+$0001),BC
  XOR A
  LD (ChCOrnamentPos+$0001),A
  LD A,$0F
  LD (ChCEnvMask+$0001),A
  JP ChCDecodeLimits

; as ChASampleCmd, applied to channel C at once
;
; 1 entry in the window.
ChCSampleCmd:
  JR Z,ChCRowEnd
  ADD A,A
  ADD A,$A0
  LD L,A
  LD C,(HL)
  INC L
  LD B,(HL)
  LD (ChCSamplePtr+$0001),BC
  JP ChCDecodeLimits
ChCRowEnd:
  RET
; This entry point is used by the routine at ChCVolumeCmd.
ChCSoundOff:
  LD A,$FF
  LD (ChCMute+$0001),A
  LD (ChCOnOffCount+$0001),A
  RET
; This entry point is used by the routine at ChCEnvCmd.
ChCEnvOff:
  LD A,$0F
  LD (ChCEnvMask+$0001),A
  JP ChCDecodeByte
; This entry point is used by the routine at ChCEnvCmd.
ChCSkipCmd:
  LD A,(DE)
  INC DE
  LD (ChCRowSkipLen+$0001),A
  JP ChCDecodeByte

; as ChAVolumeCmd, applied to channel C at once
;
; 1 entry in the window.
ChCVolumeCmd:
  JR Z,ChCSoundOff
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  LD (ChCVolume+$0001),A
  JP ChCDecodeByte

; as ChAEnvCmd, applied to channel C at once
;
; 20 entries in the window.
ChCEnvCmd:
  JR Z,ChCEnvOff
  DEC A
  JR Z,ChCSkipCmd
  LD (NewEnvType+$0001),A
  LD A,(DE)
  INC DE
  LD (NewEnvPeriod+$0002),A
  LD A,(DE)
  INC DE
  LD (NewEnvPeriod+$0001),A
  LD A,$1F
  LD (ChCEnvMask+$0001),A
  JP ChCDecodeByte

; as ChANoteCmd: the note into channel C's tick, its state cleared
;
; 391 entries in the window.
ChCNoteCmd:
  LD (ChCNote+$0001),A
  XOR A
  LD (ChCEnvOffsetAcc+$0001),A
  LD (ChCOrnamentPos+$0001),A
  LD (ChCMute+$0001),A
  LD (ChCSamplePos+$0001),A
  LD (ChCGlissCount+$0001),A
  LD (ChCOnOffCount+$0001),A
  LD (ChCVolSlide+$0001),A
  LD (ChCNoiseAcc+$0001),A
  LD H,A
  LD L,A
  LD (ChCToneSlide+$0001),HL
  LD (ChCToneAcc+$0001),HL
  RET
; This entry point is used by the routine at ChCDecodeByte.
ChCOrnamentCmd:
  ADD A,A
  ADD A,$E0
  LD L,A
  LD C,(HL)
  INC L
  LD B,(HL)
  LD (ChCOrnamentPtr+$0001),BC
  XOR A
  LD (ChCOrnamentPos+$0001),A
  JP ChCDecodeLimits
ChCEnvOffSample:
  LD A,$0F
  LD (ChCEnvMask+$0001),A
  JP ChCEnvSampleSet
; This entry point is used by the routine at ChCDecodeByte.
ChCEnvSampleCmd:
  JR Z,ChCEnvOffSample
  LD (NewEnvType+$0001),A
  LD A,(DE)
  INC DE
  LD (NewEnvPeriod+$0002),A
  LD A,(DE)
  INC DE
  LD (NewEnvPeriod+$0001),A
  LD A,$1F
  LD (ChCEnvMask+$0001),A
ChCEnvSampleSet:
  LD A,(DE)
  INC DE
  ADD A,$A0
  LD L,A
  LD C,(HL)
  INC L
  LD B,(HL)
  LD (ChCSamplePtr+$0001),BC
  JP ChCDecodeLimits
