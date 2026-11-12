; --------------------------------------------------------------------------------------------------------------------
; player.asm: The ASC Sound Master player: the entry vectors, the set-up, the frame, the pattern reader, the samples and ornaments, the AY write
;
; The compiled player of ASC Sound Master (Andrew Sendetski, ASC). Three entry points: MusicInit $C00B (JP InitPlayer
; $C053) reads the module's header at TuneHeader $C478 into self-modified operands (the delay into DelayOp $C10A, the
; three table addresses into PatternTableOp $C1A8, SampleTableOp $C25E and CommandOrnament $C26B, the number of
; positions into PositionCountOp $C19A, the positions' address into NextPosition $C191), clears the channel records
; and silences the AY; MusicPlay $C00E (JP PlayFrame $C104) plays one frame; MusicStop $C011 (JP Silence $C095)
; silences the AY (known only from the code: nobody calls it).
;
; A frame (PlayFrame): DelayCounter $C103 counts the tune's delay (6 frames: a row every 6 frames, 8.33 rows a
; second). On a row frame, when all three channels have met the $FF that ends their stream in the current pattern,
; NextPosition $C191 starts the next position (after the last, position 0 again: the module has no loop byte); then
; ChannelRow $C1CE reads a channel's stream when its row counter runs out (an event lasts the length set by the $F0
; command, in rows). On every frame ChannelSound $C2A0 runs for A, B and C: one row of the channel's sample
; (SampleStep $C308: volume, tone offset, noise offset, mixer bits) and of its ornament (OrnamentStep $C385: a note
; offset), then the tone period from PeriodTable $C3CA, the volume and the noise into AYRegisters $C0F4; the mixer
; from the three samples' bits; last WriteAY $C15F writes the registers (register 13, the envelope shape, only in a
; frame that set it).
;
; Cost: c1 calls MusicPlay 7274 times (frames 543-7879) for 49 741 659 T-states with all it calls, 6838 T-states a
; frame on average; MusicInit takes 3139 T-states.
; --------------------------------------------------------------------------------------------------------------------

; The compiled player's header: the init, play, AY-write and AY-register
; addresses
;
; DEFW MusicInit $C00B, MusicPlay $C00E, WriteAY $C15F, AYRegisters $C0F4: the
; addresses a program using the compilation may take from the header. No
; instruction in c1-c4 reads them (the menu calls $C00B and $C00E directly).
PlayerVectors:
  DEFW MusicInit,MusicPlay,WriteAY,AYRegisters

; Three more bytes of the compilation's header: $80, $54, $1E
;
; No instruction in c1-c4 reads them and the player's code does not refer to
; them (known only from the code); their meaning is not known.
PlayerHeaderBytes:
  DEFB $80,$54,$1E

; Set the player up for the tune (JP InitPlayer)
;
; The init entry: the menu's set-up calls it once (c1 frame 532), before its IM
; 2 handler starts calling MusicPlay $C00E.
;
; Witness: L1 4 (c x4).
MusicInit:
  JP InitPlayer

; Play one frame of the tune (JP PlayFrame)
;
; The play entry: the menu's IM 2 handler calls it at $676D on every interrupt
; (c1: 7274 calls, frames 543-7879).
;
; Witness: L1 13931 (c x4).
MusicPlay:
  JP PlayFrame

; Silence the AY (JP Silence)
;
; The stop entry of the compilation. Known only from the code: no instruction
; in c1-c4 jumps or calls here (the menu never stops the music; the launched
; program loads over it).
;
; Witness: L1 0 ().
MusicStop:
  JP Silence

; "ASM COMPILATION OF DISCO MUSIC BY ANT P BY ANDREW SENDETSKI ASC"
;
; 63 bytes the compiler puts in the player: "ASM COMPILATION OF " (19), the
; tune's title "DISCO MUSIC BY ANT P" (20), " BY " (4), the author field
; "ANDREW SENDETSKI ASC" (20). No instruction in c1-c4 reads it; the menu never
; prints it.
PlayerText:
  INCBIN "res/texts/player-text.bin",$0000,63

; Clear the channels, read the module's header into the player's operands,
; silence the AY
;
; In: nothing. Clears ChannelA $C0A9 to the end of ChannelC $C0F3 (75 bytes),
; sets PositionOp+1 to 0 (the first position), and DelayCounter $C103 and the
; three row counters (+$0A of each record) to 1, so the first MusicPlay reads a
; row at once.
;
; Then BC = DE = TuneHeader $C478: DelayOp+1 = the delay (byte 0: 6); through
; ReadOffsetDE $C189 the three offsets at +1, +3, +5 plus the module's address
; into PatternTableOp+1 ($C496), SampleTableOp+1 ($D074) and CommandOrnament+1
; ($D4EF); PositionCountOp+1 = the number of positions (byte 7: 22);
; NextPosition+1 = the positions' address ($C480). Falls into Silence $C095.
;
; c1 runs it once, at frame 532.
;
; Witness: L1 4 (c x4).
InitPlayer:
  XOR A
  LD HL,ChannelA
  LD DE,ChannelA+$0001
  LD BC,$004A
  LD (HL),A
  LDIR
  LD (PositionOp+$0001),A
  INC A
  LD (DelayCounter),A
  LD (ChannelA+$000A),A
  LD (ChannelB+$000A),A
  LD (ChannelC+$000A),A
  LD DE,TuneHeader
  LD B,D
  LD C,E
  LD A,(DE)
  INC DE
  LD (DelayOp+$0001),A
  CALL ReadOffsetDE
  LD (PatternTableOp+$0001),HL
  CALL ReadOffsetDE
  LD (SampleTableOp+$0001),HL
  CALL ReadOffsetDE
  LD (CommandOrnament+$0001),HL
  LD A,(DE)
  INC DE
  LD (PositionCountOp+$0001),A
  LD (NextPosition+$0001),DE

; Clear the AY register image, mixer $FF, write all 14 registers
;
; AYRegisters $C0F4-$C101 = 0, then AYMixer $C0FB = $FF (tones and noise off),
; and JP WriteAY $C15F, which writes registers 13 to 0 (AYEnvelopeShape is 0
; here, not $FF, so register 13 is written too). Reached by falling from
; InitPlayer $C053 (once a recording) and from MusicStop $C011 (known only from
; the code).
;
; Witness: L1 4 (c x4).
Silence:
  XOR A
  LD HL,AYRegisters
  LD DE,AYRegisters+$0001
  LD BC,$000D
  LD (HL),A
  LDIR
  DEC A
  LD (AYMixer),A
  JP WriteAY

; Channel A's record (25 bytes)
;
; The record PlayFrame $C104 hands to ChannelRow $C1CE and ChannelSound $C2A0
; in IX. +$00 the flags: bit 0 the pattern stream goes on (cleared when the
; next byte is the $FF that ends it), bit 1 the sample ended (its X row:
; silence), bit 2 a note sounds (set by a note, cleared by off $7F), bit 3
; released (set by $7E: the sample's loop no longer loops), bit 4 envelope mode
; (set by $C0, cleared by $C1-$CF), bit 5 the sample row's envelope bit. +$01
; the sample row's mixer bits (bit 0 tone off, bit 3 noise off). +$02 the note
; (0-$55; the ornament adds to it). +$03/$04 the tone offset (the sum of the
; sample's tone deltas since the note). +$05 the noise base ($D0+n). +$06 the
; noise period (the base plus the noise deltas, 0-31). +$07 the volume of this
; frame. +$08 the channel volume ($C1-$CF). +$09 the row length ($F0 n). +$0A
; the rows left of the current event. +$0B/$0C the stream pointer. +$0D/$0E the
; sample's start, +$0F/$10 its row, +$11/$12 its loop row. +$13/$14 the
; ornament's start, +$15/$16 its row, +$17/$18 its loop row.
;
; Cleared by InitPlayer $C053, which sets the row counter +$0A ($C0B3) to 1.
ChannelA:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00

; Channel B's record (25 bytes, as ChannelA)
;
; Its +$01 ($C0C3) gives the mixer bits 1 and 4 (PlayFrame $C104).
ChannelB:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00

; Channel C's record (25 bytes, as ChannelA)
;
; Its +$01 ($C0DC) gives the mixer bits 2 and 5 (PlayFrame $C104).
ChannelC:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00

; The image of AY registers 0-13 that WriteAY sends
;
; Written by SetAYRegister $C17D (E = the register), ChannelSound $C2A0 (the
; noise), CommandLength $C294 (the shape) and ChannelRow $C1CE (the envelope
; period); cleared by Silence $C095.
AYRegisters:
  DEFB $00,$00,$00,$00,$00,$00 ; registers 0-5: the tone periods of A, B, C
                               ; (low, high)
AYNoise:
  DEFB $00                ; register 6: the noise period (the last channel
                          ; whose sample row has noise on)
AYMixer:
  DEFB $00                ; register 7: the mixer, from the three channels'
                          ; +$01 bits
  DEFB $00,$00,$00        ; registers 8-10: the volumes of A, B, C (bit 4: the
                          ; envelope)
AYEnvelopePeriod:
  DEFB $00,$00            ; register 11: the envelope period's low byte (the
                          ; byte after a note in envelope mode); register 12
                          ; stays 0
AYEnvelopeShape:
  DEFB $00                ; register 13: the envelope shape ($F1-$FF sets
                          ; 1-15); $FF: no new shape, not written

; The channel ChannelSound is working on: 0 A, 1 B, 2 C
;
; Set by ChannelSound $C2A0 from A; it selects the registers (2 x channel, 8 +
; channel).
CurrentChannel:
  DEFB $00

; Frames left to the next row
;
; PlayFrame $C104 decrements it each frame and reads a row when it reaches 0,
; then sets it to the delay (DelayOp $C10A: 6). InitPlayer $C053 sets it to 1.
DelayCounter:
  DEFB $01

; Play one frame: on a row frame the next position and the channels' rows, then
; each channel's sound, the mixer, the AY write
;
; In: nothing (reached from MusicPlay $C00E). DelayCounter $C103 - 1; at 0 it
; becomes the delay and, if bit 0 of all three records' flags is 0 (every
; stream met its $FF), NextPosition $C191 starts the next position; then
; ChannelRow $C1CE for A, B and C (IX = ChannelA $C0A9, ChannelB $C0C2,
; ChannelC $C0DB).
;
; PlayFrameSound $C131, every frame: ChannelSound $C2A0 with A = 0, 1, 2 and IX
; = each record; the mixer (register 7) = channel C's +$01 bits << 2 | channel
; B's << 1 | channel A's (bits 0-2 tone off, 3-5 noise off) through
; SetAYRegister $C17D; falls into WriteAY $C15F.
;
; c1: 7274 frames, 1213 of them row frames (the JR NZ at $C108), 21 new
; positions (the CALL Z at $C119).
;
; Witness: L1 13931 (c x4).
PlayFrame:
  LD HL,DelayCounter
  DEC (HL)
  JR NZ,PlayFrameSound
DelayOp:
  LD (HL),$06             ; LD (HL),n: n = the module's delay (self-modified by
                          ; InitPlayer $C053)
  LD A,(ChannelA)
  LD HL,ChannelB
  OR (HL)
  LD HL,ChannelC
  OR (HL)
  BIT 0,A
  CALL Z,NextPosition
  LD IX,ChannelA
  CALL ChannelRow
  LD IX,ChannelB
  CALL ChannelRow
  LD IX,ChannelC
  CALL ChannelRow
PlayFrameSound:
  XOR A                   ; every frame: the three channels' sound and the
                          ; mixer
  LD IX,ChannelA
  CALL ChannelSound
  LD A,$01
  LD IX,ChannelB
  CALL ChannelSound
  LD A,$02
  LD IX,ChannelC
  CALL ChannelSound
  LD A,(ChannelC+$0001)
  RLCA
  LD B,A
  LD A,(ChannelB+$0001)
  OR B
  RLCA
  LD B,A
  LD A,(ChannelA+$0001)
  OR B
  LD E,$07
  CALL SetAYRegister

; Write AYRegisters to the AY: registers 13 (when set) or 12 down to 0
;
; In: AYRegisters $C0F4. Register 13 is written only when AYEnvelopeShape $C101
; is not $FF (a shape command this frame, or Silence $C095), since writing it
; restarts the envelope; then AYEnvelopeShape = $FF. Each register: OUT ($FFFD)
; its number, OUTD its value (B = $BF goes to $BE first: port $BEFD, the AY
; data port).
;
; Out: A = $FF. Reached by falling from PlayFrame $C104 and by JP from Silence
; $C095.
;
; Witness: L1 13935 (c x4).
WriteAY:
  LD HL,AYEnvelopeShape
  LD DE,$FFBF
  LD C,$FD
  LD A,(HL)
  INC A
  LD A,$0D
  JR NZ,WriteAYLoop
  DEC A
  DEC HL
WriteAYLoop:
  LD B,D                  ; select register A, write its value, down to
                          ; register 0
  OUT (C),A
  LD B,E
  OUTD
  DEC A
  JP P,WriteAYLoop
  LD (AYEnvelopeShape),A
  RET

; AYRegisters[E] = A
;
; In: E = the register (0-13), A = the value. Keeps DE and HL.
;
; Witness: L1 137602 (c x4).
SetAYRegister:
  PUSH HL
  PUSH DE
  LD HL,AYRegisters
  LD D,$00
  ADD HL,DE
  LD (HL),A
  POP DE
  POP HL
  RET

; HL = BC + the word at (DE), DE + 2
;
; EX DE,HL and falls into ReadOffset $C18A. Used by InitPlayer $C053 (the
; module's three table offsets) and NextPosition $C191 (the streams of channels
; B and C).
;
; Witness: L1 98 (c x4).
ReadOffsetDE:
  EX DE,HL

; HL = BC + the word at (HL); DE = HL + 2
;
; In: HL = the word's address, BC = the base the offset is from. Out: HL = the
; address, DE = the address after the word.
;
; Witness: L1 141 (c x4).
ReadOffset:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  ADD HL,BC
  RET

; Start the next position: the three channels' streams of its pattern
;
; LD HL,n: n = the positions' address (set by InitPlayer $C053), plus the
; position (PositionOp+1); the next position = this one + 1, or 0 after the
; last (PositionCountOp+1 = 22): the tune loops to position 0. Then HL =
; PatternTableOp+1 + 6 x the pattern number (an 8-bit product: at most pattern
; 42), and ReadOffset $C18A / ReadOffsetDE $C189 put the three stream addresses
; into +$0B/$0C of ChannelA $C0A9, ChannelB $C0C2, ChannelC $C0DB, and bit 0 of
; their flags is set.
;
; c1: 21 positions (0-20, frames 543-7602); position 21 (pattern 14) would
; start at row 1230, after c1's last row 1213.
;
; Witness: L1 43 (c x4).
NextPosition:
  LD HL,$0000
PositionOp:
  LD DE,$0000             ; LD DE,n: n = the position to start (self-modified
                          ; here; 0 by InitPlayer $C053)
  ADD HL,DE
  INC E
  LD A,E
PositionCountOp:
  CP $01                  ; CP n: n = the number of positions (self-modified by
                          ; InitPlayer $C053)
  SBC A,A
  AND E
  LD (PositionOp+$0001),A
  LD A,(HL)
  ADD A,A
  LD E,A
  ADD A,A
  ADD A,E
  LD H,D
  LD L,A
PatternTableOp:
  LD BC,$0000             ; LD BC,n: n = PatternTable $C496 (self-modified by
                          ; InitPlayer $C053)
  ADD HL,BC
  CALL ReadOffset
  LD (ChannelA+$000B),HL
  CALL ReadOffsetDE
  LD (ChannelB+$000B),HL
  CALL ReadOffsetDE
  LD (ChannelC+$000B),HL
  LD HL,ChannelA
  SET 0,(HL)
  LD HL,ChannelB
  SET 0,(HL)
  LD HL,ChannelC
  SET 0,(HL)
  RET

; One row of a channel: when its event ends, read the commands and the next
; event of its stream
;
; In: IX = the channel record. +$0A - 1; while not 0 the current event goes on.
; At 0, the bytes at +$0B/$0C: each byte $80-$FF is a command (PatternCommand
; $C24C), then the event: $00-$55 a note (RowNote $C1F9), $56-$7D nothing new
; (the note goes on), $7E release (RowRelease $C1F3: the sample leaves its
; loop), $7F off (bit 2 cleared: silence).
;
; RowDone $C238: +$0A = the length (+$09), the pointer kept; when the next byte
; is $FF the stream is over (bit 0 cleared). So the three streams of a pattern
; must end on the same row.
;
; c1: 3639 calls in the 1213 row frames.
;
; Witness: L1 6972 (c x4).
ChannelRow:
  DEC (IX+$0A)
  RET NZ
  LD E,(IX+$0B)
  LD D,(IX+$0C)
ChannelRowLoop:
  LD A,(DE)               ; the next byte: a command ($80-$FF) or the event
  INC DE
  BIT 7,A
  PUSH AF
  CALL NZ,PatternCommand
  POP AF
  JR NZ,ChannelRowLoop
  CP $56
  JR C,RowNote
  CP $7E
  JR C,RowDone
  JR Z,RowRelease
  RES 2,(IX+$00)
  JR RowDone
RowRelease:
  SET 3,(IX+$00)          ; $7E: released (bit 3), the sample's loop row no
                          ; longer loops
  JR RowDone
RowNote:
  SET 2,(IX+$00)          ; a note: sound on, the note, noise = the base, tone
                          ; offset 0, the sample and the ornament from their
                          ; start
  RES 3,(IX+$00)
  LD (IX+$02),A
  LD A,(IX+$05)
  LD (IX+$06),A
  XOR A
  LD (IX+$03),A
  LD (IX+$04),A
  LD L,(IX+$0D)
  LD H,(IX+$0E)
  LD (IX+$0F),L
  LD (IX+$10),H
  RES 1,(IX+$00)
  LD L,(IX+$13)
  LD H,(IX+$14)
  LD (IX+$15),L
  LD (IX+$16),H
  BIT 4,(IX+$00)
  JR Z,RowDone
  LD A,(DE)
  INC DE
  LD (AYEnvelopePeriod),A
RowDone:
  LD A,(IX+$09)           ; the event lasts +$09 rows; bit 0 cleared when the
                          ; next byte is $FF
  LD (IX+$0A),A
  LD (IX+$0B),E
  LD (IX+$0C),D
  LD A,(DE)
  INC A
  RET NZ
  RES 0,(IX+$00)
  RET

; A pattern command byte $80-$FF: sample, ornament, volume or envelope mode,
; noise, length or shape
;
; In: A = the byte, IX = the record, DE = the stream after it. $80-$9F: the
; sample A - $80 (+$0D/$0E = SampleTable + its offset, through TableEntry
; $C278); $A0-$BF: the ornament (CommandOrnament $C26B, +$13/$14); $C0-$CF:
; CommandVolume $C283; $D0-$EF: CommandNoise $C290; $F0-$FF: CommandLength
; $C294.
;
; Witness: L1 3520 (c x4).
PatternCommand:
  SUB $F0
  JR NC,CommandLength
  ADD A,$20
  JR C,CommandNoise
  ADD A,$10
  JR C,CommandVolume
  ADD A,$20
  JR C,CommandOrnament
  ADD A,$20
SampleTableOp:
  LD BC,$0000             ; LD BC,n: n = SampleTable $D074 (self-modified by
                          ; InitPlayer $C053)
  CALL TableEntry
  LD (IX+$0D),L
  LD (IX+$0E),H
  RET
CommandOrnament:
  LD BC,$0000             ; $A0-$BF: the ornament. LD BC,n: n = OrnamentTable
                          ; $D4EF (self-modified by InitPlayer $C053)
  CALL TableEntry
  LD (IX+$13),L
  LD (IX+$14),H
  RET

; HL = BC + the word at BC + 2A (a sample or ornament address from its table)
;
; In: A = the number (0-31), BC = SampleTable $D074 or OrnamentTable $D4EF.
;
; Witness: L1 2522 (c x4).
TableEntry:
  ADD A,A
  LD H,$00
  LD L,A
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  ADD HL,BC
  RET

; $C0: envelope mode; $C1-$CF: the channel volume 1-15
;
; In: A = the byte - $C0 (Z for $C0). $C0 sets bit 4 (envelope mode: each note
; is followed by the envelope period byte, and a sample row with E plays on the
; envelope); $C1-$CF clears it and +$08 = 1-15, the scale of the sample's
; volumes.
;
; Witness: L1 173 (c x4).
CommandVolume:
  SET 4,(IX+$00)
  RET Z
  RES 4,(IX+$00)
  LD (IX+$08),A
  RET

; $D0-$EF: the noise base 0-31
;
; +$05 = A; a note copies it into the noise period +$06.
;
; Witness: L1 119 (c x4).
CommandNoise:
  LD (IX+$05),A
  RET

; $F0 n: the row length n; $F1-$FF: the envelope shape 1-15
;
; In: A = the byte - $F0 (Z for $F0). $F0: +$09 = the next byte
; (CommandLengthByte $C29A). $F1-$FF: AYEnvelopeShape $C101 = 1-15, written
; (and the envelope restarted) at this frame's WriteAY $C15F.
;
; Witness: L1 706 (c x4).
CommandLength:
  JR Z,CommandLengthByte
  LD (AYEnvelopeShape),A
  RET
CommandLengthByte:
  LD A,(DE)               ; $F0: the next byte is the length in rows
  INC DE
  LD (IX+$09),A
  RET

; One frame of a channel's sound: its sample and ornament rows, the period, the
; volume, the noise
;
; In: A = the channel (0-2, into CurrentChannel $C102), IX = its record. When
; the sample ended (bit 1) or no note sounds (bit 2 clear): only the volume
; register, 0. Else SampleStep $C308 and OrnamentStep $C385; AYNoise $C0FA =
; +$06 unless the sample row has noise off; the note +$02 (above $55: $55, or 0
; when an ornament took it below 0) indexes PeriodTable $C3CA, plus the tone
; offset +$03/$04: registers 2 x channel and 2 x channel + 1 (its low nibble);
; the volume +$07, with bit 4 (the envelope) when both bit 4 (envelope mode)
; and bit 5 (the row's E) are set: register 8 + channel.
;
; c1: 21 822 calls (3 a frame); 224 with the sample ended, 72 with no note.
;
; Witness: L1 41793 (c x4).
ChannelSound:
  LD (CurrentChannel),A
  XOR A
  BIT 1,(IX+$00)
  JR NZ,ChannelSoundVolume
  BIT 2,(IX+$00)
  JR Z,ChannelSoundVolume
  CALL SampleStep
  CALL OrnamentStep
  BIT 3,(IX+$01)
  JR NZ,ChannelSoundNote
  LD A,(IX+$06)
  LD (AYNoise),A
ChannelSoundNote:
  LD A,(IX+$02)           ; the note, clamped to 0-$55
  CP $56
  JR C,ChannelSoundPeriod
  RLA
  SBC A,A
  CPL
  AND $55
ChannelSoundPeriod:
  ADD A,A                 ; PeriodTable[note] + the tone offset: the channel's
                          ; two period registers
  LD B,$00
  LD C,A
  LD HL,PeriodTable
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD L,(IX+$03)
  LD H,(IX+$04)
  ADD HL,DE
  LD A,(CurrentChannel)
  ADD A,A
  LD E,A
  LD A,L
  CALL SetAYRegister
  INC E
  LD A,H
  AND $0F
  CALL SetAYRegister
  LD A,(IX+$00)
  CPL
  AND $30
  LD A,(IX+$07)
  JR NZ,ChannelSoundVolume
  OR $10
ChannelSoundVolume:
  LD D,A                  ; register 8 + channel = A
  LD A,(CurrentChannel)
  ADD A,$08
  LD E,A
  LD A,D
  JP SetAYRegister

; One row of the channel's sample: loop marks, tone offset, mixer, volume,
; noise offset
;
; In: IX. The row at +$0F/$10, three bytes: F (flags and noise delta), T (tone
; delta), M (mixer and volume). F bit 7: this row is the loop row (+$11/$12);
; bit 6: the next row is the loop row, unless released (bit 3); bit 5 (checked
; only when not looping back): the sample ends here (bit 1: silence from the
; next frame). The tone offset += T (signed); +$01 = M AND 9 (bit 0 tone off,
; bit 3 noise off); bit 5 of the flags = M bit 1 (envelope); the volume +$07 =
; (M >> 4) x (the channel volume + 1) / 16. Then AddNoise $C3BB with F's low 5
; bits.
;
; Witness: L1 40939 (c x4).
SampleStep:
  LD L,(IX+$0F)
  LD H,(IX+$10)
  LD D,H
  LD E,L
  LD A,(HL)
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  CP $20
  JR C,SampleRow
  BIT 7,A
  JR NZ,SampleLoopStart
SampleLoopEnd:
  BIT 6,A                 ; bit 6: back to the loop row, unless released
  JR NZ,SampleLoopBack
SampleEnd:
  BIT 5,A                 ; bit 5: the sample ends
  JR Z,SampleRow
  SET 1,(IX+$00)
  JR SampleRow
SampleLoopStart:
  LD (IX+$11),E           ; bit 7: this row is the loop row
  LD (IX+$12),D
  JR SampleLoopEnd
SampleLoopBack:
  BIT 3,(IX+$00)          ; not released: the next row is the loop row
  JR NZ,SampleEnd
  LD L,(IX+$11)
  LD H,(IX+$12)
SampleRow:
  LD (IX+$0F),L           ; the next row kept; the tone delta, the mixer, the
                          ; envelope bit, the volume
  LD (IX+$10),H
  LD E,C
  LD C,A
  LD A,E
  RLA
  SBC A,A
  LD D,A
  LD L,(IX+$03)
  LD H,(IX+$04)
  ADD HL,DE
  LD (IX+$03),L
  LD (IX+$04),H
  LD A,B
  AND $09
  LD (IX+$01),A
  RES 5,(IX+$00)
  BIT 1,B
  JR Z,SampleVolume
  SET 5,(IX+$00)
SampleVolume:
  LD A,B                  ; the row's volume scaled by the channel volume + 1
  RRCA
  RRCA
  RRCA
  RRCA
  AND $0F
  LD D,A
  LD B,(IX+$08)
  LD A,D
SampleVolumeLoop:
  ADD A,D                 ; A = vol x (channel volume + 1)
  DJNZ SampleVolumeLoop
  AND $F0
  RRCA
  RRCA
  RRCA
  RRCA
  LD (IX+$07),A
  JR AddNoise

; One row of the channel's ornament: loop marks, note offset, noise offset
;
; In: IX. The row at +$15/$16, two bytes: F (flags and noise delta), N (note
; delta). F bit 7: this row is the loop row (+$17/$18); bit 6: the next row is
; the loop row (always, released or not). The note +$02 += N (signed): the
; deltas add up from the note's start. Falls into AddNoise $C3BB with F.
;
; Witness: L1 40939 (c x4).
OrnamentStep:
  LD L,(IX+$15)
  LD H,(IX+$16)
  LD D,H
  LD E,L
  LD A,(HL)
  INC HL
  LD B,(HL)
  INC HL
  CP $20
  JR C,OrnamentRow
  BIT 7,A
  JR NZ,OrnamentLoopStart
OrnamentLoopEnd:
  BIT 6,A                 ; bit 6: back to the loop row
  JR Z,OrnamentRow
  LD L,(IX+$17)
  LD H,(IX+$18)
  JR OrnamentRow
OrnamentLoopStart:
  LD (IX+$17),E           ; bit 7: this row is the loop row
  LD (IX+$18),D
  JR OrnamentLoopEnd
OrnamentRow:
  LD (IX+$15),L           ; the next row kept; the note delta
  LD (IX+$16),H
  LD C,A
  LD A,B
  ADD A,(IX+$02)
  LD (IX+$02),A

; The noise period += the row's signed 5-bit noise delta
;
; In: C = the row's first byte (bits 0-4 a signed delta, -16 to 15), IX. +$06 =
; (+$06 + the delta) AND 31. Reached from SampleStep $C308 and OrnamentStep
; $C385.
;
; Witness: L1 81878 (c x4).
AddNoise:
  LD A,C
  AND $10
  NEG
  OR C
  ADD A,(IX+$06)
  AND $1F
  LD (IX+$06),A
  RET

; The AY tone period of each note 0-$55 (86 notes, A#0 to B7)
;
; Read by ChannelSound $C2A0. At the 128K's AY clock of 1.7734 MHz note n is
; MIDI n + 22 (note 0 = $0EDC, A#0, 29.1 Hz; note 2 = C1), within 1 cent up to
; the fifth octave and up to 33 cents off at the top, where the periods are
; small.
PeriodTable:
  INCBIN "res/tables/note-periods.bin",$0000,172

; Two zero bytes after the table: a note $56 would read them, but the player
; clamps the note to $55
;
; Known only from the code: no instruction reads them.
PeriodPad:
  DEFB $00,$00
