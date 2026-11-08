; The Hewson "Countdown II" loader of Exolon: the tape's block 4 (768 bytes at $FC00), loaded by the ROM (LOAD ""
; CODE) and entered at $FC00 by the BASIC's RANDOMIZE USR 64512. docs/03-build-and-load.md 3.3.
;
; This file is the loader in the clear. On the tape $FC13-$FEA2 is encrypted: Decrypt, the 19 plain bytes at the
; top, runs one pass byte[i] ^= byte[i+1] forward over it, each byte XORed with the next one as the tape holds it.
; tools/xorchain.py applies the inverse when the build writes the block (from the end backwards: tape[i] = plain[i]
; ^ tape[i+1], the byte after the range, $FEA3, being plain).
;
; It is Zynaps' loader (../../zynaps/src/tape/loader.asm) with these changes: the counter drawn at the bottom
; right (columns 27-30 of row 23, the strip of boxes of the loading screen), no LD SP at Start, the game's own
; addresses in MoveStub, and LoadFile taking only a header of type 42 ($2A).
;
; What it does (Start): clears the attributes, loads the 4096-byte file at $8000 and calls its unpacker at $8001
; (the loading screen), loads the 37536-byte file at $6590-$F82F and runs MoveStub from $5B00, which moves the game
; up by $7D0 over this loader to $6D60-$FFFF and jumps to $6D60. LdBytes is the ROM's LD-BYTES ($0556-$05E2) with the border kept
; black and its edge routine hooked: LdEdge1 first runs CountStep, the countdown's work in the time of the ROM's
; 358 T delay, every path padded to that length so the tape's timings stay the ROM's. While a data block loads,
; four digits at the bottom right run down to zero (one unit per 32 bytes), rolling like an odometer.

  DEVICE ZXSPECTRUM48
  ORG $FC00

PicyEntry   EQU $8001           ; the unpacker of the "picy" file, which loads at $8000
GameEntry   EQU $6D60           ; the game's first instruction once moved
StubAt      EQU $5B00           ; the printer buffer, where MoveStub runs
GameLoaded  EQU $6590           ; the code file's load address (its header)
MoveBy      EQU $07D0           ; the move: $6590-$F82F to $6D60-$FFFF
GameLength  EQU $92A0           ; 37536 bytes
GameStack   EQU $6D5E           ; SP for the game: two below the moved image
CountRow    EQU $50FF           ; the screen byte right of the counter: row 23 (pixel line 184), column 31
CountAttr   EQU $5AFB           ; the counter's four attribute cells, columns 27-30 of row 23
FileType    EQU 42              ; the type byte LoadFile wants in a header ($2A; the ROM's are 0-3)
BrightWhite EQU $47             ; bright white ink on black paper
DigitCycle  EQU 79              ; 10 digits x 8 sub-steps, less one: a digit's byte runs 79 ... 0

; ----------------------------------------------------------------------------------------------------------------
; Decrypt: the plain head. Makes $FC13-$FEA2 plain, then runs into it.
Decrypt:
  LD BC,DecryptEnd-DecryptFrom  ; 656 bytes
  LD HL,DecryptFrom
  LD DE,DecryptFrom+1
DecryptLoop:
  LD A,(DE)                     ; the next byte, still as the tape holds it
  XOR (HL)
  LD (HL),A
  INC HL
  INC DE
  DEC BC
  LD A,B
  OR C
  JR NZ,DecryptLoop
; ----------------------------------------------------------------------------------------------------------------
; From here to DecryptEnd the tape holds the bytes XORed in a chain (tools/xorchain.py).
DecryptFrom:
  JP Start

; The countdown's state
CountDigits:
  DB $48,$48,$48,$48            ; units, tens, hundreds, thousands: 8 x the digit + a sub-step 0-7 (CountSet)
CountOn:
  DB 0                          ; 0 while a header loads (no counter), 1 while a data block loads
CountGlyph:
  DW 0                          ; the digit being drawn (an address in CountDigits)
CountScreen:
  DW 0                          ; its screen address (the counter is drawn right to left)
CountTick:
  DB 0                          ; edges until the counter moves; 1-4 the four digits are drawn, 5 up the colours
  DB 0
; The header just loaded (LoadFile): type, 10 name bytes, length, start, parameter 2
Header:
  DB 0
  DS 10
HeaderLength:
  DW 0
HeaderStart:
  DW 0
  DW 0
; 11 glyphs of 8 lines, 0-9 and 0 again, inverted (dark digits on a white cell): the sub-step offsets a digit's
; glyph by 0-7 lines, so it rolls into the next one
DigitGlyphs:
  DB $FE,$C6,$BA,$BA,$BA,$BA,$C6,$FE    ; 0
  DB $FE,$EE,$CE,$EE,$EE,$EE,$82,$FE    ; 1
  DB $FE,$C6,$BA,$F6,$EE,$DE,$82,$FE    ; 2
  DB $FE,$82,$F6,$E6,$FA,$BA,$C6,$FE    ; 3
  DB $FE,$F6,$E6,$D6,$B6,$82,$F6,$FE    ; 4
  DB $FE,$82,$BE,$86,$FA,$BA,$C6,$FE    ; 5
  DB $FE,$E6,$DE,$86,$BA,$BA,$C6,$FE    ; 6
  DB $FE,$82,$FA,$F6,$F6,$EE,$EE,$FE    ; 7
  DB $FE,$C6,$BA,$C6,$BA,$BA,$C6,$FE    ; 8
  DB $FE,$C6,$BA,$BA,$C2,$FA,$C6,$FE    ; 9
  DB $FE,$C6,$BA,$BA,$BA,$BA,$C6,$FE    ; 0 again, for the roll from 9

; ----------------------------------------------------------------------------------------------------------------
; LdBytes: the ROM's LD-BYTES. IX the address, DE the length, A the flag, carry set (load). Returns carry set when
; the block loaded with a good checksum. The changes from the ROM: C' (the counter switch) is cleared here and set
; from CountOn after the sync; the border is $0A then black, never the ROM's red / cyan stripes; no LD-BYTES return
; address is pushed (the ROM's SA/LD-RET), so BREAK or an error simply returns NC.
LdBytes:
  INC D                         ; the ROM's: D + 1 for the flag byte's turn,
  EX AF,AF'                     ; the flag and carry kept in AF'
  DEC D
  DI
  EXX
  LD C,0                        ; C': no countdown during the leader
  EXX
  LD A,$0A                      ; border red, MIC on (once; the edges write black)
  OUT ($FE),A
  IN A,($FE)
  RRA
  AND $20                       ; the EAR level now
  OR 0                          ; the ROM's OR 2 (red) is gone
  LD C,A
  CP A                          ; Z: no edge yet
LdBreak:
  RET NZ
LdStart:
  CALL LdEdge1
  JR NC,LdBreak
  LD HL,$0415                   ; the ROM's: about a second of signal
LdWait:
  DJNZ LdWait
  DEC HL
  LD A,H
  OR L
  JR NZ,LdWait
  CALL LdEdge2
  JR NC,LdBreak
LdLeader:
  LD B,$9C                      ; the pilot: 256 pulses of the right length
  CALL LdEdge2
  JR NC,LdBreak
  LD A,$C6
  CP B
  JR NC,LdStart
  INC H
  JR NZ,LdLeader
LdSync:
  LD B,$C9
  CALL LdEdge1
  JR NC,LdBreak
  LD A,B
  CP $D4
  JR NC,LdSync
  CALL LdEdge1
  RET NC
  EXX                           ; the ROM's XOR 3 on the border colour is replaced:
  LD A,(CountOn)
  LD C,A                        ; C' = the counter switch for this block
  LD (CountTick),A              ; the first move at once
  EXX
  LD H,0                        ; the checksum
  LD B,$B0
  JR LdMarker
LdLoop:
  EX AF,AF'
  JR NZ,LdFlag
  JR NC,LdVerify
  LD (IX+0),L
  JR LdNext
LdFlag:
  RL C
  XOR L
  RET NZ
  LD A,C
  RRA
  LD C,A
  INC DE
  JR LdDec
LdVerify:
  LD A,(IX+0)
  XOR L
  RET NZ
LdNext:
  INC IX
LdDec:
  DEC DE
  EX AF,AF'
  LD B,$B2
LdMarker:
  LD L,1
Ld8Bits:
  CALL LdEdge2
  RET NC
  LD A,$CB
  CP B
  RL L
  LD B,$B0
  JP NC,Ld8Bits
  LD A,H
  XOR L
  LD H,A
  LD A,D
  OR E
  JR NZ,LdLoop
  LD A,H
  CP 1                          ; carry: the checksum is 0
  RET

; LdEdge2 / LdEdge1: the ROM's LD-EDGE-2 / LD-EDGE-1; LdEdge1 does CountStep instead of the ROM's delay loop
LdEdge2:
  CALL LdEdge1
  RET NC
LdEdge1:
  JP CountStep
LdSample:
  INC B                         ; the ROM's LD-SAMPLE
  RET Z
  LD A,$7F
  IN A,($FE)
  RRA
  RET NC
  XOR C
  AND $20
  JR Z,LdSample
  LD A,C
  CPL
  LD C,A
  LD A,0                        ; the ROM's AND 7 / OR 8, the same length: the border black, MIC off
  LD A,$08
  OUT ($FE),A
  SCF
  RET

; ----------------------------------------------------------------------------------------------------------------
; CountStep: one step of the countdown in the time of the ROM's delay (every path the same length), then LdSample.
; C' = 0: nothing (a header). Else CountTick counts edges down: at 0 the odometer moves (CountAdvance); 1-4 draw
; one digit each (right to left); 5 up set the four cells bright white.
CountStep:
  EXX
  LD A,C
  OR A
  JR Z,CountIdle
  LD HL,CountTick
  DEC (HL)
  LD A,(HL)
  JR Z,CountAdvance
  CP 5
  JR NC,CountAttrs
  LD HL,CountGlyph              ; the next digit to the left
  INC (HL)
  INC L
  INC L
  DEC (HL)                      ; CountScreen - 1
  LD HL,(CountGlyph)
  LD A,(HL)                     ; 8 x the digit + the sub-step
  ADD A,low DigitGlyphs
  LD E,A
  LD D,high DigitGlyphs
  LD HL,(CountScreen)
  LD A,(DE)                     ; 8 lines down the character cell
  LD (HL),A
  INC E
  INC H
  LD A,(DE)
  LD (HL),A
  INC E
  INC H
  LD A,(DE)
  LD (HL),A
  INC E
  INC H
  LD A,(DE)
  LD (HL),A
  INC E
  INC H
  LD A,(DE)
  LD (HL),A
  INC E
  INC H
  LD A,(DE)
  LD (HL),A
  INC E
  INC H
  LD A,(DE)
  LD (HL),A
  INC E
  INC H
  LD A,(DE)
  LD (HL),A
  EXX
  JP LdSample
CountIdle:
  LD B,$17                      ; the ROM's delay, as long as the drawing
CountDelay:
  DJNZ CountDelay
  LD A,0
  NEG
  AND A
  EXX
  JP LdSample
CountAttrs:
  LD A,BrightWhite
  LD (CountAttr),A
  LD (CountAttr+1),A
  LD (CountAttr+2),A
  LD (CountAttr+3),A
  INC HL                        ; padding
  INC HL
  LD B,$0D
  JP CountDelay
; CountAdvance: the odometer one sub-step down (units first, a borrow into the next digit at each wrap), the
; drawing restarted at the right, CountTick = 64 edges (32 bits, 4 bytes)
CountAdvance:
  LD B,DigitCycle
  LD DE,(CountDigits)           ; E units, D tens
  LD HL,(CountDigits+2)         ; L hundreds, H thousands
  DEC E
  JP P,CountTens
  LD E,B                        ; the units wrap: 9 again
  DEC D
  LD B,5
CountPad1:
  DJNZ CountPad1
  LD A,(HL)
  JP CountStore
CountTens:
  LD A,D                        ; the tens roll with the units' last sub-steps
  AND 7
  JP Z,CountTensSkip
  DEC D
  JP P,CountHundreds
  LD D,B
  DEC L
  LD A,($8000)                  ; padding (Zynaps' game entry, kept: only the time counts)
  LD A,($8000)
  LD A,($8000)
  JP CountStore
CountTensSkip:
  LD A,(HL)
  LD A,(HL)
CountHundreds:
  LD A,L
  AND 7
  JP Z,CountHundredsSkip
  DEC L
  JP P,CountThousands
  LD L,B
  DEC H
  NEG
  JP CountStore
CountHundredsSkip:
  LD A,(HL)
  LD A,(HL)
CountThousands:
  LD A,H
  AND 7
  JR Z,CountStore
  DEC H
CountStore:
  LD (CountDigits),DE
  LD (CountDigits+2),HL
  LD HL,CountDigits-1           ; CountStep's INC makes it the units
  LD (CountGlyph),HL
  LD HL,CountRow
  LD (CountScreen),HL
  LD A,64
  LD (CountTick),A
  NEG                           ; padding
  NEG
  NEG
  AND A
  EXX
  JP LdSample

; CountSet: the counter's start, the header's length / 32 in four decimal digits (8 x each)
CountSet:
  LD HL,(HeaderLength)
  LD B,5
CountShift:
  SRL H
  RR L
  DJNZ CountShift
  LD DE,CountDigits+3           ; the thousands first
CountDigit:
  LD A,$FF
  LD BC,1000
CountSubtract:
  INC A
  OR A
  SBC HL,BC
  JR NC,CountSubtract
  ADD HL,BC
  ADD A,A
  ADD A,A
  ADD A,A
  LD (DE),A
  LD C,L                        ; the rest x 10 for the next digit
  LD B,H
  ADD HL,HL
  ADD HL,HL
  ADD HL,BC
  ADD HL,HL
  DEC DE
  LD A,E
  CP low (CountDigits-1)
  JR NZ,CountDigit
  RET

; ----------------------------------------------------------------------------------------------------------------
; Start: the stages of the load
Start:
  DI                            ; the stack stays the BASIC's, below RAMTOP
  LD HL,$5800                   ; the attributes black on black: the picture appears when the unpacker colours it
  LD DE,$5801
  LD BC,$02FF
  LD (HL),0
  LDIR
  CALL LoadFile                 ; the packed screen at $8000
  CALL PicyEntry                ; the loading screen
  CALL LoadFile                 ; the game at $6590
  LD HL,MoveStub
  LD DE,StubAt
  LD BC,MoveStubEnd-MoveStub
  LDIR
  JP StubAt

; MoveStub: copied to $5B00 and run there (the game lands over this loader)
MoveStub:
  LD HL,GameLoaded+GameLength-1 ; $F82F
  LD DE,GameLoaded+GameLength-1+MoveBy  ; $FFFF
  LD BC,GameLength
  LDDR
  LD SP,GameStack
  EI
  JP GameEntry
MoveStubEnd:

; LoadFile: a header into Header, then its data block (flag $FF) at the header's start and length; a header whose
; type is not 42, or an error in either block, starts again with a header (so the ROM's files on a tape are passed
; over)
LoadFile:
  XOR A
  LD (CountOn),A
  LD IX,Header
  LD DE,17
  XOR A
  SCF
  CALL LdBytes
  JR NC,LoadFile
  LD A,(Header)
  CP FileType
  JR NZ,LoadFile
  CALL CountSet
  LD A,1
  LD (CountOn),A
  LD IX,(HeaderStart)
  LD DE,(HeaderLength)
  LD A,$FF
  SCF
  CALL LdBytes
  JR NC,LoadFile
  RET
DecryptEnd:

; ----------------------------------------------------------------------------------------------------------------
; The rest of the block is plain and never run or read: zeros, then what the mastering machine's memory held there.
  DS 50
; 20 bytes that match no part of the 48K ROM longer than 3 bytes (RAM left over when the block was saved)
Leftover:
  DB $91,$05,$B8,$05,$E7,$FE,$C3,$05,$42,$0D,$00,$00,$CB,$5C,$C9,$02,$E9,$01,$F2,$FF
; 23 bytes equal to the 48K ROM's $0652-$0668 (SA-DATA: RST $18, CP $E4 ... LD HL,0), cut off by the block's end
RomSaData:
  DB $DF,$FE,$E4,$20,$49,$3A,$74,$5C,$FE,$03,$CA,$8A,$1C,$E7,$CD,$B2
  DB $28,$CB,$F9,$30,$0B,$21,$00
LoaderEnd:

  SAVEBIN "loader-plain.bin",Decrypt,LoaderEnd-Decrypt
