; H.A.T.E. - the BASIC loader, block 1 of the tape (413 bytes, LINE 10).
;
; Lines 0 and 1 are REMs added by INXS Soft for their 1989 disk version: line 0 holds the credit text and the banner
; code (USR 23788), line 1 the title it shows. Line 10 loads and starts the two CODE blocks; BASIC then falls
; through to line 30, which enters the game. docs/03-build-and-load.md, 3.2 and 3.3.
;
; Assembled at PROG ($5CCB), where the ROM loads a program on a 48K machine with no microdrive channels.

        device zxspectrum48

; ROM and system variables used here
CHAN_OPEN       equ $1601               ; A = channel number
CHARS           equ $5C36               ; font address - 256
ROM_FONT        equ $3D00               ; the ROM's character set, space onwards

; BASIC tokens and controls
T_CODE          equ $AF
T_USR           equ $C0
T_INK           equ $D9
T_PAPER         equ $DA
T_BORDER        equ $E7
T_REM           equ $EA
T_LOAD          equ $EF
T_POKE          equ $F4
T_RANDOMIZE     equ $F9
T_CLS           equ $FB
T_CLEAR         equ $FD
C_AT            equ $16
C_INK           equ $10
CR              equ $0D

; A small integer as BASIC keeps it after its digits: the number marker and the 5-byte integer form
        macro NUM value
        db $0E, 0, 0, low (value), high (value), 0
        endm

        org $5CCB

; ---------------------------------------------------------------------------------------------------------------
; 0 REM Disked by INXS SOFT'89 ... and the banner
line0:  db 0, 0
        dw line0_end - line0_text
line0_text:
        db T_REM
Credit: db "Disked by INXS SOFT'89     "  ; $5CD0: slid in on row 12 by WipeCredit
        db CR

; The banner, USR 23788 ($5CEC). Called once from line 10, before the first CODE block loads.
Banner:
        call MeasureTitle
        call BoldFont
        call FadeInTitle
        call RomFont
        call WipeCredit
        ret

; The title's length up to its CR (at most 30) and the column that centres it
MeasureTitle:
        ld hl,Title
        ld b,30
.find:  ld a,(hl)
        cp CR
        jr z,.found
        inc hl
        djnz .find
.found: ld a,30
        sub b
        ld (TitleLength),a
        ld b,a
        ld a,32
        sub b
        srl a
        ld (TitleColumn),a
        ret
TitleLength:
        db 8                            ; as left on the tape: the length of "H.A.T.E."
TitleColumn:
        db 12

; The title at row 10, eight times with INK 0 to 7, three frames apart: it fades in from the black screen
FadeInTitle:
        ld a,2                          ; the upper screen
        call CHAN_OPEN
        ld b,8
.step:  ld a,C_AT
        rst $10
        ld a,10
        rst $10
        ld a,(TitleColumn)
        rst $10
        ld a,C_INK
        rst $10
        ld a,8
        sub b
        rst $10
        push bc
        ld a,(TitleLength)
        ld b,a
        ld hl,Title
.char:  ld a,(hl)
        rst $10
        inc hl
        djnz .char
        pop bc
        call Wait3
        djnz .step
        ret

; Three frames (the ROM's interrupt is on)
Wait3:
        push bc
        ld b,3
.halt:  halt
        djnz .halt
        pop bc
        ret

; The credit on row 12, printed at columns 31 down to 5, each time its first 32 - column characters: it slides in
; from the right edge
WipeCredit:
        ld b,31
.step:  ld a,C_AT
        rst $10
        ld a,12
        rst $10
        ld a,b
        rst $10
        ld a,32
        sub b
        push bc
        ld hl,Credit
        ld b,a
.char:  ld a,(hl)
        rst $10
        inc hl
        djnz .char
        pop bc
        dec b
        ld a,b
        cp 4
        jp nz,.step
        ret

; A bold font: every byte of the ROM's ORed with itself shifted right, at $C350; CHARS points at it
BoldFont:
        ld hl,ROM_FONT
        ld de,BoldChars
        push de
        ld bc,$0300
.byte:  ld a,(hl)
        rra
        or (hl)
        ld (de),a
        inc hl
        inc de
        dec bc
        ld a,b
        or c
        jr nz,.byte
        pop hl
        dec h
        ld (CHARS),hl
        ret

; The ROM's font back
RomFont:
        ld hl,ROM_FONT
        dec h
        ld (CHARS),hl
        ret

        db 0, "00000"                   ; unused (the REM's padding)
        db CR
line0_end:

BoldChars       equ $C350               ; a free area above RAMTOP, overwritten later by the game

; ---------------------------------------------------------------------------------------------------------------
; 1 REM H.A.T.E.
line1:  db 0, 1
        dw line1_end - line1_text
line1_text:
        db T_REM
Title:  db "H.A.T.E."                   ; $5D9E
        db CR
line1_end:

; ---------------------------------------------------------------------------------------------------------------
; 10 PAPER 0: BORDER 0: POKE 23624,0: INK 0: CLEAR 24499: RANDOMIZE USR 23788: LOAD "H_A_T_E.1" CODE: CLS:
;    RANDOMIZE USR 40000: POKE 23739,111: LOAD "H_A_T_E.2" CODE: RANDOMIZE USR 24500
line10: db 0, 10
        dw line10_end - line10_text
line10_text:
        db T_PAPER, "0"
        NUM 0
        db ":", T_BORDER, "0"
        NUM 0
        db ":", T_POKE, "23624"         ; BORDCR: the lower screen black too
        NUM 23624
        db ",0"
        NUM 0
        db ":", T_INK, "0"
        NUM 0
        db ":", T_CLEAR, "24499"        ; RAMTOP below the game's first byte
        NUM 24499
        db ":", T_RANDOMIZE, T_USR, "23788"
        NUM Banner
        db ":", T_LOAD, " \"H_A_T_E.1\"", T_CODE   ; a space after LOAD, as typed
        db ":", T_CLS
        db ":", T_RANDOMIZE, T_USR, "40000"     ; the loading screen
        NUM 40000
        db ":", T_POKE, "23739"         ; CHANS + 5: the S channel's output -> $096F, a RET: no "Bytes:" message
        NUM 23739
        db ",111"
        NUM 111
        db ":", T_LOAD, " \"H_A_T_E.2\"", T_CODE   ; a space after LOAD, as typed
        db ":", T_RANDOMIZE, T_USR, "24500"     ; the depacker; returns here, BASIC goes on to line 30
        NUM 24500
        db CR
line10_end:

; ---------------------------------------------------------------------------------------------------------------
; 20 REM NO POKE
line20: db 0, 20
        dw line20_end - line20_text
line20_text:
        db T_REM, "NO POKE", CR
line20_end:

; ---------------------------------------------------------------------------------------------------------------
; 30 RANDOMIZE USR 25000: the game
line30: db 0, 30
        dw line30_end - line30_text
line30_text:
        db T_RANDOMIZE, T_USR, "25000"
        NUM 25000
        db CR
line30_end:

loader_end:
        savebin "loader.bin", line0, loader_end - line0
