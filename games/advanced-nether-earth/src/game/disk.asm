; --------------------------------------------------------------------------------------------------------------------
; disk.asm: the disk load bridge and the stack the bank calls run on
;
; Loading and saving go through the disk module, a separate image in bank 4 that reads and writes the saved game on
; the disk. The game calls it through two bridges: GameLoad here (key 5 of the main menu) and GameSave in the im2
; module (key 5 in play). Each keeps SP, switches to GlueStack, tells the module which job to do in IX (DiskLoad $4000
; or DiskSave $4033), pages bank 4 and jumps to DiskModule ($C000); the module comes back by a JP to LoadReturn or
; SaveReturn with bank 0 paged, and the bridge restores SP and IM 2.
;
; GlueStack is the stack of every call that pages a bank over $C000-$FFFF (the game's stack starts at $0000 and grows
; down from $FFFF): SP = $A5ED, growing down over the 54 zero bytes here and over GameEntry's 19 bytes, which run only
; once, at the block's start.
; --------------------------------------------------------------------------------------------------------------------

; Load a saved game through the disk module in bank 4
;
; Reached by LoadGame's JP ($C1FD, key 5 of the main menu). The same steps as
; GameSave with IX = DiskLoad ($4000): SP into LoadReturn's operand, GlueStack,
; a HALT for a frame's start, bank 4, the ROM's keyboard variables (FLAGS $CC,
; LAST_K ENTER, CAPS LOCK off), JP DiskModule.
GameLoad:
  LD (LoadReturn+$0001),SP ; keep SP in LoadReturn's LD SP
  LD SP,GlueStack+73      ; GlueStack
  LD IX,DiskLoad          ; the module's load entry
  LD A,$14                ; bank 4: the disk module
  EI
  HALT                    ; a frame's start
  LD BC,$7FFD
  OUT (C),A
  LD A,$CC                ; FLAGS: the keyboard state the module expects
  LD (ViewBuffer+315),A
  LD A,$0D                ; LAST_K = ENTER
  LD (ViewBuffer+264),A
  LD HL,ViewBuffer+362             ; FLAGS2 bit 3: CAPS LOCK off
  RES 3,(HL)
  JP DiskModule           ; the disk module; it comes back with JP LoadReturn

; LoadReturn
LoadReturn:
  LD SP,$0000             ; back from the disk module (bank 0 paged again), its
                          ; flags kept
  LD A,$68                ; IM 2 through ImTable again
  LD I,A
  IM 2
  EI
  HALT                    ; a frame's start
  LD HL,$FFFF             ; $FFFF into the view buffer's first word, which
                          ; nothing reads
  LD (ViewBuffer),HL
  JP NewGameSetup         ; with the module's flags: NZ a game was loaded
                          ; (NewGameSetup goes straight to EnterPlay), Z a new
                          ; game

; The stack of the bank calls: SP = $A5ED, down over these 54 bytes and
; GameEntry's
;
; Set by MenuPicture, GameSave and GameLoad while bank 3 or bank 4 lies over
; $C000-$FFFF. Zero in the block; the pushes reach into GameEntry
; ($A5DA-$A5EC), which never runs again.
GlueStack:
  DEFS $36
