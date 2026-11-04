# "NE Editor ": the editor tape's first program (TZX block 30-31, 221 bytes, LINE 1). docs/03 (edA), docs/02 (editor).
# Built by tools/zxbasic.py (the format is in its docstring); the tape's header says LINE 1, length 221, no variables.
#
# One line: a black screen, a title in the lower screen, then the two loads.
# - CLEAR 38999 ($9857): RAMTOP just below the editor's checksum word $9858, so the saved game ($9C40-$C110) and
#   nee.mix ($C350-$CC13) lie above the BASIC's reach.
# - PRINT #0: the title in the lower screen: INVERSE 1 "N E T H E R  E A R T H  E D I T O R", the (c) line, then
#   TAB 12 "loading" in FLASH 1. {14 01} / {14 00} are INVERSE 1 / 0, {12 01} / {12 00} FLASH 1 / 0, {7F} the (c).
# - POKE 23739,111: channel S's output address (the CHANS area's second record, 23739-23740) $09F4 PRINT-OUT becomes
#   $096F, a RET: nothing reaches the upper screen, so the ROM's "Bytes: nee.mix" / "Program: nee.bas" (LD-LOOK-H
#   opens stream -2, channel S, at $0775) do not print over the title. Recording edB/tour: the POKE writes $6F at
#   frame 254+39859 ($1E83, the ROM's POKE); nee.bas's first CLS puts $09F4 back at frame 259+17648 (CL-ALL, $0DCF).
# - LOAD "nee.mix" CODE: 2244 bytes at 50000 ($C350); LOAD "nee.bas": the main program, which runs itself (LINE 1).
1 BORDER 0: PAPER 0: INK 7: CLEAR 38999: PRINT #0;"{14}{01}    N E T H E R    E A R T H              E D I T O R           {14}{00}      {7F} 1996  V.O.software"' TAB 12;"{12}{01}loading{12}{00}": POKE 23739,111: LOAD "nee.mix" CODE : LOAD "nee.bas"
