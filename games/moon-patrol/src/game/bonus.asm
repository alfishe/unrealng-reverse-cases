; --------------------------------------------------------------------------------------------------------------------
; bonus.asm: The sector bonus screen at each sector end, with the best sector time kept in the course script
;
; The course interpreter jumps to SectorBonus $A4EE at each of the five sector-end records of a course script (the
; command word $A4EE; Beginner $B87C, ... Champion ...). The record after the command word: the time required for the
; bonus (BCD word, high byte first), the sector bonus (one BCD byte), the scenery flag for the next sector, and the
; best time so far (BCD word, $0999 in the image).
;
; The screen: the time taken, the time required and the best time; the sector bonus added to the score; the time bonus
; (100 points a second under the time required) counted up with a blip a second, or SORRY NO TIME BONUS; a better time
; is written back into the script, so the best time lives in the course script for the rest of the session. Then the
; next sector starts. Witness: i1 and i2, the five sector ends of each course (i1 frames 5176-29659, i2 5357-30694).
; --------------------------------------------------------------------------------------------------------------------

; The sector bonus screen: the times, the sector and time bonuses, the best
; time written back into the course script
;
; Entered by a jump from the course interpreter $9751 at a sector-end record,
; HL just past the command word. Reads the record: TimeRequired $B241 (BCD
; word, high byte first), SectorBonus $B245 (one BCD byte, $B246 = 0), the
; scenery flag $B27D ($FF / $00, alternate sectors: picks the hills graphics at
; the life start $90D3 through $95B0 / $9541), BestTime $B243 (BCD word, $0999
; in the image), and leaves the course pointer $B27A just past the record.
;
; SetIm1 $A7CB (the ROM's interrupt: the game's clock $7F98 stops), clears the
; screen ($9044, colour 7), $9136, prints BonusHeaderText and the course letter
; ($9258 with $B27C), then the time taken $B285, TimeRequired and BestTime
; ($9369, 2 BCD bytes at x $C2, y $49 / $51 / $59). Prints SectorBonusText and
; the bonus at x $A0, y $69, and adds it to the score: ScoreAdd $92D3 with B =
; the bonus byte, C = 0 ($10 = 1000 points). Plays BonusTune $A773 (22 BEEPER
; notes), waits 50 frames.
;
; The time bonus: TimeRequired - time taken in BCD. Not positive: NoTimeBonus
; (SORRY NO TIME BONUS and a low note). Positive: TimeBonusText, a two-note
; fanfare (BonusBeep $A690), 50 frames, then one pass of TimeBonusLoop a second
; of the difference: the bonus counter $B245 + 100 shown at x $A0, y $71, 100
; points to the score, a 15-half-cycle blip on the beeper with interrupts off
; (DI $A5E5, OUT $A60A, EI $A610), 4 frames. Only the low byte of the
; difference counts (DEC A / DAA to zero): a difference of 100 seconds or more
; would lose its hundreds (known only from the code: no time required in the
; scripts is over $0150).
;
; Then the 100-frame wait $903D and the best time: if the time taken is below
; BestTime, BestTimeWrite stores it (DE = $B285, low byte $B285 first, that is
; the same big-endian BCD order) over the record's last word, through the
; course pointer $B27A - 2: this is the writer of the script words $B884,
; $B925, $B9AE, $BA51, $BB03 (Beginner) and $BBC7, $BC95, $BD42, $BDF0, $BED0
; (Champion). The AWESOME! BEST SECTOR TIME SO FAR!! text and the longer flash
; (50 passes, else 25) only when the old best is not the image's placeholder
; (high byte $09): the first finish of a sector records its time silently.
;
; Last: BonusFlash 25 or 50 passes of $8349 (the attribute cycle of the menu,
; here on $5A03-$5A1D) and the delay $820D; the time $B285 / $B286 and the tick
; counter $B287 to zero, the screen cleared, the life start $90D3, SP back from
; $B25F and a jump to the main loop $9696 with the course pointer at the next
; sector.
;
; Witness: i1 5 and i2 5 runs (l1sum $A4EE, i1 frames 5176-29659, i2
; 5357-30694, the five sector ends of NOTES); TimeBonusLoop i1 134 seconds, i2
; 172; the blip OUT $A60A i1 2010 = 134 x 15; BestTimeWrite $A659 i1 5, i2 5;
; the reads of $B884 (i1 1). NoTimeBonus $A620 and the AWESOME text $A651 were
; not executed in any recording (game, a1, g1, t1, p2, h1, i1, i2, h2): known
; only from the code (both runs finished every sector in time, and no sector
; was finished twice).
SectorBonus:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (SectorTime),DE      ; TimeRequired $B241: the record's first word, high
                          ; BCD byte first
  LD E,(HL)
  INC HL
  LD D,$00
  LD (SectorBonusPoints),DE ; SectorBonus $B245: the record's bonus byte, $B246
                            ; = 0
  LD A,(HL)
  INC HL
  LD (PlayerScenery),A    ; the scenery flag $B27D for the next sector
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (BestTime),DE        ; BestTime $B243: the record's last word
  LD (PlayerCourse),HL    ; the course pointer $B27A: past the record
                          ; (BestTimeWrite writes through it)
  CALL SetIm1             ; IM 1: the game's handler and its clock stop
  LD A,$07
  CALL ClearScreen
  CALL HudDraw
  LD HL,BonusHeaderText
  CALL PrintText
  LD A,(PlayerPoint)
  CALL HudPrintPointLetter
  LD HL,PlayerTime
  LD DE,$C249             ; the time taken $B285 at x $C2, y $49
  LD BC,$0206
  CALL PrintBcd
  LD HL,SectorTime
  LD DE,$C251             ; TimeRequired at x $C2, y $51
  LD BC,$0206
  CALL PrintBcd
  LD HL,BestTime
  LD DE,$C259             ; BestTime at x $C2, y $59
  LD BC,$0206
  CALL PrintBcd
  LD HL,SectorBonusText
  CALL PrintText
  LD HL,SectorBonusPoints
  LD DE,$A069             ; the sector bonus at x $A0, y $69
  LD BC,$0206
  CALL PrintBcd
  LD A,(SectorBonusPoints)
  LD DE,$0000
  LD B,A
  LD C,E
  CALL ScoreAdd           ; the sector bonus to the score: B = the bonus byte,
                          ; C = 0
  LD HL,BonusTune         ; the fanfare: 22 notes of BonusTune
  LD B,$16
BonusTuneLoop:
  PUSH BC                 ; HL = the period word, DE = the length byte; the
                          ; fourth byte is skipped
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD C,(HL)
  INC HL
  INC HL
  PUSH HL
  EX DE,HL
  LD D,$00
  LD E,C
  CALL BEEPER
  POP HL
  POP BC
  DJNZ BonusTuneLoop
  LD B,$32                ; 50 frames
BonusWait1:
  HALT
  DJNZ BonusWait1
  LD HL,(SectorTime)      ; TimeRequired - time taken, BCD, low bytes first: H
                          ; = low byte, L = high byte
  LD DE,(PlayerTime)
  LD A,H
  SUB D
  DAA
  LD H,A
  LD A,L
  SBC A,E
  DAA
  LD L,A
  BIT 7,A                 ; negative or zero: no time bonus
  JP NZ,NoTimeBonus
  OR H
  JP Z,NoTimeBonus
  PUSH HL
  LD HL,TimeBonusText
  CALL PrintText
  LD HL,$01B7             ; the two-note fanfare of the time bonus
  LD DE,$00A8
  CALL BonusBeep
  POP HL
  LD B,$32                ; 50 frames
BonusWait2:
  HALT
  DJNZ BonusWait2
  LD A,H                  ; A = the seconds to count: only the low BCD byte of
                          ; the difference
  LD HL,$0000
  LD (SectorBonusPoints),HL ; the bonus counter $B245 / $B246 = 0
TimeBonusLoop:
  PUSH AF                 ; one second of the difference: the counter + 100
                          ; (BCD, high byte first)
  LD HL,SectorBonusPoints+$0001
  LD A,(HL)
  ADD A,$00
  DAA
  LD (HL),A
  DEC HL
  LD A,(HL)
  ADC A,$01
  DAA
  LD (HL),A
  LD C,$03
  LD HL,Screen+2260             ; three characters cleared before the new count
  CALL ClearCells
  LD HL,SectorBonusPoints
  LD DE,$A071             ; the counter at x $A0, y $71
  LD BC,$0206
  CALL PrintBcd
  LD DE,$0000             ; 100 points to the score
  LD BC,$0100
  CALL ScoreAdd
  DI                      ; the blip with interrupts off; A' = the border
                          ; colour from BORDCR
  EX AF,AF'
  LD A,(BORDCR)
  AND $38
  RRCA
  RRCA
  RRCA
  EX AF,AF'
  LD DE,RomBlipLengths             ; the half-cycle lengths come from the ROM bytes at
                          ; $0B16
  LD C,$0F
BlipHalfCycle:
  LD A,(DE)               ; one half-cycle: (DE) x 10 DJNZ loops, then $77
                          ; short ones
  INC DE
BlipDelayOuter:
  LD B,$0A
BlipDelayInner:
  DJNZ BlipDelayInner
  DEC A
  JR NZ,BlipDelayOuter
  LD A,$77
BlipDelayFixed:
  LD B,$01
BlipDelayFixedInner:
  DJNZ BlipDelayFixedInner
  DEC A
  JR NZ,BlipDelayFixed
  EX AF,AF'
  XOR $18                 ; toggles the speaker and MIC bits, the border
                          ; unchanged
  OUT ($FE),A
  EX AF,AF'
  DEC C
  JR NZ,BlipHalfCycle
  EI                      ; interrupts back on, 4 frames
  LD B,$04
BonusWait3:
  HALT
  DJNZ BonusWait3
  POP AF                  ; the next second, in BCD
  DEC A
  DAA
  JR NZ,TimeBonusLoop
  CALL Wait100Frames      ; the 100-frame wait, then the best time
  JR BestTimeCheck
NoTimeBonus:
  LD HL,NoTimeBonusText   ; SORRY NO TIME BONUS and a low note (not executed in
                          ; any recording)
  CALL PrintText
  LD HL,$1BBA
  LD DE,$000B
  CALL BonusBeep
  CALL Wait100Frames
BestTimeCheck:
  LD HL,(BestTime)        ; BestTime - time taken, BCD: positive means a new
                          ; best
  LD DE,(PlayerTime)
  LD A,H
  SUB D
  DAA
  LD H,A
  LD A,L
  SBC A,E
  DAA
  LD L,A
  LD B,$19                ; 25 flash passes unless AWESOME
  BIT 7,A
  JR NZ,BonusFlash
  OR H
  JR Z,BonusFlash
  LD A,(BestTime)         ; BestTime high byte $09: the image's placeholder
                          ; $0999, no text
  CP $09
  JR Z,BestTimeWrite
  LD HL,BestTimeText      ; AWESOME! BEST SECTOR TIME SO FAR!! and 50 flash
                          ; passes (not executed in any recording)
  CALL PrintText
  LD B,$32
BestTimeWrite:
  LD DE,(PlayerTime)      ; the writer of the script's best time: the time
                          ; taken over the record's last word
  LD HL,(PlayerCourse)
  DEC HL
  LD (HL),D
  DEC HL
  LD (HL),E
BonusFlash:
  PUSH BC                 ; one pass of the attribute cycle $8349 on
                          ; $5A03-$5A1D and the delay $820D
  LD DE,Attributes+515
  LD IX,Attributes+541
  CALL CycleColourRange
  LD C,$AF
  CALL MenuDelay
  POP BC
  DJNZ BonusFlash
  LD HL,$0000             ; the time and the tick counter to zero for the next
                          ; sector
  LD (PlayerTime),HL
  XOR A
  LD (PlayerFrames),A
  LD A,$07
  CALL ClearScreen
  CALL LifeStart          ; the life start, then the main loop with the course
                          ; pointer at the next sector
  LD SP,(LoopStack)
  JP MainLoop

; Two BEEPER calls with the same note, 7 frames apart (the bonus fanfares)
;
; HL = the period, DE = the length, as for BEEPER $03B5 (the ROM's). Called by
; SectorBonus with HL $01B7, DE $00A8 (the time bonus) and with HL $1BBA, DE
; $000B (no time bonus; not executed in any recording). Witness: i1 5, i2 5
; entries (i1 frames 5423-28918), the 7-frame wait $A699 35 times each.
BonusBeep:
  PUSH DE
  PUSH HL
  CALL BEEPER
  POP HL
  POP DE
  LD B,$07
BonusBeepWait:
  HALT
  DJNZ BonusBeepWait
  CALL BEEPER
  RET

; The bonus screen's three labels: TIME TAKEN TO REACH POINT, TIME REQUIRED FOR
; BONUS, BEST TIME SO FAR
;
; A string of the print routine $FFD0: $16 x y moves to the pixel position x, y
; ($16 $1A $49 here), $0D starts the next line, $1F ends; $18 and $1A take one
; byte each (their role is the print routine's). The numbers are printed after
; it by SectorBonus at x $C2. Read by SectorBonus $A519 (i1 5, i2 5 reads a
; byte).
BonusHeaderText:
  INCBIN "res/text/BonusHeaderText.bin",$0000,102

; SECTOR BONUS = at x $46, y $69
SectorBonusText:
  INCBIN "res/text/SectorBonusText.bin",$0000,19

; TIME BONUS   = at x $46, y $71
TimeBonusText:
  INCBIN "res/text/TimeBonusText.bin",$0000,19

; SORRY NO TIME BONUS at x $46, y $71 (never read in the recordings)
NoTimeBonusText:
  INCBIN "res/text/NoTimeBonusText.bin",$0000,23

; AWESOME! BEST SECTOR TIME SO FAR!! in its own colours ($10 ink 4, $11 paper
; 0, $13 bright 1) at x $1C, y $81 (never read in the recordings)
BestTimeText:
  INCBIN "res/text/BestTimeText.bin",$0000,48

; The sector-end fanfare: 22 notes of 4 bytes: BEEPER period (word), length
; (byte), a spare byte
;
; Played by BonusTuneLoop $A56B: HL = the period, DE = the length byte; the
; fourth byte is never read (l1sum --reads $A773-$A7CA: three bytes of each
; four read 5 times in i1). Doc 2's "never touched $A72C-$A7CA" holds only for
; the two texts and these spare bytes.
BonusTune:
  DEFB $1D,$08,$23,$00
  DEFB $CE,$06,$29,$00
  DEFB $11,$05,$37,$00
  DEFB $A7,$07,$25,$00
  DEFB $0C,$06,$2E,$00
  DEFB $11,$05,$37,$00
  DEFB $CE,$06,$29,$00
  DEFB $60,$05,$34,$00
  DEFB $80,$04,$3E,$00
  DEFB $11,$05,$37,$00
  DEFB $CE,$06,$29,$00
  DEFB $1D,$08,$23,$00
  DEFB $1D,$08,$23,$00
  DEFB $CE,$06,$29,$00
  DEFB $11,$05,$37,$00
  DEFB $A7,$07,$25,$00
  DEFB $0C,$06,$2E,$00
  DEFB $11,$05,$37,$00
  DEFB $CE,$06,$29,$00
  DEFB $60,$05,$34,$00
  DEFB $80,$04,$3E,$00
  DEFB $11,$05,$37,$00
