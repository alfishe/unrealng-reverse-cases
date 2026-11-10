; --------------------------------------------------------------------------------------------------------------------
; basic.asm: The BASIC: line 10 and the header of the array a$ that carries the rest of the block
;
; Tape block 2 holds the program "CHUCKIE" (header: LINE 10, program length 18) and its variables area. Line 10 is
; RANDOMIZE USR 24307, a call of the loader at $5EF3. The variables area is one character array, a$(1600): its six
; header bytes, then 1600 bytes that BASIC never reads as text: the loading picture's graphics $5CE3, the loader's
; code $5EF3 and the picture's codes $601C, padded with seven spaces to $6322, the block's last byte.
;
; c1: the ROM loads the block through the fast LD-BYTES trap and runs line 10; the loader is entered at frame 246, T
; 30 897 (WALKTHROUGH 1).
; --------------------------------------------------------------------------------------------------------------------

; BASIC line 10: RANDOMIZE USR 24307
;
; The program the header's "program length 18" covers: the line number
; (big-endian), the line's length (14), RANDOMIZE ($F9), USR ($C0), the digits
; "24307", the number marker $0E and the five-byte small-integer form of 24307
; ($5EF3), ENTER. The ROM runs it at once (LINE 10 in the header) and its USR
; enters Loader $5EF3 (c1 frame 246).
BasicLine10:
  DEFB $00,$0A
  DEFB $0E,$00            ; the line's length, 14
  DEFB $F9,$C0            ; RANDOMIZE, USR
  DEFB $32,$34,$33,$30,$37 ; "24307"
  DEFB $0E,$00,$00,$F3,$5E,$00 ; $0E, then 24307 = $5EF3 as a small integer (0,
                               ; 0, low, high, 0)
  DEFB $0D                ; ENTER

; The variables area: the header of the character array a$(1600)
;
; $C1 is the name byte of a character array called a ($C0 + 1), then the
; array's length after this word ($0643 = 1603: the dimension count, the
; dimension and 1600 characters), one dimension, 1600 ($0640). BASIC keeps the
; array and never reads its contents: the 1600 bytes from $5CE3 are the loader
; and its picture.
ArrayHeader:
  DEFB $C1
  DEFB $43,$06            ; the length, 1603
  DEFB $01,$40,$06        ; one dimension of 1600
