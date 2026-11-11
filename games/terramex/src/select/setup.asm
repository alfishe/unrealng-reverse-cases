; --------------------------------------------------------------------------------------------------------------------
; setup.asm: The 128K setup: the paging test, the copies to RAM 1, 3, 4 and 6
;
; The loader $5D08 calls the block at $7200 with BC = $7200. Setup $C005 reads the first byte: 0 means the code is not
; relocated yet. Run at $7200 it tests the paging: $AA written to $C000 with RAM 0 paged, $55 with RAM 1, then read
; back with RAM 0; equal bytes mean one RAM there, a 48K. On a 128K it copies the block from $7200 to RAM 1 at $C000,
; the explorer sets 0-2 to RAM 4 ($C000, $D200, $E400) and 3-4 to RAM 3 ($C000, $D200), the music player $6000-$71FF
; to RAM 6, sets Has128K $5FFE = $11 and jumps to the copy in RAM 1 with BC = $C000, where the relocation pass runs.
; On a 48K it relocates the code in place at $7200.
;
; c1: the setup runs at $7200 at frame 11841 (the L1 arrival: $C000 in RAM 1 written by the LDIR at $7243, entered
; from $72A7); the copy to RAM 6 is the LDIR at $729B.
; --------------------------------------------------------------------------------------------------------------------

; The block's first bytes: the relocated flag, a jump over the table offset
;
; The NOP at $C000 is also a flag: the tape holds 0, RelocateSelector $C0AB
; writes $2F (CPL) once the words are relocated, so every later entry runs CPL;
; JR (harmless) and Setup $C005 sees a nonzero byte. Entered with BC = the
; block's address: by the loader at $7200 (CALL $7200 at $5D61), by Setup at
; $C000 in RAM 1 (JP at $C0A7), and by the game's menu (CALL $C000 at $8F5E
; with RAM 1 paged, Last7FFD = $11).
;
; c1: entered twice (the load at frame 11841, the game's menu at frame 22215);
; explorers: six times (the menu after each abort).
;
; Witness: L1 8 (c1, explorers).
SelectorStart:
  NOP
  JR Setup

; The offset of RelocTable from the block's start ($2A0F)
;
; RelocateSelector $C0AB adds this word to the block's address to find
; RelocTable $EA0F. It is not itself relocated.
RelocTableOffset:
  DEFW $2A0F

; Dispatch on the relocated flag and the run address; on a 128K the paging test
; and the copies
;
; In: BC = the block's address. HL = BC; a nonzero first byte (relocated) goes
; to SelectorEntry $C0D2. With B = $C0 (the unrelocated copy in RAM 1) it goes
; to RelocateSelector $C0AB. Otherwise (run at $7200 by the loader) the paging
; test, using the alternate registers for the port so that BC and HL keep the
; address: Has128K $5FFE = 0; RAM 0 at $C000 ($7FFD = $10, ROM 1), its byte at
; $C000 kept in E and $AA written; RAM 1 ($11), $55 written and read; RAM 0
; again and compared; the byte restored. Equal: a 48K, RelocateInPlace $C0AA.
;
; 128K: RAM 1 paged, the $2EE0 bytes from $7200 copied to $C000 (the block's 11
; 000 and 1000 bytes of set 0 after it, unused there); the 3 x $1200 bytes from
; $9CF8 to RAM 4 $C000 a byte at a time (RAM 0 paged to read, since the source
; runs past $C000, RAM 4 to write), the 2 x $1200 bytes after them to RAM 3
; $C000 the same way, Has128K = $11, the music player $6000-$71FF ($1200 bytes)
; to RAM 6 $C000, RAM 1 paged again, and JP $C000 with BC = $C000.
;
; c1: one run at frame 11841: 13 824 bytes to RAM 4 ($724E loop), 9216 to RAM 3
; ($7272 loop), 4608 to RAM 6 ($729B). explorers starts from a snapshot after
; the load: only the relocated path ($C009 to $C068).
;
; Witness: L1 8 (c1, explorers).
Setup:
  PUSH BC
  POP HL
  LD A,(HL)
  OR A
  JR NZ,SetupToEntry      ; relocated (first byte nonzero): the selector proper
  LD A,B                  ; not relocated: B = $C0 is the copy in RAM 1,
                          ; relocate it there
  CP $C0
  JR Z,SetupToRelocate
TestPaging:
  EXX                     ; run at $7200 by the loader: the paging test with
                          ; the port in the alternate BC
  LD BC,$7FFD
  XOR A
  LD (Has128K),A            ; Has128K = 0 until the test says otherwise
  LD A,$10
  OUT (C),A
  PUSH HL
  LD HL,$C000             ; the test byte: $C000, in whichever RAM is paged
                          ; there
  LD E,(HL)
  LD (HL),$AA
  LD A,$11
  OUT (C),A
  LD (HL),$55
  LD A,(HL)
  EX AF,AF'
  LD A,$10
  OUT (C),A
  EX AF,AF'
  CP (HL)                 ; $55 read under RAM 1 against RAM 0's byte: equal on
                          ; a 48K
  LD (HL),E               ; put RAM 0's byte back
  POP HL
  JR Z,RelocateInPlace    ; a 48K: relocate in place at $7200
Copy128K:
  EXX                     ; a 128K: RAM 1 at $C000, copy the block there
  LD BC,$7FFD
  LD A,$11
  OUT (C),A
  LD DE,SelectorStart
  LD BC,$2EE0
  LDIR                    ; 11 000 bytes of the block and 1000 of set 0 after
                          ; it
  LD HL,TapeExplorerSets             ; explorer sets 0-2 ($3600 bytes) to RAM 4
  LD DE,$C000
  LD BC,$3600
CopyToRam4Loop:
  EXX                     ; read with RAM 0 paged, write with RAM 4 paged
  LD BC,$7FFD
  LD E,$14
  LD D,$10
  OUT (C),D
  EXX
  LD A,(HL)
  EXX
  OUT (C),E
  EXX
  LD (DE),A
  INC DE
  INC HL
  DEC BC
  LD A,C
  OR B
  JR NZ,CopyToRam4Loop
  JR CopyToRam3
SetupToEntry:
  JR SelectorEntry        ; a JR stepping stone to SelectorEntry
SetupToRelocate:
  JR RelocateSelector     ; a JR stepping stone to RelocateSelector
CopyToRam3:
  LD DE,$C000             ; explorer sets 3-4 ($2400 bytes) to RAM 3
  LD BC,$2400
CopyToRam3Loop:
  EXX                     ; read with RAM 0 paged, write with RAM 3 paged
  DI
  LD E,$13
  OUT (C),D
  EXX
  LD A,(HL)
  EXX
  OUT (C),E
  EXX
  LD (DE),A
  DEC BC
  INC HL
  INC DE
  LD A,B
  OR C
  JR NZ,CopyToRam3Loop
  LD A,$11                ; Has128K = $11
  LD (Has128K),A
  LD BC,$7FFD
  LD A,$16                ; the music player $6000-$71FF to RAM 6 at $C000
  OUT (C),A
  LD HL,$6000
  LD BC,$1200
  LD DE,$C000
  LDIR
  LD A,$11                ; RAM 1 again
  LD BC,$7FFD
  OUT (C),A
  LD BC,SelectorStart     ; enter the copy in RAM 1 with BC = its address
  JP SelectorStart
