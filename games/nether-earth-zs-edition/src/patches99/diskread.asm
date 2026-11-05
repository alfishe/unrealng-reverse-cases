; --------------------------------------------------------------------------------------------------------------------
; diskread.asm: The TR-DOS sector reader (the disk set), run at $A598
;
; The patches block's `$D800-$D83D` (62 bytes). Stage 3 copies it to `$A598-$A5D5` on the disk paths ($6264), over the
; room the game block leaves there (src/game99 difficulty: PieceRoomA59C). LOAD MAP (DiskLoadMap) and the one-page
; text reader (LoadText) call it; on 128 K the texts come from page 3 instead.
;
; Every step is a routine of the TR-DOS ROM, reached by DiskRomCall: PUSH IX; JP $3D2F. The TR-DOS ROM pages itself in
; when the CPU fetches from `$3D00-$3DFF`; at `$3D2F` it holds a RET, which takes the pushed IX: the routine runs with
; the TR-DOS ROM in, and its own RET leaves through the same window back to the 48 ROM and to the caller. The routines
; are the same in TR-DOS 5.03 and 5.04T.
; --------------------------------------------------------------------------------------------------------------------

; Read B sectors from logical track D, sector E (0-15) to HL, through the
; TR-DOS ROM
;
; In: HL the destination, D the logical track (the physical track D / 2, the
; side D bit 0: odd tracks are side 1), E the first sector, B the count; C is
; not used. A RESTORE first (the head to track 0), then a seek at the start and
; at each new logical track, and per sector a read of 256 bytes to HL, HL one
; page on each. After sector 15, sector 0 of the next logical track. No error
; check: what the ROM routines do on a bad sector is all.
;
; Out: HL past the data, D, E past the last sector. A, BC, IX lost.
DiskRead:
  LD IX,TrDosRestore             ; TR-DOS $2F65: the RESTORE command
  CALL DiskRomCall        ; (the 4 bytes up to here are also in the game block:
                          ; DiskReadLeftover)
DiskSeekTrack:
  PUSH BC                 ; keep the count and the position
  PUSH DE
  LD A,D                  ; the logical track
  OR A                    ; no carry in
  RRA                     ; the side into the carry...
  LD C,A                  ; ... C = the physical track
  JR NC,DiskSide0         ; even: side 0
  LD A,$2C                ; odd: the system register for side 1 ($2C: the drive
                          ; A, side 1, no reset)
  JR DiskSeek
DiskSide0:
  LD A,$3C                ; the system register for side 0 ($3C)
DiskSeek:
  LD IX,TrDosSeek             ; TR-DOS $2F4D: A to the system register, seek track
                          ; C
  CALL DiskRomCall
  POP DE                  ; the position and the count back
  POP BC
DiskReadSector:
  PUSH BC                 ; keep them over the read
  PUSH DE
  LD IX,TrDosReadSector             ; TR-DOS $2F1B: sector E + 1, 256 bytes to HL
  CALL DiskRomCall
  POP DE                  ; the position back
  INC H                   ; the next 256 bytes
  INC E                   ; the next sector
  BIT 4,E                 ; past sector 15?
  JR Z,DiskSameTrack      ; no: the same track, no seek
  LD E,$00                ; yes: sector 0...
  INC D                   ; ... of the next logical track
  POP BC                  ; the count
  DJNZ DiskSeekTrack      ; the next sector, with a seek first
  RET                     ; done
DiskSameTrack:
  POP BC                  ; the count
  DJNZ DiskReadSector     ; the next sector on this track
  RET                     ; done

; Run the TR-DOS ROM routine at IX: PUSH IX; JP $3D2F (the RET there takes IX)
;
; The TR-DOS ROM is paged in by the fetch at `$3D2F` and stays in while the
; routine runs; its RET returns here through the same window, with the 48 ROM
; back. The ROM routines keep BC, DE and HL as they leave them.
DiskRomCall:
  PUSH IX                 ; the routine's address under the caller's return
  JP TrDosEntry                ; into the TR-DOS ROM: its RET at $3D2F jumps to IX
