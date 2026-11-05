; --------------------------------------------------------------------------------------------------------------------
; loader.asm: the intro's sequence: the two reads, the picture, the scroller loop, the exit to stage 3
;
; Stage 2 is the intro of the '99: it reads the pictures block (13 sectors to $7D87) and the music block (13 sectors
; to $C000) from where TR-DOS stopped (DosNextSector: the sectors right after its own), starts the Sound Tracker tune
; on an IM 2 interrupt, dissolves the screen, decodes the picture (photo, logo, the "You wanted new levels? Take its!"
; line) into a buffer and rolls it in, flashes the border and runs the 64-column scroller in a window under the logo
; until SPACE. Then it pushes the picture out sideways, wipes the attributes to white in a spiral, mutes the music,
; returns to IM 0 (the ROM's handler: on the Spectrum IM 0 reads $FF, RST $38) and reads stage 3 (6 sectors) to $8000,
; entering it by the RET of TR-DOS's read.
; --------------------------------------------------------------------------------------------------------------------

; Read the pictures block: 13 sectors to $7D87
;
; Entered by the depacker's jump (r99 frame 227). TR-DOS reads (C = 5) 13
; sectors from DosNextSector, where the BASIC's read stopped: sectors 19-31 of
; NEZSEd99.B. Falls through to ReadMusic.
Stage2Start:
  LD BC,$0D05
  LD DE,(DosNextSector)
  LD HL,Pictures
  CALL TrDosEntry

; Read the music block: the next 13 sectors to $C000
;
; Sectors 32-44 of NEZSEd99.B. Falls through to IntroMain.
ReadMusic:
  LD BC,$0D05
  LD DE,(DosNextSector)
  LD HL,Music
  CALL TrDosEntry

; The intro from the music's start to stage 3's read
;
; Sets IM 2 (table $B000 of $B1, I = $B0, JP IM2Handler at $B1B1), initialises
; the tune (MusicInit, A = $80) and enables interrupts: from now on the tune
; plays each frame. Dissolves the screen (DissolveScreen), border black, the
; attributes to white ink on black in a spiral (SpiralAttrs, A = 7), patches
; the pictures block's two targets to PictureBuffer and PictureBufferAttrs,
; decodes the picture (DecodeScreen at $7D87) and rolls it in (RollInPicture).
; The border flashes yellow / black ten times (20 frames). The bottom row of
; the scroller window ($5AD0-$5ADF) is made black on black, the print font set
; to Font64, and the scroller runs (ScrollerLoop) until SPACE; then
; OutroAndLoad.
IntroMain:
  DI
  LD HL,IM2Table             ; the IM 2 table: 257 bytes $B1 from $B000
  LD DE,IM2Table+1
  LD BC,$0100
  LD (HL),$B1
  LDIR
  LD A,$B0                ; I = $B0, IM 2: every vector reads $B1B1
  LD I,A
  IM 2
  LD A,$C3                ; JP IM2Handler at $B1B1
  LD (IM2Jump),A
  LD HL,IM2Handler
  LD (IM2Jump+1),HL
  LD A,$80                ; the tune from its start (A is not read by the
                          ; player)
  CALL MusicInit
  EI
  CALL DissolveScreen     ; the old screen's pixels dissolved to nothing
  XOR A
  OUT ($FE),A
  LD A,$07                ; the attributes to ink 7, paper 0, cell by cell in a
                          ; spiral
  CALL SpiralAttrs
  LD HL,PictureBuffer             ; the pictures block decodes into the buffer, not the
                          ; screen
  LD (DecodePixelsTo),HL
  LD HL,PictureBufferAttrs
  LD (DecodeAttrsTo),HL
  CALL Pictures              ; the picture into PictureBuffer
  LD HL,PictureBuffer
  CALL RollInPicture      ; and onto the screen, line by line
  LD B,$0A                ; the border yellow / black ten times
BorderFlash:
  LD A,$06
  OUT ($FE),A
  HALT
  LD A,$00
  OUT ($FE),A
  HALT
  DJNZ BorderFlash
  LD HL,Attrs+720             ; row 22, columns 16-31: the window's bottom row,
                          ; black on black (the line printed there is not seen)
  LD B,$10
ClearPrintRow:
  LD (HL),$00
  INC HL
  DJNZ ClearPrintRow
  LD HL,Font64            ; the scroller's font
  LD (PrintFont),HL

; The scroller: a line printed in the window's bottom row, then eight one-pixel
; scrolls
;
; From ScrollText: PrintLine prints AT 32,22 and a line up to its CR, INC DE
; skips the LF, then 8 one-pixel scrolls of the window (ScrollWindowUp), each
; scroll two frames with the logo (CycleLogoColours) and the bottom line
; (CycleBottomRow) recoloured. The first line is printed before the loop
; without the skip, so the first pass prints its LF (the print row 23, below
; the window) and the empty second line. 156 passes print lines 2-157; then it
; starts again from the first. ENTER held stops the scroller (the colours keep
; cycling); SPACE ends it (OutroAndLoad). Ran r99 frames 746-1310 (23 lines,
; 184 scrolls).
ScrollerLoop:
  LD DE,ScrollText
  CALL PrintLine
  LD B,$9C                ; 156 lines
ScrollerLine:
  PUSH BC
  CALL PrintLine
  INC DE                  ; past the LF
  PUSH DE
  LD IX,ScrollWindow
  LD B,$08
ScrollerStep:
  PUSH BC                 ; the 8 scrolls of a line
  CALL ScrollWindowUp
ScrollerPause:
  CALL CycleLogoColours   ; two frames of colours
  CALL CycleBottomRow
  HALT
  CALL CycleBottomRow
  HALT
  LD A,$BF                ; ENTER (port $BFFE bit 0): held, stay here
  IN A,($FE)
  AND $01
  HALT
  JR Z,ScrollerPause
  LD A,$7F                ; SPACE (port $7FFE bit 0): on to the end
  IN A,($FE)
  AND $01
  JR Z,OutroAndLoad
  POP BC
  DJNZ ScrollerStep
  POP DE
  POP BC
  DJNZ ScrollerLine
  JR ScrollerLoop
OutroAndLoad:
  POP BC                  ; SPACE: the stack's three loop words dropped
  POP BC
  POP BC
  CALL PushOutScreen      ; the picture pushed out to both sides
  LD A,$07                ; border white
  OUT ($FE),A
  LD A,$38                ; the attributes to black ink on white paper in a
                          ; spiral
  CALL SpiralAttrs
  DI                      ; I = $3F and IM 0: the ROM's handler again (the game
                          ; is later unpacked over $B000)
  LD A,$3F
  LD I,A
  IM 0
  CALL MusicMute              ; the tune off
  EI
  LD BC,$0605             ; stage 3: 6 sectors to $8000 ...
  LD DE,(DosNextSector)
  LD HL,Stage3Load
  PUSH HL                 ; ... entered by the RET of TR-DOS's read (r99 frame
                          ; 2179)
  CALL TrDosEntry
  RET
