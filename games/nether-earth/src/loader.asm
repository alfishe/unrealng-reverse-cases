; N1, the loader of Nether Earth: the tape's block 3 (180 bytes). The BASIC loads it with LOAD "" CODE 64730, at
; $FCDA, not at the header's $F938, and enters it with RANDOMIZE USR 64730.
;
; It is the ROM's LD-BYTES ($0556) moved into RAM, the same edge timing to the T-state (the constants $16, $415, $9C,
; $C6, $C9, $D4, $B0, $B2, $CB are the ROM's), with three changes:
;   - it loads the headerless game block itself: 48361 bytes from $4000 ($4000-$FCE8, the screen included);
;   - each edge paints the border a random colour (LD A,R): the stripes are noise, not the ROM's red / cyan;
;   - it returns to $A600, the game's start, pushed before the load: a bad checksum or BREAK go there too.
; The block's last 15 bytes land on $FCDA-$FCE8, this loader's own first bytes, which have run by then.
; docs/03-build-and-load.md.

  DEVICE ZXSPECTRUM48
  ORG $FCDA

GameStart   EQU $A600
GameBlock   EQU $4000
GameLength  EQU $BCE9           ; 48361

N1:
  LD SP,$FFE0
  SCF                           ; carry: load, not verify
  LD A,$FF                      ; the flag byte expected
  LD IX,GameBlock
  LD DE,GameLength
  INC D                         ; the ROM's LD-BYTES entry: the length and flag kept in DE / A'
  EX AF,AF'
  DEC D
  DI
  LD A,$0F                      ; border white, MIC on
  OUT ($FE),A
  LD HL,GameStart               ; the loader returns into the game
  PUSH HL
  IN A,($FE)
  RRA
  AND $20                       ; the EAR level now
  OR $02
  LD C,A                        ; C: the last EAR level and the border bits
  CP A                          ; Z: no edge yet
LdBreak:
  CALL LdEdge1                  ; wait for an edge (the ROM's LD-START)
  JR NC,LdBreak
  LD HL,$0415                   ; about a second of silence check
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
  JR NC,LdBreak
  INC H
  JR NZ,LdLeader
LdSync:
  LD B,$C9                      ; the sync pulse: short edges
  CALL LdEdge1
  JR NC,LdBreak
  LD A,B
  CP $D4
  JR NC,LdSync
  CALL LdEdge1
  LD A,C
  XOR $03                       ; the border colour bits flip
  LD C,A
  LD H,$00                      ; H: the checksum
  LD B,$B0
  JR LdMarker
LdLoop:
  EX AF,AF'
  JR NZ,LdFlag                  ; the first byte is the flag
  LD (IX+$00),L                 ; $FD3B: every byte of the game is written here
  JR LdNext
LdFlag:
  RL C
  XOR L
  LD A,C
  RRA
  LD C,A
  INC DE
  JR LdDec
LdNext:
  INC IX
LdDec:
  DEC DE
  EX AF,AF'
  LD B,$B2
LdMarker:
  LD L,$01                      ; a marker bit: eight shifts fill the byte
LdBits:
  CALL LdEdge2                  ; one bit: two edges, their length in B
  LD A,$CB
  CP B
  RL L
  LD B,$B0
  JP NC,LdBits
  LD A,H
  XOR L
  LD H,A
  LD A,D
  OR E
  JR NZ,LdLoop
  LD A,H
  CP $01                        ; carry: the checksum was right (the game does not look)
  RET                           ; to GameStart

LdEdge2:
  CALL LdEdge1
  RET NC
LdEdge1:
  LD A,$16                      ; the ROM's delay before sampling
LdDelay:
  DEC A
  JR NZ,LdDelay
  AND A
LdSample:
  INC B
  RET Z                         ; timed out
  LD A,$7F
  IN A,($FE)
  RRA
  RET NC                        ; BREAK
  XOR C
  AND $20
  JR Z,LdSample
  LD A,C                        ; an edge: flip the stored level
  CPL
  LD C,A
  LD A,R                        ; a random border colour, MIC on
  AND $07
  OR $08
  OUT ($FE),A
  SCF
  RET
  NOP                           ; the block's last byte

  SAVEBIN "loader.bin",N1,$-N1
