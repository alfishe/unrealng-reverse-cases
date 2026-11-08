; The Softlock pieces of the tape that are code: the chunk reader, its three patches, the decryptor and the plain
; loader left in two filler chunks. docs/03-build-and-load.md 3.5-3.7. tools/mktape.py puts each file in its chunk
; (src/tape/elite-tzx.txt); SoftByte and SoftBytes are the Softlock loader's entry points, rebuilt from the ROM by
; the stub (src/tape/basic.asm).

  DEVICE ZXSPECTRUM48

SoftBytes   EQU $FF70           ; the copy's byte loop: B = $86, the next byte into L, the store loop
LD_BLOCK    EQU $0802           ; the ROM's LD-BLOCK: IX, DE, A = the flag, carry = load
Kickoff     EQU $D05F           ; the game's kickoff: the two ROM blocks, the Lenslok, the game (03 3.7)
ERR_NR      EQU $5C3A           ; IY's value for the ROM

; ---------------------------------------------------------------------------------------------------------------
; The chunk reader, the page $5B00-$5BFF of the turbo block. LD-BYTES "returns" here after the turbo block, and
; the reader leaves its own address on the stack again each time, so every chunk ends by entering it again.
  ORG $5B00
ChunkReader:
  DEC SP
  DEC SP                        ; the return to ChunkReader back on the stack
  CALL SoftBytes
  LD A,L
  LD IXL,A
  CALL SoftBytes
  LD A,L
  LD IXH,A
  PUSH IX                       ; the length
  CALL SoftBytes
  LD A,L
  LD IXL,A
  CALL SoftBytes
  LD A,L
  LD IXH,A                      ; IX = the address
ChunkEnd:                       ; $5B1C: the stream patches these bytes three times (PatchUp, PatchKey, PatchDown)
  LD A,IXL
  OR IXH
  RET Z                         ; never taken: the patches take the test away before an address 0 could come
  POP DE                        ; DE = the length
  JP SoftBytes                  ; the data and the check byte, then RET into ChunkReader
  DB $00
; The rest of the page is what the mastering machine's memory held: the RETs a run of the decryptor fills the page
; with up to its own LDIR at $5B47, the LDIR's second byte, and zeros (inference: the tape was saved after a run)
  DS $5B48-$, $C9
  DB $B0
  DS $5C00-$, 0
ReaderPageEnd:
  SAVEBIN "reader-page.bin",ChunkReader,ReaderPageEnd-ChunkReader

; ---------------------------------------------------------------------------------------------------------------
; The three patches of ChunkEnd, each a chunk of its own
  ORG $5B1C
PatchUp:
  INC IXH                       ; every later address lands 256 bytes higher
  SAVEBIN "patch-up.bin",PatchUp,$-PatchUp
  ORG $5B1C
PatchKey:
  LD IY,$2E6D                   ; the decryptor's two constants (Decrypt)
  NOP                           ; over the RET Z: the end test is gone for good
  SAVEBIN "patch-key.bin",PatchKey,$-PatchKey
  ORG $5B1C
PatchDown:
  DEC IXH                       ; every later address lands 256 bytes lower
  SAVEBIN "patch-down.bin",PatchDown,$-PatchDown

; ---------------------------------------------------------------------------------------------------------------
; The decryptor, the last chunk: it lands over the reader that loads it, whose RET enters it.
  ORG $5B00
Decrypt:
  XOR A
  OUT ($FE),A                   ; the border black
  LD HL,$D0A8
  LD DE,$D0A8
  LD BC,$7060                   ; $6049-$D0A8, top down, in place
  LD IX,$5AFF                   ; the key: memory from $5AFF down (the loading screen, then the ROM)
  LD A,$FF
  LD R,A                        ; bit 7 of R stays 1 from here on: the Lenslok's seed (lenslok.md 4.2)
DecryptLoop:
  LD A,(HL)
  SUB (IX+0)
  XOR IYL                       ; $6D
  RLCA
  XOR IYH                       ; $2E
  LD (DE),A
  DEC HL
  DEC DE
  DEC BC
  DEC IX
  LD A,IXH
  OR IXL
  JR NZ,DecryptNext
  LD IXH,$5A                    ; after $0001 the key starts again at $5A00
DecryptNext:
  LD A,B
  OR C
  JR NZ,DecryptLoop
  LD HL,Kickoff
  LD DE,Decrypt+1
  LD BC,$00FF
  LD SP,$FFFF
  LD IY,ERR_NR
  PUSH HL                       ; the RET below goes to Kickoff
  LD HL,Decrypt
  LD A,$C9
  LD (HL),A
DecryptWipe:
  LDIR                          ; fills the page with RET; at $5B47 it overwrites its own $ED and runs the RET
DecryptEnd:
  DS $5B5C-$, 0
  SAVEBIN "decrypt.bin",Decrypt,$-Decrypt

; ---------------------------------------------------------------------------------------------------------------
; A plain ROM loader, the same 43 bytes at $F300 in the filler chunks of TZX blocks 7 and 9 (all zeros otherwise).
; It loads a screen and $6048-$D0B9 as two ROM blocks and enters the kickoff at the start of the game's top block:
; the shape of the game's tape before Softlock (inference: nothing on the tape calls it, and $6048 + $7072 is
; exactly $D0BA, where TZX block 36 starts).
  ORG $F300
PlainLoader:
  LD SP,$FFFF
  PUSH IX
  LD IX,$4000
  LD DE,$1B00                   ; a screen
  LD A,$FF
  SCF
  CALL LD_BLOCK
  EI
  LD B,$20
PlainWait:
  HALT
  DJNZ PlainWait                ; 32 frames
  LD IX,$6048
  LD DE,$7072                   ; $6048-$D0B9
  LD A,$FF
  SCF
  CALL LD_BLOCK
  EI
  RET
  POP HL
  JP Kickoff
  SAVEBIN "plain-loader.bin",PlainLoader,$-PlainLoader
