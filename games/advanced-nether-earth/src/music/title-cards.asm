; =====================================================================================================================
; The title cards before the game ($D8E1-$E21A in bank 1, after the game tune): "Eternity Industry", "presents",
; "Advanced Nether Earth", each drawn on a black screen, its ink faded in from black to white, held, faded out and
; wiped. The game block's GameEntry pages bank 1 in, CALLs TitleCards, then pages bank 0 back and restarts the game.
; The bitmaps are src/res/music/title-*.png (tools/music_res.py); the screen is the 48 K ROM's interrupt-paced one
; (IM 1, I = $3F), so each HALT is a frame.
; =====================================================================================================================

; ---------------------------------------------------------------------------------------------------------------------
; TitleCards: the three cards; on the way the game tune is initialised (Init: TAIGA ready, the AY silent; the game's
; interrupt plays it). Out: a clear screen, border black, IM 1.
; ---------------------------------------------------------------------------------------------------------------------
TitleCards:
    DI
    LD    A,$3F                         ; I back to the ROM's value, IM 1: HALT waits a frame
    LD    I,A
    IM    1
    EI
    CALL  Init                          ; the game tune (src/music/stp-player.asm)
    XOR   A
    OUT   ($FE),A                       ; border black
    LD    HL,$5B00                      ; the screen and attributes cleared, downwards from $5AFF: the loop stops at
TitleCardsClear:                        ; the first byte that does not keep 0 (the ROM's last byte, $3FFF)
    DEC   HL
    LD    (HL),A
    OR    (HL)
    JR    Z,TitleCardsClear
    LD    HL,TitleEternityIndustry
    LD    DE,$4824                      ; screen third 1, character row 1, column 4
    LD    BC,$2018                      ; 32 lines of 24 bytes
    CALL  DrawBitmap
    LD    HL,FadeIn
    CALL  FadeAttributes
    CALL  Wait80
    LD    HL,FadeOut
    CALL  FadeAttributes
    CALL  ClearPixels
    LD    HL,TitlePresents
    LD    DE,$482A                      ; column 10
    LD    BC,$200C                      ; 32 lines of 12 bytes
    CALL  DrawBitmap
    LD    HL,FadeIn
    CALL  FadeAttributes
    CALL  Wait80
    LD    HL,FadeOut
    CALL  FadeAttributes
    CALL  ClearPixels
    LD    HL,TitleAdvancedNetherEarth
    LD    DE,$4807                      ; column 7
    LD    BC,$3812                      ; 56 lines of 18 bytes
    CALL  DrawBitmap
    LD    HL,FadeIn
    CALL  FadeAttributes
    CALL  Wait80
    LD    HL,FadeOut
    CALL  FadeAttributes
    CALL  ClearPixels
    RET

; ClearPixels: the screen's pixels ($4000-$57FF) to 0
ClearPixels:
    LD    HL,$4000
    LD    D,H
    LD    E,L
    INC   E
    LD    (HL),L
    LD    BC,$17FF
    LDIR
    RET

; Wait80: 80 frames
Wait80:
    LD    B,$50
Wait80Loop:
    HALT
    DJNZ  Wait80Loop
    RET

; DrawBitmap: HL = the bitmap (its pixel lines in order), DE = the screen address of its top left, B = the lines,
; C = the bytes a line
DrawBitmap:
    PUSH  BC
    PUSH  DE
    LD    B,$00
    LDIR
    POP   DE
    CALL  NextLine
    POP   BC
    DJNZ  DrawBitmap
    RET

; NextLine: DE = the screen address one pixel line down
NextLine:
    INC   D
    LD    A,D
    AND   $07
    RET   NZ
    LD    A,E
    ADD   A,$20
    LD    E,A
    RET   C
    LD    A,D
    SUB   $08
    LD    D,A
    RET

; FadeAttributes: HL = 8 attribute values; each in turn fills the whole attribute area ($5800-$5AFF), two frames
; apiece
FadeAttributes:
    LD    B,$08
FadeAttributesStep:
    PUSH  BC
    PUSH  HL
    LD    A,(HL)
    LD    HL,$5800
    LD    D,H
    LD    E,L
    INC   E
    LD    (HL),A
    LD    BC,$02FF
    LDIR
    HALT
    HALT
    POP   HL
    INC   HL
    POP   BC
    DJNZ  FadeAttributesStep
    RET

; the fades: ink 0-7 on black paper, up and down
FadeIn:
    DB    $00,$01,$02,$03,$04,$05,$06,$07
FadeOut:
    DB    $07,$06,$05,$04,$03,$02,$01,$00

; the bitmaps (src/res/music/title-*.png, built by tools/music_res.py)
TitleEternityIndustry:
    INCBIN "build/music/res/titles/eternity-industry.bin"
TitlePresents:
    INCBIN "build/music/res/titles/presents.bin"
TitleAdvancedNetherEarth:
    INCBIN "build/music/res/titles/advanced-nether-earth.bin"
