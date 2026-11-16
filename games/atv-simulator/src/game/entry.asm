; --------------------------------------------------------------------------------------------------------------------
; entry.asm: The entry: the copies out of the buffers' way, the initialisation, IM 2
;
; The 40000-byte block fills $6338-$FF77, so the game keeps work areas inside its own image: BufferP1 ($F03C-$F71B)
; lies over trail 6 as loaded ($F230), BufferP2 ($F71C-$FDFB) over the tune player ($F850-$FDFA). GameEntry first
; copies the tune player to $5B00-$60AB (Title and TrailEnd copy it back before a tune) and trail 6 to $60AC-$6335,
; just under the image, then the stack goes to $FFDC (the loader's place).
; --------------------------------------------------------------------------------------------------------------------

  ORG $D7D6

; Copy the tune player and trail 6 out, initialise, set IM 2, then the outer
; loop: Title, NewGame, CheckHiScore
;
; Entered from the loader's JP $D6B0 (c1 frame 14 100). LDIR $F850-$FDFA to
; $5B00 ($5AB bytes), $F230-$F4B9 to $60AC ($28A bytes); DI, SP = $FFDC, Init,
; SetupIm2.
;
; Witness: L1 1 (c1).
GameEntry:
  DI
  LD HL,TunePlay0
  LD DE,TunePlayerCopy
  LD BC,$05AB
  LDIR
  LD HL,Trail6Image
  LD DE,Trail6
  LD BC,$028A
  LDIR
; This entry point is used by the routine at EntryJumps.
Restart:
  DI                      ; the restart after ItemTooLow: SP, Init, SetupIm2,
                          ; the outer loop
  LD (SavedSp0),SP
  LD SP,StackTop
  CALL Init
  CALL SetupIm2
OuterLoop:
  LD HL,Attributes             ; AttrBase = $5800, Title, NewGame, CheckHiScore,
                          ; again
  LD (AttrBase),HL
  CALL MenuTable
  CALL NewGame
  CALL JpCheckHiScore
  JP OuterLoop
