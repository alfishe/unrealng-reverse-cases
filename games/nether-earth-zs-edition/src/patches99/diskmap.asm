; --------------------------------------------------------------------------------------------------------------------
; diskmap.asm: LOAD MAP from disk (the disk set), run at $C1FD
;
; The patches block's `$D83E-$D973` (310 bytes). Stage 3 copies it to `$C1FD-$C332` on the disk paths ($626F), over
; the game block's LoadMapRoom (src/game99 mainmenu). The start-up menu's LOAD MAP item reaches it through the
; launcher at `$C10F` (menu128 LoadMapLauncher on 128 K, a JP on one page).
;
; The screen: the disk's catalogue (track 0, sectors 0-7: 128 entries of 16 bytes) is read to LoadBuffer `$F000`;
; every live entry of type N is copied to FileList `$F800` and its 8-character name printed, four names a row, eight
; columns each, from the screen's top left in attribute $01 (blue on black). The chosen name's eight attribute cells
; are $38 (black on white). Q moves the choice one name back, A one name on, SPACE loads it; other keys do nothing.
; The keys are read with the 48 ROM's KEY-SCAN and its key table (`$0205`), three frames (HALT) apart and with no wait
; for a release: a held key repeats every three frames.
;
; Loading: the chosen entry's sector and track (its bytes +14, +15) give the map file's first sector; two sectors (512
; bytes) are read to `$F000`. The first 499 bytes replace the game's level area (`$BDA9-$BF9B`: the scenery and base
; lists); the 13-byte tail patches the game: see DiskApplyLevel. Then JP Start: the start-up menu again, whose START
; plays the map. No N file at all, or a choice past the list whose word +14 is 0, goes back to the menu with nothing
; loaded.
;
; Limits: the cursor goes up to the 96th name (index 95, $C2C4) with no check against the count of files; past the
; list, FileList's bytes are whatever was in the map there before. The print fix at $C263 moves the print address from
; the screen's first third to the second ($41xx to $48xx) only: from the 65th name on (the third third) the names land
; in the wrong pixel lines, while the attributes (and so the highlight) go on in order.
; --------------------------------------------------------------------------------------------------------------------

; LOAD MAP from disk: list the catalogue's N files, Q / A / SPACE to choose and
; load one
;
; No interrupts while it runs (DI; I = $3F, IM 0: the play interrupt is off, I
; points at the ROM); EI comes before the key loop for the HALTs, with IM 0 and
; I = $3F (an interrupt executes the bus's $FF: RST $38, the 48 ROM's handler).
;
; The catalogue: 8 sectors of track 0 to LoadBuffer. Then the print position
; (0,0), attribute $01, setting $11 (single size) for the names.
DiskLoadMap:
  CALL ClearScreen              ; a blank screen
  DI                      ; the play interrupt off
  LD A,$3F                ; I points at the ROM
  LD I,A
  IM 0                    ; IM 0
  LD HL,LoadBuffer             ; the catalogue...
  LD DE,$0000             ; ... track 0, sector 0...
  LD BC,$0800             ; ... 8 sectors (C is not used)
  CALL ReadBlock              ; read
  CALL PrintInline              ; the names' position and colour

; Inline string: position (0,0), attribute $01, setting $11, end
;
; The bytes 1 0 0 (position (0,0)), 2 $01 (blue on black), 4 $11 (single size),
; 0.
DiskListPos:
  DEFB $01,$00,$00,$02,$01,$04,$11,$00 ; AT (0,0), attribute $01, size $11

; Copy each live N entry of the catalogue to FileList and print its name
;
; 128 entries from `$F000` (IX), 16 bytes each (bytes 0-7 the name, 8 the type,
; 9-10 the start, 11-12 the length, 13 the sectors, 14 the first sector, 15 the
; first track). A first byte 0 ends the catalogue; below $20 (1: deleted) the
; entry is skipped; a type other than N too.
;
; A live N entry is copied to the list (DE), then patched in its place to print
; its own name: CALL PrintInline into the 3 bytes before it (ix-3, the end of
; the entry before, already copied), 0 after the name (+8, the type) and RET
; (+9). The CALL at $C25D, whose operand gets the patched entry's address - 3,
; prints the name and returns at the entry's +9 to $C260.
;
; The print address: when it has run into $41xx (the first screen third full
; after 32 names, PrintAddr's high byte from $40 to $41) it is set to $48xx,
; the second third. The jump from the second third to the third is not fixed.
DiskListFiles:
  LD DE,FileList             ; the list
  LD B,$80                ; 128 catalogue entries
  LD IX,LoadBuffer             ; the catalogue
DiskListEntry:
  PUSH BC                 ; the count
  LD BC,$0010             ; an entry's length
  LD A,(IX+$00)           ; the name's first byte
  OR A                    ; 0?
  JR Z,DiskListEnd        ; the catalogue's end
  CP $20                  ; below $20?
  JR C,DiskListNext       ; a deleted file: skip
  LD A,$4E                ; the type
  CP (IX+$08)             ; N?
  JR NZ,DiskListNext      ; no: skip
  PUSH IX                 ; HL = the entry
  POP HL
  PUSH HL                 ; kept
  LDIR                    ; to the list (DE moves on)
  LD (IX-$03),$CD         ; CALL...
  LD (IX-$02),$2D         ; ... PrintInline...
  LD (IX-$01),$D4         ; ... in the 3 bytes before the entry
  LD (IX+$08),$00         ; the name's end: 0 over the type
  LD (IX+$09),$C9         ; then RET
  POP HL                  ; the entry...
  DEC HL                  ; ... - 3: the patched CALL
  DEC HL
  DEC HL
  LD (PrintNameCall+$0001),HL ; into the CALL below
PrintNameCall:
  CALL $0000              ; print the name (the CALL returns at the entry's +9)
  LD BC,$0010             ; the entry's length again
  LD A,(PrintAddr+1)            ; the print address's high byte
  CP $41                  ; $41: past the first third?
  LD A,$48                ; the second third
  JR NZ,DiskListNext      ; no: as it is
  LD (PrintAddr+1),A            ; the print address on in the second third
DiskListNext:
  ADD IX,BC               ; the next entry
  POP BC                  ; the count
  DJNZ DiskListEntry      ; all 128
DiskListEnd:
  LD HL,FileList             ; any file listed?
  AND A                   ; no carry
  SBC HL,DE               ; the list's start - its end
  JP Z,DiskMapDone        ; none: back to the menu
  EI                      ; the HALTs below need interrupts
MapCursor:
  LD B,$00                ; B = the choice (the operand at $C27F: the name's
                          ; index 0-95, 0 the first time)
  INC B                   ; B = the index + 1
  LD HL,$57F8             ; the attribute cell before the first...
  LD DE,$0008             ; ... 8 cells a name
DiskCursorAddr:
  ADD HL,DE               ; the index + 1 times
  DJNZ DiskCursorAddr
  PUSH HL                 ; the choice's first attribute cell, kept
  LD B,$08                ; 8 cells
DiskCursorPaint:
  LD (HL),$38             ; black on white
  INC HL                  ; the next cell
  DJNZ DiskCursorPaint    ; the whole name
DiskMapKeys:
  HALT                    ; three frames a poll
  HALT
  HALT
  CALL KeyScan              ; ROM KEY-SCAN: E = the key, $FF none
  LD A,E                  ; the key
  OR A                    ; a key?
  JP M,DiskMapKeys        ; no: wait on
  ADD A,$05               ; the key table at $0205...
  LD H,$02                ; ...
  LD L,A                  ; ... HL = $0205 + E
  LD A,($C27F)            ; the choice
  LD C,A                  ; C = it
  LD A,(HL)               ; A = the key's character
  POP HL                  ; the choice's attribute cells
  LD B,$08                ; 8 cells
DiskCursorClear:
  LD (HL),$01             ; back to blue on black
  INC HL                  ; the next cell
  DJNZ DiskCursorClear    ; the whole name
  CP $51                  ; Q?
  JR NZ,DiskMapKeyA       ; no
  DEC C                   ; the name before
  JR DiskMapMove          ; to the check
DiskMapKeyA:
  CP $41                  ; A?
  JR NZ,DiskMapKeySpace   ; no
  INC C                   ; the next name
  JR DiskMapMove          ; to the check
DiskMapKeySpace:
  CP $20                  ; SPACE?
  JR Z,DiskMapLoad        ; load the choice
  JR MapCursor            ; another key: the same choice again
DiskMapMove:
  LD A,C                  ; the new choice
  CP $60                  ; 96 names at most (0 - 1 is $FF: refused too)
  JR NC,MapCursor         ; out of range: the old choice
  LD (MapCursor+$0001),A  ; the new choice into the operand
  JR MapCursor            ; highlight it
DiskMapLoad:
  LD A,($C27F)            ; the choice...
  INC A                   ; ... + 1
  LD B,A                  ; times
  LD HL,$F7FE             ; the list's +14, less one entry...
  LD DE,$0010             ; ... 16 bytes an entry
DiskFindEntry:
  ADD HL,DE               ; HL = FileList + 16 x the choice + 14
  DJNZ DiskFindEntry
  LD E,(HL)               ; E = the first sector
  INC HL                  ; (on)
  LD D,(HL)               ; D = the first track
  LD A,E                  ; both 0?
  OR D
  JR Z,DiskMapDone        ; yes (past the list): back to the menu
  LD HL,LoadBuffer             ; the map file...
  LD BC,$0200             ; ... 2 sectors
  CALL ReadBlock              ; read

; The map file into the game: 499 bytes to the level area, the tail into the
; game's operands
;
; The file's bytes $000-$1F2 go to `$BDA9-$BF9B` (SceneryWest on: the scenery
; lists, the base lists, spare). The tail: the four list addresses (+$1F4,
; +$1F6, +$1F8, +$1FA) into BuildMap's LD HL operands; the first factory record
; (+$1FC) into BuildMap's LD IX; the capture points (+$1F3) into the capture
; tick and CountBuildings; the enemy's warbases (+$1FE) into BuildMap and, + 1
; (all the warbases), into the target table and the enemy's build; the player's
; general resource at the start (+$1FF) into NewGameSetup. Then JP Start.
;
; The tail stays in the game until the next LOAD MAP: a later START plays the
; same map. The built-in level's values come back only with a new load of the
; game.
DiskApplyLevel:
  LD HL,LoadBuffer             ; the file
  LD DE,SceneryWest             ; the level area
  LD BC,$01F3             ; 499 bytes
  LDIR                    ; the level's lists
  LD HL,(LoadBuffer+500)           ; +$1F4: the west scenery's address
  LD (SceneryWestList),HL           ; into BuildMap
  LD HL,(LoadBuffer+502)           ; +$1F6: the east scenery's address
  LD (SceneryEastList),HL           ; into BuildMap
  LD HL,(LoadBuffer+504)           ; +$1F8: the west bases' address
  LD (BaseWestList),HL           ; into BuildMap
  LD HL,(LoadBuffer+506)           ; +$1FA: the east bases' address
  LD (BaseEastList),HL           ; into BuildMap
  LD HL,(LoadBuffer+508)           ; +$1FC: the first factory record ($FD70 + 5 x the
                          ; warbases)
  LD (FirstFactory),HL           ; into BuildMap
  LD A,(LoadBuffer+499)            ; +$1F3: the capture points (warbases + factories)
  LD (CapturePoints),A            ; the capture tick
  LD (CountPoints),A            ; CountBuildings
  LD A,(LoadBuffer+510)            ; +$1FE: the enemy's warbases
  LD (EnemyWarbases),A            ; into BuildMap
  INC A                   ; + 1: all the warbases
  LD (TargetWarbases),A            ; the target table
  LD (SpawnWarbases),A            ; the enemy's build
  LD A,(LoadBuffer+511)            ; +$1FF: the player's general resource at the start
  LD (MapGeneral),A            ; into NewGameSetup
; This entry point is used by the routine at DiskListFiles.
DiskMapDone:
  JP Start                ; back to the start-up menu
