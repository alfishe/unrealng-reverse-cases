; --------------------------------------------------------------------------------------------------------------------
; stage2-module.asm: The second loader stage: the key, the deciphering, groups 2 and 3, the start
;
; Group 1's block 46, which Rick1 copies to $5D00 and whose tail jumps to it: $5D00-$5D3F come plain, $5D40-$5DFF
; enciphered with the key, which this stage makes and then uses on itself. It loads group 1's last block (only three
; of its pointers are read), makes the key from the key page and Rick1's code, deciphers its own rest and the pages
; $CF00-$FBFF, shows the loading screen and calls LoadGroup for groups 2 and 3. Last it starts the game at $AB4D, or,
; with two keys held, verifies the image against a plain tape block: a check for the tape duplicators.
;
; The key: key[i] = keypage[$C900 + i] XOR Rick1[$CD00 + i] XOR Rick1[$CE00 + i], made in place over the key page.
; tools/bleepload.py does the same both ways; the tape stores the key page (src/res/loader/keypage.bin) and the plain
; bytes of every other page.
; --------------------------------------------------------------------------------------------------------------------

; The second stage's entry: load and check group 1's last block, without
; storing it
;
; Entered from block 46's tail (`JP $5D00`) with IX = `$CD3E`, the address
; StoreBlock left (pushed for MakeKey). Loads block 47 by LoadBlock and checks
; it (CheckBlock; a bad one: BadBlock and again). The block is never stored:
; its payload and its tail's `JP $5D94` are decoys, and only KeyPagePtr,
; KeyedFrom and KeyedEnd in the buffer are read.
;
; Witness: L1 1 (c1).
Stage2Start:
  PUSH IX
LoadLastBlock:
  CALL LoadBlock
  CALL CheckBlock
  CP (HL)
  JR Z,MakeKey
  LD B,$00
  CALL BadBlock
  JR LoadLastBlock
MakeKey:
  DI                      ; HL = Rick1's first page; each key page byte XOR
                          ; Rick1[$CD00 + i] XOR Rick1[$CE00 + i]
  POP HL
  LD L,$00
  LD DE,(KeyPagePtr)
MakeKeyLoop:
  LD A,(DE)
  XOR (HL)
  INC H
  XOR (HL)
  DEC H
  LD (DE),A
  INC L
  INC E
  JR NZ,MakeKeyLoop
DecipherSelf:
  LD DE,(KeyPagePtr)           ; the stage's bytes $5D40-$5DFF XOR key[0..$BF]
  LD HL,Stage2Start+$40
DecipherSelfLoop:
  LD A,(DE)
  XOR (HL)
  LD (HL),A
  INC E
  INC L
  JR NZ,DecipherSelfLoop
  LD HL,$0000             ; NMIADD = 0, DF_SZ = 2
  LD (NmiAdd),HL
  LD A,$02
  LD (DfSz),A
DecipherGroup1:
  LD DE,(KeyPagePtr)           ; KeyedFrom to KeyedEnd: each byte XOR key[address
                          ; AND $FF]
  LD HL,(KeyedFrom)
DecipherLoop:
  LD A,(DE)
  XOR (HL)
  LD (HL),A
  INC HL
  INC E
  JR NZ,DecipherLoop
  LD A,(KeyedEnd)
  CP H
  JR NZ,DecipherLoop
ShowScreen:
  LD SP,Stage2Start+$FF   ; the stack under $5DFF, the loading screen to the
                          ; screen
  LD HL,Group1Screen
  LD DE,Screen
  LD BC,$1B00
  LDIR
  LD HL,Group1Low             ; the game's $5E00-$6DFF
  LD DE,GameLow
  LD BC,$1000
  LDIR
LoadGroup2:
  LD A,$34                ; marker $34; the status line at AT 19,14, the error
                          ; line at AT 20,14
  LD BC,$0E13
  LD DE,$0E14
  CALL LoadGroup
  LD HL,Screen             ; clear the screen and its attributes
  LD DE,Screen+1
  LD BC,$1AFF
  LD (HL),$00
  LDIR
LoadGroup3:
  LD A,$35                ; marker $35, into $4000-$45FF; the status at AT
                          ; 10,10, the errors at AT 13,10
  LD BC,$0A0A
  LD DE,$0A0D
  CALL LoadGroup
  LD HL,Screen             ; group 3 to the game's $FA00-$FFFF
  LD DE,$FA00
  LD BC,$0600
  LDIR
StartOrVerify:
  EI                      ; KEY-SCAN: two keys whose codes differ by $21
                          ; verify, else start
  CALL KeyScan
  JR Z,StartGame
  LD A,D
  SUB E
  CP $21
  JR NZ,StartGame
VerifyImage:
  LD IX,GameLow             ; LD-BYTES in verify mode: $5E00-$FF1D against a
                          ; ROM-speed block, flag $FF
  LD DE,$A11E
  XOR A
  DEC A
  CALL LdBytes
  JR NC,VerifyFailed
  LD A,$04
  JR ShowVerify
VerifyFailed:
  XOR A
ShowVerify:
  OUT ($FE),A             ; the border green (the bytes agree) or black,
                          ; forever
  JR ShowVerify
StartGame:
  JP GameEntry                ; the game

; The page's last 66 bytes: zeros on the tape; the stack under $5DFF from
; ShowScreen on
Stage2Spare:
  DEFS $29
  DEFS $19                ; the stack at the game's entry: 24 bytes the game's
                          ; image holds here
