; --------------------------------------------------------------------------------------------------------------------
; leftover.asm: What the development machine left: the BASIC stack, the UDGs, a serial downloader
; --------------------------------------------------------------------------------------------------------------------

; Leftover of the development machine: its BASIC machine stack
;
; Words such as $0DF3, $0BCE, $171E, $0ADC (48K ROM addresses), $50E2, $6D5F,
; and at $FF54 $1303 (the address the 48K ROM keeps at the bottom of every
; BASIC stack, the error return to MAIN-4), then $3E at $FF57: the marker byte
; the ROM puts at RAMTOP, here $FF57, the 48K default. The image was saved from
; a 48K whose BASIC stack and user-defined graphics lay at the top of RAM. No
; reader in any recording.
LeftoverStack:
  DEFB $F3,$0D,$CE,$0B,$E2,$50,$CE,$0B,$E3,$50,$1E,$17,$DC,$0A,$CE,$0B
  DEFB $E4,$50,$1D,$17,$03,$1A,$FF,$FF,$FF,$FF,$DB,$02,$4D,$00,$DB,$02
  DEFB $4D,$00,$DB,$02,$4D,$00,$BD,$58,$43,$02,$BC,$58,$4C,$38,$C0,$57
  DEFB $71,$0E,$F3,$0D,$21,$17,$C6,$1E,$5F,$6D,$76,$1B,$03,$13,$00,$3E
LeftoverUdgs:
  DEFB $00,$3C,$42,$42,$7E,$42,$42,$00,$00,$7C,$42,$7C,$42,$42,$7C,$00 ; $FF58-$FF77:
  DEFB $00,$3C,$42,$40,$40,$42,$3C,$00,$00,$78,$44,$42,$42,$44,$78,$00 ; the
                                                                       ; user-defined
                                                                       ; graphics
                                                                       ; A-D as the
                                                                       ; ROM sets
                                                                       ; them
                                                                       ; (copies of
                                                                       ; the ROM
                                                                       ; font's A,
                                                                       ; B, C, D)

; A development downloader over the ZX Interface 1 RS232 port, left in the
; image (never ran)
;
; DI, the checksum SerialSum $FFDB = 0, then blocks: a count byte (0 ends), the
; address high and low, the bytes to (HL) (the border shows each byte's low 3
; bits). After the 0 one more byte is compared with the checksum of everything
; received: a mismatch is JP $0000 (a reset), else EI and RET. Bytes come from
; SerialReadByte $FFA7. It lies over the UDGs E-P; no code of the game reaches
; it and no recording ran it: the transfer tool of the cross-development setup
; the code was sent with.
SerialDownloader:
  DI
  XOR A
  LD (SerialSum),A
SerialDownloaderBlock:
  CALL SerialReadByte     ; the next block: its count, 0 the end
  OR A
  JR Z,SerialDownloaderCheck
  LD D,A
  CALL SerialReadByte
  LD H,A
  CALL SerialReadByte
  LD L,A
SerialDownloaderByte:
  CALL SerialReadByte     ; a byte to (HL), the border from it
  LD (HL),A
  INC HL
  AND $07
  OUT ($FE),A
  DEC D
  JR NZ,SerialDownloaderByte
  JR SerialDownloaderBlock
SerialDownloaderCheck:
  LD A,(SerialSum)        ; the checksum byte
  LD H,A
  CALL SerialReadByte
  CP H
  JP NZ,$0000
  EI
  RET

; SerialReadByte
;
; Used by the routine at SerialDownloader.
SerialReadByte:
  LD A,$FE                ; one byte off the Interface 1 RS232 line: CTS on
                          ; (port $EF = $FE), the start bit awaited on port $F7
                          ; bit 7, 8 bits about 9600 baud apart (DJNZ $23 to
                          ; the middle, $19 a bit), CTS off ($EE); A = the byte
                          ; (the line inverted), XORed into SerialSum
  OUT ($EF),A
  IN A,($F7)
  RLCA
  JR NC,SerialReadByte
  IN A,($F7)
  RLCA
  JR NC,SerialReadByte
  IN A,($F7)
  RLCA
  JR NC,SerialReadByte
  LD B,$23
SerialStartWait:
  DJNZ SerialStartWait    ; half a bit's time
  LD C,$80
SerialReadBit:
  IN A,($F7)
  RLCA
  LD B,$19
SerialBitWait:
  DJNZ SerialBitWait      ; one bit's time
  RR C
  JR NC,SerialReadBit
  LD A,$EE
  OUT ($EF),A
  LD A,C
  CPL
  LD C,A
  LD A,(SerialSum)
  XOR C
  LD (SerialSum),A
  LD A,C
  RET

; The downloader's checksum
SerialSum:
  DEFB $00
LeftoverCode:
  DEFB $30                ; $FFDC-$FFFA: an older copy of SerialReadByte's tail
  DEFB $F2                ; (the bytes of $FFB3-$FFD1, then CPL and RET: no
  DEFB $DB                ; checksum); $FFFB-$FFFF the end of UDG U
  DEFB $F7
  DEFB $07
  DEFB $30
  DEFB $ED
  DEFB $06
  DEFB $23
  DEFB $10
  DEFB $FE
  DEFB $0E
  DEFB $80
  DEFB $DB
  DEFB $F7
  DEFB $07
  DEFB $06
  DEFB $19
  DEFB $10
  DEFB $FE
  DEFB $CB
  DEFB $19
  DEFB $30
  DEFB $F5
  DEFB $3E
  DEFB $EE
  DEFB $D3
  DEFB $EF
  DEFB $79
  DEFB $2F
  DEFB $C9
  DEFB $42
  DEFB $42
  DEFB $42
  DEFB $3C
  DEFB $00
