; --------------------------------------------------------------------------------------------------------------------
; commander.asm: The commander menu (load and save on tape, the security number), the view names and the message line
;
; CommanderMenu $D90A is the ACCESS MENU page (SYMBOL SHIFT docked, KeySteer bit 5 in FlightLoop, or Y on the title;
; other token 1): 1 loads a commander, 2 saves one, 3 leaves. A commander on tape is one headerless data block of the
; 102 bytes $D054-$D0B9, read and written by the ROM's LD-BYTES and SA-BYTES entered past their prologues. After a
; load or a save the record is also copied to DefaultCommander ($D232), the commander a new game (and the death)
; starts from. Neither tape path ran in the recordings (known from the code only).
;
; The bottom of the space view is the message line (row 14 of the screen above the dashboard): MessageTick keeps the
; ten message slots ($D0BD-$D0D0), shows one for 14 passes, and between messages raises the periodic ones (ENERGY LOW,
; FUEL SCOOPS ON, DOCKING COMPUTERS ON, the mission's MAYDAY texts).
; --------------------------------------------------------------------------------------------------------------------

; The menu page's colour bands for ColourBands: one cell and a gap of 4 rows,
; two cells and 2 rows twice, two cells and 3 rows, sixteen cells and the end
MenuBands:
  DEFB $0C,$12,$12,$13,$80

; 1 once a commander has been loaded: CommanderMenu returns it
TapeLoaded:
  DEFB $00

; SP at the menu's start: every pass and every error path starts again from it
MenuStack:
  DEFW $0000

; The ACCESS MENU: 1 load, 2 save, 3 leave; returns A = 1 (NZ) when a commander
; was loaded
;
; The page is cleared, coloured (MenuBands, the message row, the top three
; attribute rows $0F and a rule at $4740 by MenuTop), and other token 1 prints
; the three choices. The keys are read by WaitKey; the stack is reset from
; MenuStack before each, so a BREAK or an error deep in the tape code just
; comes back here.
CommanderMenu:
  CALL ClearScreen
  LD DE,MenuBands
  CALL ColourBands
  CALL FillAttrRow
  LD A,$0F
  CALL MenuTop
  XOR A
  LD (TapeLoaded),A
  INC A
  CALL PrintOther
  LD (MenuStack),SP
; This entry point is used by the routine at KeepCommander.
CommanderMenuKey:
  LD SP,(MenuStack)
  CALL WaitKey
  SUB $31
  JR Z,LoadCommander
  DEC A
  JP Z,SaveCommander
  DEC A
  JR NZ,CommanderMenuKey
CommanderMenuExit:
  CALL ClickWait
  CALL ClearKeys4
  LD A,(TapeLoaded)
  AND A
  RET NZ
  XOR A
  RET

; 1: the name to look for (empty: the first commander found), then blocks until
; the names agree
;
; The ROM's LD-BYTES is entered at $0562, after its own INC D / EX AF,AF' / DEC
; D / DI (copied here before the CALL), so it returns to the game and not
; through SA/LD-RET. The record is loaded in place over $D054: a block whose
; name differs is simply followed by the next one. FOUND COMMANDER (other $D6)
; names each block read.
LoadCommander:
  LD HL,NameInput
  CALL ReadName
LoadCommanderBlock:
  CALL TapeBlock
  SCF
  INC D
  EX AF,AF'
  DEC D
  DI
  CALL $0562
  EI
  JP NC,LoadFailed
  LD A,$01
  LD (TapeLoaded),A
  LD A,$D6
  CALL TapeMessage
LoadCommanderName:
  LD HL,NameInput
  LD DE,CommanderName
  LD A,(HL)
  AND A
  JP Z,KeepCommander
  LD B,$0B
LoadCommanderCompare:
  LD A,(DE)
  CP (HL)
  JR NZ,LoadCommanderBlock
  OR (HL)
  JP Z,KeepCommander
  INC HL
  INC DE
  DJNZ LoadCommanderCompare
  JR LoadCommanderBlock

; 2: the name into the record, the sun's place into its tail, START TAPE,
; SA-BYTES, then the security number
;
; SA-BYTES is entered at $04C6, past the PUSH of SA/LD-RET, so it comes back
; here with the border as it left it (set black at once) and the interrupts off
; (EI here). The nine bytes of SunPosition go into the record's tail $D0B1 so a
; loaded commander gets its sun back.
SaveCommander:
  LD HL,CommanderName
  CALL ReadName
  LD HL,SunPosition
  LD DE,RecordTail
  LD BC,$0009
  LDIR
  LD A,$02
  CALL TapeMessage
  CALL WaitKey
  CALL TapeBlock
  CALL $04C6
  LD A,$00
  OUT ($FE),A
  EI
  JP NC,TapeBreak
  LD A,$97
  CALL TapeMessage

; Print "SECURITY NUMBER:" and two five-digit numbers made from the combat
; score, the galaxy, two mission flags and the cash
;
; D takes the galaxy (bits 0-2) and the mission flags' bits 3 and 6, three
; places up, then the parities of E (the combat score's middle byte, doubled),
; H and L (the cash in thousands): Parity shifts each in from the top. The four
; bytes are then chained: D = L xor D + $3D, E = D xor E + $66, H = E xor H +
; $8F, L = H xor L + $C7, and DE and HL are printed. The game never reads the
; number back; a checker with the same chain can test a claimed rank and cash
; (inference: the code only prints it).
SecurityNumber:
  LD HL,$0C01
  LD (TextColumn),HL
  LD A,$04
  CALL PrintOther
  LD HL,(CombatScore+$0001)
  RL L
  LD E,H
  RL E
  LD A,(CommanderRest+$0002)
  LD HL,MissionFlags
  BIT 3,(HL)
  JR Z,SecurityNumberIfZero
  SET 3,A
SecurityNumberIfZero:
  BIT 6,(HL)
  JR Z,SecurityNumberGetCommanderRest3
  SET 4,A
SecurityNumberGetCommanderRest3:
  LD HL,(CommanderRest+$0003)
  RLCA
  RLCA
  RLCA
  LD D,A
  LD A,E
  CALL Parity
  LD A,H
  CALL Parity
  LD A,L
  CALL Parity
  LD A,L
  XOR D
  ADD A,$3D
  LD D,A
  XOR E
  ADD A,$66
  LD E,A
  XOR H
  ADD A,$8F
  LD H,A
  XOR L
  ADD A,$C7
  LD L,A
  PUSH DE
  AND A
  CALL PrintNumber
  LD A,$05
  LD (Messages+$0011),A
  XOR A
  LD (Messages+$000F),A
  POP HL
  AND A
  CALL PrintNumber

; The record becomes DefaultCommander (93 bytes), back to the menu
;
; Used by the routine at LoadCommander.
KeepCommander:
  LD HL,CommanderName
  LD DE,DefaultCommander
  LD BC,$005D
  LDIR
; This entry point is used by the routines at TapeBreak and TapeError.
CommanderMenuAgain:
  JP CommanderMenuKey

; The parity of A's eight bits into the top of D (C = the count of ones, its
; bit 0 shifted in)
;
; Used by the routine at SecurityNumber.
Parity:
  LD B,$08
  LD C,$00
ParityLoop:
  RRA
  JR NC,ParityNext
  INC C
ParityNext:
  DJNZ ParityLoop
  RR C
  RR D
  RET

; One frame, then BREAK if SPACE is held (FC0D = $20), else TAPE LOADING ERROR
; and the record back from DefaultCommander
;
; Used by the routine at LoadCommander.
LoadFailed:
  HALT
  LD A,(KeyCode)
  CP $20
  JR NZ,TapeError

; The message lines cleared and BREAK
;
; Used by the routine at SaveCommander.
TapeBreak:
  CALL ClearInputRows
  LD A,$C7
  CALL TapeMessage
  JR CommanderMenuAgain

; TapeError
;
; Used by the routine at LoadFailed.
TapeError:
  LD A,$03
  CALL TapeMessage
  LD HL,DefaultCommander
  LD DE,CommanderName
  LD BC,$005D
  LDIR
  JR CommanderMenuAgain

; IX = the record, DE = 102, A = $FF (a data block)
;
; Used by the routines at LoadCommander and SaveCommander.
TapeBlock:
  LD IX,CommanderName
  LD DE,$0066
  LD A,$FF
  RET

; Read a name of up to 10 letters into HL after COMMANDER'S NAME? (other 8)
;
; Used by the routines at LoadCommander and SaveCommander.
ReadName:
  LD B,$0A
  LD A,$08
  JP ReadLine

; Other token A on the message row 22, after the row is cleared; a new line, a
; click
;
; Used by the routines at LoadCommander, SaveCommander, TapeBreak and
; TapeError.
TapeMessage:
  PUSH AF
  XOR A
  LD (PrintCase),A
  LD HL,$1600
  LD (TextColumn),HL
  CALL ClearRow22
  POP AF
  CALL PrintOther
  CALL NewLine
  JP Click

; Counts 70 passes between the periodic messages
MessageTimer:
  DEFB $00

; The passes the message on the line has left (14 from MessageShow)
MessageShown:
  DEFB $00

; Toggled each pass: the slots are scanned on even passes, the periodic
; messages on odd ones
MessagePass:
  DEFB $00

; The message's column on row 14
MessageColumn:
  DEFB $00

; The message's standard code: $FD (token $5D, " DESTROYED") after MessageItem,
; $E2 (token $42, " CR") after MessageNumber, 0 none
MessageToken:
  DEFB $00

; The bounty AddCash shows, in tenths
MessageNumber:
  DEFW $0000

; The item DamageItem destroyed, a standard code (equipment $6C on, cargo $CC
; on)
MessageItem:
  DEFB $F5

; The space view's name ("FRONT VIEW" and the like) into the back buffer, then
; MessageTick
;
; Called each pass (1220 times in c1). The name is plotted with SET 7 at $D50A,
; so PlotChar writes into the back buffer at $C000 and the frame copy shows it
; on top of the stars. On the screens (view 4 and up) the plot byte $D548 is
; set to write over (NOP) while MessageTick runs and back to mixing (XOR C)
; after.
ViewTexts:
  XOR A
  LD (PrintCase),A
  LD A,(ViewIndex)
  CP $04
  JR C,ViewTextsSpace
  LD HL,PlotCharLine+$0002
  LD (HL),$00
  CALL MessageTick
  LD HL,PlotCharLine+$0002
  LD (HL),$A9
  RET
ViewTextsSpace:
  LD HL,PlotCharGlyph+$0019
  SET 7,(HL)
  LD HL,$010A
  LD (TextColumn),HL
  LD A,(ViewIndex)
  ADD A,$60
  CALL PrintCode
  LD A,$AF
  CALL PrintCodeLine
  CALL MessageTick
  LD HL,PlotCharGlyph+$0019
  RES 7,(HL)
  RET

; The jump countdown, the condition light, then the message line: show, scan
; the slots, or raise a periodic message
;
; The ten slots at $D0BD hold a column and a code each, bit 7 of the column a
; request (FullMessage and the market set them). On an even pass the first
; request found is taken (its bit cleared, a click) and shown for 14 passes. A
; shown message is plotted once a pass from its fourth pass on and only in the
; space views, so it blinks on as the screen copy overwrites it: XOR plotting
; twice would clear it.
MessageTick:
  CALL JumpTick
  CALL ConditionLightVector
  LD HL,MessageShown
  LD A,(HL)
  AND A
  JR NZ,MessagePrint
  LD HL,MessagePass
  INC (HL)
  BIT 0,(HL)
  JR NZ,MessagePeriodic
MessageScan:
  LD B,$0A
  LD HL,Messages
MessageScanLoop:
  BIT 7,(HL)
  JR NZ,MessageTake
  INC HL
  INC HL
  DJNZ MessageScanLoop
  RET
MessageTake:
  RES 7,(HL)
  LD C,(HL)
  INC HL
  LD B,(HL)
; This entry point is used by the routine at JumpKeys.
MessageTickJoin:
  PUSH BC
  CALL Click
  POP BC

; Show standard code B at column C for 14 passes
;
; Used by the routine at MessagePeriodic.
MessageShow:
  LD A,$0E
  LD (MessageShown),A

; Code B at column C, the count left as it is
;
; Used by the routine at JumpKeys.
MessageSet:
  LD A,C
  LD (MessageColumn),A
  LD A,B
  LD (MessageToken),A
  RET
; This entry point is used by the routine at MessageTick.
MessagePrint:
  DEC (HL)
  CP $04
  RET C
  LD A,(ViewIndex)
  CP $04
  RET NC
  LD A,(MessageColumn)
  LD L,A
  LD H,$0E
  LD (TextColumn),HL
  LD A,(MessageToken)
  CP $FD
  JR Z,MessageDestroyed
  CP $E2
  JR Z,MessageBounty
MessagePrintCode:
  LD A,(MessageToken)
  JP PrintCodeLine
MessageDestroyed:
  LD A,(MessageItem)      ; $FD: the item's name (three columns on, except code
                          ; $73) and DESTROYED
  CP $73
  JR Z,MessageDestroyedName
  LD HL,TextColumn
  INC (HL)
  INC (HL)
  INC (HL)
MessageDestroyedName:
  CALL PrintCode
  JR MessagePrintCode
MessageBounty:
  LD HL,(MessageNumber)   ; $E2: the bounty and CR
  SCF
  CALL PrintNumber
  JR MessagePrintCode

; Every 70 passes: ENERGY LOW, FUEL SCOOPS ON (and the fuel), DOCKING COMPUTERS
; ON, or the mission's MAYDAY
;
; In this order: the fourth energy bank below $9F gives ENERGY LOW (code $64)
; at once each odd pass and turns the cloak off (CloakOn 0); the sun near with
; a fuel scoop fitted adds 0.1 light years (SetFuel) and shows FUEL SCOOPS ON
; (code $A0); the docking computer on shows DOCKING COMPUTERS ON (code $7B).
; Otherwise MessageTimer counts 70 odd passes, then the mission state 1 shows
; its MAYDAY (code $0F, token $81: "... INVADED") and NovaMission (the second
; mission) "MAYDAY CORIOLIS IN DANGER" (code $C2) unless the sun is already
; growing.
MessagePeriodic:
  LD A,(BarEnergy4)
  CP $9F
  JR C,MessageEnergyLow
  LD A,(SunNear)
  AND A
  JR NZ,MessageScooping
  LD A,(AutoDocked)
  AND A
  JR NZ,MessageDocking
  LD HL,MessageTimer
  LD A,(HL)
  AND A
  JR NZ,MessagePeriodicCount
MessagePeriodicDue:
  LD A,$46
  LD (HL),A
  LD A,(MissionState)
  DEC A
  JR Z,MessageInvaded
  LD A,(NovaMission)
  AND A
  RET Z
  LD A,(SunGrows)
  AND A
  RET NZ
  LD BC,$C202
  JR MessagePeriodicShow
MessagePeriodicCount:
  DEC (HL)
  RET
MessageInvaded:
  LD BC,$0F03
  JR MessagePeriodicShow
MessageDocking:
  LD BC,$7B05
  JR MessagePeriodicShow
MessageScooping:
  LD A,(Equipment+$0004)
  AND A
  RET Z
  LD A,(Fuel)
  INC A
  CALL SetFuel
  LD BC,$A008
  JR MessagePeriodicShow
MessageEnergyLow:
  XOR A
  LD (CloakOn),A
  LD L,$07
  LD A,(ViewIndex)
  CP $04
  CALL C,FillAttrsVector
  LD BC,$640A
MessagePeriodicShow:
  JP MessageShow

; Every slot's request bit cleared and the line's code to 0
;
; Used by the routines at ClearHighlightsVector, NewGame and JumpTick.
ClearMessages:
  LD B,$0A
  LD HL,Messages
ClearMessagesLoop:
  RES 7,(HL)
  INC HL
  INC HL
  DJNZ ClearMessagesLoop
  XOR A
  LD (MessageToken),A
  RET

; The hyperspace countdown (twice the seconds shown); 0 when no jump is pending
JumpCountdown:
  DEFB $00
