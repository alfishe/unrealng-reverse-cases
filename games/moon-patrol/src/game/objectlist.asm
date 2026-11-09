; --------------------------------------------------------------------------------------------------------------------
; objectlist.asm: The object list, free space and the stack: zero in the loaded image
; --------------------------------------------------------------------------------------------------------------------

; The live objects: one record per object, written by the course commands, run
; each pass
;
; Each record starts with the handler's address (a word) and the handler's own
; bytes; the first of them is the countdown before the object appears. The
; script commands write records at ObjectWrite $B261 (from $96A1: LD HL,$BEF8);
; the main loop runs the list through $9745 ($974A LD HL,$BEF8) and the
; interpreter at $9751, which stops at the end word $975E. The tape menu also
; clears it ($8288 LD IX,$BEF8, $830F). The record sizes the commands write: 20
; bytes for a UFO ($9B6B), 14 a tank ($9EBD), 9 a low flyer ($A03B), 8 a
; boulder ($A196) or a plant ($A2C6). $BEF8-$C194 is written in the runs.
ObjectList:
  DEFS $029D

; Never written in the runs: free space between the object list and the stack,
; zero in the image
FreeSpace:
  DEFS $017D

; The machine stack below BASIC's RAMTOP: the game keeps BASIC's stack
; (BasicStack $B25D), written from $C312 to $C34F in the runs
Stack:
  DEFS $3E
