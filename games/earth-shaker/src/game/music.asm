; --------------------------------------------------------------------------------------------------------------------
; music.asm: The tune player and the tunes
;
; PlayTune $88CE plays a tune of 4-byte notes with interrupts off: [drum, n1, n2, length]. Drum 1 calls ROM BEEPER
; with HL = $020B, DE = 3 before the note, drum 2 with HL = $0106, DE = 5 (two clicks of different pitch); other
; values nothing. n1 and n2 index NotePeriods $BC00 (a big-endian word at $BC00 + 2n): two counters toggle bit 4 of
; port $FE, each at its own period, for length x 256 loop turns. The tune ends at the record whose n1 is $FF, or when
; a key of half row 1-5 (port $F7FE) is down. HL returns pointing at the n1 byte of the record where it stopped (past
; its drum byte): the menu compares HL with $B269, the $FF byte of TitleTune's end record, to know the tune ran out.
;
; The tunes: the title TitleTune $AD00, the game over GameOverTune $AA00, the extra life LifeTune $AC5F, the win
; WinTune $6EF4, the map MapTune $E8E8 and eight cave tunes, one per four caves (CaveTunes $EE24; the 1988 version
; played CaveTune1 $BB80 in every cave).
; --------------------------------------------------------------------------------------------------------------------

  ORG $6EF4

; The tune after cave 32: 258 notes, the last record $FF,$FF at $72FC
;
; Played by WinGame $A8BF through PlayWinTune $A615. Witness: the rzx32 build
; reads $6EF4-$6F5F (its first 27 notes) before the recording ends; the rest is
; known only from the code.
WinTune:
  INCBIN "res/music/win.bin",$0000,1034

; Leftover: two $FF bytes after the win tune
;
; No code reads them (known only from the code).
WinTunePad:
  INCBIN "res/leftovers/win-pad.bin",$0000,2

  ORG $88CE

; Play the tune at HL with interrupts off; a key 1-5 stops it
;
; See the module header. Out: HL at the byte that ended the tune, interrupts
; on.
;
; Witness: L1 66 (c1, hiscore, lives, menu, timer, rzx01-rzx32).
PlayTune:
  DI
NoteLoop:
  LD A,(HL)
  INC HL
  CP $01
  JR NZ,PlayTuneSkip
  PUSH HL
  PUSH DE
  PUSH BC
  PUSH AF
  LD DE,$0003
  LD HL,$020B
  CALL RomBeeper
  DI
  POP AF
  POP BC
  POP DE
  POP HL
PlayTuneSkip:
  CP $02
  JR NZ,PlayTuneSkip2
  PUSH HL
  PUSH DE
  PUSH BC
  PUSH AF
  LD DE,$0005
  LD HL,$0106
  CALL RomBeeper
  DI
  POP AF
  POP BC
  POP DE
  POP HL
PlayTuneSkip2:
  LD A,$F7
  OUT ($FF),A
  IN A,($FE)
  AND $1F
  CP $1F
  JR NZ,TuneEnds
  LD A,(HL)
  CP $FF
  JR NZ,PlayNote
TuneEnds:
  EI
  RET
PlayNote:
  PUSH HL
  RLCA
  LD L,A
  LD H,NotePeriods/256
  LD D,(HL)
  INC HL
  LD E,(HL)
  PUSH DE
  POP IX
  POP HL
  LD A,(HL)
  INC HL
  NOP
  NOP
  NOP
  DEC IX
  PUSH HL
  LD A,(HL)
  RLCA
  LD L,A
  LD H,NotePeriods/256
  LD B,(HL)
  INC HL
  LD C,(HL)
  PUSH BC
  POP IY
  POP HL
  INC HL
  PUSH HL
  LD H,(HL)
  LD L,$00
ToneLoop:
  DEC DE
  LD A,D
  OR E
  JR NZ,PlayTuneSkip5
  XOR A
  OUT ($FE),A
  LD A,$10
  OUT ($FE),A
  PUSH IX
  POP DE
PlayTuneSkip5:
  DEC BC
  LD A,B
  OR C
  JR NZ,PlayTuneSkip6
  LD A,$10
  OUT ($FE),A
  XOR A
  OUT ($FE),A
  PUSH IY
  POP BC
PlayTuneSkip6:
  DEC HL
  LD A,H
  OR L
  JR NZ,ToneLoop
  POP HL
  INC HL
  JP NoteLoop

; JP PlayCaveTune: the 1990 version's one tune per four caves
;
; Witness: L1 46 (c1, hiscore, lives, timer, rzx01-rzx31).
PlayCaveTuneJump:
  JP PlayCaveTune

; Leftover: CALL $88CE, RET (the 1988 version's tail after LD HL,$BB80)
PlayCaveTunePad:
  DEFB $CD,$CE,$88,$C9

  ORG $8A35

; Play TitleTune $AD00
;
; Witness: L1 10 (c1, lives, menu).
PlayTitleTune:
  LD HL,TitleTune
  CALL PlayTune
  RET

  ORG $AC5F

; The extra-life tune
LifeTune:
  INCBIN "res/music/life.bin",$0000,158

; Leftover: 3 bytes $FF
LifeTunePad:
  INCBIN "res/leftovers/life-pad.bin",$0000,3

; The title tune
TitleTune:
  INCBIN "res/music/title.bin",$0000,1386

; Leftover: 2 zero bytes
TitleTunePad:
  INCBIN "res/leftovers/title-pad.bin",$0000,2

  ORG $BB80

; The tune of caves 1-4
CaveTune1:
  INCBIN "res/music/cave-1.bin",$0000,122

; Zeros (6 bytes)
CaveTune1Pad:
  DEFS $06

; The note periods: 73 big-endian words, note n at $BC00 + 2n
NotePeriods:
  INCBIN "res/music/periods.bin",$0000,146

  ORG $EE24

; The tune of each group of four caves
CaveTunes:
  INCLUDE "res/music/cave-tunes.inc"

; Play the tune of the cave's group of four
;
; Witness: L1 46 (c1, hiscore, lives, timer, rzx01-rzx31).
PlayCaveTune:
  LD A,(CaveNumber)
  DEC A
  AND $FC
  RRCA
  ADD A,CaveTunes&255
  LD E,A
  LD D,CaveTunes/256
  LD A,(DE)
  LD L,A
  INC DE
  LD A,(DE)
  LD H,A
  CALL PlayTune
  RET

; Leftover: 183 bytes
PlayCaveTunePad2:
  INCBIN "res/leftovers/tune-pad.bin",$0000,183

  ORG $F100

; The tune of caves 5-8
CaveTune2:
  INCBIN "res/music/cave-2.bin",$0000,82

; The tune of caves 29-32
CaveTune8:
  INCBIN "res/music/cave-8.bin",$0000,126

; The tune of caves 9-12
CaveTune3:
  INCBIN "res/music/cave-3.bin",$0000,66

; The tune of caves 13-16
CaveTune4:
  INCBIN "res/music/cave-4.bin",$0000,134

; The tune of caves 25-28
CaveTune7:
  INCBIN "res/music/cave-7.bin",$0000,106

; The tune of caves 17-20
CaveTune5:
  INCBIN "res/music/cave-5.bin",$0000,150

; The tune of caves 21-24
CaveTune6:
  INCBIN "res/music/cave-6.bin",$0000,262

; Leftover: 1602 bytes, from $F9A6 an unused test cave record
; (src/res/leftovers/README.md)
CaveTunesPad:
  INCBIN "res/leftovers/tunes-pad.bin",$0000,1602
