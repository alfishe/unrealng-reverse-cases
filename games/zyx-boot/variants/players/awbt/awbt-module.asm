; --------------------------------------------------------------------------------------------------------------------
; awbt-module.asm: A game's music and effects player: songs of sequence triples, sequences of voice numbers, voices of volume and pitch pairs
;
; Entries: the variant's start $BFFB (song 2), MusicPlay $C000 (JP Play, once a frame), MusicStart $C003 (song A, 1-5,
; from the next frame), Effect $C006 (sound effect A, 1-7), MusicStop $C009.
;
; A song ($C4E9 + 2 * song): two bytes an item; a second byte not 0: three words, the sequences of channels A, B and
; C; else a command: 1 the voice records of channels A and B (two words), 2 call (a word), 3 the transposition, 4
; return, 5 the tempo, 0 stop. A sequence: its speed (frames a step), then voice numbers (0: none) up to $FF. A voice:
; base note, speed, step, then (volume, pitch) pairs up to a volume $FF.
; --------------------------------------------------------------------------------------------------------------------

; Song 2: LD A,2, then MusicStart
Start:
  LD A,$02
  JP MusicStart

; JP Play
MusicPlay:
  JP Play

; JP SetSong
;
; Used by the routine at Start.
MusicStart:
  JP SetSong

; JP EffectEntry
Effect:
  JP EffectEntry

; JP StopEntry
MusicStop:
  JP StopEntry

; Two RETs, the current song, the tempo
PlayerVars:
  DEFB $C9,$C9,$00,$00,$40,$C9,$C9,$C9

; The first frame (Play's JR at $C029 points here until then): clear the flag,
; the mixer to $2A
;
; Used by the routine at Play.
FirstFrame:
  LD HL,$0000
  LD (Play+$0006),HL
  LD C,$07
  LD A,$2A
  CALL WriteAY
  JR l_C02B

; One frame: a pending song start, the effects, the tempo counter, the song's
; next step, each channel's sequence and voice
;
; Used by the routine at MusicPlay.
Play:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH IX
  JR FirstFrame
; This entry point is used by the routine at FirstFrame.
l_C02B:
  CALL StartSong
  CALL Effects
  LD HL,TempoFlags+$0001
  LD A,(HL)
  LD BC,(PlayerVars+$0004)
  SUB C
  LD (HL),A
  SBC A,A
  LD (TempoFlags),A
  JR NC,l_C045
  LD A,$F0
  ADD A,(HL)
  LD (HL),A
l_C045:
  CALL SongStep
  LD IX,Channels+$0002
  CALL ChannelVoice
  LD IX,Channels+$0014
  CALL ChannelVoice
  LD IX,Channels+$0026
  CALL ChannelVoice
  SUB A
  LD (TempoFlags),A
  POP IX
  POP HL
  POP DE
  POP BC
  POP AF
  RET

; The music off: the song pointer to the table's start, every channel cleared
;
; Used by the routine at MusicStop.
StopEntry:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  SUB A
  LD (PlayerVars+$0002),A
  LD HL,$C4E9
  LD (SongPointers),HL
  CALL sub_C31B
  POP HL
  POP DE
  POP BC
  POP AF
  RET

; Two bytes $FF (the empty sequence), then the channel records: 18 bytes each
; at $C080, $C092, $C0A4 (+0 the voice row, +2 the note, +3 the step, +4 the AY
; register, +5 the volume register, +6 the sequence, +8 its counter, +9 its
; speed, +$0A the voice record, +$0C the speed, +$0D its counter, +$0E the
; effect priority, +$0F flags, +$10 the effect)
Channels:
  DEFB $FF,$FF,$7E,$C0,$00,$00,$04,$0A,$7E,$C0,$00,$02,$7C,$C0,$01,$01
  DEFB $00,$00,$00,$00,$7E,$C0,$00,$00,$00,$08,$7E,$C0,$01,$02,$7C,$C0
  DEFB $01,$01,$00,$08,$00,$00,$7E,$C0,$00,$00,$02,$09,$7E,$C0,$00,$02
  DEFB $7C,$C0,$01,$01,$00,$05,$00,$00,$38,$73,$39,$30,$41,$49,$48,$49
  DEFB $30,$60,$3E,$58,$79,$7C,$75,$89

; A channel's sequence step, then its voice row: the volume, the period (note +
; step + pitch), noise when flagged
;
; Used by the routine at Play.
ChannelVoice:
  CALL ChannelSequence
  DEC (IX+$0D)
  RET NZ
  LD A,(IX+$0C)
  LD (IX+$0D),A
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,(HL)
  INC HL
  INC A
  JR Z,l_C12E
  DEC A
  LD C,(IX+$05)
  CALL WriteVolume
  LD A,(HL)
  INC HL
  LD (IX+$00),L
  LD (IX+$01),H
  LD B,A
  LD A,(IX+$0F)
  AND $03
  JR Z,l_C101
  LD A,$1F
  SUB B
  LD C,$06
  BIT 2,(IX+$0F)
  CALL NZ,WriteAY
l_C101:
  LD A,(IX+$02)
  ADD A,(IX+$03)
  LD (IX+$02),A
  ADD A,B
  CALL NotePeriod
  EX DE,HL
  LD C,(IX+$04)
  CALL WriteAYPair
  BIT 3,(IX+$0F)
  RET Z
  SRL H
  RR L
  SRL H
  RR L
  SRL H
  RR L
  JR NC,l_C129
  INC HL
l_C129:
  LD C,$0B
  JP WriteAYPair
l_C12E:
  BIT 1,(IX+$0F)
  RET Z
  RES 1,(IX+$0F)
  LD (IX+$0E),A
  RET

; A channel's sequence step on a tempo frame: the next voice number, the voice
; from the channel's voice record
;
; Used by the routine at ChannelVoice.
ChannelSequence:
  LD A,(TempoFlags)
  OR A
  RET Z
  DEC (IX+$08)
  RET NZ
  LD A,(IX+$09)
  LD (IX+$08),A
  LD L,(IX+$06)
  LD H,(IX+$07)
  LD A,(HL)
  INC A
  RET Z
  DEC A
  INC HL
  LD (IX+$06),L
  LD (IX+$07),H
  OR A
  RET Z
  BIT 1,(IX+$0F)
  RET NZ
  BIT 0,(IX+$0F)
  JR NZ,l_C198
  RLCA
  RLCA
  LD HL,Transpose
  ADD A,(HL)
  LD L,(IX+$0A)
  LD H,(IX+$0B)
  ADD A,(HL)
  INC HL
  LD (IX+$02),A
; This entry point is used by the routine at sub_C2A9.
l_C179:
  CALL ReadWord
  LD (IX+$0D),$01
  LD (IX+$0C),E
  LD (IX+$03),D
  LD (IX+$00),L
  LD (IX+$01),H
  BIT 3,(IX+$0F)
  RET Z
  LD C,$0D
  LD A,$08
  JP WriteAY
l_C198:
  DEC A
  RLCA
  RLCA
  LD C,A
  LD B,$00
  LD HL,$C627
  ADD HL,BC
  CALL ReadWord
  LD A,(HL)
  LD C,$07
  CALL WriteAY
  INC HL
  LD A,(HL)
  INC HL
  LD (IX+$02),A
  EX DE,HL
  JR l_C179

; The tempo frame flag and the tempo counter
TempoFlags:
  DEFB $00,$00

; When channel A's sequence has ended: the song's next item (sequence triples
; and commands)
;
; Used by the routine at Play.
SongStep:
  LD A,(Channels+$000A)
  DEC A
  RET NZ
  LD HL,(Channels+$0008)
  LD A,(HL)
  INC A
  RET NZ
  LD HL,(SongPointers)
l_C1C4:
  INC HL
  LD A,(HL)
  DEC HL
  CP $00
  JR NZ,l_C1ED
  LD A,(HL)
  INC HL
  INC HL
  CP $01
  JR Z,l_C21C
  CP $02
  JR Z,l_C20F
  CP $03
  JR Z,l_C22C
  CP $04
  JR Z,l_C23E
  CP $05
  JR Z,l_C235
  LD HL,$C4E9
  LD (SongPointers),HL
  SUB A
  LD (PlayerVars+$0002),A
  RET
l_C1ED:
  CALL ReadSequence
  LD (Channels+$000B),A
  LD (Channels+$0008),DE
  CALL ReadSequence
  LD (Channels+$001D),A
  LD (Channels+$001A),DE
  CALL ReadSequence
  LD (Channels+$002F),A
  LD (Channels+$002C),DE
  LD (SongPointers),HL
  RET
l_C20F:
  CALL ReadWord
  EX DE,HL
  LD (SongPointers+$0002),DE
  LD (SongPointers),HL
  JR l_C1C4
l_C21C:
  CALL ReadWord
  LD (Channels+$000C),DE
  CALL ReadWord
  LD (Channels+$001E),DE
  JR l_C1C4
l_C22C:
  LD A,(HL)
  LD (Transpose),A
  INC HL
  INC HL
  JP l_C1C4
l_C235:
  LD A,(HL)
  LD (PlayerVars+$0004),A
  INC HL
  INC HL
  JP l_C1C4
l_C23E:
  LD HL,(SongPointers+$0002)
  JP l_C1C4

; The song's position and the return position of a call
SongPointers:
  DEFW $C4E9,$C4E9

; DE = the word at HL (a sequence), A = its speed byte, DE + 1
;
; Used by the routine at SongStep.
ReadSequence:
  CALL ReadWord
  LD A,(DE)
  INC DE
  RET

; Sound effect A (1-7): its record at $C40F, onto its channel when its priority
; is not lower
;
; Used by the routine at Effect.
EffectEntry:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH IX
  CALL sub_C25E
  POP IX
  POP HL
  POP DE
  POP BC
  POP AF
  RET

; sub_C25E
;
; Used by the routine at EffectEntry.
sub_C25E:
  DEC A
  CP $07
  RET NC
  LD C,A
  RLCA
  RLCA
  ADD A,C
  ADD A,C
  LD C,A
  LD B,$00
  LD HL,EffectTable+$0004
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD IX,Channels+$0002
  CP $01
  JR Z,l_C284
  LD IX,Channels+$0014
  CP $02
  JR Z,l_C284
  LD IX,Channels+$0026
l_C284:
  LD A,(HL)
  CP (IX+$0E)
  RET C
  LD (IX+$11),$00
  LD (IX+$0E),A
  LD (IX+$10),L
  LD (IX+$11),H
  RET

; Each channel's effect step
;
; Used by the routine at Play.
Effects:
  LD IX,Channels+$0002
  CALL sub_C2A9
  LD IX,Channels+$0014
  CALL sub_C2A9
  LD IX,Channels+$0026

; sub_C2A9
;
; Used by the routine at Effects.
sub_C2A9:
  LD H,(IX+$11)
  LD A,H
  OR A
  RET Z
  LD (IX+$11),$00
  LD L,(IX+$10)
  DEC HL
  DEC HL
  LD A,(HL)
  LD (IX+$02),A
  DEC HL
  LD A,(HL)
  DEC HL
  DEC HL
  LD C,$07
  BIT 2,(IX+$0F)
  CALL NZ,WriteAY
  SET 1,(IX+$0F)
  CALL ReadWord
  EX DE,HL
  JP l_C179

; Song A (below 6) to start on the next frame
;
; Used by the routine at MusicStart.
SetSong:
  CP $06
  RET NC
  PUSH AF
  LD (PlayerVars+$0002),A
  LD (data_C2E0),A
  POP AF
  RET

; data_C2E0
data_C2E0:
  DEFB $00

; A pending song: its song pointer, every counter 1, the mixer, the channels
; cleared, the volumes 0
;
; Used by the routine at Play.
StartSong:
  LD A,(data_C2E0)
  OR A
  RET Z
  LD C,A
  RLCA
  LD C,A
  LD B,$00
  LD HL,$C4E9
  ADD HL,BC
  CALL ReadWord
  LD (SongPointers),DE
  LD A,$01
  LD (Channels+$000A),A
  LD (Channels+$001C),A
  LD (Channels+$002E),A
  LD (Channels+$000F),A
  LD (Channels+$0021),A
  LD (Channels+$0033),A
  LD A,$38
  LD C,$07
  CALL WriteAY
  SUB A
  LD (TempoFlags),A
  LD (TempoFlags+$0001),A
  LD (data_C2E0),A

; sub_C31B
;
; Used by the routine at StopEntry.
sub_C31B:
  LD HL,Channels
  LD (Channels+$0008),HL
  LD (Channels+$001A),HL
  LD (Channels+$002C),HL
  LD (Channels+$0002),HL
  LD (Channels+$0014),HL
  LD (Channels+$0026),HL
  SUB A
  LD (Channels+$0010),A
  LD (Channels+$0022),A
  LD (Channels+$0034),A
  LD (Channels+$0013),A
  LD (Channels+$0025),A
  LD (Channels+$0037),A
  LD C,$08
  LD H,A
  LD L,A
  CALL WriteAY
  INC C
  JP WriteAYPair

; DE = the AY period of note A (48 notes, shifted right an octave above)
;
; Used by the routine at ChannelVoice.
NotePeriod:
  PUSH AF
  PUSH BC
  PUSH HL
  LD B,$01
l_C353:
  CP $30
  JR C,l_C35C
  SUB $30
  INC B
  JR l_C353
l_C35C:
  LD L,A
  LD H,$00
  ADD HL,HL
  LD DE,PeriodTable
  ADD HL,DE
  CALL ReadWord
l_C367:
  SRL D
  RR E
  DJNZ l_C367
  POP HL
  POP BC
  POP AF
  RET

; The song's transposition
Transpose:
  DEFB $70

; 48 AY tone periods (the lowest octaves)
PeriodTable:
  DEFW $0EEE,$0EB7,$0E81,$0E4C,$0E17,$0DE4,$0DB1,$0D7F
  DEFW $0D4D,$0D1C,$0CEC,$0CBD,$0C8E,$0C60,$0C32,$0C06
  DEFW $0BDA,$0BAE,$0B83,$0B59,$0B2F,$0B06,$0ADE,$0AB5
  DEFW $0A8F,$0A68,$0A42,$0A1C,$09F7,$09D2,$09AE,$098B
  DEFW $0968,$0945,$0923,$0902,$08E1,$08C0,$08A0,$0880
  DEFW $0861,$0842,$0824,$0806,$07E9,$07CC,$07AF,$0793

; Bytes after the table, no code reads them
PeriodTail:
  DEFB $2A,$45,$2B,$22,$33,$3B,$3A,$3B,$22,$52,$30,$4A,$4B,$4E,$47,$5B

; DE = the word at HL, HL + 2
;
; Used by the routines at ChannelSequence, SongStep, ReadSequence, sub_C2A9,
; StartSong and NotePeriod.
ReadWord:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  RET

; AY register C = L, C + 1 = H
;
; Used by the routines at ChannelVoice and sub_C31B.
WriteAYPair:
  PUSH AF
  LD A,L
  CALL WriteAY
  INC C
  LD A,H
  CALL WriteAY
  DEC C
  POP AF
  RET

; AY register C = A / 2 + 8 (0 stays 0)
;
; Used by the routine at ChannelVoice.
WriteVolume:
  OR A
  JR Z,WriteAY
  SRL A
  ADD A,$08

; AY register C = A
;
; Used by the routines at FirstFrame, ChannelVoice, ChannelSequence, sub_C2A9,
; StartSong, sub_C31B, WriteAYPair and WriteVolume.
WriteAY:
  PUSH BC
  PUSH DE
  LD D,C
  LD BC,$FFFD
  OUT (C),D
  LD BC,$BFFD
  OUT (C),A
  POP DE
  POP BC
  RET

; Bytes, then the sound effects from $C40F: 6 bytes each (channel, priority,
; the voice) and their voices
EffectTable:
  DEFB $35,$C4,$28,$1E,$00,$02,$8F,$C4,$2A,$00,$00,$01,$8F,$C4,$28,$14
  DEFB $00,$01,$AC,$C4,$38,$78,$01,$02,$AC,$C4,$38,$84,$01,$03,$56,$C4
  DEFB $38,$A0,$01,$02,$56,$C4,$2A,$00,$00,$00,$02,$FE,$0F,$0C,$0D,$14
  DEFB $0B,$14,$09,$14,$08,$12,$07,$13,$06,$11,$05,$12,$04,$13,$04,$12
  DEFB $03,$11,$02,$18,$01,$1C,$01,$1F,$00,$01,$FF,$01,$00,$0F,$0C,$0D
  DEFB $12,$0B,$18,$09,$12,$08,$0C,$08,$06,$07,$00,$07,$06,$06,$0C,$06
  DEFB $12,$05,$18,$05,$12,$04,$0C,$04,$06,$04,$00,$03,$06,$03,$0C,$03
  DEFB $12,$02,$18,$02,$12,$02,$0C,$02,$06,$01,$00,$01,$06,$01,$0C,$01
  DEFB $12,$00,$01,$FF,$01,$FE,$0D,$00,$0D,$0A,$0A,$14,$09,$1E,$07,$00
  DEFB $07,$0A,$04,$14,$04,$1E,$02,$00,$02,$0A,$01,$14,$01,$1E,$00,$01
  DEFB $FF,$01,$01,$0F,$20,$0E,$2B,$0C,$20,$0B,$2B,$09,$20,$08,$2B,$05
  DEFB $20,$04,$2B,$07,$20,$06,$2B,$06,$20,$05,$2B,$04,$20,$04,$2B,$03
  DEFB $20,$03,$2B,$03,$20,$02,$2B,$02,$20,$02,$2B,$01,$20,$01,$2B,$01
  DEFB $20,$01,$2B,$01,$20,$01,$2B,$01,$20,$01,$2B,$00,$01,$FF
