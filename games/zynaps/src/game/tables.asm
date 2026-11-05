; --------------------------------------------------------------------------------------------------------------------
; tables.asm: The span node pool, the bit reverse table, the hit grid, the script stack and the interrupt vectors
;
; All built in play: the tape holds zeros here, except a leftover of the mastering machine at $FDE8-$FE4A (a receive
; routine over the ZX Interface 1 RS-232 port, see ScriptStack).
; --------------------------------------------------------------------------------------------------------------------

; 95 span nodes of 8 bytes
;
; LevelSetUp ($8C3B) links them into the free list (head NodeFreeList $7F68)
; and ends it with $FFFF at $FAF8. A node: +0/+1 the span handler, +2 the
; column, +3 the countdown, +4/+5 the next node, +6 the width. PopNode $8AD0,
; PushNode $8ADF, the scroll step $8AED and $8C1C walk it (c2).
NodePool:
  DEFS $02F8
  DEFS $08                ; the end marker ($FFFF)

; 256 bytes, each the bit reverse of its index
;
; Built by LevelSetUp ($8C3B, loop $8CE9). BuildGlyph ($89C9) patches its own
; load to look tiles up here for a mirrored tile (the row's flag bit 1);
; DrawSpinner ($A8BE) mirrors the panel's spinner with it.
BitReverse:
  DEFS $0100

; The collision grid: one byte a column (play) / the menu's raster colours
;
; Play: ClearHitGrid ($91C6, SP = $FD90, 200 bytes of PUSHes) clears
; $FC00-$FD8F each frame, MarkEnemyGrid ($90CB) ORs the collision bit of each
; enemy slot into the X bytes (step 4) and the Y bytes $FD00 (step 8),
; TestHitGrid ($9150) ANDs them for the ship and its shots.
;
; Menu: ClearColourBuffer ($A5A7) zeroes it, ExpandColours ($A5D1 and its
; callers $A685, $A790) writes a colour per scan line from $FC20, the menu
; raster interrupt ($A512) reads $FC20-$FC7F.
HitGridX:
  DEFS $20
MenuColours:
  DEFS $E0                ; the menu's raster colours from here, one a scan
                          ; line

; The Y half of the collision grid
;
; $FD00-$FD8F, cleared with HitGridX; MarkEnemyGrid ($90CB) ORs the enemies'
; collision bits in, TestHitGrid ($9150) reads them (c2: 331 and 494 entries).
HitGridY:
  DEFS $90

; The scenery script's stack (down from $FDFB)
;
; The scenery coroutine runs on its own stack: StartScript ($8D35) sets its SP
; ScriptSP ($801A) to $FDFB and puts the script's entry $8D72 there;
; ScriptYield ($8D45) and ScriptResume ($8D69) swap SP between it and the main
; stack. c2 play-start holds return addresses at $FDD9-$FDFA.
;
; On the tape: zero to $FDE7, then the start of a routine left by the mastering
; machine, running into the next entries to $FE4A: DI; XOR A; LD ($FE4B),A,
; then a loop that takes a count, an address and that many bytes through CALL
; $FE17 and stores them with a border flash, then a checksum compared at $FE0A
; (JP NZ,0 on a bad one). $FE17 reads a byte from the ZX Interface 1 RS-232
; port (OUT ($EF), IN ($F7), bit 7, 11-step delays): a download link, never
; used by the game.
ScriptStack:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $F3,$AF,$32,$4B,$FE,$CD,$17,$FE,$B7,$28,$17,$57,$CD,$17,$FE,$67 ; leftover
  DEFB $CD,$17,$FE                                                     ; routine
                                                                       ; (DI)

; The scenery script's first return address
;
; StartScript ($8D35) writes $8D72 here (the script entry) before the first
; resume. The tape holds leftover bytes ($6F, $CD).
ScriptStackTop:
  DEFW $CD6F

; JP to the frame handler, where every IM 2 interrupt lands
;
; SetUpInterrupts ($8516) writes JP $A9E4 here; the handler word $FDFE is
; switched by the menu and play code. The tape holds the leftover routine's
; bytes.
InterruptJump:
  DEFB $17
InterruptHandler:
  DEFB $FE,$77            ; the JP's address: the current interrupt routine

; The IM 2 vector table: 257 bytes of $FD
;
; SetUpInterrupts ($8516) fills $FE00-$FF00 with $FD and sets I = $FE, so any
; vector the bus gives reads $FDFD. Reads at $FEFF/$FF00 in the recordings are
; interrupts taken inside routines (c1: $A321 1566 entries, c2: $899E 3948).
;
; On the tape: the rest of the leftover routine to $FE4A, then zeros.
VectorTable:
  DEFB $23,$E6,$07,$D3,$FE,$15,$20,$F4,$18,$E3,$3A,$4B,$FE,$67,$CD,$17
  DEFB $FE,$BC,$C2,$00,$00,$FB,$C9
  DEFB $3E,$FE,$D3,$EF,$DB,$F7,$07,$30,$F7,$DB,$F7,$07,$30,$F2,$DB,$F7 ; leftover:
  DEFB $07,$30,$ED,$06,$12,$10,$FE,$0E,$80,$DB,$F7,$07,$06,$0B,$10,$FE ; receive a
  DEFB $CB,$19,$30,$F5,$3E,$EE,$D3,$EF,$79,$2F,$4F,$3A,$4B,$FE,$A9,$32 ; byte
  DEFB $4B,$FE,$79,$C9
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; leftover:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; checksum
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
