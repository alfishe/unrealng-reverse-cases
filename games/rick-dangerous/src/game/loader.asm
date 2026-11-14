; --------------------------------------------------------------------------------------------------------------------
; loader.asm: What the ROM and the loader leave below the game: system variables, the BASIC, the second stage, the AY player
;
; The image is memory at the game's entry $AB4D (tools/image.py: SkoolKit's simulated load of the original TZX on a
; 128K). Below the graphics at $6E00 it holds what the 128K ROM and the loader left: the ROM's paging routines and
; system variables at $5B00-$5CCA, the first 53 bytes of the BASIC "Rick", the second loader stage at $5D00 (its last
; bytes the loader's stack), and from $5E00 the AY player and its tunes, which the entry copies to RAM 1 (src/music),
; then two sprite frames the entry copies to their places; once copied, $5E00-$6DFF is work space (the char map, the
; cell flags).
;
; The game rebuilds $5C00-$5CFF as its char property table (BuildCharProps $F6A9); the bytes here are the ones the
; load leaves, kept so the image is the original's.
; --------------------------------------------------------------------------------------------------------------------

; The 128K ROM's paging routines, copied here by its reset (SWAP, YOUNGER,
; ONERROR, PIN, POUT, POUT2)
;
; Known only from the 128K ROM: the load runs on the 128K editor, whose reset
; copies them. No code of the game calls them.
RomPagingRoutines:
  DEFB $F5,$C5,$01,$FD,$7F,$3A,$5C,$5B
  DEFB $EE,$10,$F3,$32,$5C,$5B,$ED,$79
  DEFB $FB,$C1,$F1,$C9,$CD,$00,$5B,$E5
  DEFB $2A,$5A,$5B,$E3,$C9,$F3,$3A,$5C
  DEFB $5B,$E6,$EF,$32,$5C,$5B,$01,$FD
  DEFB $7F,$ED,$79,$FB,$C3,$C3,$00,$21
  DEFB $D8,$06,$18,$03,$21,$CA,$07,$08
  DEFB $01,$FD,$7F,$3A,$5C,$5B,$F5,$E6
  DEFB $EF,$F3,$32,$5C,$5B,$ED,$79,$C3
  DEFB $E6,$05,$08,$F1,$01,$FD,$7F,$F3
  DEFB $32,$5C,$5B,$ED,$79,$FB,$08,$C9

; The 128K ROM's system variables (TARGET, RETADDR, BANK_M $5B5C, ...) and its
; stack TSTACK up to $5BFF
;
; Known only from the 128K ROM.
Rom128Variables:
  DEFB $DE,$1C,$D9,$18,$10,$CF,$00,$0B
  DEFB $00,$00,$00,$00,$50,$00,$11,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$F3,$5B,$EC,$EB,$EC,$2B,$01
  DEFB $01,$2E,$00,$21,$03,$00,$00,$00
  DEFB $00,$00,$00,$00,$0A,$00,$0A,$00
  DEFB $01,$03,$07,$0F,$1F,$3F,$7F,$FF
  DEFB $FE,$FC,$F8,$F0,$E0,$C0,$80,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$45
  DEFB $39,$A3,$39,$DB,$02,$7C,$38,$6C
  DEFB $FD,$4D,$00,$DB,$02,$7C,$38,$6C
  DEFB $FD,$4D,$00,$BC,$5C,$02,$03,$CE
  DEFB $0B,$FC,$50,$05,$17,$F3,$0D,$21
  DEFB $18,$00,$00,$5C,$00,$00,$00,$27
  DEFB $1F,$F7,$02,$E7,$3F,$2B,$27,$E7
  DEFB $3F,$7A,$26,$11,$0D,$67,$26,$00

; The 48K system variables as the loader leaves them (DF_SZ 2, NMIADD 0, RAMTOP
; $C350, ...)
;
; The game rebuilds `$5C00-$5CFF` as its char property table before it uses it
; (BuildCharProps `$F6A9`).
SystemVariables:
  DEFB $FF,$00,$00,$00,$FF,$00,$23,$0D
  DEFB $0D,$23,$02,$00,$00,$00,$16,$0A
  DEFB $01,$00,$06,$00,$0B,$00,$01,$00
  DEFB $01,$00,$06,$00,$10,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$3C
  DEFB $40,$00,$FF,$DC,$00,$4D,$C3,$00
  DEFB $00,$00,$0A,$00,$FF,$3C,$00,$01
  DEFB $07,$00,$00,$80,$5D,$00,$00,$B6
  DEFB $5C,$BB,$5C,$CB,$5C,$80,$5D,$CA
  DEFB $5C,$81,$5D,$81,$5D,$7F,$5D,$B9
  DEFB $5D,$86,$5D,$86,$5D,$86,$5D,$2D
  DEFB $92,$5C,$00,$02,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$4A,$17,$00,$00
  DEFB $3E,$00,$00,$58,$FF,$00,$00,$00
  DEFB $00,$00,$21,$17,$56,$48,$E0,$50
  DEFB $0B,$0E,$21,$17,$03,$00,$00,$07
  DEFB $3F,$10,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$50,$C3,$FF,$FF

; The channel information: K, S, R and P, then the $80 end mark
ChannelInfo:
  DEFB $F4,$09,$A8,$10,$4B,$F4,$09,$C4
  DEFB $15,$53,$81,$0F,$C4,$15,$52,$34
  DEFB $5B,$2F,$5B,$50,$80

; The first 53 bytes of the BASIC "Rick" (src/tape/basic.asm): lines 10, 20 and
; the start of 30; the second stage overwrote the rest
BasicLeft:
  DEFB $00,$0A,$19,$00,$EA,$20,$52,$49
  DEFB $43,$4B,$20,$44,$41,$4E,$47,$45
  DEFB $52,$4F,$55,$53,$20,$20,$76,$2E
  DEFB $32,$2F,$38,$39,$0D,$00,$14,$0D
  DEFB $00,$FD,$35,$30,$30,$30,$30,$0E
  DEFB $00,$00,$50,$C3,$00,$0D,$00,$1E
  DEFB $1D,$00,$E7,$30,$0E

; The second loader stage, deciphered (src/loader/stage2.asm): the build's
; stage2.bin
LoaderStage2:
  INCBIN "stage2.bin",$0000,231

; The loader's stack at the game's entry: 24 bytes under $5DFF (zeros on the
; tape)
;
; What the second stage's calls (LoadGroup, the ROM's KEY-SCAN) left on its
; stack (SP = `$5DFF` from `$5D51`); nothing reads them.
LoaderStack:
  DEFB $CE,$0B,$CE,$0B,$54,$48,$CE,$0B
  DEFB $55,$48,$0C,$0E,$DC,$0A,$FE,$15
  DEFB $58,$27,$5E,$FB,$30,$FA,$9C,$5D
  DEFB $00

; The AY player and its tunes, $0DA4 bytes, as the entry copies them to RAM 1
; $C000 (src/music/music.asm)
MusicImage:
  INCBIN "music.bin",$0000,3492

; A sprite frame (24 x 21, 126 bytes): kind 16's graphic, which Start $AB4D
; copies to $6A80
;
; Start (`$AB62`) LDIRs it to `$6A80`, the frame ObjectKinds gives kind 16,
; past the map's rows: the music's bytes at
;
; `$5E00-$6BA3` and these become work space (the char map from `$6500`, the
; cell flags from `$6C00`) once RAM 1 has
;
; the player. Read once, by that copy (c1).
Kind16Frame:
  INCBIN "res/sprites/copied.bin",$0000,126

; A sprite frame: kind 19's graphic, which Start $AB4D copies to $7080
;
; The second LDIR of Start, to GraphicSlot19 `$7080`.
Kind19Frame:
  INCBIN "res/sprites/copied.bin",$007E,126

; Zeros up to the graphics: part of the cell flags ($6B00-$707F) as the load
; leaves them
;
; The game writes the cell flags before it reads them (MarkAllDirty `$A239`).
LowZeros:
  DEFS $0160
