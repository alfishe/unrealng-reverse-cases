# "nee.bas": the editor's main program (TZX block 34-35, 13625 bytes, LINE 1, no variables). docs/02 (editor),
# docs/05-controls.md, docs/08-hud-and-text.md. Built by tools/zxbasic.py (the format is in its docstring).
#
# The saved game it edits is the game's own save (NE SaveGame $C28D: 2 bytes, then $24D1 = 9425 bytes from $D92B):
# nee.mix loads the 2-byte checksum at $9858 (PEEK 39000) and the 9425-byte block at $9C40-$C110. Every game
# address A of the block is A - $3CEB (15595) here:
#
#   editor        game                         what (NE src/game/game.ann)
#   40000 $9C40   $D92B SaveShots              5 records of 9 bytes
#   40045 $9C6D   $D958 SaveBuildings          56 records of 3: map cell address (game's), type
#   40981 $A015   $DD00 Map                    16 rows of 512 cells, cell = Map + 512 * row + column
#   49207 $C037   $FD22 Resources              human: general, electronics, nuclear, phasers, missiles, cannon, chassis
#   49226 $C04A   $FD35 Clock (4) + PanelBusy  zeroed before a save (line 15)
#   49231 $C04F   $FD3A PlayerBuildings        human warbases, then factories by type
#   49239 $C057   $FD42 EnemyBuildings         insignian, the same order
#   49247 $C05F   $FD4A EnemyResources         insignian resources
#   49285 $C085   $FD70 Warbases               4 records of 5: X (2), Y, owner + type, door turns
#   49305 $C099   $FD84 Factories              24 records of 5, the same shape
#
# Variables: Q(7,4) the status table (rows: warbases, then the six factory types; columns: human, insignian,
# neutral, available), FA the factories still available, DA the map address at the screen's left column (page),
# MP the map page 1-24, CB the selected block (2-18, the UDG set at 50419 + 32 * (CB - 2)), CX / CY the cursor
# (column 1-29, row 1-15), CA the map address under the cursor, I$ the key, I / P / N / T / P1 scratch.
# Keys are read with PAUSE 0 and INKEY$: Sinclair 2 (6 7 8 9 0) moves the cursor and puts, Sinclair 1 (1-5) selects
# the block, moves the map and deletes.


# Start: the error trap (machine code in this line's REM, src/basic/nee-rem.asm), CHARS = 51220 (the font of
# nee.mix at 51476 = 51220 + 256), then straight into LOAD FILE (GO SUB 8): the saved game follows nee.bas on tape.
1 RANDOMIZE USR 23830: POKE 23606,20: POKE 23607,200: CLS : GO SUB 8: REM {<nee-rem.bin}

# The main menu.
2 CLS : PRINT "{14}{01}    N E T H E R    E A R T H            E  D  I  T  O  R        {14}{00}"''"{7F} 1996  V.O.software"''''''"{14}{01}1{14}{00} - LOAD FILE"''"{14}{01}2{14}{00} - SAVE FILE"''"{14}{01}3{14}{00} - EDIT MAP"''"{14}{01}4{14}{00} - EDIT RESOURCES"

# Menu keys: 1 load, 2 save, 3 the map editor, 4 the resources. PAUSE 0 then INKEY$.
3 PAUSE 0: LET I$= INKEY$ : IF I$="1" THEN GO SUB 8: GO TO 3
4 IF I$="2" THEN GO SUB 11: GO TO 3
5 IF I$="3" THEN GO SUB 16: GO TO 2
6 IF I$="4" THEN GO SUB 133: GO TO 2
7 GO TO 3

# LOAD FILE: nee.mix 50000 (LD-BYTES, the 2-byte block to $9858) and 50013 (the 9425-byte block to $9C40), then the
# status table (GO SUB 9). PRINT # BIN : print to stream 0 (BIN with no digits is 0 in a 6-byte number); INPUT BIN
# clears the lower screen. A tape error or BREAK lands at line 146 through the trap.
8 PRINT # BIN ;"Searching...": RANDOMIZE USR 50000: INPUT BIN : PRINT # BIN ;"Loading file...": RANDOMIZE USR 50013: INPUT BIN : PRINT # BIN ;"Processing...": GO SUB 9: INPUT BIN : BEEP .5,30: RETURN

# Count the buildings into Q(7,4): Q(i,1) / Q(i,2) from PlayerBuildings / EnemyBuildings; Q(i,3) the neutral ones
# (an owner+type byte below 7 in the Factories records: no owner bit); Q(i,4) what may still be placed: warbases up
# to 4 in all, factories 9 a type and 24 in all (FA what is left of the 24).
9 DIM Q(7,4): FOR I=1 TO 7: LET Q(I,1)= PEEK (49230+I): LET Q(I,2)= PEEK (49238+I): NEXT I: FOR I=49308 TO 49423 STEP 5: LET P= PEEK I: IF P<7 THEN LET Q(P+1,3)=Q(P+1,3)+1
10 NEXT I: LET Q(1,4)=4-Q(1,1)-Q(1,2): LET N=24: FOR I=2 TO 7: LET N=N-Q(I,1)-Q(I,2)-Q(I,3): NEXT I: FOR I=2 TO 7: LET P=9-Q(I,1)-Q(I,2)-Q(I,3): LET Q(I,4)=N*(N<P)+P*(N >= P): NEXT I: LET FA=N: RETURN

# SAVE FILE: refused without a human and an insignian warbase.
11 PRINT # BIN ;"Processing...": IF Q(1,1)=0 THEN INPUT BIN : PRINT # BIN ;"Human warbases needed": BEEP .5,0: PAUSE 50: INPUT BIN : RETURN
12 IF Q(1,2)=0 THEN INPUT BIN : PRINT # BIN ;"Insignians warbases needed": BEEP .5,0: PAUSE 50: INPUT BIN : RETURN

# Sort the Warbases records (lines 13-14), then the Factories (14-15), by their 16-bit X: a bubble sort over 5-byte
# records, swapping byte by byte (the game expects them in map order). Then the clock and PanelBusy to zero, the checksum (50052), the prompt, the two
# blocks saved (50026: 2 bytes, 50039: 9425 bytes, flag $00).
13 LET P1=49295: FOR P=1 TO 3: FOR I=49285 TO P1 STEP 5: LET N= PEEK I+256* PEEK (I+1): LET T= PEEK (I+5)+256* PEEK (I+6): IF N>T THEN FOR T=0 TO 4: LET N= PEEK (I+T): POKE I+T, PEEK (I+T+5): POKE I+T+5,N: NEXT T
14 NEXT I: LET P1=P1-5: NEXT P: LET P1=49415: FOR P=1 TO 23: FOR I=49305 TO P1 STEP 5: LET N= PEEK I+256* PEEK (I+1): LET T= PEEK (I+5)+256* PEEK (I+6): IF N>T THEN FOR T=0 TO 4: LET N= PEEK (I+T): POKE I+T, PEEK (I+T+5): POKE I+T+5,N: NEXT T
15 NEXT I: LET P1=P1-5: NEXT P: POKE 49226, BIN : POKE 49227, BIN : POKE 49228, BIN : POKE 49229, BIN : POKE 49230, BIN : RANDOMIZE USR 50052: INPUT BIN : PRINT # BIN ;"Start tape, then press any key": BEEP .5,30: PAUSE 0: INPUT BIN : PRINT # BIN ;"Saving file...": RANDOMIZE USR 50026: RANDOMIZE USR 50039: INPUT BIN : RETURN

# EDIT MAP: page 1, block 2 selected, the cursor at (1,1); the map drawn (GO SUB 33), the help, the cursor.
16 INK 2: CLS : LET DA=40996: LET MP=1: GO SUB 33: LET CB=2: LET CX=1: LET CY=1: LET CA=41509

# The help in rows 16-19 (INK 5, the key names INVERSE), the selected block (GO SUB 34), the cursor (GO SUB 36).
17 PRINT AT 16,0; INK 5;"{14}{01}SINC.2 J/S{14}{00}   {14}{01}SINC.1 J/S{14}{00}  {14}{01}S{14}{00}tatus {14}{01}l/r{14}{00}-select   {14}{01}l/r{14}{00}-move    {14}{01}W{14}{00}arbase{14}{01}u/d{14}{00}-move map {14}{01}u/d{14}{00} cursor  {14}{01}F{14}{00}actory{14}{01}fire{14}{00}-delete  {14}{01}fire{14}{00}-put {14}{01}SPACE{14}{00}-exit": GO SUB 34: GO SUB 36

# The editor's keys: 1/2 select, 3/4 page, 5 delete, 6/7 left/right, 8/9 down/up, 0 put, S status, W warbase,
# F factory, SPACE back to the menu (line 5 then redraws it).
18 PAUSE 0: LET I$= INKEY$ : IF I$="1" THEN GO SUB 39: GO TO 18
19 IF I$="2" THEN GO SUB 42: GO TO 18
20 IF I$="3" THEN GO SUB 45: GO TO 18
21 IF I$="4" THEN GO SUB 48: GO TO 18
22 IF I$="5" THEN GO SUB 51: GO TO 18
23 IF I$="6" THEN GO SUB 73: GO TO 18
24 IF I$="7" THEN GO SUB 76: GO TO 18
25 IF I$="8" THEN GO SUB 79: GO TO 18
26 IF I$="9" THEN GO SUB 82: GO TO 18
27 IF I$="0" THEN GO SUB 85: GO TO 18
28 IF I$="S" OR I$="s" THEN GO SUB 90: GO TO 17
29 IF I$="W" OR I$="w" THEN GO SUB 91: GO TO 18
30 IF I$="F" OR I$="f" THEN GO SUB 110: GO TO 18
31 IF I$=" " THEN RETURN
32 GO TO 18: PAUSE 0: STOP

# Draw the map page: DA into $C4E3 (nee.mix's map pointer, via RANDOMIZE and SEED), USR 50080 (DrawMap), the page.
33 RANDOMIZE DA: POKE 50403, PEEK 23670: POKE 50404, PEEK 23671: RANDOMIZE USR 50080: PRINT AT 21,0; INK 4;"MAP PAGE "; INK 7;MP;" ": RETURN

# Show the selected block in the lower screen: the UDG pointer (23675) at its four characters; blocks above 11 have a
# second variant (P + 224) for odd rows, shown too.
34 LET P=50419+(CB-2)*32: RANDOMIZE P: POKE 23675, PEEK 23670: POKE 23676, PEEK 23671: INPUT BIN : PRINT # BIN ; INK 4;; AT 1,0;"SELECTED"; PAPER 7; INK 0; AT 0,10;"{90}{91}"; AT 1,10;"{92}{93}": IF CB>11 THEN RANDOMIZE P+224: POKE 23675, PEEK 23670: POKE 23676, PEEK 23671: PRINT # BIN ; AT 0,13;"/"; AT 1,12;"/"; PAPER 7; INK 0; AT 0,14;"{90}{91}"; AT 1,14;"{92}{93}"
35 RETURN

# GO SUB 36: MILE (the cursor's map column / 2), then on into 37. GO SUB 37: the cursor toggled: two rows of two
# $8F full blocks with OVER 1 (drawn twice it is gone), INK 4 PAPER 0 on a map cell in the editor's colours
# (ATTR 56: black on white), else INK 0 PAPER 7. The REM in line 37 holds a tokenised copy of 36-37 as one line
# (an older version), never run.
36 PRINT AT 21,13; INK 4;"MILE "; INK 7;(DA-40995+cx)/2;"  "
37 PRINT INK 4*( ATTR (CY,CX)=56); PAPER 7*( ATTR (CY,CX) <> 56); OVER 1; AT CY-1,CX;"{8F}{8F}"; AT CY,CX;"{8F}{8F}": REM {F5}{AC}21,13;{D9}4;"MILE ";{D9}7;(DA-40995+cx)/2;"  ";{D9}2*({AB}(CY,CX)=56);{DA}7;{DE}1;{AC}CY-1,CX;"{8F}{8F}";{AC}CY,CX;"{8F}{8F}"
38 RETURN

# 1 / 2: the previous / next block, skipping 15-16 (the warbase and factory pieces placed only by W and F).
39 LET CB=CB-1: IF CB=16 THEN LET CB=14
40 IF CB=1 THEN LET CB=18
41 GO SUB 34: RETURN
42 LET CB=CB+1: IF CB=15 THEN LET CB=17
43 IF CB=19 THEN LET CB=2
44 GO SUB 34: RETURN

# 3 / 4: the map page back / on: 20 columns a page, 24 pages; the last one is cut to the map's end (41453).
45 IF DA=40996 THEN RETURN
46 LET DA=DA-20: IF DA<40996 THEN LET DA=40996: LET CA=CA+3
47 LET CA=CA-20: LET MP=MP-1: GO SUB 33: GO SUB 36: RETURN
48 IF DA=41453 THEN RETURN
49 LET DA=DA+20: IF DA>41453 THEN LET DA=41453: LET CA=CA-3
50 LET CA=CA+20: LET MP=MP+1: GO SUB 33: GO SUB 36: RETURN

# 5 (delete): a warbase or factory door (cell 80 or 16) goes to line 54; another building piece (2-18, not 15) is
# cleared with its 2x2 cells (line 53); anything else: Can not delete.
51 IF PEEK CA=80 OR PEEK CA=16 THEN GO TO 54
52 IF PEEK CA<2 OR PEEK CA>18 OR PEEK CA=15 THEN GO TO 72
53 POKE CA,0: POKE CA+1,0: POKE CA-512,0: POKE CA-511,0: PRINT PAPER 7; INK 0; AT CY,CX;"  "; AT CY-1,CX;"  ": GO SUB 36: RETURN

# Delete a building: find the capture point (Warbases or Factories) whose (X, Y) gives the cursor: X + 256 * X hi +
# 512 * Y + 39957 is the editor's cell of (X, Y) less 2 rows: a factory's door (N = 0) is there, a warbase's door
# (N = 1) 2 rows higher still. Its owner byte above 70 (destroyed): Can not delete. Else the record marked free
# (owner 128), the owner's
# count lowered, the footprint cleared (DATA 142 / 143) and the SaveBuildings entries that point at it removed (3 zero
# bytes): the pad (game cell = editor cell + 15595, type 0) and the owner's flag 4 / 2 cells left (+15591 / +15593,
# human) or right (+15599 / +15597, insignian) of the door. Insignian warbases have no pad entry (line 102).
54 PRINT # BIN ; AT 1,21;"Please wait": FOR I=49285 TO 49420 STEP 5: LET P= PEEK I+256* PEEK (I+1)+512* PEEK (I+2)+39957: LET N=0: IF P <> CA THEN LET P=P-1024: LET N=1: IF P <> CA THEN NEXT I: GO TO 72
55 LET P= PEEK (I+3): IF P>70 THEN GO TO 72
56 IF N=0 THEN GO TO 63
57 LET N=P: POKE I+3,128: LET P=49230+(N=64)+9*(N=32): LET P1=15591*(N=64)+15599*(N=32): POKE P, PEEK P-1: RESTORE 142: FOR P=1 TO 60: READ N: POKE CA+N,0: NEXT P: IF P1=15599 THEN GO TO 60
58 FOR I=40045 TO 40207 STEP 3: LET P= PEEK I+256* PEEK (I+1)-15595: IF P=CA THEN POKE I,0: POKE I+1,0: POKE I+2,0: GO TO 60
59 NEXT I
60 FOR I=40045 TO 40207 STEP 3: LET P= PEEK I+256* PEEK (I+1)-P1: IF P=CA THEN POKE I,0: POKE I+1,0: POKE I+2,0: GO TO 62
61 NEXT I
62 GO TO 71
63 LET N=P: POKE I+3,128: IF N<7 THEN LET P1=0: GO TO 66
64 LET N=N-32: IF N<7 THEN LET P1=15597: LET P=49239+N: POKE P, PEEK P-1: GO TO 66
65 LET N=N-32: LET P1=15593: LET P=49231+N: POKE P, PEEK P-1
66 RESTORE 143: FOR P=1 TO 20: READ N: POKE CA+N,0: NEXT P: FOR I=40045 TO 40207 STEP 3: LET P= PEEK I+256* PEEK (I+1)-15595: IF P=CA THEN POKE I,0: POKE I+1,0: POKE I+2,0: GO TO 68
67 NEXT I
68 IF P1=0 THEN GO TO 71
69 FOR I=40045 TO 40207 STEP 3: LET P= PEEK I+256* PEEK (I+1)-P1: IF P=CA THEN POKE I,0: POKE I+1,0: POKE I+2,0: GO TO 71
70 NEXT I
71 GO SUB 9: RANDOMIZE USR 50080: GO SUB 36: GO SUB 34: RETURN

# Can not delete.
72 PRINT # BIN ; INK 2; AT 1,18;"Can not delete": BEEP .1,30: PAUSE 50: GO SUB 34: RETURN

# 6 / 7 / 8 / 9: the cursor left / right / down / up, repeated while the key is held. CA moves by 1 / 512.
73 IF CX=1 THEN RETURN
74 GO SUB 37: LET CX=CX-1: LET CA=CA-1: GO SUB 36: IF INKEY$ ="6" THEN GO TO 73
75 RETURN
76 IF CX=29 THEN RETURN
77 GO SUB 37: LET CX=CX+1: LET CA=CA+1: GO SUB 36: IF INKEY$ ="7" THEN GO TO 76
78 RETURN
79 IF CY=15 THEN RETURN
80 GO SUB 37: LET CY=CY+1: LET CA=CA+512: GO SUB 37: IF INKEY$ ="8" THEN GO TO 79
81 RETURN
82 IF CY=1 THEN RETURN
83 GO SUB 37: LET CY=CY-1: LET CA=CA-512: GO SUB 37: IF INKEY$ ="9" THEN GO TO 82
84 RETURN

# 0 (put): over a block piece (2-18, not 15 or 16) or on four empty cells; the cursor's cell gets CB, the one right of
# it and the two above CB + 32 (the 2x2 characters: UDG 2-3 in the cursor's row, 0-1 above). Else a beep.
85 IF PEEK CA>1 AND PEEK CA<19 AND PEEK CA <> 15 AND PEEK CA <> 16 THEN GO TO 88
86 IF PEEK CA=0 AND PEEK (CA+1)=0 AND PEEK (CA-512)=0 AND PEEK (CA-511)=0 THEN GO TO 88
87 BEEP .1,30: RETURN
88 POKE CA,CB: POKE CA+1,CB+32: POKE CA-512,CB+32: POKE CA-511,CB+32: LET P=50419+(CB-2)*32: IF CB>11 AND CY/2 <> INT (CY/2) THEN LET P=P+224
89 RANDOMIZE P: POKE 23675, PEEK 23670: POKE 23676, PEEK 23671: PRINT AT CY,CX; PAPER 7; INK 0;"{92}{93}"; AT CY-1,CX;"{90}{91}": GO SUB 36: RETURN

# S: the status table Q (GO SUB 9 made it), then the map again.
90 CLS : PRINT TAB 10;"{14}{01} S T A T U S {14}{00}"'' TAB 11;"{14}{01}HUMN{14}{00} {14}{01}INSG{14}{00} {14}{01}NEUTR{14}{00} {14}{01}AVAIL{14}{00}"''"WARBASES"''"ELECTRON'S"''"NUCLEAR"''"PHASERS"''"MISSILES"''"CANNON"''"CHASSIS": FOR I=1 TO 7: FOR P=1 TO 4: PRINT AT I*2+2,P*5+7;Q(I,P): NEXT P: NEXT I: PRINT AT 4,22;"-": PRINT # BIN ;"Press any key": PAUSE 0: CLS : GO SUB 33: RETURN

# W: a warbase. It needs one available, the cursor in rows 4-10 off the map's first columns, and its 60 footprint
# cells (DATA 142) empty; then its owner (1 human, 2 insignian, at most 3 each).
91 IF Q(1,4)=0 THEN PRINT # BIN ; INK 2; AT 0,21;"No warbases"; AT 1,21;"available": BEEP .1,30: PAUSE 50: GO SUB 34: RETURN
92 PRINT # BIN ; AT 1,21;"Please wait": IF CA<43049 OR CA>46598 OR (DA=40996 AND CX<5) THEN GO TO 108
93 RESTORE 142: FOR I=1 TO 60: READ N: IF PEEK (CA+N)>0 THEN GO TO 108
94 NEXT I: INPUT BIN : PRINT # BIN ; AT 0,0;"Select warbase status:"'"{14}{01}1{14}{00}-HUMN {14}{01}2{14}{00}-INSG"
95 PAUSE 0: LET I$= INKEY$ : IF I$="1" OR I$="2" THEN GO TO 97
96 GO TO 95
97 INPUT BIN : IF Q(1, VAL I$)=3 THEN PRINT # BIN ; INK 2;"Not available": BEEP .1,30: PAUSE 50: GO SUB 34: RETURN
98 INPUT BIN : PRINT # BIN ;"Please wait": IF I$="2" THEN GO TO 102

# Human warbase (99-101): the count up, the pad (type 0) at the door + 15595 and the flag (type 7) at + 15591, in
# the first free SaveBuildings records (address 0). Insignian (102-103): the count up, the flag (type 8) at + 15599
# only, no pad.
99 POKE 49231, PEEK 49231+1: FOR I=40045 TO 40207 STEP 3: IF PEEK I+ PEEK (I+1)=0 THEN RANDOMIZE CA+15595: POKE I, PEEK 23670: POKE I+1, PEEK 23671: POKE I+2,0: GO TO 101
100 NEXT I
101 LET P1=15591: GO TO 103
102 POKE 49239, PEEK 49239+1: LET P1=15599
103 FOR I=40045 TO 40207 STEP 3: IF PEEK I+ PEEK (I+1)=0 THEN RANDOMIZE CA+P1: POKE I, PEEK 23670: POKE I+1, PEEK 23671: POKE I+2,6+ VAL I$: GO TO 105
104 NEXT I

# The first free Warbases record (owner 128): (X, Y) from CA - 38933, 4 rows below the door; owner 64 (human) or 32
# (insignian).
105 FOR I=49285 TO 49300 STEP 5: IF PEEK (I+3)=128 THEN LET P=CA-38933: LET N= INT (P/512): POKE I+2,N: LET P=P-N*512: LET N= INT (P/256): POKE I+1,N: LET P=P-N*256: POKE I,P: POKE I+3,32*(3- VAL I$): GO TO 107
106 NEXT I

# The 15 pieces (DATA 144: offset, block) with their 2x2 cells, the door cells (80 for the owner, 16 for the other).
107 RESTORE 144: FOR I=1 TO 15: READ P,N: POKE CA+P,N: POKE CA+P+1,N+32: POKE CA+P-512,N+32: POKE CA+P-511,N+32: NEXT I: POKE CA,16*(I$="2")+80*(I$="1"): POKE CA-4,16*(I$="2")+80*(I$="1"): POKE CA+4,16*(I$="1")+80*(I$="2"): GO TO 109
108 PRINT # BIN ; INK 2; AT 0,19;"Can not place"; AT 1,19;"warbase here ": BEEP .1,30: PAUSE 50: GO SUB 34: RETURN
109 GO SUB 9: RANDOMIZE USR 50080: GO SUB 36: GO SUB 34: RETURN

# F: a factory: one available, its type (1-6) and owner (1 human, 2 insignian, 3 neutral), 20 empty cells (DATA 143).
110 IF FA=0 THEN PRINT # BIN ; INK 2; AT 0,21;"No factorys"; AT 1,21;"available": BEEP .1,30: PAUSE 50: GO SUB 34: RETURN
111 PRINT # BIN ; AT 1,21;"Please wait": IF CA<41511 OR CA>47112 OR (DA=40996 AND CX<3) THEN GO TO 131
112 RESTORE 143: FOR I=1 TO 20: READ N: IF PEEK (CA+N)>0 THEN GO TO 131
113 NEXT I: INPUT BIN : PRINT # BIN ; AT 0,0;"Select factory type:    {14}{01}1{14}{00}-ELE"'"{14}{01}2{14}{00}-NUC {14}{01}3{14}{00}-PHA {14}{01}4{14}{00}-MIS {14}{01}5{14}{00}-CAN {14}{01}6{14}{00}-CHA"
114 PAUSE 0: LET I$= INKEY$ : IF CODE I$>48 AND CODE I$<55 THEN GO TO 116
115 GO TO 114
116 LET T= VAL I$: INPUT BIN : IF Q(T+1,4)=0 THEN PRINT # BIN ; INK 2;"Not available": BEEP .1,30: PAUSE 50: GO SUB 34: RETURN
117 INPUT BIN : PRINT # BIN ; AT 0,0;"Select factory status:"'"{14}{01}1{14}{00}-HUMN {14}{01}2{14}{00}-INSG {14}{01}3{14}{00}-NEUTR"
118 PAUSE 0: LET I$= INKEY$ : IF CODE I$>48 AND CODE I$<52 THEN GO TO 120
119 GO TO 118
120 INPUT BIN : PRINT # BIN ;"Please wait": IF I$="3" THEN GO TO 126
121 IF I$="2" THEN GO TO 123
122 POKE 49231+T, PEEK (49231+T)+1: LET P1=15593: GO TO 124
123 POKE 49239+T, PEEK (49239+T)+1: LET P1=15597
124 FOR I=40045 TO 40207 STEP 3: IF PEEK I+ PEEK (I+1)=0 THEN RANDOMIZE CA+P1: POKE I, PEEK 23670: POKE I+1, PEEK 23671: POKE I+2,6+ VAL I$: GO TO 126
125 NEXT I
126 FOR I=40045 TO 40207 STEP 3: IF PEEK I+ PEEK (I+1)=0 THEN RANDOMIZE CA+15595: POKE I, PEEK 23670: POKE I+1, PEEK 23671: POKE I+2,T: GO TO 128
127 NEXT I

# The first free Factories record: (X, Y) from CA - 39957, 2 rows below the door; owner bits + type.
128 FOR I=49305 TO 49420 STEP 5: IF PEEK (I+3)=128 THEN LET P=CA-39957: LET N= INT (P/512): POKE I+2,N: LET P=P-N*512: LET N= INT (P/256): POKE I+1,N: LET P=P-N*256: POKE I,P: POKE I+3,32*(3- VAL I$)+T: GO TO 130
129 NEXT I

# The 5 pieces (DATA 145) and the door cells.
130 RESTORE 145: FOR I=1 TO 5: READ P,N: POKE CA+P,N: POKE CA+P+1,N+32: POKE CA+P-512,N+32: POKE CA+P-511,N+32: NEXT I: POKE CA,80: POKE CA-2,16*(I$ <> "1")+80*(I$="1"): POKE CA+2,16*(I$ <> "2")+80*(I$="2"): GO TO 132
131 PRINT # BIN ; INK 2; AT 0,19;"Can not place"; AT 1,19;"factory here ": BEEP .1,30: PAUSE 50: GO SUB 34: RETURN
132 GO SUB 9: RANDOMIZE USR 50080: GO SUB 36: GO SUB 34: RETURN

# EDIT RESOURCES: both sides' seven resources (PEEK 49207+k, 49247+k) with totals; each value under a flashing
# cursor: a number 0-99, or ENTER alone to keep it. INPUT LINE: a string, no expression.
133 CLS : PRINT TAB 7;"{14}{01} R E S O U R C E S {14}{00}"''"{14}{01}  HUMAN   {14}{00}"; TAB 22;"{14}{01}INSIGNIANS{14}{00}"'' TAB 10;"GENERAL"'' TAB 10;"ELECTRONICS"'' TAB 10;"NUCLEAR"'' TAB 10;"PHASERS"'' TAB 10;"MISSILES"'' TAB 10;"CANNON"'' TAB 10;"CHASSIS"'''' TAB 10;"TOTAL": LET TH=0: LET TI=0: FOR I=4 TO 16 STEP 2: LET P=(49207+(I-4)/2): LET TH=TH+ PEEK P: LET TI=TI+ PEEK (P+40): PRINT AT I,4; PEEK P; AT I,26; PEEK (P+40): NEXT I: PRINT AT 20,4;TH; AT 20,26;TI: FOR I=4 TO 16 STEP 2: PRINT AT I,4; OVER 1; FLASH 1;"{8F}{8F}"
134 INPUT "Input number 0 to 99     "; LINE I$: IF I$="" THEN PRINT AT I,4; OVER 1;"{8F}{8F}": NEXT I: GO TO 137
135 LET N= VAL I$: IF N<0 OR N>99 THEN GO TO 134
136 LET P=(49207+(I-4)/2): LET TH=TH- PEEK P+N: POKE P,N: PRINT AT I,4;N;" "; AT 20,4;TH;"  ": NEXT I
137 FOR I=4 TO 16 STEP 2: PRINT AT I,26; OVER 1; FLASH 1;"{8F}{8F}"
138 INPUT "Input number 0 to 99     "; LINE I$: IF I$="" THEN PRINT AT I,26; OVER 1;"{8F}{8F}": NEXT I: GO TO 141
139 LET N= VAL I$: IF N<0 OR N>99 THEN GO TO 138
140 LET P=(49247+(I-4)/2): LET TI=TI- PEEK P+N: POKE P,N: PRINT AT I,26;N;" "; AT 20,26;TI;"  ": NEXT I
141 PRINT # BIN ;"Press any key": PAUSE 0: RETURN

# The footprints: 142 a warbase's 60 cells, 143 a factory's 20 (offsets from the door cell; 512 a row).
142 DATA -2050,-2049,-2046,-2045,-1540,-1539,-1538,-1537,-1536,-1535,-1534,-1533,-1532,-1531,-1028,-1027,-1026,-1025,-1024,-1023,-1022,-1021,-1020,-1019,-516,-515,-514,-513,-512,-511,-510,-509,-508,-507,-4,-3,-2,-1,0,1,2,3,4,5,510,511,512,513,514,515,1022,1023,1024,1025,1026,1027,1534,1535,1538,1539
143 DATA -514,-513,-512,-511,-510,-509,-2,-1,0,1,2,3,510,511,514,515,1022,1023,1026,1027

# A warbase's 15 pieces and a factory's 5: (offset, block) pairs. Line 145 goes on after its DATA with a debug dump
# of SaveBuildings (address, type): no line jumps to 144-145 and 141 returns, so it never runs.
144 DATA -1538,16,-1534,16,-1028,16,-1024,16,-1020,16,-514,15,-510,15,-4,16,0,16,4,16,510,15,514,15,1024,15,1534,15,1538,15
145 DATA -2,16,0,16,2,16,1022,15,1026,15: FOR F=40045 TO 40207 STEP 3: PRINT PEEK F; TAB 5; PEEK (F+1); TAB 10; PEEK F+256* PEEK (F+1); TAB 20; PEEK (F+2): NEXT F

# The error trap's target (nee-rem.asm): ERROR, a key, the main menu.
146 CLS : PRINT AT 10,10;"{12}{01} E R R O R {12}{00}";# BIN ; TAB 8;"Press any key": BEEP .3,10: PAUSE BIN : GO TO 2
