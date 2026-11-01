; Build the ground profile $6000 from the course
;
; Clears $6000-$62FF and fills it with the ground profile of the course
; (CourseRecord): one byte for every 2 units along, height in bits 0-4 and
; walls in bits 5-7 (docs/07-objects.md 7.4). Each course byte b after the type
; gives the anchors at $C9FE + b / 2 (GroundAnchors), ended by $FF; an anchor
; goes every 8 bytes from $6008, and the 7 bytes after the previous anchor step
; from it toward the new one by (old height - new height) / 8 a byte. The
; previous anchor also takes the new anchor's wall bits. Stops when the buffer
; is full ($6300) or the course ends. Entered by JP from the course check
; ($D4C2) right after RoundSetup, so it returns to the caller of ScrollStep.
BuildGroundProfile:
  LD HL,ProfileBuffer     ; clear the 768-byte profile
  LD DE,ProfileBuffer+$0001
  LD (HL),L
  LD BC,$02FF
  LDIR
  LD HL,(CourseRecord)    ; BC = the course data
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC BC                  ; skip the player's type
  LD DE,ProfileBuffer+$0008 ; the first anchor; $6000 is the anchor before it
ProfileSegment:
  LD A,(BC)               ; the next course byte; $FF ends the course
  CP $FF
  RET Z
  PUSH BC
  SRL A                   ; its anchors at $C9FE + b / 2
  LD L,A
  LD H,$00
  LD BC,GroundAnchors
  ADD HL,BC
ProfileAnchor:
  LD A,D                  ; the buffer full at $6300: done
  CP $63
  JR C,l_D11A
  POP AF                  ; drop the saved course pointer
  RET
l_D11A:
  LD A,(HL)               ; the next anchor; $FF ends the segment
  CP $FF
  JR Z,l_D149
  LD (DE),A               ; the new anchor
  INC HL
  EX DE,HL
  LD BC,$FFF8             ; back to the previous anchor
  ADD HL,BC
  LD B,A
  AND $1F
  LD C,A
  LD A,B
  AND $E0                 ; the previous anchor takes the new walls
  OR (HL)
  LD (HL),A
  AND $1F                 ; (old height - new height) / 8: the step
  SUB C
  SRA A
  SRA A
  SRA A
  LD C,A
  LD A,(HL)
  INC HL
  LD B,$07                ; the 7 bytes in between
l_D13D:
  SUB C
  LD (HL),A
  INC HL
  DJNZ l_D13D
  LD BC,$0008             ; on to the new anchor
  ADD HL,BC
  EX DE,HL
  JR ProfileAnchor
l_D149:
  POP BC                  ; the next course byte
  INC BC
  JR ProfileSegment

; The distance scrolled into the round
;
; + 2 a pass (ScrollStep). The positions of the object records along the course
; are in the same unit (docs/07-objects.md 7.1). Cleared at a round start and
; by RoundSetup.
ScrollDistance:
  DEFW $0000

; The player's old position less $6C
;
; Set by RoundSetup ($D209): subtracted from the positions of the records
; $C060-$C090 (the followers), so they keep their place behind the player when
; the positions start again.
ConvoyShift:
  DEFW $0000

; Set up a round: round table, round number, lives, objects, colour
;
; Called by the course check ($D4BF) when the 32nd strip of a course is drawn:
; at the end of a round start's pre-roll, and when the next course scrolls in
; without a break (docs/04-game-loop.md 4.2, docs/10-gameplay-logic.md 10.2).
; Outside the demo: MAX from SCORE, the round table entry of the round just
; ended (or retried) gets the carried lives and SCORE, the round number counts
; up (after 10 back to 1, with the lap $C2F8 counted and round 10's entry
; copied to round 0's), the round number and the lives are shown. Then, demo or
; not ($D1DE): the round's objects from the course record (docs/07-objects.md
; 7.2, 7.8), the round sound, and the course colour painted by falling into
; PaintAttributes with B = ink 6 - ((round - 1) AND 3), bright below 5; in the
; demo the subtracted value is one less (the round number stays 0 there, so ink
; 4, bright green).
RoundSetup:
  LD A,(DemoFlag)         ; the demo skips the score and the panel
  AND A
  JP NZ,ObjectSetup
  CALL UpdateMax          ; MAX from SCORE
  LD A,(RoundNumber)      ; round table entry $EF4F + 6 x round
  ADD A,A
  LD B,A
  ADD A,A
  ADD A,B
  LD C,A
  LD B,$00
  LD HL,RoundTable
  ADD HL,BC
  LD A,(Followers)        ; the carried lives
  LD (HL),A
  INC HL
  LD DE,Score             ; then SCORE, 5 characters
  EX DE,HL
  LD BC,$0005
  LDIR
  CALL ShowScore          ; print SCORE
  LD HL,RoundText+$0003   ; the round's two digits go to $C2FD-$C2FE
  LD A,(RoundNumber)      ; the next round
  INC A
  CP $0B                  ; after round 10:
  JR C,l_D19B
  LD A,(LapNumber)        ; the next lap
  INC A
  LD (LapNumber),A
  PUSH HL                 ; round 10's entry into round 0's
  LD DE,RoundTable
  LD HL,RoundTable+$003C
  LD BC,$0006
  LDIR
  POP HL
  LD A,$01
l_D19B:
  LD (RoundNumber),A
  LD A,(LapNumber)        ; tens digit: the lap, plus 1 from round 10
  ADD A,$30
  LD B,A
  LD A,(RoundNumber)
  CP $0A
  JR C,l_D1AE
  INC B
  SUB $0A
l_D1AE:
  LD C,A
  LD A,B
  CP $31                  ; a leading 0 becomes a space
  JR NC,l_D1B6
  LD A,$20
l_D1B6:
  LD (HL),A
  LD A,C
  ADD A,$30
  INC HL
  LD (HL),A
  LD HL,RoundText         ; print the round number
  CALL PrintString
  LD A,(Followers)        ; lives = the carried lives
  LD (Lives),A
  LD HL,$5A58             ; hide the 4 dots
  LD B,$04
l_D1CD:
  LD (HL),$12
  INC L
  DJNZ l_D1CD
  CALL ShortPause         ; a short pause; A still holds the lives
  LD HL,$5A58
  LD B,A
l_D1D9:
  LD (HL),$15             ; a cyan dot per life
  INC L
  DJNZ l_D1D9
ObjectSetup:
  LD HL,(CourseRecord)    ; the round's objects
  LD (RestartRecord),HL   ; a retry restarts this course
  LD A,$0A                ; the speed reserve $E7B8 = 10
  LD (SpeedReserve),A
  XOR A                   ; no followers
  LD (Followers),A
  LD HL,UdgLeftover+$009E
  LD (FollowerOffset),HL
  LD HL,ConvoyLinks+$0002 ; the follower list $ECE9 (pointer $ECF1): empty
  LD (ConvoyLinkEnd),HL
  LD B,$08
l_D1FB:
  LD (HL),$FF
  INC HL
  DJNZ l_D1FB
  LD HL,(PlayerRecord+$0001) ; how far the player has come, less $6C
  LD BC,$006C
  AND A
  SBC HL,BC
  LD (ConvoyShift),HL
  LD DE,PlayerRecord+$0001 ; the player's start fields +1-+7 from $C292
  LD HL,PlayerTemplate
  LD BC,$0007
  LDIR
  LD (ScrollDistance),BC  ; the scroll distance starts again (BC = 0 after
                          ; LDIR)
  LD A,(PlayerRecord)     ; the type of the round before: kept for the record
                          ; $C260
  LD HL,VehicleTemplate
  LD (HL),A
  INC HL
  LD DE,ParkedVehicleRecord+$0001 ; the parked vehicle $C0A1-$C0AF from $C2A2
  LD BC,$000F
  LDIR
  LD HL,(CourseRecord)    ; the course data
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD A,(DE)               ; the player's type, the course's first byte
  LD (PlayerRecord),A
  ADD A,$06               ; $C2BD = type + 6
  LD (LaunchTemplates+$0009),A
  LD A,(DE)               ; the parked vehicle is of the other type
  INC A
  AND $01
  LD (ParkedVehicleRecord),A
  LD A,(DE)               ; $C008 = 2 x type
  AND $0F
  ADD A,A
  LD (PlayerRecord+$0008),A
  LD B,$46                ; AUTO countdown: 70 passes, or 14 for a nonzero type
  AND A
  JR Z,l_D250
  LD B,$0E
l_D250:
  LD A,B
  LD (AutoCountdown),A
  LD E,(HL)               ; the object block of the round
  INC HL
  LD D,(HL)
  LD HL,CourseObjectRecords
  EX DE,HL
  LD B,$10                ; 16 course objects at $C0B0: 8 bytes from the block,
                          ; 8 zero
l_D25D:
  PUSH BC
  LD BC,$0008
  LDIR
  XOR A
  LD B,$08
l_D266:
  LD (DE),A
  INC DE
  DJNZ l_D266
  POP BC
  DJNZ l_D25D
  EX DE,HL
  LD DE,$0010             ; the 11 slots $C1B0-$C250 free
  LD B,$06
l_D273:
  LD (HL),$80
  ADD HL,DE
  DJNZ l_D273
  LD B,$05
l_D27A:
  LD (HL),$80
  ADD HL,DE
  DJNZ l_D27A
  LD A,(VehicleTemplate)  ; $C260: the vehicle of the round before, at $006C
  LD (HL),A
  INC L
  LD (HL),$6C
  INC L
  LD (HL),$00
  INC L
  LD DE,VehicleTemplate+$0003 ; its fields +3 on from $C2A4
  EX DE,HL
  LD BC,$000D
  LDIR
  EX DE,HL
  LD (HL),$FF             ; the end of the list ($C270)
  LD A,(LapNumber)        ; the lap: 0 skips the arming
  CP $01
  JR C,SetField8
  JR Z,LapArming
  LD A,$02                ; from lap 2, own operands: CP $05 becomes CP $02,
                          ; types 2-9 fire
  LD (l_D2B1+$000D),A
  LD A,$88                ; every launch pad's behaviour becomes $88
  LD (l_D2D7+$0001),A
  LD (l_D2DB+$0001),A
LapArming:
  LD HL,CourseObjectRecords ; arm the 16 course objects
  LD B,$10
l_D2B1:
  LD A,(HL)               ; the type
  AND $0F
  LD DE,$0007
  ADD HL,DE
  LD C,(HL)               ; C = the behaviour
  CP $0A
  JR NC,l_D2C6
  CP $05                  ; operand changed at $D2A1
  JR C,l_D2C6
  SET 3,C                 ; types 5-9 (2-9 from lap 2): fire
  LD (HL),C
  JR l_D2DD
l_D2C6:
  CP $0E                  ; type $0E, a launch pad: rotate what it launches
  JR NZ,l_D2DD
  LD A,C
  CP $18
  JR Z,l_D2D7
  CP $48
  JR Z,l_D2DB
  LD (HL),$88             ; others: $88
  JR l_D2DD
l_D2D7:
  LD (HL),$48             ; $18 becomes $48 (operand changed at $D2A6)
  JR l_D2DD
l_D2DB:
  LD (HL),$08             ; $48 becomes $08 (operand changed at $D2A9)
l_D2DD:
  LD DE,$0009
  ADD HL,DE
  DJNZ l_D2B1
SetField8:
  LD HL,PodRecords        ; every record from $C060 to the end: +8 = 2 x type
  LD DE,$0008
l_D2E9:
  LD A,(HL)
  CP $FF
  JR Z,l_D2F6
  AND $0F
  ADD A,A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  JR l_D2E9
l_D2F6:
  LD IX,PodRecords        ; the 4 records $C060-$C090 (the followers)
  LD B,$04
l_D2FC:
  LD L,(IX+$01)           ; position along less ConvoyShift
  LD H,(IX+$02)
  LD DE,(ConvoyShift)
  AND A
  SBC HL,DE
  LD (IX+$01),L
  LD (IX+$02),H
  LD (IX+$06),$00         ; speed 0
  LD DE,$0010
  ADD IX,DE
  DJNZ l_D2FC
  LD HL,RoundStartSound   ; the round sound: entry 5 of the effect table $F2E2
  CALL PlaySound
  LD A,(RoundNumber)      ; the course colour from the round
  DEC A
  AND $03
  LD B,A
  LD A,(DemoFlag)         ; the demo subtracts one less
  AND A
  JR Z,l_D32E
  DEC B
l_D32E:
  LD A,$06                ; ink 6 - that
  SUB B
  CP $05                  ; bright below 5
  JR NC,l_D337
  SET 6,A
l_D337:
  LD B,A

; Colour the cells of the blit address list with B
;
; Walks the address list at $D5B2 (BlitAddresses), screen addresses of the
; bottom lines of character cells ended by a high byte $FF, and sets the
; attribute of each cell to B. A high byte below $47 (the $0800 clip entries)
; is skipped; $47 gives row block $58xx, $48-$4F $59xx, $50 and up $5Axx
; (docs/08-hud-and-text.md 8.5). Reached by falling through from RoundSetup
; with the course colour, and called by the menu with B = 6.
PaintAttributes:
  LD DE,BlitAddresses
PaintCell:
  LD A,(DE)               ; the next screen address
  LD L,A
  INC DE
  LD A,(DE)
  INC DE
  LD H,$58                ; attribute row block $58
  CP $FF                  ; $FF ends the list
  RET Z
  CP $47                  ; below $47: a clipped entry
  JR C,PaintCell
  JR Z,l_D351             ; $47: block $58
  CP $50                  ; $48-$4F: block $59; $50 and up: $5A
  JR C,l_D350
  INC H
l_D350:
  INC H
l_D351:
  LD (HL),B               ; the cell's colour
  JR PaintCell

; A busy wait of 65 536 DJNZ steps
;
; About 0.85 million T-states, a quarter of a second. Keeps A. Used after
; hiding the dots (RoundSetup $D1D2, and on the last life lost at $D00A).
ShortPause:
  LD C,$00
l_D356:
  LD B,$00
l_D358:
  DJNZ l_D358
  DEC C
  JR NZ,l_D356
  RET
