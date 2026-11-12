; --------------------------------------------------------------------------------------------------------------------
; tune.asm: The tune: the ASC Sound Master module "Disco music" by Ant P
;
; One module in the ASC Sound Master 0.x layout from TuneHeader $C478 to the end of OrnamentData ($D592, 4379 bytes),
; the resource src/res/music/disco.txt (tools/res_music.py; the format in src/res/music/README.md). Delay 6 (a row
; every 6 frames), 22 positions playing 16 patterns (0-15; patterns 1, 3, 4, 5, 6 and 9 twice), 32 samples and 32
; ornaments, of which the streams use 1-10 and 13 (each sample with the ornament of its number).
;
; Length: the streams add up to 1294 rows (7764 frames), but a position starts as soon as all three channels have read
; their last event (PlayFrame $C117), and a channel whose last event still runs delays the next pattern's stream. So
; the first tune loop from MusicInit is 7704 frames (154.1 s: position 21, pattern 14, ends 10 rows early), and every
; later tune loop 7764 frames (155.3 s: position 0 waits those 10 rows, 96 frames instead of 36). Positions 3 (378
; frames), 9 (390), 19 (48) and 21 (324) are the odd lengths (python3 tools/sound_sim.py loop). c1 starts positions 0
; to 20 in its 7274 frames of music (1213 rows); c6 plays on into the third tune loop: position 0 restarts at frames
; 8249 and 16013 (TTD memory_at of PositionOp+1).
;
; Channels: A the melody (samples 1, 6, 7, 9, 10, 13; patterns 6-9 open on the envelope: sample 13 with E rows,
; envelope mode, shape 14, an envelope period after each note following its pitch), B the bass (samples 2 and 8,
; octave jumps), C the drums (samples 3, 4, 5 with noise rows and falling ornaments).
; --------------------------------------------------------------------------------------------------------------------

; The module's header: delay, the three table offsets, the number of positions
;
; Read by InitPlayer $C053: the delay (6), the pattern table (+$001E: $C496),
; the sample table (+$0BFC: $D074), the ornament table (+$1077: $D4EF), 22
; positions. No loop byte: NextPosition $C191 loops to position 0.
TuneHeader:
  INCBIN "res/music/disco.bin",$0000,8

; The 22 positions: the pattern of each
;
; 0 1 2 3 3 4 4 5 5 6 6 7 8 9 9 10 11 12 13 15 1 14. Read by NextPosition $C191
; (c1 reads positions 0-20).
TunePositions:
  INCBIN "res/music/disco.bin",$0008,22

; 16 patterns: the offsets of the streams of channels A, B and C from this
; table
;
; Read by NextPosition $C191 (6 x the pattern).
PatternTable:
  INCBIN "res/music/disco.bin",$001E,96

; The 48 channel streams (pattern 0 first): commands, events, $FF at each
; stream's end
;
; Read by ChannelRow $C1CE and PatternCommand $C24C. Pattern 14 (position 21)
; is read in no recording.
PatternData:
  INCBIN "res/music/disco.bin",$007E,21
Pattern1:
  INCBIN "res/music/disco.bin",$0093,211
Pattern2:
  INCBIN "res/music/disco.bin",$0166,206
Pattern3:
  INCBIN "res/music/disco.bin",$0234,198
Pattern4:
  INCBIN "res/music/disco.bin",$02FA,206
Pattern5:
  INCBIN "res/music/disco.bin",$03C8,256
Pattern6:
  INCBIN "res/music/disco.bin",$04C8,193
Pattern7:
  INCBIN "res/music/disco.bin",$0589,193
Pattern8:
  INCBIN "res/music/disco.bin",$064A,197
Pattern9:
  INCBIN "res/music/disco.bin",$070F,211
Pattern10:
  INCBIN "res/music/disco.bin",$07E2,210
Pattern11:
  INCBIN "res/music/disco.bin",$08B4,208
Pattern12:
  INCBIN "res/music/disco.bin",$0984,210
Pattern13:
  INCBIN "res/music/disco.bin",$0A56,210
Pattern14:
  INCBIN "res/music/disco.bin",$0B28,188
Pattern15:
  INCBIN "res/music/disco.bin",$0BE4,24

; 32 samples: their offsets from this table
;
; Read by TableEntry $C278 for a $80-$9F command.
SampleTable:
  INCBIN "res/music/disco.bin",$0BFC,64

; The samples (sample 0 first): rows of 3 bytes (flags and noise, tone delta,
; mixer and volume)
;
; Read by SampleStep $C308. Samples 0, 11, 12 and 14-31 are one row with S, L
; and X: a steady tone at volume 15 that loops on itself until a release ($7E),
; then ends. The streams use samples 1-10 and 13.
SampleData:
  INCBIN "res/music/disco.bin",$0C3C,3
Sample1:
  INCBIN "res/music/disco.bin",$0C3F,75
Sample2:
  INCBIN "res/music/disco.bin",$0C8A,48
Sample3:
  INCBIN "res/music/disco.bin",$0CBA,36
Sample4:
  INCBIN "res/music/disco.bin",$0CDE,18
Sample5:
  INCBIN "res/music/disco.bin",$0CF0,54
Sample6:
  INCBIN "res/music/disco.bin",$0D26,18
Sample7:
  INCBIN "res/music/disco.bin",$0D38,258
Sample8:
  INCBIN "res/music/disco.bin",$0E3A,18
Sample9:
  INCBIN "res/music/disco.bin",$0E4C,81
Sample10:
  INCBIN "res/music/disco.bin",$0E9D,84
Sample11:
  INCBIN "res/music/disco.bin",$0EF1,6
Sample13:
  INCBIN "res/music/disco.bin",$0EF7,330
Sample14:
  INCBIN "res/music/disco.bin",$1041,54

; 32 ornaments: their offsets from this table
;
; Read by TableEntry $C278 for an $A0-$BF command (through CommandOrnament
; $C26B).
OrnamentTable:
  INCBIN "res/music/disco.bin",$1077,64

; The ornaments (ornament 0 first): rows of 2 bytes (flags and noise, note
; delta)
;
; Read by OrnamentStep $C385. Ornaments 0, 2, 10 and 11-31 are one row of no
; change; the streams use 1-10 and 13.
OrnamentData:
  INCBIN "res/music/disco.bin",$10B7,2
Ornament1:
  INCBIN "res/music/disco.bin",$10B9,8
Ornament2:
  INCBIN "res/music/disco.bin",$10C1,2
Ornament3:
  INCBIN "res/music/disco.bin",$10C3,4
Ornament4:
  INCBIN "res/music/disco.bin",$10C7,8
Ornament5:
  INCBIN "res/music/disco.bin",$10CF,4
Ornament6:
  INCBIN "res/music/disco.bin",$10D3,6
Ornament7:
  INCBIN "res/music/disco.bin",$10D9,8
Ornament8:
  INCBIN "res/music/disco.bin",$10E1,6
Ornament9:
  INCBIN "res/music/disco.bin",$10E7,8
Ornament10:
  INCBIN "res/music/disco.bin",$10EF,2
Ornament11:
  INCBIN "res/music/disco.bin",$10F1,42

; 109 bytes after the module to the end of the 22nd sector: older stream bytes,
; not read
;
; Leftovers of the memory the compilation was saved from (they read like a
; pattern stream: $F0 $0C, notes, $7E, $FF, $85 $A5 $CF $D0 $F0 $01 ...). Known
; only from the code: the player's pointers end at $D592 and no instruction in
; c1-c4 reads these bytes.
SectorTail:
  INCBIN "res/spare/music-tail.bin",$0000,109
