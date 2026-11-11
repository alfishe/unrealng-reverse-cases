; --------------------------------------------------------------------------------------------------------------------
; entry.asm: GameEntry, the IM 2 table and the game's start
; --------------------------------------------------------------------------------------------------------------------

; A game variable inside the image, set to 0 by GameEntry $8F00
Var8D00:
  DEFB $00

; Leftover: 255 bytes no code reads (350 of the 511 bytes up to $8EFF are
; zeros)
;
; No play build reads or writes $8D01-$8DFF (bytemap.py).
Leftover8D01:
  INCBIN "res/leftovers/8d01.bin",$0000,255

; The IM 2 table: on the tape, leftover bytes; GameEntry fills $8E00-$8F00 with
; $5F
;
; GameEntry $8F00 writes 257 bytes of $5F from $8E00, its own first byte $8F00
; included (the SkoolKit snapshot, taken after it, holds $5F there). With I =
; $8E and the bus at $FF the CPU reads the vector from $8EFF and $8F00: $5F5F,
; where GameEntry put JP $9491. Witness: every play build reads $8EFF 69582
; times in all (one interrupt a frame), and no other byte of the table.
Im2Table:
  INCBIN "res/leftovers/im2-table-tape.bin",$0000,256

; Game entry: the IM 2 table and vector, the stack, the 128K page, the
; life-loss patch
;
; The last tape block's loader jumps here (`JP $8F00` of the BASIC loader's
; code, c1 frame 21597). With interrupts off it writes `$10` to Last7FFD
; `$5FE5` (RAM 0 at `$C000`, ROM 1: the value the IM 2 handler `$9491` pages
; back after the music), fills the IM 2 table `$8E00-$8F00` (257 bytes) with
; `$5F`, puts `JP $9491` at `$5F5F` (the vector every interrupt reaches with I
; = `$8E`), sets SP to `$5E00`, I to `$8E`, IM 2 and EI.
;
; Then: `$5FFF` = 1 (the selector, run again from NewGame `$8F47`, reads it:
; the game has been loaded), border 0, `$8D00` = 0, the high score
; `$5B78-$5B7B` = 0 (it is cleared only here, so it survives from game to
; game), and the life-loss patch: the opcode at `$A9FD` (the `DEC (HL)` on
; Lives in `$A9EE`) is written `$35` (`DEC (HL)`) or, when `$5B03` is not 0,
; `$B7` (`OR A`): lives are never lost. The BASIC loader sets `$5B03` to 1 when
; `$8000` held `$C9` before the load (doc 3, 3.2): a cheat hook for a front end
; that pokes `$8000`. In c1 `$5B03` is 0 (`$8F41` not executed in any
; recording).
;
; Falls into NewGame `$8F47`.
;
; Witness: L1 1 (c1).
GameEntry:
  DI
  LD A,$10
  LD (Last7FFD),A
  LD HL,Im2Table
  LD BC,$005F
FillIm2Table:
  LD (HL),C               ; B = 0: 256 bytes of $5F, then the 257th
  INC HL
  DJNZ FillIm2Table
  LD (HL),C
  LD A,$C3
  LD (Im2Jump),A
  LD HL,Im2Handler
  LD (Im2Jump+1),HL
  LD SP,StackTop
  LD A,$8E
  LD I,A
  IM 2
  EI
  LD A,$01
  LD (GameLoaded),A
  XOR A
  OUT ($FE),A
  LD (Var8D00),A          ; the byte at $8D00 = 0 (read by $9C7E in play)
  LD H,A                  ; the high score $5B78-$5B7B = 0
  LD L,A
  LD (HiScore),HL
  LD (HiScore+2),HL
  LD C,$35                ; C = $35, the opcode DEC (HL)
  LD A,(InfiniteLives)            ; $5B03 = 1: the loader saw $C9 at $8000
  OR A
  JR Z,SetLifeLossOp
  LD C,$B7                ; C = $B7, the opcode OR A: Lives never decreases
SetLifeLossOp:
  LD A,C                  ; the opcode at $A9FD ($A9EE: DEC (HL) on Lives)
  LD (LifeLossOp),A

; Start a game: the device menu, the explorer selector, the set-up of a new
; game
;
; Reached from GameEntry `$8F00` (falls in) and from EndGame `$906D` (`JP
; $8F47`) after every game: c1 2 runs, explorers 5, gameover 1, rzx50000 1.
;
; 1. DeviceMenu `$93AF` until 0 is pressed.
;
; 2. On a 128K (Has128K `$5FFE` not 0): pages RAM 1 in (`$7FFD` = `$11`, kept
; in Last7FFD `$5FE5`) and calls `$C000` with BC = `$C000`: the explorer
; selector, which the 128K setup copied to RAM 1 and relocated there; it copies
; the chosen explorer's data set to `$6000-$71FF` and returns; then RAM 0 is
; paged back (`$10`). On a 48K the explorer was chosen during the load (the
; selector runs in place before the last block), so the same explorer plays
; every game.
;
; 3. The set-up (InitGame `$8F69`): clears `$5B04-$5B66` (the hero and party
; records and other state, 99 bytes); fills BearerLoads `$5B7C-$5B96` (27
; bytes) with `$FF` (free); `$B932` clears the creature table's active bits and
; bit 7 of `$B9D9` is set again; copies the saved panel back to the screen
; (`$E000` -> `$5000`, 2048 bytes; `$E800` -> `$5A00`, 256 attributes: EndGame
; `$906D` saved it there, because play uses `$E000-$EFFF` as the background
; copy of the play window); the tile bitmap pointer `$5B72` = `$F000`; `$5C3C`,
; `$A6FD`, `$A700`, `$5B98`, `$5B9B` = `$FF`, `$A6F5` = 7, `$5B06` = 0; clears
; `$5BFA-$5C8D` (148 bytes: the countdown, GameOver, Room, PassCount, RoomEvent
; and the rest); `$BCF2` with DE = 0; the object at `$5C25-$5C27` = X `$70`, Y
; `$60`, room `$0F`; Room `$5C01` = `$14` and the room set-up `$9855`; `$9EBD`;
; Lives `$5B97` = 4 and `$9E96` (the lives in the panel); the hero at X `$0A`
; (`$5B04`), Y `$60` (`$5B05`); the lift (`$AF81`) in room `$2B` (`$5B9E`) at Y
; `$30` (`$5B9F`); the countdown 30 days 23:59 (`$5BFB` days = `$1E`, `$5BFC`
; hours = `$17`, `$5BFD` minutes = `$3B`); `$9AA1` copies the start into the
; respawn state `$5C2B-$5C33`; `$9E5D`. Falls into MainLoop `$9018`.
;
; Witness: L1 9 (c1, explorers, gameover, rzx).
NewGame:
  CALL DeviceMenu

; The explorer selector on a 128K, then the new game (NewGame continued)
;
; The return point of NewGame's `CALL $93AF`: an entry of its own only because
; the explorers recording starts inside DeviceMenu, so its L1 sees the RET land
; here. Step 2 and 3 of NewGame `$8F47`: on a 128K the selector at `$C000` in
; RAM 1, then InitGame `$8F69`. Falls into MainLoop `$9018`.
;
; Witness: L1 8 (c1, explorers, rzx).
RunSelector:
  LD A,(Has128K)
  OR A
  JR Z,InitGame
  LD BC,$7FFD             ; page RAM 1 in: the relocated explorer selector at
                          ; $C000
  LD A,$11
  PUSH BC
  LD (Last7FFD),A
  OUT (C),A
  LD BC,SelectorStart     ; BC = the selector's base, $C000
  CALL SelectorStart      ; the selector: the chosen explorer's set to
                          ; $6000-$71FF
  POP BC
  LD A,$10                ; RAM 0 back at $C000
  LD (Last7FFD),A
  OUT (C),A
InitGame:
  LD HL,Hero             ; the new game's variables
  LD BC,$0063
  LD DE,Hero+1
  LD (HL),$00
  LDIR
  LD HL,BearerLoads             ; BearerLoads: 27 bytes of $FF (free)
  LD DE,BearerLoads+1
  LD BC,$001A
  LD (HL),$FF
  LDIR
  CALL ResetItems
  LD HL,CrystalPlace      ; bit 7 of $B9D9 set again
  SET 7,(HL)
  LD HL,BackBuffer        ; the panel saved by EndGame back on the screen:
                          ; $E000 -> $5000 (2048), $E800 -> $5A00 (256)
  LD DE,Screen+4096
  LD BC,$0800
  LDIR
  LD DE,Attributes+512
  LD BC,$0100
  LDIR
  LD HL,TilePixels        ; the tile bitmaps are at $F000
  LD (TilePixelsPtr),HL
  LD A,$FF
  LD (WantedItem),A
  LD (ThinkHints+$0017),A
  LD (ThinkHints+$001A),A
  LD (HeldItem),A
  LD (Thought+2),A
  LD A,$07
  LD (ThinkHints+$000F),A
  XOR A
  LD (Hero+2),A
  LD HL,UnicycleFrames             ; clear $5BFA-$5C8D (148 bytes): Countdown, GameOver,
                          ; Room, PassCount, RoomEvent, ...
  LD DE,CountdownDays
  LD BC,$0093
  LD (HL),A
  LDIR
  LD D,A
  LD E,A
  CALL AddScore
  LD HL,$6070             ; X $70, Y $60 to $5C25/$5C26: a constant, not an
                          ; address
  LD (BalloonX),HL
  LD A,$0F
  LD (BalloonInRoom),A
  LD HL,TilePixels
  LD (TilePixelsPtr),HL
  LD A,$14                ; the first room: $14
  LD (Room),A
  CALL SetUpRoom
  CALL DrawBearers
  LD A,$04                ; Lives = 4
  LD (Lives),A
  CALL DrawSpareLives
  LD A,$60                ; the hero's Y = $60
  LD (Hero+1),A
  LD A,$0A                ; the hero's X = $0A
  LD (Hero),A
  LD A,$2B                ; the lift's room = $2B
  LD (LiftRoom),A
  LD A,$30                ; the lift's Y = $30
  LD (LiftY),A
  LD HL,CountdownDays             ; the countdown: 30 days ($5BFB), 23 hours ($5BFC),
                          ; 59 minutes ($5BFD)
  LD (HL),$1E
  INC HL
  LD (HL),$17
  INC HL
  LD (HL),$3B
  CALL SaveRespawnPoint   ; the start is the first respawn state ($5C2B-$5C33)
  CALL DrawPortrait
