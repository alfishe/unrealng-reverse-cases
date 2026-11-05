; A_NETHER.B, the boot BASIC of the SCL (sectors 0-10, 2816 bytes), in its plain form: UltraXOR v1.2 (Paracels)
; with every layer decrypted. tools/ultraxor.py encrypts it into the file on the disk (the build: tools/build.sh;
; how the layers and their keys work: tools/ultraxor.py, docs/03-build-and-load.md 4.2).
;
; TR-DOS loads the file to PROG = $5D3B and runs line 1, CLOSE # USR Eternity (the variable Eternity = 23959 =
; $5D97). The code at $5D97 clears the screen, copies $5DE0-$8815 to $7705 and jumps there. At $7705 the
; envelope: its sign, then 78 decrypting loops, each decrypting the next (all but the first are encrypted in the
; file), the last one the code at $7FE9-$813A: it copies the TR-DOS sector reader to $5D3F (over line 0) and runs
; it. The reader loads the whole game: the loader ($6161), the intro, the title picture (it calls $9C40 itself),
; the boot program ($6060) and the banks, then jumps to $6060.

    OUTPUT "build/boot/a-nether-plain.bin"

    ORG $5D3B
Prog:
; ---------------------------------------------------------------------------------------------------------------
; Line 0: no keyword, only code (LIST shows garbage); its length word covers the whole envelope
; ---------------------------------------------------------------------------------------------------------------
    DB $00,$00                  ; line number 0 (big-endian)
    DW Line0End - Line0         ; its length, $0AD8
Line0:
; $5D3F, where RANDOMIZE USR 23871 (the usual start of code in a line 0) would enter: a trap. It clears $4000-$5BFF
; (BC = $1C00) and jumps to $0000, a reset. The boot never runs it; later the reader is copied over it
TrapEntry:
    DI
    LD HL,$4000
    LD DE,$4001
    LD IX,$1B00
    LD (HL),L                   ; 0
    LD C,IXL                    ; C = 0
    INC IXH                     ; IX = $1C00
    PUSH IX
    LD B,IXH                    ; BC = $1C00
    LDIR
    POP IX
    LD H,C
    LD L,B                      ; HL = $0000 (B, C are 0 after the LDIR)
    JP (HL)                     ; reset
; $5D5A: another trap, a jump into TR-DOS through its RET at $3D2F to the address in IX; then a text, a
; RANDOMIZE USR 15619 stub (CALL $3D13: RET) and the authors' message to crackers. Never run
    PUSH IX
    JP $3D2F
    DB "TRUL-LYA-LYA..."
    CALL $3D13
    RET
    DB "LAMERZ MUST DIE !!!"

; $5D85, called by the entry: the border black and the screen cleared, from $5AFF down until a byte reads back
; non-zero (the first ROM byte, $3FFF)
ClearScreen:
    XOR A
    OUT ($FE),A
    LD HL,$5B00
.loop:
    DEC HL
    LD (HL),A
    OR (HL)
    JR Z,.loop
    RET
; 6 bytes no path runs: they make a disassembly from $5D91 start out of step with the entry
    DB $ED,$01,$ED,$6E,$FD,$CB

; $5D97: the entry (line 1's USR Eternity). The jumps over bytes and the ED NOPs are there to confuse a reader
Entry:
    DI
    LD SP,CopyTo
    CALL ClearScreen
    LD L,$5D                    ; L = $5D
    DB $ED,$07                  ; ED NOP (undocumented)
    NOP
    LD D,$0A
    LD H,$E0                    ; H = $E0
    NOP
    SCF
    DB $ED,$03                  ; ED NOP (undocumented)
    JR C,.go                    ; always (carry set)
.dest:
    DW CopyTo                   ; $5DAD: read as a word below ($7705); as code DEC B; LD (HL),A, never run
.go:
    LD A,L
    LD L,H
    LD E,$36                    ; DE = $0A36, the length
    LD H,A                      ; HL = $5DE0, the source
    LD BC,(.dest)               ; BC = $7705
    PUSH HL
    LD H,B
    LD L,C
    EX DE,HL                    ; DE = $7705, HL = $0A36
    LD B,H
    LD C,L                      ; BC = $0A36
    NOP
    POP HL                      ; HL = $5DE0
    PUSH DE
    LDIR                        ; $5DE0-$8815 -> $7705-$813A
    POP IX
    JP (IX)                     ; $7705
    DB "(C)1998 ETERNITY INDUSTRY"

; ---------------------------------------------------------------------------------------------------------------
; $5DE0 in the file, run at $7705: the envelope (copied by the entry)
; ---------------------------------------------------------------------------------------------------------------
CopyFrom:
    DISP $7705
CopyTo:
    JR Layer0
    DB "UltraXOR v1.2 (c) PARACELS"
; The first loop, plain in the file: from here on the interrupts are off and R starts at $2A, so every R value
; read below is fixed by the code alone (tools/ultraxor.py). The registers it sets (C, D, E, IX, IY) are the
; working values the loops after it keep changing
Layer0:
    DI
    LD A,$2A
    LD R,A
    LD DE,$E82E
    LD C,$A3
    LD IX,$5FBB
    LD IY,$D64D
    LD HL,Layer0Disp            ; the first byte decrypted: this loop's own DJNZ displacement
    LD B,$0F                    ; 15 bytes, $7757-$7765
.loop:
    LD A,R                      ; the key: R ...
    RRCA
    DEC D
    XOR IYL
    DB $ED,$07                  ; ED NOP (undocumented): R + 2
    XOR B
    SUB B
    RLCA
    DEC E
    XOR $50
    XOR IXL
    NEG
    DEC C
    DB $ED,$0D                  ; ED NOP
    CPL
    DB $ED,$07                  ; ED NOP
    XOR B                       ; ... and the working registers
    LD SP,IX                    ; against a debugger: a breakpoint or an interrupt would push onto the code
    XOR (HL)
    LD (HL),A                   ; the byte decrypted
    INC HL
    DB $10                      ; DJNZ .loop: its displacement is the first byte the loop decrypts
Layer0Disp:
    DB Layer0.loop - $ - 1

    INCLUDE "src/boot/ultraxor-layers.asm"

; Layer 77, $7FCA, the last: $7FE9-$813A (338 bytes), from its own JR NZ displacement to the end of the
; envelope; the key also takes H and L, the address
Layer77:
    LD HL,Layer77Disp
    LD BC,$0152
.loop:
    DB $ED,$4E                  ; IM 0/1 (undocumented): R + 2
    LD A,R
    XOR B
    RRCA
    NOP
    DB $ED,$07                  ; ED NOP
    XOR H
    SUB L
    CPL
    XOR (HL)
    XOR C
    XOR L
    DB $ED,$03                  ; ED NOP
    LD (HL),A
    DB $ED,$6E                  ; IM 0 (undocumented)
    DEC BC
    LD A,B
    INC HL
    OR C
    DB $20                      ; JR NZ,.loop; the displacement is decrypted twice: the end of layer 76's range too
Layer77Disp:
    DB Layer77.loop - $ - 1

; $7FEA, decrypted: the system state TR-DOS and the ROM expect, then the reader
    LD SP,$8000
    LD A,$3F
    LD I,A
    IM 1
    LD IY,$5C3A                 ; the ROM's IY (the system variables)
    EXX
    LD HL,$2758                 ; the ROM's HL' (the calculator's return)
    EXX
    DI
    JP MoveReader
    ASSERT $ == $8000
MoveReader:
    LD HL,ReaderCode
    LD DE,Reader
    LD BC,ReaderEnd - Reader    ; 301 bytes
    LDIR                        ; over line 0
    JP Reader
ReaderCode:
    ENT

; ---------------------------------------------------------------------------------------------------------------
; $800E, run at $5D3F: the sector reader, through TR-DOS ROM gadgets (each an OUT and a RET, entered by pushing
; the address and jumping to TR-DOS's RET at $3D2F, which pages the ROM in on the way)
; ---------------------------------------------------------------------------------------------------------------
    DISP $5D3F
Reader:
    DI
    LD SP,$6000
    XOR A
    OUT ($FE),A
    LD HL,$5B00                 ; the screen cleared again, as ClearScreen
.cls:
    DEC HL
    LD (HL),A
    OR (HL)
    JR Z,.cls
    LD A,$10                    ; bank 0, the 48 K ROM
    CALL SetPage
    LD HL,$6161                 ; the loader and the intro's block: 44 sectors (11-54)
    LD B,$2C
    CALL ReadSectors
    LD A,$17                    ; bank 7 $DB00: "Presents", 17 sectors (55-71)
    CALL SetPage
    LD HL,$DB00
    LD B,$11
    CALL ReadSectors
    LD A,$14                    ; bank 4 $C000: the scroller, 15 sectors (72-86)
    CALL SetPage
    LD HL,$C000
    LD B,$0F
    CALL ReadSectors
    CALL ResetFdc
    LD A,$10
    CALL SetPage
    CALL $6221                  ; the loader: the intro, "Presents", the scroller; back on SPACE (LoaderEnd)
    EI
    HALT
    LD A,$07                    ; border white, the attributes white on white
    OUT ($FE),A
    LD HL,$5800
    LD DE,$5801
    LD (HL),$3F
    LD BC,$02FF
    LDIR
    HALT
    DI
    LD HL,$9C40                 ; the title picture with its own depacker: 13 sectors (87-99), run here
    LD B,$0D
    CALL ReadSectors
    CALL $9C40
    LD HL,$6060                 ; the boot program's block: 112 sectors (100-211)
    LD B,$70
    CALL ReadSectors
    LD A,$13                    ; bank 3: Dead End, the game block's end, the game music: 59 sectors (212-270)
    CALL SetPage
    LD HL,$C000
    LD B,$3B
    CALL ReadSectors
    LD A,$11                    ; bank 1: the boot music's block, 13 sectors (271-283), unpacked at once
    CALL SetPage
    LD HL,$C000
    LD B,$0D
    CALL ReadSectors
    CALL $C000
    LD A,$14                    ; bank 4: the game block's first 16384 bytes, 64 sectors (284-347)
    CALL SetPage
    LD HL,$C000
    LD B,$40
    CALL ReadSectors
    LD A,$16                    ; bank 6: Final Cut and the disk module, 63 sectors (348-410)
    CALL SetPage
    LD HL,$C000
    LD B,$3F
    CALL ReadSectors
    LD A,$17                    ; bank 7: the boot's bank 7 image, 26 sectors (411-436)
    CALL SetPage
    LD HL,$C000
    LD B,$1A
    CALL ReadSectors
    CALL ResetFdc
    LD A,$10
    CALL SetPage
    JP $6060                    ; the boot program's block: it unpacks and runs the boot menu

; B sectors to HL, from the disk's next logical sector (TR-DOS's $5CF4: E the sector 0-15, D the logical track,
; side = bit 0); the next one is left in $5CF4
ReadSectors:
    LD DE,($5CF4)
.sector:
    PUSH BC
    PUSH DE
    LD A,D
    SRL A                       ; the cylinder; carry = the side
    LD (ResetFdc.track + 1),A   ; kept for ResetFdc
    LD C,A
    LD A,$3C                    ; system register: side 0, MFM, no reset
    JR NC,.side
    LD A,$2C                    ; side 1
.side:
    CALL OutSystem
    LD A,C
    LD C,$7F
    LD IX,$2A53                 ; TR-DOS: OUT (C),A; RET: the data register = the cylinder
    CALL RomCall
    LD A,$18                    ; SEEK (head loaded, 6 ms steps)
    LD IX,$2FC3                 ; TR-DOS: OUT ($1F),A; RET
    CALL RomCall
    LD IX,$2F1B                 ; TR-DOS: the sector register = E + 1, READ SECTOR, the INI loop to HL ($3FE5)
    CALL RomCall
    POP DE
    POP BC
    INC H                       ; the next 256 bytes
    INC E
    LD A,E
    CP $10
    CCF                         ; carry: E reached 16
    ADC A,D
    SUB E
    LD D,A                      ; D + 1 after sector 15
    RES 4,E                     ; E mod 16
    DJNZ .sector
    LD ($5CF4),DE
    RET

; A to the Beta interface's system register ($FF)
OutSystem:
    LD IX,$1FF3                 ; TR-DOS: OUT ($FF),A; RET
; IX in the TR-DOS ROM, as a call: its RET at $3D2F pages the ROM in and returns to IX, and IX's RET back here
RomCall:
    PUSH IX
    JP $3D2F

; The controller reset (system register 0, then $3C), a FORCE INTERRUPT, two frames, and the track register set
; to the cylinder the head is on (the operand below, written by ReadSectors)
ResetFdc:
    XOR A
    CALL OutSystem
    LD A,$3C
    CALL OutSystem
    LD A,$D0                    ; FORCE INTERRUPT
    LD IX,$2FC3
    CALL RomCall
    EI
    HALT
    HALT
    DI
.track:
    LD A,$00
    LD C,$3F
    LD IX,$2A53                 ; the track register
    CALL RomCall
    RET

; A to $7FFD
SetPage:
    LD BC,$7FFD
    OUT (C),A
    RET
ReaderEnd:
    ENT
    ASSERT $ - CopyFrom == $0A36
    DB $0D                      ; the end of line 0
Line0End:

; ---------------------------------------------------------------------------------------------------------------
; Line 1: CLOSE # USR Eternity. Its length word says 15; the line is 11 bytes
; ---------------------------------------------------------------------------------------------------------------
    DB $00,$01                  ; line 1
    DW $000F
    DB $D4,$C0,"Eternity",$0D   ; CLOSE #, USR, the variable's name, ENTER
Vars:
; The variable Eternity (a long name: the first letter with %101, the last with bit 7) = 23959 ($5D97, Entry)
    DB $A5,"ternit",$F9
    DB $00,$00
    DW Entry
    DB $00
    DB $80                      ; the end of the variables
; TR-DOS's autostart after a BASIC: $80 (above), $AA, the line number; then the rest of the last sector
    DB $AA
    DW 1
    DB "1998"
    ASSERT $ - Prog == 2816
