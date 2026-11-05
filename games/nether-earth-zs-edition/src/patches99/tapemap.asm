; --------------------------------------------------------------------------------------------------------------------
; tapemap.asm: LOAD MAP from tape (the tape set), run at $C1FD
;
; The patches block's `$D9AC-$DA3E` (147 bytes). Stage 3 copies it to `$C1FD-$C28F` on the tape path ($639A), over the
; game block's LoadMapRoom. Never run in a recording: the code is read from its bytes.
;
; "WAITING FOR LEVELFILE", then the next tape block with flag N ($4E), 512 bytes to LoadBuffer `$F000` (TapeRead
; repeats it until it loads), "LOADED O.K.", and the same tail as the disk version's DiskApplyLevel. It ends with JP
; $D800, into the start-up menu's code, not JP Start as the disk version does.
; --------------------------------------------------------------------------------------------------------------------

; LOAD MAP from tape: "WAITING FOR LEVELFILE", then a 512-byte block with flag
; N
;
; A tape map file is a headerless block of 512 bytes with the flag byte $4E:
; the 499 level bytes and the 13-byte tail of a NELEV file.
TapeLoadMap:
  CALL ClearScreen              ; a blank screen
  DI                      ; the play interrupt off
  LD A,$3F                ; I points at the ROM
  LD I,A
  IM 0                    ; IM 0
  CALL PrintInline              ; the prompt

; PrintInline text: "WAITING FOR LEVELFILE" at (11,5), attribute $05, setting
; $21
;
; The bytes 1 11 5 (position (11,5)), 2 $05 (cyan on black), 4 $21 (double
; height), the 21 characters, 0.
TapeWaitText:
  DEFM $01,$0B,$05,$02,$05,$04,"!WAITING FOR LEVELFILE",$00 ; AT (11,5),
                                                            ; attribute $05,
                                                            ; size $21

; The map block: 512 bytes, flag N, to LoadBuffer
TapeLoadLevel:
  LD HL,LoadBuffer             ; the buffer
  LD BC,$0200             ; 512 bytes
  LD A,$4E                ; flag N
  CALL ReadBlock              ; load (until it loads)
  CALL PrintInline              ; the report, over the prompt

; PrintInline text: "LOADED O.K." at (11,5), attribute $05, setting $22
;
; The bytes 1 11 5 (position (11,5)), 2 $05, 4 $22 (double height, double
; width), the 11 characters, 0.
TapeLoadedText:
  DEFM $01,$0B,$05,$02,$05,$04,"\"LOADED O.K.",$00 ; AT (11,5), attribute $05,
                                                   ; size $22

; The map block into the game: as DiskApplyLevel, then JP $D800
;
; The bytes $000-$1F2 to `$BDA9-$BF9B`, the tail $1F3-$1FF into the game's
; operands (DiskApplyLevel tells them), then the start-up menu's code at $D800.
TapeApplyLevel:
  LD HL,LoadBuffer             ; the block
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
  LD HL,(LoadBuffer+508)           ; +$1FC: the first factory record
  LD (FirstFactory),HL           ; into BuildMap
  LD A,(LoadBuffer+499)            ; +$1F3: the capture points
  LD (CapturePoints),A            ; the capture tick
  LD (CountPoints),A            ; CountBuildings
  LD A,(LoadBuffer+510)            ; +$1FE: the enemy's warbases
  LD (EnemyWarbases),A            ; into BuildMap
  INC A                   ; + 1: all the warbases
  LD (TargetWarbases),A            ; the target table
  LD (SpawnWarbases),A            ; the enemy's build
  LD A,(LoadBuffer+511)            ; +$1FF: the player's general resource at the start
  LD (MapGeneral),A            ; into NewGameSetup
  JP MenuCode                ; the start-up menu's code
