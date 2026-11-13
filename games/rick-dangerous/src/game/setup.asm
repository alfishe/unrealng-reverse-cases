; --------------------------------------------------------------------------------------------------------------------
; setup.asm: The start: the 128K test, the player's copy to RAM 1, the interrupt mode, the mirror table
;
; The game's entry Start $AB4D runs once: DetectPaging $A043 tells a 128K from a 48K and on a 128K copies the AY
; player to RAM 1 and hooks its tick into the interrupt handler, SetUpInterrupts $A215 sets IM 2, two 126-byte blocks
; are moved out of the player's area, BuildMirrorTable fills $5B00 with the bit-reversed bytes the sprite drawers
; mirror with, and the game goes to the title at $E219.
; --------------------------------------------------------------------------------------------------------------------

  ORG $A043

; Tell a 128K from a 48K by paging RAM 1 in; on a 128K go on to copy the player
;
; Reads the byte E at $C000 (RAM 0), pages RAM 1 in, writes E + 1 at $C000,
; pages RAM 0 back and reads $C000 again. Still E: the write went to another
; page, the machine pages, and the routine goes on into CopyPlayerToRam1. E +
; 1: one RAM only (a 48K): the byte is put back and Is48K is set to $FF.
;
; Input: none. Output: A, BC, DE changed. Interrupts left disabled. Called once
; from Start (c1: 1 run, the 128K path).
;
; Witness: L1 1 (c1).
DetectPaging:
  DI
  LD A,($C000)
  LD E,A
  LD BC,$7FFD
  LD A,$01
  OUT (C),A
  LD A,E
  INC A
  LD D,A
  LD ($C000),A
  XOR A
  OUT (C),A
  LD A,($C000)
  CP E
  JP Z,CopyPlayerToRam1
Set48K:
  LD A,E                  ; a 48K: restore $C000, Is48K = $FF, return (run in
                          ; no recording: beeper48 starts after the load; its
                          ; state has Is48K = $FF)
  LD ($C000),A
  LD A,$FF
  LD (Is48K),A
  RET

; Copy the AY player and its tunes to RAM 1 and hook its tick into the
; interrupt handler
;
; Pages RAM 1, copies the $0DA4 bytes $5E00-$6BA3 to $C000-$CDA3, pages RAM 0
; back, then writes CALL SoundTick ($CD $30 $A0) over the three NOPs at
; $FF11-$FF13 in the interrupt handler ($FEFE).
;
; Entered from DetectPaging on a 128K only. Output: A, BC, DE, HL changed.
;
; Witness: L1 1 (c1).
CopyPlayerToRam1:
  LD BC,$7FFD
  LD A,$01
  OUT (C),A
  LD DE,$C000
  LD HL,$5E00
  LD BC,$0DA4
  LDIR
  XOR A
  LD BC,$7FFD
  OUT (C),A
  LD A,$CD
  LD (Im2MusicCall),A
  LD HL,SoundTick
  LD (Im2MusicCall+$0001),HL
  RET

  ORG $AB4D

; The game's entry: the 128K test, IM 2, the data moves, the mirror table, then
; the title
;
; Entered by a JP from the loader's second stage ($5DBB, c1 frame 19010). DI,
; SP = 0 (the stack below $FFFF), DetectPaging (on a 128K also the player's
; copy), SetUpInterrupts, then moves the 126 bytes at $6BA4 to $6A80 and the
; next 126 ($6C22) to $7080 (126 bytes is the size of a sprite frame: 21 rows
; of 6), builds the mirror table, border 0, and jumps to the title at $E219.
;
; Witness: L1 1 (c1).
Start:
  DI
  LD SP,$0000
  CALL DetectPaging
  CALL SetUpInterrupts
  LD HL,Kind16Frame
  LD DE,MusicImage+$0C80
  LD BC,$007E
  LDIR
  LD DE,GraphicSlot19
  LD BC,$007E
  LDIR
BuildMirrorTable:
  LD B,$00                ; $5B00 + n = n with its bits in reverse order, for n
                          ; = 255 ... 0 (B counts down from 0)
  LD H,$5B
BuildMirrorByte:
  LD L,B
  LD A,B
  LD C,$00
  RLA
  RR C
  RLA
  RR C
  RLA
  RR C
  RLA
  RR C
  RLA
  RR C
  RLA
  RR C
  RLA
  RR C
  RLA
  RR C
  LD (HL),C
  DJNZ BuildMirrorByte
  XOR A
  OUT ($FE),A
  JP Menu
