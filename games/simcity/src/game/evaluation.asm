; --------------------------------------------------------------------------------------------------------------------
; evaluation.asm: The evaluation and the advice
;
; The EVALUATION window: the category (from 2000, 10 000, 50 000, 100 000, 500 000 people), the problems, the score
; and the poll; Advise picks the advice line every pass.
; --------------------------------------------------------------------------------------------------------------------

; The WINDOWS menu's EVALUATION: the window $95D7 with the hook Evaluate
EvaluationWindow:
  LD A,$01
  LD (SwitchOff),A
  LD HL,Evaluate
  LD (MenuHook),HL
  LD IX,EvaluationText
  CALL ShowWindow
  LD HL,$0000
  LD (MenuHook),HL
  XOR A
  LD (SwitchOff),A
  JP DrawView

; The evaluation window: the poll, the worst problems, population, migration,
; value, category, level, score
EvaluationText:
  INCBIN "res/text/menus/Evaluation.bin",$0000,352

; The evaluation hook: the category, the figures; with a population, the
; problems, the score and the poll
;
; L1 18.
Evaluate:
  CALL CategoryOf
  CALL PrintEvalFigures
  LD HL,LastPop
  LD A,(HL)
  INC HL
  OR (HL)
  INC HL
  OR (HL)
  RET Z
  CALL Problems
  CALL ScoreOf
  CALL Poll
  RET

; The five population limits (24 bits): 2000, 10 000, 50 000, 100 000, 500 000
CategoryLimits:
  INCBIN "res/tables/CategoryLimits.bin",$0000,15

; 0 VILLAGE, 1 TOWN, 2 CITY, 3 CAPITAL, 4 METROPOLIS, 5 MEGALOPOLIS
Category:
  DEFB $00

; Category = how many CategoryLimits PopLastYear reaches (not below)
;
; Only the evaluation window computes it, from the population at the last
; year's end: the category changes nothing in the game. L1 18.
CategoryOf:
  XOR A
  LD (Category),A
  LD IX,CategoryLimits
  LD B,$05
CategoryLoop:
  PUSH BC
  LD DE,(PopLastYear)
  LD A,(PopLastYear+$0002)
  LD B,A
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD C,(IX+$02)
  CALL Sub24
  POP BC
  AND A
  RET P
  LD HL,Category
  INC (HL)
  INC IX
  INC IX
  INC IX
  DJNZ CategoryLoop
  RET

; PopLastYear - PopYearBefore (24 bits)
Migration:
  DEFB $00,$00,$00

; The level, the category, the population, the migration, the assessed value
; (CityValueLast) followed by 000 (x 1000: two CALL PrintZero and a
; fall-through)
;
; POPULATION is LastPop (last month's), not the year's population.
PrintEvalFigures:
  LD HL,GameTexts
  LD A,(Level)
  ADD A,$0E
  CALL FindText
  LD BC,$140F
  LD A,$08
  CALL PrintPadded
  LD HL,GameTexts
  LD A,(Category)
  ADD A,$11
  CALL FindText
  LD BC,$130F
  LD A,$0A
  CALL PrintPadded
  LD HL,LastPop
  LD BC,$0F14
  CALL PrintNumberVar
  LD HL,(PopLastYear)
  LD A,(PopLastYear+$0002)
  LD C,A
  LD DE,(PopYearBefore)
  LD A,(PopYearBefore+$0002)
  LD B,A
  CALL Sub24
  LD (Migration),HL
  LD A,C
  LD (Migration+$0002),A
  LD HL,Migration
  LD BC,$1014
  CALL PrintNumberVar
  LD HL,CityValueLast
  LD BC,$1114
  CALL PrintNumberVar
  LD HL,(NumberEnd)
  LD (PrintAddr),HL
  CALL PrintZero
  CALL PrintZero

; Print "0" and step on
;
; Used by the routine at PrintEvalFigures.
PrintZero:
  LD A,$30
  CALL PrintChar
  CALL NextColumn
  RET

; The problems added up
ProblemSum:
  DEFB $00,$00

; Each problem 0-100 printed (red from 20): traffic AvgTraffic / 2, pollution /
; 2, crime / 4, fire 5 FireCells, taxes 4 (rate - 3), house prices
; AvgLandValue, unemployment PopBalance; plus UnpoweredZones / 4 and 4 for an
; advice
;
; L1 18.
Problems:
  LD A,(AvgTraffic)
  SRL A
  LD L,A
  LD H,$00
  CALL Clamp100
  LD (ProblemSum),HL
  LD BC,$0A09
  CALL PrintProblem
  LD A,(AvgPollution)
  SRL A
  LD L,A
  LD H,$00
  CALL Clamp100
  PUSH HL
  LD BC,$0A1B
  CALL PrintProblem
  POP HL
  LD DE,(ProblemSum)
  ADD HL,DE
  LD (ProblemSum),HL
  LD A,(AvgCrime)
  SRL A
  SRL A
  LD L,A
  LD H,$00
  CALL Clamp100
  PUSH HL
  LD BC,$0B09
  CALL PrintProblem
  POP HL
  LD DE,(ProblemSum)
  ADD HL,DE
  LD (ProblemSum),HL
  LD A,(LastFireCells)
  LD L,A
  LD H,$00
  LD D,H
  LD E,L
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  CALL Clamp100
  PUSH HL
  LD BC,$0B1B
  CALL PrintProblem
  POP HL
  LD DE,(ProblemSum)
  ADD HL,DE
  LD (ProblemSum),HL
  LD A,(TaxRate)
  LD L,A
  LD H,$00
  LD DE,$FFFD
  ADD HL,DE
  LD D,H
  LD E,L
  ADD HL,HL
  ADD HL,HL
  CALL Clamp100
  PUSH HL
  LD BC,$0C09
  CALL PrintProblem
  POP HL
  LD DE,(ProblemSum)
  ADD HL,DE
  LD (ProblemSum),HL
  LD A,(AvgLandValue)
  LD L,A
  LD H,$00
  CALL Clamp100
  PUSH HL
  LD BC,$0C1B
  CALL PrintProblem
  POP HL
  LD DE,(ProblemSum)
  ADD HL,DE
  LD (ProblemSum),HL
  LD HL,(PopBalance)
  CALL Clamp100
  PUSH HL
  LD BC,$0D1B
  CALL PrintProblem
  POP HL
  LD DE,(ProblemSum)
  ADD HL,DE
  LD (ProblemSum),HL
  LD DE,(UnpoweredZones)
  SRL D
  RR E
  SRL D
  RR E
  LD HL,(ProblemSum)
  ADD HL,DE
  LD (ProblemSum),HL
  LD DE,$0000
  LD A,(Advice)
  AND A
  JR Z,ProblemsEnd
  LD DE,$0004
ProblemsEnd:
  LD HL,(ProblemSum)
  ADD HL,DE
  LD (ProblemSum),HL
  RET

; HL to 0-100
;
; Used by the routine at Problems.
Clamp100:
  LD A,H
  AND A
  JR Z,Clamp100Low
  JP M,Clamp100Zero
  JP P,Clamp100High
Clamp100Low:
  LD A,L
  CP $65
  RET C
Clamp100High:
  LD HL,$0064
  RET
Clamp100Zero:
  LD HL,$0000
  RET

; 0-1000
CityScore:
  DEFW $0000

; CityScore = 4 (250 - 3 ProblemSum), 0-1000
;
; Used by the routine at Evaluate.
ScoreOf:
  LD HL,(ProblemSum)
  LD D,H
  LD E,L
  ADD HL,HL
  ADD HL,DE
  EX DE,HL
  LD HL,$00FA
  AND A
  SBC HL,DE
  ADD HL,HL
  ADD HL,HL
  CALL Clamp1000
  LD (CityScore),HL
  LD BC,$150F
  CALL PrintNumberHL
  RET

; Clamp1000
;
; Used by the routine at ScoreOf.
Clamp1000:
  LD A,H
  AND A
  JP P,Clamp1000Pos
  LD HL,$0000
  RET
Clamp1000Pos:
  EX DE,HL
  LD HL,$03E8
  AND A
  SBC HL,DE
  JR NC,Clamp1000End
  LD D,H
  LD E,L
Clamp1000End:
  EX DE,HL
  RET

; The poll: of 100 Random draws (0-1023), how many are below CityScore (YES)
; and not (NO)
PollYes:
  DEFB $00
PollNo:
  DEFB $00

; Poll
;
; Used by the routine at Evaluate.
Poll:
  LD HL,$0000
  LD (PollYes),HL
  LD B,$64
PollLoop:
  CALL Random
  LD HL,(RandomSeed)
  LD A,H
  AND $03
  LD H,A
  LD DE,(CityScore)
  AND A
  SBC HL,DE
  JR NC,PollNo1
  LD HL,PollYes
  JR PollCount
PollNo1:
  LD HL,PollNo
PollCount:
  INC (HL)
  DJNZ PollLoop
  LD A,(PollYes)
  LD L,A
  LD H,$00
  LD BC,$050C
  CALL PrintPercent
  LD A,(PollNo)
  LD L,A
  LD H,$00
  LD BC,$060C
  CALL PrintPercent
  RET

; HL in 3 digits at BC, attribute $42 (red) from 20
;
; Used by the routine at Problems.
PrintProblem:
  PUSH HL
  LD A,L
  CP $14
  JR C,PrintProblemAt
  LD A,$42
  LD (PrintAttr),A
PrintProblemAt:
  CALL ScreenAddr
  LD (PrintAddr),HL
  POP HL
  CALL Print3Digits
  LD A,$47
  LD (PrintAttr),A
  RET

; HL in 3 digits at BC
;
; Used by the routine at Poll.
PrintPercent:
  PUSH HL
  CALL ScreenAddr
  LD (PrintAddr),HL
  POP HL
  JP Print3Digits

; The advice shown (0 none, 1-$15): GameTexts 23 + Advice
Advice:
  DEFB $00

; Print GameTexts[23 + Advice] at row 6, column 1, padded to 30 columns
;
; L1 4944.
ShowAdvice:
  LD A,(Advice)
  ADD A,$17
  LD HL,GameTexts
  CALL FindText
  LD A,$1D
  LD BC,$0601
  JP PrintPadded

; One byte no code reads
AdviceSpare:
  DEFB $00
AllZones:
  DEFB $00                ; ResPop + ComPop + IndPop (16 bits)
  DEFB $00

; The advice: the first rule that fires sets Advice (the later ones may
; overwrite, CALL NC)
;
; In order: R at most a quarter of all zones (1), C at most an eighth (2), I
; (3); then, with people: roads fewer than zones from 10 zones (4), rails from
; 50 (5), no power station from 10 (6), no stadium from 20 R (7), no seaport
; from 30 I (8), no airport from 30 C (9), no fire station from 30 zones (10),
; no police from 25 (11), tax 12+ (12), transport underfunded (13), fire (14),
; police (15), 10+ unpowered zones (16), a brownout (17), pollution 60+ (19),
; crime 20+ (20), traffic 60+ (21). L1 1089.
Advise:
  XOR A
  LD (Advice),A
  LD HL,(ResPop)
  LD DE,(ComPop)
  ADD HL,DE
  LD DE,(IndPop)
  ADD HL,DE
  LD (AllZones),HL
  LD HL,(AllZones)
  SRL H
  RR L
  SRL H
  RR L
  LD DE,(ResPop)
  AND A
  SBC HL,DE
  LD A,$01
  JP Z,SetAdvice
  JP NC,SetAdvice
  LD HL,(AllZones)
  SRL H
  RR L
  SRL H
  RR L
  SRL H
  RR L
  LD DE,(ComPop)
  AND A
  SBC HL,DE
  LD A,$02
  JP Z,SetAdvice
  JP NC,SetAdvice
  LD HL,(AllZones)
  SRL H
  RR L
  SRL H
  RR L
  SRL H
  RR L
  LD DE,(IndPop)
  AND A
  SBC HL,DE
  LD A,$03
  JP Z,SetAdvice
  JP NC,SetAdvice
  LD HL,LastPop
  LD A,(HL)
  INC HL
  OR (HL)
  INC HL
  OR (HL)
  RET Z
  LD HL,(AllZones)
  LD DE,$000A
  AND A
  SBC HL,DE
  JR C,AdviseRails
  LD HL,(AllZones)
  LD DE,(RoadCount)
  AND A
  SBC HL,DE
  LD A,$04
  CALL NC,SetAdvice
AdviseRails:
  LD HL,(AllZones)
  LD DE,$0032
  AND A
  SBC HL,DE
  JR C,AdvisePower
  LD HL,(AllZones)
  LD DE,(RailCount)
  AND A
  SBC HL,DE
  LD A,$05
  CALL NC,SetAdvice
AdvisePower:
  LD HL,(AllZones)
  LD DE,$000A
  AND A
  SBC HL,DE
  JR C,AdviseStadium
  LD HL,(NuclearCount)
  LD DE,(CoalCount)
  ADD HL,DE
  LD A,H
  OR L
  LD A,$06
  JP Z,SetAdvice
AdviseStadium:
  LD A,(StadiumCount)
  AND A
  JR NZ,AdviseSeaport
  LD HL,(ResPop)
  LD DE,$0014
  AND A
  SBC HL,DE
  LD A,$07
  JP NC,SetAdvice
AdviseSeaport:
  LD A,(SeaportCount)
  AND A
  JR NZ,AdviseAirport
  LD HL,(IndPop)
  LD DE,$001E
  AND A
  SBC HL,DE
  LD A,$08
  JP NC,SetAdvice
AdviseAirport:
  LD A,(AirportCount)
  AND A
  JR NZ,AdviseFire
  LD HL,(ComPop)
  LD DE,$001E
  AND A
  SBC HL,DE
  LD A,$09
  JP NC,SetAdvice
AdviseFire:
  LD A,(FireCount)
  AND A
  JR NZ,AdvisePolice
  LD HL,(AllZones)
  LD DE,$001E
  AND A
  SBC HL,DE
  LD A,$0A
  JP NC,SetAdvice
AdvisePolice:
  LD A,(PoliceCount)
  AND A
  JR NZ,AdviseTax
  LD HL,(AllZones)
  LD DE,$0019
  AND A
  SBC HL,DE
  LD A,$0B
  JP NC,SetAdvice
AdviseTax:
  LD A,(TaxRate)
  CP $0C
  LD A,$0C
  JP NC,SetAdvice
  LD HL,(RailCount)
  LD DE,(RoadCount)
  ADD HL,DE
  LD A,H
  OR L
  JR Z,AdviseFireFunds
  LD A,(RoadDecay)
  CP $FF
  LD A,$0D
  JP NZ,SetAdvice
AdviseFireFunds:
  LD HL,(FireCount)
  LD A,H
  OR L
  JR Z,AdvisePoliceFunds
  LD A,(FireStrength)
  CP $0F
  LD A,$0E
  JP NZ,SetAdvice
AdvisePoliceFunds:
  LD HL,(PoliceCount)
  LD A,H
  OR L
  JR Z,AdviseUnpowered
  LD A,(PoliceStrength)
  CP $0F
  LD A,$0F
  JP NZ,SetAdvice
AdviseUnpowered:
  LD HL,(UnpoweredZones)
  LD DE,$000A
  AND A
  SBC HL,DE
  LD A,$10
  JP NC,SetAdvice
  LD A,(Brownout)
  AND A
  LD A,$11
  JP NZ,SetAdvice
  LD A,(AvgPollution)
  CP $3C
  LD A,$13
  CALL NC,SetAdvice
  LD A,(AvgCrime)
  CP $14
  LD A,$14
  CALL NC,SetAdvice
  LD A,(AvgTraffic)
  CP $3C
  LD A,$15
  CALL NC,SetAdvice
  RET

; Advice = A (the disasters' messages too)
;
; Used by the routines at AirCrash, NuclearMeltdown, StartTornado,
; FireDisaster, FloodDisaster, Earthquake and Advise.
SetAdvice:
  LD (Advice),A
  RET
