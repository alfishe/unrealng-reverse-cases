;=====================================================================================================================
; PT 3 Player v1.0 by Nick of GDC: the compile player of Pro Tracker 3.x (Golden Disk, Voronezh)
;=====================================================================================================================
;
; The player Pro Tracker 3.x writes in front of a compiled tune: its own string "PT 3 Player v1.0 by Nick of
; GDC" at +$0B, the module right after the player at +$E21 (Pt3Module). No ORG here: the includer sets it
; (ORG $C000 or ORG $DB00); every address inside the player is a label, and the tables sit at page offsets
; ($xxA0, $xxE0, $xx00) the code relies on, so the start must be a multiple of 256.
;
; Entries (Pt3Init +0, +5, +8):
;   Pt3Init   +0  LD HL,Pt3Module and the module set-up (InitModule): the pointers, the delay, every
;                 channel muted, the AY written silent. DI, returns with interrupts still off.
;   Pt3Play   +5  JP: one frame (call from the 50 Hz interrupt, interrupts off: it uses SP as a data
;                 pointer and IYL as a scratch, IY = $5C3A again on return).
;   Pt3Stop   +8  JP: the AY silent (the three volumes 0, the registers written once).
;
; The module: the PT3 file form as Pro Tracker 3 saves it (+0 "ProTracker 3.x compilation of ...", +99 the
; tone table number, +100 the delay, +101 the number of positions, +102 the loop position, +103 the pattern
; table offset, +105 32 sample offsets, +169 16 ornament offsets, +201 the position list (pattern * 3,
; $FF end)); every pointer is an offset from the module's start: InitModule adds the address (into
; SamplePtrs / OrnamentPtrs and the operands of the readers). The player ignores +99 and +13 (the version
; digit): it carries one tone table (NoteTable: table #1, Sound Tracker's) and one volume table.
;
; In Advanced Nether Earth: the boot music (bank 1 $C000, X-Man's TOMY at $CE21; Pt3Init is CALLed by
; UltraXOR's sector reader after bank 1 is read, Pt3Play from the boot program's interrupt) and Final
; Cut's music (the same source at ORG $DB00 with X-Man's REM at $E921, copied from Final Cut's image
; $8BF5). The two copies differ only in the high bytes of the addresses ($C0xx / $DBxx).
;
; How it works (a frame):
;   1. the three channel ticks (ChAMute..., ChBMute..., ChCMute...): sample line, volume (VolumeTable),
;      noise / envelope offset, mixer, ornament, tone (NoteTable) + slide, on-off; the envelope slide;
;   2. WriteAy: registers 0-12 from the AY block at a page start (L = the register number), 13 only when
;      a new envelope type was set (EnvType);
;   3. the pattern reading, spread over three frames by RowFrame: channel A's row two frames before
;      the row, B's one frame before, C's on the row's frame. A and B are decoded into a staging area
;      (the operands of the blocks from ChANewNoteJr on, each block skipped by a JR / JP whose
;      displacement the decoder clears), C applies its row at once; the staged A and B blocks run right
;      after C's decode, so all three channels change on the same frame. RowFrame is reloaded with the
;      delay there: the player needs a delay of 3 or more (with 2 channel A is never decoded, with 1
;      neither A nor B).
;
; The channel bytes (the decoders ChADecodeByte, ChBDecodeByte, ChCDecodeByte; B = $10, C = $20 step the
; accumulator through the ranges with ADD and the carry):
;   $F0-$FF ornament n + the next byte: sample * 2 (envelope off, ornament from its start)
;   $D1-$EF sample n-$D0 (for the next note)        $D0  the row ends, nothing new
;   $C1-$CF volume n-$C0                            $C0  sound off, the row ends
;   $B2-$BF envelope type n-$B1 + period (2 bytes, high first); $B1 + byte: rows to skip; $B0 envelope off
;   $50-$AF note n-$50, the row ends                 $40-$4F ornament n-$40
;   $11-$1F envelope type n-$10 + period (2 bytes) + sample * 2;  $10 envelope off + sample * 2
;   $20-$3F noise base n-$20 in channel B (A and C take them as $11-$1F, a quirk of this player)
;   $01-$09 an effect: its routine's address (ChAEffects...) is pushed and runs after the row's note, its
;           parameters follow the row's bytes (1 gliss: delay, step word; 2 portamento: delay, distance
;           word, step word; 3 sample offset; 4 ornament offset; 5 on-off: off frames, on frames; 8
;           envelope slide: delay, step word; 9 delay; 6 and 7 do nothing ($0052 in the 48 K ROM, a RET:
;           the 48 K BASIC ROM must be paged in)
;   $00     at the start of channel A's row: the pattern ends, the next position
;
; Against S.V.Bulba's PT3 player (ayplayers/PTx.a80, Vortex Tracker II), which plays the same format and
; whose effects this one matches in function: Bulba builds his note and volume tables at init (Ivan
; Roshin's creators, four tone tables in their 3.3x-3.4r / 3.4x+ forms, the volume table in the 3.3x-3.4x
; or 3.5x+ form, chosen by the module's +99 and version digit); this player carries one tone table, equal
; to table #1 (Sound Tracker's) in both forms, and the volume table equal to the 3.5x+ form, and uses
; them for every module. Bulba keeps the channel state in IX-indexed records and computes the
; portamento's distance from the note table; this player keeps every value in the operands of its own
; code (three unrolled channels), reads the distance the tracker stored in the effect's parameters and
; spreads the pattern reading over three frames. No plain copy of the player was found in the
; collection (every Pro Tracker 3.x there is packed), so it is identified by its string and its use.
;
; Known bug: channel B's on-off effect (ChBEffOnOff) sets ChBOnOffJp to jump to itself: the player hangs
; on the row that applies it (channel A's twin is right: ChAEffOnOff, ChAOnOffApply).

    MODULE Pt3

OpRet       EQU $C9
OpIyPrefix  EQU $FD
OpCpl       EQU $2F
EnvOn       EQU $1F                     ; the envelope mask: bit 4 of the volume kept
EnvOff      EQU $0F                     ; ... cleared

@Pt3Init:
    LD    hl,Pt3Module
    JR    InitModule
@Pt3PlayEntry:
    JP    Pt3Play
@Pt3StopEntry:
    JP    Pt3Stop
PlayerId:
    DB " PT 3 Player v1."
    DB "0 by Nick of GDC"
    DB $20

;---------------------------------------------------------------------------------------------------------------------
; InitModule: HL = the module. The module address into every reader's operand, the delay, the
; position pointers (the start and the loop), the pattern table, the 48 sample and ornament
; pointers (offsets + the address) copied to SamplePtrs / OrnamentPtrs; then InitState.
InitModule:
    DI   
    LD    (InitPositions+1),hl
    LD    (InitPatterns+1),hl
    LD    (InitPointerBase+1),hl
    LD    (ModuleAddr+1),hl
    LD    bc,100                        ; +100: the delay
    ADD   hl,bc
    LD    a,(hl)
    LD    (Delay+1),a
    INC   hl
    INC   hl
    LD    e,(hl)
    INC   hl
    LD    d,b
    PUSH  hl
InitPositions:
    LD    hl,$0000
    LD    c,201                         ; +201: the position list
    ADD   hl,bc
    LD    (PositionPtr+1),hl
    ADD   hl,de
    LD    (LoopPositionPtr+1),hl
    POP   hl
    LD    c,(hl)
    INC   hl
    LD    b,(hl)
    INC   hl
    LD    (InitSp+1),sp
    LD    sp,hl
InitPatterns:
    LD    hl,$0000
    ADD   hl,bc
    LD    (PatternTable+1),hl
    LD    de,SamplePtrs
    LD    a,48                          ; 32 sample + 16 ornament pointers
InitPointerLoop:
    POP   bc
InitPointerBase:
    LD    hl,$0000
    ADD   hl,bc
    EX    de,hl
    LD    (hl),e
    INC   hl
    LD    (hl),d
    INC   hl
    EX    de,hl
    DEC   a
    JR    nz,InitPointerLoop
InitSp:
    LD    sp,$0000
    LD    a,$F0                         ; volume 15 (its row of VolumeTable)
    LD    (ChAVolume+1),a
    LD    (ChBVolume+1),a
    LD    (ChCVolume+1),a
    LD    hl,(OrnamentPtrs)
    LD    (ChCOrnamentPtr+1),hl
    LD    (ChAOrnamentPtr+1),hl
    LD    (ChBOrnamentPtr+1),hl
    LD    hl,(SamplePtrs)
    LD    (ChANewSample+1),hl
    LD    (ChBNewSample+1),hl
    LD    a,3                           ; RowFrame: A decoded on the next frame
    JP    InitState

; 32 sample pointers (module address added by InitModule); at a page offset $A0: the decoders index it by the low byte
SamplePtrs:
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; 16 ornament pointers, right after the samples (page offset $E0)
OrnamentPtrs:
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; VolumeTable: 16 x 16 bytes at a page start: [channel volume * 16 + sample level] -> the AY
; volume. Equal to Ivan Roshin's creator in its Pro Tracker 3.5x+ form (rounded: row 1 = 0 x 8, 1 x 8).
; Its first byte (0) is also the "end of pattern" InitState points channel A at.
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
    DB $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F

; NoteTable: 96 tone periods (words, notes C-1 .. B-8 of the tracker), at a page start: PT3's
; tone table #1 (Sound Tracker's, $0EF8 for the lowest note), the only one this player has.
; The effect tables follow it in the same page (the decoders index them by the low byte).
NoteTable:
    DB $F8,$0E,$10,$0E,$60,$0D,$80,$0C,$D8,$0B,$28,$0B,$88,$0A,$F0,$09
    DB $60,$09,$E0,$08,$58,$08,$E0,$07,$7C,$07,$08,$07,$B0,$06,$40,$06
    DB $EC,$05,$94,$05,$44,$05,$F8,$04,$B0,$04,$70,$04,$2C,$04,$FD,$03
    DB $BE,$03,$84,$03,$58,$03,$20,$03,$F6,$02,$CA,$02,$A2,$02,$7C,$02
    DB $58,$02,$38,$02,$16,$02,$F8,$01,$DF,$01,$C2,$01,$AC,$01,$90,$01
    DB $7B,$01,$65,$01,$51,$01,$3E,$01,$2C,$01,$1C,$01,$0A,$01,$FC,$00
    DB $EF,$00,$E1,$00,$D6,$00,$C8,$00,$BD,$00,$B2,$00,$A8,$00,$9F,$00
    DB $96,$00,$8E,$00,$85,$00,$7E,$00,$77,$00,$70,$00,$6B,$00,$64,$00
    DB $5E,$00,$59,$00,$54,$00,$4F,$00,$4B,$00,$47,$00,$42,$00,$3F,$00
    DB $3B,$00,$38,$00,$35,$00,$32,$00,$2F,$00,$2C,$00,$2A,$00,$27,$00
    DB $25,$00,$23,$00,$21,$00,$1F,$00,$1D,$00,$1C,$00,$1A,$00,$19,$00
    DB $17,$00,$16,$00,$15,$00,$13,$00,$12,$00,$11,$00,$10,$00,$0F,$00

; The effect routines of the three channels, effects 1-9 (6 and 7 unused: $0052, a RET in the 48 K ROM).
ChAEffects:
    DW ChAEffGliss
    DW ChAEffPorta
    DW ChAEffSampleOffset
    DW ChAEffOrnOffset
    DW ChAEffOnOff
    DW $0052
    DW $0052
    DW EffEnvSlide
    DW EffDelay
ChBEffects:
    DW ChBEffGliss
    DW ChBEffPorta
    DW ChBEffSampleOffset
    DW ChBEffOrnOffset
    DW ChBEffOnOff
    DW $0052
    DW $0052
    DW EffEnvSlide
    DW EffDelay
ChCEffects:
    DW ChCEffGliss
    DW ChCEffPorta
    DW ChCEffSampleOffset
    DW ChCEffOrnOffset
    DW ChCEffOnOff
    DW $0052
    DW $0052
    DW EffEnvSlide
    DW EffDelay

; Unused, up to the page start the AY block needs.
AyPad:
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The AY block, at a page start (WriteAy uses L as the register number): registers 0-12.
AyToneA:
    DB $00,$00
AyToneB:
    DB $00,$00
AyToneC:
    DB $00,$00
AyUnused:                               ; registers 6 and 7: WriteAy takes IXH and IXL instead
    DB $00,$00
AyVolumeA:
    DB $00
AyVolumeB:
    DB $00
AyVolumeC:
    DB $00
AyEnvPeriod:
    DB $00,$00
AyEnvTypeUnused:                        ; register 13: written from EnvType, not from here
    DB $00

;---------------------------------------------------------------------------------------------------------------------
; InitState: the channels' start values: RowFrame 3, every row skip counter 1 (decode on the first
; frame), the channels muted, the envelope masks off, RowCounter -1, channel A's pattern pointer at
; a 0 byte (VolumeTable's first) so that the first frame reads position 0. Falls into Pt3Stop.
InitState:
    LD    (ChCSamplePtr+1),hl
    LD    (RowFrame+1),a
    LD    a,$01
    LD    (ChARowSkip+1),a
    LD    (ChBRowSkip+1),a
    LD    (ChCRowSkip+1),a
    LD    a,$FF
    LD    (ChAMute+1),a
    LD    (ChCMute+1),a
    LD    (ChBMute+1),a
    LD    l,a
    LD    h,a
    LD    (RowCounter+1),hl
    LD    a,EnvOff
    LD    (ChAEnvMask+1),a
    LD    (ChBEnvMask+1),a
    LD    (ChCEnvMask+1),a
    LD    hl,VolumeTable
    LD    (ChAPatternPtr+1),hl

;---------------------------------------------------------------------------------------------------------------------
; Pt3Stop: the three volumes 0, then WriteAy with RestoreIy patched to RET (only the AY write).
Pt3Stop:
    XOR   a
    LD    (AyVolumeA),a
    LD    (AyVolumeB),a
    LD    (AyVolumeC),a
    LD    a,OpRet
    LD    (RestoreIy),a
    CALL  WriteAy
    LD    a,OpIyPrefix
    LD    (RestoreIy),a
    RET  

;---------------------------------------------------------------------------------------------------------------------
; Pt3Play: one frame. IYL = 0 (the envelope offset of the samples), IX = the noise of the last
; frame (IXH) and the mixer 0 (IXL); SP saved in PlaySp (the ticks read with POP).
; NoiseMixer+3 = IXH: the noise is kept from frame to frame.
Pt3Play:
    LD    iyl,$00
NoiseMixer:
    LD    ix,$0000
    LD    (PlaySp+1),sp

;---------------------------------------------------------------------------------------------------------------------
; Channel A, one tick: the sample line, the volume, the noise or envelope offset, the mixer bits, the
; ornament, the tone and its slide. Runs every frame; the channel's state lives in the operands of these
; instructions (each label names the value its operand holds). Out: the tone in the AY block, the volume
; in AyVolumeA (0 when muted), the mixer bits ORed into IXL, the noise into IXH, the envelope
; offset added to IYL.
;
; ChAMute: 0 while the channel sounds, $FF when it is off ($C0, before the first note, or the on-off
; effect's off phase).
ChAMute:
    LD    a,$FF
    LD    h,a
    INC   a
    JP    z,ChAStoreVolume
ChASamplePtr:
    LD    sp,$0000
    POP   de
ChASamplePos:
    LD    a,$00
    LD    l,a
    INC   a
    CP    d
    JR    nz,ChASampleStep
    LD    a,e
ChASampleStep:
    LD    (ChASamplePos+1),a
    LD    a,l
    ADD   a,a
    ADD   a,a
    LD    l,a
    ADD   hl,sp
    LD    sp,hl
    POP   de
    LD    a,d
    AND   $0F
    LD    l,a
    LD    a,e
    AND   a
    JP    p,ChAVolSlide
    AND   $40
    LD    a,(ChAVolSlide+1)
    JP    nz,ChAVolSlideUp
    DEC   a
    CP    $F0
    JR    nz,ChAVolSlideSet
    INC   a
    JP    ChAVolSlideSet
ChAVolSlideUp:
    INC   a
    CP    $10
    JR    nz,ChAVolSlideSet
    DEC   a
ChAVolSlideSet:
    LD    (ChAVolSlide+1),a
ChAVolSlide:
    LD    a,$00
    ADD   a,l
    JP    p,ChALevelHigh
    XOR   a
    JP    ChAVolume
ChALevelHigh:
    CP    $10
    JR    c,ChAVolume
    LD    a,$0F
ChAVolume:
    ADD   a,$00
    LD    h,HIGH VolumeTable
    LD    l,a
    LD    a,(hl)
    SRL   e
    JR    c,ChAEnvMask
    OR    $10
ChAEnvMask:
    AND   $0F
    EX    af,af'
    LD    a,d
    LD    l,a
    RLCA 
    JR    c,ChAEnvOffset
    LD    h,a
ChANoiseAcc:
    LD    a,$00
    ADD   a,e
    BIT   5,l
    JR    z,ChANoiseSet
    LD    (ChANoiseAcc+1),a
ChANoiseSet:
    LD    ixh,a
    LD    a,h
    JP    ChAMixer
ChAEnvOffset:
    LD    h,a
    LD    a,e
    AND   $1F
    CP    $10
    JR    c,ChAEnvOffsetAcc
    OR    $F0
ChAEnvOffsetAcc:
    ADD   a,$00
    BIT   5,l
    JR    z,ChAEnvOffsetAdd
    LD    (ChAEnvOffsetAcc+1),a
ChAEnvOffsetAdd:
    ADD   a,iyl
    LD    iyl,a
    LD    a,h
ChAMixer:
    RLCA 
    RLCA 
    RLCA 
    AND   $09
    LD    ixl,a
    POP   bc
    LD    a,l
ChAToneAcc:
    LD    hl,$0000
    ADD   hl,bc
    AND   $40
    JR    z,ChAOrnament
    LD    (ChAToneAcc+1),hl
ChAOrnament:
    EX    de,hl
ChAOrnamentPtr:
    LD    sp,$0000
    POP   bc
ChAOrnamentPos:
    LD    a,$00
    LD    l,a
    INC   a
    CP    b
    JR    nz,ChAOrnamentStep
    LD    a,c
ChAOrnamentStep:
    LD    (ChAOrnamentPos+1),a
    LD    h,$00
    ADD   hl,sp
    LD    l,(hl)
    LD    h,HIGH NoteTable
ChANote:
    LD    a,$00
    ADD   a,l
    ADD   a,a
    LD    l,a
    LD    sp,hl
    POP   hl
    ADD   hl,de
ChAToneSlide:
    LD    de,$0000
    ADD   hl,de
    LD    (AyToneA),hl
ChAGlissCount:
    LD    a,$00
    DEC   a
    JP    m,ChATickEnd
    JR    nz,ChAGlissStore
ChAGlissStep:
    LD    hl,$0000
    ADD   hl,de
    LD    (ChAToneSlide+1),hl
ChAPortaJr:
    JR    ChAGlissReload
    EX    de,hl
ChAPortaDistance:
    LD    hl,$0000
    JR    nc,ChAPortaSub
    ADD   hl,de
    JP    ChAPortaTest
ChAPortaSub:
    SBC   hl,de
ChAPortaTest:
    INC   h
    JR    nz,ChAGlissReload
ChAPortaNote:
    LD    a,$00
    LD    (ChANote+1),a
    XOR   a
    LD    (ChAGlissCount+1),a
    LD    l,a
    LD    (ChAToneSlide+1),hl
    JP    ChATickEnd
ChAGlissReload:
    LD    a,$00
ChAGlissStore:
    LD    (ChAGlissCount+1),a
ChATickEnd:
    EX    af,af'
ChAStoreVolume:
    LD    (AyVolumeA),a
ChAOnOffCount:
    LD    a,$00
    DEC   a
    JP    m,ChBMute
    JR    nz,ChAOnOffStore
    LD    a,(ChAMute+1)
    XOR   $FF
    LD    (ChAMute+1),a
    JP    z,ChAOnTime
ChAOffTime:
    LD    a,$00
    JP    ChAOnOffStore
ChAOnTime:
    LD    a,$00
ChAOnOffStore:
    LD    (ChAOnOffCount+1),a

;---------------------------------------------------------------------------------------------------------------------
; Channel B, one tick: the sample line, the volume, the noise or envelope offset, the mixer bits, the
; ornament, the tone and its slide. Runs every frame; the channel's state lives in the operands of these
; instructions (each label names the value its operand holds). Out: the tone in the AY block, the volume
; in AyVolumeB (0 when muted), the mixer bits ORed into IXL, the noise into IXH, the envelope
; offset added to IYL.
;
; ChBMute: 0 while the channel sounds, $FF when it is off ($C0, before the first note, or the on-off
; effect's off phase).
ChBMute:
    LD    a,$FF
    LD    h,a
    INC   a
    JP    z,ChBStoreVolume
ChBSamplePtr:
    LD    sp,$0000
    POP   de
ChBSamplePos:
    LD    a,$00
    LD    l,a
    INC   a
    CP    d
    JR    nz,ChBSampleStep
    LD    a,e
ChBSampleStep:
    LD    (ChBSamplePos+1),a
    LD    a,l
    ADD   a,a
    ADD   a,a
    LD    l,a
    ADD   hl,sp
    LD    sp,hl
    POP   de
    LD    a,d
    AND   $0F
    LD    l,a
    LD    a,e
    AND   a
    JP    p,ChBVolSlide
    AND   $40
    LD    a,(ChBVolSlide+1)
    JP    nz,ChBVolSlideUp
    DEC   a
    CP    $F0
    JR    nz,ChBVolSlideSet
    INC   a
    JP    ChBVolSlideSet
ChBVolSlideUp:
    INC   a
    CP    $10
    JR    nz,ChBVolSlideSet
    DEC   a
ChBVolSlideSet:
    LD    (ChBVolSlide+1),a
ChBVolSlide:
    LD    a,$00
    ADD   a,l
    JP    p,ChBLevelHigh
    XOR   a
    JP    ChBVolume
ChBLevelHigh:
    CP    $10
    JR    c,ChBVolume
    LD    a,$0F
ChBVolume:
    ADD   a,$00
    LD    h,HIGH VolumeTable
    LD    l,a
    LD    a,(hl)
    SRL   e
    JR    c,ChBEnvMask
    OR    $10
ChBEnvMask:
    AND   $0F
    EX    af,af'
    LD    a,d
    LD    l,a
    RLCA 
    JR    c,ChBEnvOffset
    LD    h,a
ChBNoiseAcc:
    LD    a,$00
    ADD   a,e
    BIT   5,l
    JR    z,ChBNoiseSet
    LD    (ChBNoiseAcc+1),a
ChBNoiseSet:
    LD    ixh,a
    LD    a,h
    JP    ChBMixer
ChBEnvOffset:
    LD    h,a
    LD    a,e
    AND   $1F
    CP    $10
    JR    c,ChBEnvOffsetAcc
    OR    $F0
ChBEnvOffsetAcc:
    ADD   a,$00
    BIT   5,l
    JR    z,ChBEnvOffsetAdd
    LD    (ChBEnvOffsetAcc+1),a
ChBEnvOffsetAdd:
    ADD   a,iyl
    LD    iyl,a
    LD    a,h
ChBMixer:
    RLCA 
    RLCA 
    RLCA 
    RLCA 
    AND   $12
    OR    ixl
    LD    ixl,a
    POP   bc
    LD    a,l
ChBToneAcc:
    LD    hl,$0000
    ADD   hl,bc
    AND   $40
    JR    z,ChBOrnament
    LD    (ChBToneAcc+1),hl
ChBOrnament:
    EX    de,hl
ChBOrnamentPtr:
    LD    sp,$0000
    POP   bc
ChBOrnamentPos:
    LD    a,$00
    LD    l,a
    INC   a
    CP    b
    JR    nz,ChBOrnamentStep
    LD    a,c
ChBOrnamentStep:
    LD    (ChBOrnamentPos+1),a
    LD    h,$00
    ADD   hl,sp
    LD    l,(hl)
    LD    h,HIGH NoteTable
ChBNote:
    LD    a,$00
    ADD   a,l
    ADD   a,a
    LD    l,a
    LD    sp,hl
    POP   hl
    ADD   hl,de
ChBToneSlide:
    LD    de,$0000
    ADD   hl,de
    LD    (AyToneB),hl
ChBGlissCount:
    LD    a,$00
    DEC   a
    JP    m,ChBTickEnd
    JR    nz,ChBGlissStore
ChBGlissStep:
    LD    hl,$0000
    ADD   hl,de
    LD    (ChBToneSlide+1),hl
ChBPortaJr:
    JR    ChBGlissReload
    EX    de,hl
ChBPortaDistance:
    LD    hl,$0000
    JR    nc,ChBPortaSub
    ADD   hl,de
    JP    ChBPortaTest
ChBPortaSub:
    SBC   hl,de
ChBPortaTest:
    INC   h
    JR    nz,ChBGlissReload
ChBPortaNote:
    LD    a,$00
    LD    (ChBNote+1),a
    XOR   a
    LD    (ChBGlissCount+1),a
    LD    l,a
    LD    (ChBToneSlide+1),hl
    JP    ChBTickEnd
ChBGlissReload:
    LD    a,$00
ChBGlissStore:
    LD    (ChBGlissCount+1),a
ChBTickEnd:
    EX    af,af'
ChBStoreVolume:
    LD    (AyVolumeB),a
ChBOnOffCount:
    LD    a,$00
    DEC   a
    JP    m,ChCMute
    JR    nz,ChBOnOffStore
    LD    a,(ChBMute+1)
    XOR   $FF
    LD    (ChBMute+1),a
    JP    z,ChBOnTime
ChBOffTime:
    LD    a,$00
    JP    ChBOnOffStore
ChBOnTime:
    LD    a,$00
ChBOnOffStore:
    LD    (ChBOnOffCount+1),a

;---------------------------------------------------------------------------------------------------------------------
; Channel C, one tick: the sample line, the volume, the noise or envelope offset, the mixer bits, the
; ornament, the tone and its slide. Runs every frame; the channel's state lives in the operands of these
; instructions (each label names the value its operand holds). Out: the tone in the AY block, the volume
; in AyVolumeC (0 when muted), the mixer bits ORed into IXL, the noise into IXH, the envelope
; offset added to IYL.
;
; ChCMute: 0 while the channel sounds, $FF when it is off ($C0, before the first note, or the on-off
; effect's off phase).
ChCMute:
    LD    a,$FF
    LD    h,a
    INC   a
    JP    z,ChCStoreVolume
ChCSamplePtr:
    LD    sp,$0000
    POP   de
ChCSamplePos:
    LD    a,$00
    LD    l,a
    INC   a
    CP    d
    JR    nz,ChCSampleStep
    LD    a,e
ChCSampleStep:
    LD    (ChCSamplePos+1),a
    LD    a,l
    ADD   a,a
    ADD   a,a
    LD    l,a
    ADD   hl,sp
    LD    sp,hl
    POP   de
    LD    a,d
    AND   $0F
    LD    l,a
    LD    a,e
    AND   a
    JP    p,ChCVolSlide
    AND   $40
    LD    a,(ChCVolSlide+1)
    JP    nz,ChCVolSlideUp
    DEC   a
    CP    $F0
    JR    nz,ChCVolSlideSet
    INC   a
    JP    ChCVolSlideSet
ChCVolSlideUp:
    INC   a
    CP    $10
    JR    nz,ChCVolSlideSet
    DEC   a
ChCVolSlideSet:
    LD    (ChCVolSlide+1),a
ChCVolSlide:
    LD    a,$00
    ADD   a,l
    JP    p,ChCLevelHigh
    XOR   a
    JP    ChCVolume
ChCLevelHigh:
    CP    $10
    JR    c,ChCVolume
    LD    a,$0F
ChCVolume:
    ADD   a,$00
    LD    h,HIGH VolumeTable
    LD    l,a
    LD    a,(hl)
    SRL   e
    JR    c,ChCEnvMask
    OR    $10
ChCEnvMask:
    AND   $0F
    EX    af,af'
    LD    a,d
    LD    l,a
    RLCA 
    JR    c,ChCEnvOffset
    LD    h,a
ChCNoiseAcc:
    LD    a,$00
    ADD   a,e
    BIT   5,l
    JR    z,ChCNoiseSet
    LD    (ChCNoiseAcc+1),a
ChCNoiseSet:
    LD    ixh,a
    LD    a,h
    JP    ChCMixer
ChCEnvOffset:
    LD    h,a
    LD    a,e
    AND   $1F
    CP    $10
    JR    c,ChCEnvOffsetAcc
    OR    $F0
ChCEnvOffsetAcc:
    ADD   a,$00
    BIT   5,l
    JR    z,ChCEnvOffsetAdd
    LD    (ChCEnvOffsetAcc+1),a
ChCEnvOffsetAdd:
    ADD   a,iyl
    LD    iyl,a
    LD    a,h
ChCMixer:
    RRCA 
    RRCA 
    RRCA 
    AND   $24
    OR    ixl
    LD    ixl,a
    POP   bc
    LD    a,l
ChCToneAcc:
    LD    hl,$0000
    ADD   hl,bc
    AND   $40
    JR    z,ChCOrnament
    LD    (ChCToneAcc+1),hl
ChCOrnament:
    EX    de,hl
ChCOrnamentPtr:
    LD    sp,$0000
    POP   bc
ChCOrnamentPos:
    LD    a,$00
    LD    l,a
    INC   a
    CP    b
    JR    nz,ChCOrnamentStep
    LD    a,c
ChCOrnamentStep:
    LD    (ChCOrnamentPos+1),a
    LD    h,$00
    ADD   hl,sp
    LD    l,(hl)
    LD    h,HIGH NoteTable
ChCNote:
    LD    a,$00
    ADD   a,l
    ADD   a,a
    LD    l,a
    LD    sp,hl
    POP   hl
    ADD   hl,de
ChCToneSlide:
    LD    de,$0000
    ADD   hl,de
    LD    (AyToneC),hl
ChCGlissCount:
    LD    a,$00
    DEC   a
    JP    m,ChCTickEnd
    JR    nz,ChCGlissStore
ChCGlissStep:
    LD    hl,$0000
    ADD   hl,de
    LD    (ChCToneSlide+1),hl
ChCPortaJr:
    JR    ChCGlissReload
    EX    de,hl
ChCPortaDistance:
    LD    hl,$0000
    JR    c,ChCPortaAdd
    SBC   hl,de
    JP    ChCPortaTest
ChCPortaAdd:
    ADD   hl,de
ChCPortaTest:
    INC   h
    JR    nz,ChCGlissReload
ChCPortaNote:
    LD    a,$00
    LD    (ChCNote+1),a
    XOR   a
    LD    (ChCGlissCount+1),a
    LD    l,a
    LD    (ChCToneSlide+1),hl
    JP    ChCTickEnd
ChCGlissReload:
    LD    a,$00
ChCGlissStore:
    LD    (ChCGlissCount+1),a
ChCTickEnd:
    EX    af,af'
ChCStoreVolume:
    LD    (AyVolumeC),a
ChCOnOffCount:
    LD    a,$00
    DEC   a
    JP    m,EnvSlideAcc
    JR    nz,ChCOnOffStore
    LD    a,(ChCMute+1)
    XOR   $FF
    LD    (ChCMute+1),a
    JP    z,ChCOnTime
ChCOffTime:
    LD    a,$00
    JP    ChCOnOffStore
ChCOnTime:
    LD    a,$00
ChCOnOffStore:
    LD    (ChCOnOffCount+1),a

;---------------------------------------------------------------------------------------------------------------------
; The envelope: EnvPeriod (set by the row) + the samples' offsets (IYL, low byte only) + the slide
; (EnvSlideAcc, stepped by EnvSlideStep every EnvSlideReload frames: effect 8) into AyEnvPeriod.
EnvSlideAcc:
    LD    de,$0000
EnvPeriod:
    LD    hl,$0000
    LD    a,iyl
    ADD   a,l
    LD    l,a
    ADD   hl,de
    LD    (AyEnvPeriod),hl
EnvSlideCount:
    LD    a,$00
    DEC   a
    JP    m,PlaySp
    JR    nz,EnvSlideStore
EnvSlideStep:
    LD    hl,$0000
    ADD   hl,de
    LD    (EnvSlideAcc+1),hl
EnvSlideReload:
    LD    a,$00
EnvSlideStore:
    LD    (EnvSlideCount+1),a
PlaySp:
    LD    sp,$0000

;---------------------------------------------------------------------------------------------------------------------
; WriteAy: the AY registers 0-12 from the block AyToneA at a page start (L = the register number;
; B = $FF selects, B = $BF writes): tones, noise (IXH + NoiseBase), mixer (IXL), volumes, envelope
; period; register 13 only when EnvType holds a new type (then cleared).
WriteAy:
    LD    de,$FFBF
    LD    bc,$FFFD
    LD    hl,AyToneA
    OUT   (c),l
    LD    b,e
    OUTI 
    LD    b,d
    OUT   (c),l
    LD    b,e
    OUTI 
    LD    b,d
    OUT   (c),l
    LD    b,e
    OUTI 
    LD    b,d
    OUT   (c),l
    LD    b,e
    OUTI 
    LD    b,d
    OUT   (c),l
    LD    b,e
    OUTI 
    LD    b,d
    OUT   (c),l
    LD    b,e
    OUTI 
    LD    b,d
    OUT   (c),l
    LD    a,ixh
    LD    (NoiseMixer+3),a
NoiseBase:
    ADD   a,$00
    LD    b,e
    OUT   (c),a
    INC   l
    LD    b,d
    OUT   (c),l
    LD    a,ixl
    LD    b,e
    OUT   (c),a
    INC   l
    LD    b,d
    OUT   (c),l
    LD    b,e
    OUTI 
    LD    b,d
    OUT   (c),l
    LD    b,e
    OUTI 
    LD    b,d
    OUT   (c),l
    LD    b,e
    OUTI 
    LD    b,d
    OUT   (c),l
    LD    b,e
    OUTI 
    LD    b,d
    OUT   (c),l
    LD    b,e
    OUTI 
EnvType:
    LD    a,$00
    OR    a
    JR    z,RestoreIy
    LD    b,d
    OUT   (c),l
    LD    b,e
    OUT   (c),a
    XOR   a
    LD    (EnvType+1),a

;---------------------------------------------------------------------------------------------------------------------
; RestoreIy: IY = $5C3A for the ROM's interrupt (Pt3Stop patches this opcode to RET). Then the
; row scheduler: RowFrame counts down from the delay: 2 -> channel A's row, 1 -> B's, 0 -> C's
; (and the staged A and B applied, RowFrame reloaded); above 2 nothing.
RestoreIy:
    LD    iyl,LOW $5C3A                 ; IY back to the ROM's $5C3A (patched to RET by Pt3Stop)
RowFrame:
    LD    a,$03
    DEC   a
    LD    (RowFrame+1),a
    JP    z,ChCRowSkip
    DEC   a
    JP    z,ChBRowSkip
    DEC   a
    RET   nz

;---------------------------------------------------------------------------------------------------------------------
; Channel A's row (two frames before the row). First every staging JR / JP of A is set to skip
; (H, L, E, A: the displacements); unless ChARowSkip ran out, done. Else the skips go to the
; alternate set (EXX / EX AF,AF'), B' = 0: each decoded command clears its block's skip (H' note,
; L' volume, A' ornament / envelope, E' gliss / portamento), C' = the old note (portamento).
; A 0 at the row's start: the next position (PositionPtr, $FF -> LoopPositionPtr), its pattern's
; three channel pointers (+ the module address) into ChAPatternPtr, ChBPatternPtr, ChCPatternPtr,
; the noise base 0.
ChARowSkip:
    LD    a,$01
    DEC   a
    LD    (ChARowSkip+1),a
    LD    hl,(ChAVolumeJr-ChANewNoteJr-2)*256+ChAOrnEnvJr-ChAVolumeJr-2
    LD    e,ChAOnOffJp-ChAGlissJr-2
    LD    b,a
    LD    a,h
    LD    (ChANewNoteJr+1),a
    LD    a,l
    LD    (ChAVolumeJr+1),a
    LD    a,e
    LD    (ChAGlissJr+1),a
    LD    a,ChAGlissJr-ChAOrnEnvJr-2
    LD    (ChAOrnEnvJr+1),a
    RET   nz
    EXX  
    EX    af,af'
ChAPatternPtr:
    LD    de,$0000
    LD    a,(de)
    AND   a
    JR    nz,ChAReadRow
    LD    (PositionSp+1),sp
PositionPtr:
    LD    hl,$0000
    LD    a,(hl)
    ADD   a,a
    JR    nc,PositionStep
LoopPositionPtr:
    LD    hl,$0000
    LD    a,(hl)
    ADD   a,a
PositionStep:
    INC   hl
    LD    (PositionPtr+1),hl
    LD    e,a
    XOR   a
    LD    (NewNoiseBase+1),a
    LD    d,a
PatternTable:
    LD    hl,$0000
    ADD   hl,de
    LD    sp,hl
    POP   hl
ModuleAddr:
    LD    bc,$0000
    ADD   hl,bc
    EX    de,hl
    POP   hl
    ADD   hl,bc
    LD    (ChBPatternPtr+1),hl
    POP   hl
    ADD   hl,bc
    LD    (ChCPatternPtr+1),hl
PositionSp:
    LD    sp,$0000
ChAReadRow:
    CALL  ChADecode
    LD    (ChAPatternPtr+1),de
ChARowSkipLen:
    LD    a,$00
    LD    (ChARowSkip+1),a
    EXX  
    LD    a,h
    LD    (ChANewNoteJr+1),a
    LD    a,l
    LD    (ChAVolumeJr+1),a
    EX    af,af'
    LD    (ChAOrnEnvJr+1),a
    LD    a,e
    LD    (ChAGlissJr+1),a
    RET  

;---------------------------------------------------------------------------------------------------------------------
; ChADecode: DE = channel A's bytes; decodes one row (the ranges in the file header) into the
; staging operands; ends on a note, $D0 or $C0 (RET runs the pushed effect routines, which read
; their parameters from DE). Out: DE = the next row.
ChADecode:
    LD    h,HIGH SamplePtrs
ChADecodeLimits:
    LD    bc,$1020                      ; B = $10, C = $20: the steps of the byte ranges
ChADecodeByte:
    LD    a,(de)
    INC   de
    ADD   a,b
    JP    c,ChAOrnSampleCmd
    ADD   a,c
    JP    c,ChASampleCmd
    ADD   a,b
    JP    c,ChAVolumeCmd
    ADD   a,b
    JP    c,ChAEnvCmd
    ADD   a,$60
    JP    c,ChANoteCmd
    ADD   a,b
    JP    c,ChAOrnamentCmd
    ADD   a,$30
    JP    c,ChAEnvSampleCmd
    ADD   a,b
    ADD   a,a
    ADD   a,LOW (ChAEffects-2)
    LD    l,a
    LD    h,HIGH NoteTable
    LD    a,(hl)
    INC   l
    LD    h,(hl)
    LD    l,a
    PUSH  hl
    LD    a,(ChANote+1)
    EXX  
    LD    c,a
    EXX  
    JP    ChADecodeByte

;---------------------------------------------------------------------------------------------------------------------
; Channel A's effects (ChAEffects), run after the row's note, DE at their parameters:
; ChAEffGliss (1): delay, step word; ChAEffPorta (2): delay, distance word, step word (the note
; stays the old one until the slide has covered the distance, then ChANewPortaNote);
; ChAEffSampleOffset (3), ChAEffOrnOffset (4): the start position; ChAEffOnOff (5): off frames, on
; frames. EffEnvSlide (8): delay, step word; EffDelay (9): the delay (shared by the channels).
ChAEffGliss:
    EX    de,hl
    LD    a,(hl)
    LD    (ChANewGlissDelay+1),a
    INC   hl
    LD    e,(hl)
    INC   hl
    LD    d,(hl)
    INC   hl
    LD    (ChANewGlissStep+1),de
    LD    a,ChAGlissReload-ChAPortaJr-2
    LD    (ChANewPortaJr+1),a
    EX    de,hl
    EXX  
    LD    e,b
    EXX  
    RET  
ChAEffPorta:
    EX    de,hl
    LD    a,(hl)
    LD    (ChANewGlissDelay+1),a
    INC   hl
    LD    e,(hl)
    INC   hl
    LD    d,(hl)
    INC   hl
    LD    (ChANewPortaDistance+1),de
    LD    e,(hl)
    INC   hl
    LD    d,(hl)
    INC   hl
    LD    (ChANewGlissStep+1),de
    XOR   a
    LD    (ChANewPortaJr+1),a
    LD    a,(ChANewNote+1)
    LD    (ChANewPortaNote+1),a
    EXX  
    LD    a,c
    LD    e,b
    EXX  
    LD    (ChANewNote+1),a
    EX    de,hl
    RET  
ChAEffSampleOffset:
    LD    a,(de)
    INC   de
    LD    (ChANewSamplePos+1),a
    LD    a,LOW ChANewSamplePos
    LD    (ChASampleOffJp+1),a
    RET  
ChAEffOrnOffset:
    LD    a,(de)
    INC   de
    LD    (ChANewOrnamentPos+1),a
    LD    a,LOW ChANewOrnamentPos
    LD    (ChAOrnOffJp+1),a
    RET  
ChAEffOnOff:
    LD    a,(de)
    LD    (ChANewOffTime+1),a
    INC   de
    LD    a,(de)
    INC   de
    LD    (ChANewOnTime+1),a
    LD    a,LOW ChAOnOffApply
    LD    (ChAOnOffJp+1),a
    RET  
EffEnvSlide:
    EX    de,hl
    LD    a,(hl)
    LD    (NewEnvSlideDelay+1),a
    INC   hl
    LD    e,(hl)
    INC   hl
    LD    d,(hl)
    INC   hl
    LD    (NewEnvSlideStep+1),de
    EX    de,hl
    XOR   a
    LD    (EnvSlideJr+1),a
    RET  
EffDelay:
    LD    a,(de)
    INC   de
    LD    (Delay+1),a
    RET  

;---------------------------------------------------------------------------------------------------------------------
; Channel A's commands (the jumps of ChADecodeByte; A = the byte less the range's start): the sample
; and ornament numbers index SamplePtrs / OrnamentPtrs by the low byte (H = HIGH SamplePtrs).
ChAOrnSampleCmd:
    ADD   a,a
    ADD   a,LOW OrnamentPtrs
    LD    l,a
    LD    c,(hl)
    INC   l
    LD    b,(hl)
    LD    (ChANewOrnament+1),bc
    LD    a,(de)
    INC   de
    ADD   a,LOW SamplePtrs
    LD    l,a
    LD    c,(hl)
    INC   l
    LD    b,(hl)
    LD    (ChANewSample+1),bc
    XOR   a
    EX    af,af'
    LD    a,EnvOff
    LD    (ChANewEnvMask+1),a
    JP    ChADecodeLimits
ChASampleCmd:
    JR    z,ChARowEnd
    ADD   a,a
    ADD   a,LOW SamplePtrs
    LD    l,a
    LD    c,(hl)
    INC   l
    LD    b,(hl)
    LD    (ChANewSample+1),bc
    JP    ChADecodeLimits
ChARowEnd:
    RET  
ChASoundOff:
    LD    a,OpCpl
    LD    (ChANoteOnOp),a
    EXX  
    LD    h,b
    EXX  
    RET  
ChAEnvOff:
    EX    af,af'
    LD    a,EnvOff
    LD    (ChANewEnvMask+1),a
    JP    ChADecodeByte
ChASkipCmd:
    LD    a,(de)
    INC   de
    LD    (ChARowSkipLen+1),a
    JP    ChADecodeByte
ChAVolumeCmd:
    JR    z,ChASoundOff
    ADD   a,a
    ADD   a,a
    ADD   a,a
    ADD   a,a
    LD    (ChANewVolume+1),a
    EXX  
    LD    l,b
    EXX  
    JP    ChADecodeByte
ChAEnvCmd:
    JR    z,ChAEnvOff
    DEC   a
    JR    z,ChASkipCmd
    LD    (NewEnvType+1),a
    LD    a,(de)
    INC   de
    LD    (NewEnvPeriod+2),a
    LD    a,(de)
    INC   de
    LD    (NewEnvPeriod+1),a
    LD    a,EnvOn
    LD    (ChANewEnvMask+1),a
    XOR   a
    EX    af,af'
    JP    ChADecodeByte
ChANoteCmd:
    LD    (ChANewNote+1),a
    XOR   a
    LD    (ChANoteOnOp),a
    EXX  
    LD    h,b
    EXX  
    RET  
ChAOrnamentCmd:
    ADD   a,a
    ADD   a,LOW OrnamentPtrs
    LD    l,a
    LD    c,(hl)
    INC   l
    LD    b,(hl)
    LD    (ChANewOrnament+1),bc
    XOR   a
    EX    af,af'
    JP    ChADecodeLimits
ChAEnvOffSample:
    LD    a,EnvOff
    LD    (ChANewEnvMask+1),a
    JP    ChAEnvSampleSet
ChAEnvSampleCmd:
    JR    z,ChAEnvOffSample
    LD    (NewEnvType+1),a
    LD    a,(de)
    INC   de
    LD    (NewEnvPeriod+2),a
    LD    a,(de)
    INC   de
    LD    (NewEnvPeriod+1),a
    LD    a,EnvOn
    LD    (ChANewEnvMask+1),a
ChAEnvSampleSet:
    XOR   a
    EX    af,af'
    LD    a,(de)
    INC   de
    ADD   a,LOW SamplePtrs
    LD    l,a
    LD    c,(hl)
    INC   l
    LD    b,(hl)
    LD    (ChANewSample+1),bc
    JP    ChADecodeLimits

;---------------------------------------------------------------------------------------------------------------------
; Channel B's row (one frame before the row): as channel A's (ChARowSkip), without the positions.
ChBRowSkip:
    LD    a,$01
    DEC   a
    LD    (ChBRowSkip+1),a
    LD    hl,(ChBVolumeJr-ChBNewNoteJr-2)*256+ChBOrnEnvJr-ChBVolumeJr-2
    LD    e,ChBOnOffJp-ChBGlissJr-2
    LD    b,a
    LD    a,h
    LD    (ChBNewNoteJr+1),a
    LD    a,l
    LD    (ChBVolumeJr+1),a
    LD    a,e
    LD    (ChBGlissJr+1),a
    LD    a,ChBGlissJr-ChBOrnEnvJr-2
    LD    (ChBOrnEnvJr+1),a
    RET   nz
    EXX  
    EX    af,af'
ChBPatternPtr:
    LD    de,$0000
    CALL  ChBDecode
    LD    (ChBPatternPtr+1),de
ChBRowSkipLen:
    LD    a,$00
    LD    (ChBRowSkip+1),a
    EXX  
    LD    a,h
    LD    (ChBNewNoteJr+1),a
    LD    a,l
    LD    (ChBVolumeJr+1),a
    EX    af,af'
    LD    (ChBOrnEnvJr+1),a
    LD    a,e
    LD    (ChBGlissJr+1),a
    RET  

;---------------------------------------------------------------------------------------------------------------------
; ChBDecode: as ChADecode; channel B also takes $20-$3F, the noise base (ChBNoiseCmd).
ChBDecode:
    LD    h,HIGH SamplePtrs
ChBDecodeLimits:
    LD    bc,$1020
ChBDecodeByte:
    LD    a,(de)
    INC   de
    ADD   a,b
    JP    c,ChBOrnSampleCmd
    ADD   a,c
    JP    c,ChBSampleCmd
    ADD   a,b
    JP    c,ChBVolumeCmd
    ADD   a,b
    JP    c,ChBEnvCmd
    ADD   a,$60
    JP    c,ChBNoteCmd
    ADD   a,b
    JP    c,ChBOrnamentCmd
    ADD   a,c
    JP    c,ChBNoiseCmd
    ADD   a,b
    JP    c,ChBEnvSampleCmd
    ADD   a,b
    ADD   a,a
    ADD   a,LOW (ChBEffects-2)
    LD    l,a
    LD    h,HIGH NoteTable
    LD    a,(hl)
    INC   l
    LD    h,(hl)
    LD    l,a
    PUSH  hl
    LD    a,(ChBNote+1)
    EXX  
    LD    c,a
    EXX  
    JP    ChBDecodeByte

;---------------------------------------------------------------------------------------------------------------------
; Channel B's effects (ChBEffects): as channel A's. ChBEffOnOff's jump is wrong (the file header).
ChBEffGliss:
    EX    de,hl
    LD    a,(hl)
    LD    (ChBNewGlissDelay+1),a
    INC   hl
    LD    e,(hl)
    INC   hl
    LD    d,(hl)
    INC   hl
    LD    (ChBNewGlissStep+1),de
    LD    a,ChBGlissReload-ChBPortaJr-2
    LD    (ChBNewPortaJr+1),a
    EX    de,hl
    EXX  
    LD    e,b
    EXX  
    RET  
ChBEffPorta:
    EX    de,hl
    LD    a,(hl)
    LD    (ChBNewGlissDelay+1),a
    INC   hl
    LD    e,(hl)
    INC   hl
    LD    d,(hl)
    INC   hl
    LD    (ChBNewPortaDistance+1),de
    LD    e,(hl)
    INC   hl
    LD    d,(hl)
    INC   hl
    LD    (ChBNewGlissStep+1),de
    XOR   a
    LD    (ChBNewPortaJr+1),a
    LD    a,(ChBNewNote+1)
    LD    (ChBNewPortaNote+1),a
    EXX  
    LD    a,c
    LD    e,b
    EXX  
    LD    (ChBNewNote+1),a
    EX    de,hl
    RET  
ChBEffSampleOffset:
    LD    a,(de)
    INC   de
    LD    (ChBNewSamplePos+1),a
    LD    a,LOW ChBNewSamplePos
    LD    (ChBSampleOffJp+1),a
    RET  
ChBEffOrnOffset:
    LD    a,(de)
    INC   de
    LD    (ChBNewOrnamentPos+1),a
    LD    a,LOW ChBNewOrnamentPos
    LD    (ChBOrnOffJp+1),a
    RET  
ChBEffOnOff:
    LD    a,(de)
    LD    (ChBNewOffTime+1),a
    INC   de
    LD    a,(de)
    INC   de
    LD    (ChBNewOnTime+1),a
    LD    a,LOW ChBOnOffJp                ; BUG: the JP's own address (LOW ChBNewOnTime meant)
    LD    (ChBOnOffJp+1),a
    RET  

;---------------------------------------------------------------------------------------------------------------------
; Channel B's commands: as channel A's; ChBNoiseCmd: the noise base for the row.
ChBNoiseCmd:
    LD    (NewNoiseBase+1),a
    JP    ChBDecodeByte
ChBOrnSampleCmd:
    ADD   a,a
    ADD   a,LOW OrnamentPtrs
    LD    l,a
    LD    c,(hl)
    INC   l
    LD    b,(hl)
    LD    (ChBNewOrnament+1),bc
    LD    a,(de)
    INC   de
    ADD   a,LOW SamplePtrs
    LD    l,a
    LD    c,(hl)
    INC   l
    LD    b,(hl)
    LD    (ChBNewSample+1),bc
    XOR   a
    EX    af,af'
    LD    a,EnvOff
    LD    (ChBNewEnvMask+1),a
    JP    ChBDecodeLimits
ChBSampleCmd:
    JR    z,ChBRowEnd
    ADD   a,a
    ADD   a,LOW SamplePtrs
    LD    l,a
    LD    c,(hl)
    INC   l
    LD    b,(hl)
    LD    (ChBNewSample+1),bc
    JP    ChBDecodeLimits
ChBRowEnd:
    RET  
ChBSoundOff:
    LD    a,OpCpl
    LD    (ChBNoteOnOp),a
    EXX  
    LD    h,b
    EXX  
    RET  
ChBEnvOff:
    EX    af,af'
    LD    a,EnvOff
    LD    (ChBNewEnvMask+1),a
    JP    ChBDecodeByte
ChBSkipCmd:
    LD    a,(de)
    INC   de
    LD    (ChBRowSkipLen+1),a
    JP    ChBDecodeByte
ChBVolumeCmd:
    JR    z,ChBSoundOff
    ADD   a,a
    ADD   a,a
    ADD   a,a
    ADD   a,a
    LD    (ChBNewVolume+1),a
    EXX  
    LD    l,b
    EXX  
    JP    ChBDecodeByte
ChBEnvCmd:
    JR    z,ChBEnvOff
    DEC   a
    JR    z,ChBSkipCmd
    LD    (NewEnvType+1),a
    LD    a,(de)
    INC   de
    LD    (NewEnvPeriod+2),a
    LD    a,(de)
    INC   de
    LD    (NewEnvPeriod+1),a
    LD    a,EnvOn
    LD    (ChBNewEnvMask+1),a
    XOR   a
    EX    af,af'
    JP    ChBDecodeByte
ChBNoteCmd:
    LD    (ChBNewNote+1),a
    XOR   a
    LD    (ChBNoteOnOp),a
    EXX  
    LD    h,b
    EXX  
    RET  
ChBOrnamentCmd:
    ADD   a,a
    ADD   a,LOW OrnamentPtrs
    LD    l,a
    LD    c,(hl)
    INC   l
    LD    b,(hl)
    LD    (ChBNewOrnament+1),bc
    XOR   a
    EX    af,af'
    JP    ChBDecodeLimits
ChBEnvOffSample:
    LD    a,EnvOff
    LD    (ChBNewEnvMask+1),a
    JP    ChBEnvSampleSet
ChBEnvSampleCmd:
    JR    z,ChBEnvOffSample
    LD    (NewEnvType+1),a
    LD    a,(de)
    INC   de
    LD    (NewEnvPeriod+2),a
    LD    a,(de)
    INC   de
    LD    (NewEnvPeriod+1),a
    LD    a,EnvOn
    LD    (ChBNewEnvMask+1),a
ChBEnvSampleSet:
    XOR   a
    EX    af,af'
    LD    a,(de)
    INC   de
    ADD   a,LOW SamplePtrs
    LD    l,a
    LD    c,(hl)
    INC   l
    LD    b,(hl)
    LD    (ChBNewSample+1),bc
    JP    ChBDecodeLimits

;---------------------------------------------------------------------------------------------------------------------
; Channel C's row (on the row's frame): decoded straight into the tick's operands (ChCDecode),
; then the staged rows of A and B applied (from ChANewNoteJr), the envelope, the delay.
ChCRowSkip:
    LD    a,$01
    DEC   a
    LD    (ChCRowSkip+1),a
    JP    nz,ChANewNoteJr
ChCPatternPtr:
    LD    de,$0000
    CALL  ChCDecode
    LD    (ChCPatternPtr+1),de
ChCRowSkipLen:
    LD    a,$00
    LD    (ChCRowSkip+1),a

;---------------------------------------------------------------------------------------------------------------------
; The staged row of channel A, applied after channel C's decode. Each block is skipped by its JR
; unless the decoder cleared the displacement:
;   ChANewNoteJr: a note or sound off: the tick's state cleared (slides, positions, accumulators),
;     ChANoteOnOp (NOP: the note sounds, CPL: muted), ChANewNote, ChANewSample;
;   ChAVolumeJr: the channel volume (ChANewVolume = volume * 16, a row of VolumeTable);
;   ChAOrnEnvJr: ornament or envelope: the ornament from its start, the envelope slide cleared,
;     ChANewOrnament, ChANewEnvMask;
;   ChAGlissJr: gliss / portamento (delay, distance, step, the JR of the tick's test);
;   ChAOnOffJp: the on-off effect (JP to ChAOnOffApply, which sets the JP back to skip).
ChANewNoteJr:
    JR    ChAVolumeJr
    XOR   a
    LD    (ChAEnvOffsetAcc+1),a
    LD    (ChAGlissCount+1),a
    LD    (ChASamplePos+1),a
    LD    (ChAOrnamentPos+1),a
    LD    (ChANoiseAcc+1),a
    LD    (ChAVolSlide+1),a
    LD    (ChAOnOffCount+1),a
    LD    h,a
    LD    l,a
    LD    (ChAToneSlide+1),hl
    LD    (ChAToneAcc+1),hl
ChANoteOnOp:
    CPL  
    LD    (ChAMute+1),a
ChANewNote:
    LD    a,$00
    LD    (ChANote+1),a
ChANewSample:
    LD    hl,$0000
    LD    (ChASamplePtr+1),hl
ChAVolumeJr:
    JR    ChAOrnEnvJr
ChANewVolume:
    LD    a,$00
    LD    (ChAVolume+1),a
ChAOrnEnvJr:
    JR    ChAGlissJr
    XOR   a
    LD    (ChAOrnamentPos+1),a
    LD    l,a
    LD    h,a
    LD    (EnvSlideAcc+1),hl
    LD    (EnvSlideCount+1),a
ChANewOrnament:
    LD    hl,$0000
    LD    (ChAOrnamentPtr+1),hl
ChANewEnvMask:
    LD    a,$00
    LD    (ChAEnvMask+1),a
ChAGlissJr:
    JR    ChAOnOffJp
ChANewPortaNote:
    LD    a,$00
    LD    (ChAPortaNote+1),a
ChANewGlissDelay:
    LD    a,$00
    LD    (ChAGlissCount+1),a
    LD    (ChAGlissReload+1),a
ChANewPortaDistance:
    LD    hl,$0000
    LD    (ChAPortaDistance+1),hl
ChANewGlissStep:
    LD    hl,$0000
    LD    (ChAGlissStep+1),hl
ChANewPortaJr:
    LD    a,$00
    LD    (ChAPortaJr+1),a
    XOR   a
    LD    (ChAOnOffCount+1),a
ChAOnOffJp:
    JP    ChBNewNoteJr
ChAOnOffApply:
    XOR   a
    LD    (ChAGlissCount+1),a
    LD    l,a
    LD    h,a
    LD    (ChAToneSlide+1),hl
    LD    a,LOW ChBNewNoteJr              ; this block runs once: skip it again
    LD    (ChAOnOffJp+1),a
ChANewOnTime:
    LD    a,$00
    LD    (ChAOnTime+1),a
    LD    (ChAOnOffCount+1),a
ChANewOffTime:
    LD    a,$00
    LD    (ChAOffTime+1),a

;---------------------------------------------------------------------------------------------------------------------
; The staged row of channel B: as channel A's.
ChBNewNoteJr:
    JR    ChBVolumeJr
    XOR   a
    LD    (ChBEnvOffsetAcc+1),a
    LD    (ChBGlissCount+1),a
    LD    (ChBSamplePos+1),a
    LD    (ChBOrnamentPos+1),a
    LD    (ChBNoiseAcc+1),a
    LD    (ChBVolSlide+1),a
    LD    (ChBOnOffCount+1),a
    LD    h,a
    LD    l,a
    LD    (ChBToneSlide+1),hl
    LD    (ChBToneAcc+1),hl
ChBNoteOnOp:
    CPL  
    LD    (ChBMute+1),a
ChBNewNote:
    LD    a,$00
    LD    (ChBNote+1),a
ChBNewSample:
    LD    hl,$0000
    LD    (ChBSamplePtr+1),hl
ChBVolumeJr:
    JR    ChBOrnEnvJr
ChBNewVolume:
    LD    a,$00
    LD    (ChBVolume+1),a
ChBOrnEnvJr:
    JR    ChBGlissJr
    XOR   a
    LD    (ChBOrnamentPos+1),a
    LD    l,a
    LD    h,a
    LD    (EnvSlideAcc+1),hl
    LD    (EnvSlideCount+1),a
ChBNewOrnament:
    LD    hl,$0000
    LD    (ChBOrnamentPtr+1),hl
ChBNewEnvMask:
    LD    a,$00
    LD    (ChBEnvMask+1),a
ChBGlissJr:
    JR    ChBOnOffJp
ChBNewPortaNote:
    LD    a,$00
    LD    (ChBPortaNote+1),a
ChBNewGlissDelay:
    LD    a,$00
    LD    (ChBGlissCount+1),a
    LD    (ChBGlissReload+1),a
ChBNewPortaDistance:
    LD    hl,$0000
    LD    (ChBPortaDistance+1),hl
ChBNewGlissStep:
    LD    hl,$0000
    LD    (ChBGlissStep+1),hl
ChBNewPortaJr:
    LD    a,$00
    LD    (ChBPortaJr+1),a
    XOR   a
    LD    (ChBOnOffCount+1),a
ChBOnOffJp:
    JP    EnvSlideJr
ChBNewOnTime:
    LD    a,$00
    LD    (ChBOnTime+1),a
    LD    (ChBOnOffCount+1),a
ChBNewOffTime:
    LD    a,$00
    LD    (ChBOffTime+1),a
    XOR   a
    LD    (ChBGlissCount+1),a
    LD    l,a
    LD    h,a
    LD    (ChBToneSlide+1),hl
    LD    a,LOW EnvSlideJr                ; this block runs once: skip it again
    LD    (ChBOnOffJp+1),a

;---------------------------------------------------------------------------------------------------------------------
; Once-only blocks, entered when a row set them (their JR / JP retargeted, the block retargets it
; back): the envelope slide (EnvSlideJr), the sample and ornament offsets of A and B
; (ChASampleOffJp ...). Then the row's envelope (NewEnvType: 0 = none, NewEnvPeriod), RowFrame
; reloaded with Delay, the noise base, RowCounter + 1 (the rows played, from 0).
EnvSlideJr:
    JR    ChASampleOffJp
NewEnvSlideStep:
    LD    hl,$0000
    LD    (EnvSlideStep+1),hl
NewEnvSlideDelay:
    LD    a,$00
    LD    (EnvSlideCount+1),a
    LD    (EnvSlideReload+1),a
    LD    a,ChASampleOffJp-EnvSlideJr-2   ; this block runs once: skip it again
    LD    (EnvSlideJr+1),a
ChASampleOffJp:
    JP    ChAOrnOffJp
ChANewSamplePos:
    LD    a,$00
    LD    (ChASamplePos+1),a
    LD    a,LOW ChAOrnOffJp
    LD    (ChASampleOffJp+1),a
ChAOrnOffJp:
    JP    ChBSampleOffJp
ChANewOrnamentPos:
    LD    a,$00
    LD    (ChAOrnamentPos+1),a
    LD    a,LOW ChBSampleOffJp
    LD    (ChAOrnOffJp+1),a
ChBSampleOffJp:
    JP    ChBOrnOffJp
ChBNewSamplePos:
    LD    a,$00
    LD    (ChBSamplePos+1),a
    LD    a,LOW ChBOrnOffJp
    LD    (ChBSampleOffJp+1),a
ChBOrnOffJp:
    JP    NewEnvType
ChBNewOrnamentPos:
    LD    a,$00
    LD    (ChBOrnamentPos+1),a
    LD    a,LOW NewEnvType
    LD    (ChBOrnOffJp+1),a
NewEnvType:
    LD    a,$00
    LD    (EnvType+1),a
    AND   a
    JR    z,Delay
NewEnvPeriod:
    LD    hl,$0000
    LD    (EnvPeriod+1),hl
    XOR   a
    LD    (NewEnvType+1),a
Delay:
    LD    a,$03
    LD    (RowFrame+1),a
NewNoiseBase:
    LD    a,$00
    LD    (NoiseBase+1),a
RowCounter:
    LD    hl,$FFFF
    INC   hl
    LD    (RowCounter+1),hl
    RET  

;---------------------------------------------------------------------------------------------------------------------
; ChCDecode: as ChADecode, but into channel C's tick at once (no staging).
ChCDecode:
    LD    h,HIGH SamplePtrs
ChCDecodeLimits:
    LD    bc,$1020
ChCDecodeByte:
    LD    a,(de)
    INC   de
    ADD   a,b
    JP    c,ChCOrnSampleCmd
    ADD   a,c
    JP    c,ChCSampleCmd
    ADD   a,b
    JP    c,ChCVolumeCmd
    ADD   a,b
    JP    c,ChCEnvCmd
    ADD   a,$60
    JP    c,ChCNoteCmd
    ADD   a,b
    JP    c,ChCOrnamentCmd
    ADD   a,$30
    JP    c,ChCEnvSampleCmd
    ADD   a,b
    ADD   a,a
    ADD   a,LOW (ChCEffects-2)
    LD    l,a
    LD    h,HIGH NoteTable
    LD    a,(hl)
    INC   l
    LD    h,(hl)
    LD    l,a
    PUSH  hl
    LD    a,(ChCNote+1)
    EXX  
    LD    c,a
    EXX  
    JP    ChCDecodeByte

;---------------------------------------------------------------------------------------------------------------------
; Channel C's effects (ChCEffects): as channel A's, applied at once.
ChCEffGliss:
    EX    de,hl
    LD    a,(hl)
    LD    (ChCGlissCount+1),a
    LD    (ChCGlissReload+1),a
    INC   hl
    LD    e,(hl)
    INC   hl
    LD    d,(hl)
    INC   hl
    LD    (ChCGlissStep+1),de
    LD    a,ChCGlissReload-ChCPortaJr-2
    LD    (ChCPortaJr+1),a
    XOR   a
    LD    (ChCOnOffCount+1),a
    EX    de,hl
    RET  
ChCEffPorta:
    EX    de,hl
    LD    a,(hl)
    LD    (ChCGlissCount+1),a
    LD    (ChCGlissReload+1),a
    INC   hl
    LD    e,(hl)
    INC   hl
    LD    d,(hl)
    INC   hl
    LD    (ChCPortaDistance+1),de
    LD    e,(hl)
    INC   hl
    LD    d,(hl)
    INC   hl
    LD    (ChCGlissStep+1),de
    XOR   a
    LD    (ChCOnOffCount+1),a
    LD    (ChCPortaJr+1),a
    LD    a,(ChCNote+1)
    LD    (ChCPortaNote+1),a
    EXX  
    LD    a,c
    EXX  
    LD    (ChCNote+1),a
    EX    de,hl
    RET  
ChCEffSampleOffset:
    LD    a,(de)
    INC   de
    LD    (ChCSamplePos+1),a
    RET  
ChCEffOrnOffset:
    LD    a,(de)
    INC   de
    LD    (ChCOrnamentPos+1),a
    RET  
ChCEffOnOff:
    LD    a,(de)
    LD    (ChCOffTime+1),a
    INC   de
    LD    a,(de)
    INC   de
    LD    (ChCOnTime+1),a
    LD    (ChCOnOffCount+1),a
    XOR   a
    LD    (ChCGlissCount+1),a
    LD    l,a
    LD    h,a
    LD    (ChCToneSlide+1),hl
    RET  

;---------------------------------------------------------------------------------------------------------------------
; Channel C's commands: as channel A's, applied at once (ChCNoteCmd clears the tick's state).
ChCOrnSampleCmd:
    ADD   a,a
    ADD   a,LOW OrnamentPtrs
    LD    l,a
    LD    c,(hl)
    INC   l
    LD    b,(hl)
    LD    (ChCOrnamentPtr+1),bc
    LD    a,(de)
    INC   de
    ADD   a,LOW SamplePtrs
    LD    l,a
    LD    c,(hl)
    INC   l
    LD    b,(hl)
    LD    (ChCSamplePtr+1),bc
    XOR   a
    LD    (ChCOrnamentPos+1),a
    LD    a,EnvOff
    LD    (ChCEnvMask+1),a
    JP    ChCDecodeLimits
ChCSampleCmd:
    JR    z,ChCRowEnd
    ADD   a,a
    ADD   a,LOW SamplePtrs
    LD    l,a
    LD    c,(hl)
    INC   l
    LD    b,(hl)
    LD    (ChCSamplePtr+1),bc
    JP    ChCDecodeLimits
ChCRowEnd:
    RET  
ChCSoundOff:
    LD    a,$FF
    LD    (ChCMute+1),a
    LD    (ChCOnOffCount+1),a
    RET  
ChCEnvOff:
    LD    a,EnvOff
    LD    (ChCEnvMask+1),a
    JP    ChCDecodeByte
ChCSkipCmd:
    LD    a,(de)
    INC   de
    LD    (ChCRowSkipLen+1),a
    JP    ChCDecodeByte
ChCVolumeCmd:
    JR    z,ChCSoundOff
    ADD   a,a
    ADD   a,a
    ADD   a,a
    ADD   a,a
    LD    (ChCVolume+1),a
    JP    ChCDecodeByte
ChCEnvCmd:
    JR    z,ChCEnvOff
    DEC   a
    JR    z,ChCSkipCmd
    LD    (NewEnvType+1),a
    LD    a,(de)
    INC   de
    LD    (NewEnvPeriod+2),a
    LD    a,(de)
    INC   de
    LD    (NewEnvPeriod+1),a
    LD    a,EnvOn
    LD    (ChCEnvMask+1),a
    JP    ChCDecodeByte
ChCNoteCmd:
    LD    (ChCNote+1),a
    XOR   a
    LD    (ChCEnvOffsetAcc+1),a
    LD    (ChCOrnamentPos+1),a
    LD    (ChCMute+1),a
    LD    (ChCSamplePos+1),a
    LD    (ChCGlissCount+1),a
    LD    (ChCOnOffCount+1),a
    LD    (ChCVolSlide+1),a
    LD    (ChCNoiseAcc+1),a
    LD    h,a
    LD    l,a
    LD    (ChCToneSlide+1),hl
    LD    (ChCToneAcc+1),hl
    RET  
ChCOrnamentCmd:
    ADD   a,a
    ADD   a,LOW OrnamentPtrs
    LD    l,a
    LD    c,(hl)
    INC   l
    LD    b,(hl)
    LD    (ChCOrnamentPtr+1),bc
    XOR   a
    LD    (ChCOrnamentPos+1),a
    JP    ChCDecodeLimits
ChCEnvOffSample:
    LD    a,EnvOff
    LD    (ChCEnvMask+1),a
    JP    ChCEnvSampleSet
ChCEnvSampleCmd:
    JR    z,ChCEnvOffSample
    LD    (NewEnvType+1),a
    LD    a,(de)
    INC   de
    LD    (NewEnvPeriod+2),a
    LD    a,(de)
    INC   de
    LD    (NewEnvPeriod+1),a
    LD    a,EnvOn
    LD    (ChCEnvMask+1),a
ChCEnvSampleSet:
    LD    a,(de)
    INC   de
    ADD   a,$A0
    LD    l,a
    LD    c,(hl)
    INC   l
    LD    b,(hl)
    LD    (ChCSamplePtr+1),bc
    JP    ChCDecodeLimits

@Pt3Module:                             ; the module follows the player (Pt3Init + $E21)


    ENDMODULE
