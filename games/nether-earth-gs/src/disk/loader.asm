; loader.asm: neart022, the disk loader (865 bytes at $61A8-$6508), Tron 2002. docs/03-build-and-load.md 3.2,
; docs/09-sound.md 9.2.
;
; Run by "neart GS" (RANDOMIZE USR 25000) with the 48K ROM and TR-DOS. It does everything between the BASIC and the
; game: it clears the screen and loads the loading screen, uploads to the General Sound one ProTracker module
; (neart002-006) and 14 effect samples (neart007-020, neart023), puts the GS driver neart021 in RAM bank 1 at $C000,
; loads the game neart001 to $6590-$FFFF, starts the module and sets the volumes, and jumps to the game's entry
; Start $A600. Every file goes through LoadFile (TR-DOS $3D13 to the file's catalogue address: $8000 for the sound
; files) and is then streamed byte by byte from $8000 to the card's data port. A box with a tick per file
; (DrawProgress) and four attribute cells that take each byte sent as their colour (ShowByte) are the loading display.
;
; Bugs, as they are (live run work/stage1/x3, docs/09-sound.md 9.2):
; - It waits for the card (WaitGs) only before a load, never between two commands. #F4 makes the card restart
;   cold, so the #30 and #D1 written right after it are lost: the module streams into nothing and the disk version
;   has no music. In 5 of the 14 effect loads the #3E is replaced by the #D1 written a few T-states later, and the
;   effect is skipped: the card ends with 9 effects, and the driver's handles no longer match.
; - Every effect is loaded with data 0 (signed samples), but the files are unsigned: each one is stored with its top
;   bit flipped and plays distorted.
; - Effect 11 is loaded from neart019 (its first 401 bytes) where neart017 was meant: neart017 is never read.
;
;   sjasmplus src/disk/loader.asm   ->  build/disk/loader.bin (865 bytes)

  INCLUDE "gs.inc"

Start           EQU $A600       ; the game's entry (src/game: Start)
Driver          EQU $C000       ; the GS driver neart021 in the RAM bank paged at $C000 (src/disk/driver.asm)
Buffer          EQU $8000       ; where every sound file is loaded before it is sent
TrDos           EQU $3D13       ; TR-DOS's command entry (C = the function: $0E loads the file named at $5CDD)
DrawLine        EQU $24BA       ; the 48K ROM's DRAW-LINE: from COORDS, B / C = |dy| / |dx|, D / E = their signs
Coords          EQU $5C7D       ; COORDS: the last plotted point (x, y; y counts up from the bottom)
BarCells        EQU $5861       ; attributes of row 3, columns 1-4: the cells ShowByte colours
BarDone         EQU $56         ; the attribute ShowByte leaves after a file: bright, red paper, yellow ink

; The 48K and TR-DOS system variables LoadFile sets
ErrNr           EQU $5C3A       ; ERR_NR (IY+0); FLAGS is IY+1
ELine           EQU $5C59       ; E_LINE
StkEnd          EQU $5C65       ; STKEND
TrDosVars       EQU $5CC8       ; the TR-DOS variables LoadFile clears ($5CC8 = $83, $5CC9-$5D1A = 0)
TrDosRet        EQU $5CC2       ; a byte TR-DOS calls into: RET
TrDosF4         EQU $5CB6       ; set to $F4
TrDosName       EQU $5CDD       ; the file name (8) and type (1) TR-DOS function $0E looks up
TrDos5CFA       EQU $5CFA       ; set to 8
TrDos5D06       EQU $5D06       ; set to 9
FreeMemory      EQU $5D27       ; E_LINE and STKEND are put here

  OUTPUT "build/disk/loader.bin"
  ORG $61A8

; LoaderStart: the entry (RANDOMIZE USR 25000). Clears the screen (pixels and attributes to 0, border black), loads
; the loading screen neart000 to $4000, then the uploads in the order the GS hands out its handles: module 1,
; effects 1-14.
LoaderStart:
    LD HL,$4000
    LD DE,$4001
    LD BC,$1AFF
    LD A,0
    LD (HL),A
    LDIR                        ; $4000-$5AFF = 0
    OUT ($FE),A                 ; border black
    LD HL,NameScreen
    CALL LoadFile               ; neart000: the loading screen ("GS-512", "TRON 2002")
; The module. Bug: no wait between the three commands: #F4 restarts the card cold and #30 / #D1 are lost
GsStartModule:
    LD A,GsReset
    OUT (GsCommand),A
    LD A,GsLoadModule
    OUT (GsCommand),A
    LD A,GsOpen
    OUT (GsCommand),A
    LD HL,NameModule1
    CALL LoadFile
    CALL SendModuleFile         ; neart002: bytes 0-32767 of the module
    LD HL,NameModule2
    CALL LoadFile
    CALL SendModuleFile         ; neart003
    LD HL,NameModule3
    CALL LoadFile
    CALL SendModuleFile         ; neart004
    LD HL,NameModule4
    CALL LoadFile
    CALL SendModuleFile         ; neart005
    LD HL,NameModule5
    CALL LoadFile
    CALL SendModuleLast         ; neart006: the last 6998 bytes
    LD A,GsClose
    OUT (GsCommand),A
; The effects: LoadEffect with the file's length. The GS numbers them 1-14 in this order (the driver's handles)
GsLoadEffects:
    LD HL,NameFx1
    CALL LoadFile
    LD DE,14798
    CALL LoadEffect             ; effect 1: neart007
    LD HL,NameFx2
    CALL LoadFile
    LD DE,14592
    CALL LoadEffect             ; effect 2: neart008
    LD HL,NameFx3
    CALL LoadFile
    LD DE,23296
    CALL LoadEffect             ; effect 3: neart009
    LD HL,NameFx4
    CALL LoadFile
    LD DE,19456
    CALL LoadEffect             ; effect 4: neart010
    LD HL,NameFx5
    CALL LoadFile
    LD DE,26880
    CALL LoadEffect             ; effect 5: neart011
    LD HL,NameFx6
    CALL LoadFile
    LD DE,8499
    CALL LoadEffect             ; effect 6: neart012
    LD HL,NameFx7
    CALL LoadFile
    LD DE,15427
    CALL LoadEffect             ; effect 7: neart013
    LD HL,NameFx8
    CALL LoadFile
    LD DE,19187
    CALL LoadEffect             ; effect 8: neart014
    LD HL,NameFx9
    CALL LoadFile
    LD DE,9056
    CALL LoadEffect             ; effect 9: neart015
    LD HL,NameFx10
    CALL LoadFile
    LD DE,176
    CALL LoadEffect             ; effect 10: neart016
; Bug: effect 11 is meant to be neart017 (401 bytes); the name given is neart019's, so the first 401 bytes of
; neart019 (the start of effect 14) become effect 11, and neart017 is never read
    LD HL,NameFx14a
    CALL LoadFile
    LD DE,401
    CALL LoadEffect             ; effect 11: neart019's first 401 bytes
    LD HL,NameFx12
    CALL LoadFile
    LD DE,15849
    CALL LoadEffect             ; effect 12: neart018
    LD HL,NameFx13
    CALL LoadFile
    LD DE,12560
    CALL LoadEffect             ; effect 13: neart023
; Effect 14 is 49274 bytes in two files: the stream stays open from the first to the second
    LD HL,NameFx14a
    CALL LoadFile
    LD DE,32768
    CALL LoadEffectOpen         ; effect 14: neart019, the stream left open
    LD HL,NameFx14b
    CALL LoadFile
    LD DE,16506
    CALL SendEffectRest         ; neart020, then #D2
; The driver: neart021 to RAM bank 1 at $C000, paged in for the load only
LoadDriver:
    LD A,$11                    ; 48K ROM, bank 1
    LD BC,Port7FFD
    OUT (C),A
    LD HL,NameDriver
    CALL LoadFile               ; neart021 at its catalogue address $C000: bank 1
    LD A,$10                    ; 48K ROM, bank 0
    LD BC,Port7FFD
    OUT (C),A
; The game, then the music on and the volumes, and play
LoadGame:
    LD HL,NameGame
    CALL LoadFile               ; neart001 to $6590-$FFFF (39536 bytes)
    CALL StartModule
    LD A,$40
    OUT (GsData),A
    LD A,GsFxVolume
    OUT (GsCommand),A           ; effects at 64 of 64. Bug: no wait after #31 or this command
    LD A,$25
    OUT (GsData),A
    LD A,GsModVolume
    OUT (GsCommand),A           ; the module at 37 of 64
    JP Start

; StartModule: waits for the card, then plays the current module (#31, data 0). On the disk the card holds no module
; (see GsStartModule), so it plays nothing. Hood's tape BASIC pokes RET here for "2-music OFF" (src/tape)
StartModule:
    CALL WaitGs
    LD A,0
    OUT (GsData),A
    LD A,GsPlayModule
    OUT (GsCommand),A
    RET

; SendModuleFile: 32768 bytes from Buffer to the card (one of neart002-005). SendModuleLast: neart006's 6998.
; SendBytes: waits once for the card to take the last command, then writes DE bytes from Buffer to GsData with no
; wait per byte (the card's LOAD loop takes them faster than this loop sends), each also shown by ShowByte; ends with
; the cells at BarDone. No command: the stream stays open across the five files
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

; WaitGs: waits until the card has taken the last command (status bit 0 clear)
WaitGs:
    IN A,(GsCommand)
    RRCA
    JR C,WaitGs
    RET

; LoadEffect: one effect of DE bytes from Buffer. Waits for the card, then data 0, #3E, #D1 back to back (bug: the
; #D1 can replace the #3E before the card took it; data 0 means signed samples, but the files are unsigned), the
; bytes, #D2. A = the byte is shown before it is sent
LoadEffect:
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
    LD A,GsClose
    OUT (GsCommand),A
    LD A,BarDone
    CALL ShowByte
    RET

; ShowByte: A as the attribute of the four cells at BarCells (row 3, columns 1-4): during a load they flicker in the
; colours of the bytes sent
ShowByte:
    LD (BarCells),A
    LD (BarCells+1),A
    LD (BarCells+2),A
    LD (BarCells+3),A
    RET

; LoadEffectOpen: LoadEffect without the closing #D2 (the first file of effect 14, neart019)
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

; SendEffectRest: DE more bytes into the open stream, then #D2 (the second file of effect 14, neart020)
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

; LoadFile: loads the file whose 9-byte name and type HL points to, at its catalogue address, through TR-DOS. It
; first sets the system variables a caller outside BASIC must give TR-DOS: $83 and 82 zeros from TrDosVars, ERR_NR
; $FF and FLAGS 0, the TR-DOS variables at $5CFA / $5D06 / $5CC2 / $5CB6, E_LINE and STKEND at FreeMemory; then it
; copies the name to TrDosName and calls function $0E with A = 0 (the catalogue's address). Ends with DrawProgress
LoadFile:
    PUSH HL
    LD HL,TrDosVars
    LD BC,$5200                 ; B = 82 bytes to clear, C = 0
    LD (HL),$83
.clear:
    INC HL
    LD (HL),C
    DJNZ .clear
    LD IY,ErrNr
    LD (IY+0),$FF               ; ERR_NR: no error
    LD (IY+1),C                 ; FLAGS = 0
    LD A,8
    LD (TrDos5CFA),A
    INC A
    LD C,A                      ; C = 9: the name and type
    LD (TrDos5D06),A
    LD A,$C9
    LD (TrDosRet),A             ; RET
    LD A,$F4
    LD (TrDosF4),A
    LD HL,FreeMemory
    LD (StkEnd),HL
    LD (ELine),HL
    POP HL
    LD DE,TrDosName
    LDIR
    XOR A                       ; A = 0: to the address in the catalogue
    LD C,$0E                    ; load a file
    CALL TrDos
    CALL DrawProgress
    RET

; The names (8 characters and the type, as in the catalogue), one per file; neart022 (this loader) is not in it
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
NameFx11:       DB "neart017C"      ; never used: GsLoadEffects names NameFx14a for effect 11
NameFx12:       DB "neart018C"
NameFx14a:      DB "neart019C"
NameFx14b:      DB "neart020C"
NameDriver:     DB "neart021C"
NameFx13:       DB "neart023C"

; DrawProgress: after each file, the loading box: a 22 x 3 rectangle from (0, 140) (ROM coordinates, y up) drawn
; again each time, and a vertical tick 3 high at x = TickX, which then counts up. 23 files: ticks at x = 0-22.
; Keeps every register (TR-DOS's caller's IY included)
DrawProgress:
    PUSH HL
    PUSH DE
    PUSH BC
    PUSH AF
    PUSH IX
    PUSH IY
    LD H,140
    LD L,0
    LD (Coords),HL              ; (0, 140)
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
    LD (Coords),HL              ; (TickX, 140)
    LD DE,$0101
    LD BC,$0300
    CALL DrawLine               ; the tick, up 3
    POP IY
    POP IX
    POP AF
    POP BC
    POP DE
    POP HL
    RET

BarWidth:       DB 22           ; the box's width in pixels
TickX:          DB 0            ; the next tick's x
