; H.A.T.E. - the head of block 5, CODE "H_A_T_E.2" (35495 bytes at $5FB4, RANDOMIZE USR 24500): the depacker and
; the packed game. docs/03-build-and-load.md, 3.5.
;
; $5FB4 moves the depacker into the printer buffer, then moves the packed data down $64 bytes over itself with the
; ROM's LDIR; RET, which returns into the depacker. The depacker unpacks backwards from the last packed byte into
; $FFFF down to $5FB4 and returns to BASIC (line 30 starts the game).

        device zxspectrum48

ROM_LDIR_RET    equ $33C3                       ; LDIR : RET in the ROM
DEPACKER_AT     equ $5B8C                       ; in the printer buffer, out of the way of both copies
MARKER          equ $97                         ; the RLE marker
GAME_START      equ $5FB4                       ; the first byte the depacker writes, and the block's load address
GAME_END        equ $FFFF

        org GAME_START

Head:
        ld hl,Depacker
        ld de,DEPACKER_AT
        ld bc,Depacker_end - Depacker
        push de                                 ; the RET of ROM_LDIR_RET goes to the depacker
        ldir
        ld hl,Packed
        ld de,GAME_START
        ld bc,$10000 - Packed                   ; everything up to the top of RAM, the packed data in it
        jp ROM_LDIR_RET

; Runs at DEPACKER_AT. Reads backwards: a byte other than MARKER is itself; MARKER is preceded by a count N:
;   N bit 7 set    N & $7F zeros if 0 (256) or >= 3, else N & $7F copies of MARKER
;   N bit 7 clear  N copies (0 = 256) of the byte before N
Depacker:
        disp DEPACKER_AT
        ld hl,PACKED_LAST                       ; the last packed byte, moved down
        ld de,GAME_END
.next:  push hl
        ld bc,GAME_START - 1
        or a
        sbc hl,bc
        pop hl
        ret z                                   ; past the first packed byte: done
        ld a,(hl)
        cp MARKER
        jr z,.token
        ldd                                     ; a literal
        jr .next
.token: dec hl
        ld b,(hl)
        bit 7,b
        jr z,.repeat
        res 7,b
        ld a,b
        and a
        jr z,.fill                              ; $80: 256 zeros
        cp 3
        ld a,0
        jr nc,.fill                             ; 3-127 zeros
        ld a,MARKER                             ; 1-2 escaped markers
        jr .fill
.repeat:
        dec hl
        ld a,(hl)
.fill:  ld (de),a
        dec de
        djnz .fill
        dec hl
        jr .next
        ent
Depacker_end:

        ds GAME_START + $64 - $, 0              ; padding up to the packed data
Packed:
        incbin "game.pk"                        ; tools/pack.py of the game image $5FB4-$FFFF
Packed_end:
PACKED_LAST     equ Packed_end - 1 - (Packed - GAME_START)

        savebin "game-block.bin", Head, Packed_end - Head
