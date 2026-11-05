; loader.asm: neart0222, Hood's tape loader (865 bytes at $61A8-$6508), 2017. docs/03-build-and-load.md 3.3,
; docs/09-sound.md 9.7.
;
; Hood made the tape version from the disk loader neart022 by changing 91 of its bytes in place, so the layout is
; the disk loader's (src/disk/loader.asm) and the bytes he did not change are still there, some of them never run.
; On tape the BASIC (src/tape/basic.asm) does the loading: each file is a standard ROM block that the BASIC loads
; with LOAD "" CODE to its address ($8000 for the sound files), then calls one of the entries below with RANDOMIZE
; USR. Each entry sends what the disk loader sent after the same file and returns to BASIC.
;
; What he changed:
; - Every command now goes through SendCommand: the command byte follows its CALL, and the card is waited for after
;   each one. The #F4 / #30 / #D1 that lost the disk version its music, and the #3E / #D1 pairs that lost effects,
;   now reach the card.
; - Each disk "LD HL,name / CALL LoadFile" became "RET / CALL LoadFile": the RET ends the entry before it, the two
;   operand bytes of the LD stay as dead bytes, and LoadFile no longer loads anything: it jumps to TickReturn, which
;   draws the progress tick and gives BASIC back its H'L' ($2758, which the ROM needs on the return from USR).
; - LoadEffect sends data 1 before #3E: effects 1-13 are stored unsigned, as the files are. LoadEffectOpen, used for
;   effect 14, was not changed: data 0 (stored with every byte + $80) and no wait between #3E, #D1 and the first
;   bytes. Live (work/stage1, x4 / x6) the card holds effect 14 from its 4th byte on, every byte flipped: consistent
;   with the first 3 data bytes written before the card's LOAD loop was ready to take them.
; - The driver goes to bank 6 ($16) instead of bank 1: SendEffect14b pages bank 6 and returns, the BASIC loads
;   neart021 to $C000, and PageBank0 pages bank 0 back. This only works when the ROM leaves the paging alone between
;   the two USRs (48 BASIC with paging free, docs/03-build-and-load.md 3.3).
; - MusicOff (#F4 only) for "2-music OFF"; the BASIC also pokes RET at StartModule.
;
;   sjasmplus src/tape/loader.asm   ->  build/tape/loader.bin (865 bytes)

  INCLUDE "../disk/gs.inc"

Start           EQU $A600       ; the game's entry (src/game: Start)
Buffer          EQU $8000       ; where the BASIC loads every sound file
TrDos           EQU $3D13       ; (only in the dead rest of the disk LoadFile)
DrawLine        EQU $24BA       ; the 48K ROM's DRAW-LINE
Coords          EQU $5C7D       ; COORDS
BarCells        EQU $5861       ; the four attribute cells ShowByte colours
BarDone         EQU $56
BasicHl         EQU $2758       ; the H'L' the 48K ROM's expression evaluator needs on the return from USR
ELine           EQU $5C59
StkEnd          EQU $5C65
TrDosRet        EQU $5CC2
TrDosF4         EQU $5CB6
TrDosName       EQU $5CDD
TrDos5CFA       EQU $5CFA
TrDos5D06       EQU $5D06
FreeMemory      EQU $5D27

  OUTPUT "build/tape/loader.bin"
  ORG $61A8

; The disk loader's start, kept and never run on tape (the BASIC loads the screen itself and enters at the USR
; entries below; this code would clear the screen it just loaded)
LoaderStart:
    LD HL,$4000
    LD DE,$4001
    LD BC,$1AFF
    LD A,0
    LD (HL),A
    LDIR
    OUT ($FE),A
    LD HL,NameScreen
    CALL LoadFile

; USR 25022 (line 20, before the module): reset the card, start a module load, open its stream, each command waited
GsStartModule:
    CALL SendCommand
    DB GsReset
    CALL SendCommand
    DB GsLoadModule
    CALL SendCommand
    DB GsOpen
    RET
    DW NameModule1              ; dead: the operand of the disk loader's LD HL,NameModule1
; USR 25037, 25046, 25055, 25064 (line 20, after LOAD "neart002" ... "neart005" CODE): send the 32768 bytes
SendModule1:
    CALL LoadFile               ; the tick
    CALL SendModuleFile
    RET
    DW NameModule2              ; dead
SendModule2:
    CALL LoadFile
    CALL SendModuleFile
    RET
    DW NameModule3              ; dead
SendModule3:
    CALL LoadFile
    CALL SendModuleFile
    RET
    DW NameModule4              ; dead
SendModule4:
    CALL LoadFile
    CALL SendModuleFile
    RET
    DW NameModule5              ; dead
; USR 25073 (after neart006): the last 6998 bytes, then #D2: module 1 is on the card
SendModule5:
    CALL LoadFile
    CALL SendModuleLast
    CALL SendCommand
    DB GsClose
    RET
    DW NameFx1                  ; dead
; USR 25086 ... 25230 (lines 30-50, after each effect file): LoadEffect with the file's length; the card numbers
; them 1-13 in this order
SendFx1:
    CALL LoadFile
    LD DE,14798
    CALL LoadEffect             ; effect 1: neart007
    RET
    DW NameFx2                  ; dead
SendFx2:
    CALL LoadFile
    LD DE,14592
    CALL LoadEffect             ; effect 2: neart008
    RET
    DW NameFx3                  ; dead
SendFx3:
    CALL LoadFile
    LD DE,23296
    CALL LoadEffect             ; effect 3: neart009
    RET
    DW NameFx4                  ; dead
SendFx4:
    CALL LoadFile
    LD DE,19456
    CALL LoadEffect             ; effect 4: neart010
    RET
    DW NameFx5                  ; dead
SendFx5:
    CALL LoadFile
    LD DE,26880
    CALL LoadEffect             ; effect 5: neart011
    RET
    DW NameFx6                  ; dead
SendFx6:
    CALL LoadFile
    LD DE,8499
    CALL LoadEffect             ; effect 6: neart012
    RET
    DW NameFx7                  ; dead
SendFx7:
    CALL LoadFile
    LD DE,15427
    CALL LoadEffect             ; effect 7: neart013
    RET
    DW NameFx8                  ; dead
SendFx8:
    CALL LoadFile
    LD DE,19187
    CALL LoadEffect             ; effect 8: neart014
    RET
    DW NameFx9                  ; dead
SendFx9:
    CALL LoadFile
    LD DE,9056
    CALL LoadEffect             ; effect 9: neart015
    RET
    DW NameFx10                 ; dead
SendFx10:
    CALL LoadFile
    LD DE,176
    CALL LoadEffect             ; effect 10: neart016
    RET
    DW NameFx14a                ; dead: the disk loader's slip (neart019 for effect 11) is only a dead operand here
SendFx11:
    CALL LoadFile
    LD DE,401
    CALL LoadEffect             ; effect 11: neart017 (the BASIC loads the right file)
    RET
    DW NameFx12                 ; dead
SendFx12:
    CALL LoadFile
    LD DE,15849
    CALL LoadEffect             ; effect 12: neart018
    RET
    DW NameFx13                 ; dead
SendFx13:
    CALL LoadFile
    LD DE,12560
    CALL LoadEffect             ; effect 13: neart023
    RET
    DW NameFx14a                ; dead
; USR 25242 (after neart019): effect 14's first 32768 bytes, the stream left open (data 0: signed, see above)
SendFx14a:
    CALL LoadFile
    LD DE,32768
    CALL LoadEffectOpen
    RET
    DW NameFx14b                ; dead
; USR 25254 (after neart020): the rest of effect 14 and #D2, then bank 6 paged at $C000 for the driver's LOAD
SendFx14b:
    CALL LoadFile
    LD DE,16506
    CALL SendEffectRest
    LD A,$16                    ; 48K ROM, bank 6
    LD BC,Port7FFD
    OUT (C),A
    RET
    DW NameDriver               ; dead
; USR 25273 (line 60, after LOAD "neart021" CODE): bank 0 back at $C000
PageBank0:
    CALL LoadFile
    LD A,$10                    ; 48K ROM, bank 0
    LD BC,Port7FFD
    OUT (C),A
    RET
    DW NameGame                 ; dead
; USR 25286 (after LOAD "neart001" CODE): the module on, the volumes, and play
StartGame:
    CALL LoadFile
    CALL StartModule
    LD A,$40
    OUT (GsData),A
    CALL SendCommand
    DB GsFxVolume               ; effects at 64 of 64
    LD A,$25
    OUT (GsData),A
    CALL SendCommand
    DB GsModVolume              ; the module at 37 of 64
    JP Start

; StartModule (25311): plays the current module (#31, data 0). "2-music OFF" pokes RET (201) here
StartModule:
    CALL WaitGs
    LD A,0
    OUT (GsData),A
    CALL SendCommand
    DB GsPlayModule
    RET

; SendModuleFile / SendModuleLast / SendBytes: as on disk: one wait, then DE bytes from Buffer to GsData
SendModuleFile:
    LD DE,32768
    JR SendBytes
SendModuleLast:
    LD DE,6998
SendBytes:
    CALL WaitGs
    LD HL,Buffer
.loop:
    LD A,(HL)
    OUT (GsData),A
    CALL ShowByte
    INC HL
    DEC DE
    LD A,E
    CP 0
    JR NZ,.loop
    LD A,D
    CP 0
    JR NZ,.loop
    LD A,BarDone
    CALL ShowByte
    RET

; WaitGs: waits until the card has taken the last command
WaitGs:
    IN A,(GsCommand)
    RRCA
    JR C,WaitGs
    RET

; LoadEffect: one effect of DE bytes from Buffer: data 1 (unsigned samples), #3E, #D1, the bytes, #D2, each command
; waited for
LoadEffect:
    CALL WaitGs
    LD A,1
    OUT (GsData),A
    CALL SendCommand
    DB GsLoadFx
    CALL SendCommand
    DB GsOpen
    LD HL,Buffer
.loop:
    LD A,(HL)
    CALL ShowByte
    OUT (GsData),A
    INC HL
    DEC DE
    LD A,E
    CP 0
    JR NZ,.loop
    LD A,D
    CP 0
    JR NZ,.loop
    CALL SendCommand
    DB GsClose
    LD A,BarDone
    CALL ShowByte
    RET

; ShowByte: A as the attribute of the four cells at BarCells
ShowByte:
    LD (BarCells),A
    LD (BarCells+1),A
    LD (BarCells+2),A
    LD (BarCells+3),A
    RET

; LoadEffectOpen: unchanged from the disk loader: data 0 (signed), #3E and #D1 with no wait, the bytes, no #D2
LoadEffectOpen:
    CALL WaitGs
    LD A,0
    OUT (GsData),A
    LD A,GsLoadFx
    OUT (GsCommand),A
    LD A,GsOpen
    OUT (GsCommand),A
    LD HL,Buffer
.loop:
    LD A,(HL)
    CALL ShowByte
    OUT (GsData),A
    INC HL
    DEC DE
    LD A,E
    CP 0
    JR NZ,.loop
    LD A,D
    CP 0
    JR NZ,.loop
    LD A,BarDone
    CALL ShowByte
    RET

; SendEffectRest: DE more bytes into the open stream, then #D2 (unchanged: the command is not waited for)
SendEffectRest:
    LD HL,Buffer
.loop:
    LD A,(HL)
    CALL ShowByte
    OUT (GsData),A
    INC HL
    DEC DE
    LD A,E
    CP 0
    JR NZ,.loop
    LD A,D
    CP 0
    JR NZ,.loop
    LD A,GsClose
    OUT (GsCommand),A
    LD A,BarDone
    CALL ShowByte
    RET

; LoadFile: on tape nothing to load: the tick and the return to BASIC (TickReturn)
LoadFile:
    JP TickReturn
; ReturnToBasic: H'L' = $2758 for the ROM, then back to the caller (a USR entry, or BASIC itself for USR 25561)
ReturnToBasic:
    LD HL,BasicHl
    EXX
    RET

; SendCommand: the byte after the CALL to the command port, then the wait until the card has taken it; returns past
; the byte
SendCommand:
    POP HL
    LD A,(HL)
    OUT (GsCommand),A
    INC HL
    PUSH HL
    JP WaitGs

; USR 25516 ("2-music OFF", line 16): only the card's reset; no module is loaded
MusicOff:
    CALL SendCommand
    DB GsReset
    RET

; The rest of the disk loader's LoadFile, never run on tape: two bytes of an instruction cut by the RET above, then
; the TR-DOS set-up up to the function number
    DB $71,$01                  ; dead: the end of LD (IY+1),C
    LD A,8
    LD (TrDos5CFA),A
    INC A
    LD C,A
    LD (TrDos5D06),A
    LD A,$C9
    LD (TrDosRet),A
    LD A,$F4
    LD (TrDosF4),A
    LD HL,FreeMemory
    LD (StkEnd),HL
    LD (ELine),HL
    POP HL
    LD DE,TrDosName
    LDIR
    XOR A
    LD C,$0E

; TickReturn (USR 25561: lines 13 and 16 call it directly for a tick): the progress tick, then ReturnToBasic
TickReturn:
    CALL DrawProgress
    JP ReturnToBasic
    RET                         ; the disk LoadFile's last RET, not reached

; The disk loader's names, kept; on tape only dead operands above point at them
NameScreen:     DB "neart000C"
NameGame:       DB "neart001C"
NameModule1:    DB "neart002C"
NameModule2:    DB "neart003C"
NameModule3:    DB "neart004C"
NameModule4:    DB "neart005C"
NameModule5:    DB "neart006C"
NameFx1:        DB "neart007C"
NameFx2:        DB "neart008C"
NameFx3:        DB "neart009C"
NameFx4:        DB "neart010C"
NameFx5:        DB "neart011C"
NameFx6:        DB "neart012C"
NameFx7:        DB "neart013C"
NameFx8:        DB "neart014C"
NameFx9:        DB "neart015C"
NameFx10:       DB "neart016C"
NameFx11:       DB "neart017C"
NameFx12:       DB "neart018C"
NameFx14a:      DB "neart019C"
NameFx14b:      DB "neart020C"
NameDriver:     DB "neart021C"
NameFx13:       DB "neart023C"

; DrawProgress: the 22 x 3 box at (0, 140) and a tick at x = TickX, which counts up (one per USR entry that calls
; LoadFile, and per USR 25561)
DrawProgress:
    PUSH HL
    PUSH DE
    PUSH BC
    PUSH AF
    PUSH IX
    PUSH IY
    LD H,140
    LD L,0
    LD (Coords),HL
    LD DE,$0101
    LD A,(BarWidth)
    LD C,A
    LD B,0
    CALL DrawLine               ; right 22
    LD DE,$0101
    LD BC,$0300
    CALL DrawLine               ; up 3
    LD A,(BarWidth)
    LD C,A
    LD B,0
    LD DE,$01FF
    CALL DrawLine               ; left 22
    LD BC,$0300
    LD DE,$FF01
    CALL DrawLine               ; down 3
    LD H,140
    LD A,(TickX)
    LD L,A
    INC A
    LD (TickX),A
    LD (Coords),HL
    LD DE,$0101
    LD BC,$0300
    CALL DrawLine               ; the tick
    POP IY
    POP IX
    POP AF
    POP BC
    POP DE
    POP HL
    RET

BarWidth:       DB 22
TickX:          DB 0
