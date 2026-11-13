; --------------------------------------------------------------------------------------------------------------------
; objects.asm: The two object tables over the entry code
;
; Table A: six 24-byte records from $7B8F (update $A2F7, end mark $7C1F); table B: four 23-byte records from $7C20
; (update $9EAF, end mark $7C7C). A record with +0 = 0 is free. Both are cleared at every new game, as are the entry
; code's bytes they lie on.
;
; A section's map entry list (its address in SectionEntries, set from the section table) is sorted by row.
; FindFirstMapEntry sets ScanStart to the first entry at or below the view's top row whenever the view is built;
; ScanMapObjects goes through the list from there every pass and spawns ($9C97) the entries that come into the view or
; whose trigger boxes fire ($A69F).
;
; A section's map carries a list of 4-byte entries, each followed by 0-3 trigger boxes of 4 bytes (scanned by $8B75):
; +0 the kind (bit 7 set while the object lives), +1 the cell row in the section, +2 the column (bits 0-4) with bit 5
; = 4 pixels right and bit 6 = 3 pixels down, +3 the parameters (bits 0-1 the number of boxes, bits 2-5 the behaviour
; or the patrol length, bit 6 one-shot). A box is +0 the x in pixels, +1 the cell row, +2 the size (high nibble rows -
; 1, low nibble columns - 1), +3 who sets it off (bit 0 Rick, 1 the bullet, 2 the detonator's blast, 3 the punch box,
; 4 an enemy, 5 a trap; bit 6 fires on every pass, bit 7 the latch of a box that fired and is still occupied).
;
; A map entry whose kind is below $74 becomes a trap or a pickup in the 24-byte records at $7B8F (SpawnMapObject,
; UpdateTrap); $78 and $7C start and stop the countdown bonus; any other kind from $74 up becomes an enemy in the
; 23-byte records at $7C20 (UpdateEnemy). Both lists end with a $FF byte; a record whose +0 is 0 is free. The y of
; every record is in pixels from the top of the view (16 bits), so the scroll ($78A5, $7905) shifts them all through
; ShiftObjects.
; --------------------------------------------------------------------------------------------------------------------

  ORG $83B8

; Clear $7B8F-$7C7C and put the end marks of the two tables
;
; $7B8F-$7C7C = 0 (238 bytes), $FF at $7C1F (the end of table A) and at $7C7C
; (the end of table B).
;
; Evidence: 12 runs in 11 builds, from StartGame.
;
; Witness: L1 56 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l1-00000-poke, rzx-l5-full, sec-l1-s8, c1, c48,
; load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
ClearObjectTables:
  LD HL,Entry
  LD DE,Entry+$0001
  LD BC,$00ED
  LD (HL),$00
  LDIR
  XOR A
  DEC A
  LD (SetupIm2+$0005),A
  LD (ObjectTableBEnd),A
  RET

  ORG $865D

; Update the objects of both tables, then Rick and the records $9BB4 and $9BBD
;
; With $8A24 set (level 5's Fat Guy part) CALL $C209 (LevelHookB: level 5's own
; code, JP $F8D0) instead of the tables. Else table A: $A2F7 for every used
; record; table B: $9EAF. Then, unless SectionBusy is set: $95ED for Rick
; ($9BAB), $91B0 for $9BB4 when used, $91EB for $9BBD when used; $A7F0 set: it
; and $9BB4's +0 cleared; $9BA9 set: $9163 (the TimeBonus countdown).
;
; Evidence: called by MainLoopPause every pass and by $8A6D; the hook $C209 in
; rzx-l5-22000-poke (stage 1).
;
; Witness: L1 119413 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full,
; sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
UpdateObjects:
  LD A,(LevelHookOn)
  AND A
  JP Z,UpdateTableA
  CALL LevelHookB
  JP UpdateRickStep
UpdateTableA:
  LD IX,Entry             ; table A
UpdateTableALoop:
  LD A,(IX+$00)           ; a record: 0 free, $FF the end
  AND A
  JP Z,UpdateTableANext
  CP $FF
  JP Z,UpdateTableB
  CALL UpdateTrap
UpdateTableANext:
  LD DE,$0018             ; + 24
  ADD IX,DE
  JP UpdateTableALoop
UpdateTableB:
  LD IX,SetupIm2+$0006    ; table B
UpdateTableBLoop:
  LD A,(IX+$00)           ; a record: 0 free, $FF the end
  AND A
  JP Z,UpdateTableBNext
  CP $FF
  JP Z,UpdateRickStep
  CALL UpdateEnemy
UpdateTableBNext:
  LD DE,$0017             ; + 23
  ADD IX,DE
  JP UpdateTableBLoop
UpdateRickStep:
  LD A,(SectionBusy)      ; Rick and the records after his
  AND A
  RET NZ
  LD IX,RickRecord
  CALL UpdateRick
  LD A,(BulletRecord)
  AND A
  JP Z,UpdateThird
  LD IX,BulletRecord
  CALL MoveBullet
UpdateThird:
  LD A,(DetonatorRecord)  ; the record $9BBD
  AND A
  JP Z,ClearSecond
  LD IX,DetonatorRecord
  CALL UpdateDetonator
ClearSecond:
  LD A,(BulletSpent)      ; $A7F0 set: $9BB4 freed
  AND A
  JP Z,UpdateTimeBonus
  XOR A
  LD (BulletSpent),A
  LD (BulletRecord),A
UpdateTimeBonus:
  LD A,(BonusRunning)     ; $9BA9 set: the TimeBonus countdown
  AND A
  RET Z
  CALL CountBonus
  RET

; $FF while a section is set up: UpdateObjects leaves Rick alone
;
; $FF and 0 written by the section setup ($8AF1 area, $8B01); read by
; UpdateObjects.
SectionBusy:
  DEFB $00

  ORG $8B3E

; The section's map entry list (0: none)
;
; Set by SetupSection ($8AD5) from the section table's +6/+7; read by
; FindFirstMapEntry.
SectionEntries:
  DEFW $0000

; The first map entry at or below the view's top row (0: none)
;
; Set by FindFirstMapEntry after every BuildView; read by ScanMapObjects each
; pass.
ScanStart:
  DEFW $0000

; Spawn the map entries that come into the view or whose trigger boxes fire
;
; Returns at once while LevelHookOn is set or the list is empty. From
; ScanStart, entry by entry (4 bytes and +3 bits 0-1 boxes of 4 bytes after
; it), until the 0 end or an entry whose row is ViewTop + 40 or more: an entry
; already alive (+0 bit 7) is skipped. With +2 bit 7 set the entry spawns when
; its row is in the view's first 8 rows or above the top or 32 rows or more
; below it (the rows the scroll brings in; every row while SpawnWholeView is
; set); the rows between are skipped. With +2 bit 7 clear its trigger boxes are
; tested ($A69F with BC = 0) and it spawns when one fires. A spawn is $9C97
; with IX at the entry.
;
; Called each pass by the main loop ($7D75, 50 161) and by SetupSection ($8AFE,
; 95). Witness: 50 256 runs in 65 builds; 1982 spawns ($8B96).
;
; Witness: L1 119401 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full,
; sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
ScanMapObjects:
  LD A,(LevelHookOn)
  AND A
  RET NZ
  LD HL,(ScanStart)
  LD A,H
  OR L
  RET Z
  LD A,(ViewTopRow)
  ADD A,$28
  LD C,A
  LD DE,$0004

; ScanMapObjects: the next entry; stop at the end or below the view
;
; HL: an entry's +0, C: ViewTop + 40, DE: 4. An entry alive (+0 bit 7) goes to
; ScanSkipEntry, else ScanDeadEntry.
;
; Evidence: 447 209 runs in 65 builds.
;
; Witness: L1 1036481 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full,
; sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
ScanEntry:
  LD A,(HL)
  AND A
  RET Z
  LD B,A
  INC HL
  LD A,(HL)
  CP C
  RET NC
  BIT 7,B
  JP Z,ScanDeadEntry
  INC HL

; ScanMapObjects: from +2 on to +3
;
; Evidence: 267 846 runs in 61 builds.
;
; Witness: L1 607301 (cheats, end-congrats, long-l4, rzx-l1-00000-poke,
; rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke,
; rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke,
; rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke,
; rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke,
; rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke,
; rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke,
; rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke,
; rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke,
; rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke,
; rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke,
; rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke,
; rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke,
; rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2-load-l5,
; sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s
; x5, sec-l5-s3, sec-l5-s5).
ScanSkipEntry:
  INC HL

; ScanMapObjects: past +3 and the entry's boxes (+3 bits 0-1 of them)
;
; Evidence: 397 475 runs in 65 builds.
;
; Witness: L1 918124 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1,
; c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
ScanSkipBoxes:
  LD A,(HL)
  INC HL
  AND $03
  JP Z,ScanEntry
ScanSkipBoxLoop:
  ADD HL,DE
  DEC A
  JP NZ,ScanSkipBoxLoop
  JP ScanEntry

; ScanMapObjects: an entry not alive; HL on to +2
;
; Evidence: 174 646 runs in 65 builds.
;
; Witness: L1 403591 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1,
; c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
ScanDeadEntry:
  INC HL

; ScanMapObjects: +2 bit 7 set: spawn at the view's edge rows; clear: test the
; trigger boxes
;
; Evidence: 174 647 runs in 65 builds.
;
; Witness: L1 403593 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1,
; c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
ScanSpawnRule:
  BIT 7,(HL)
  JP Z,ScanTriggerTest
  LD A,(SpawnWholeView)
  AND A
  JP NZ,ScanSpawnHere
  LD A,(ViewTopRow)
  LD B,A

; ScanMapObjects: the entry's row less the view's top: 0-7 or 32 up spawn, 8-31
; skip
;
; Evidence: 46 215 runs in 54 builds.
;
; Witness: L1 95376 (cheats, end-congrats, long-l4, rzx-l1-02000-poke,
; rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, load-l4, load-l5,
; sec-l2-s7, sec-l2-s12, sec-l4-s2, sec-l4-s11, sec-l5-s3, sec-l5-s5).
ScanEdgeRows:
  DEC HL
  LD A,(HL)
  INC HL
  SUB B
  CP $08
  JP C,ScanSpawnHere
  CP $20
  JP C,ScanSkipEntry

; ScanMapObjects: HL back to the entry's +0
;
; Evidence: 1540 runs in 57 builds.
;
; Witness: L1 3625 (long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke,
; rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke,
; rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke,
; rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke,
; rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke,
; rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke,
; rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke,
; rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, c48, load-l2-load-l5,
; sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s
; x5, sec-l5-s3, sec-l5-s5).
ScanSpawnHere:
  DEC HL
  DEC HL
  PUSH HL

; ScanMapObjects: spawn the entry ($9C97, IX = the entry)
;
; Evidence: 1982 runs in 59 builds (from $8B95 and $8BBD).
;
; Witness: L1 4603 (long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke,
; rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke,
; rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke,
; rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke,
; rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke,
; rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke,
; rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke,
; rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1,
; c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
ScanSpawn:
  PUSH HL
  POP IX
  CALL SpawnFromMap
  POP HL

; ScanMapObjects: HL to +3, C and DE again, on past the boxes
;
; Evidence: 129 629 runs in 64 builds.
;
; Witness: L1 310823 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke,
; rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke,
; rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke,
; rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke,
; rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke,
; rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke,
; rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2-load-l5,
; sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9,
; sec-l4-s x5, sec-l5-s3, sec-l5-s5).
ScanNextEntry:
  INC HL
  INC HL
  INC HL
  LD A,(ViewTopRow)
  ADD A,$28
  LD C,A
  LD DE,$0004
  JP ScanSkipBoxes

; ScanMapObjects: test the entry's trigger boxes ($A69F, BC = 0); C: spawn
;
; Evidence: 128 087 runs in 62 builds; a fire 442 times ($8BBC).
;
; Witness: L1 307194 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke,
; rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke,
; rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke,
; rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke,
; rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke,
; rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke,
; rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke,
; rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke,
; rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke,
; rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke,
; rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l3-load-l5,
; sec-l2-s10-sec-l2-s12, sec-l3-s3, sec-l3-s4, sec-l3-s7-sec-l3-s9, sec-l4-s
; x5, sec-l5-s3, sec-l5-s5).
ScanTriggerTest:
  DEC HL
  DEC HL
  PUSH HL
  PUSH HL
  POP IX
  LD BC,$0000
  CALL TestTriggerBoxes
  POP HL
  JP NC,ScanNextEntry
  PUSH HL
  JP ScanSpawn

; $FF while SetupSection spawns: every entry in the 40 rows, not only the edge
; rows
;
; Set to $FF at $8AEB and 0 at $8B02; read by ScanMapObjects ($8B78).
SpawnWholeView:
  DEFB $00

; ScanStart = the first entry of SectionEntries whose row is ViewTop or more
;
; Skips an entry and its boxes while its row (+1) is above the view's top
; $88CF. An empty list (0) leaves ScanStart 0. Called at the end of BuildView
; ($894A).
;
; Evidence: 269 runs in 62 builds.
;
; Witness: L1 643 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke,
; rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke,
; rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke,
; rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke,
; rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke,
; rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke,
; rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke,
; rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, sec-l1-s8, c1, c48,
; load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
FindFirstMapEntry:
  LD HL,(SectionEntries)
  LD (ScanStart),HL
  LD A,H
  OR L
  RET Z
  LD BC,$0002
  LD DE,$0004
FindEntryLoop:
  LD A,(HL)               ; the 0 end leaves ScanStart at the list's start
  AND A
  RET Z
  INC HL
  LD A,(ViewTopRow)
  CP (HL)
  JP Z,FindEntryFound
  JP C,FindEntryFound
  ADD HL,BC
  LD A,(HL)
  INC HL
  AND $03
  JP Z,FindEntryLoop
FindSkipBoxLoop:
  ADD HL,DE               ; 4 bytes a box
  DEC A
  JP NZ,FindSkipBoxLoop
  JP FindEntryLoop
FindEntryFound:
  DEC HL
  LD (ScanStart),HL
  RET

  ORG $917D

; jump through KindHandlers by A AND 15
;
; A AND 15 indexes KindHandlers; the word is written into DispatchJump's
; operand and jumped to: 0 to $0000 (a reset), 1 to $A2F7 (the trap and pickup
; update), 2-14 to NoHandler (15 to $3AC9, the bytes after the table). Nothing
; calls or jumps here (no word $917D in the image) and no recording ran it: a
; dispatcher from an earlier design, kept in the code. Kept as bytes for the
; reason given at BonusRunOut.
;
; Witness: L1 0 ().
DispatchByKind:
  AND $0F                 ; AND $0F
  ADD A,A
  LD L,A
  LD H,$00
  LD BC,KindHandlers      ; LD BC,KindHandlers
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (DispatchJump+$0001),DE ; LD (DispatchJump+1),DE
DispatchJump:
  JP $0000                ; JP nn: nn = the handler

; DispatchByKind's handlers: $0000, $A2F7, then NoHandler 13 times (kind 15
; would read $3AC9 past the end)
;
; Read only by DispatchByKind, which no recording ran.
KindHandlers:
  DEFW $0000
  DEFW UpdateTrap
  DEFW NoHandler
  DEFW NoHandler
  DEFW NoHandler
  DEFW NoHandler
  DEFW NoHandler
  DEFW NoHandler
  DEFW NoHandler
  DEFW NoHandler
  DEFW NoHandler
  DEFW NoHandler
  DEFW NoHandler
  DEFW NoHandler
  DEFW NoHandler

; RET the handler of kinds 2-14 in KindHandlers
;
; Not executed in any recording.
;
; Witness: L1 0 ().
NoHandler:
  RET

  ORG $9BC7

; Find a free 24-byte record in the $7B8F list
;
; Out: Z set and HL = the free record (+0 = 0); NZ when the list's $FF end
; comes first. Called by $9D6C (a map entry becomes a trap or a pickup). Ran
; 1471 times in 59 builds.
;
; Witness: L1 3254 (long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke,
; rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke,
; rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke,
; rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke,
; rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke,
; rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke,
; rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke,
; rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1,
; c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
FindFreeTrapRecord:
  LD HL,Entry
  LD DE,$0018
FindFreeTrapLoop:
  LD A,(HL)
  AND A
  RET Z
  ADD HL,DE
  CP $FF
  JP NZ,FindFreeTrapLoop
  XOR A
  INC A
  RET

; Find a free 23-byte record in the $7C20 list
;
; As FindFreeTrapRecord for the enemies' list. Called by $9CDF. Ran 474 times
; in 49 builds.
;
; Witness: L1 1272 (rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke,
; rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke,
; rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke,
; rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke,
; rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-full, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s5, sec-l3-s8, sec-l4-s2, sec-l4-s6,
; sec-l4-s11, sec-l4-s12, sec-l5-s3, sec-l5-s5).
FindFreeEnemyRecord:
  LD HL,SetupIm2+$0006
  LD DE,$0017
FindFreeEnemyLoop:
  LD A,(HL)
  AND A
  RET Z
  ADD HL,DE
  CP $FF
  JP NZ,FindFreeEnemyLoop
  XOR A
  INC A
  RET

; Free every live record of both lists, and end the bullet and the detonator
;
; Calls $9C57 (free the record, re-arm its map entry) for every record whose +0
; is neither 0 nor $FF, in $7B8F (24 bytes) then $7C20 (23 bytes); then
; BulletRecord +0 = DetonatorRecord +0 = 0. Called by the level start ($7CD5)
; and the section setup ($8AE3). Ran 103 times in 44 builds.
;
; Witness: L1 279 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-04000-poke, rzx-l2-08000-poke,
; rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke,
; rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke,
; rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke,
; rzx-l4-16000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-06000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke,
; rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
FreeAllObjects:
  LD IX,Entry
  LD DE,$0018
FreeTrapsLoop:
  LD A,(IX+$00)
  AND A
  JP Z,FreeTrapsNext
  CP $FF
  JP Z,FreeEnemies
  CALL FreeObject
FreeTrapsNext:
  ADD IX,DE
  JP FreeTrapsLoop
FreeEnemies:
  LD IX,SetupIm2+$0006
  LD DE,$0017
FreeEnemiesLoop:
  LD A,(IX+$00)
  AND A
  JP Z,FreeEnemiesNext
  CP $FF
  JP Z,FreeWeapons
  CALL FreeObject
FreeEnemiesNext:
  ADD IX,DE
  JP FreeEnemiesLoop
FreeWeapons:
  XOR A
  LD (DetonatorRecord),A
  LD (BulletRecord),A
  RET

; clear bit 7 of the entries of one section's object list (an old form)
;
; IX = the section table ($C202's word): HL = the word at IX+6/IX+7 read
; little-endian and absolute, then for each 4-byte entry RES 7 of +0 and skip
; +3 AND 3 boxes of 4 bytes; returns with IX on the next section's 8-byte
; entry. The live code ($8AD0) reads that word big-endian as an offset from the
; section table, and the loop's end test (JP Z after LD A,(HL)) uses stale
; flags, so it would stop after the first entry. Nothing calls it (no word
; $9C29 in the image); not executed in any recording. Kept as bytes for the
; reason given at BonusRunOut.
;
; Witness: L1 0 ().
RearmSectionList:
  LD BC,$0008             ; LD BC,$0008
  LD DE,$0004
  LD IX,(LevelHeader+2)           ; LD IX,($C202): the section table
  LD L,(IX+$06)
  LD H,(IX+$07)
RearmEntryLoop:
  LD A,(HL)
  JP Z,RearmNextSection   ; JP Z,RearmNextSection (the flags are not A's)
  RES 7,(HL)
  INC HL                  ; INC HL (3 times)
  INC HL
  INC HL
  LD A,(HL)               ; LD A,(HL): +3
  AND $03                 ; AND $03: the boxes
  INC HL
  JP Z,RearmEntryLoop     ; JP Z,RearmEntryLoop
RearmSkipBoxes:
  ADD HL,DE
  DEC A
  JP NZ,RearmSkipBoxes    ; JP NZ,RearmSkipBoxes
  JP RearmEntryLoop       ; JP RearmEntryLoop
RearmNextSection:
  LD BC,$0008
  ADD IX,BC
  RET

; Free the object record at IX and re-arm its map entry
;
; Clears bit 7 of the map entry the record points to (+$0C/+$0D; none when the
; word is 0) so the entry can spawn again, and clears +0, which frees the
; record. Called for every record when a section is set up ($9BEB), and when an
; object leaves the view (ShiftObjects, EnemyVertical, UpdateTrap).
;
; Input IX: an enemy or trap record. Witness: 476 runs in 56 builds (callers
; $9BFE 239, $9C19 206, $9E54 124, $9E7F 100, $A1CC 13, $A38E 44, $A39C 39,
; $A3CA 69).
;
; Witness: L1 1031 (long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke,
; rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke,
; rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-02000-poke,
; rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke,
; rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke,
; rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke,
; rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2, load-l4,
; sec-l2-s11, sec-l2-s12, sec-l4-s6, sec-l4-s11, sec-l5-s5).
FreeObject:
  LD L,(IX+$0C)
  LD H,(IX+$0D)
  LD A,L
  OR H
  JP Z,FreeObjectSlot
  RES 7,(HL)
FreeObjectSlot:
  LD (IX+$00),$00         ; the record is free
  RET

; Free the record at IX; re-arm its map entry unless the entry is one-shot
;
; As FreeObject, but leaves bit 7 of the map entry set when the entry's +3 has
; bit 6 (the one-shot flag): the object never comes back. Used when an object
; is used up: an enemy that fell out of the view after it was killed ($9FC2), a
; trap at the end of a one-shot path ($A348) or removed by its trigger ($A4A7,
; $A4C0), a pickup taken ($A598, $A5AD, $A5BD).
;
; Evidence: 548 runs in 57 builds.
;
; Witness: L1 1398 (cheats, end-congrats, long-l4, rzx-l1-00000-poke,
; rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke,
; rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke,
; rzx-l1-18000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke,
; rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke,
; rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke,
; rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke,
; rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke,
; rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke,
; rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke,
; rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke,
; rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke,
; rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l5, sec-l2-s7, sec-l2-s12,
; sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l5-s3, sec-l5-s5).
RetireObject:
  LD L,(IX+$0C)
  LD H,(IX+$0D)
  LD A,L
  OR H
  JP Z,RetireObjectSlot
  INC HL
  INC HL
  INC HL
  BIT 6,(HL)
  JP NZ,RetireObjectSlot
  DEC HL
  DEC HL
  DEC HL
  RES 7,(HL)
RetireObjectSlot:
  LD (IX+$00),$00         ; the record is free
  RET

; NZ when the y in HL lies outside the view
;
; HL: a y in pixels from the view's top. Z (A = 0) for 0-$138, NZ (A = 1) for a
; negative y or one from $139 (313) up. Called after every y change (127 574
; runs from UpdateTrap's $A3C7 alone, 132 289 in all).
;
; Witness: L1 306071 (cheats, end-congrats, long-l4, rzx-l1-00000-poke,
; rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke,
; rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke,
; rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke,
; rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke,
; rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke,
; rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke,
; rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke,
; rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke,
; rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke,
; rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke,
; rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke,
; rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke,
; rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke,
; rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
IsOffView:
  LD A,H
  AND A
  RET Z
  CP $01
  RET NZ
  LD A,L
  CP $39
  JP NC,IsOffViewYes
  XOR A
  RET
IsOffViewYes:
  XOR A                   ; $139-$1FF: off the view
  INC A
  RET

; Bring the map entry at IX to life: an enemy, a trap or pickup, or the bonus
; countdown
;
; Called by the map scan at $8B96 for an entry that came into the view or whose
; trigger box fired. Kinds below $74 go to SpawnMapObject; $78 starts the
; countdown bonus, $7C stops it and pays it; every other kind becomes an enemy.
; A full list (no free record) spawns nothing, and the entry stays unspawned
; (bit 7 clear) so the next scan tries again.
;
; Evidence: 1982 runs in 59 builds (all from $8B99); SpawnMapObject 1471 of
; them, the enemy branch 474, the bonus start 18 ($9CAC, rzx-l1-00000-poke and
; 14 pieces of levels 2-5) and stop 19 ($9CCA).
;
; Witness: L1 4603 (long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke,
; rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke,
; rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke,
; rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke,
; rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke,
; rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke,
; rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke,
; rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1,
; c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
SpawnFromMap:
  LD A,(IX+$00)
  CP $74
  JP C,SpawnMapObject
  CP $78
  JP Z,StartBonusTimer
  CP $7C
  JP Z,StopBonusTimer
  JP SpawnEnemy
StartBonusTimer:
  LD A,(BonusRunning)     ; kind $78: only when no countdown runs ($9BA9 = 0)
  AND A
  RET NZ
  DEC A                   ; $9BA9 = $FF: the countdown runs ($865D calls $9163
                          ; each pass)
  LD (BonusRunning),A
  LD A,$19                ; $9BAA = 25: passes per step of $9163 (10 points off
                          ; every 25 passes)
  LD (BonusPrescaler),A
  LD HL,$0002             ; the bonus digits $7F17-$7F1C = 002000
  LD (TimeBonus+$0002),HL
  XOR A
  LD (TimeBonus+$0004),A
  LD A,$01                ; tune 1
  CALL StartTune
  RET
StopBonusTimer:
  LD A,(BonusRunning)     ; kind $7C: only while the countdown runs
  AND A
  RET Z
  XOR A
  LD (BonusRunning),A
  LD HL,TimeBonus         ; the digits left at $7F17 go to the score
  CALL AddScore
  LD A,$01                ; tune 1 again
  CALL StartTune
  RET
SpawnEnemy:
  CALL FindFreeEnemyRecord ; a free 23-byte record at $7C20 ($9BD9), else
                           ; return
  RET NZ
  PUSH HL
  POP IY
  XOR A
  LD (IY+$06),$02         ; +6 = 2: walking right (+6 is the x step, its bit 7
                          ; the mirror)
  LD (IY+$09),A
  LD (IY+$0E),A
  LD (IY+$0F),A
  LD (IY+$10),A
  LD (IY+$12),A
  LD (IY+$11),A
  LD (IY+$14),A
  LD A,(IX+$00)           ; +0 = the kind without bit 7; bits 0-1 the
                          ; behaviour, bit 2 the sprite set
  AND $7F
  LD (IY+$00),A           ; the map entry marked alive
  SET 7,(IX+$00)
  LD A,(IX+$02)           ; x = column x 8
  AND $1F
  ADD A,A
  ADD A,A
  ADD A,A
  LD (IY+$01),A
  LD A,(ViewTopRow)       ; y = (row - the view's top row $88CF) x 8 + 3
  LD C,A
  LD A,(IX+$01)
  SUB C
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  INC HL
  INC HL
  INC HL
  LD (IY+$02),L
  LD (IY+$03),H
  PUSH IX                 ; +$0C/+$0D: the map entry
  POP HL
  LD (IY+$0C),L
  LD (IY+$0D),H
  LD HL,EnemyAnimScripts  ; both branches load the same script (+$0A/+$0B),
                          ; which no enemy code reads
  BIT 2,(IY+$00)
  JP Z,SpawnEnemySetAnim
  LD HL,EnemyAnimScripts
SpawnEnemySetAnim:
  LD (IY+$0A),L
  LD (IY+$0B),H
  LD A,(IX+$03)           ; +$13 = (bits 2-5 of the entry's +3, plus 1) x 8:
                          ; the patrol length in pixels
  RRA
  RRA
  AND $0F
  INC A
  ADD A,A
  ADD A,A
  ADD A,A
  LD (IY+$13),A
  RET

; Three animation scripts the enemy spawn stores and nothing reads
;
; Frame numbers for SpriteFrameMap, each script closed by $FF and the address
; to loop to (the form AnimateTrap reads): frames $2A, $2A, $2B, $2B, $2C, $2C;
; $2D, $2E; $2F, $30. SpawnEnemy writes $9D59 into every enemy's +$0A/+$0B, but
; the enemies' sprites come from EnemyWalkSprites ($9ECE): no recording reads
; these bytes (l1q: the loader's writes only).
EnemyAnimScripts:
  DEFB $2A,$2A,$2B,$2B,$2C,$2C,$FF,$59,$9D
EnemyAnimScript2:
  DEFB $2D,$2E,$FF,$62,$9D ; frames $2D, $2E, loop
EnemyAnimScript3:
  DEFB $2F,$30,$FF,$67,$9D ; frames $2F, $30, loop

; Spawn a trap or pickup from a map entry (kind below $74)
;
; Takes a free 24-byte record at $7B8F ($9BC7; none: return) and fills it from
; the level's kind table, the word at LevelHeader (11 bytes a kind, addressed
; by kind x 2 through the table of pointers there): +7 width, +8 height, +2
; bits 6-7 into +0 and bits 0-5 x 4 (with the new kind's bits 0-5) into +$15
; (the kind to switch to), +3/+4 the path (+$0F/+$10), +5/+6 the animation
; (+$0A/+$0B), +7/+8 the second path (+$11/+$12), +9/+10 the second animation
; (+$13/+$14).
;
; +0 = 1 OR bits 2-5 of the entry's +3 OR the kind table's bits 6-7: bit 0
; alive, bit 1 path paused, bits 2-4 the trigger behaviour (UpdateTrap $A4AA),
; bit 5 with bit 2 the pickup kinds ($21, $29, $2D), bit 6 deadly to Rick and
; enemies, bit 7 the detonator test. Behaviour $10 starts with +6 = $60 (bit 6:
; no trigger test; bit 5: freed at the path's end), and with the one-shot bit
; (+3 bit 6) the record keeps no map entry (+$0C/+$0D = 0), so the entry is
; never re-armed. x = column x 8 (+4), y = (row - $88CF) x 8 (+3).
;
; Evidence: 1471 runs in 59 builds, from c1 (28) on; the behaviour-$10 branch
; 722 runs.
;
; Witness: L1 3254 (long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke,
; rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke,
; rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke,
; rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke,
; rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke,
; rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke,
; rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke,
; rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1,
; c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
SpawnMapObject:
  CALL FindFreeTrapRecord
  RET NZ
  PUSH HL
  POP IY
  XOR A
  LD (IY+$06),A
  LD (IY+$09),A
  LD (IY+$0E),A
  PUSH IX
  POP HL
  LD (IY+$0C),L
  LD (IY+$0D),H
  INC HL
  INC HL
  INC HL
  LD E,(HL)
  LD A,(IX+$00)
  ADD A,A
  LD C,A
  LD B,$00
  LD HL,(LevelHeader)           ; the kind table (LevelHeader+0), indexed by kind x 2
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD A,(HL)
  LD (IY+$07),A
  INC HL
  LD A,(HL)
  LD (IY+$08),A
  INC HL
  LD A,(HL)
  AND $C0
  LD C,A
  LD A,(IX+$03)
  AND $3C
  CP $10
  JP NZ,SpawnObjectKind
  LD (IY+$06),$60
  BIT 6,E
  JP Z,SpawnObjectKind
  LD (IY+$0C),$00
  LD (IY+$0D),$00
SpawnObjectKind:
  OR $01                  ; +0 = kind bits, alive bit 0
  OR C
  LD (IY+$00),A
  AND $3F
  LD C,A
  LD A,(HL)
  ADD A,A
  ADD A,A
  OR C
  LD (IY+$15),A
  INC HL
  LD A,(HL)
  LD (IY+$0F),A
  INC HL
  LD A,(HL)
  LD (IY+$10),A
  INC HL
  LD A,(HL)
  LD (IY+$0A),A
  INC HL
  LD A,(HL)
  LD (IY+$0B),A
  INC HL
  LD A,(HL)
  LD (IY+$11),A
  INC HL
  LD A,(HL)
  LD (IY+$12),A
  INC HL
  LD A,(HL)
  LD (IY+$13),A
  INC HL
  LD A,(HL)
  LD (IY+$14),A
  LD A,(IX+$02)
  AND $1F
  ADD A,A
  ADD A,A
  ADD A,A
  BIT 5,(IX+$02)
  JP Z,SpawnObjectX
  ADD A,$04
SpawnObjectX:
  LD (IY+$01),A
  LD A,(ViewTopRow)
  LD C,A
  LD A,(IX+$01)
  SUB C
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  BIT 6,(IX+$02)
  JP Z,SpawnObjectY
  INC HL
  INC HL
  INC HL
SpawnObjectY:
  LD (IY+$02),L
  LD (IY+$03),H
  SET 7,(IX+$00)
  RET

; Shift every object's y by BC pixels after the view scrolled
;
; BC: the shift (signed). Adds it to the y of every live trap ($7B8F, 24 bytes
; a record) and enemy ($7C20, 23 bytes), to Rick's y $9BAD, the bullet's $9BB6
; and the detonator's $9BBF. A trap or enemy pushed out of the view is freed
; (FreeObject), a bullet or detonator switched off ($9BB4, $9BBD = 0); Rick is
; never tested.
;
; Callers: the scroll routines $78A5 ($78F8, 83 runs) and $7905 ($7958, 89
; runs). Witness: 172 runs in 48 builds (rzx pieces; not in c1, where Rick
; never leaves the first screen).
;
; Witness: L1 372 (rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke,
; rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke,
; rzx-l1-18000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-02000-poke,
; rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke,
; rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke,
; rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l4-00000-poke,
; rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke,
; rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke,
; rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke,
; rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke,
; rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke,
; rzx-l5-full, sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l4-s12).
ShiftObjects:
  LD IX,Entry
  LD DE,$0018
ShiftTrapsLoop:
  LD A,(IX+$00)
  AND A
  JP Z,ShiftTrapsNext
  CP $FF
  JP Z,ShiftEnemies
  LD L,(IX+$02)
  LD H,(IX+$03)
  ADD HL,BC
  LD (IX+$02),L
  LD (IX+$03),H
  CALL IsOffView
  CALL NZ,FreeObject
ShiftTrapsNext:
  ADD IX,DE
  JP ShiftTrapsLoop
ShiftEnemies:
  LD IX,SetupIm2+$0006
  LD DE,$0017
ShiftEnemiesLoop:
  LD A,(IX+$00)
  AND A
  JP Z,ShiftEnemiesNext
  CP $FF
  JP Z,ShiftRickAndShots
  LD L,(IX+$02)
  LD H,(IX+$03)
  ADD HL,BC
  LD (IX+$02),L
  LD (IX+$03),H
  CALL IsOffView
  CALL NZ,FreeObject
ShiftEnemiesNext:
  ADD IX,DE
  JP ShiftEnemiesLoop
ShiftRickAndShots:
  LD HL,(RickY)           ; Rick ($9BAD) and the bullet ($9BB6)
  ADD HL,BC
  LD (RickY),HL
  LD HL,(BulletY)
  ADD HL,BC
  LD (BulletY),HL
  CALL IsOffView
  JP Z,ShiftDetonator
  XOR A
  LD (BulletRecord),A
ShiftDetonator:
  LD HL,(DetonatorY)      ; the detonator ($9BBF)
  ADD HL,BC
  LD (DetonatorY),HL
  CALL IsOffView
  RET Z
  XOR A
  LD (DetonatorRecord),A
  RET

  ORG $A69F

; Test the trigger boxes after the map entry at IX: C when one fires
;
; IX: a map entry; its +3 bits 0-1 give the number of 4-byte boxes after it.
; BC: the record to leave out of the trap test (UpdateTrap's own record; 0 from
; the map scan), kept in the alternate set (EXX). For each box in turn: its
; rows are clipped to the view (a box above the view or 32 rows below ends the
; test with NC), then, as its +3 bits ask, tested against Rick ($8D53, skipped
; while he dies), the bullet ($8C8D; a hit sets BulletSpent so $865D removes
; the bullet), the detonator's blast at phase 5-10 ($8CAE), the punch box $9BA3
; ($8C6C), each live enemy ($8DA3) and each other trap ($8DDF).
;
; A box that hits and has bit 7 clear fires: returns C with IX at the box, and
; sets bit 7 unless bit 6 asks it to fire on every pass. A box that hits with
; bit 7 set is passed over; one that misses has bit 7 cleared. No box fired:
; NC.
;
; Callers: the map scan $8BAC ($8BB5, 128 087: spawns the entry on C) and
; UpdateTrap ($A497, 105 179). Witness: 233 266 runs in 64 builds (all
; recordings); a fire 2030 times; the enemy test only in
; rzx-l3-00000/02000/04000-poke.
;
; Witness: L1 553212 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke,
; rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke,
; rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke,
; rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke,
; rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke,
; rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke,
; rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2-load-l5,
; sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9,
; sec-l4-s x5, sec-l5-s3, sec-l5-s5).
TestTriggerBoxes:
  EXX
  LD A,(IX+$03)
  AND $03
  RET Z
; This entry point is used by the routine at TriggerBoxTestRick.
TriggerBoxLoop:
  LD DE,$0004
  ADD IX,DE
  EX AF,AF'
  LD A,(IX+$02)
  LD D,A
  RRA
  RRA
  RRA
  RRA
  AND $0F
  INC A
  LD B,A
  LD A,(ViewTopRow)
  LD E,A
  LD A,(IX+$01)
  SUB E
  JP P,TriggerBoxRows
  ADD A,B
  JP P,TriggerBoxClipTop
TriggerBoxOff:
  XOR A                   ; out of the view: NC, the rest not tested
  RET
TriggerBoxClipTop:
  JP Z,TriggerBoxOff
  LD B,A
  XOR A
TriggerBoxRows:
  CP $20                  ; HL = y, B = height, C = width in pixels
  JP NC,TriggerBoxOff
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  SLA B
  SLA B
  SLA B
  LD A,D
  AND $0F
  INC A
  ADD A,A
  ADD A,A
  ADD A,A
  LD C,A

; TriggerBoxTestRick
TriggerBoxTestRick:
  LD A,(IX+$00)           ; E = the box's x
  LD E,A
  PUSH IX
  LD A,(IX+$03)
  RRA
  JP NC,TriggerBoxTestBullet
  LD D,A
  LD A,(RickDying)
  AND A
  JP NZ,TriggerBoxRickResult
  PUSH HL
  PUSH DE
  CALL TouchesRick
  POP DE
  POP HL
TriggerBoxRickResult:
  LD A,D
  JP NC,TriggerBoxTestBullet
TriggerBoxHit:
  POP IX
  LD A,(IX+$03)
  AND A
  JP M,TriggerBoxNext
  AND $40
  JP NZ,TriggerBoxFire
  SET 7,(IX+$03)
TriggerBoxFire:
  SCF
  RET
TriggerBoxTestBullet:
  RRA
  JP NC,TriggerBoxTestBlast
  LD D,A
  LD A,(BulletRecord)
  AND A
  JP Z,TriggerBoxBulletMiss
  PUSH DE
  PUSH HL
  CALL BulletHits
  POP HL
  POP DE
  JP NC,TriggerBoxBulletMiss
  LD A,$FF                ; the bullet is used up
  LD (BulletSpent),A
  JP TriggerBoxHit
TriggerBoxBulletMiss:
  LD A,D
TriggerBoxTestBlast:
  RRA
  JP NC,TriggerBoxTestPunch
  LD D,A
  LD A,(DetonatorRecord)
  AND A
  JP Z,TriggerBoxBlastMiss
  LD A,(DetonatorFuse)
  CP $0B
  JP NC,TriggerBoxBlastMiss
  CP $05
  JP C,TriggerBoxBlastMiss
  PUSH DE
  PUSH HL
  CALL BlastHits
  POP HL
  POP DE
  JP C,TriggerBoxHit
TriggerBoxBlastMiss:
  LD A,D
TriggerBoxTestPunch:
  RRA
  JP NC,TriggerBoxTestEnemies
  LD D,A
  LD A,(PunchTimer)
  AND A
  JP Z,TriggerBoxPunchMiss
  PUSH DE
  PUSH HL
  CALL PunchHits
  POP HL
  POP DE
  JP C,TriggerBoxHit
TriggerBoxPunchMiss:
  LD A,D
TriggerBoxTestEnemies:
  RRA
  JP NC,TriggerBoxTestTraps
  PUSH IX
  PUSH AF
  EXX
  LD HL,SetupIm2+$0006
  LD DE,$0017
TriggerBoxEnemyLoop:
  LD A,(HL)
  AND A
  JP Z,TriggerBoxEnemyNext
  CP $FF
  JP Z,TriggerBoxEnemiesDone
  PUSH HL
  POP IX
  LD A,(IX+$14)
  AND A
  JP NZ,TriggerBoxEnemyNext
  EXX
  PUSH DE
  PUSH HL
  CALL TouchesObject
  POP HL
  POP DE
  EXX
  JP NC,TriggerBoxEnemyNext
  POP AF
  POP IX
  EXX
  JP TriggerBoxHit
TriggerBoxEnemyNext:
  ADD HL,DE
  JP TriggerBoxEnemyLoop
TriggerBoxEnemiesDone:
  POP AF
  POP IX
  EXX
TriggerBoxTestTraps:
  RRA
  JP NC,TriggerBoxMiss
  EXX
  LD HL,Entry
  LD DE,$0018
TriggerBoxTrapLoop:
  LD A,(HL)
  AND A
  JP Z,TriggerBoxTrapNext
  CP $FF
  JP Z,TriggerBoxMiss
  LD A,L
  CP C
  JP NZ,TriggerBoxTrapTest
  LD A,H
  CP B
  JP Z,TriggerBoxTrapNext
TriggerBoxTrapTest:
  PUSH HL
  POP IX
  EXX
  PUSH DE
  PUSH HL
  CALL BoxesOverlap
  POP HL
  POP DE
  EXX
  JP C,TriggerBoxHit
TriggerBoxTrapNext:
  ADD HL,DE
  JP TriggerBoxTrapLoop
TriggerBoxMiss:
  POP IX                  ; no hit: the latch cleared
  RES 7,(IX+$03)
TriggerBoxNext:
  EX AF,AF'
  DEC A
  JP NZ,TriggerBoxLoop
  RET

; $FF: the bullet hit a trigger box this pass
;
; Written $FF by TestTriggerBoxes ($A734) and by the unexecuted pickup shot
; ($A5E6); $865D reads it after the bullet's move, clears it and switches the
; bullet off ($9BB4 = 0).
BulletSpent:
  DEFB $00

; Zeros to the end of the game image ($A7FF); the level starts at $A800
;
; No recording reads them (l1q: the loader's writes only).
ImageEndPad:
  DEFS $0F
