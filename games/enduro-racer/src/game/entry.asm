; --------------------------------------------------------------------------------------------------------------------
; entry.asm: Mover, the entry, the IM 2 table and the 128K test
;
; The last tape block puts Mover at $5B00; LoadEnd ($FF7A, src/loader/tail.asm) jumps there. Mover's LDDR moves the 40
; 540 bytes $5BC4-$FA1F up by $5E0 to $61A4-$FFFF (the tape blocks were cut with that gap) and jumps to Start at
; $8000. Init sets I = $B2 and fills the IM 2 table $B200-$B300 with $64 (every vector reads $6464: JR Interrupt),
; copies the 13 record bytes to $5E00 and the 1456 bytes of track tables from $EB00 to $5E80 (the back buffer takes
; $EB00 after that), builds the bit-reverse table at $5D00, tests the ROM, and starts the attract loop.
;
; The work space below $6430 ($5B00-$642F) is overwritten before any read: the image's bytes there are leftovers
; (Mover, zeros, the LDDR's leftover, the image's old table bytes), and each entry is named after what the game keeps
; there.
;
; The 128K test is a checksum: the byte sum of the ROM's $3B00-$3BFF is $FE on the 48K ROM; then Beeper ($7C2F) = $FF
; and the engine sounds on the beeper, else 0 and the engine is an AY tone (m128: $7C2F = 0, the AY written by
; EngineSound).
; --------------------------------------------------------------------------------------------------------------------

; LDDR $5BC4-$FA1F up by $5E0 to $61A4-$FFFF, SP = $61A7, JP Start
;
; Loaded by tape block 15 (row 9 of BlockTable, src/loader/loader.asm) and
; entered by TailEnd's JP $5B00 at c1 frame 11632 (m128 too). DE = $FFFF, HL =
; $FA1F, BC = $9E5C (40 540), LDDR; SP = $61A7, the top of the gap the move
; leaves; JP Start. The entry image differs from the loaded one only by that
; move (doc 02, 2.2).
;
; Witness: L1 1379 (c1, m128).
Mover:
  LD DE,StackArea+$007F
  LD HL,$FA1F
  LD BC,$9E5C
  LDDR
  LD SP,$61A7
  JP Start

; The 47 bytes after Mover in tape block 15: the ROM font's letters F to K,
; never read
;
; Tape block 15 carries 64 bytes; Mover uses 17. $5B11-$5B3F are the Spectrum
; ROM's glyphs of F, G, H, I, J and K (ROM $3E31-$3E5F; the first row of F, a
; zero, falls on JP Start's last byte). The game writes RowList ($5B00) before
; it reads it; nothing reads these bytes as loaded (c1, m128). A leftover of
; the tape's cutting.
MoverTail:
  DEFB $7E,$40,$7C,$40,$40,$40,$00,$00
  DEFB $3C,$42,$40,$4E,$42,$3C,$00,$00
  DEFB $42,$42,$7E,$42,$42,$42,$00,$00
  DEFB $3E,$08,$08,$08,$08,$3E,$00,$00
  DEFB $02,$02,$02,$42,$42,$3C,$00,$00
  DEFB $44,$48,$70,$48,$44,$42,$00

; $5B40-$5B7F: zeros no tape block loads; the rest of RowList (RoadRowsMake
; writes it)
;
; RowList ($5B00-$5B7F, over Mover) is the list of the road's rows, each the
; RoadLines index of a drawn line, $FE a gap (GapRows), $FF the end;
; RoadRowsMake ($9DF1) writes it, DrawRoad reads it.
RowListTail:
  DEFS $40

; The bend row table, 128 bytes: each road row's x centre (the bend's sideways
; shift), built by ScrollBends / BlendBend
;
; In the image $5B80-$5BC7 are zeros (no block loads them) and $5BC8-$5BFF the
; start of the LDDR's leftover: an LDDR moving a block up leaves its first $5E0
; bytes where they were, so $5BC8-$61A3 still hold what is now at $61A8-$6783
; (entry.cpu.bin byte for byte; tools/parts.py rebuilds it so). ClearBendRows
; and the game overwrite all of $5B80-$642F before reading it.
BendRows:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $A0,$C8,$01,$01,$14,$0C,$A3,$C8
  DEFB $14,$EC,$12,$10,$A2,$C8,$14,$D6
  DEFB $A4,$3A,$13,$F6,$13,$32,$A2,$C8
  DEFB $10,$14,$14,$C8,$12,$F2,$11,$02
  DEFB $A1,$3A,$11,$26,$10,$D0,$13,$E2
  DEFB $11,$22,$12,$06,$A1,$C8,$12,$D3
  DEFB $11,$E8,$13,$18,$A2,$3A,$D0,$A7

; The screen line of each road row, 128 bytes ($70 + depth / 2): RoadRowsFlat,
; RoadRowsCrest, RoadRowsJump write it
;
; RoadLines' last entry ($5C7F) gives RoadTopRow = ($5C7F) - $71; all entries
; $70 (the road flat under a high jump) make RoadTopRow $FF (the stage 3 reset,
; leftovers section of NOTES).
RoadLines:
  DEFB $C8,$A7,$3A,$A7,$BC,$A7,$46,$C0
  DEFB $F6,$26,$C8,$23,$A0,$13,$3A,$26
  DEFB $3A,$23,$62,$13,$C8,$C0,$F2,$A4
  DEFB $C4,$A4,$3E,$A4,$CA,$A4,$38,$C0
  DEFB $F6,$AC,$C8,$A0,$3A,$C0,$FA,$A5
  DEFB $C8,$A5,$3A,$C0,$FA,$37,$32,$37
  DEFB $32,$37,$32,$37,$32,$40,$B8,$C0
  DEFB $F4,$64,$CA,$60,$4C,$62,$AA,$14
  DEFB $B9,$61,$38,$11,$58,$15,$43,$61
  DEFB $C8,$64,$B3,$61,$4F,$66,$38,$12
  DEFB $AD,$62,$C8,$15,$49,$61,$5B,$12
  DEFB $BF,$60,$B0,$64,$3A,$12,$52,$63
  DEFB $C6,$66,$4C,$11,$B3,$C0,$D2,$04
  DEFB $02,$A4,$C8,$A8,$3A,$13,$27,$A5
  DEFB $C8,$18,$0B,$A0,$3A,$18,$D8,$A0
  DEFB $C8,$15,$2C,$13,$0A,$A0,$3A,$12

; The six riders, 15 bytes each: flags, x, distance, speed, pose, jump
;
; +0 flags (bit 7 not in the race, bit 0 the second kind: the wider sprite set
; and the hard collision), +2 x, +3/+4 distance (the high byte is the road row;
; 0-$4F on screen), +5/+6 speed, +7 acceleration, +8 top speed, +9 pose (0-3, 4
; for the second kind), +$0A the lowest pose on a hill, +$0B/+$0C jump height,
; +$0D/+$0E jump speed. StartRace fills it from RiderStarts; MoveRiders and
; DrawRiders use it.
Riders:
  DEFB $1E,$12,$4F,$12,$19,$12,$E5,$A0,$C8,$12,$DC,$12,$22,$12,$01
  DEFB $12,$ED,$A0,$3A,$12,$15,$12,$EA,$12,$30,$12,$F1,$A0,$C8,$12
  DEFB $40,$12,$0A,$12,$24,$12,$F4,$A0,$3A,$12,$2B,$12,$E9,$A4,$C8
  DEFB $D0,$14,$B8,$64,$C8,$64,$A2,$C0,$F8,$14,$4A,$64,$3A,$64,$60
  DEFB $C0,$F8,$E0,$F7,$61,$30,$00,$55,$C8,$55,$3A,$55,$B8,$55,$4A
  DEFB $C0,$F1,$E0,$07,$62,$30,$00,$C0,$EA,$08,$02,$18,$17,$A0,$3A
DrawStack:
  DEFB $16,$D0,$A2,$C8,$10,$13,$12,$33,$12,$02,$12,$CA,$13 ; the track
                                                           ; interpreter's
                                                           ; stack for the
                                                           ; drawing walk (a
                                                           ; copy of TrackStack
                                                           ; each pass, 13
                                                           ; bytes)
SavedSp2:
  DEFB $21,$A0            ; DrawRoad's SP while it walks RowList (and
                          ; RoadRowsJump's)
JumpHeight:
  DEFB $3A,$12,$D9,$12,$1D,$12 ; the bike's height in the air, 8.8 ($5CEA the
                               ; whole part; 0 on the ground)
HorizonAddr:
  DEFB $09,$12            ; the stage's horizon (StageTable)
HorizonRows:
  DEFB $E4                ; its rows
HorizonBottom:
  DEFB $A0                ; the line under it (StageTable byte 3)
HorizonScroll:
  DEFB $C8,$12            ; the horizon's scroll position, 8.8
                          ; (HorizonScrollStep)
JumpRows:
  DEFB $20,$12,$DC,$12    ; up to four rows of ramps (type 0 objects) this
                          ; pass, $FF the end: MoveRiders makes riders jump
                          ; there
JumpRowPtr:
  DEFB $08,$12            ; the next free JumpRows place
DrawTrackPtr:
  DEFB $EE,$A0            ; the drawing walk's track position
JumpSpeed:
  DEFB $3A,$12            ; the bike's vertical speed, 8.8 ($5CFE the whole
                          ; part), minus $02F0 each pass
SplashOn:
  DEFB $E7                ; $87 on stages 2 and 4: the splash under the bike
                          ; (DrawSplash)

; Each byte with its bits reversed: Init builds it, DrawMirrored reads it (H =
; $5D)
ReverseTable:
  DEFB $12,$02,$12,$F3,$12,$2E,$A0,$C8,$12,$DC,$12,$1E,$12,$14,$12,$DE
  DEFB $A0,$3A,$D0,$A9,$A3,$A0,$C8,$A0,$3A,$A0,$5F,$C0,$F6,$08,$02,$6F
  DEFB $14,$66,$E2,$68,$F6,$65,$1A,$0F,$02,$D0,$A5,$C2,$C0,$FC,$A5,$40
  DEFB $C0,$FC,$12,$B8,$11,$5A,$A1,$B4,$12,$A8,$11,$4A,$11,$B6,$A2,$5E
  DEFB $12,$40,$13,$55,$A0,$B0,$12,$3A,$12,$B5,$A2,$4E,$C0,$E4,$68,$C8
  DEFB $62,$3A,$C0,$FA,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The five stage records (seconds, hundredths, BCD) and their total (minutes,
; seconds, hundredths)
;
; Init copies InitialRecords here; RecordStages improves them at game over.
; They last until the machine is reset.
Records:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00

; The current player's block, 56 bytes (NewGame clears it; TurnLoop swaps it
; with OtherPlayer)
Player:
PlayerChar:
  DEFB $00                ; '1' or '2' (the HUD's nUP)
StageTimes:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; five stage times: seconds, hundredths
  DEFB $00,$00                         ; (BCD)
Score:
  DEFB $00,$00,$00,$00,$00,$00,$00 ; seven characters, leading blanks
Timer:
  DEFB $00                ; seconds left, BCD (game over at 0)
Tenths:
  DEFB $00                ; passes to the next second, 10 down to 1
TimerAtStart:
  DEFB $00,$00            ; Timer and Tenths at the stage's start (StageTime)
Stage:
  DEFB $00                ; 0-4 (5 after the finish)
Countdown:
  DEFB $00                ; the start's countdown (16 down; bit 7: resume after
                          ; a fall)
SegmentLeft:
  DEFB $00,$00            ; the segment's progress, 8.8: counts down by
                          ; ScrollStep
TrackPtr:
  DEFB $00,$00            ; the track position (Track's elements)
TrackDistance:
  DEFB $00,$00            ; the distance into the track, 8.8
StageListPtr:
  DEFB $00,$00            ; the segment in StageList
BendDir:
  DEFB $00                ; the bend's side (segment bit 4): 1 one way, 0 the
                          ; other
BendPrev:
  DEFB $00                ; the previous segment's bend (bits 0-1: 0 straight,
                          ; 1-3 a bend profile)
Bend:
  DEFB $00                ; the segment's bend (bits 0-1)
CrestPrev:
  DEFB $00                ; the previous segment's crest (bits 2-3: 0 level,
                          ; 1-3 a rise or dip)
Crest:
  DEFB $00                ; the segment's crest (bits 2-3)
FallX:
  DEFB $00                ; x at a fall (the restart's x)
GapMarks:
  DEFB $00,$00            ; the rows of the two $F0 marks (the gap ends); $7F
                          ; none
Segments:
  DEFB $00                ; segments driven in the stage (the lap table's %)
VarObject:
  DEFB $00                ; the object type the $B0 command set (elements of
                          ; type 10 draw it)
TrackStack:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; the track interpreter's stack: depth,
  DEFB $00,$00,$00,$00,$00,$00         ; two frames of 6 bytes (return, length,
                                       ; distance)

; The other player's block, 56 bytes, swapped in by TurnLoop
OtherPlayer:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$07,$3F,$07,$38,$08
  DEFB $0D,$09,$0E,$0A,$0F,$00,$00,$ED
  DEFB $73,$86,$65,$31,$84,$65,$F5,$C5
  DEFB $D5,$E5,$DD,$E5,$FD,$E5,$2A,$86
  DEFB $65,$5E,$23,$56,$23,$22,$86,$65
  DEFB $2B,$2B,$ED,$53,$24,$65,$7C,$C3

; 3 bytes after the blocks, never used ($66, $64, $00 in the image: LDDR
; leftovers)
PlayerPad:
  DEFB $66,$64,$00

; The stage list, one byte a segment (Init copies it from $EB00; the image's
; own bytes here are leftovers)
;
; bits 0-1 the bend (0 straight, BendProfiles 1-3), bits 2-3 the crest (0
; level, CrestTable 1-3), bit 4 the direction, bit 5 the stage's last segment,
; bits 6-7 added to the segment's progress at its start (SegmentLen, $AF81).
; Five stages end at $5E9F, $5EB6, $5ED0, $5EEB, $5F0B: 32, 23, 26, 27 and 32
; segments. src/res/track/stage1.txt ... stage5.txt (tools/course.py).
StageList:
  DEFB $02,$00,$00,$00,$18,$D6,$FE,$FE
  DEFB $CA,$2E,$65,$FE,$FF,$C2,$26,$65
  DEFB $7D,$FE,$82,$DA,$2E,$65,$21,$3B
  DEFB $64,$3A,$61,$64,$BE,$28,$56,$57
  DEFB $3A,$60,$64,$A7,$28,$4F,$7A,$77
  DEFB $87,$20,$0A,$21,$30,$64,$1E,$01
  DEFB $CD,$06,$68,$18,$7A,$87,$6F,$26
  DEFB $00,$11,$BE,$66,$19,$5E,$23,$56
  DEFB $ED,$53,$1B,$68,$ED,$53,$18,$68
  DEFB $23,$5E,$23,$56,$ED,$53,$29,$68
  DEFB $ED,$53,$2C,$68,$AF,$32,$60,$64
  DEFB $3E,$01,$32,$28,$68,$32,$17,$68
  DEFB $3E,$FF,$32,$1D,$68,$32,$2E,$68
  DEFB $1E,$04,$21,$32,$64,$CD,$06,$68
  DEFB $3E,$38,$32,$FC,$67,$3A,$3B,$64
  DEFB $A7,$28,$34,$3A,$2F,$7C,$A7,$20
  DEFB $20,$3A,$62,$64,$A7,$28,$05,$32
  DEFB $3A,$64,$18,$23
TrackPatterns:
  DEFB $3A,$3A,$64,$A7,$28,$0F,$AF,$32 ; the patterns the $E0 commands run
  DEFB $3A,$64,$21,$32,$64,$1E,$04,$CD
  DEFB $06,$68,$CD,$01,$68,$DD,$21,$17
  DEFB $68,$CD,$88,$65,$DD,$21,$28,$68
  DEFB $CD,$88,$65,$3A,$61,$64,$A7,$C4
  DEFB $51,$68,$FD,$E1,$DD,$E1,$E1,$D1
  DEFB $C1,$F1,$ED,$7B,$86,$65,$FB,$C3
  DEFB $00,$00,$36,$00,$23,$36,$00,$C3
  DEFB $76,$64,$E5,$11,$00,$02,$19,$A7
  DEFB $CB,$1C,$CB,$1D,$7D,$FE,$28,$30
  DEFB $05,$CD,$39,$68,$18,$1D,$FE,$40
  DEFB $30,$11,$D6,$28,$6F,$26,$00,$29
  DEFB $29,$29,$29,$29,$11,$00,$EB,$19
  DEFB $EB,$18,$08,$CD,$39,$68,$21,$00
  DEFB $A6,$19,$EB,$E1,$73,$23,$72,$C3
  DEFB $76,$64,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$ED,$B0,$DD,$7E,$00,$3D
  DEFB $DD,$77,$00,$20,$0C,$3A,$FC,$67
  DEFB $DD,$B6,$0E,$32,$FC,$67,$C3,$01
  DEFB $68,$3C,$C0,$3A,$FC,$67,$DD,$AE
  DEFB $0E,$32,$FC,$67,$CD,$01,$68,$DD
  DEFB $6E,$01,$DD,$66,$02,$7E,$FE,$C8
  DEFB $30,$58,$3D,$DD,$77,$00,$23,$7E
  DEFB $23,$DD,$75,$01,$DD,$74,$02,$4F
  DEFB $E6,$0F,$20,$0C,$3A,$FC,$67,$DD
  DEFB $B6,$0E,$32,$FC,$67,$C3,$01,$68
  DEFB $87,$C6,$AA,$6F,$26,$66,$30,$01
  DEFB $24,$5E,$23,$56,$EB,$79,$DD,$86
  DEFB $03,$E6,$F0,$1F,$1F,$1F,$1F,$A7
  DEFB $CB,$1C,$CB,$1D,$3D,$20,$F8,$EB
  DEFB $01,$FD,$FF,$DD,$6E,$0D,$7D,$ED
  DEFB $79,$06,$BF,$7B,$ED,$79,$06,$FF
  DEFB $7D,$3C,$ED,$79,$06,$BF,$7A,$ED
  DEFB $79,$C9,$FE,$C9,$20,$0C,$AF,$32
  DEFB $60,$64,$DD,$6E,$04,$DD,$66,$05
  DEFB $18,$93,$FE,$CA,$20,$08,$23,$3E
  DEFB $01,$32,$60,$64,$18,$87,$FE,$FE
  DEFB $20,$19,$23,$DD,$7E,$06,$3C,$DD
  DEFB $77,$06,$CD,$94,$66,$7E,$23,$FD
  DEFB $77,$00,$FD,$75,$01,$FD,$74,$02
  DEFB $C3,$B1,$65,$FE,$FD,$20,$20,$CD
  DEFB $94,$66,$FD,$7E,$00,$3D,$FD,$77
  DEFB $00,$20,$0B,$23,$DD,$7E,$06,$3D
  DEFB $DD,$77,$06,$C3,$B1,$65,$FD,$6E
  DEFB $01,$FD,$66,$02,$C3,$B1,$65,$FE
  DEFB $FB,$20,$09,$DD,$6E,$0F,$DD,$66
  DEFB $10,$C3,$B1,$65,$FE,$FC,$20,$0F
  DEFB $23,$5E,$23,$56,$23,$DD,$75,$0F
  DEFB $DD,$74,$10,$EB,$C3,$B1,$65,$23
  DEFB $5E,$23,$CD,$06,$68,$C3,$B1,$65
  DEFB $DD,$7E,$06,$DD,$5D,$DD,$54,$FD
  DEFB $21,$07,$00,$FD,$19,$5F,$87,$83
  DEFB $5F,$16,$00,$FD,$19,$C9,$EE,$0E
  DEFB $18,$0E,$4D,$0D
Track:
  DEFB $8E,$0C,$DA,$0B,$2F,$0B,$8F,$0A ; the track's elements, from the start
  DEFB $F7,$09,$68,$09,$E1,$08,$61,$08 ; of stage 1 (TrackPtr)
  DEFB $E9,$07,$01,$67,$90,$67,$CA,$66
  DEFB $25,$67,$FE,$03,$FC,$E9,$66,$FC
  DEFB $F1,$66,$FC,$F9,$66,$FD,$FC,$E9
  DEFB $66,$FC,$F1,$66,$FE,$06,$08,$04
  DEFB $04,$04,$FD,$C7,$00,$CA,$C7,$00
  DEFB $C9,$FE,$04,$08,$04,$04,$04,$FD
  DEFB $FB,$FE,$04,$08,$02,$04,$02,$FD
  DEFB $FB,$FE,$08,$08,$04,$04,$04,$FD
  DEFB $FB,$FE,$04,$FC,$E9,$66,$FC,$F1
  DEFB $66,$FC,$F9,$66,$FD,$FE,$0A,$08
  DEFB $04,$04,$04,$08,$14,$04,$14,$FD
  DEFB $FE,$06,$04,$02,$FD,$04,$04,$C7
  DEFB $00,$CA,$C7,$00,$C9,$FC,$60,$67
  DEFB $FC,$79,$67,$FC,$60,$67,$04,$09
  DEFB $08,$07,$04,$00,$08,$04,$18,$00
  DEFB $04,$04,$08,$07,$04,$09,$FC,$60
  DEFB $67,$FC,$79,$67,$08,$0B,$0D,$00
  DEFB $08,$09,$08,$00,$08,$07,$08,$12
  DEFB $1B,$00,$04,$0B,$08,$16,$08,$14
  DEFB $44,$00,$C7,$00,$CA,$C7,$00,$C9
  DEFB $08,$0B,$0D,$00,$08,$09,$08,$00
  DEFB $08,$07,$08,$06,$1B,$00,$04,$02
  DEFB $08,$04,$04,$06,$08,$06,$1A,$00
  DEFB $FB,$08,$07,$04,$00,$04,$09,$08
  DEFB $07,$04,$00,$08,$00,$00,$00,$00
  DEFB $A0,$C8,$01,$01,$14,$0C,$A3,$C8
  DEFB $14,$EC,$12,$10,$A2,$C8,$14,$D6
  DEFB $A4,$3A,$13,$F6,$13,$32,$A2,$C8
  DEFB $10,$14,$14,$C8,$12,$F2,$11,$02
  DEFB $A1,$3A,$11,$26,$10,$D0,$13,$E2
  DEFB $11,$22,$12,$06,$A1,$C8,$12,$D3
  DEFB $11,$E8,$13,$18,$A2,$3A,$D0,$A7
  DEFB $C8,$A7,$3A,$A7,$BC,$A7,$46,$C0
  DEFB $F6,$26,$C8,$23,$A0,$13,$3A,$26
  DEFB $3A,$23,$62,$13,$C8,$C0,$F2,$A4
  DEFB $C4,$A4,$3E,$A4,$CA,$A4,$38,$C0
  DEFB $F6,$AC,$C8,$A0,$3A,$C0,$FA,$A5
  DEFB $C8,$A5,$3A,$C0,$FA,$37,$32,$37
  DEFB $32,$37,$32,$37,$32,$40,$B8,$C0
  DEFB $F4,$64,$CA,$60,$4C,$62,$AA,$14
  DEFB $B9,$61,$38,$11,$58,$15,$43,$61
  DEFB $C8,$64,$B3,$61,$4F,$66,$38,$12
  DEFB $AD,$62,$C8,$15,$49,$61,$5B,$12
  DEFB $BF,$60,$B0,$64,$3A,$12,$52,$63
  DEFB $C6,$66,$4C,$11,$B3,$C0,$D2,$04
  DEFB $02,$A4,$C8,$A8,$3A,$13,$27,$A5
  DEFB $C8,$18,$0B,$A0,$3A,$18,$D8,$A0
  DEFB $C8,$15,$2C,$13,$0A,$A0,$3A,$12
  DEFB $1E,$12,$4F,$12,$19,$12,$E5,$A0
  DEFB $C8,$12,$DC,$12,$22,$12,$01,$12
  DEFB $ED,$A0,$3A,$12,$15,$12,$EA,$12
  DEFB $30,$12,$F1,$A0,$C8,$12,$40,$12
  DEFB $0A,$12,$24,$12,$F4,$A0,$3A,$12
  DEFB $2B,$12,$E9,$A4,$C8,$D0,$14,$B8
  DEFB $64,$C8,$64,$A2,$C0,$F8,$14,$4A
  DEFB $64,$3A,$64,$60,$C0,$F8,$E0,$F7
  DEFB $61,$30,$00,$55,$C8,$55,$3A,$55
  DEFB $B8,$55,$4A,$C0,$F1,$E0,$07,$62
  DEFB $30,$00,$C0,$EA,$08,$02,$18,$17
  DEFB $A0,$3A,$16,$D0,$A2,$C8,$10,$13
  DEFB $12,$33,$12,$02,$12,$CA,$13,$21
  DEFB $A0,$3A,$12,$D9,$12,$1D,$12,$09
  DEFB $12,$E4,$A0,$C8,$12,$20,$12,$DC
  DEFB $12,$08,$12,$EE,$A0,$3A,$12,$E7
  DEFB $12,$02,$12,$F3,$12,$2E,$A0,$C8
  DEFB $12,$DC,$12,$1E,$12,$14,$12,$DE
  DEFB $A0,$3A,$D0,$A9,$A3,$A0,$C8,$A0
  DEFB $3A,$A0,$5F,$C0,$F6,$08,$02,$6F
  DEFB $14,$66,$E2,$68,$F6,$65,$1A,$0F
  DEFB $02,$D0,$A5,$C2,$C0,$FC,$A5,$40
  DEFB $C0,$FC,$12,$B8,$11,$5A,$A1,$B4
  DEFB $12,$A8,$11,$4A,$11,$B6,$A2,$5E
  DEFB $12,$40,$13,$55,$A0,$B0,$12,$3A
  DEFB $12,$B5,$A2,$4E,$C0,$E4,$68,$C8
  DEFB $62,$3A,$C0,$FA,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; AY register 7 = $3F: every tone and noise off (written when the tune stops)
;
; AY data: a register then its value, written by AyWrite ($6806). Interrupt
; writes this one pair when the tune request TuneRequest goes to 0 (pause, the
; end of a race).
AySilence:
  DEFB $07,$3F
AyTuneStart:
  DEFB $07,$38,$08,$0D,$09,$0E ; four pairs at a tune's start: 7 = $38 (tones
                               ; A, B, C on), 8 = $0D, 9 = $0E, 10 = $0F
                               ; (volumes)
AyEngineVolume:
  DEFB $0A,$0F            ; register 10 (volume C) = $0F: EngineSound's AY tone
                          ; on channel C
TuneHeld:
  DEFB $00                ; nonzero while an effect owns the AY: the tune's
                          ; mixer is written again when it ends
TunePlaying:
  DEFB $00                ; the tune the channels play: 0 none, 1 or 2
                          ; (compared with TuneRequest each interrupt)

  ORG $8000

; JP Init: the entry Mover jumps to; its three bytes and the 181 after them are
; work space later
;
; After the start $8000-$8002 hold variables (MenuItem $8001, KeyItem $8000,
; WaitCount $8002-$8003) and $8000-$80B7 is the line buffer of the sprite
; routines (DrawShifted, DrawMirrored, BuildRoadRows: up to 184 bytes).
;
; Recorded: c1 frame 11646: Mover's JP $8000.
;
; Witness: L1 2 (c1, m128).
Start:
  JP Init

; The five stage records (99"59 each) and their total, copied to Records
; ($5E00) by Init
;
; 13 bytes: five times (seconds BCD, hundredths BCD) = $99, $59, then the total
; (minutes, seconds, hundredths) $03, $59, $96, which RecordTotals recomputes
; before it is shown. Afterwards the bytes are the line buffer.
InitialRecords:
  INCBIN "res/tables/records.bin",$0000,13

; $8010-$80B7: zeros, the rest of the sprite line buffer that starts at $8000
LineBufferTail:
  DEFS $A8

; The IM 2 table, the records, the track tables, the bit-reverse table, the
; 128K test, IM 2 and on to Attract
;
; I = $B2, $B200-$B300 = $64; InitialRecords to Records ($5E00, 13 bytes);
; $EB00-$F0AF to StageList ($5E80, 1456 bytes: the stage list and the track);
; ReverseTable at $5D00 (each byte with its bits reversed, for DrawMirrored);
; the byte sum of ROM $3B00-$3BFF: $FE (the 48K ROM) gives Beeper = $FF, else
; 0; Players = 1; SP = 0 (the stack under $0000: $FFxx); IM 2; EI; falls into
; Attract.
;
; Recorded: c1 and m128 frame 11646; c1's sum is $FE, m128's is not: Beeper 0
; there.
;
; Witness: L1 2 (c1, m128).
Init:
  DI
  LD HL,Im2Table
  LD A,H
  LD I,A
l_80BF:
  LD (HL),$64
  INC L
  JR NZ,l_80BF
  INC H
  LD (HL),$64
  LD HL,InitialRecords
  LD DE,Records
  LD BC,$000D
  LDIR
  LD HL,TrackTables
  LD DE,StageList
  LD BC,$05B0
  LDIR
  LD HL,ReverseTable
l_80E0:
  LD A,L
  LD B,$08
l_80E3:
  RLA
  RR C
  DJNZ l_80E3
  LD (HL),C
  INC L
  JR NZ,l_80E0
RomSum:
  LD HL,$3B00             ; the 128K test: sum ROM $3B00-$3BFF
  XOR A
l_80F0:
  ADC A,(HL)
  INC L
  JR NZ,l_80F0
  LD C,A
  LD B,$00
  CP $FE
  LD A,$FF
  JR Z,l_80FE
  XOR A
l_80FE:
  LD (Beeper),A           ; Beeper = $FF on the 48K ROM
  LD A,$01
  LD (Players),A
  LD SP,$0000
  IM 2
  EI
