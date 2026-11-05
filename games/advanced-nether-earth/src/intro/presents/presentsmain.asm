; --------------------------------------------------------------------------------------------------------------------
; presentsmain.asm: "Presents": the word spins and grows in the middle of the screen
;
; What it shows: the loader has blacked out the screen (LoaderMain), the block unpacks to $6600 and runs here.
; PresentsClear clears screen 5 to bright green ink on black ($44), PresentsBuildShow writes the unrolled copy routine
; PresentsShowLines after the image, and PresentsLoop shows the 16 frames of PresentsFrames one after another, two
; interrupts each (32 frames, about 0.64 s: sim frames 1198-1230 of tools/intro_trace.py, the recording work/intro/i1
; a little after the intro's picture): the word "Presents" turning a full turn about its centre while it grows from a
; speck to 176 pixels across, ending upright. Then it returns to the loader, which flashes screen 5 (the word) against
; the white screen 7 twenty times and goes on to the scroller.
;
; The frames (src/res/intro/presents/frames.png, tools/intro_presents.py): 16 bitmaps of 176 x 80 pixels (22 bytes x
; 80 lines, 1760 bytes each), one under another in play order, ink 1 paper 0. They are shown at character columns
; 5-26, pixel lines 56-135 (from $40E5: character row 7), with no mask: each frame overwrites the whole 22 x 80
; window, so a smaller frame clears what a larger one left.
;
; SPACE ends the part early (PresentsLoop reads the half row SPACE..B after each frame); so does the loader's own
; interrupt (LoaderInterrupt's SPACE test ends the whole boot at once). The interrupts run the loader's IM 2 handler,
; which plays "MAD NIGHT" on: Presents itself makes no sound.
; --------------------------------------------------------------------------------------------------------------------

; the entry: the screen cleared, the show routine built, the frames played
;
; Called by LoaderMain at $6600 with interrupts off (the HRUM block's set-up
; ends EI; JP $6600: they are on). Returns to LoaderMain after the 16th frame
; (PresentsFramePtr set back to the table's start) or on SPACE (the pointer
; left where it was).
Presents:
  CALL PresentsClear      ; screen 5: pixels clear, attributes bright green on
                          ; black
  CALL PresentsBuildShow  ; PresentsShowLines: the unrolled copy of one frame
PresentsLoop:
  EI                      ; one frame of the animation
  HALT                    ; two interrupts a frame: 25 frames a second
  HALT
PresentsFramePtr:
  LD HL,PresentsFrameTable ; HL = the table entry of this frame (the operand is
                           ; the pointer, moved on below)
  LD E,(HL)               ; DE = the frame's offset in PresentsFrames
  INC HL
  LD A,(HL)
  INC HL
  LD (PresentsFramePtr+$0001),HL ; the pointer on to the next entry
  CP $FF                  ; high byte $FF: the end of the table
  JR NZ,PresentsShowFrame
  LD HL,PresentsFrameTable ; the pointer back to the first entry for a next
                           ; run, and back to the loader
  LD (PresentsFramePtr+$0001),HL
  RET
PresentsShowFrame:
  LD D,A                  ; HL = PresentsFrames + the offset: the frame's first
                          ; byte
  LD HL,PresentsFrames
  ADD HL,DE
  CALL PresentsShow       ; copy it to the screen
  LD A,$7F                ; the half row SPACE..B
  IN A,($FE)
  RRA                     ; bit 0 set (SPACE up): the next frame
  JR C,PresentsLoop
  RET                     ; SPACE: back to the loader at once

; screen 5 cleared: pixels 0, attributes $44
;
; The 6144 pixel bytes zero (L of $4000), then the 768 attributes $44: bright,
; paper black, ink green. The frames are drawn in green on black over it.
PresentsClear:
  LD HL,$4000
  LD DE,$4001
  LD BC,$1800             ; 6144 + 1 bytes: the first attribute byte too, which
                          ; the next LDIR overwrites
  LD (HL),L
  LDIR
  LD BC,$02FF             ; HL = $5800 here: 767 more after it
  LD (HL),$44
  LDIR
  RET

; write PresentsShowLines: 80 lines of 11 POP HL / LD (nn),HL
;
; The code it writes at PresentsShowLines ($D4A4-$E266, 3523 bytes, just past
; the loaded image, in bank 0, which the loader leaves paged at $C000): for
; each of the 80 screen lines of the window, top down, 11 times POP HL (E1) and
; LD (address),HL (22 lo hi) with the address going 2 bytes right each time; at
; the end LD SP,IX (DD F9) and RET (C9). PresentsShow points SP at a frame
; first, so the routine moves the frame's 1760 bytes to the screen at 16 + 16 T
; a word: about 31 000 T, under half a frame.
PresentsBuildShow:
  LD HL,PresentsShowLines             ; where the code goes
  LD DE,$40E5             ; the window's top left: character row 7, column 5,
                          ; pixel line 0 (screen line 56)
  LD B,$50                ; 80 lines
PresentsBuildLine:
  PUSH BC                 ; one screen line of the window
  PUSH DE
  LD B,$0B                ; 11 words a line: 22 bytes, columns 5-26
PresentsBuildWord:
  LD (HL),$E1             ; POP HL
  INC HL
  LD (HL),$22             ; LD (nn),HL with nn = DE
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  INC E                   ; two bytes right
  INC E
  DJNZ PresentsBuildWord
  POP DE                  ; the line's start back
  CALL PresentsLineDown   ; one pixel line down
  POP BC
  DJNZ PresentsBuildLine
  LD (HL),$DD             ; after the 80th line: LD SP,IX ...
  INC HL
  LD (HL),$F9
  INC HL
  LD (HL),$C9             ; ... RET
  RET

; DE one pixel line down the screen
;
; The usual step: D + 1 within a character row; after its 8th line E + $20 (the
; next row) with D back by 8, unless E carries (the next third: D stays + 8
; past the third's first line).
PresentsLineDown:
  INC D
  LD A,D
  AND $07
  RET NZ
  LD A,E                  ; the next character row
  ADD A,$20
  LD E,A
  RET C                   ; the next third: D is right as it is
  LD A,D                  ; the same third: D back to the row's first line
  SUB $08
  LD D,A
  RET

; the frames' offsets in PresentsFrames, in play order, then $FFFF
;
; 16 words, k x 1760 for frames 0-15 (the frames are stored in play order, so
; the table is a plain count up), and $FFFF that ends the run (PresentsLoop
; tests the high byte). PresentsFramePtr walks it.
PresentsFrameTable:
  DEFW $0000,$06E0
  DEFW $0DC0,$14A0
  DEFW $1B80,$2260
  DEFW $2940,$3020
  DEFW $3700,$3DE0
  DEFW $44C0,$4BA0
  DEFW $5280,$5960
  DEFW $6040,$6720
  DEFW $FFFF

; the 16 frames: 22 bytes x 80 lines each
;
; The bytes of src/res/intro/presents/frames.png (tools/intro_presents.py):
; frame k at PresentsFrames + 1760 x k, each line 22 bytes left to right, top
; line first, in the order PresentsShowLines' POPs take them.
PresentsFrames:
  INCBIN "res/presents/frames.bin",$0000,28160

; copy one frame (HL) to the screen
;
; SP is kept in IX and set to the frame; the code falls through into
; PresentsShowLines (written by PresentsBuildShow just past the image), whose
; last instructions put SP back from IX and return to PresentsLoop. Interrupts
; stay on: an interrupt during the copy pushes its return address over the word
; just taken (below SP), so the frame's bytes in memory change after it is
; shown; each frame is shown once, so it does not show.
PresentsShow:
  LD IX,$0000
  ADD IX,SP               ; IX = SP
  LD SP,HL                ; SP = the frame: the POPs of PresentsShowLines read
                          ; it
