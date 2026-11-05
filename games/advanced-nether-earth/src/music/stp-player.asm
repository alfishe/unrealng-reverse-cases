; =====================================================================================================================
; New SoundTrack Player by PHANTOM FAMILY'1996: the player Pro Tracker 2.40 (Phantom Family's version of Golden
; Disk's Pro Tracker 2) compiles in front of a tune. ZXTune knows it as "Pro Tracker v2.40 Phantom Family player"
; (src/formats/packed/compiledpt2.cpp: the same first 28 bytes, player size $A45 = this code, the length word and
; the tune at +$A45); no copy of the tracker itself was found in the collection.
;
; ANE holds three copies, all assembled at $C000 from this source, each followed by `TuneLength DW` and its tune at
; $CA45 (Tune): bank 1 (the game music, X-Man's TAIGA: src/music/music-bank1.asm), bank 3 (Dead End, Syrus's NETHER
; EARTH END: src/music/dead-end-music.asm) and the intro (Syrus's MAD NIGHT, copied by the intro to bank 6 $C000:
; src/music/intro-music.asm).
;
; The tune: Pro Tracker 2's module compiled (tools/music_ptmodule.py build): the header (delay, positions count,
; loop position, 32 sample and 16 ornament pointers, the pattern table pointer, the name), the position list (pattern
; numbers times 3, end $FF), the pattern table (3 channel pointers a pattern), the channels' data, the samples (length,
; loop, 3 bytes a tick) and ornaments (length, loop, a note offset a tick). The sample, ornament and channel pointers
; are absolute; the pattern table pointer stays an offset, InitAt adds the module's address.
;
; How it works: the player is self-modifying. Each channel's state lives in the operands of its tick code (ChAOff,
; ChAPos, ChASample ...: the label is the instruction, +1 / +2 its operand); a row is read into "next" operands
; (ChANext...) and taken on the row's last tick by ApplyPending, gated by NOP / SCF opcodes the decoders patch.
; The AY registers are built in AyToneA..AyEnvShape and written by AyOut every frame.
;
; Entries: Init (+0) starts the tune at Tune; Play (+5) plays one frame (from the interrupt).
; =====================================================================================================================

; -----------------------------------------------------------------------------------------------------------------
; The entries. Init (+0): start the module that follows the player (TuneLength, then the tune at Tune); Play
; (+5): one frame, called from the interrupt. Init leaves interrupts enabled and the AY silent.
; -----------------------------------------------------------------------------------------------------------------
Init:
    LD    hl,Tune
    JR    InitAt
Play:
    JP    PlayFrame
; InitAt: start the module at HL (compiled: its sample, ornament and channel pointers absolute, the pattern table
; pointer an offset). Patches the module's tables into the code, clears the channel state, points every channel
; at ornament 0 and the loudest volume row, takes the first position and writes the silent registers.
InitAt:
    DI   
    PUSH  hl
    LD    a,(hl)                        ; the delay (ticks a row)
    LD    (Speed+1),a
    LD    (TickCount+1),a
    INC   hl
    INC   hl
    LD    a,(hl)                        ; the loop position
    INC   hl                            ; HL = the sample pointers (+3)
    LD    de,$0020
    LD    (ChASampleTable+1),hl
    LD    (ChBSampleTable+1),hl
    LD    (ChCSampleTable+1),hl
    ADD   hl,de
    ADD   hl,de                         ; HL = the ornament pointers (+67)
    LD    (ChAOrnamentTable+1),hl
    LD    (ChBOrnamentTable+1),hl
    LD    (ChCOrnamentTable+1),hl
    PUSH  hl
    LD    c,(hl)                        ; ornament 0 for every channel
    INC   hl
    LD    h,(hl)
    LD    l,c
    LD    (ChANextOrnament+1),hl
    LD    (ChBNextOrnament+1),hl
    LD    (ChAOrnament+1),hl
    LD    (ChBOrnament+1),hl
    LD    (ChCOrnament+1),hl
    POP   hl
    ADD   hl,de
    LD    b,d
    LD    e,(hl)                        ; DE = the pattern table offset (+99)
    INC   hl
    LD    d,(hl)
    INC   hl
    LD    c,$1E
    ADD   hl,bc                         ; HL = +131, the position list
    LD    (PositionPtr+1),hl
    LD    c,a
    ADD   hl,bc                         ; HL = the loop position's entry
    LD    (LoopPosition+1),hl
    POP   hl
    ADD   hl,de                         ; the pattern table, absolute
    LD    (PatternTable+1),hl
; clear the 13 AY register copies AyToneA..AyEnvPeriod
    XOR   a
    LD    b,$0D
    LD    c,b
    LD    hl,AyToneA
InitClearRegs:
    LD    (hl),a
    INC   hl
    DJNZ  InitClearRegs
; clear the 13 state bytes InitClearList names (the row counters, the noise and envelope state of each channel)
    LD    h,b
    LD    l,h
    ADD   hl,sp
    LD    b,c
    LD    sp,InitClearList
InitClearState:
    POP   de
    LD    (de),a
    DJNZ  InitClearState
    LD    sp,hl
    CPL                                 ; A = $FF: every channel off
    LD    (ChAOff+1),a
    LD    (ChBOff+1),a
    LD    (ChCOff+1),a
    AND   $2F                           ; $2F = CPL: a channel keeps "off" until its first note
    LD    (ChBNewOff),a
    LD    (ChANewOff),a
    LD    hl,VolumeTableLoudest         ; the volume row 15 (loudest) for every channel
    LD    (ChANextVolume+1),hl
    LD    (ChBNextVolume+1),hl
    LD    (ChAVolume+1),hl
    LD    (ChBVolume+1),hl
    LD    (ChCVolume+1),hl
    CALL  NextPosition
    LD    (ChAPattern+1),de             ; channel A's first row
; the AY writer: AyOut (ABC); `LD A,1: RRCA` sets carry, so AyOutSwapBC (ACB) is never chosen (a build option)
    LD    hl,AyOut
    LD    a,$01
    RRCA 
    JR    c,InitSetOut
    LD    hl,AyOutSwapBC
InitSetOut:
    LD    (AyOutVector+1),hl
    EI   
    JP    WriteAy
; NextPosition: step to the next entry of the position list (after its end marker $FF: the loop position).
; Out: DE = channel A's pattern data; channels B and C's pattern pointers set (ChBPattern, ChCPattern). The
; entry's pattern number, doubled, times 3 = its 6-byte pattern table entry.
NextPosition:
    LD    (NextPositionSp+1),sp
PositionPtr:
    LD    hl,$0000                      ; the next position's entry
    LD    a,(hl)
    ADD   a,a
    JR    nc,NextPositionTake
LoopPosition:
    LD    hl,$0000                      ; the loop position's entry
    LD    a,(hl)
    ADD   a,a
NextPositionTake:
    INC   hl
    LD    (PositionPtr+1),hl
    LD    c,a
    ADD   a,a
    ADD   a,c
    LD    c,a
    XOR   a
    LD    b,a
PatternTable:
    LD    hl,$0000                      ; the pattern table (3 channel pointers a pattern)
    ADD   hl,bc
    LD    sp,hl
    POP   hl
    EX    de,hl
    POP   hl
    LD    (ChBPattern+1),hl
    POP   hl
    LD    (ChCPattern+1),hl
NextPositionSp:
    LD    sp,$0000                      ; SP saved
    RET  
; ChannelTone: one tick of a channel's sample and ornament. In: HL = the sample's data, E = the sample position,
; C = the ornament position, OrnamentData = the ornament's data, IXL = the note, B = the channel's noise base.
; A sample tick is 3 bytes: byte 0 bit 0 = noise off, bit 1 = tone off, bit 2 = the tone offset's sign (1 add),
; bits 3-7 the noise value; byte 1 bits 4-7 the volume, bits 0-3 the tone offset's high bits; byte 2 its low
; byte. Out: HL = the tone period (NoteTable[note + ornament value] -/+ the offset), IXH = the mixer bits (bit 0
; tone off, bit 3 noise off), A' = the sample volume; AyNoise = noise value + base while the noise is on.
ChannelTone:
    LD    a,e
    ADD   a,a
    ADD   a,e
    LD    e,a
    LD    d,$00
    ADD   hl,de
    LD    a,(hl)
    RRA  
    JR    nc,ChannelToneMask
    LD    d,$04
ChannelToneMask:
    RRA  
    RL    d
    RRA  
    EX    af,af'
    INC   hl
    LD    a,(hl)
    RRCA 
    RRCA 
    RRCA 
    RRCA 
    AND   $0F
    EX    af,af'
    BIT   3,d
    JR    nz,ChannelToneOffset
    PUSH  af
    ADD   a,b
    LD    (AyNoise),a
    POP   af
ChannelToneOffset:
    LD    a,(hl)
    RLA  
    AND   $1F
    INC   hl
    LD    l,(hl)
    LD    h,a
    LD    ixh,d
    EX    de,hl
    LD    b,$00
OrnamentData:
    LD    hl,$0000                      ; the ornament's data (set by each channel before the call)
    ADD   hl,bc
    LD    a,ixl
    ADD   a,(hl)
    ADD   a,a
    LD    c,a
    LD    hl,NoteTable
    ADD   hl,bc
    LD    a,(hl)
    INC   hl
    LD    h,(hl)
    LD    l,a
    SRL   d                             ; the offset's sign in bit 0 of D
    JR    c,ChannelToneAdd
    SBC   hl,de
    RET  
ChannelToneAdd:
    ADD   hl,de
    RET  
; -----------------------------------------------------------------------------------------------------------------
; Every frame: the three channels' ticks (sample and ornament positions, slides, volumes into the AY copies),
; then WriteAy. Channel A's tick; B's (from ChBOff) and C's (from ChCOff) are the same code with their own operands.
; The operands are self-modified: the label is the instruction, the value its operand (+1 / +2).
; -----------------------------------------------------------------------------------------------------------------
ChAOff:
    LD    a,$00                         ; $FF: the channel is off (volume 0), 0: on
    INC   a
    JR    z,ChAVolumeSet
ChAPos:
    LD    bc,$0000                      ; +1 the ornament position, +2 the sample position
ChASample:
    LD    de,$0000                      ; the sample
ChAOrnament:
    LD    hl,$0000                      ; the ornament
    LD    a,c                           ; the ornament's next position (at its length: its loop)
    INC   a
    CP    (hl)
    INC   hl
    JR    nz,ChAOrnamentNext
    LD    a,(hl)
ChAOrnamentNext:
    LD    (ChAPos+1),a
    INC   hl
    LD    (OrnamentData+1),hl
    EX    de,hl
    LD    a,b                           ; the sample's next position (at its length: its loop)
    LD    e,a
    INC   a
    CP    (hl)
    INC   hl
    JR    nz,ChASampleNext
    LD    a,(hl)
ChASampleNext:
    LD    (ChAPos+2),a
    INC   hl
ChANote:
    LD    ixl,$00                       ; +2 the note (0-95)
ChANoise:
    LD    b,$00                         ; +1 the noise base
    CALL  ChannelTone
ChASlide:
    LD    de,$0000                      ; the tone slide so far (glissando / portamento)
    ADD   hl,de
    LD    (AyToneA),hl
    EX    de,hl
ChASlideMode:
    LD    de,$0000                      ; +1 the slide step a tick, +2 the mode: 0 none, 1 glissando, 2 portamento
    DEC   d
    JP    m,ChAMix
    JR    z,ChASlideSign
    PUSH  hl
ChAPortaLeft:
    LD    hl,$0000                      ; portamento: the distance still to go
    LD    a,e
    AND   a
    JP    p,ChAPortaStep
    NEG  
ChAPortaStep:
    LD    c,a
    AND   a
    SBC   hl,bc
    JR    nc,ChAPortaGo
    POP   hl
ChAPortaNote:
    LD    a,$00                         ; portamento: the target note, the note once the distance is covered
    LD    (ChANote+2),a
    XOR   a
    LD    (ChASlideMode+2),a
    LD    h,a
    LD    l,a
    LD    (ChASlide+1),hl
    JR    ChAMix
ChAPortaGo:
    LD    (ChAPortaLeft+1),hl
    POP   hl
ChASlideSign:
    LD    d,$00                         ; +1 the step's high byte ($00 / $FF)
    ADD   hl,de
    LD    (ChASlide+1),hl
ChAMix:
    LD    a,ixh
    LD    (AyMixer),a
    EX    af,af'
    LD    c,a
ChAVolume:
    LD    hl,$0000                      ; the channel volume's row of VolumeTable
    ADD   hl,bc
    LD    a,(hl)
ChAEnvelope:
    OR    $00                           ; +1 $10: the volume follows the envelope (register bit 4)
ChAVolumeSet:
    LD    (AyVolumeA),a
; channel B's tick
ChBOff:
    LD    a,$00
    INC   a
    JR    z,ChBVolumeSet
ChBPos:
    LD    bc,$0000
ChBSample:
    LD    de,$0000
ChBOrnament:
    LD    hl,$0000
    LD    a,c
    INC   a
    CP    (hl)
    INC   hl
    JR    nz,ChBOrnamentNext
    LD    a,(hl)
ChBOrnamentNext:
    LD    (ChBPos+1),a
    INC   hl
    LD    (OrnamentData+1),hl
    EX    de,hl
    LD    a,b
    LD    e,a
    INC   a
    CP    (hl)
    INC   hl
    JR    nz,ChBSampleNext
    LD    a,(hl)
ChBSampleNext:
    LD    (ChBPos+2),a
    INC   hl
ChBNote:
    LD    ixl,$00
ChBNoise:
    LD    b,$00
    CALL  ChannelTone
ChBSlide:
    LD    de,$0000
    ADD   hl,de
    LD    (AyToneB),hl
    EX    de,hl
ChBSlideMode:
    LD    de,$0000
    DEC   d
    JP    m,ChBMix
    JR    z,ChBSlideSign
    PUSH  hl
ChBPortaLeft:
    LD    hl,$0000
    LD    a,e
    AND   a
    JP    p,ChBPortaStep
    NEG  
ChBPortaStep:
    LD    c,a
    AND   a
    SBC   hl,bc
    JR    nc,ChBPortaGo
    POP   hl
ChBPortaNote:
    LD    a,$00
    LD    (ChBNote+2),a
    XOR   a
    LD    (ChBSlideMode+2),a
    LD    h,a
    LD    l,a
    LD    (ChBSlide+1),hl
    JR    ChBMix
ChBPortaGo:
    LD    (ChBPortaLeft+1),hl
    POP   hl
ChBSlideSign:
    LD    d,$00
    ADD   hl,de
    LD    (ChBSlide+1),hl
ChBMix:
    LD    a,ixh                         ; the mixer bits one place up
    LD    hl,AyMixer
    RLCA 
    OR    (hl)
    LD    (hl),a
    EX    af,af'
    LD    c,a
ChBVolume:
    LD    hl,$0000
    ADD   hl,bc
    LD    a,(hl)
ChBEnvelope:
    OR    $00
ChBVolumeSet:
    LD    (AyVolumeB),a
; channel C's tick
ChCOff:
    LD    a,$00
    INC   a
    JR    z,ChCVolumeSet
ChCPos:
    LD    bc,$0000
ChCSample:
    LD    de,$0000
ChCOrnament:
    LD    hl,$0000
    LD    a,c
    INC   a
    CP    (hl)
    INC   hl
    JR    nz,ChCOrnamentNext
    LD    a,(hl)
ChCOrnamentNext:
    LD    (ChCPos+1),a
    INC   hl
    LD    (OrnamentData+1),hl
    EX    de,hl
    LD    a,b
    LD    e,a
    INC   a
    CP    (hl)
    INC   hl
    JR    nz,ChCSampleNext
    LD    a,(hl)
ChCSampleNext:
    LD    (ChCPos+2),a
    INC   hl
ChCNote:
    LD    ixl,$00
ChCNoise:
    LD    b,$00
    CALL  ChannelTone
ChCSlide:
    LD    de,$0000
    ADD   hl,de
    LD    (AyToneC),hl
    EX    de,hl
ChCSlideMode:
    LD    de,$0000
    DEC   d
    JP    m,ChCMix
    JR    z,ChCSlideSign
    PUSH  hl
ChCPortaLeft:
    LD    hl,$0000
    LD    a,e
    AND   a
    JP    p,ChCPortaStep
    NEG  
ChCPortaStep:
    LD    c,a
    AND   a
    SBC   hl,bc
    JR    nc,ChCPortaGo
ChCPortaNote:
    LD    a,$00
    LD    (ChCNote+2),a
    XOR   a
    LD    (ChCSlideMode+2),a
    LD    h,a
    LD    l,a
    LD    (ChCSlide+1),hl
    POP   hl
    JR    ChCMix
ChCPortaGo:
    LD    (ChCPortaLeft+1),hl
    POP   hl
ChCSlideSign:
    LD    d,$00
    ADD   hl,de
    LD    (ChCSlide+1),hl
ChCMix:
    LD    a,ixh                         ; the mixer bits two places up
    LD    hl,AyMixer
    RLCA 
    RLCA 
    OR    (hl)
    LD    (hl),a
    EX    af,af'
    LD    c,a
ChCVolume:
    LD    hl,$0000
    ADD   hl,bc
    LD    a,(hl)
ChCEnvelope:
    OR    $00
ChCVolumeSet:
    LD    (AyVolumeC),a
; WriteAy: the copies to the AY, from AyEnvShape down when a shape was set this row (AyEnvShape not 0), else
; from R10 down; D = $FF (register port $FFFD), E = $BF (data port: OUTD decrements B first, $BEFD decodes as
; $BFFD), C = $FD
WriteAy:
    LD    hl,AyEnvShape
    LD    de,$FFBF
    LD    c,$FD
    XOR   a
    OR    (hl)
    LD    a,$0D
AyOutVector:
    JP    $0052                         ; AyOut (AyOutSwapBC never)
; PlayFrame: the rows are read in turns: on tick 3 of a row channel A's, tick 2 channel B's, tick 1 channel C's
; and then every pending change of A and B applied (ApplyPending: the three channels change on the same tick);
; other ticks only the channels' ticks. A' collects "a sound parameter changed" while a row is read.
PlayFrame:
    XOR   a
    LD    b,a
    EX    af,af'
TickCount:
    LD    a,$03                         ; ticks left in this row
    DEC   a
    LD    (TickCount+1),a
    JR    z,PlayRowC
    DEC   a
    JR    z,PlayRowB
    DEC   a
    JP    nz,ChAOff
    LD    hl,ChARows
    DEC   (hl)
    JP    p,ChAOff
ChARowReload:
    LD    (hl),$00                      ; +1 the rows to skip after each row
ChAPattern:
    LD    de,$0000                      ; channel A's next row
    LD    a,(de)
    AND   a
    CALL  z,NextPosition
    CALL  ChADecode
    LD    (ChAPattern+1),de
    LD    (ChANewNote),a
    JP    ChAOff
PlayRowB:
    LD    hl,ChBRows
    DEC   (hl)
    JP    p,ChAOff
ChBRowReload:
    LD    (hl),$00
ChBPattern:
    LD    de,$0000
    CALL  ChBDecode
    LD    (ChBPattern+1),de
    LD    (ChBNewNote),a
    JP    ChAOff
PlayRowC:
    LD    hl,ChCRows
    DEC   (hl)
    JP    p,ApplyPending
ChCRowReload:
    LD    (hl),$00
ChCPattern:
    LD    de,$0000
    CALL  ChCDecode
    LD    (ChCPattern+1),de
; ApplyPending: channels A and B's rows, read two and one ticks ago, take effect now. Each change is gated by an
; opcode the decoders patch: NOP (no change) or SCF ($37, take it), then JR NC over the block.
ApplyPending:
    XOR   a
ChANewNote:
    NOP                                 ; SCF: a note came (or a note off)
    JR    nc,ChANewParams
    LD    (ChANewNote),a
    LD    (ChASlideMode+2),a
    LD    h,a
    LD    l,a
    LD    (ChAPos+1),hl
    LD    (ChASlide+1),hl
ChANewOff:
    CPL                                 ; CPL: the note was "off", NOP: a note
    LD    (ChAOff+1),a
ChANextNote:
    LD    a,$00
    LD    (ChANote+2),a
ChANextSample:
    LD    hl,$0000
    LD    (ChASample+1),hl
    XOR   a
ChANewParams:
    NOP                                 ; SCF: the volume, envelope flag or noise changed
    JR    nc,ChANewOrnament
    LD    (ChANewParams),a
ChANextEnvelope:
    LD    a,$00
    LD    (ChAEnvelope+1),a
ChANextNoise:
    LD    a,$00
    LD    (ChANoise+1),a
ChANextVolume:
    LD    hl,$0000
    LD    (ChAVolume+1),hl
    XOR   a
ChANewOrnament:
    NOP                                 ; SCF: an ornament came
    JR    nc,ChANewSlide
    LD    (ChAPos+1),a
    LD    (ChANewOrnament),a
ChANextOrnament:
    LD    hl,$0000
    LD    (ChAOrnament+1),hl
    XOR   a
ChANewSlide:
    NOP                                 ; SCF: a glissando / portamento / slide off came
    JR    nc,ChBNewNote
    LD    (ChANewSlide),a
ChANextPortaNote:
    LD    a,$00
    LD    (ChAPortaNote+1),a
ChANextPortaLeft:
    LD    hl,$0000
    LD    (ChAPortaLeft+1),hl
ChANextSlideSign:
    LD    a,$00
    LD    (ChASlideSign+1),a
ChANextSlideMode:
    LD    hl,$0000
    LD    (ChASlideMode+1),hl
    XOR   a
ChBNewNote:
    NOP  
    JR    nc,ChBNewParams
    LD    h,a
    LD    l,a
    LD    (ChBSlideMode+2),a
    LD    (ChBSlide+1),hl
    LD    (ChBPos+1),hl
    LD    (ChBNewNote),a
ChBNewOff:
    CPL  
    LD    (ChBOff+1),a
ChBNextNote:
    LD    a,$00
    LD    (ChBNote+2),a
ChBNextSample:
    LD    hl,$0000
    LD    (ChBSample+1),hl
    XOR   a
ChBNewParams:
    NOP  
    JR    nc,ChBNewOrnament
    LD    (ChBNewParams),a
ChBNextEnvelope:
    LD    a,$00
    LD    (ChBEnvelope+1),a
ChBNextNoise:
    LD    a,$00
    LD    (ChBNoise+1),a
ChBNextVolume:
    LD    hl,$0000
    LD    (ChBVolume+1),hl
    XOR   a
ChBNewOrnament:
    NOP  
    JR    nc,ChBNewSlide
    LD    (ChBPos+1),a
    LD    (ChBNewOrnament),a
ChBNextOrnament:
    LD    hl,$0000
    LD    (ChBOrnament+1),hl
    XOR   a
ChBNewSlide:
    NOP  
    JR    nc,NextEnvShape
    LD    (ChBNewSlide),a
ChBNextPortaLeft:
    LD    hl,$0000
    LD    (ChBPortaLeft+1),hl
ChBNextPortaNote:
    LD    a,$00
    LD    (ChBPortaNote+1),a
ChBNextSlideSign:
    LD    a,$00
    LD    (ChBSlideSign+1),a
ChBNextSlideMode:
    LD    hl,$0000
    LD    (ChBSlideMode+1),hl
NextEnvShape:
    LD    a,$00                         ; +1 the envelope shape a channel set this row (0: none)
    LD    (AyEnvShape),a
NextEnvPeriod:
    LD    hl,$0000                      ; +1 its period
    LD    (AyEnvPeriod),hl
Speed:
    LD    a,$05                         ; +1 the delay (ticks a row)
    LD    (TickCount+1),a
    XOR   a
    LD    (NextEnvShape+1),a
    JP    ChAOff
; ChANotePorta: a note after a glissando ($0E) or portamento ($0D) command. Glissando: the note plays and slides.
; Portamento: the note becomes the target (ChANextPortaNote), the current note keeps playing and slides to it.
ChANotePorta:
    LD    (ChANextPortaNote+1),a
    LD    a,(ChANextSlideMode+2)
    DEC   a
    JR    z,ChANotePortaSet
    LD    a,c
    LD    (ChANextNote+1),a
    XOR   a
ChANotePortaSet:
    LD    (ChANewOff),a
    LD    a,$37
    LD    (ChANewSlide),a
    RET  
; ChASetNote ($80-$DF, note 0-95): the row's note; A' (parameters changed) goes to ChANewParams. Out: A = $37
; (SCF) for ChANewNote, the row ends.
ChASetNote:
    EX    af,af'
    LD    (ChANewParams),a
    LD    a,(ChANote+2)
    LD    c,a
    EX    af,af'
    LD    (ChANextNote+1),a
    INC   b
    JR    z,ChANotePorta
    XOR   a
    LD    (ChANextSlideMode+2),a
    LD    (ChANewOff),a
    LD    a,$37
    RET  
; ChASetVolume ($10-$1F): the channel volume's row of VolumeTable
ChASetVolume:
    ADD   a,a
    ADD   a,a
    ADD   a,a
    ADD   a,a
    LD    hl,VolumeTable
    LD    c,a
    ADD   hl,bc
    LD    (ChANextVolume+1),hl
    LD    a,$37
    EX    af,af'
    JP    ChADecode
; ChAGliss ($0E, step): glissando, the tone slides by the step every tick
ChAGliss:
    LD    a,$37
    LD    (ChANewSlide),a
    LD    a,(de)
    INC   de
    LD    h,$01
    LD    l,a
    LD    (ChANextSlideMode+1),hl
    AND   a
    LD    a,b
    JP    p,ChAGlissSign
    CPL  
ChAGlissSign:
    LD    (ChANextSlideSign+1),a
    DEC   b
    JR    ChADecode
; ChAPortamento ($0D, step, distance word): portamento to the next note
ChAPortamento:
    LD    a,(de)
    INC   de
    LD    h,$02
    LD    l,a
    LD    (ChANextSlideMode+1),hl
    AND   a
    LD    a,b
    JP    p,ChAPortaSign
    CPL  
ChAPortaSign:
    LD    (ChANextSlideSign+1),a
    LD    a,(de)
    LD    l,a
    INC   de
    LD    a,(de)
    INC   de
    LD    h,a
    LD    (ChANextPortaLeft+1),hl
    DEC   b
    JR    ChADecode
; ChASetNoise ($01-$0B, value): the noise base
ChASetNoise:
    LD    a,(de)
    INC   de
    LD    (ChANextNoise+1),a
    LD    a,$37
    EX    af,af'
    JR    ChADecode
; ChASkip ($20-$5F): the rows to skip after each row of this channel, 0-63
ChASkip:
    LD    (ChARows),a
    LD    (ChARowReload+1),a
; -----------------------------------------------------------------------------------------------------------------
; ChADecode: read channel A's row at DE up to its note (or note off / empty row). The bytes: $E1-$FF sample
; 1-31, $E0 note off, $80-$DF note 0-95, $70 empty row, $71-$7E envelope shape 1-14 + period word, $7F
; envelope off, $60-$6F ornament 0-15, $20-$5F skip 0-63, $10-$1F volume 0-15, $0F delay + byte, $0E glissando
; + step, $0D portamento + step + distance word, $0C slide off, $01-$0B noise + value (the command number
; itself unused); $00 ends a pattern (seen by PlayFrame before channel A's row). Out: DE after the row, A = the
; ChANewNote opcode ($37 a note or off, $A7 none). B = $FF after a glissando / portamento command.
; -----------------------------------------------------------------------------------------------------------------
ChADecode:
    LD    a,(de)
    INC   de
    ADD   a,$20
    JR    c,ChASampleOrOff
    ADD   a,$60
    JR    c,ChASetNote
    ADD   a,$10
    JR    c,ChAEnvelopeOn
    ADD   a,$10
    JR    c,ChAOrnamentTable
    ADD   a,$40
    JR    c,ChASkip
    ADD   a,$10
    JR    c,ChASetVolume
    INC   a
    JR    z,ChASpeed
    INC   a
    JR    z,ChAGliss
    INC   a
    JR    z,ChAPortamento
    INC   a
    JR    nz,ChASetNoise
    XOR   a
    LD    (ChANextSlideMode+2),a
    LD    a,$37
    LD    (ChANewSlide),a
    JR    ChADecode
ChASampleOrOff:
    JR    z,ChANoteOff
ChASampleTable:
    LD    hl,$0000                      ; +1 the module's sample pointers
    ADD   a,a
    LD    c,a
    ADD   hl,bc
    LD    a,(hl)
    INC   hl
    LD    h,(hl)
    LD    l,a
    LD    (ChANextSample+1),hl
    JP    ChADecode
ChAOrnamentTable:
    LD    hl,$0000                      ; +1 the module's ornament pointers
    ADD   a,a
    LD    c,a
    ADD   hl,bc
    LD    a,(hl)
    INC   hl
    LD    h,(hl)
    LD    l,a
    LD    (ChANextOrnament+1),hl
    LD    a,$37
    LD    (ChANewOrnament),a
    JP    ChADecode
; ChANoteOff ($E0)
ChANoteOff:
    EX    af,af'
    LD    (ChANewParams),a
    LD    a,$2F
    LD    (ChANewOff),a
    LD    a,$37
    RET  
; ChAEmptyRow ($70): no note this row; A = $A7 (AND A) for ChANewNote
ChAEmptyRow:
    EX    af,af'
    LD    (ChANewParams),a
    LD    a,$A7
    RET  
; ChAEnvelopeOff ($7F)
ChAEnvelopeOff:
    XOR   a
    LD    (ChANextEnvelope+1),a
    LD    a,$37
    EX    af,af'
    JP    ChADecode
; ChAEnvelopeOn ($71-$7E, period word): the envelope shape and period, the channel's volume on the envelope
ChAEnvelopeOn:
    JR    z,ChAEmptyRow
    CP    $0F
    JR    z,ChAEnvelopeOff
    LD    (NextEnvShape+1),a
    LD    a,$10
    LD    (ChANextEnvelope+1),a
    LD    a,(de)
    LD    (NextEnvPeriod+1),a
    INC   de
    LD    a,(de)
    LD    (NextEnvPeriod+2),a
    INC   de
    LD    a,$37
    EX    af,af'
    JP    ChADecode
; ChASpeed ($0F, delay)
ChASpeed:
    LD    a,(de)
    INC   de
    LD    (Speed+1),a
    JP    ChADecode
; channel B's commands: the same as channel A's, with its own operands
ChBNotePorta:
    LD    (ChBNextPortaNote+1),a
    LD    a,(ChBNextSlideMode+2)
    DEC   a
    JP    z,ChBNotePortaSet
    LD    a,c
    LD    (ChBNextNote+1),a
    XOR   a
ChBNotePortaSet:
    LD    (ChBNewOff),a
    LD    a,$37
    LD    (ChBNewSlide),a
    RET  
ChBSetNote:
    EX    af,af'
    LD    (ChBNewParams),a
    LD    a,(ChBNote+2)
    LD    c,a
    EX    af,af'
    LD    (ChBNextNote+1),a
    INC   b
    JR    z,ChBNotePorta
    XOR   a
    LD    (ChBNextSlideMode+2),a
    LD    (ChBNewOff),a
    LD    a,$37
    RET  
ChBSetVolume:
    ADD   a,a
    ADD   a,a
    ADD   a,a
    ADD   a,a
    LD    hl,VolumeTable
    LD    c,a
    ADD   hl,bc
    LD    (ChBNextVolume+1),hl
    LD    a,$37
    EX    af,af'
    JP    ChBDecode
ChBGliss:
    LD    a,$37
    LD    (ChBNewSlide),a
    LD    a,(de)
    INC   de
    LD    h,$01
    LD    l,a
    LD    (ChBNextSlideMode+1),hl
    AND   a
    LD    a,b
    JP    p,ChBGlissSign
    CPL  
ChBGlissSign:
    LD    (ChBNextSlideSign+1),a
    DEC   b
    JR    ChBDecode
ChBPortamento:
    LD    a,(de)
    INC   de
    LD    h,$02
    LD    l,a
    LD    (ChBNextSlideMode+1),hl
    AND   a
    LD    a,b
    JP    p,ChBPortaSign
    CPL  
ChBPortaSign:
    LD    (ChBNextSlideSign+1),a
    LD    a,(de)
    LD    l,a
    INC   de
    LD    a,(de)
    INC   de
    LD    h,a
    LD    (ChBNextPortaLeft+1),hl
    DEC   b
    JR    ChBDecode
ChBSetNoise:
    LD    a,(de)
    INC   de
    LD    (ChBNextNoise+1),a
    LD    a,$37
    EX    af,af'
    JR    ChBDecode
ChBSkip:
    LD    (ChBRows),a
    LD    (ChBRowReload+1),a
ChBDecode:
    LD    a,(de)
    INC   de
    ADD   a,$20
    JR    c,ChBSampleOrOff
    ADD   a,$60
    JR    c,ChBSetNote
    ADD   a,$10
    JR    c,ChBEnvelopeOn
    ADD   a,$10
    JR    c,ChBOrnamentTable
    ADD   a,$40
    JR    c,ChBSkip
    ADD   a,$10
    JR    c,ChBSetVolume
    INC   a
    JR    z,ChBSpeed
    INC   a
    JR    z,ChBGliss
    INC   a
    JR    z,ChBPortamento
    INC   a
    JR    nz,ChBSetNoise
    XOR   a
    LD    (ChBNextSlideMode+2),a
    LD    a,$37
    LD    (ChBNewSlide),a
    JR    ChBDecode
ChBSampleOrOff:
    JR    z,ChBNoteOff
ChBSampleTable:
    LD    hl,$0000
    ADD   a,a
    LD    c,a
    ADD   hl,bc
    LD    a,(hl)
    INC   hl
    LD    h,(hl)
    LD    l,a
    LD    (ChBNextSample+1),hl
    JP    ChBDecode
ChBOrnamentTable:
    LD    hl,$0000
    ADD   a,a
    LD    c,a
    ADD   hl,bc
    LD    a,(hl)
    INC   hl
    LD    h,(hl)
    LD    l,a
    LD    (ChBNextOrnament+1),hl
    LD    a,$37
    LD    (ChBNewOrnament),a
    JP    ChBDecode
ChBNoteOff:
    EX    af,af'
    LD    (ChBNewParams),a
    LD    a,$2F
    LD    (ChBNewOff),a
    LD    a,$37
    RET  
ChBEmptyRow:
    EX    af,af'
    LD    (ChBNewParams),a
    LD    a,$A7
    RET  
ChBEnvelopeOff:
    XOR   a
    LD    (ChBNextEnvelope+1),a
    LD    a,$37
    EX    af,af'
    JP    ChBDecode
ChBEnvelopeOn:
    JR    z,ChBEmptyRow
    CP    $0F
    JR    z,ChBEnvelopeOff
    LD    (NextEnvShape+1),a
    LD    a,$10
    LD    (ChBNextEnvelope+1),a
    LD    a,(de)
    LD    (NextEnvPeriod+1),a
    INC   de
    LD    a,(de)
    LD    (NextEnvPeriod+2),a
    INC   de
    LD    a,$37
    EX    af,af'
    JP    ChBDecode
ChBSpeed:
    LD    a,(de)
    INC   de
    LD    (Speed+1),a
    JP    ChBDecode
; channel C's commands: read on the apply tick, so they set the tick's operands at once (no pending copies)
ChCSetNote:
    EX    af,af'
    LD    a,(ChCNote+2)
    LD    c,a
    EX    af,af'
    LD    (ChCNote+2),a
    INC   b
    JR    z,ChCNotePorta
    XOR   a
    LD    (ChCSlideMode+2),a
    JP    ChCNoteStart
ChCNotePorta:
    LD    (ChCPortaNote+1),a
    LD    a,(ChCSlideMode+2)
    DEC   a
    JP    z,ChCNoteStart
    LD    a,c
    LD    (ChCNote+2),a
    XOR   a
ChCNoteStart:
    LD    h,a
    LD    l,a
    LD    (ChCSlide+1),hl
    LD    (ChCOff+1),a
    LD    (ChCPos+1),hl
    RET  
ChCGliss:
    LD    a,(de)
    INC   de
    LD    h,$01
    LD    l,a
    LD    (ChCSlideMode+1),hl
    AND   a
    LD    a,b
    JP    p,ChCGlissSign
    CPL  
ChCGlissSign:
    LD    (ChCSlideSign+1),a
    DEC   b
    JR    ChCDecode
ChCPortamento:
    LD    a,(de)
    INC   de
    LD    l,a
    LD    h,$02
    LD    (ChCSlideMode+1),hl
    AND   a
    LD    a,b
    JP    p,ChCPortaSign
    CPL  
ChCPortaSign:
    LD    (ChCSlideSign+1),a
    LD    a,(de)
    LD    l,a
    INC   de
    LD    a,(de)
    INC   de
    LD    h,a
    LD    (ChCPortaLeft+1),hl
    DEC   b
    JR    ChCDecode
ChCSetNoise:
    LD    a,(de)
    INC   de
    LD    (ChCNoise+1),a
    JR    ChCDecode
ChCSkip:
    LD    (ChCRows),a
    LD    (ChCRowReload+1),a
ChCDecode:
    LD    a,(de)
    INC   de
    ADD   a,$20
    JR    c,ChCSampleOrOff
    ADD   a,$60
    JR    c,ChCSetNote
    ADD   a,$10
    JR    c,ChCEnvelopeOn
    ADD   a,$10
    JR    c,ChCOrnamentTable
    ADD   a,$40
    JR    c,ChCSkip
    ADD   a,$10
    JR    c,ChCSetVolume
    INC   a
    JR    z,ChCSpeed
    INC   a
    JR    z,ChCGliss
    INC   a
    JR    z,ChCPortamento
    INC   a
    JR    nz,ChCSetNoise
    XOR   a
    LD    (ChCSlideMode+2),a
    JR    ChCDecode
ChCSampleOrOff:
    JR    z,ChCNoteOff
ChCSampleTable:
    LD    hl,$0000
    ADD   a,a
    LD    c,a
    ADD   hl,bc
    LD    a,(hl)
    INC   hl
    LD    h,(hl)
    LD    l,a
    LD    (ChCSample+1),hl
    JP    ChCDecode
ChCOrnamentTable:
    LD    hl,$0000
    ADD   a,a
    LD    c,a
    ADD   hl,bc
    LD    a,(hl)
    INC   hl
    LD    h,(hl)
    LD    l,a
    LD    (ChCOrnament+1),hl
    XOR   a
    LD    (ChCPos+1),a
    JP    ChCDecode
ChCNoteOff:
    LD    a,$FF
    LD    (ChCOff+1),a
    RET  
ChCEnvelopeOn:
    RET   z
    CP    $0F
    JR    z,ChCEnvelopeOff
    LD    (NextEnvShape+1),a
    LD    a,$10
    LD    (ChCEnvelope+1),a
    LD    a,(de)
    LD    (NextEnvPeriod+1),a
    INC   de
    LD    a,(de)
    LD    (NextEnvPeriod+2),a
    INC   de
    JP    ChCDecode
ChCEnvelopeOff:
    XOR   a
    LD    (ChCEnvelope+1),a
    JP    ChCDecode
ChCSpeed:
    LD    a,(de)
    INC   de
    LD    (Speed+1),a
    JP    ChCDecode
ChCSetVolume:
    ADD   a,a
    ADD   a,a
    ADD   a,a
    ADD   a,a
    LD    hl,VolumeTable
    LD    c,a
    ADD   hl,bc
    LD    (ChCVolume+1),hl
    JP    ChCDecode
; AyOut: the AY copies to the AY, R13 (the envelope shape) down to R0 when NZ, else R10 down to R0 (the shape
; not retriggered); A = the first register, HL = its copy; then the mixer copy and the shape cleared (the
; channels OR their mixer bits in again next frame)
AyOut:
    JP    nz,AyOutFrom13
    SUB   $03
    LD    hl,AyVolumeC
    JP    AyOutFrom10
AyOutFrom13:
    LD    b,d
    OUT   (c),a
    LD    b,e
    OUTD 
    DEC   a
    LD    b,d
    OUT   (c),a
    LD    b,e
    OUTD 
    DEC   a
    LD    b,d
    OUT   (c),a
    LD    b,e
    OUTD 
    DEC   a
AyOutFrom10:
    LD    b,d
    OUT   (c),a
    LD    b,e
    OUTD 
    DEC   a
    LD    b,d
    OUT   (c),a
    LD    b,e
    OUTD 
    DEC   a
    LD    b,d
    OUT   (c),a
    LD    b,e
    OUTD 
    DEC   a
    LD    b,d
    OUT   (c),a
    LD    b,e
    OUTD 
    DEC   a
    LD    b,d
    OUT   (c),a
    LD    b,e
    OUTD 
    DEC   a
    LD    b,d
    OUT   (c),a
    LD    b,e
    OUTD 
    DEC   a
    LD    b,d
    OUT   (c),a
    LD    b,e
    OUTD 
    DEC   a
    LD    b,d
    OUT   (c),a
    LD    b,e
    OUTD 
    DEC   a
    LD    b,d
    OUT   (c),a
    LD    b,e
    OUTD 
    DEC   a
AyOutLast2:
    LD    b,d
    OUT   (c),a
    LD    b,e
    OUTD 
    DEC   a
    LD    b,d
    OUT   (c),a
    LD    b,e
    OUTD 
    LD    (AyMixer),a
    LD    (AyEnvShape),a
    RET  
; AyOutSwapBC: the same with channels B and C swapped (ACB): volumes, tones and the mixer bits; not used here
AyOutSwapBC:
    JP    nz,AyOutSwapFrom13
    LD    a,$0A
    JP    AyOutSwapFrom10
AyOutSwapFrom13:
    LD    b,d
    OUT   (c),a
    LD    b,e
    OUTD 
    DEC   a
    LD    b,d
    OUT   (c),a
    LD    b,e
    OUTD 
    DEC   a
    LD    b,d
    OUT   (c),a
    LD    b,e
    OUTD 
    DEC   a
AyOutSwapFrom10:
    LD    b,d
    OUT   (c),a
    LD    hl,(AyVolumeB)
    LD    b,e
    OUT   (c),l
    DEC   a
    LD    b,d
    OUT   (c),a
    LD    b,e
    OUT   (c),h
    LD    hl,(AyMixer)
    DEC   a
    LD    b,d
    OUT   (c),a
    LD    b,e
    OUT   (c),h
    DEC   a
    LD    b,d
    OUT   (c),a
    LD    a,l
    AND   $36
    LD    h,a
    RLA  
    SRL   h
    OR    h
    AND   $36
    LD    h,a
    LD    a,l
    AND   $C9
    OR    h
    LD    b,e
    OUT   (c),a
    LD    a,$06
    LD    b,d
    OUT   (c),a
    LD    hl,(AyToneCHigh)
    LD    b,e
    OUT   (c),h
    RRCA 
    LD    b,d
    OUT   (c),a
    LD    b,e
    OUT   (c),l
    DEC   a
    LD    b,d
    OUT   (c),a
    LD    hl,(AyToneBHigh)
    LD    b,e
    OUT   (c),h
    LD    a,$05
    LD    b,d
    OUT   (c),a
    LD    b,e
    OUT   (c),l
    DEC   a
    LD    b,d
    OUT   (c),a
    LD    hl,(AyToneB)
    LD    b,e
    OUT   (c),l
    LD    a,$01
    LD    hl,AyToneAHigh
    JP    AyOutLast2
; InitClearList: the 13 state bytes InitAt clears
InitClearList:
    DW ChARows
    DW ChBRows
    DW ChCRows
    DW ChANextNoise+1
    DW ChBNextNoise+1
    DW ChANoise+1
    DW ChBNoise+1
    DW ChCNoise+1
    DW ChANextEnvelope+1
    DW ChBNextEnvelope+1
    DW ChAEnvelope+1
    DW ChBEnvelope+1
    DW ChCEnvelope+1
; NoteTable: 96 tone periods, note 0 = $0EF8 (Sound Tracker's table)
NoteTable:
    DW $0EF8,$0E10,$0D60,$0C80,$0BD8,$0B28,$0A88,$09F0,$0960,$08E0,$0858,$07E0
    DW $077C,$0708,$06B0,$0640,$05EC,$0594,$0544,$04F8,$04B0,$0470,$042C,$03FD
    DW $03BE,$0384,$0358,$0320,$02F6,$02CA,$02A2,$027C,$0258,$0238,$0216,$01F8
    DW $01DF,$01C2,$01AC,$0190,$017B,$0165,$0151,$013E,$012C,$011C,$010A,$00FC
    DW $00EF,$00E1,$00D6,$00C8,$00BD,$00B2,$00A8,$009F,$0096,$008E,$0085,$007E
    DW $0077,$0070,$006B,$0064,$005E,$0059,$0054,$004F,$004B,$0047,$0042,$003F
    DW $003B,$0038,$0035,$0032,$002F,$002C,$002A,$0027,$0025,$0023,$0021,$001F
    DW $001D,$001C,$001A,$0019,$0017,$0016,$0015,$0013,$0012,$0011,$0010,$000F
; VolumeTable: 16 rows of 16, row = the channel volume, column = the sample volume: the AY volume
VolumeTable:
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01
    DB $00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02
    DB $00,$00,$00,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$03,$03,$03
    DB $00,$00,$01,$01,$01,$01,$02,$02,$02,$02,$03,$03,$03,$03,$04,$04
    DB $00,$00,$01,$01,$01,$02,$02,$02,$03,$03,$03,$04,$04,$04,$05,$05
    DB $00,$00,$01,$01,$02,$02,$02,$03,$03,$04,$04,$04,$05,$05,$06,$06
    DB $00,$00,$01,$01,$02,$02,$03,$03,$04,$04,$05,$05,$06,$06,$07,$07
    DB $00,$01,$01,$02,$02,$03,$03,$04,$04,$05,$05,$06,$06,$07,$07,$08
    DB $00,$01,$01,$02,$02,$03,$04,$04,$05,$05,$06,$07,$07,$08,$08,$09
    DB $00,$01,$01,$02,$03,$03,$04,$05,$05,$06,$07,$07,$08,$09,$09,$0A
    DB $00,$01,$01,$02,$03,$04,$04,$05,$06,$07,$07,$08,$09,$0A,$0A,$0B
    DB $00,$01,$02,$02,$03,$04,$05,$06,$06,$07,$08,$09,$0A,$0A,$0B,$0C
    DB $00,$01,$02,$03,$03,$04,$05,$06,$07,$08,$09,$0A,$0A,$0B,$0C,$0D
    DB $00,$01,$02,$03,$04,$05,$06,$07,$07,$08,$09,$0A,$0B,$0C,$0D,$0E
VolumeTableLoudest:
    DB $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F; row 15
; the channels' row counters (rows still to skip) and the AY register copies R0-R13
ChARows:
    DB $00
ChBRows:
    DB $00
ChCRows:
    DB $00
AyToneA:
    DB $00
AyToneAHigh:
    DB $00
AyToneB:
    DB $00
AyToneBHigh:
    DB $00
AyToneC:
    DB $00
AyToneCHigh:
    DB $00
AyNoise:
    DB $00
AyMixer:
    DB $00
AyVolumeA:
    DB $00
AyVolumeB:
    DB $00
AyVolumeC:
    DB $00
AyEnvPeriod:
    DB $00,$00
AyEnvShape:
    DB $00
; the player's name
PlayerName:
    DB "New SoundTrack P"
    DB "layer By PHANTOM"
    DB " FAMILY'1996"
PlayerEnd:
