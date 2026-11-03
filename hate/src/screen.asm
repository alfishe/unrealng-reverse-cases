; H.A.T.E. - block 3 of the tape, CODE "H_A_T_E.1" (6432 bytes at $9C40, RANDOMIZE USR 40000): Vortex's screen
; unpacker and the loading screen. docs/03-build-and-load.md, 3.4.
;
; The code is position independent: it finds its own address, so the block may be loaded anywhere. IY points at
; the four parameter bytes; the pictures follow the code at IY + $12A.

        device zxspectrum48

SCREEN          equ $4000
ATTRS           equ $5800
ROM_RET         equ $007C                       ; a lone RET in the ROM

; Flags (Params + 3 and each picture's flag byte)
F_ACROSS        equ 0                           ; set: bitmap by pixel lines across; clear: by columns down
F_RUN           equ 2                           ; a run is being written (count in B', value in C')
F_ATTRS         equ 3                           ; the attribute phase

        org $9C40

ScreenUnpacker:
        jr Params.start
Params:
        db 1                                    ; IY+0: the picture to unpack (1 = the first)
        db $FF                                  ; IY+1: the first third, $FF = from the picture
        db $FF                                  ; IY+2: the number of thirds, $FF = from the picture
        db $0C                                  ; IY+3: flags
.start:
        call ROM_RET                            ; leaves the address of .here below SP
.here:  dec sp
        dec sp
        ex (sp),hl                              ; HL = .here
        inc sp
        inc sp
        and a
        ld de,.here - Params
        sbc hl,de
        push hl
        pop iy                                  ; IY = Params, wherever the block is
        ld de,Pictures - Params
        add hl,de
; Skip to the picture asked for: each starts with its length
        ld a,(iy+0)
.skip:  dec a
        jr z,.found
        ld e,(hl)
        inc hl
        ld d,(hl)
        add hl,de
        jr .skip
.found: ld de,SCREEN
        inc hl
        inc hl
; The picture's first third, number of thirds and flags, where the parameters leave them open
        ld a,(iy+1)
        inc a
        jr nz,.first
        ld a,(hl)
        ld (iy+1),a
.first: inc hl                                  ; the picture always has the byte
        ld a,(iy+2)
        inc a
        jr nz,.thirds
        ld a,(hl)
        ld (iy+2),a
.thirds:
        inc hl
        ld a,(hl)
        ld (iy+3),a
; Keep them on the screen: first third 0-2, thirds 1-3, first + thirds at most 3
        ld a,(iy+1)
        cp 3
        jr c,.first_ok
        ld (iy+1),0
.first_ok:
        ld a,(iy+2)
        cp 4
        jr c,.count_ok
        ld (iy+2),1
.count_ok:
        add a,(iy+1)
        cp 4
        jr c,.fits
        ld (iy+2),1
.fits:  ld a,(iy+2)
        and a
        jr nz,.some
        ld (iy+2),1
.some:  inc hl
; The bitmap: columns x thirds x character rows x pixel lines x bytes across
        ld e,0
        ld a,(iy+1)
        add a,a
        add a,a
        add a,a
        add a,high SCREEN
        ld d,a                                  ; DE = the first third's first byte
        ld c,a                                  ; C = its high byte, for each column
        ld b,1                                  ; across: one pass of 32 bytes a line
        bit F_ACROSS,(iy+3)
        jr nz,.columns
        ld b,32                                 ; down: 32 columns of one byte a line
.columns:
        push bc
        ld b,(iy+2)
.third: push bc
        ld b,8
.row:   push bc
        ld b,8
.line:  push bc
        ld b,1
        bit F_ACROSS,(iy+3)
        jr z,.bytes
        ld b,32
.bytes: push de
.byte:  push bc
        jr NextByte                             ; returns to .stored with the byte written at DE
.stored:
        pop bc
        inc de
        djnz .byte
        pop de
        pop bc
        inc d                                   ; the next pixel line
        djnz .line
        ld a,d
        sub 8
        ld d,a
        ld a,e
        add a,32                                ; the next character row
        ld e,a
        pop bc
        djnz .row
        ld a,d
        add a,8                                 ; the next third
        ld d,a
        pop bc
        djnz .third
        ld d,c
        inc e                                   ; the next column
        pop bc
        djnz .columns
; The attributes of the same thirds, in address order
        ld e,0
        ld a,high ATTRS
        add a,(iy+1)
        ld d,a
        ld b,(iy+2)
        ld c,e                                  ; BC = thirds x 256
        set F_ATTRS,(iy+3)
.attr:  push bc
        jr NextByte                             ; returns to .attr_stored
.attr_stored:
        pop bc
        dec bc
        inc de
        ld a,b
        or c
        jr nz,.attr
        ld (iy+1),$FF                           ; open again for the next call
        ld (iy+2),$FF
        ret

; The next byte of the RLE stream at HL, written at DE: 00 N V is N copies of V (0 = 256), anything else itself.
; Jumped to, not called: returns into the bitmap or the attribute loop by F_ATTRS.
NextByte:
        bit F_RUN,(iy+3)
        jr z,.read
        exx
        dec b
        ld a,c
        exx
        jr z,.run_done
        ld (de),a
        jr .back
.run_done:
        res F_RUN,(iy+3)
.read:  ld a,(hl)
        inc hl
        and a
        jr nz,.store
        ld a,(hl)
        exx
        ld b,a                                  ; B' = the count
        exx
        inc hl
        ld a,(hl)
        exx
        ld c,a                                  ; C' = the value
        exx
        inc hl
        set F_RUN,(iy+3)
.store: ld (de),a
.back:  bit F_ATTRS,(iy+3)
        jr nz,Params.attr_stored
        jr Params.stored

; 25 bytes not read by this code (a table of an earlier version, left in the block)
        db $08, $10, $11, $12, $12, $14, $00, $03, $00, $01, $02, $01, $00, $03, $00, $0F
        db $19, $0E, $00, $04, $00, $08, $18, $22, $22

; The pictures: length (to the next picture), first third, thirds, flags, the packed bytes
Pictures:
        dw LoadingScreen_end - Pictures
        db 0, 3, 1 << F_ACROSS
LoadingScreen:
        incbin "loading.pk"                     ; tools/screen_pack.py src/res/screens/loading.scr
        db $00, $01                             ; counted in the length, not read
LoadingScreen_end:
        ; The last 160 bytes of block 3, after the packed screen: not read by the unpacker (RLE fragments left in
        ; the packer's buffer), kept for the byte-exact tape
        incbin "res/leftovers/screen-tail.bin"
ScreenBlock_end:

        savebin "screen.bin", ScreenUnpacker, ScreenBlock_end - ScreenUnpacker
