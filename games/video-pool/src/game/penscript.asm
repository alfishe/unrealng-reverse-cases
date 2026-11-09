; --------------------------------------------------------------------------------------------------------------------
; penscript.asm: The pen script: "written by" and the signature, as pen moves
;
; SignatureScript $DA80 is the pen's script for SignatureWrite $BD0C: 378 bytes, 312 commands, 557 steps; the pen
; starts at (16, 128). Byte b: high nibble 0 = command b (0 end, 1 pen up, 2 pen down, 3 dot dx dy with two signed
; bytes following); otherwise a move of b AND 15 steps by dy = bits 7-6, dx = bits 5-4 (2-bit two's complement: 0, 1,
; -2, -1), one pixel and one frame a step, plotting (x, y - 1) before each step while the pen is down. The text form
; for editing is in work/stage2/ann/05-editor-notes.md.
; --------------------------------------------------------------------------------------------------------------------

; The pen script of "written by" (x 16-64) and "James Hutchby" (x 75-184), y
; 120-146
;
; Read only by SignatureCommand $BD23 (m1, all 378 bytes, 1830 reads: two whole
; runs and one cut by a key). Stage 1 called it the logo's data; it is the
; pen's path. $DBF9 is the end command.
SignatureScript:
  INCBIN "res/text/SignatureScript.bin",$0000,378
