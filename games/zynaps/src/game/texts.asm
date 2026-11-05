; --------------------------------------------------------------------------------------------------------------------
; texts.asm: The messages
;
; 28 messages, each up to $FF, printed by PrintMessage $A423 (message n: n + 1 $FF bytes from $82ED) and PrintString
; $A401. The editable text is src/res/text/messages.msg.txt (tools/res_text.py: the print codes as escapes).
; --------------------------------------------------------------------------------------------------------------------

; The 28 messages
;
; The print codes (PrintChar $A321): a byte below $20 takes the next byte: 0
; attribute, 1 ink, 2 paper, 3 column, 4 row, 5 column + n, 6 row + n; $1B n
; prints message n; $80 and up are the game's glyphs ($B54F). c1: PrintMessage
; 98 entries, PrintString 103.
Messages:
  INCBIN "res/text/messages.bin",$0000,461
PlayerDigit:
  INCBIN "res/text/messages.bin",$01CD,91
                                                                       ; $B034
