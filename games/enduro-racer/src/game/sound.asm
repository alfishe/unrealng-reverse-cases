; --------------------------------------------------------------------------------------------------------------------
; sound.asm: Sound: the AY tunes, the effects, the engine on the beeper or the AY
;
; The AY plays a two-channel tune in play, tune 1 on odd stages and tune 2 on even ones (SetTune), switched only at a
; $CA mark of the tune (TuneMark). The code writes the AY ports on the 48K too, where nothing answers (c1: the writes;
; m128: the AY's registers move). PlayChannel reads a channel's byte stream: a note is a length byte below $C8 then
; the note byte (low nibble 1-12 a semitone of NoteTable, 0 a rest; high nibble plus the channel's transpose: how many
; times the period is halved); commands: $C9 restart, $CA the mark, $FE n repeat n times, $FD the repeat's end, $FC
; addr a call, $FB return, any other byte a count of AY pairs inline (no tune uses that).
;
; The engine (EngineSound, every second interrupt while a tune is requested): on the 48K a burst of 11 beeper edges
; whose spacing falls as the speed rises (plus a ROM byte AND $3F as jitter); on the 128K a tone on AY channel C from
; the speed, or the skid noise (SkidLevel). The speed is folded before use (below 60 as is, 60-129 minus 60, from 130
; minus 120): the note drops twice as the bike speeds up, a gear change heard. The effects and beeps are in the game's
; modules: PlayEffect ($AC88, the AY sweep of a crash), BeepTone ($AB95), the name entry's sweep NameEntrySound
; ($8AF0).
; --------------------------------------------------------------------------------------------------------------------

; Step one tune channel (IX): count its note down, then read the next note or
; command
;
; In: IX = ChannelA or ChannelB. The count (IX+0) minus 1: reaching 0 sets the
; channel's mixer bit (IX+$0E) in AyMixer's value (the note stops for one
; interrupt) and writes the mixer; going past 0 ($FF) toggles the bit back and
; reads the stream at (IX+1,2): a length byte below $C8 (the new count, minus
; 1), then the note byte: low nibble 0 sets the bit (a rest); 1-11 reads
; NoteTable's word n ($66AA + 2n), halved (high nibble + transpose IX+3) times,
; into the channel's tone registers (IX+$0D and +1). Bytes from $C8:
; ChannelCommands.
;
; Recorded: c1, m128: two calls each interrupt in play.
;
; Witness: L1 51862 (c1, crash, ctl, m128, stages, twoplayer).
PlayChannel:
  LD A,(IX+$00)
  DEC A
  LD (IX+$00),A
  JR NZ,l_659D
  LD A,(AyMixer+$0001)
  OR (IX+$0E)
  LD (AyMixer+$0001),A
  JP WriteMixer
l_659D:
  INC A
  RET NZ
  LD A,(AyMixer+$0001)
  XOR (IX+$0E)
  LD (AyMixer+$0001),A
  CALL WriteMixer
  LD L,(IX+$01)
  LD H,(IX+$02)
; This entry point is used by the routines at ChannelPeriod and ChannelAyPairs.
ChannelRead:
  LD A,(HL)               ; the next byte of the stream
  CP $C8
  JR NC,ChannelCommands
  DEC A
  LD (IX+$00),A
  INC HL
  LD A,(HL)
  INC HL
  LD (IX+$01),L
  LD (IX+$02),H
  LD C,A
  AND $0F
  JR NZ,l_65D4
  LD A,(AyMixer+$0001)
  OR (IX+$0E)
  LD (AyMixer+$0001),A
  JP WriteMixer
l_65D4:
  ADD A,A
  ADD A,$AA
  LD L,A
  LD H,$66
  JR NC,ChannelPeriod     ; NoteTable ($66AA) + 2n never crosses $66FF, so the
                          ; INC H below is never needed

; INC H for a note table that crosses a page: not reached with this table
;
; Known only from the code.
NoteCarry:
  INC H

; The period from (HL), halved (high nibble + transpose) times, out to the
; channel's tone registers
;
; In: HL = the word in NoteTable, C = the note byte, IX the channel. Writes the
; low then the high register (IX+$0D, IX+$0D+1) through ports $FFFD / $BFFD.
;
; Witness: L1 5104 (c1, crash, ctl, m128, stages, twoplayer).
ChannelPeriod:
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  LD A,C
  ADD A,(IX+$03)
  AND $F0
  RRA
  RRA
  RRA
  RRA
l_65EB:
  AND A
  RR H
  RR L
  DEC A
  JR NZ,l_65EB
  EX DE,HL
  LD BC,$FFFD
  LD L,(IX+$0D)
  LD A,L
  OUT (C),A
  LD B,$BF
  LD A,E
  OUT (C),A
  LD B,$FF
  LD A,L
  INC A
  OUT (C),A
  LD B,$BF
  LD A,D
  OUT (C),A
  RET
; This entry point is used by the routine at PlayChannel.
ChannelCommands:
  CP $C9                  ; $C9 restart at (IX+4,5) and clear TuneMark; $CA set
                          ; TuneMark; $FE n repeat; $FD repeat end; $FB return;
                          ; $FC call
  JR NZ,l_661E
  XOR A
  LD (TuneMark),A
  LD L,(IX+$04)
  LD H,(IX+$05)
  JR ChannelRead
l_661E:
  CP $CA
  JR NZ,l_662A
  INC HL
  LD A,$01
  LD (TuneMark),A
  JR ChannelRead
l_662A:
  CP $FE
  JR NZ,l_6647
  INC HL
  LD A,(IX+$06)
  INC A
  LD (IX+$06),A
  CALL ChannelLoop
  LD A,(HL)
  INC HL
  LD (IY+$00),A
  LD (IY+$01),L
  LD (IY+$02),H
  JP ChannelRead
l_6647:
  CP $FD
  JR NZ,l_666B
  CALL ChannelLoop
  LD A,(IY+$00)
  DEC A
  LD (IY+$00),A
  JR NZ,l_6662
  INC HL
  LD A,(IX+$06)
  DEC A
  LD (IX+$06),A
  JP ChannelRead
l_6662:
  LD L,(IY+$01)
  LD H,(IY+$02)
  JP ChannelRead
l_666B:
  CP $FB
  JR NZ,l_6678
  LD L,(IX+$0F)
  LD H,(IX+$10)
  JP ChannelRead
l_6678:
  CP $FC
  JR NZ,ChannelAyPairs
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (IX+$0F),L
  LD (IX+$10),H
  EX DE,HL
  JP ChannelRead

; Any other command byte: the next byte E is a count of AY pairs, written by
; AyWrite, then on
;
; Known only from the code: no stream of the two tunes holds such a byte
; (src/res/sound/tunes.txt lists every command they use).
ChannelAyPairs:
  INC HL
  LD E,(HL)
  INC HL
  CALL AyWrite
  JP ChannelRead

; IY = the channel's repeat record: IX + 7 + 3 * depth (count, address)
;
; Witness: L1 2347 (c1, crash, ctl, m128, stages, twoplayer).
ChannelLoop:
  LD A,(IX+$06)
  LD E,IXL
  LD D,IXH
  LD IY,$0007
  ADD IY,DE
  LD E,A
  ADD A,A
  ADD A,E
  LD E,A
  LD D,$00
  ADD IY,DE
  RET

; The AY tone periods of one octave ($0EEE ... $07E9), halved per octave by
; ChannelPeriod
;
; A note n reads word n ($66AA + 2n): word 0 ($0EEE) is never read, and a note
; 12 would read TuneTable; the tunes use the notes 2, 4, 6, 7, 9 and 11
; (src/res/sound/tunes.txt).
NoteTable:
  INCBIN "res/sound/notes.bin",$0000,24

; The tunes' streams, two words a tune: tune 1 Tune1A, Tune1B; tune 2 Tune2A,
; Tune2B
;
; Read at IntSound as $66BE + 4 * tune (the operand TuneTable-4): tune 0 is
; silence and has no row.
TuneTable:
  DEFW Tune1A,Tune1B,Tune2A,Tune2B

; Tune 2, channel A: calls of phrases, repeats and $CA marks (the stream
; format: PlayChannel)
;
; src/res/sound/tunes.txt lists the four streams as text (sound/tunes.bin,
; tools/res_formats.py).
Tune2A:
  INCBIN "res/sound/tunes.bin",$0000,55
Tune1A:
  INCBIN "res/sound/tunes.bin",$0037,36
Tune2B:
  INCBIN "res/sound/tunes.bin",$005B,107
Tune1B:
  INCBIN "res/sound/tunes.bin",$00C6,107

; AY register 7 and its value: the channels' mixer (PlayChannel sets and clears
; the tone bits)
;
; Pairs for AyWrite: register, value. AyMixer's value ($67FC) is the live
; mixer: PlayChannel, EngineTone and EngineSkid change its bits and WriteMixer
; sends it.
AyMixer:
  DEFB $07,$3C
AyVolumeC:
  DEFB $0A,$0B            ; register 10 (channel C's volume), set by EngineSkid
                          ; from SkidLevel
AyNoise:
  DEFB $06,$00            ; register 6 (the noise period), set by EngineSkid
                          ; from the speed

; AY register 7 = AyMixer's value
;
; Witness: L1 13197 (c1, crash, ctl, m128, stages, twoplayer).
WriteMixer:
  LD E,$01
  LD HL,AyMixer

; Write E pairs (register, value) from HL to the AY: OUT ($FFFD) the register,
; OUT ($BFFD) the value
;
; Out: HL past the pairs. On the 48K the ports reach nothing (the game writes
; them on both machines).
;
; Witness: L1 15123 (c1, crash, ctl, m128, stages, twoplayer).
AyWrite:
  LD A,(HL)
  LD BC,$FFFD
  OUT (C),A
  INC HL
  LD A,(HL)
  LD B,$BF
  OUT (C),A
  INC HL
  DEC E
  JR NZ,AyWrite
  RET

; Tune channel A: count, stream, transpose, restart, repeat depth and records,
; tone register 0, mixer bit 1
;
; 17 bytes: +0 the note's count, +1/+2 the stream pointer, +3 the transpose,
; +4/+5 the restart, +6 the repeat depth ($FF none), +7 two records of 3 bytes
; (count, address), +$0D the tone register, +$0E the mixer bit, +$0F/+$10 the
; call's return.
ChannelA:
  DEFB $00,$00,$00,$20,$01,$67,$00,$00
  DEFB $00,$00,$00,$00,$00,$02,$02,$00
  DEFB $00
ChannelB:
  DEFB $00,$00,$00,$30,$90,$67,$00,$00 ; tune channel B: tone register 2, mixer
  DEFB $00,$00,$00,$00,$00,$00,$01,$00 ; bit 2
  DEFB $00

; DE = the screen address of pixel line A (L = the same line): the ROM's
; PIXEL-ADD layout, column 0
;
; In: A = L = the line (0-191). D = $40 + (line AND 7) + 8 * (line >> 6), E =
; (line AND $38) * 4. RowEntry's helper.
;
; Witness: L1 11245 (c1, crash, ctl, m128, stages, twoplayer).
LineAddress:
  AND $07
  ADD A,$40
  BIT 6,L
  JR Z,l_6843
  ADD A,$08
l_6843:
  BIT 7,L
  JR Z,l_6849
  ADD A,$10
l_6849:
  LD D,A
  LD A,L
  AND $38
  ADD A,A
  ADD A,A
  LD E,A
  RET

; Every second interrupt: the engine's note from SPEED, on the beeper (48K) or
; AY channel C (128K)
;
; EngineToggle (the LD A operand at $6852) flips each call and the call with it
; 0 returns. A = SPEED ($7C34), +9 in the air (JumpHeight), folded (below 60 as
; is, 60-129 minus 60, then minus 60 more), C = $63 - A. 48K (Beeper nonzero):
; 11 edges on port $FE, the n-th after $14 + C + (a ROM byte at $02xx AND $3F)
; DJNZ turns: a buzz whose pitch rises with the speed. 128K: an effect playing
; (EffectTime): nothing; SkidLevel nonzero: EngineSkid; else EngineTone.
;
; Recorded: c1: the OUT ($FE) at $687F in play; m128: the AY path $68D1.
;
; Witness: L1 23083 (c1, crash, ctl, m128, stages, twoplayer).
EngineSound:
  LD A,$00
  XOR $FF
  LD (EngineSound+$0001),A
  RET NZ
  LD A,(JumpHeight+$0001)
  AND A
  LD A,(Speed+$0001)
  JR Z,l_6864
  ADD A,$09
l_6864:
  CP $3C
  JR C,l_6870
  SUB $3C
  CP $46
  JR C,l_6870
  SUB $3C
l_6870:
  CPL
  ADD A,$64
  LD C,A
  LD A,(Beeper)
  AND A
  JR Z,l_6893
  LD D,$0B
  LD H,$02
  XOR A
EngineEdges:
  OUT ($FE),A             ; 48K: the burst
  LD E,A
  LD A,(HL)
  INC L
  AND $3F
  ADD A,$14
  ADD A,C
  LD B,A
  LD A,E
  XOR $10
l_688D:
  DJNZ l_688D
  DEC D
  JR NZ,EngineEdges
  RET
l_6893:
  LD A,(EffectTime)
  AND A
  RET NZ
  LD A,(SkidLevel)
  AND A
  JR Z,EngineTone

; 128K: channel C's volume from SkidLevel, the noise period from SPEED, noise
; on C and tone off
;
; In: A = SkidLevel. Volume = ((A >> 2) AND 3) + $0B, at most 15; noise period
; = SPEED >> 4 (SPEED 0: EngineTone instead); AyVolumeC and AyNoise written,
; mixer AND $1F OR 4.
;
; Known only from the code: SkidLevel is set by the sand of stage 3
; (OffRoadSand), and no recording left the road there on the 128K.
EngineSkid:
  RRA
  RRA
  AND $03
  ADD A,$0B
  CP $10
  JR C,l_68AA
  LD A,$0F
l_68AA:
  LD (AyVolumeC+$0001),A
  LD A,(Speed+$0001)
  AND A
  JR Z,EngineTone
  AND $F0
  RRA
  RRA
  RRA
  RRA
  LD (AyNoise+$0001),A
  LD HL,AyVolumeC
  LD E,$02
  CALL AyWrite
  LD A,(AyMixer+$0001)
  AND $1F
  OR $04
  LD (AyMixer+$0001),A
  JP WriteMixer

; 128K: AY channel C's period from C and SPEED's low byte, volume 15
; (AyEngineVolume), tone C on
;
; Period = (C + $1C) * 32 with the top bits of -SPEED's low byte ($7C33)
; shifted in. Mixer AND $3B OR $20.
;
; Witness: L1 1768 (m128).
EngineTone:
  LD A,C
  ADD A,$1C
  LD H,$00
  LD L,A
  LD A,(Speed)
  NEG
  LD B,$05
  RLA
l_68DF:
  ADC HL,HL
  DJNZ l_68DF
  LD BC,$FFFD
  LD A,$05
  OUT (C),A
  LD B,$BF
  LD A,H
  OUT (C),A
  LD B,$FF
  LD A,$04
  OUT (C),A
  LD B,$BF
  LD A,L
  OUT (C),A
  LD HL,AyEngineVolume
  LD E,$01
  CALL AyWrite
  LD A,(AyMixer+$0001)
  AND $3B
  OR $20
  LD (AyMixer+$0001),A
  JP WriteMixer
