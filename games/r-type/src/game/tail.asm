; --------------------------------------------------------------------------------------------------------------------
; tail.asm: The extra life, the waits and fills, the level loader, the first screen
; --------------------------------------------------------------------------------------------------------------------

; When the score changed: print it and give an extra life at 50 000 and at each
; 100 000
;
; Witness: L1 32904 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
CheckExtraLife:
  LD A,(ScoreChanged)
  AND A
  RET Z

; Print the score and check the extra life (DrawHud calls it here)
;
; LD HL,Lives; the next instruction starts in its last byte ($7A, LD A,D) where
; nothing jumps. The score printed; an extra life when the second digit is 5
; and none was given, or when the first digit equals ExtraLives: ExtraLives +
; 1, Lives + 1, DrawHud, sound $0E.
;
; Witness: L1 1357 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
PrintScore:
  LD HL,Lives
  PUSH HL
  LD HL,ScoreText
  LD DE,ExtraLives
  LD BC,$1501
  PUSH HL
  PUSH DE
  CALL PrintTextNormal
  POP HL
  POP IX
  XOR A
  LD (ScoreChanged),A
  LD A,(IX+$01)
  CP $35
  JR NZ,l_FDCE
  LD A,(HL)
  AND A
  JR Z,l_FDDA
l_FDCE:
  LD A,(HL)
  AND A
  JR Z,ExtraLifeNone
  LD A,(IX+$00)
  SUB $30
  CP (HL)
  JR NZ,ExtraLifeNone
l_FDDA:
  INC (HL)
  POP HL
  INC (HL)
  CALL DrawHud
  LD HL,$0E83
ExtraLifeSound:
  CALL PlaySound          ; the sound
  RET
ExtraLifeNone:
  POP HL                  ; no life
  RET

; Wait 256 frames
;
; Witness: L1 10 (boss, ending, hiscore, l1-l7).
Wait256:
  LD B,$00

; HALT B times
;
; Witness: L1 8495 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, gameover, hiscore, hiscore-typed, restart, l1-l8).
WaitFrames:
  HALT
  DJNZ WaitFrames
  RET

; Zero BC bytes from HL
;
; Witness: L1 99924 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
ClearBlock:
  XOR A

; Fill BC bytes from HL with A
;
; HL ends at the last byte filled, not after it: a FillBlock that follows
; another starts one byte early (DrawHud's $44 fill covers row 20 column 31 and
; row 21 columns 0-6).
;
; Witness: L1 103437 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
FillBlock:
  LD (HL),A
  LD D,H
  LD E,L
FillRest:
  INC E                   ; the LDIR
  DEC BC
  LDIR
  RET

; Zero the bitmap $4000-$57FF
;
; Witness: L1 11 (continue, gameover, hiscore, hiscore-typed).
ClearScreen:
  LD HL,$4000
  LD BC,$1800
  CALL ClearBlock
  RET

; a byte between the routines
SpareFE02:
  DEFB $00

; Load the next level from tape
;
; The digit + 1; SEARCHING FOR R TYPE LEVEL N; START TAPE; headers read and
; skipped until the level's; LOADING, the body to $C4AE; STOP TAPE, LOADED OK,
; a key. A load error: ERROR IN LOADING, REWIND TAPE, a key, again. After the
; last level ('0'): REWIND TAPE first.
;
; Witness: L1 8 (ending, l1-l7).
LoadLevel:
  CALL StarsOff
  CALL ClearPlayState
  LD A,$02
  LD (FrameCounter),A
  CALL CycleTitleColour
  LD A,$C9
  LD (l_8AA2+$001D),A
  CALL TitleLogo
  XOR A
  LD (l_8AA2+$001D),A
  LD A,(LevelDigit)
  CP $30
  JR NZ,l_FE32
LoadLevelRewind:
  LD C,$00                ; the rewind prompt
  LD HL,RewindSide2Text
  CALL PrintRow22
  CALL WaitKey
  CALL ClearTextRow
l_FE32:
  LD A,(LevelDigit)
  INC A
  LD (LevelDigit),A
  LD C,$01
  LD HL,StartTapeText
  CALL PrintRow22
  LD HL,RewindSide2Text+$000D
  CALL PrintText
  CALL WaitKey

; LoadLevelStart
LoadLevelStart:
  CALL ClearTextRow       ; START TAPE
  LD C,$02
  LD HL,SearchingText
  CALL PrintRow22
  LD HL,LevelText
  CALL PrintText
LoadLevelHeader:
  LD IX,$6000             ; read a header
  LD DE,$0012
  CALL LoadBytes
  LD A,($600D)
  LD L,A
  LD A,(LevelDigit)
  CP L
  JR Z,l_FE76
  LD B,$80
  CALL WaitFrames
  JR LoadLevelHeader
l_FE76:
  CALL ClearTextRow
  LD HL,LoadingText
  LD C,$05
  CALL PrintRow22
  INC C
  LD HL,LevelText
  CALL PrintText
  LD IX,LevelSpace
  LD DE,($6010)
  CALL LoadBytes
  XOR A
  OUT ($FE),A
  CALL ClearTextRow
  LD C,$04
  LD HL,LevelText
  CALL PrintRow22
  LD HL,LoadedOkText
  CALL PrintText
  LD B,$5C
  CALL WaitFrames
  LD C,$02
  LD HL,StopTapeText
  CALL PrintRow22
  LD HL,RewindSide2Text+$000D
  CALL PrintText
  CALL WaitKey
  RET
; This entry point is used by the routine at LoadError.
LoadLevelRetry:
  JR LoadLevelStart       ; back to START TAPE

; Every LoadBytes return: EI; RET C; an error falls into LoadError
;
; Witness: L1 25 (deaths-l7, ending, l1-l8).
LoadDone:
  EI
  RET C

; ERROR IN LOADING, REWIND TAPE, a key, retry
;
; Witness: L1 2 (ending).
LoadError:
  POP HL
  CALL ClearTextRow
  LD HL,ErrorInLoadingText
  LD C,$08
  CALL PrintRow22
  LD B,$60
  CALL WaitFrames
  LD C,$01
  LD HL,RewindTapeText
  CALL PrintRow22
  LD HL,RewindSide2Text+$000D
  CALL PrintText
  LD B,$40
  CALL WaitFrames
  CALL WaitKey
  JR LoadLevelRetry

; Draw the 8 block columns from the restart column into the shadow, then the
; scenery marks
;
; Soft cells on; the drawers' limit $20; each map byte drawn with its drawer (a
; patched CALL); MapReadPtr / MapBlockPtr set; every attribute with bit 7 marks
; its SolidMap cell $FF and loses bit 7; the limit back; soft cells off.
;
; Witness: L1 47 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7,
; gameover, hiscore, hiscore-typed, restart, l2-l8).
DrawFirstScreen:
  CALL SoftCellsOn
  LD HL,$5800
  LD BC,$0280
  CALL ClearBlock
  LD B,$20
  CALL SetDrawLimit
  LD A,(MapColumn)
  LD E,A
  ADD A,$08
  LD (MapColumn),A
  LD HL,ColumnBuffer
  LD (ColumnPtr),HL
  XOR A
  LD D,A
  LD H,D
  LD L,E
  LD B,A
  LD C,A
  LD (ScrollStep),A
  LD (MetaColumn),A
  LD (DrawTag),A
  LD (FrameCounter),A
  ADD HL,DE
  ADD HL,HL
  ADD HL,DE
  LD DE,(LevelMetatiles)
  ADD HL,DE
  LD DE,$0508
DrawFirstCell:
  PUSH BC                 ; one metatile
  PUSH DE
  PUSH HL
  LD A,(HL)
  AND $3F
  EX AF,AF'
  LD A,(HL)
  LD HL,DrawSprite
  AND $C0
  JR Z,DrawFirstPatch
  LD HL,DrawSpriteMirrored
  CP $40
  JR Z,DrawFirstPatch
  LD HL,DrawSpriteFlipped
  CP $80
  JR Z,DrawFirstPatch
  LD HL,DrawSpriteBoth
DrawFirstPatch:
  LD (DrawFirstPatch+$000B),HL ; the drawer written into the CALL
  EX AF,AF'
  CALL MetatileAddress
  LD D,$04
  LD E,D
  CALL $0000
  POP HL
  POP DE
  POP BC
  INC HL
  INC B
  INC B
  INC B
  INC B
  DEC D
  JR NZ,DrawFirstCell
  LD B,$00
  LD D,$05
  INC C
  INC C
  INC C
  INC C
  DEC E
  JR NZ,DrawFirstCell
  LD (MapBlockPtr),HL
  LD (MapReadPtr),HL
  LD DE,PlayAttrs
  LD HL,SolidMap
  LD BC,$0280
FirstScreenMarks:
  LD A,(DE)               ; the bit-7 attributes into SolidMap
  BIT 7,A
  JR Z,l_FF81
  LD (HL),$FF
l_FF81:
  RES 7,A
  LD (DE),A
  INC HL
  INC DE
  DEC BC
  LD A,B
  OR C
  JR NZ,FirstScreenMarks
  LD B,$1F
  CALL SetDrawLimit
  CALL SoftCellsOff
  RET

; Loader leftovers ($FF94-$FFC7, no play recording reads them) and the stack
; (SP = $FFFE)
StackArea:
  INCBIN "res/leftovers/stack-area.bin",$0000,108
