; Nether Earth ZS Edition'99: the BASIC, sector 0 of NEZSEd99.B (256 bytes; TR-DOS loads it to PROG = $5D3B).
;
; Hand-written source (a BASIC line, six instructions and the sector's slack: too small for an annotation); every
; byte of the sector is here. Built by tools/build_front99.sh into build/front99/basic.bin and compared with
; work/media/99/basic.bin (tools/zs_media.py).
;
; Line 10 lists as  CLEAR 00000: RANDOMIZE USR 00000: REM ...  but runs  CLEAR 24999: RANDOMIZE USR 23899: each number
; is written as the text "00000" followed by the hidden 5-byte form ($0E then 0, 0, low, high, 0) that the ROM uses.
; USR 23899 = $5D5B, the code in the line's REM (Reader).
;
; Witness: r99 (work/stage1/r99), L1 window work/stage2/front99/basic (frames 152-177): Reader's five instructions
; run once each, entered at frame 152 from the ROM's USR ($34BB); TR-DOS's read returns into $8000 at frame 177
; (python3 $RS stages --work work/stage1/r99, arrivals 4 and 5).

  DEVICE ZXSPECTRUM48

TrDosEntry     EQU $3D13  ; TR-DOS's entry from BASIC ROM: C = 5 reads B sectors from track D sector E to HL
DosNextSector  EQU $5CF4  ; TR-DOS: the sector (E) and track (D) after the last one read (here: after this sector)
Stage2Load     EQU $8000  ; where stage 2's packed block (sectors 1-18) is read and entered

  ORG $5D3B

; Line 10 (the program is this one line, 44 bytes of text)
Line10:
  DEFB $00,$0A            ; line number 10 (high byte first)
  DEFW Line10End-Line10Text ; the text's length: 44
Line10Text:
  DEFB $FD                ; CLEAR
  DEFM "00000"            ; shown
  DEFB $0E,$00,$00        ; the hidden number ...
  DEFW 24999              ; ... 24999: RAMTOP below stage 2's $61A8
  DEFB $00
  DEFB ":",$F9,$C0        ; : RANDOMIZE USR
  DEFM "00000"            ; shown
  DEFB $0E,$00,$00        ; the hidden number ...
  DEFW Reader             ; ... 23899 = $5D5B
  DEFB $00
  DEFB ":",$EA            ; : REM, the code follows in the line

; Read stage 2: 18 sectors from where TR-DOS stopped (the sector after this one) to $8000, then run it
;
; DE = DosNextSector: TR-DOS left there the track and sector after the BASIC it just loaded (sector 1 of
; NEZSEd99.B). C = 5: read B = 18 sectors to HL. Stage2Load is pushed first, so the RET at the end of TR-DOS's read
; enters the packed block (r99 frame 177).
Reader:
  LD HL,Stage2Load
  PUSH HL                 ; TR-DOS's RET goes to $8000
  LD DE,(DosNextSector)
  LD BC,$1205             ; B = 18 sectors, C = 5: read
  JP TrDosEntry
  DEFB $00                ; a byte no code reads (between the JP and the line's end)
  DEFB $0D                ; the line's ENTER
Line10End:

; After the program: what TR-DOS saved with it (the catalogue's 48 bytes end above)
  DEFB $80                ; the end of the (empty) variables area
  DEFB $AA                ; TR-DOS: the autostart mark ...
  DEFW 10                 ; ... and the line it runs: 10

; The sector's slack: 204 bytes no code reads, as on the disk (the memory after the program when the file was saved):
; zeros but one $0A at $5D96 (offset $5B)
  DEFS 39,$00             ; $5D6F-$5D95
  DEFB $0A                ; $5D96
  DEFS 164,$00            ; $5D97-$5E3A

  SAVEBIN "basic.bin",$5D3B,256
