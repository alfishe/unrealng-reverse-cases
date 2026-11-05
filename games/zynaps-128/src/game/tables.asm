; --------------------------------------------------------------------------------------------------------------------
; tables.asm: The span node pool, the bit reverse table, the hit grid, the script stack and the interrupt vectors
;
; All built in play: block 2 holds zeros here. (The 48K tape had a leftover of its mastering machine at $FDE8-$FE4A, a
; receive routine over the ZX Interface 1 RS-232 port; the 2 in 1 cleared it.)
; --------------------------------------------------------------------------------------------------------------------

; 95 span nodes of 8 bytes
;
; LevelSetUp ($8C3B) links them into the free list (head NodeFreeList $7F68)
; and ends it with $FFFF at $FAF8. A node: +0/+1 the span handler, +2 the
; column, +3 the countdown, +4/+5 the next node, +6 the width. PopNode $8AD0,
; PushNode $8ADF, the scroll step $8AED and $8C1C walk it (48K c2).
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
; $FC00-$FD8F in phases 2-4, MarkEnemyGrid ($90CB) ORs the collision bit of
; each enemy slot into the X bytes (step 4) and the Y bytes $FD00 (step 8),
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
; collision bits in, TestHitGrid ($9150) reads them (48K c2: 331 and 494
; entries).
HitGridY:
  DEFS $90

; The scenery script's stack (down from $FDFB)
;
; The scenery coroutine runs on its own stack: StartScript ($8D35) sets its SP
; ScriptSP ($801A) to $FDFB and puts the script's entry $8D72 there;
; ScriptYield ($8D45) and ScriptResume ($8D69) swap SP between it and the main
; stack. 48K c2 play-start holds return addresses at $FDD9-$FDFA.
;
; Zero in block 2. (The 48K tape had a download routine of its mastering
; machine from $FDE8 to $FE4A here: a count, an address and bytes over the ZX
; Interface 1 RS-232 port, never used by the game.)
ScriptStack:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The scenery script's first return address
;
; StartScript ($8D35) writes $8D72 here (the script entry) before the first
; resume. Zero in block 2.
ScriptStackTop:
  DEFW $0000

; JP to the frame handler, where every IM 2 interrupt lands
;
; SetUpInterrupts ($8516) writes JP $A9E4 here; the handler word $FDFE is
; switched by the menu and play code. Zero in block 2.
InterruptJump:
  DEFB $00
InterruptHandler:
  DEFB $00,$00            ; the JP's address: the current interrupt routine

; The IM 2 vector table: 257 bytes of $FD
;
; SetUpInterrupts ($8516) fills $FE00-$FF00 with $FD and sets I = $FE, so any
; vector the bus gives reads $FDFD. Reads at $FEFF/$FF00 in the recordings are
; interrupts taken inside routines (48K c1: $A321 1566 entries, 48K c2: $899E
; 3948).
;
; Zero in block 2. With K-MOUSE the set-up copies the mouse driver to
; $FE00-$FEDC (src/game/mouse.asm) and makes SetUpInterrupts fill the table
; from $FEE8: I = $FE still, and the vectors the bus gives on a Pentagon ($FF)
; read $FFFF/$FF00 inside the fill.
VectorTable:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00
