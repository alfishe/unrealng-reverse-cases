; --------------------------------------------------------------------------------------------------------------------
; im2.asm: the IM 2 table and jump, and the disk save's bridge between them
;
; The game runs in IM 2 with I = $68. Restart fills ImTable ($6800-$6900, 257 bytes) with $69, so whatever the data
; bus holds at the interrupt the vector read is $6969, where Restart has put a JP (ImJump) whose operand ImHandler
; ($696A) is the only thing that changes: MusicInterrupt outside play, PlayInterrupt in play. The table and the jump
; lie below $C000, where no paged bank can cover them, and are zero in the game block.
;
; Between them sits GameSave, the save half of the disk bridge (the load half, GameLoad, is in the disk module of this
; source, at $A56A): it pages bank 4 and jumps into the disk module, which comes back to SaveReturn.
; --------------------------------------------------------------------------------------------------------------------

; The IM 2 vector table: $6800-$6900, 257 bytes of $69 written by Restart; zero
; in the block
;
; Restart writes the 257 bytes ($6800 + 256 and the one after) every time it
; runs. The four bytes $6901-$6904 after the table are never written or read.
ImTable:
  DEFS $0105

; Save the game through the disk module in bank 4, then back to play
;
; Reached by SaveGameStage's JP ($C2E5) once the shots and the buildings are
; staged with the game state at $D92B-$FDFB, interrupts off. Keeps SP in
; SaveReturn's operand, takes GlueStack, sets IX = DiskSave ($4033, the
; module's save entry; GameLoad passes DiskLoad), HALTs once for a frame's
; start, pages bank 4 ($14) and sets the ROM's keyboard variables as the module
; reads them: FLAGS ($5C3B) = $CC, LAST_K ($5C08) = ENTER, CAPS LOCK off
; (FLAGS2 bit 3). Then JP DiskModule ($C000 in bank 4).
GameSave:
  LD (SaveReturn+$0001),SP ; keep SP in SaveReturn's LD SP
  LD SP,GlueStack+$0049   ; GlueStack: bank 4 covers the game's stack
  LD IX,DiskSave          ; the module's save entry
  LD A,$14                ; bank 4: the disk module
  EI
  HALT                    ; a frame's start: the music handler has run before
                          ; the switch
  LD BC,$7FFD
  OUT (C),A
  LD A,$CC                ; FLAGS: the keyboard state the module's key reading
                          ; expects
  LD (ViewBuffer+315),A
  LD A,$0D                ; LAST_K = ENTER
  LD (ViewBuffer+264),A
  LD HL,ViewBuffer+362             ; FLAGS2 bit 3: CAPS LOCK off
  RES 3,(HL)
  JP DiskModule           ; the disk module; it comes back with JP SaveReturn

; SaveReturn
SaveReturn:
  LD SP,$0000             ; back from the disk module (bank 0 paged again)
  LD A,$68                ; IM 2 through ImTable again
  LD I,A
  IM 2
  EI
  HALT                    ; a frame's start
  JP PlayRedraw           ; PlayLoop's JP EnterPlay: the play screen again

; 48 bytes, never used
Im2Spare:
  DEFS $30

; The JP the vector $6969 lands on: $C3 written by Restart, zero in the block
ImJump:
  DEFB $00

; The interrupt handler's address, the operand of ImJump: MusicInterrupt or
; PlayInterrupt
;
; Written by Restart and ConstructionMenu (MusicInterrupt), by EnterPlay and
; StartRobot (PlayInterrupt). Zero in the block.
ImHandler:
  DEFW $0000

; 20 bytes, never used, up to the sprites
ImSpare:
  DEFS $14
