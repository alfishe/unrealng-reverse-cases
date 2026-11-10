; --------------------------------------------------------------------------------------------------------------------
; picturetext.asm: The loading picture's character codes and the array's padding
;
; 24 rows of 32 codes (src/res/loader/PictureText.txt), then the seven spaces left of a$.
; --------------------------------------------------------------------------------------------------------------------

; The loading picture: 24 rows of 32 character codes, the top row first
;
; Read by Loader through PrintPictureChar (c1: 768 reads, frames 246-361).
; Codes below $5F are the ROM's characters: "IS LOADING" (row 6) and the
; instructions in rows 8-22 ("USE FOUR DIRECTION KEYS WITH A JUMP KEY TO GUIDE
; YOUR MAN AND COLLECT A DOZEN EGGS. YOU MAY CHANGE THE DIRECTION AND JUMP
; KEYS. THERE ARE ALSO THE FOLLOWING FIXED KEYS: CAPS SHIFT & H ... HOLD, CAPS
; SHIFT & A ... ABORT"); codes $60 and up are PictureGraphics: the title logo
; of rows 0-4 and the frames of the panels.
PictureText:
  INCBIN "res/loader/PictureText.bin",$0000,768

; The array's last seven characters: spaces
;
; a$ is 1600 characters and the picture ends at $631B, so seven of its spaces
; are left ($631C-$6322, the last bytes of tape block 2). Never read by the
; loader or the game (c1 L1: no read).
ArrayPadding:
  DEFB $20,$20,$20,$20,$20,$20,$20
