; --------------------------------------------------------------------------------------------------------------------
; keys.asm: Redefining the keys and the speech picks
;
; R on the title or the instructions page redefines key set 3.
; --------------------------------------------------------------------------------------------------------------------

; Take five new keys into key set 3
;
; ClearScreen, KeyType 3, ten bytes of KeySet3 cleared (the second jump key
; stays), the prompt and the five labels (MenuTexts), row 6 green; waits for no
; key; RedefineOne for up, down, left, right and jump (the attribute bar at
; $592A + 64 k, the name into InstructionsText's row 3, printed at row 14 - 2k
; column 22). Then the title scroller (JP TitleScrollerStart) over this page.
; Witness: tour-redefine 1.
RedefineKeys:
  CALL ClearScreen
  LD HL,KeyType
  LD (HL),$03
  LD HL,KeySet3
  LD B,$0A
RedefineKeysClear:
  LD (HL),$00
  INC HL
  DJNZ RedefineKeysClear
  LD HL,$1100
  LD B,$20
  LD DE,RedefinePrompt
RedefineKeysPrompt:
  LD A,(DE)
  CALL PrintChar
  INC L
  INC DE
  DJNZ RedefineKeysPrompt
  LD H,$0E
  LD C,$05
RedefineKeysLabels:
  LD B,$0A
  LD L,$0A
RedefineKeysLabel:
  LD A,(DE)
  CALL PrintChar
  INC DE
  INC L
  DJNZ RedefineKeysLabel
  DEC H
  DEC H
  DEC C
  JR NZ,RedefineKeysLabels
  LD HL,Attributes+192
  LD B,$20
RedefineKeysColour:
  LD (HL),$04
  INC HL
  DJNZ RedefineKeysColour
RedefineKeysRelease:
  CALL ReadAnyKey
  LD A,L
  AND A
  JR NZ,RedefineKeysRelease
  LD A,$05
  LD IX,KeySet3
  LD HL,Attributes+298
  LD BC,InstructionsText+$0066
  LD DE,$0E16
RedefineKeysNext:
  CALL RedefineOne
  PUSH BC
  LD BC,$0040
  ADD HL,BC
  POP BC
  DEC D
  DEC D
  INC IX
  INC IX
  INC BC
  INC BC
  INC BC
  INC BC
  INC BC
  DEC A
  JR NZ,RedefineKeysNext
  JP TitleScrollerStart

; B = 1 when the key just stored is already in key set 3
;
; Finds the set's last stored pair (the first zero after it) and compares it
; with the pairs before. Witness: 5 calls.
KeyUsed:
  LD HL,KeySet3-$0001
  LD B,$00
KeyUsedEnd:
  INC HL
  INC HL
  INC B
  LD A,B
  CP $06
  JR Z,KeyUsedLast
  LD A,(HL)
  AND A
  JR NZ,KeyUsedEnd
KeyUsedLast:
  DEC HL
  DEC HL
  DEC B
  INC B
  LD D,(HL)
  DEC HL
  LD E,(HL)
KeyUsedCompare:
  DEC HL
  LD A,(HL)
  DEC HL
  CP D
  JR NZ,KeyUsedNext
  LD A,(HL)
  CP E
  JR NZ,KeyUsedNext
  LD B,$01
  RET
KeyUsedNext:
  DJNZ KeyUsedCompare
  LD B,$00
  RET

; Speak one of the eight DeathPhrases (R AND 7)
;
; Witness: 13 calls.
DeathPhrase:
  LD A,R
  LD HL,DeathPhrases-$0001
  AND $07
  INC A
  LD B,A
DeathPhraseFind:
  INC HL
  DJNZ DeathPhraseFind
  LD A,(HL)
  JP StartPhrase

; The one key held: L its row bits, H its port row, E the row number; HL = 0
; for none or two rows
;
; Scans the eight rows $FEFE .. $7FFE. Witness: 24 310 calls.
ReadAnyKey:
  LD D,$00
  LD HL,$0000
  LD B,$08
  LD C,$FE
ReadAnyKeyRow:
  LD A,C
  IN A,($FE)
  AND $1F
  CP $1F
  JR Z,ReadAnyKeyNext
  DEC D
  JR NZ,ReadAnyKeyFound
  LD HL,$0000
  RET
ReadAnyKeyFound:
  LD D,$01
  LD L,A
  LD H,C
  LD E,B
ReadAnyKeyNext:
  SLA C
  SET 0,C
  DJNZ ReadAnyKeyRow
  RET

; Take one key into (IX), name it into (BC), print it at DE
;
; The bar (13 bytes of attribute 3 at HL), a key (ReadAnyKey) stored as (mask,
; port row); the name from KeyNames (row E, the bit of the key); a key already
; used is taken again; the name printed; waits for the release. Witness: 5
; calls.
RedefineOne:
  PUSH AF
  PUSH HL
  PUSH DE
  PUSH BC
  LD B,$0D
RedefineOneBar:
  LD (HL),$03
  INC HL
  DJNZ RedefineOneBar
RedefineOneKey:
  CALL ReadAnyKey
  LD A,L
  AND A
  JR Z,RedefineOneKey
  LD C,L
  LD B,E
  LD (IX+$00),L
  LD (IX+$01),H
  LD HL,KeyNames-$0006
  LD DE,$0005
RedefineOneRow:
  ADD HL,DE
  DJNZ RedefineOneRow
RedefineOneBit:
  INC HL
  SRL C
  JR C,RedefineOneBit
  LD A,(HL)
  POP BC
  PUSH BC
  LD (BC),A
  PUSH AF
  CALL KeyUsed
  POP AF
  DEC B
  JR Z,RedefineOneKey
  POP BC
  POP HL
  PUSH HL
  PUSH BC
  CALL PrintChar
RedefineOneRelease:
  CALL ReadAnyKey
  LD A,L
  AND A
  JR NZ,RedefineOneRelease
  POP BC
  POP DE
  POP HL
  POP AF
  RET
