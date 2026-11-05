; Advanced Nether Earth (Eternity Industry, 1998): the loader, $6161-$8D60 (docs/03-build-and-load.md 3).
;
; UltraXOR's sector reader (src/boot/a-nether.asm, ReadSectors) reads these 44 sectors of A_NETHER.B (file sectors
; 11-54) to $6161, then bank 7's $DB00 and bank 4's $C000 parts, and calls LoaderMain ($6221). The loader runs the
; intro and the two programs after it (each a HRUM 3.5 block called at $6600: Presents, the scroller) and plays their
; music from an IM 2 handler: LoaderInterrupt sits at $6161 so that a vector table of $61 bytes reaches it whatever
; the data bus holds (the intro builds that table).
;
; The bytes: the code $6161-$62C7, zero to $65FF, the intro's HRUM block at $6600-$8CE3, and 125 bytes to $8D60
; that nothing reads (left in the sector buffer by the authors' tool, kept as they are on the disk).

    DEVICE ZXSPECTRUM48

BANKM       EQU $5B5C           ; the 128 ROM's copy of the last $7FFD write
PlayerInit  EQU $C000           ; bank 6: the intro's copy of New SoundTrack Player (Phantom Family) with "MAD NIGHT"
                                ; (copied there from the intro's image at $7D2D): init, also silences the AY
PlayerFrame EQU $C005           ; ... and one frame of play
IntroRun    EQU $6600           ; every block of the boot is called here

    ORG $6161

; The music of the boot, one call a frame (IM 2). Saves everything, pages bank 6 (the player) with the screen bank
; as BANKM has it, plays a frame, and SPACE ends the boot program at once (LoaderEnd).
LoaderInterrupt:
    DI
    LD (.sp + 1),SP
    LD SP,$6200                 ; its own stack under WaitFrames (the zero bytes $61B0-$61FF)
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    EXX
    EX AF,AF'
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    PUSH IX
    PUSH IY
    LD A,$16                    ; bank 6, the 48 ROM
    LD HL,BANKM
    BIT 3,(HL)                  ; the shown screen as the program has it
    JR Z,.page
    SET 3,A
.page:
    LD BC,$7FFD
    OUT (C),A
    CALL PlayerFrame
    NOP
    NOP
    NOP
    LD A,$7F                    ; half-row SPACE..B
    IN A,($FE)
    RRA
    JP NC,LoaderEnd             ; SPACE: skip to the end of the boot
    LD A,(BANKM)                ; the program's paging back
    LD BC,$7FFD
    OUT (C),A
    POP IY
    POP IX
    POP HL
    POP DE
    POP BC
    POP AF
    EX AF,AF'
    EXX
    POP HL
    POP DE
    POP BC
    POP AF
.sp:
    LD SP,0                     ; the interrupted SP, written above
    EI
    RET

    DS $6200 - $, 0             ; LoaderInterrupt's stack

; Wait BC frames
WaitFrames:
    HALT
    DEC BC
    LD A,B
    OR C
    JR NZ,WaitFrames
    RET

; Page A at $C000 ($7FFD), BANKM kept up to date
SetPage:
    LD BC,$7FFD
    LD (BANKM),A
    OUT (C),A
    RET

; The 768 attributes at HL white on white ($3F), the border white: the flash between the boot's pictures
WhiteScreen:
    HALT
    LD A,7
    OUT ($FE),A
    LD D,H
    LD E,L
    INC E
    LD (HL),$3F
    LD BC,$02FF
    LDIR
    HALT
    RET

; The boot: the intro, the logo program, the boot menu (docs/03-build-and-load.md 3)
LoaderMain:
    DI
    LD (LoaderEnd + 2),SP       ; UltraXOR's SP: LoaderEnd returns to its caller
    CALL IntroRun               ; the intro (Intro: the block at $6600 below) unpacks and runs
    LD BC,309
    CALL WaitFrames             ; the intro's picture with its tune, about 6 seconds
    LD HL,$5800
    CALL WhiteScreen
    LD A,$17                    ; bank 7: its $DB00 holds the next block
    CALL SetPage
    LD HL,$DB00
    LD DE,IntroRun
    LD BC,$1005                 ; Block02's length (src/sfx/blocks.asm)
    LDIR
    LD A,$10
    CALL SetPage
    HALT
    XOR A                       ; black border and attributes: nothing shows while it unpacks
    OUT ($FE),A
    LD HL,$5800
    LD DE,$5801
    LD (HL),A
    LD BC,$02FF
    LDIR
    CALL IntroRun               ; Block02
    LD A,$17
    CALL SetPage
    LD HL,$D800                 ; bank 7's (the second screen's) attributes white
    LD DE,$D801
    LD (HL),$3F
    LD BC,$02FF
    LDIR
    LD B,20                     ; 20 flashes: screen 5 with a black border, screen 7 (white) with a white one
.flash:
    PUSH BC
    HALT
    XOR A
    OUT ($FE),A
    LD A,$10
    CALL SetPage
    HALT
    LD A,7
    OUT ($FE),A
    LD A,$18                    ; bank 0 at $C000, screen 7 shown
    CALL SetPage
    POP BC
    DJNZ .flash
    LD HL,$5800
    CALL WhiteScreen
    LD A,$14                    ; bank 4: the scroller's block
    CALL SetPage
    LD HL,$C000
    LD DE,IntroRun
    LD BC,$1B15                 ; more than Block03 (3679 bytes): the rest is not read
    LDIR
    LD A,$10
    CALL SetPage
    CALL IntroRun               ; Block03: the credits scroller (back here only through SPACE: LoaderEnd)

; The end of the boot, also SPACE in LoaderInterrupt: IM 1, the player silenced, the BASIC's registers back, a
; return to UltraXOR's caller
LoaderEnd:
    DI
    LD SP,0                     ; written by LoaderMain
    LD A,$3F
    LD I,A
    IM 1
    LD A,$16
    CALL SetPage
    CALL PlayerInit                ; silence
    LD A,$10
    CALL SetPage
    LD IY,$5C3A
    EXX
    LD HL,$2758
    EXX
    EI
    RET

    DS $6600 - $, 0

    INCBIN "build/blk/intro.bin"
    INCBIN "src/res/disk/filler-loader-8ce4.bin"
LoaderTop:
    ASSERT LoaderTop == $8D61
    SAVEBIN "build/loader.bin", $6161, LoaderTop - $6161
