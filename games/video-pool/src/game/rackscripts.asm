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
  DEFW Rack1Ball1,Rack1Ball2,Rack1Ball3,Rack1Ball4,Rack1Ball5,Rack1Ball6

; The scripts of rack-in set 1, ball 1 first
;
; The six scripts of set 1 (commands: 0 end, 1 x y place, 2 n dx dy move n
; frames by dx,dy, 3 n wait n frames; see RackSet1). Interpreted by the racking
; step $A05E.
Rack1Ball1:
  DEFB $03,$0F            ; ball 1: wait 15 frames
  DEFB $01,$07,$37        ; place at (7, 55)
  DEFB $02,$1E,$02,$02    ; move 30 frames by (+2, +2)
  DEFB $02,$3D,$02,$00    ; move 61 frames by (+2, +0)
  DEFB $01,$BE,$73        ; place at (190, 115)
  DEFB $00                ; end
Rack1Ball2:
  DEFB $03,$3E            ; ball 2: wait 62 frames
  DEFB $01,$80,$37        ; place at (128, 55)
  DEFB $02,$0A,$00,$02    ; move 10 frames by (+0, +2)
  DEFB $02,$17,$02,$00    ; move 23 frames by (+2, +0)
  DEFB $02,$0F,$02,$02    ; move 15 frames by (+2, +2)
  DEFB $01,$CD,$6A        ; place at (205, 106)
  DEFB $00                ; end
Rack1Ball3:
  DEFB $03,$3E            ; ball 3: wait 62 frames
  DEFB $01,$80,$B0        ; place at (128, 176)
  DEFB $02,$0B,$00,$FE    ; move 11 frames by (+0, -2)
  DEFB $02,$17,$02,$00    ; move 23 frames by (+2, +0)
  DEFB $02,$0F,$02,$FE    ; move 15 frames by (+2, -2)
  DEFB $01,$CD,$7C        ; place at (205, 124)
  DEFB $00                ; end
Rack1Ball4:
  DEFB $03,$5A            ; ball 4: wait 90 frames
  DEFB $01,$F8,$37        ; place at (248, 55)
  DEFB $02,$06,$FE,$02    ; move 6 frames by (-2, +2)
  DEFB $02,$08,$00,$02    ; move 8 frames by (+0, +2)
  DEFB $02,$06,$FE,$02    ; move 6 frames by (-2, +2)
  DEFB $01,$DD,$62        ; place at (221, 98)
  DEFB $00                ; end
Rack1Ball5:
  DEFB $03,$00            ; ball 5: wait 0 frames
  DEFB $01,$07,$AF        ; place at (7, 175)
  DEFB $02,$1E,$02,$FE    ; move 30 frames by (+2, -2)
  DEFB $02,$4D,$02,$00    ; move 77 frames by (+2, +0)
  DEFB $01,$DD,$73        ; place at (221, 115)
  DEFB $00                ; end
Rack1Ball6:
  DEFB $03,$5A            ; ball 6: wait 90 frames
  DEFB $01,$F8,$B0        ; place at (248, 176)
  DEFB $02,$06,$FE,$FE    ; move 6 frames by (-2, -2)
  DEFB $02,$09,$00,$FE    ; move 9 frames by (+0, -2)
  DEFB $02,$06,$FE,$FE    ; move 6 frames by (-2, -2)
  DEFB $01,$DD,$84        ; place at (221, 132)
  DEFB $00                ; end

; Rack-in set 2: the script of each object ball 1-6, the frames 5-6 rack
;
; Reached only through the set table $A0C4 (the word at $A0C8) when the racking
; $9F6F racks frame 5 or 6 (or 17-18 after the wrap). No recording read a byte
; (l1sum.py --reads A1E4-A701: game, w1, f1, p2, v1, m1 all zero; w1, the
; longest game, reached frame 4). Known only from the code; every script
; decodes cleanly and ends on its ball's rack position ($9D5D)
; (work/stage2/ann/04-scratch/racks.py).
RackSet2:
  DEFW Rack2Ball1,Rack2Ball2,Rack2Ball3,Rack2Ball4,Rack2Ball5,Rack2Ball6

; The scripts of rack-in set 2, ball 1 first
;
; The six scripts of set 2 (commands: 0 end, 1 x y place, 2 n dx dy move n
; frames by dx,dy, 3 n wait n frames; see RackSet1). Interpreted by the racking
; step $A05E.
Rack2Ball1:
  DEFB $03,$BE            ; ball 1: wait 190 frames
  DEFB $01,$07,$37        ; place at (7, 55)
  DEFB $02,$0A,$02,$02    ; move 10 frames by (+2, +2)
  DEFB $02,$14,$00,$02    ; move 20 frames by (+0, +2)
  DEFB $01,$1B,$73        ; place at (27, 115)
  DEFB $03,$00            ; wait 0 frames
  DEFB $02,$51,$02,$00    ; move 81 frames by (+2, +0)
  DEFB $01,$BE,$73        ; place at (190, 115)
  DEFB $00                ; end
Rack2Ball2:
  DEFB $03,$6F            ; ball 2: wait 111 frames
  DEFB $01,$80,$37        ; place at (128, 55)
  DEFB $02,$0A,$00,$02    ; move 10 frames by (+0, +2)
  DEFB $02,$32,$FE,$00    ; move 50 frames by (-2, +0)
  DEFB $02,$0F,$00,$02    ; move 15 frames by (+0, +2)
  DEFB $01,$1B,$6A        ; place at (27, 106)
  DEFB $03,$00            ; wait 0 frames
  DEFB $02,$59,$02,$00    ; move 89 frames by (+2, +0)
  DEFB $01,$CD,$6A        ; place at (205, 106)
  DEFB $00                ; end
Rack2Ball3:
  DEFB $03,$2E            ; ball 3: wait 46 frames
  DEFB $01,$F8,$37        ; place at (248, 55)
  DEFB $02,$0A,$FE,$02    ; move 10 frames by (-2, +2)
  DEFB $02,$64,$FE,$00    ; move 100 frames by (-2, +0)
  DEFB $02,$18,$00,$02    ; move 24 frames by (+0, +2)
  DEFB $01,$1B,$7C        ; place at (27, 124)
  DEFB $03,$06            ; wait 6 frames
  DEFB $02,$59,$02,$00    ; move 89 frames by (+2, +0)
  DEFB $01,$CD,$7C        ; place at (205, 124)
  DEFB $00                ; end
Rack2Ball4:
  DEFB $03,$00            ; ball 4: wait 0 frames
  DEFB $01,$F8,$B0        ; place at (248, 176)
  DEFB $02,$0A,$FE,$FE    ; move 10 frames by (-2, -2)
  DEFB $02,$64,$FE,$00    ; move 100 frames by (-2, +0)
  DEFB $02,$1D,$00,$FE    ; move 29 frames by (+0, -2)
  DEFB $01,$1B,$62        ; place at (27, 98)
  DEFB $03,$0D            ; wait 13 frames
  DEFB $02,$61,$02,$00    ; move 97 frames by (+2, +0)
  DEFB $01,$DD,$62        ; place at (221, 98)
  DEFB $00                ; end
Rack2Ball5:
  DEFB $03,$41            ; ball 5: wait 65 frames
  DEFB $01,$80,$B0        ; place at (128, 176)
  DEFB $02,$0A,$00,$FE    ; move 10 frames by (+0, -2)
  DEFB $02,$32,$FE,$00    ; move 50 frames by (-2, +0)
  DEFB $02,$14,$00,$FE    ; move 20 frames by (+0, -2)
  DEFB $01,$1B,$73        ; place at (27, 115)
  DEFB $03,$07            ; wait 7 frames
  DEFB $02,$61,$02,$00    ; move 97 frames by (+2, +0)
  DEFB $01,$DD,$73        ; place at (221, 115)
  DEFB $00                ; end
Rack2Ball6:
  DEFB $03,$82            ; ball 6: wait 130 frames
  DEFB $01,$07,$B0        ; place at (7, 176)
  DEFB $02,$0A,$02,$FE    ; move 10 frames by (+2, -2)
  DEFB $02,$0C,$00,$FE    ; move 12 frames by (+0, -2)
  DEFB $01,$1B,$84        ; place at (27, 132)
  DEFB $03,$00            ; wait 0 frames
  DEFB $02,$61,$02,$00    ; move 97 frames by (+2, +0)
  DEFB $01,$DD,$84        ; place at (221, 132)
  DEFB $00                ; end

; Rack-in set 3: the script of each object ball 1-6, the frames 7-8 rack
;
; Reached only through the set table $A0C4 (the word at $A0CA) when the racking
; $9F6F racks frame 7 or 8 (or 19-20 after the wrap). No recording read a byte
; (l1sum.py --reads A1E4-A701: game, w1, f1, p2, v1, m1 all zero; w1, the
; longest game, reached frame 4). Known only from the code; every script
; decodes cleanly and ends on its ball's rack position ($9D5D)
; (work/stage2/ann/04-scratch/racks.py).
RackSet3:
  DEFW Rack3Ball1,Rack3Ball2,Rack3Ball3,Rack3Ball4,Rack3Ball5,Rack3Ball6

; The scripts of rack-in set 3, ball 6 first
;
; The six scripts of set 3 (commands: 0 end, 1 x y place, 2 n dx dy move n
; frames by dx,dy, 3 n wait n frames; see RackSet1). Interpreted by the racking
; step $A05E.
Rack3Ball6:
  DEFB $03,$00            ; ball 6: wait 0 frames
  DEFB $01,$F8,$AF        ; place at (248, 175)
  DEFB $02,$22,$FE,$FE    ; move 34 frames by (-2, -2)
  DEFB $02,$3B,$FE,$00    ; move 59 frames by (-2, +0)
  DEFB $02,$0D,$FE,$02    ; move 13 frames by (-2, +2)
  DEFB $02,$04,$FE,$00    ; move 4 frames by (-2, +0)
  DEFB $02,$09,$00,$FE    ; move 9 frames by (+0, -2)
  DEFB $02,$48,$02,$00    ; move 72 frames by (+2, +0)
  DEFB $02,$11,$02,$01    ; move 17 frames by (+2, +1)
  DEFB $02,$08,$02,$00    ; move 8 frames by (+2, +0)
  DEFB $01,$DD,$84        ; place at (221, 132)
  DEFB $00                ; end
Rack3Ball4:
  DEFB $03,$16            ; ball 4: wait 22 frames
  DEFB $01,$F8,$AF        ; place at (248, 175)
  DEFB $02,$22,$FE,$FE    ; move 34 frames by (-2, -2)
  DEFB $02,$25,$FE,$00    ; move 37 frames by (-2, +0)
  DEFB $02,$0D,$FE,$02    ; move 13 frames by (-2, +2)
  DEFB $02,$1A,$FE,$00    ; move 26 frames by (-2, +0)
  DEFB $02,$09,$00,$FE    ; move 9 frames by (+0, -2)
  DEFB $02,$32,$02,$00    ; move 50 frames by (+2, +0)
  DEFB $02,$11,$02,$FF    ; move 17 frames by (+2, -1)
  DEFB $02,$1E,$02,$00    ; move 30 frames by (+2, +0)
  DEFB $01,$DD,$62        ; place at (221, 98)
  DEFB $00                ; end
Rack3Ball2:
  DEFB $03,$2C            ; ball 2: wait 44 frames
  DEFB $01,$F8,$AF        ; place at (248, 175)
  DEFB $02,$22,$FE,$FE    ; move 34 frames by (-2, -2)
  DEFB $02,$0F,$FE,$00    ; move 15 frames by (-2, +0)
  DEFB $02,$0D,$FE,$02    ; move 13 frames by (-2, +2)
  DEFB $02,$30,$FE,$00    ; move 48 frames by (-2, +0)
  DEFB $02,$09,$00,$FE    ; move 9 frames by (+0, -2)
  DEFB $02,$14,$02,$00    ; move 20 frames by (+2, +0)
  DEFB $02,$09,$02,$FF    ; move 9 frames by (+2, -1)
  DEFB $02,$3C,$02,$00    ; move 60 frames by (+2, +0)
  DEFB $01,$CD,$6A        ; place at (205, 106)
  DEFB $00                ; end
Rack3Ball5:
  DEFB $03,$0B            ; ball 5: wait 11 frames
  DEFB $01,$F8,$37        ; place at (248, 55)
  DEFB $02,$22,$FE,$02    ; move 34 frames by (-2, +2)
  DEFB $02,$30,$FE,$00    ; move 48 frames by (-2, +0)
  DEFB $02,$0D,$FE,$FE    ; move 13 frames by (-2, -2)
  DEFB $02,$0F,$FE,$00    ; move 15 frames by (-2, +0)
  DEFB $02,$09,$00,$02    ; move 9 frames by (+0, +2)
  DEFB $02,$61,$02,$00    ; move 97 frames by (+2, +0)
  DEFB $01,$DD,$73        ; place at (221, 115)
  DEFB $00                ; end
Rack3Ball3:
  DEFB $03,$21            ; ball 3: wait 33 frames
  DEFB $01,$F8,$37        ; place at (248, 55)
  DEFB $02,$22,$FE,$02    ; move 34 frames by (-2, +2)
  DEFB $02,$1A,$FE,$00    ; move 26 frames by (-2, +0)
  DEFB $02,$0D,$FE,$FE    ; move 13 frames by (-2, -2)
  DEFB $02,$25,$FE,$00    ; move 37 frames by (-2, +0)
  DEFB $02,$09,$00,$02    ; move 9 frames by (+0, +2)
  DEFB $02,$1F,$02,$00    ; move 31 frames by (+2, +0)
  DEFB $02,$09,$02,$01    ; move 9 frames by (+2, +1)
  DEFB $02,$31,$02,$00    ; move 49 frames by (+2, +0)
  DEFB $01,$CD,$7C        ; place at (205, 124)
  DEFB $00                ; end
Rack3Ball1:
  DEFB $03,$37            ; ball 1: wait 55 frames
  DEFB $01,$F8,$37        ; place at (248, 55)
  DEFB $02,$22,$FE,$02    ; move 34 frames by (-2, +2)
  DEFB $02,$04,$FE,$00    ; move 4 frames by (-2, +0)
  DEFB $02,$0D,$FE,$FE    ; move 13 frames by (-2, -2)
  DEFB $02,$3B,$FE,$00    ; move 59 frames by (-2, +0)
  DEFB $02,$09,$00,$02    ; move 9 frames by (+0, +2)
  DEFB $02,$51,$02,$00    ; move 81 frames by (+2, +0)
  DEFB $01,$BE,$73        ; place at (190, 115)
  DEFB $00                ; end

; Rack-in set 4: the script of each object ball 1-6, the frames 9-10 rack
;
; Reached only through the set table $A0C4 (the word at $A0CC) when the racking
; $9F6F racks frame 9 or 10 (or 21-22 after the wrap). No recording read a byte
; (l1sum.py --reads A1E4-A701: game, w1, f1, p2, v1, m1 all zero; w1, the
; longest game, reached frame 4). Known only from the code; every script
; decodes cleanly and ends on its ball's rack position ($9D5D)
; (work/stage2/ann/04-scratch/racks.py).
RackSet4:
  DEFW Rack4Ball1,Rack4Ball2,Rack4Ball3,Rack4Ball4,Rack4Ball5,Rack4Ball6

; The scripts of rack-in set 4, ball 5 first
;
; The six scripts of set 4 (commands: 0 end, 1 x y place, 2 n dx dy move n
; frames by dx,dy, 3 n wait n frames; see RackSet1). Interpreted by the racking
; step $A05E.
Rack4Ball5:
  DEFB $03,$00            ; ball 5: wait 0 frames
  DEFB $01,$F8,$AF        ; place at (248, 175)
  DEFB $02,$08,$FE,$FE    ; move 8 frames by (-2, -2)
  DEFB $02,$2C,$00,$FE    ; move 44 frames by (+0, -2)
  DEFB $02,$01,$00,$FF    ; move 1 frames by (+0, -1)
  DEFB $02,$67,$FE,$00    ; move 103 frames by (-2, +0)
  DEFB $02,$09,$00,$02    ; move 9 frames by (+0, +2)
  DEFB $02,$33,$02,$00    ; move 51 frames by (+2, +0)
  DEFB $02,$01,$01,$00    ; move 1 frames by (+1, +0)
  DEFB $03,$5A            ; wait 90 frames
  DEFB $02,$1B,$01,$00    ; move 27 frames by (+1, +0)
  DEFB $02,$1B,$00,$01    ; move 27 frames by (+0, +1)
  DEFB $03,$12            ; wait 18 frames
  DEFB $03,$2C            ; wait 44 frames
  DEFB $02,$21,$02,$00    ; move 33 frames by (+2, +0)
  DEFB $01,$DD,$73        ; place at (221, 115)
  DEFB $00                ; end
Rack4Ball2:
  DEFB $03,$12            ; ball 2: wait 18 frames
  DEFB $01,$07,$37        ; place at (7, 55)
  DEFB $02,$09,$02,$02    ; move 9 frames by (+2, +2)
  DEFB $02,$19,$00,$02    ; move 25 frames by (+0, +2)
  DEFB $02,$01,$00,$01    ; move 1 frames by (+0, +1)
  DEFB $02,$67,$02,$00    ; move 103 frames by (+2, +0)
  DEFB $02,$09,$00,$FE    ; move 9 frames by (+0, -2)
  DEFB $02,$33,$FE,$00    ; move 51 frames by (-2, +0)
  DEFB $03,$90            ; wait 144 frames
  DEFB $02,$09,$FF,$00    ; move 9 frames by (-1, +0)
  DEFB $02,$09,$00,$01    ; move 9 frames by (+0, +1)
  DEFB $03,$4F            ; wait 79 frames
  DEFB $02,$09,$00,$FF    ; move 9 frames by (+0, -1)
  DEFB $02,$09,$FF,$00    ; move 9 frames by (-1, +0)
  DEFB $02,$2F,$02,$00    ; move 47 frames by (+2, +0)
  DEFB $01,$CD,$6A        ; place at (205, 106)
  DEFB $00                ; end
Rack4Ball1:
  DEFB $03,$24            ; ball 1: wait 36 frames
  DEFB $01,$07,$37        ; place at (7, 55)
  DEFB $02,$09,$02,$02    ; move 9 frames by (+2, +2)
  DEFB $02,$07,$00,$02    ; move 7 frames by (+0, +2)
  DEFB $02,$01,$00,$01    ; move 1 frames by (+0, +1)
  DEFB $02,$67,$02,$00    ; move 103 frames by (+2, +0)
  DEFB $02,$09,$00,$FE    ; move 9 frames by (+0, -2)
  DEFB $02,$33,$FE,$00    ; move 51 frames by (-2, +0)
  DEFB $02,$2D,$FF,$00    ; move 45 frames by (-1, +0)
  DEFB $02,$2D,$00,$01    ; move 45 frames by (+0, +1)
  DEFB $03,$48            ; wait 72 frames
  DEFB $03,$91            ; wait 145 frames
  DEFB $02,$35,$02,$00    ; move 53 frames by (+2, +0)
  DEFB $01,$BE,$73        ; place at (190, 115)
  DEFB $00                ; end
Rack4Ball3:
  DEFB $03,$00            ; ball 3: wait 0 frames
  DEFB $01,$07,$37        ; place at (7, 55)
  DEFB $02,$09,$02,$02    ; move 9 frames by (+2, +2)
  DEFB $02,$2B,$00,$02    ; move 43 frames by (+0, +2)
  DEFB $02,$01,$00,$01    ; move 1 frames by (+0, +1)
  DEFB $02,$67,$02,$00    ; move 103 frames by (+2, +0)
  DEFB $02,$09,$00,$FE    ; move 9 frames by (+0, -2)
  DEFB $02,$33,$FE,$00    ; move 51 frames by (-2, +0)
  DEFB $03,$5A            ; wait 90 frames
  DEFB $02,$1B,$FF,$00    ; move 27 frames by (-1, +0)
  DEFB $02,$1B,$00,$FF    ; move 27 frames by (+0, -1)
  DEFB $03,$12            ; wait 18 frames
  DEFB $03,$4E            ; wait 78 frames
  DEFB $02,$09,$00,$01    ; move 9 frames by (+0, +1)
  DEFB $02,$09,$01,$00    ; move 9 frames by (+1, +0)
  DEFB $02,$01,$01,$00    ; move 1 frames by (+1, +0)
  DEFB $02,$2E,$02,$00    ; move 46 frames by (+2, +0)
  DEFB $01,$CD,$7C        ; place at (205, 124)
  DEFB $00                ; end
Rack4Ball6:
  DEFB $03,$12            ; ball 6: wait 18 frames
  DEFB $01,$F8,$AF        ; place at (248, 175)
  DEFB $02,$08,$FE,$FE    ; move 8 frames by (-2, -2)
  DEFB $02,$1A,$00,$FE    ; move 26 frames by (+0, -2)
  DEFB $02,$01,$00,$FF    ; move 1 frames by (+0, -1)
  DEFB $02,$67,$FE,$00    ; move 103 frames by (-2, +0)
  DEFB $02,$09,$00,$02    ; move 9 frames by (+0, +2)
  DEFB $02,$33,$02,$00    ; move 51 frames by (+2, +0)
  DEFB $02,$01,$01,$00    ; move 1 frames by (+1, +0)
  DEFB $03,$90            ; wait 144 frames
  DEFB $02,$09,$01,$00    ; move 9 frames by (+1, +0)
  DEFB $02,$09,$00,$FF    ; move 9 frames by (+0, -1)
  DEFB $03,$0A            ; wait 10 frames
  DEFB $02,$11,$00,$01    ; move 17 frames by (+0, +1)
  DEFB $02,$12,$01,$00    ; move 18 frames by (+1, +0)
  DEFB $02,$01,$01,$00    ; move 1 frames by (+1, +0)
  DEFB $02,$20,$02,$00    ; move 32 frames by (+2, +0)
  DEFB $01,$DD,$84        ; place at (221, 132)
  DEFB $00                ; end
Rack4Ball4:
  DEFB $03,$24            ; ball 4: wait 36 frames
  DEFB $01,$F8,$AF        ; place at (248, 175)
  DEFB $02,$08,$FE,$FE    ; move 8 frames by (-2, -2)
  DEFB $02,$08,$00,$FE    ; move 8 frames by (+0, -2)
  DEFB $02,$01,$00,$FF    ; move 1 frames by (+0, -1)
  DEFB $02,$67,$FE,$00    ; move 103 frames by (-2, +0)
  DEFB $02,$09,$00,$02    ; move 9 frames by (+0, +2)
  DEFB $02,$33,$02,$00    ; move 51 frames by (+2, +0)
  DEFB $02,$01,$01,$00    ; move 1 frames by (+1, +0)
  DEFB $02,$2D,$01,$00    ; move 45 frames by (+1, +0)
  DEFB $02,$2D,$00,$FF    ; move 45 frames by (+0, -1)
  DEFB $03,$48            ; wait 72 frames
  DEFB $03,$0A            ; wait 10 frames
  DEFB $02,$11,$00,$FF    ; move 17 frames by (+0, -1)
  DEFB $02,$12,$FF,$00    ; move 18 frames by (-1, +0)
  DEFB $02,$21,$02,$00    ; move 33 frames by (+2, +0)
  DEFB $01,$DD,$62        ; place at (221, 98)
  DEFB $00                ; end

; Rack-in set 5: the script of each object ball 1-6, the frames 11-12 rack
;
; Reached only through the set table $A0C4 (the word at $A0CE) when the racking
; $9F6F racks frame 11 or 12 (or 23-24 after the wrap). No recording read a
; byte (l1sum.py --reads A1E4-A701: game, w1, f1, p2, v1, m1 all zero; w1, the
; longest game, reached frame 4). Known only from the code; every script
; decodes cleanly and ends on its ball's rack position ($9D5D)
; (work/stage2/ann/04-scratch/racks.py).
RackSet5:
  DEFW Rack5Ball1,Rack5Ball2,Rack5Ball3,Rack5Ball4,Rack5Ball5,Rack5Ball6

; The scripts of rack-in set 5, ball 1 first
;
; The six scripts of set 5 (commands: 0 end, 1 x y place, 2 n dx dy move n
; frames by dx,dy, 3 n wait n frames; see RackSet1). Interpreted by the racking
; step $A05E.
Rack5Ball1:
  DEFB $03,$37            ; ball 1: wait 55 frames
  DEFB $01,$08,$38        ; place at (8, 56)
  DEFB $02,$1D,$02,$02    ; move 29 frames by (+2, +2)
  DEFB $02,$3C,$02,$00    ; move 60 frames by (+2, +0)
  DEFB $02,$1E,$02,$02    ; move 30 frames by (+2, +2)
  DEFB $01,$F7,$AF        ; place at (247, 175)
  DEFB $01,$80,$38        ; place at (128, 56)
  DEFB $02,$1D,$00,$02    ; move 29 frames by (+0, +2)
  DEFB $02,$1E,$02,$00    ; move 30 frames by (+2, +0)
  DEFB $02,$01,$01,$00    ; move 1 frames by (+1, +0)
  DEFB $02,$1C,$02,$FE    ; move 28 frames by (+2, -2)
  DEFB $01,$F7,$38        ; place at (247, 56)
  DEFB $01,$08,$AF        ; place at (8, 175)
  DEFB $02,$1E,$02,$FE    ; move 30 frames by (+2, -2)
  DEFB $02,$1E,$02,$00    ; move 30 frames by (+2, +0)
  DEFB $02,$1E,$00,$02    ; move 30 frames by (+0, +2)
  DEFB $01,$80,$AF        ; place at (128, 175)
  DEFB $01,$08,$38        ; place at (8, 56)
  DEFB $02,$1D,$02,$02    ; move 29 frames by (+2, +2)
  DEFB $02,$01,$01,$01    ; move 1 frames by (+1, +1)
  DEFB $02,$3D,$02,$00    ; move 61 frames by (+2, +0)
  DEFB $01,$BE,$73        ; place at (190, 115)
  DEFB $00                ; end
Rack5Ball2:
  DEFB $03,$2C            ; ball 2: wait 44 frames
  DEFB $01,$08,$38        ; place at (8, 56)
  DEFB $02,$1D,$02,$02    ; move 29 frames by (+2, +2)
  DEFB $02,$3C,$02,$00    ; move 60 frames by (+2, +0)
  DEFB $02,$1E,$02,$02    ; move 30 frames by (+2, +2)
  DEFB $01,$F7,$AF        ; place at (247, 175)
  DEFB $01,$80,$38        ; place at (128, 56)
  DEFB $02,$1D,$00,$02    ; move 29 frames by (+0, +2)
  DEFB $02,$1E,$02,$00    ; move 30 frames by (+2, +0)
  DEFB $02,$01,$01,$00    ; move 1 frames by (+1, +0)
  DEFB $02,$1C,$02,$FE    ; move 28 frames by (+2, -2)
  DEFB $01,$F7,$38        ; place at (247, 56)
  DEFB $01,$08,$AF        ; place at (8, 175)
  DEFB $02,$1E,$02,$FE    ; move 30 frames by (+2, -2)
  DEFB $02,$1E,$02,$00    ; move 30 frames by (+2, +0)
  DEFB $02,$1E,$00,$02    ; move 30 frames by (+0, +2)
  DEFB $01,$80,$AF        ; place at (128, 175)
  DEFB $01,$08,$38        ; place at (8, 56)
  DEFB $02,$1D,$02,$02    ; move 29 frames by (+2, +2)
  DEFB $02,$01,$01,$01    ; move 1 frames by (+1, +1)
  DEFB $02,$3D,$02,$00    ; move 61 frames by (+2, +0)
  DEFB $02,$04,$02,$FE    ; move 4 frames by (+2, -2)
  DEFB $02,$03,$02,$00    ; move 3 frames by (+2, +0)
  DEFB $01,$CD,$6A        ; place at (205, 106)
  DEFB $00                ; end
Rack5Ball3:
  DEFB $03,$21            ; ball 3: wait 33 frames
  DEFB $01,$08,$38        ; place at (8, 56)
  DEFB $02,$1D,$02,$02    ; move 29 frames by (+2, +2)
  DEFB $02,$3C,$02,$00    ; move 60 frames by (+2, +0)
  DEFB $02,$1E,$02,$02    ; move 30 frames by (+2, +2)
  DEFB $01,$F7,$AF        ; place at (247, 175)
  DEFB $01,$80,$38        ; place at (128, 56)
  DEFB $02,$1D,$00,$02    ; move 29 frames by (+0, +2)
  DEFB $02,$1E,$02,$00    ; move 30 frames by (+2, +0)
  DEFB $02,$01,$01,$00    ; move 1 frames by (+1, +0)
  DEFB $02,$1C,$02,$FE    ; move 28 frames by (+2, -2)
  DEFB $01,$F7,$38        ; place at (247, 56)
  DEFB $01,$08,$AF        ; place at (8, 175)
  DEFB $02,$1E,$02,$FE    ; move 30 frames by (+2, -2)
  DEFB $02,$1E,$02,$00    ; move 30 frames by (+2, +0)
  DEFB $02,$1E,$00,$02    ; move 30 frames by (+0, +2)
  DEFB $01,$80,$AF        ; place at (128, 175)
  DEFB $01,$08,$38        ; place at (8, 56)
  DEFB $02,$1D,$02,$02    ; move 29 frames by (+2, +2)
  DEFB $02,$01,$01,$01    ; move 1 frames by (+1, +1)
  DEFB $02,$3D,$02,$00    ; move 61 frames by (+2, +0)
  DEFB $02,$04,$02,$02    ; move 4 frames by (+2, +2)
  DEFB $02,$03,$02,$00    ; move 3 frames by (+2, +0)
  DEFB $01,$CD,$7C        ; place at (205, 124)
  DEFB $00                ; end
Rack5Ball4:
  DEFB $03,$16            ; ball 4: wait 22 frames
  DEFB $01,$08,$38        ; place at (8, 56)
  DEFB $02,$1D,$02,$02    ; move 29 frames by (+2, +2)
  DEFB $02,$3C,$02,$00    ; move 60 frames by (+2, +0)
  DEFB $02,$1E,$02,$02    ; move 30 frames by (+2, +2)
  DEFB $01,$F7,$AF        ; place at (247, 175)
  DEFB $01,$80,$38        ; place at (128, 56)
  DEFB $02,$1D,$00,$02    ; move 29 frames by (+0, +2)
  DEFB $02,$1E,$02,$00    ; move 30 frames by (+2, +0)
  DEFB $02,$01,$01,$00    ; move 1 frames by (+1, +0)
  DEFB $02,$1C,$02,$FE    ; move 28 frames by (+2, -2)
  DEFB $01,$F7,$38        ; place at (247, 56)
  DEFB $01,$08,$AF        ; place at (8, 175)
  DEFB $02,$1E,$02,$FE    ; move 30 frames by (+2, -2)
  DEFB $02,$1E,$02,$00    ; move 30 frames by (+2, +0)
  DEFB $02,$1E,$00,$02    ; move 30 frames by (+0, +2)
  DEFB $01,$80,$AF        ; place at (128, 175)
  DEFB $01,$08,$38        ; place at (8, 56)
  DEFB $02,$1D,$02,$02    ; move 29 frames by (+2, +2)
  DEFB $02,$01,$01,$01    ; move 1 frames by (+1, +1)
  DEFB $02,$3D,$02,$00    ; move 61 frames by (+2, +0)
  DEFB $02,$08,$02,$FE    ; move 8 frames by (+2, -2)
  DEFB $02,$07,$02,$00    ; move 7 frames by (+2, +0)
  DEFB $01,$DD,$62        ; place at (221, 98)
  DEFB $00                ; end
Rack5Ball5:
  DEFB $03,$0B            ; ball 5: wait 11 frames
  DEFB $01,$08,$38        ; place at (8, 56)
  DEFB $02,$1D,$02,$02    ; move 29 frames by (+2, +2)
  DEFB $02,$3C,$02,$00    ; move 60 frames by (+2, +0)
  DEFB $02,$1E,$02,$02    ; move 30 frames by (+2, +2)
  DEFB $01,$F7,$AF        ; place at (247, 175)
  DEFB $01,$80,$38        ; place at (128, 56)
  DEFB $02,$1D,$00,$02    ; move 29 frames by (+0, +2)
  DEFB $02,$1E,$02,$00    ; move 30 frames by (+2, +0)
  DEFB $02,$01,$01,$00    ; move 1 frames by (+1, +0)
  DEFB $02,$1C,$02,$FE    ; move 28 frames by (+2, -2)
  DEFB $01,$F7,$38        ; place at (247, 56)
  DEFB $01,$08,$AF        ; place at (8, 175)
  DEFB $02,$1E,$02,$FE    ; move 30 frames by (+2, -2)
  DEFB $02,$1E,$02,$00    ; move 30 frames by (+2, +0)
  DEFB $02,$1E,$00,$02    ; move 30 frames by (+0, +2)
  DEFB $01,$80,$AF        ; place at (128, 175)
  DEFB $01,$08,$38        ; place at (8, 56)
  DEFB $02,$1D,$02,$02    ; move 29 frames by (+2, +2)
  DEFB $02,$01,$01,$01    ; move 1 frames by (+1, +1)
  DEFB $02,$3D,$02,$00    ; move 61 frames by (+2, +0)
  DEFB $02,$0F,$02,$00    ; move 15 frames by (+2, +0)
  DEFB $01,$DD,$73        ; place at (221, 115)
  DEFB $00                ; end
Rack5Ball6:
  DEFB $03,$00            ; ball 6: wait 0 frames
  DEFB $01,$08,$38        ; place at (8, 56)
  DEFB $02,$1D,$02,$02    ; move 29 frames by (+2, +2)
  DEFB $02,$3C,$02,$00    ; move 60 frames by (+2, +0)
  DEFB $02,$1E,$02,$02    ; move 30 frames by (+2, +2)
  DEFB $01,$F7,$AF        ; place at (247, 175)
  DEFB $01,$80,$38        ; place at (128, 56)
  DEFB $02,$1D,$00,$02    ; move 29 frames by (+0, +2)
  DEFB $02,$1E,$02,$00    ; move 30 frames by (+2, +0)
  DEFB $02,$01,$01,$00    ; move 1 frames by (+1, +0)
  DEFB $02,$1C,$02,$FE    ; move 28 frames by (+2, -2)
  DEFB $01,$F7,$38        ; place at (247, 56)
  DEFB $01,$08,$AF        ; place at (8, 175)
  DEFB $02,$1E,$02,$FE    ; move 30 frames by (+2, -2)
  DEFB $02,$1E,$02,$00    ; move 30 frames by (+2, +0)
  DEFB $02,$1E,$00,$02    ; move 30 frames by (+0, +2)
  DEFB $01,$80,$AF        ; place at (128, 175)
  DEFB $01,$08,$38        ; place at (8, 56)
  DEFB $02,$1D,$02,$02    ; move 29 frames by (+2, +2)
  DEFB $02,$01,$01,$01    ; move 1 frames by (+1, +1)
  DEFB $02,$3D,$02,$00    ; move 61 frames by (+2, +0)
  DEFB $02,$08,$02,$02    ; move 8 frames by (+2, +2)
  DEFB $02,$07,$02,$00    ; move 7 frames by (+2, +0)
  DEFB $01,$DD,$84        ; place at (221, 132)
  DEFB $00                ; end
