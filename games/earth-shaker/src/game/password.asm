; --------------------------------------------------------------------------------------------------------------------
; password.asm: The password entry and the cave name table
;
; The passwords are the cave names: CaveNames $9700 holds 32 names of 20 characters, space padded. EnterPassword $8E2D
; reads up to 20 characters into PasswordBuffer $FD00; FindPassword $8E91 compares it with 50 records of 20 bytes from
; $9700 (records 33-50 run past the names over zeros, code and data; they never match a typed name). A match starts
; the game at that cave; no match (ENTER alone too) at cave 1.
; --------------------------------------------------------------------------------------------------------------------

  ORG $85D6

; Start a game: the password, 5 lives, the score 0
;
; CaveDigits $FD7E = 0, 1; Password $8F29 (sets the cave); Lives $FD93 = 5,
; ScoreDigits 0.
;
; Witness: L1 3 (c1, lives, rzx x1).
StartGame:
  LD HL,$0100
  LD (CaveDigits),HL
  CALL Password
  NOP
  LD HL,Lives
  LD (HL),$05
  INC HL
  LD (HL),$00
  LD DE,ScoreDigits+$0001
  LD BC,$0005
  LDIR
  RET

  ORG $8DFF

; Clear the screen, print EnterPasswordText on row 0
;
; Witness: L1 3 (c1, lives, rzx x1).
ShowPasswordPrompt:
  CALL ClearScreen
  LD BC,$0000
  LD D,$20
  LD HL,EnterPasswordText
  CALL PrintText
  LD BC,$0000
  LD D,$20
  LD A,$43
  CALL FillAttrs
  RET

; A short click for a typed or deleted character
;
; Witness: L1 7 (hiscore).
KeyClick:
  PUSH BC
  PUSH DE
  DI
  LD D,$00
  XOR A
KeyClickLoop:
  LD E,D
KeyClickLoop2:
  DEC E
  JR NZ,KeyClickLoop2
  OUT ($FE),A
  XOR $18
  DEC D
  JR NZ,KeyClickLoop
  EI
  POP DE
  POP BC
  RET

; Read the password into PasswordBuffer $FD00
;
; The buffer to spaces, the prompt; WaitKey: '0' deletes, 'e' (ENTER) ends,
; space and A-Z are stored, at most 20.
;
; Witness: L1 3 (c1, lives, rzx x1).
EnterPassword:
  CALL ShowPasswordPrompt
  LD HL,PasswordBuffer
  LD DE,PasswordBuffer+$0001
  LD BC,$0013
  LD (HL),$20
  LDIR
  LD DE,PasswordBuffer
  LD BC,$0406
EnterPasswordLoop:
  PUSH BC
  PUSH DE
  CALL WaitKey
  POP DE
  POP BC
  INC HL
  LD A,(HL)
  CP $30
  JR NZ,EnterPasswordSkip
  LD A,C
  CP $06
  JR Z,EnterPasswordLoop
  DEC DE
  LD A,$20
  LD (DE),A
  DEC C
  PUSH DE
  PUSH BC
  LD D,$01
  LD HL,EnterPasswordText+$0005
  CALL PrintText
  POP BC
  POP DE
  CALL KeyClick
  JR EnterPasswordLoop
EnterPasswordSkip:
  CP $65
  RET Z
  CP $20
  JR Z,EnterPasswordSkip2
  CP $40
  JR C,EnterPasswordLoop
  CP $5B
  JR NC,EnterPasswordLoop
EnterPasswordSkip2:
  LD (DE),A
  PUSH DE
  POP HL
  PUSH DE
  LD D,$01
  PUSH BC
  CALL PrintText
  POP BC
  POP DE
  CALL KeyClick
  INC C
  INC DE
  LD A,C
  CP $1A
  JR NZ,EnterPasswordLoop
  RET

; Compare PasswordBuffer with 50 records of 20 bytes from CaveNames
;
; Out: B = the record that matched (0-49), or 50 when none did.
;
; Witness: L1 3 (c1, lives, rzx x1).
FindPassword:
  LD HL,CaveNames
  LD B,$00
FindPasswordLoop:
  PUSH BC
  LD B,$14
  PUSH HL
  LD DE,PasswordBuffer
FindPasswordLoop2:
  LD C,(HL)
  LD A,(DE)
  CP C
  JR NZ,FindPasswordSkip
  INC HL
  INC DE
  DJNZ FindPasswordLoop2
  POP HL
  POP BC
  RET
FindPasswordSkip:
  POP HL
  LD DE,$0014
  ADD HL,DE
  POP BC
  INC B
  LD A,B
  CP $32
  JR NZ,FindPasswordLoop
  RET

; A match: colour the prompt line in cycling colours
;
; Known only from the code: no recording types a valid password.
PasswordFlashText:
  LD BC,$0406
  LD E,$43
PasswordFlashTextLoop:
  LD A,E
  LD D,$01
  PUSH BC
  CALL FillAttrs
  POP BC
  INC E
  LD A,E
  CP $48
  JR NZ,PasswordFlashTextSkip
  LD E,$41
PasswordFlashTextSkip:
  INC C
  LD A,C
  CP $1A
  JR NZ,PasswordFlashTextLoop
  RET

; Rotate the prompt line's attributes one cell left
;
; Known only from the code.
PasswordFlashStep:
  LD A,(Attributes+134)
  LD HL,Attributes+135
  LD DE,Attributes+134
  LD BC,$0013
  LDIR
  LD (Attributes+153),A
  RET

; A match: the coloured line and a rising buzz
;
; Known only from the code.
PasswordAccepted:
  CALL PasswordFlashText
  DI
  LD D,$01
  XOR A
PasswordAcceptedLoop:
  LD E,D
  LD BC,$0004
PasswordAcceptedLoop2:
  DEC E
  JR NZ,PasswordAcceptedSkip
  XOR $18
  OUT ($FE),A
  LD E,D
PasswordAcceptedSkip:
  DJNZ PasswordAcceptedLoop2
  DEC C
  JR NZ,PasswordAcceptedLoop2
  PUSH AF
  PUSH DE
  CALL PasswordFlashStep
  POP DE
  POP AF
  INC D
  JR NZ,PasswordAcceptedLoop
  EI
  RET

; No match: RET (the 1990 version dropped the failure flash PasswordRejectedOld
; $8F09)
;
; Witness: L1 3 (c1, lives, rzx x1).
PasswordRejected:
  RET

; Leftover: the old failure flash (32 bytes), never run
PasswordRejectedOld:
  DEFB $1E,$C5,$3E,$01,$16,$14,$01,$06
  DEFB $04,$CD,$74,$8A,$CD,$F9,$82,$3E
  DEFB $07,$16,$14,$01,$06,$04,$CD,$74
  DEFB $8A,$CD,$3C,$82,$C1,$10,$E2,$C9

; Enter and check the password; set the first cave
;
; EnterPassword $8E2D, FindPassword $8E91. No match: cave 1. Record B:
; CaveNumber = B + 1, CaveDigits counted up to it, PasswordAccepted $8EE4.
;
; Witness: L1 3 (c1, lives, rzx x1).
Password:
  CALL EnterPassword
  CALL FindPassword
  LD A,B
  CP $32
  JR NZ,PasswordSkip
  CALL PasswordRejected
  LD A,$01
  LD (CaveNumber),A
  LD HL,$0100
  LD (CaveDigits),HL
  RET
PasswordSkip:
  INC A
  LD (CaveNumber),A
  LD HL,$0000
  LD (CaveDigits),HL
PasswordLoop:
  LD HL,CaveDigits+$0001
  LD B,$02
  PUSH HL
  PUSH AF
  CALL IncDigits
  POP AF
  POP HL
  DEC A
  JR NZ,PasswordLoop
  CALL PasswordAccepted
  RET

  ORG $9700

; The 32 cave names of 20 characters: the passwords
;
; Read by CaveIntro $92D4 (the name of the cave) and FindPassword $8E91.
CaveNames:
  INCBIN "res/texts/cave-names.bin",$0000,640

  ORG $99C0

; Zeros after the names (64 bytes): FindPassword's 50 records run on over them
CaveNamesPad:
  INCBIN "res/leftovers/names-pad.bin",$0000,64

  ORG $9ACC

; Zeros (28 bytes), the end of FindPassword's 50 records
CaveNamesPad2:
  INCBIN "res/leftovers/names-pad2.bin",$0000,28

; "ENTER PASSWORD (ENTER=LEVEL ONE)"
EnterPasswordText:
  INCBIN "res/texts/password-prompt.bin",$0000,32
