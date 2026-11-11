; --------------------------------------------------------------------------------------------------------------------
; budget.asm: The budget
;
; The year's budget: the tax income from last year's population and the tax rate, the three requests (transport,
; police, fire) funded by percent and capped by the money, the window, and ApplyFunding which turns the shares into
; the roads' decay and the stations' strength.
; --------------------------------------------------------------------------------------------------------------------

; The year's budget window (the UI task, when BudgetDue): BudgetFigures, the
; window $91BC with the hook $9346; then the view
;
; L1 9.
BudgetWindow:
  LD A,$01
  LD (SwitchOff),A
  CALL TaxIncomeOf
  CALL BudgetFigures
  LD HL,BudgetHook
  LD (MenuHook),HL
  LD IX,BudgetWindowText
  CALL ShowWindow
  LD HL,$0000
  LD (MenuHook),HL
  XOR A
  LD (SwitchOff),A
  LD (BudgetDue),A
  JP DrawView

; The budget window's menu description: FISCAL BUDGET, the tax rate, the three
; fundings, the cash lines, GO WITH THESE FIGURES
;
; The numbers live inside the text (menu codes 5, 6, 7, section DrawMenu):
; TaxRate and the three funding percentages are the bytes the player edits.
BudgetWindowText:
  INCLUDE "res/text/menus/Budget.inc"

; 24 bits: last year's population / 100 x TaxRate
TaxIncome:
  DEFB $00,$00,$00
TransportCost:
  DEFB $00,$00            ; the year's requests (16 bits each): transport
                          ; upkeep, police, fire
PoliceCost:
  DEFB $00,$00
FireCost:
  DEFB $00,$00
TransportFunded:
  DEFB $00,$00            ; what is granted: the request x percent / 100,
                          ; capped by the money
PoliceFunded:
  DEFB $00,$00
FireFunded:
  DEFB $00,$00
FundedTotal:
  DEFB $00,$00,$00        ; 24 bits
CashFlow:
  DEFB $00,$00,$00        ; 24 bits: TaxIncome - FundedTotal
FundsBefore:
  DEFB $00,$00,$00        ; 24 bits
FundsAfter:
  DEFB $00,$00,$00        ; 24 bits: the new Funds

; TaxIncome = PopLastYear / 100 x TaxRate
;
; L1 77.
TaxIncomeOf:
  LD HL,(PopLastYear)
  LD A,(PopLastYear+$0002)
  LD C,A
  LD A,$64
  CALL Div24By8
  LD A,(TaxRate)
  LD E,A
  LD D,$00
  CALL Mul16
  LD (TaxIncome),HL
  LD A,C
  LD (TaxIncome+$0002),A
  RET

; The budget window's menu hook: recompute and print the figures while the
; player edits them
BudgetHook:
  LD A,$47
  LD (PrintAttr),A
  CALL BudgetFigures
  CALL PrintBudget
  LD A,$45
  LD (PrintAttr),A
  RET

; One byte no code reads
HookSpare:
  DEFB $00

; FundsBefore, the three fundings (request x percent), each capped so the money
; does not go below 0, the totals
;
; L1 1918.
BudgetFigures:
  LD HL,(Funds)
  LD A,(Funds+$0002)
  LD C,A
  LD (FundsBefore),HL
  LD A,C
  LD (FundsBefore+$0002),A
  CALL FundTransport
  CALL FundPolice
  CALL FundFire
  CALL CapTransport
  CALL CapPolice
  CALL CapFire
  CALL BudgetTotals
  RET

; FundTransport
;
; Used by the routine at BudgetFigures.
FundTransport:
  LD A,(TransportPercent)
  LD HL,(TransportCost)
  CALL Percent
  LD (TransportFunded),HL
  RET

; FundPolice
;
; Used by the routine at BudgetFigures.
FundPolice:
  LD A,(PolicePercent)
  LD HL,(PoliceCost)
  CALL Percent
  LD (PoliceFunded),HL
  RET

; FundFire
;
; Used by the routine at BudgetFigures.
FundFire:
  LD A,(FirePercent)
  LD HL,(FireCost)
  CALL Percent
  LD (FireFunded),HL
  RET

; FundedTotal, CashFlow, FundsAfter = Funds - FundedTotal + TaxIncome
;
; Used by the routine at BudgetFigures.
BudgetTotals:
  LD HL,(TransportFunded)
  LD DE,(PoliceFunded)
  LD BC,$0000
  CALL Add24
  LD DE,(FireFunded)
  CALL Add24
  LD (FundedTotal),HL
  LD A,C
  LD (FundedTotal+$0002),A
  LD B,C
  EX DE,HL
  LD HL,(TaxIncome)
  LD A,(TaxIncome+$0002)
  LD C,A
  CALL Sub24
  LD (CashFlow),HL
  LD A,C
  LD (CashFlow+$0002),A
  LD HL,(Funds)
  LD A,(Funds+$0002)
  LD C,A
  LD DE,(FundedTotal)
  LD A,(FundedTotal+$0002)
  LD B,A
  CALL Sub24
  LD DE,(TaxIncome)
  LD A,(TaxIncome+$0002)
  LD B,A
  CALL Add24
  LD (FundsAfter),HL
  LD A,C
  LD (FundsAfter+$0002),A
  RET

; 24 bits: the money left for a funding
CapWork:
  DEFB $00,$00,$00

; TransportFunded at most FundsBefore + TaxIncome
;
; Used by the routine at BudgetFigures.
CapTransport:
  LD HL,(FundsBefore)
  LD A,(FundsBefore+$0002)
  LD C,A
  LD DE,(TaxIncome)
  LD A,(TaxIncome+$0002)
  LD B,A
  CALL Add24
  LD (CapWork),HL
  LD A,C
  LD (CapWork+$0002),A
  LD DE,(TransportFunded)
  LD B,$00
  CALL Sub24
  BIT 7,C
  RET Z
  LD HL,(CapWork)
  LD A,(CapWork+$0002)
  LD C,A
  LD (TransportFunded),HL
  RET

; PoliceFunded at most what is left after the transport
;
; Used by the routine at BudgetFigures.
CapPolice:
  LD HL,(FundsBefore)
  LD A,(FundsBefore+$0002)
  LD C,A
  LD DE,(TaxIncome)
  LD A,(TaxIncome+$0002)
  LD B,A
  CALL Add24
  LD DE,(TransportFunded)
  LD B,$00
  CALL Sub24
  LD (CapWork),HL
  LD A,C
  LD (CapWork+$0002),A
  LD DE,(PoliceFunded)
  LD B,$00
  CALL Sub24
  BIT 7,C
  RET Z
  LD HL,(CapWork)
  LD A,(CapWork+$0002)
  LD C,A
  LD (PoliceFunded),HL
  RET

; FireFunded at most what is left after both
;
; Used by the routine at BudgetFigures.
CapFire:
  LD HL,(FundsBefore)
  LD A,(FundsBefore+$0002)
  LD C,A
  LD DE,(TaxIncome)
  LD A,(TaxIncome+$0002)
  LD B,A
  CALL Add24
  LD DE,(TransportFunded)
  LD B,$00
  CALL Sub24
  LD DE,(PoliceFunded)
  LD B,$00
  CALL Sub24
  LD (CapWork),HL
  LD A,C
  LD (CapWork+$0002),A
  LD DE,(FireFunded)
  LD B,$00
  CALL Sub24
  BIT 7,C
  RET Z
  LD HL,(CapWork)
  LD A,(CapWork+$0002)
  LD C,A
  LD (FireFunded),HL
  RET

; Print the figures into the budget window
;
; L1 1841.
PrintBudget:
  LD BC,$0516
  LD HL,TaxIncome
  CALL PrintNumberVar
  LD BC,$1216
  LD HL,FundsBefore
  CALL PrintNumberVar
  LD HL,(TransportFunded)
  LD BC,$0B11
  CALL PrintNumberHL
  LD HL,(TransportCost)
  LD BC,$0B09
  CALL PrintNumberHL
  LD HL,(PoliceFunded)
  LD BC,$0C11
  CALL PrintNumberHL
  LD HL,(PoliceCost)
  LD BC,$0C09
  CALL PrintNumberHL
  LD HL,(FireFunded)
  LD BC,$0D11
  CALL PrintNumberHL
  LD HL,(FireCost)
  LD BC,$0D09
  CALL PrintNumberHL
  LD BC,$1116
  LD HL,CashFlow
  CALL PrintNumberVar
  LD BC,$1416
  LD HL,FundsAfter
  CALL PrintNumberVar
  RET

; HL = HL x A / 100
;
; Used by the routines at FundTransport, FundPolice and FundFire.
Percent:
  LD E,A
  LD D,$00
  CALL Mul16
  LD A,$64
  JP Div24By8

; By funded / (cost / 8), 0-15: the roads' and rails' decay mask ($0F crumbles
; most, $FF none)
DecayMasks:
  INCBIN "res/tables/Funding.bin",$0000,16
StrengthLevels:
  INCBIN "res/tables/Funding.bin",$0010,16

; The year's fundings to the city: RoadDecay and RailDecay, PoliceStrength,
; FireStrength by the share granted
;
; A request below 20 counts as fully paid. The fire branch tests TransportCost
; against 20, not FireCost (a slip: with transport costs below 20 the fire is
; always fully strong, FireStrength = 15 whatever the funding). BUG: with
; transport at 20 or more and no fire station, FireCost / 8 = 0 and Div16 by
; zero returns 0, so FireStrength = 0 (city recording, frame 8 500, JAN 1903).
; L1 74.
ApplyFunding:
  LD A,$FF
  LD HL,(TransportCost)
  LD DE,$0014
  AND A
  SBC HL,DE
  JR C,ApplyPolice
  LD HL,(TransportCost)
  SRL H
  RR L
  SRL H
  RR L
  SRL H
  RR L
  EX DE,HL
  LD HL,(TransportFunded)
  CALL Div16
  LD C,L
  LD B,$00
  LD HL,DecayMasks
  ADD HL,BC
  LD A,(HL)
ApplyPolice:
  LD (RoadDecay),A
  LD (RailDecay),A
  LD A,$0F
  LD HL,(PoliceCost)
  LD DE,$0014
  AND A
  SBC HL,DE
  JR C,ApplyFire
  LD HL,(PoliceCost)
  SRL H
  RR L
  SRL H
  RR L
  SRL H
  RR L
  EX DE,HL
  LD HL,(PoliceFunded)
  CALL Div16
  LD C,L
  LD B,$00
  LD HL,StrengthLevels
  ADD HL,BC
  LD A,(HL)
ApplyFire:
  LD (PoliceStrength),A
  LD A,$0F
  LD HL,(TransportCost)   ; BUG: LD HL,(TransportCost), not FireCost
  LD DE,$0014
  AND A
  SBC HL,DE
  JR C,ApplyFireStore
  LD HL,(FireCost)
  SRL H
  RR L
  SRL H
  RR L
  SRL H
  RR L
  EX DE,HL
  LD HL,(FireFunded)
  CALL Div16
  LD C,L
  LD B,$00
  LD HL,StrengthLevels
  ADD HL,BC
  LD A,(HL)
ApplyFireStore:
  LD (FireStrength),A
  RET
