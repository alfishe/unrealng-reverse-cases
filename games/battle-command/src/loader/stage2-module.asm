; --------------------------------------------------------------------------------------------------------------------
; stage2-module.asm: The second stage: the screen, the keys, the table, the banks
;
; LoaderMain loads this block over $BF0D and runs it. It points the last-byte path of LoadBlocks at StoreLast (the
; first block's last byte was a check byte), then reads the screen and every block the table at BlockTable names, each
; after its mark: the attributes to $8000, the key patches to $BD9C and $BDD0, a new table over this one, the banks,
; the last pieces of the loader and the bootstrap. The stream ends at LoadEnd, which wants the XOR of every byte read
; to be 0.
;
; c1: entered at frame 2484; the screen's bitmap from frame 2099 of the tape, the last block at frame 23856.
; --------------------------------------------------------------------------------------------------------------------

; Load the screen and the table's blocks; then the end of the stage
;
; AttrFlag := 0; IX = Screen, DE = $17FF (6144 bytes); LastStoreJump :=
; StoreLast; CALL LoadBlocks reads the bitmap, then walks BlockTable to the
; end. If TimeFailed is set, WaitTask. Then the loop at $BF2B clears memory
; from $4000 upwards for ever: block 39 replaces this end with TimeEnd ($BF21,
; src/loader/final.asm) before it is reached. c1: L1 1.
Stage2Start:
  XOR A
  LD (AttrFlag),A
  LD IX,Screen
  LD DE,$17FF
  LD HL,StoreLast
  LD (LastStoreJump),HL
  CALL LoadBlocks
  LD A,(TimeFailed)
  OR A
  CALL NZ,WaitTask
  LD HL,Screen
Stage2Wipe:
  LD (HL),$00             ; LD (HL),0 / INC HL for ever: the end before block
                          ; 39 rewrites it
  INC HL
  JR Stage2Wipe

; The first block table: five bytes a row, the address, the length less one,
; the $7FFD value
;
; Rows: $8000 768 bytes (the attributes), $BD9C 2 (the body key), $BDD0 4 (the
; last-byte key), $BF30 75 (the table again, src/tape/side1.txt has the new
; rows), $6000 8192 and $4000 6912 with pages $13 / $12 and $FB00 512, never
; read (the new table replaces them first), and the end row of zeros. Read by
; the table walk in LoadBlocks (c1).
BlockTable:
  DEFB $00,$80,$FF,$02,$10
  DEFB $9C,$BD,$01,$00,$10 ; row 1, $BD9C
  DEFB $D0,$BD,$03,$00,$10 ; row 2, $BDD0
  DEFB $30,$BF,$4A,$00,$10 ; row 3, $BF30: this table
  DEFB $00,$60,$FF,$1F,$13,$00,$40,$FF ; rows 4-6: never read
  DEFB $1A,$12,$00,$FB,$FF,$01,$10
  DEFB $00,$00,$00,$00,$00 ; the end
BlockTablePad:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; zeros up to the font
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; The countdown's digits 0-9, 8 bytes each
;
; Read by WaitTask's countdown (c1: the digits at the top right of the screen
; during the load).
CountdownFont:
  DEFB $7E,$66,$66,$66,$66,$76,$7E,$00
  DEFB $18,$38,$18,$18,$18,$18,$7E,$00
  DEFB $7E,$66,$06,$7E,$60,$60,$7E,$00
  DEFB $7E,$66,$06,$1E,$06,$66,$7E,$00
  DEFB $66,$66,$66,$7E,$06,$06,$06,$00
  DEFB $7E,$60,$60,$7E,$06,$66,$7E,$00
  DEFB $7E,$66,$60,$7E,$66,$66,$7E,$00
  DEFB $7E,$66,$06,$0E,$0C,$0C,$0C,$00
  DEFB $7E,$66,$66,$7E,$66,$66,$7E,$00
  DEFB $7E,$66,$66,$7E,$06,$66,$7E,$00
