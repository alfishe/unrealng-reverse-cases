; --------------------------------------------------------------------------------------------------------------------
; rackscripts.asm: The rack-in scripts of sets 1-5: how the six object balls roll onto the table before frames 3-12
;
; The racking $9F6F (the lead's range) animates the six object balls into the rack before each frame. It picks a set
; from the table $A0C4 by the frame number $9F4B: set ((frame - 1) / 2) mod 6, so frames 1-2 use set 0 ($A0D0, the
; lead's range), 3-4 set 1, 5-6 set 2, 7-8 set 3, 9-10 set 4, 11-12 set 5, and from frame 13 on the sets repeat. A set
; is six words, the script of ball 1 to ball 6, then the scripts.
;
; A script is a byte program run one step a frame by $A05E for its ball, in a 4-byte slot at $9F51 (script pointer,
; wait count, move count): 0 = the end (the ball is done; the racking ends when all six are), 1 x y = place the ball
; at pixel (x, y) (+1 / +3 of its record), 2 n dx dy = move by (dx, dy) on each of the next n frames (signed bytes,
; mostly 2 pixels a frame), 3 n = wait n frames. Every script ends with a place command on the ball's rack position of
; $9D5D ((190, 115), (205, 106), (205, 124), (221, 98), (221, 115), (221, 132)), so a step count off by one does not
; matter.
;
; Set 1 ($A162-$A1E3) is read in w1 at frames 3 and 4. Sets 2-5, the 1310 bytes $A1E4-$A701, are read by no recording:
; no game reached frame 5 (w1 won frames 1-3). The only words in the image that point into $A1E4-$A701 are the four
; set pointers $A0C8-$A0CE and the sets' own script pointers (a byte search of work/mkgame/original.bin; other matches
; are instruction bytes). The scripts decode cleanly and each ends on its ball's rack position
; (work/stage2/ann/04-scratch/racks.py): they are the racks of frames 5-12, not leftover data. The paths (from the
; decoded scripts, not seen on screen): set 1 starts the balls from the four corners and the middles of the top and
; bottom cushions; set 2 runs them along the cushions to x 27 and then right along their rack rows; set 3 brings them
; from the right corners across to the left cushion and back; set 4 sends three from the top left and three from the
; bottom right round the cushions with pauses and short side steps; set 5 sends all six along one path, in at (8, 56),
; each dropping into a pocket and reappearing at another (place commands at the pocket positions (247, 175), (128,
; 56), (247, 56), (8, 175), (128, 175), (8, 56)).
; --------------------------------------------------------------------------------------------------------------------

; Rack-in set 1: the script of each object ball 1-6, the frames 3-4 rack
; (stage-1 w1 racked frames 3 and 4 with it)
;
; Read through the set table at $A0C4 by the racking $9F6F (index ((frame - 1)
; / 2) mod 6, the frame from $9F4B): w1 read every byte of this set twice
; (frames 3 and 4 of its game; l1sum.py --reads A162-A1E3: w1 only, 1562
; reads). No other recording reached frame 3.
RackSet1:
  INCBIN "res/racks/RackScripts.bin",$009E,12
  ASSERT {RackSet1} == Rack1Ball1 && {RackSet1+2} == Rack1Ball2 && {RackSet1+4} == Rack1Ball3
  ASSERT {RackSet1+6} == Rack1Ball4 && {RackSet1+8} == Rack1Ball5 && {RackSet1+10} == Rack1Ball6

; The scripts of rack-in set 1, ball 1 first
;
; The six scripts of set 1 (commands: 0 end, 1 x y place, 2 n dx dy move n
; frames by dx,dy, 3 n wait n frames; see RackSet1). Interpreted by the racking
; step $A05E.
Rack1Ball1:
  INCBIN "res/racks/RackScripts.bin",$00AA,17
Rack1Ball2:
  INCBIN "res/racks/RackScripts.bin",$00BB,21
Rack1Ball3:
  INCBIN "res/racks/RackScripts.bin",$00D0,21
Rack1Ball4:
  INCBIN "res/racks/RackScripts.bin",$00E5,21
Rack1Ball5:
  INCBIN "res/racks/RackScripts.bin",$00FA,17
Rack1Ball6:
  INCBIN "res/racks/RackScripts.bin",$010B,21

; Rack-in set 2: the script of each object ball 1-6, the frames 5-6 rack
;
; Reached only through the set table $A0C4 (the word at $A0C8) when the racking
; $9F6F racks frame 5 or 6 (or 17-18 after the wrap). No recording read a byte
; (l1sum.py --reads A1E4-A701: game, w1, f1, p2, v1, m1 all zero; w1, the
; longest game, reached frame 4). Known only from the code; every script
; decodes cleanly and ends on its ball's rack position ($9D5D)
; (work/stage2/ann/04-scratch/racks.py).
RackSet2:
  INCBIN "res/racks/RackScripts.bin",$0120,12
  ASSERT {RackSet2} == Rack2Ball1 && {RackSet2+2} == Rack2Ball2 && {RackSet2+4} == Rack2Ball3
  ASSERT {RackSet2+6} == Rack2Ball4 && {RackSet2+8} == Rack2Ball5 && {RackSet2+10} == Rack2Ball6

; The scripts of rack-in set 2, ball 1 first
;
; The six scripts of set 2 (commands: 0 end, 1 x y place, 2 n dx dy move n
; frames by dx,dy, 3 n wait n frames; see RackSet1). Interpreted by the racking
; step $A05E.
Rack2Ball1:
  INCBIN "res/racks/RackScripts.bin",$012C,26
Rack2Ball2:
  INCBIN "res/racks/RackScripts.bin",$0146,30
Rack2Ball3:
  INCBIN "res/racks/RackScripts.bin",$0164,30
Rack2Ball4:
  INCBIN "res/racks/RackScripts.bin",$0182,30
Rack2Ball5:
  INCBIN "res/racks/RackScripts.bin",$01A0,30
Rack2Ball6:
  INCBIN "res/racks/RackScripts.bin",$01BE,26

; Rack-in set 3: the script of each object ball 1-6, the frames 7-8 rack
;
; Reached only through the set table $A0C4 (the word at $A0CA) when the racking
; $9F6F racks frame 7 or 8 (or 19-20 after the wrap). No recording read a byte
; (l1sum.py --reads A1E4-A701: game, w1, f1, p2, v1, m1 all zero; w1, the
; longest game, reached frame 4). Known only from the code; every script
; decodes cleanly and ends on its ball's rack position ($9D5D)
; (work/stage2/ann/04-scratch/racks.py).
RackSet3:
  INCBIN "res/racks/RackScripts.bin",$01D8,12
  ASSERT {RackSet3} == Rack3Ball1 && {RackSet3+2} == Rack3Ball2 && {RackSet3+4} == Rack3Ball3
  ASSERT {RackSet3+6} == Rack3Ball4 && {RackSet3+8} == Rack3Ball5 && {RackSet3+10} == Rack3Ball6

; The scripts of rack-in set 3, ball 6 first
;
; The six scripts of set 3 (commands: 0 end, 1 x y place, 2 n dx dy move n
; frames by dx,dy, 3 n wait n frames; see RackSet1). Interpreted by the racking
; step $A05E.
Rack3Ball6:
  INCBIN "res/racks/RackScripts.bin",$01E4,41
Rack3Ball4:
  INCBIN "res/racks/RackScripts.bin",$020D,41
Rack3Ball2:
  INCBIN "res/racks/RackScripts.bin",$0236,41
Rack3Ball5:
  INCBIN "res/racks/RackScripts.bin",$025F,33
Rack3Ball3:
  INCBIN "res/racks/RackScripts.bin",$0280,41
Rack3Ball1:
  INCBIN "res/racks/RackScripts.bin",$02A9,33

; Rack-in set 4: the script of each object ball 1-6, the frames 9-10 rack
;
; Reached only through the set table $A0C4 (the word at $A0CC) when the racking
; $9F6F racks frame 9 or 10 (or 21-22 after the wrap). No recording read a byte
; (l1sum.py --reads A1E4-A701: game, w1, f1, p2, v1, m1 all zero; w1, the
; longest game, reached frame 4). Known only from the code; every script
; decodes cleanly and ends on its ball's rack position ($9D5D)
; (work/stage2/ann/04-scratch/racks.py).
RackSet4:
  INCBIN "res/racks/RackScripts.bin",$02CA,12
  ASSERT {RackSet4} == Rack4Ball1 && {RackSet4+2} == Rack4Ball2 && {RackSet4+4} == Rack4Ball3
  ASSERT {RackSet4+6} == Rack4Ball4 && {RackSet4+8} == Rack4Ball5 && {RackSet4+10} == Rack4Ball6

; The scripts of rack-in set 4, ball 5 first
;
; The six scripts of set 4 (commands: 0 end, 1 x y place, 2 n dx dy move n
; frames by dx,dy, 3 n wait n frames; see RackSet1). Interpreted by the racking
; step $A05E.
Rack4Ball5:
  INCBIN "res/racks/RackScripts.bin",$02D6,55
Rack4Ball2:
  INCBIN "res/racks/RackScripts.bin",$030D,57
Rack4Ball1:
  INCBIN "res/racks/RackScripts.bin",$0346,49
Rack4Ball3:
  INCBIN "res/racks/RackScripts.bin",$0377,63
Rack4Ball6:
  INCBIN "res/racks/RackScripts.bin",$03B6,65
Rack4Ball4:
  INCBIN "res/racks/RackScripts.bin",$03F7,61

; Rack-in set 5: the script of each object ball 1-6, the frames 11-12 rack
;
; Reached only through the set table $A0C4 (the word at $A0CE) when the racking
; $9F6F racks frame 11 or 12 (or 23-24 after the wrap). No recording read a
; byte (l1sum.py --reads A1E4-A701: game, w1, f1, p2, v1, m1 all zero; w1, the
; longest game, reached frame 4). Known only from the code; every script
; decodes cleanly and ends on its ball's rack position ($9D5D)
; (work/stage2/ann/04-scratch/racks.py).
RackSet5:
  INCBIN "res/racks/RackScripts.bin",$0434,12
  ASSERT {RackSet5} == Rack5Ball1 && {RackSet5+2} == Rack5Ball2 && {RackSet5+4} == Rack5Ball3
  ASSERT {RackSet5+6} == Rack5Ball4 && {RackSet5+8} == Rack5Ball5 && {RackSet5+10} == Rack5Ball6

; The scripts of rack-in set 5, ball 1 first
;
; The six scripts of set 5 (commands: 0 end, 1 x y place, 2 n dx dy move n
; frames by dx,dy, 3 n wait n frames; see RackSet1). Interpreted by the racking
; step $A05E.
Rack5Ball1:
  INCBIN "res/racks/RackScripts.bin",$0440,79
Rack5Ball2:
  INCBIN "res/racks/RackScripts.bin",$048F,87
Rack5Ball3:
  INCBIN "res/racks/RackScripts.bin",$04E6,87
Rack5Ball4:
  INCBIN "res/racks/RackScripts.bin",$053D,87
Rack5Ball5:
  INCBIN "res/racks/RackScripts.bin",$0594,83
Rack5Ball6:
  INCBIN "res/racks/RackScripts.bin",$05E7,87
