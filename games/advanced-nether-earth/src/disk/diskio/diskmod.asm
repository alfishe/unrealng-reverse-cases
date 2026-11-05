; --------------------------------------------------------------------------------------------------------------------
; diskmod.asm: the disk module at $4000: the name prompt, the TR-DOS file load and save
;
; Two entries: LoadEntry ($4000, GameLoad's IX) and SaveEntry ($4033, GameSave's IX). Each sets the file's start
; ($D92B) and length (9941 bytes: $D92B-$FFFF of bank 0, the game's whole state: the staged shots and buildings, the
; robots, the map, the variables, the buildings), prints its screen and reads a name of up to 8 letters, then loads or
; saves the file "name.N" and goes back to the game: a load to LoadReturn ($A590: the game plays on with the loaded
; state, NZ), a save to SaveReturn ($692B), a failed or abandoned load to Restart ($A5EF, the game's menu again).
;
; The disk is driven below TR-DOS's file layer, through the TR-DOS ROM's own instructions: RomCall pushes a ROM
; address and jumps to TR-DOS's RET at $3D2F (the Beta interface pages the ROM in on the fetch from $3D00-$3DFF and
; out again when the CPU leaves it), so OUT (C),A at $2A53 reaches the WD1793's ports, the ROM's sector read at $2090
; and its INI loop at $3FE5 read a sector, its OUTI loop at $3FCA and the status test at $2099 write one, $2740 reads
; the status and $3EF5 waits for the end of a command. ReadSector / WriteSector push their own code's first byte ($01,
; the LD BC opcode) as the ROM's "sector list": the ROM reads it as the list's end mark and returns after one sector.
;
; The file is found and written as TR-DOS keeps a disk: the catalogue in track 0 sectors 0-7 (16-byte entries: name,
; type, start, length, sectors, first sector, first track) and the disk's information in sector 8 ($E1 the first free
; sector, $E2 its track, $E4 the number of files, $E5 the free sectors). Both use $F800-$FFFF of bank 4 as their
; buffer (bank 4's bytes past the module are leftovers of the boot there). There is no checksum: the save writes the
; bytes, the load reads whole sectors into $D92B on (the last sector's tail past $FFFF goes to the ROM, which ignores
; it) and the game's LoadReturn writes $FFFF over NE's checksum word at $5B00, so a damaged file loads as it is
; (recording b).
;
; Ok ($45B1) is 1 in the image (the module is copied fresh at each entry) and goes to 0 on any failure (no disk, a
; sector error abandoned with A, file not found, write protect, catalogue or disk full, EDIT at the prompt); the
; entries pick their exit from it.
; --------------------------------------------------------------------------------------------------------------------

; Load a game: the load screen, the name, the file into $D92B-$FFFF, then back
; to the game
;
; GameLoad's IX. The file's start and length go into File (the name and type
; come from the prompt and the image); PrintLoadScreen, InputName; unless EDIT
; abandoned the prompt (Cancelled), Load. Then the exit by Ok: 1 to LoadReturn
; ($A590), 0 to Restart ($A5EF), with bank 0 paged back and NZ (from the OR A)
; for LoadReturn's JP NewGameSetup.
LoadEntry:
  LD HL,SavedGame             ; the file's start
  LD (FileStart),HL
  LD HL,$26D5             ; 9941 bytes: $D92B-$FFFF
  LD (FileLength),HL
  CALL PrintLoadScreen
  CALL InputName
  LD A,(Cancelled)        ; EDIT at the prompt?
  OR A
  JR NZ,LoadLeave
  CALL Load               ; no: load the file
LoadLeave:
  LD A,(Ok)               ; Ok: 1 a game was loaded, 0 not
  LD DE,Restart             ; the exit if not: the game's restart
  LD HL,LoadReturn             ; the exit if loaded: the game's LoadReturn
  OR A                    ; NZ when loaded (LoadReturn passes it to
                          ; NewGameSetup)
  LD A,$01                ; Ok back to 1 (the module's copy, rewritten at each
                          ; entry anyway)
  LD (Ok),A
  JR NZ,LoadExit
  EX DE,HL                ; not loaded: to Restart
LoadExit:
  LD A,$10                ; bank 0 at $C000 again (the game's)
  CALL SetPage
  JP (HL)                 ; LoadReturn or Restart

; Save the game: the save screen, the name, $D92B-$FFFF to the file "name.N",
; then back to play
;
; GameSave's IX. The same set-up as LoadEntry, PrintSaveScreen, InputName and,
; unless EDIT abandoned the prompt, Save. Both exits are SaveReturn ($692B, the
; play screen again), whatever Ok says.
SaveEntry:
  LD HL,SavedGame             ; the file's start
  LD (FileStart),HL
  LD HL,$26D5             ; 9941 bytes
  LD (FileLength),HL
  CALL PrintSaveScreen
  CALL InputName
  LD A,(Cancelled)        ; EDIT at the prompt?
  OR A
  JR NZ,SaveLeave
  CALL Save               ; no: save the file
SaveLeave:
  LD A,(Ok)               ; Ok (both exits are the same)
  LD DE,SaveReturn
  LD HL,SaveReturn
  OR A
  LD A,$01
  LD (Ok),A
  JR NZ,SaveExit
  EX DE,HL
SaveExit:
  LD A,$10                ; bank 0 at $C000 again
  CALL SetPage
  JP (HL)                 ; SaveReturn

; The load screen's three lines, the name prompt and the rule (rows 17-21)
;
; Used by the routine at LoadEntry.
PrintLoadScreen:
  LD HL,LoadText1
  CALL PrintText
  LD HL,LoadText2
  CALL PrintText
  LD HL,LoadText3
  CALL PrintText
  LD HL,NamePrompt
  CALL PrintText
  LD HL,RuleLine
  CALL PrintText
  RET

; The save screen's three lines, the name prompt and the rule (rows 17-21)
;
; Used by the routine at SaveEntry.
PrintSaveScreen:
  LD HL,SaveText1
  CALL PrintText
  LD HL,SaveText2
  CALL PrintText
  LD HL,SaveText3
  CALL PrintText
  LD HL,NamePrompt
  CALL PrintText
  LD HL,RuleLine
  CALL PrintText
  RET

; the save screen, row 17: column, row, the text, $FF (PrintText's record)
;
; Each text is a PrintText record: the column (0-63, half character cells), the
; row (0-23), the characters, $FF. The module's font draws some signs as
; letters (the texts write "!" for i, "(" and "[" for c, "0" for o).
SaveText1:
  DEFM $00,$11,"Wooow ! Whatta cool opt!on ! It'll make U happy (we think);-).."
  DEFM ".",$FF

; row 18
SaveText2:
  DEFM $00,$12,"Us!n' '!s opt!on U can save yo chance or just da game position "
  DEFM "!",$FF

; row 19
SaveText3:
  DEFM $00,$13,"Don't even try 2 do something 2 catch WG at gluk, 'tis useless "
  DEFM "!",$FF

; the load screen, row 17
LoadText1:
  DEFM $00,$11,"Now U (an load da game U've saved b4 !",$FF

; row 18
LoadText2:
  DEFM $00,$12,"Us!n' '!s fun<t!on U'll get a pea[e of joy...",$FF

; row 19
LoadText3:
  DEFM $00,$13,"Als0 U (an try 2 make s0me d!sk errors :-)...",$FF

; row 20: the prompt; the name prints after it, at column 32 (NameText)
NamePrompt:
  DEFM $00,$14,"Yah, now just enter da filename:",$FF

; row 21: 64 dashes under the prompt
RuleLine:
  DEFM $00,$15,"---------------------------------------------------------------"
  DEFM "-",$FF

; Wait for a new key from the ROM's IM 1 scan: A = LAST_K
;
; Interrupts on; FLAGS bit 5 (a new key) cleared, then two frames at a time
; until the ROM's IM 1 handler sets it; A = LAST_K ($5C08). The game left FLAGS
; as the ROM's key reading wants (GameSave, GameLoad), so LAST_K holds the code
; of the key with CAPS LOCK off: letters in lower case, EDIT 7, DELETE 12,
; ENTER 13.
GetKey:
  EI
  RES 5,(IY+$01)          ; FLAGS: no new key yet
GetKeyWait:
  HALT                    ; two frames, until a new key
  HALT
  BIT 5,(IY+$01)          ; a new key?
  JR Z,GetKeyWait
  LD A,(IY-$32)           ; LAST_K
  RET

; Read the file name: up to 8 characters at column 32 of row 20; ENTER ends,
; DELETE rubs out, EDIT abandons
;
; A loop over GetKey (interrupts off after each key). EDIT (7): NameCancel.
; DELETE (12): NameDelete. ENTER (13): NameEnter, the return. Other codes below
; 32 are ignored. A character: a click on the speaker (border bit 4 for three
; NOPs), the field cleared (ClearRow at $5090, 4 bytes: 8 half cells), the
; character stored at NamePos, NameText printed, NamePos + 1 unless it is 7
; (the 8th character is overwritten by the next one).
InputName:
  CALL GetKey
  DI
  CP $07                  ; EDIT
  JR Z,NameCancel
  CP $0C                  ; DELETE
  JR Z,NameDelete
  CP $0D                  ; ENTER
  JR Z,NameEnter
  CP $20                  ; other control codes: ignored
  JR C,InputName
  PUSH AF
  LD A,$10                ; a click: the speaker bit (and border 0) ...
  OUT ($FE),A
  NOP
  NOP
  NOP
  XOR A                   ; ... and off again
  OUT ($FE),A
  LD HL,$5090             ; the name's field: row 20, columns 32-39
  LD C,$04
  CALL ClearRow
  LD A,(NamePos)          ; the character at NamePos
  LD HL,NameChars
  LD E,A
  LD D,$00
  ADD HL,DE
  POP AF
  LD (HL),A
  LD HL,NameText          ; the name, printed again
  CALL PrintText
  LD A,(NamePos)          ; the next place, up to the 8th
  INC A
  CP $08
  JR Z,InputName
  LD (NamePos),A
  JR InputName
NameCancel:
  XOR A                   ; EDIT: the name blanked, Cancelled = 1, Ok = 0
  LD (NamePos),A
  LD HL,NameChars
  LD BC,$0820             ; 8 spaces
BlankName:
  LD (HL),C               ; the 8 places blank
  INC HL
  DJNZ BlankName
  LD A,$01
  LD (Cancelled),A
  DEC A                   ; A = 0
  LD (Ok),A
  RET

; 1 when EDIT abandoned the name prompt
Cancelled:
  DEFB $00

; NameEnter
;
; Used by the routine at InputName.
NameEnter:
  XOR A                   ; ENTER: the name to File, the field blanked for the
                          ; next time, Cancelled = 0
  LD (NamePos),A
  LD HL,NameChars
  PUSH HL
  LD DE,FileName          ; the 8 characters to the catalogue name
  LD BC,$0008
  LDIR
  POP HL
  LD D,H
  LD E,L
  INC DE
  LD (HL),$20             ; the name buffer blanked (8 spaces)
  LD BC,$0007
  LDIR
  XOR A
  LD (Cancelled),A
  RET
; This entry point is used by the routine at InputName.
NameDelete:
  LD HL,$5090             ; DELETE: the last character rubbed out (the one at
                          ; NamePos, or the one before it if that is blank)
  LD C,$04
  CALL ClearRow
  LD A,$10
  OUT ($FE),A
  NOP
  NOP
  NOP
  XOR A
  OUT ($FE),A
  LD A,(NamePos)
  LD E,A
  LD D,$00
  LD HL,NameChars
  ADD HL,DE
  LD A,$20
  CP (HL)                 ; the character at NamePos blank?
  LD A,(NamePos)
  JR NZ,NameRubOut
  DEC A                   ; then back one place (not before the first)
  CP $FF
  JR NZ,NameBack
  INC A
NameBack:
  LD (NamePos),A          ; the place one back
NameRubOut:
  LD E,A                  ; the character at NamePos blank, the name printed
                          ; again
  LD D,$00
  LD HL,NameChars
  ADD HL,DE
  LD (HL),$20             ; that place blank
  LD HL,NameText
  CALL PrintText
  JP InputName

; the place (0-7) the next character of the name goes to
NamePos:
  DEFB $00

; the name's PrintText record: column 32, row 20 ...
NameText:
  DEFB $20,$14

; ... the 8 characters typed (blanks when empty) ...
NameChars:
  DEFM "        "

; ... and the end mark
NameEnd:
  DEFB $FF

; Clear C bytes of a character row from HL (8 pixel lines)
;
; In: HL = the screen address of the row's top line, C = the width in bytes
; (two half cells a byte). Each of the 8 lines: the first byte 0, an LDIR of C
; - 1 more; NextPixelLine.
ClearRow:
  DEC C
  LD B,$08
ClearRowLine:
  PUSH BC                 ; one pixel line of the row
  PUSH HL
  LD D,H
  LD E,L
  INC E
  LD B,$00
  LD (HL),B
  LDIR
  POP HL
  CALL NextPixelLine
  POP BC
  DJNZ ClearRowLine
  RET

; HL one pixel line down the screen
;
; Used by the routine at ClearRow.
NextPixelLine:
  INC H
  LD A,H
  AND $07
  RET NZ
  LD A,L
  ADD A,$20
  LD L,A
  RET C
  LD A,H
  SUB $08
  LD H,A
  RET

; "Loading...", the file, then "Loading...OK" or "Loading had errors !!!"
;
; Used by the routine at LoadEntry.
Load:
  LD HL,LoadingText
  CALL PrintText
  CALL LoadFile           ; the file
  LD A,(Ok)
  OR A
  JR NZ,LoadOk
  LD HL,$50E0             ; not loaded
  LD C,$10
  CALL ClearRow
  LD HL,LoadFailedText
  CALL PrintText
  RET
LoadOk:
  LD HL,$50E0             ; loaded
  LD C,$10
  CALL ClearRow
  LD HL,LoadingOkText
  CALL PrintText

; SetOk
;
; Used by the routine at Save.
SetOk:
  LD A,$01                ; Ok = 1
  LD (Ok),A
  RET

; Read the catalogue and find "name.N": its 16-byte entry into File
;
; The disk information sector (track 0 sector 8) to CatBuffer, its number of
; files into FindFile's LD B; the catalogue (track 0, sectors 0-7) to
; CatBuffer; each entry's first 9 bytes (the name and the type) against File's.
; Found: the whole entry (start, length, sectors, the first sector and track)
; over File, Ok as it was. Not found: Restore, "File not found !", a key, Ok =
; 0. A read that fails leaves Ok 0 and returns at once.
FindFile:
  LD HL,CatBuffer
  PUSH HL
  LD DE,$0008
  LD B,$01
  CALL ReadSectors        ; the information sector
  LD A,(Ok)
  POP HL
  OR A
  RET Z
  LD A,(CatFiles)            ; the number of files ...
  LD (FindCount+$0001),A  ; ... into the loop's count
  PUSH HL
  LD DE,$0000             ; track 0, sector 0: the catalogue's 8 sectors
  LD B,$08
  CALL ReadSectors
  LD A,(Ok)
  POP HL
  OR A
  RET Z
  LD DE,$0010             ; 16 bytes an entry
FindCount:
  LD B,$00                ; the files (written above)
FindEntry:
  PUSH DE                 ; the next catalogue entry against File
  PUSH HL
  PUSH BC
  LD BC,$0009             ; 9 bytes: name and type
  LD DE,FileName
FindCompare:
  LD A,(DE)               ; a byte of File against the entry's
  CPI
  JR NZ,FindNext
  INC DE
  JP PE,FindCompare       ; the next byte, 9 in all
  POP BC                  ; the 9 bytes alike: found
  POP HL
  POP DE
  LD DE,FileName          ; the entry over File
  LD BC,$0010
  LDIR
  RET
FindNext:
  POP BC                  ; the next entry
  POP HL
  POP DE
  ADD HL,DE
  DJNZ FindEntry
  CALL Restore            ; not found
  LD HL,$50E0
  LD C,$10
  CALL ClearRow
  LD HL,NotFoundText
  CALL PrintText
  CALL WaitKey            ; a key
  XOR A
  LD (Ok),A
  RET

; File's sector count from HL: the length rounded up to whole sectors
;
; In: HL = the length. A = 1 for HL < 256, + 1 for each further 256 started; to
; FileSectors.
SectorCount:
  LD DE,$0100
  XOR A
  INC A
  SBC HL,DE
  JR C,SectorCountDone
  INC A
SectorCountLoop:
  SBC HL,DE               ; one sector more for each 256 started
  JR C,SectorCountDone
  INC A
  JR SectorCountLoop
SectorCountDone:
  LD (FileSectors),A
  RET

; Load the file: the disk, the catalogue, the sectors into the file's start
; (bank 0)
;
; CheckDisk (no disk: a key, the end); FindFile; found: bank 0 at $C000,
; FileSectors sectors from FileTrack / FileSector to FileStart (the start the
; module set, not the one in the catalogue). DiskDone after.
LoadFile:
  DI
  CALL CheckDisk
  JR NZ,LoadDiskThere
  CALL WaitKey
  JR DiskDone
LoadDiskThere:
  CALL FindFile           ; a disk: the file in the catalogue
  LD A,(Ok)
  OR A
  JR Z,DiskDone
  LD A,$10
  CALL SetPage
  LD HL,(FileStart)
  LD DE,(FileSector)
  LD A,(FileSectors)
  LD B,A
  CALL ReadSectors
  JR DiskDone

; DiskDone
;
; Used by the routines at LoadFile and SaveFile.
DiskDone:
  CALL Restore            ; the controller reset, the error marks cleared
  XOR A
  LD (NextSector+$0001),A
  LD (NextWriteSector+$0001),A
  RET

; Is a disk spinning? NZ (and A = the status bits) when it is, else "No disk !"
; and Ok = 0
;
; The head to track 0 (Seek); ReadStatus, then up to 4096 more until the bits
; differ (the index pulse goes by: a disk turns). They do: NZ, A = the status
; AND $42 (bit 6 write protect, bit 1 the index). They do not: Restore, row 22
; cleared, "No disk !", Ok = 0, Z.
CheckDisk:
  PUSH HL
  PUSH DE
  PUSH BC
  LD DE,$0000
  LD A,D
  PUSH AF
  CALL Seek
  POP AF
  SRL A
  LD D,A
  LD BC,$1000             ; up to 4096 reads
  CALL ReadStatus
  LD E,A
CheckDiskLoop:
  CALL ReadStatus         ; the status changed?
  CP E
  JR NZ,DiskThere
  DEC BC
  LD A,B
  OR C
  JR NZ,CheckDiskLoop
  CALL Restore            ; no disk
  POP BC
  POP DE
  POP HL
  LD HL,$50C0
  LD C,$10
  CALL ClearRow
  LD HL,NoDiskText
  CALL PrintText
  XOR A
  LD (Ok),A
  RET

; A = the WD1793's status AND $42 (write protect, index), through TR-DOS's
; $2740
;
; Used by the routine at CheckDisk.
ReadStatus:
  LD A,$01
  LD (TrdosFlag),A
  PUSH DE
  PUSH BC
  LD IX,TrdosStatusSeek
  CALL RomCall
  LD A,(TrdosStatus)
  AND $42
  POP BC
  POP DE
  RET
; This entry point is used by the routine at CheckDisk.
DiskThere:
  POP BC                  ; NZ: a disk
  POP DE
  POP HL
  RET

; Read B sectors from logical track D, sector E (0-15) to HL
;
; Each sector: Seek to D; the sector register E + 1; TR-DOS's READ SECTOR
; through its own code ($2090: the command, the INI loop of 256 bytes, the
; status). TR-DOS adds 1 to TrdosSector when the status shows an error, so
; ReadSectorEnd compares it with E. An error: 14 tries, then Restore, "Load
; error ! (R)etry/(A)bort.", R: CheckDisk and the same sector again (14 more
; tries), A: Ok = 0, the return. After a sector: HL + 256, E + 1, past 15 the
; next track (D + 1, E = 0).
ReadSectors:
  PUSH BC
  PUSH DE
  LD A,D
  CALL Seek
  JR ReadSector           ; the sector

; A to the WD1793's command register ($1F)
;
; Used by the routines at Seek, Restore and WriteSectors.
OutCommand:
  LD C,$1F

; OutPort
;
; Used by the routines at RomCall, Seek, Restore and WriteSectors.
OutPort:
  LD IX,TrdosOutC             ; A to port C (TR-DOS's ports decode the low byte),
                          ; through TR-DOS's OUT (C),A

; RomCall
;
; Used by the routines at ReadStatus and Seek.
RomCall:
  PUSH IX                 ; Run the TR-DOS ROM at IX: IX pushed as the return
                          ; of TR-DOS's RET at $3D2F
  JP TrdosRet
; This entry point is used by the routines at ReadSectors and ReadSectorEnd.
ReadSector:
  LD BC,ReadSectorEnd     ; one sector: ReadSectorEnd and this code's first
                          ; byte pushed under the ROM's read
  PUSH HL                 ; the buffer under the return ...
  PUSH BC                 ; ... ReadSectorEnd
  LD BC,ReadSector
  PUSH BC                 ; the ROM's "sector list": this code's first byte,
                          ; $01, the list's end
  LD A,E                  ; TrdosSector = the sector
  LD (TrdosSector),A
  INC A                   ; the sector register counts from 1
  LD C,$5F
  CALL OutPort
  LD BC,TrdosReadSector             ; the ROM's READ SECTOR ...
  PUSH BC
  LD BC,$017F             ; ... with B = 1 (one try, 256 bytes in its INI loop)
                          ; and C = the data port
  JP TrdosRet

; ReadSectorEnd
ReadSectorEnd:
  DI                      ; TrdosSector still the sector: read well
  LD A,(TrdosSector)
  CP E
  POP HL
  JR Z,NextSector
ReadTries:
  LD A,$0E                ; the tries left (14 at each sector)
  DEC A
  LD (ReadTries+$0001),A
  JR NZ,ReadSector
  LD A,$0E
  LD (ReadTries+$0001),A
  PUSH HL
  CALL Restore
  LD A,$FF
  LD (NextSector+$0001),A
  LD HL,$50E0
  LD C,$10
  CALL ClearRow
  LD HL,LoadErrorText
  CALL PrintText
LoadErrorKey:
  LD BC,$FDFE             ; A: abandon, R: try again
  IN A,(C)
  BIT 0,A
  JR Z,LoadAbort
  LD B,$FB
  IN A,(C)
  BIT 3,A
  JR NZ,LoadErrorKey
  POP HL
  POP DE
  POP BC
  CALL CheckDisk
  JR NZ,LoadRetry
  PUSH BC
  PUSH DE
  PUSH HL
  JR LoadErrorKey
LoadRetry:
  PUSH BC                 ; R: a disk turns: rows 22-23 cleared, the sector
                          ; again
  PUSH DE
  LD A,$01
  LD (Ok),A
  PUSH HL
  LD HL,$50C0
  LD C,$10
  CALL ClearRow
  LD HL,$50E0
  LD C,$10
  CALL ClearRow
  POP HL
  JP ReadSector
LoadAbort:
  POP HL                  ; A: Ok = 0
  POP DE
  POP BC
  XOR A
  LD (Ok),A
  RET
NextSector:
  LD A,$00                ; RetryMark ($FF after an error prompt: one more word
                          ; on the stack to drop)
  INC A
  JR NZ,NextSectorOn
  POP HL
NextSectorOn:
  LD A,$0E                ; the next sector: tries back to 14, HL + 256, E + 1,
                          ; past 15 the next track
  LD (ReadTries+$0001),A
  POP DE
  POP BC
  INC E
  INC H
  LD A,E
  CP $10
  CCF
  ADC A,D
  SUB E
  LD D,A
  RES 4,E
  DEC B
  JP NZ,ReadSectors
  RET

; The head to logical track A: physical track A / 2, side from D bit 0
;
; Track = A / 2, written to the data register ($7F); the system register ($FF)
; $3C (side 0) or $2C (side 1, from D bit 0); SEEK ($18) to the command
; register; TrdosWaitDone.
Seek:
  SRL A
  LD (Track),A
  LD C,$7F
  CALL OutPort
  LD A,$3C
  BIT 0,D
  JR Z,SeekSide
  LD A,$2C
SeekSide:
  LD C,$FF                ; the system register: side and density
  CALL OutPort
  LD A,$18
  CALL OutCommand
  LD IX,TrdosWaitDone
  CALL RomCall
  DI
  RET

; the physical track Seek went to (Restore gives it back to the track register)
Track:
  DEFB $00

; Reset the WD1793 and give the track register back its track
;
; The system register 0 (reset) for 256 loops, then $3C; FORCE INTERRUPT ($D0);
; two frames; Track to the track register ($3F).
Restore:
  XOR A
  PUSH IX
  LD C,$FF
  CALL OutPort
RestoreReset:
  INC A                   ; 256 loops in reset
  JR NZ,RestoreReset
  LD A,$3C
  CALL OutPort
  LD A,$D0
  CALL OutCommand
  EI
  HALT
  HALT
  DI
  LD A,(Track)
  LD C,$3F
  CALL OutPort
  POP IX
  RET

; Wait until a key is held (any half row)
;
; Used by the routines at FindFile, LoadFile, SaveFile and WriteFile.
WaitKey:
  XOR A
  IN A,($FE)
  CPL
  AND $1F
  RET NZ
  JR WaitKey

; File: the catalogue entry, 16 bytes: the name (8, from InputName) ...
FileName:
  DEFM "        "

; ... the type, "N" ...
FileType:
  DEFM "N"

; ... the start (the module's $D92B) ...
FileStart:
  DEFW $D92B

; ... the length (9941) ...
FileLength:
  DEFW $26D5

; ... the sectors ...
FileSectors:
  DEFB $00

; ... the first sector ...
FileSector:
  DEFB $00

; ... and its track (logical)
FileTrack:
  DEFB $00

; 1: all went well (the image's value), 0: no disk, an abandoned error, not
; found, write protect, catalogue or disk full, EDIT
Ok:
  DEFB $01

; Print the record at HL: a column (0-63), a row (0-23), characters to $FF
;
; Keeps every register (HL' too). PrintChar for each character.
PrintText:
  EXX
  PUSH HL
  EXX
  PUSH AF
  PUSH BC
  PUSH DE
  LD A,(HL)
  LD (Column),A
  INC HL
  LD A,(HL)
  LD (Row),A
  INC HL
PrintTextLoop:
  LD A,(HL)
  CP $FF
  JR Z,PrintTextEnd
  PUSH HL
  CALL PrintChar
  POP HL
  INC HL
  JR PrintTextLoop
PrintTextEnd:
  POP DE                  ; the registers back
  POP BC
  POP AF
  EXX
  POP HL
  EXX
  RET

; Print the character A at Column, Row in the module's half-width font; Column
; + 1
;
; The glyph at Font + (A - 32) * 8; past column 63 the next row's start, past
; row 23 row 0. The cell's screen address from RowAddresses + Column / 2; an
; even column takes the glyph's left nibble ($F0), an odd one the right ($0F).
; The glyph's first byte (its top line) is not drawn; the 7 others are ORed
; into the screen, so the place must be clear.
PrintChar:
  LD L,A
  XOR A
  LD H,A
  LD B,A
  LD DE,Font-$0100
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  PUSH HL
  LD HL,Column
  LD A,(HL)
PrintCharPlace:
  LD C,A                  ; the column and row checked
  CP $40
  JR C,PrintCharNext
  LD A,(Row)              ; past column 63: the next row
  INC A
  LD (Row),A
  XOR A
  JR PrintCharPlace
PrintCharNext:
  INC A                   ; Column + 1
  LD (HL),A
  LD A,(Row)
  CP $18
  JR C,PrintCharRow
  XOR A                   ; past row 23: row 0
  LD (Row),A
PrintCharRow:
  LD DE,RowAddresses      ; the row's screen address
  SLA A
  LD H,B
  LD L,A
  ADD HL,DE
  LD A,C
  SRL A                   ; Column / 2: the byte; the carry: the right nibble
  LD C,A
  EX AF,AF'
  LD A,C
  ADD A,(HL)
  LD E,A
  INC HL
  LD D,(HL)
  EX DE,HL
  EX AF,AF'
  POP DE
  JR C,PrintRight
  LD C,$F0                ; the left nibble
  INC DE
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  AND C
  OR (HL)
  LD (HL),A
  RET
PrintRight:
  LD C,$0F                ; the right nibble
  INC DE
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  AND C
  OR (HL)
  LD (HL),A
  RET

; PrintChar's column (0-63)
Column:
  DEFB $00

; PrintChar's row (0-23)
Row:
  DEFB $00

; the screen address of each character row's top line, rows 0-23
RowAddresses:
  DEFW LoadEntry,$4020,$4040,SaveExit,$4080,$40A0,$40C0,$40E0
  DEFW $4800,$4820,$4840,$4860,$4880,$48A0,$48C0,$48E0
  DEFW $5000,$5020,$5040,$5060,$5080,$50A0,$50C0,$50E0

; row 22
NoDiskText:
  DEFM $00,$16,"No disk !",$FF

; the status line, row 23
LoadErrorText:
  DEFM $00,$17,"Load error ! (R(etry/(A)bort.",$FF

; LoadingText
LoadingText:
  DEFM $00,$17,"Loading...",$FF

; LoadingOkText
LoadingOkText:
  DEFM $00,$17,"Loading...OK",$FF

; LoadFailedText
LoadFailedText:
  DEFM $00,$17,"Loading had errors !!!",$FF

; NotFoundText
NotFoundText:
  DEFM $00,$17,"File not found !",$FF

; WriteProtectText
WriteProtectText:
  DEFM $00,$17,"Write protect !",$FF

; SaveErrorText
SaveErrorText:
  DEFM $00,$17,"Save error ! (R)etry/(A)bort.",$FF

; CatFullText
CatFullText:
  DEFM $00,$17,"Cat full !",$FF

; DiskFullText
DiskFullText:
  DEFM $00,$17,"Disk full !",$FF

; SavingText
SavingText:
  DEFM $00,$17,"Saving...",$FF

; SavingOkText
SavingOkText:
  DEFM $00,$17,"Saving...OK",$FF

; SaveFailedText
SaveFailedText:
  DEFM $00,$17,"Saving had errors !!!",$FF

; "Saving...", the file, then "Saving...OK" or "Saving had errors !!!"
;
; Used by the routine at SaveEntry.
Save:
  LD HL,SavingText
  CALL PrintText
  LD HL,(FileLength)      ; the sectors for the length
  CALL SectorCount
  CALL SaveFile           ; the file
  LD A,(Ok)
  OR A
  JR NZ,SaveOk
  LD HL,$50E0
  LD C,$10
  CALL ClearRow
  LD HL,SaveFailedText
  CALL PrintText
  RET
SaveOk:
  LD HL,$50E0             ; saved
  LD C,$10
  CALL ClearRow
  LD HL,SavingOkText
  CALL PrintText
  JP SetOk

; Save the file: the disk, write protect, then WriteFile
;
; CheckDisk (no disk: a key, the end); the status's write protect bit set:
; Restore, "Write protect !", a key, the end; else WaitFrames, WriteFile.
; DiskDone after. An existing file of the same name is not looked for: a second
; save adds a second entry.
SaveFile:
  DI
  LD DE,$0000
  CALL CheckDisk
  JR NZ,SaveDiskThere
  CALL WaitKey
  JP DiskDone
SaveDiskThere:
  BIT 6,A                 ; write protected?
  JR Z,SaveWritable
  CALL Restore
  LD HL,$50E0
  LD C,$10
  CALL ClearRow
  LD HL,WriteProtectText
  CALL PrintText
  CALL WaitKey
  JP DiskDone
SaveWritable:
  CALL WaitFrames         ; 29 frames (the motor up to speed)
  CALL WriteFile
  JP DiskDone

; Write the file's sectors at the disk's first free sector and its catalogue
; entry
;
; The information sector (track 0 sector 8) to CatBuffer. 127 files already:
; "Cat full !". Fewer free sectors than FileSectors: "Disk full !" (both: a
; key, Ok = 0). Else the free count less FileSectors, the first free sector and
; track to File; bank 0, WriteSectors from FileStart; bank 4; the next free
; sector and track (where WriteSectors stopped) and the information sector
; written back; the catalogue sector of the new entry (files - 1) * 16 read,
; File's 16 bytes put in, written back. Each disk step returns at once if it
; failed (Ok 0).
WriteFile:
  LD HL,CatBuffer
  LD DE,$0008
  LD B,$01
  CALL ReadSectors
  LD A,(Ok)
  OR A
  RET Z
  LD A,$01
  LD (Ok),A
  LD HL,CatFiles             ; the number of files ...
  LD A,$7F                ; ... 127: the catalogue is full
  CP (HL)
  JR NZ,CatRoom
  CALL Restore
  LD HL,$50E0
  LD C,$10
  CALL ClearRow
  LD HL,CatFullText
  CALL PrintText
  CALL WaitKey
  XOR A
  LD (Ok),A
  RET
CatRoom:
  INC (HL)                ; one file more
  INC HL
  LD E,(HL)               ; DE = the free sectors
  INC HL
  LD D,(HL)
  LD A,(FileSectors)
  LD L,A
  LD H,$00
  EX DE,HL
  AND A
  SBC HL,DE               ; enough?
  JR NC,DiskRoom
  CALL Restore
  LD HL,$50E0
  LD C,$10
  CALL ClearRow
  LD HL,DiskFullText
  CALL PrintText
  CALL WaitKey
  XOR A
  LD (Ok),A
  RET
DiskRoom:
  LD (CatFreeSectors),HL           ; the free count less the file's
  LD DE,(CatFreeSector)           ; the file goes to the first free sector
  LD (FileSector),DE
  LD A,(FileSectors)
  LD B,A
  LD HL,(FileStart)
  LD A,$10                ; bank 0: the game's state
  CALL SetPage
  CALL WriteSectors
  LD A,$14                ; bank 4: CatBuffer
  CALL SetPage
  LD A,(Ok)
  OR A
  RET Z
  LD A,$01
  LD (Ok),A
  LD (CatFreeSector),DE           ; the next free sector
  LD HL,CatBuffer             ; the information sector back
  LD DE,$0008
  LD B,$01
  CALL WriteSectors
  LD A,(Ok)
  OR A
  RET Z
  LD A,$01
  LD (Ok),A
  LD HL,CatFiles             ; the new entry's place: (files - 1) * 16 ...
  LD L,(HL)
  DEC L
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  XOR A
  LD DE,$0100             ; ... its catalogue sector (A) and the offset in it
                          ; (HL)
EntryPlaceLoop:
  SBC HL,DE               ; the entry offset into a sector and an offset
  JR C,EntryPlace
  INC A
  JR EntryPlaceLoop
EntryPlace:
  ADD HL,DE
  LD D,$00
  LD E,A
  PUSH DE
  PUSH HL
  LD HL,CatBuffer             ; that sector read
  LD B,$01
  CALL ReadSectors
  LD A,(Ok)
  OR A
  POP HL
  POP DE
  RET Z
  LD A,$01
  LD (Ok),A
  PUSH DE
  PUSH HL
  LD HL,CatBuffer
  POP DE
  ADD HL,DE
  LD DE,FileName          ; File into it
  EX DE,HL
  LD BC,$0010
  LDIR
  LD HL,CatBuffer             ; and written back
  POP DE
  LD B,$01
  CALL WriteSectors
  LD A,(Ok)
  OR A
  RET Z
  LD A,$01
  LD (Ok),A
  RET

; Write B sectors from HL to logical track D, sector E (0-15)
;
; As ReadSectors, with TR-DOS's OUTI loop ($3FCA) and status test ($2099) under
; WRITE SECTOR ($A0): 14 tries a sector, then "Save error ! (R)etry/(A)bort.",
; R: CheckDisk and again, A: Ok = 0.
WriteSectors:
  PUSH BC
  PUSH DE
  LD A,D
  CALL Seek
; This entry point is used by the routine at WriteSectorEnd.
WriteSector:
  LD BC,WriteSectorEnd    ; one sector: WriteSectorEnd and this code's first
                          ; byte pushed under the ROM's write
  PUSH HL
  PUSH BC
  LD BC,WriteSector
  PUSH BC
  LD A,E
  LD (TrdosSector),A
  INC A
  LD BC,$015F             ; the sector register, B = 1 for the ROM's one try
  CALL OutPort
  PUSH BC
  LD BC,TrdosSectorStatus             ; the ROM's status test ...
  PUSH BC
  LD BC,TrdosWriteLoop             ; ... after its OUTI loop ...
  PUSH BC
  LD A,$A0                ; ... after WRITE SECTOR
  CALL OutCommand
  LD BC,$017F
  JP TrdosRet

; WriteSectorEnd
WriteSectorEnd:
  DI                      ; TrdosSector still the sector: written well
  LD A,(TrdosSector)
  CP E
  POP HL
  JR Z,NextWriteSector
WriteTries:
  LD A,$0E                ; the tries left (14 a sector)
  DEC A
  LD (WriteTries+$0001),A
  JR NZ,WriteSector
  LD A,$0E
  LD (WriteTries+$0001),A
  PUSH HL
  CALL Restore
  LD A,$FF
  LD (NextWriteSector+$0001),A
  LD HL,$50E0
  LD C,$10
  CALL ClearRow
  LD HL,SaveErrorText
  CALL PrintText
SaveErrorKey:
  LD BC,$FDFE             ; A: abandon, R: try again
  IN A,(C)
  BIT 0,A
  JR Z,SaveAbort
  LD B,$FB
  IN A,(C)
  BIT 3,A
  JR NZ,SaveErrorKey
  POP HL
  POP DE
  POP BC
  CALL CheckDisk
  JR NZ,SaveRetry
  PUSH BC
  PUSH DE
  PUSH HL
  JR SaveErrorKey
SaveRetry:
  PUSH BC                 ; R: rows 22-23 cleared, the sector again
  PUSH DE
  LD A,$01
  LD (Ok),A
  PUSH HL
  LD HL,$50C0
  LD C,$10
  CALL ClearRow
  LD HL,$50E0
  LD C,$10
  CALL ClearRow
  JP WriteSector
SaveAbort:
  POP HL                  ; A: Ok = 0
  POP DE
  POP BC
  XOR A
  LD (Ok),A
  RET
NextWriteSector:
  LD A,$00                ; RetryMark, the next sector as in ReadSectors
  INC A
  JR NZ,NextWriteSectorOn
  POP HL
NextWriteSectorOn:
  POP DE
  POP BC
  INC E
  INC H
  LD A,E
  CP $10
  CCF
  ADC A,D
  SUB E
  LD D,A
  RES 4,E
  DEC B
  JP NZ,WriteSectors
  RET

; 29 frames with interrupts on
;
; Used by the routine at SaveFile.
WaitFrames:
  PUSH BC
  LD B,$1D
WaitFramesLoop:
  EI
  HALT
  DJNZ WaitFramesLoop
  DI
  POP BC
  RET

; A to port $7FFD (keeps BC)
;
; Used by the routines at LoadEntry, SaveEntry, LoadFile and WriteFile.
SetPage:
  PUSH BC
  LD BC,$7FFD
  OUT (C),A
  POP BC
  RET

; The module's font: codes 32-127, 8 bytes each, the glyph in both nibbles
; (PrintChar masks one)
Font:
  INCBIN "res/diskmod/font.bin",$0000,768
