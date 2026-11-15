; --------------------------------------------------------------------------------------------------------------------
; loader.asm: The loader at $5E00: the screen, the 128K test, the game, the music
;
; Every block is a standard ROM block read by the ROM's LD-BYTES ($0556), flag $FF; a load error (carry clear) jumps
; to $0000, a reset. Between the screen and the game the loader tests for 128K paging and leaves its answer in
; MachineFlag $FFFE (0 a 128K, $FF a 48K): the game reads it in every interrupt to play the AY music or the beeper
; (src/game, Interrupt $9226).
; --------------------------------------------------------------------------------------------------------------------

; Load the screen, test for 128K paging, load the game and on a 128K the music,
; then enter the game
;
; 1. The loading screen: IX = Screen $4000, DE = 6912, LD-BYTES (tape block 5).
;
; 2. MachineFlag = $FF (a 48K until proved otherwise); SP = GameBlock $6000,
; under the game's block.
;
; 3. The paging test, through port $7FFD (BC): page RAM 0 at $C000 ($10: RAM 0,
; the 48K ROM 1, the screen in RAM 5) and write $2A at $C000; page RAM 4 ($14)
; and read $C000. A 48K has no port $7FFD: the read gives the $2A back, and the
; test stops (JR Z to LoadGame, MachineFlag left $FF). Otherwise the byte must
; be RAM: write 0, DEC (HL), OR (HL), INC A gives 0 only if the $FF stuck. Then
; page RAM 0 again: its $2A must still be there (two banks, not one mirrored).
; Only when all three hold, MachineFlag = 0.
;
; 4. LoadGame: IX = GameBlock $6000, DE = 40448, LD-BYTES (tape block 6,
; $6000-$FDFF).
;
; 5. On a 48K (MachineFlag not 0) JP GameEntry $9100 at once: the tape's last
; block is never read. On a 128K LoadMusic: page RAM 4, IX = $C000, DE = 4000,
; LD-BYTES (tape block 7, src/music), page RAM 0 back ($10) and JP GameEntry.
;
; The test leaves RAM 0 paged on both paths; on a 48K the writes at $C000 land
; in plain RAM that the game's load then overwrites. c1 (the 128K): MachineFlag
; = 0 at the game's entry (frame 15 019) and RAM 4 holds block 7 byte for byte
; (work/stage1/images/entry). The 48K path: work/stage2/rec/c48 (stage 2
; NOTES).
;
; Witness: L1 1 (c1).
LoaderMain:
  LD IX,Screen
  LD DE,6912
  LD A,$FF
  SCF
  CALL LdBytes
  JP NC,RomReset
  LD A,$FF
  LD (MachineFlag),A
  LD SP,GameBlock
  LD BC,$7FFD
  LD HL,PagedRam
  LD A,$10
  OUT (C),A
  LD (HL),$2A
  LD A,$14
  OUT (C),A
  LD A,(HL)
  CP $2A
  JR Z,LoadGame
NotMirrored:
  XOR A                   ; RAM 4 read back something else: check it is RAM
  LD (HL),A
  DEC (HL)
  OR (HL)
  INC A
  JR NZ,LoadGame
Ram4Ok:
  LD A,$10                ; RAM 4 holds a written byte: check RAM 0 kept its
                          ; $2A
  OUT (C),A
  LD A,(HL)
  CP $2A
  JR NZ,LoadGame
  XOR A
  LD (MachineFlag),A
LoadGame:
  LD IX,GameBlock             ; tape block 6, the game
  LD DE,40448
  LD A,$FF
  SCF
  CALL LdBytes
  JP NC,RomReset
  LD A,(MachineFlag)
  AND A
  JP NZ,GameEntry
LoadMusic:
  LD BC,$7FFD             ; a 128K: tape block 7 into RAM 4
  LD A,$14
  OUT (C),A
  LD IX,PagedRam
  LD DE,4000
  LD A,$FF
  SCF
  CALL LdBytes
  JP NC,RomReset
  LD BC,$7FFD
  LD A,$10
  OUT (C),A
  JP GameEntry
