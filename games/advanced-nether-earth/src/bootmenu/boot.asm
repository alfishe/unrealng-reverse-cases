; --------------------------------------------------------------------------------------------------------------------
; boot.asm: the entry, the interrupt, paging, the game's start, the sample
;
; The boot program is block 5 of the disk (HRUM, src/sfx/blocks.asm Block05): UltraXOR's reader unpacks it to
; $6060-$F6D4 with bank 0 at $C000 and jumps to Start ($61A8) with SP = $6060. It holds the boot menu ("1-Game 2-Help
; 3-NOT used"), the help program (seven items, 28 pages of pictures and text) and the code that starts the game. Every
; other bank is loaded by then: bank 1 holds the boot tune (PT 3 Player v1.0 by Nick of GDC with X-Man's TOMY:
; src/music, aneS), bank 7 the game starter's block and a sample, banks 3, 4 and 6 the game's packed blocks.
;
; Start plays the tune's init, unpacks bank 7's image and goes to BootMenu (menus.asm), which installs BootInterrupt
; as the IM 2 handler: from then on the tune plays one frame an interrupt, paging bank 1 in and out ($11 / $10 through
; SetPage), until key 1. Key 1 leaves through LeaveForGame (print.asm) to StartGame: the starter from bank 7, the
; game's blocks put together and unpacked, JP to the game's block. Key 3 ("NOT used") plays a 1.1 s sample from bank 7
; through the AY's three volume registers (PlaySample).
;
; Page values: $10 = bank 0 at $C000, the 48 BASIC ROM; $11 bank 1, $13 bank 3, $14 bank 4, $16 bank 6, $17 bank 7.
; The stack is the 284 bytes under Start ($608C-$61A7).
; --------------------------------------------------------------------------------------------------------------------

; the IM 2 handler of the boot menu and the help: one frame of the boot tune
;
; Reached through Im2Table (every vector $6060, I = $5B) once a frame from
; BootMenu on. Keeps every register (both sets, IX, IY), pages bank 1 in, calls
; the player's play entry (PLAYER_PLAY, $C005 in bank 1), pages bank 0 back.
; The help's typing and pointer run under it; PlaySample turns interrupts off,
; LeaveForGame changes to IM 1.
BootInterrupt:
  DI                      ; nothing nests: the player is not reentrant
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH IX                 ; IX and IY too: the player uses them
  PUSH IY
  EXX                     ; and the second set
  EX AF,AF'
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,$11                ; bank 1 at $C000 (the tune and its player), the 48
                          ; ROM
  CALL SetPage
  CALL PLAYER_PLAY        ; one frame of the tune
  LD A,$10                ; bank 0 back
  CALL SetPage
  POP HL
  POP DE
  POP BC
  POP AF
  EX AF,AF'
  EXX
  POP IY
  POP IX
  POP HL
  POP DE
  POP BC
  POP AF
  EI                      ; interrupts on for the next frame
  RET

; the boot program's stack, $608C-$61A7 (SP starts at Start)
;
; 284 zero bytes the image carries; Start and HelpMenu set SP = $61A8, the
; stack grows down into them.
Stack:
  DEFS $011C

; the entry: the tune's init, bank 7's image unpacked, the boot menu
;
; Jumped to by the block's HRUM set-up (JP $61A8, interrupts off). Calls bank
; 1's $C000 (the player's init: the boot tune), then bank 7's $C000: bank 7's
; image is still packed there (BootBank7, src/sfx/blocks.asm) and unpacks in
; place with its depacker at $5B00, returning with interrupts off. Then
; BootMenu.
Start:
  DI
  LD SP,Stack+284         ; the stack under Start
  LD A,$11                ; bank 1
  CALL SetPage
  CALL BANK_WINDOW        ; the boot tune's init
  LD A,$17                ; bank 7
  CALL SetPage
  CALL BANK_WINDOW        ; bank 7's image unpacks itself in place
  LD A,$10                ; bank 0
  CALL SetPage
  JP BootMenu

; key 1: the game starter, the game's blocks put together and unpacked, the
; game
;
; Reached from LeaveForGame (IM 1 already). Copies the game starter's HRUM
; block (STARTER_LENGTH bytes from bank 7 $C000) to $9C40 and calls it: it
; unpacks over itself and runs the starter (the screen then shows "Eternity
; Industry": tour frame 11700). Then the game's packed block is put together at
; $6731: 16 K from bank 4 and its last 914 bytes from bank 3 $E79E; the game
; music's block goes from bank 3 to bank 1 $C000 and the disk module's from
; bank 6 to bank 4 $C000 (CopyBank, a byte at a time between two banks). Each
; of the three blocks at $C000 of banks 1, 3 (Dead End, loaded there) and 4 is
; then run: each HRUM block unpacks in place and returns. Last JP to the game's
; block at $6731, which unpacks the game over this program and starts it.
StartGame:
  DI
  LD SP,Stack+284
  LD A,$17                ; bank 7: the starter's block at its $C000
  CALL SetPage
  LD HL,BANK_WINDOW
  LD DE,STARTER
  LD BC,STARTER_LENGTH
  LDIR                    ; to $9C40, over the help's pictures
  LD A,$10                ; bank 0
  CALL SetPage
  CALL STARTER            ; the starter unpacks itself and runs; it returns
                          ; here
  LD B,$32                ; 50 turns with interrupts on: a pending interrupt is
                          ; taken
l_61E2:
  EI
  DJNZ l_61E2
  DI
  LD A,$14                ; bank 4: the game block's first 16 K
  CALL SetPage
  LD HL,BANK_WINDOW
  LD DE,GAME_BLOCK
  LD BC,GAME_HEAD_LENGTH
  LDIR
  LD A,$13                ; bank 3: the game block's last part, behind Dead End
  CALL SetPage
  LD HL,GAME_TAIL
  LD DE,GAME_TAIL_AT
  LD BC,GAME_TAIL_LENGTH
  LDIR
  LD HL,MUSIC_BLOCK
  LD DE,BANK_WINDOW
  LD BC,MUSIC_BLOCK_LENGTH
  LD IXL,A                ; from bank 3 (A = $13)
  LD IXH,$11              ; to bank 1
  CALL CopyBank           ; the game music's block to bank 1 $C000
  LD HL,DISK_BLOCK
  LD DE,BANK_WINDOW
  LD BC,DISK_BLOCK_LENGTH
  LD IXL,$16              ; from bank 6
  LD IXH,$14              ; to bank 4
  CALL CopyBank           ; the disk module's block to bank 4 $C000
  LD A,$11                ; bank 1
  CALL SetPage
  CALL BANK_WINDOW        ; the game music unpacks in place
  LD A,$13                ; bank 3
  CALL SetPage
  CALL BANK_WINDOW        ; Dead End unpacks in place
  LD A,$14                ; bank 4
  CALL SetPage
  CALL BANK_WINDOW        ; the disk module unpacks in place
  LD A,$10                ; bank 0 for the game
  CALL SetPage
  JP GAME_BLOCK           ; the game's block unpacks the game and starts it;
                          ; nothing returns

; $7FFD = A
;
; The boot program's only paging: every bank switch goes through here
; (BootInterrupt twice a frame). Keeps BC. The game starter calls it too
; (docs/03-build-and-load.md).
SetPage:
  PUSH BC
  LD BC,PAGE_PORT
  OUT (C),A
  POP BC
  RET

; copy BC bytes from (HL) in page IXL to (DE) in page IXH
;
; One byte a turn: page IXL in, read, page IXH in, write. Used by StartGame for
; the blocks that go from one bank's $C000 window to another's. Leaves the last
; page (IXH) in.
CopyBank:
  LD A,IXL
  CALL SetPage
  LD A,(HL)               ; the byte from the source bank
  EX AF,AF'
  LD A,IXH
  CALL SetPage            ; the destination bank
  EX AF,AF'
  LD (DE),A
  INC HL
  INC DE
  DEC BC
  LD A,B
  OR C
  JR NZ,CopyBank
  RET

; zero $5AFF down to the first byte that will not take a zero, then wait for a
; frame
;
; HL from $5B00 down: each byte is written 0 and read back; the loop ends at
; the first byte that reads non-zero, the ROM's $3FFF (writes to the ROM do
; nothing). So it clears the screen and the attributes ($4000-$5AFF) without a
; count. Then EI; HALT: the next frame (BootInterrupt plays the tune). Called
; before every picture is drawn.
ClearScreen:
  XOR A
  LD HL,Screen+6912       ; from the attributes' end down
l_626B:
  DEC HL                  ; the next byte down
  LD (HL),A
  OR (HL)                 ; reads back 0 while it is RAM
  JR Z,l_626B
  EI                      ; the ROM's $3FFF stopped it
  HALT
  RET

; boot menu key 3 ("NOT used"): 12790 samples from bank 7 through the AY's
; volumes
;
; Interrupts off (the tune stops), SilenceAy, bank 7. Each byte of SAMPLE
; ($CE09-$FFFE in bank 7) is written as it is to the AY's volume registers 8, 9
; and 10 (the three channels together as one DAC), then a short wait (B = 8):
; 307 T a sample, 11.4 kHz on a Pentagon, 1.1 s. Then SilenceAy, bank 0, EI.
; The menu's "3-NOT used" hides it; extra frame 50 plays it.
PlaySample:
  DI
  CALL SilenceAy
  LD A,$17                ; bank 7
  CALL SetPage
  LD HL,SAMPLE
  LD DE,SAMPLE_LENGTH
l_6282:
  LD A,(HL)               ; the sample
  EX AF,AF'
  LD BC,AY_SELECT
  LD A,$08                ; register 8: channel A's volume
  OUT (C),A
  EX AF,AF'
  LD B,$BF                ; B = $BF: the data port $BFFD
  OUT (C),A
  EX AF,AF'
  LD B,$FF
  LD A,$09                ; register 9: channel B's volume
  OUT (C),A
  EX AF,AF'
  LD B,$BF
  OUT (C),A
  EX AF,AF'
  LD B,$FF
  LD A,$0A                ; register 10: channel C's volume
  OUT (C),A
  EX AF,AF'
  LD B,$BF
  OUT (C),A
  LD B,$08                ; the wait between samples
l_62AA:
  DJNZ l_62AA
  INC HL
  DEC DE
  LD A,D
  OR E
  JR NZ,l_6282
  CALL SilenceAy          ; the sound off again
  LD A,$10                ; bank 0
  CALL SetPage
  EI
  RET

; the AY's volumes 8-10 to 0, its mixer (register 7) to $FF
;
; Used by PlaySample before and after the sample.
SilenceAy:
  LD B,$03                ; three registers from 8
  LD A,$08
l_62C0:
  PUSH BC
  PUSH AF
  LD BC,AY_SELECT
  OUT (C),A
  XOR A                   ; volume 0
  LD B,$BF
  OUT (C),A
  POP AF
  INC A
  POP BC
  DJNZ l_62C0
  LD BC,AY_SELECT
  LD A,$07                ; register 7, the mixer
  OUT (C),A
  LD A,B                  ; B = $FF: every tone and noise off
  LD B,$BF
  OUT (C),A
  RET
