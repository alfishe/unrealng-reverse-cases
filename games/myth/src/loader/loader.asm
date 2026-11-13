; --------------------------------------------------------------------------------------------------------------------
; loader.asm: The SpeedLock loader: the hardware check, the memory clear, the second stage, the timing check
;
; The last layer falls into LoaderStart. It checks for a Multiface-style device paged over the ROM (IN from ports $3F
; and $9F, then the ROM's first byte must still be $F3), sends 0 or 1 to ports $1F, $7B and $BB, wipes $0000-$3FFF (a
; RAM paged there is zeroed; the ROM ignores it) and runs LoaderMain. LoaderMain clears the chain's memory, loads the
; second stage (tape block 7) to $FF26 through TimeCheck, clears the screen and falls into it.
;
; c1: LoaderStart runs once; the second stage loads; TimeCheck's comparison passes (FailFlag stays 0). docs/03-build-
; and-load.md has the tape's blocks.
; --------------------------------------------------------------------------------------------------------------------

; Check for a Multiface, page out the add-ons, wipe $0000-$3FFF, then
; LoaderMain
;
; DI; SP = $FFFF. IN A,($3F) and IN A,($9F) (the reads that page a Multiface
; in); after each, the ROM's first byte must be $F3, else JP RomStart (a
; reset). OUT ($1F),0, OUT ($7B),1, OUT ($BB),1 (none of them is the 128K's
; $7FFD: bit 1 of every port is set). (0) := 0 and LDIR $0000 -> $0001 for
; 16383 bytes; OUT ($7F),$43; LDDR $3FFE -> $3FFF. With the ROM in place these
; writes do nothing; a RAM over $0000 (a Multiface's, a ROM switcher's) is
; wiped. JP LoaderMain. What the ports drive is known only from the code
; ($FBD8-$FC01): c1 has no add-on, the checks pass.
;
; Witness: L1 1 (c1).
LoaderStart:
  DI
  LD SP,$FFFF
  IN A,($3F)
  LD A,(RomStart)
  CP $F3
LoaderReset:
  JP NZ,RomStart             ; JP RomStart: the device answered over the ROM
  IN A,($9F)
  LD A,(RomStart)
  CP $F3
  JR NZ,LoaderReset
  XOR A
  LD L,A
  LD H,L
  OUT ($1F),A
  INC A
  LD E,$01
  OUT ($7B),A
  LD D,L
  OUT ($BB),A
  LD (HL),L
  LD A,$43
  LD BC,$3FFF
  LDIR                    ; LDIR: c1 16383 passes
  DEC HL
  OUT ($7F),A
  LD BC,$3FFF
  DEC DE
  LD A,C
  LDDR                    ; LDDR: c1 16383 passes
  JP LoaderMain

  ORG $FF03

; Clear $5D00-$FC0C, load the second stage at $FF26, clear the screen and fall
; into it
;
; Witness: L1 1 (c1).
LoaderMain:
  LD HL,ChainRam
  LD DE,ChainRam+1
  LD BC,$9F0C
  LD (HL),L
  LDIR
  LD IX,Sl1Start
  LD DE,$00AA
  CALL TimeCheck
  LD HL,Attributes+767             ; clear $4000-$5AFF: the screen, black
  LD DE,Attributes+766
  LD BC,$1AFF
  LD (HL),$00             ; then into Sl1Start at $FF26
  LDDR
