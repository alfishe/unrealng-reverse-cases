; --------------------------------------------------------------------------------------------------------------------
; stage2-module.asm: The loader's second stage: the title scroll, the load of blocks 4-6, the 128K test
;
; Stage 2 shows the SWITCHBLADE logo and scrolls "COPYRIGHT GREMLIN GRAPHICS 1991 ... LOADING" (Stage2Title), then
; loads block 4 (the game, $92A1 bytes to $6B5C-$FDFC) and block 5 ($1191 bytes to $4000: the bootstrap, the AY glue
; and the resident code, into the screen) with the tape loader's LoadBlock, tests for a 128K (Has128K, which also
; tells the bootstrap), and on a 128K loads block 6 ($20F9 bytes, the AY player and the 128K intro) through $8000 into
; bank 4. Then JP $4000, the bootstrap.
;
; Bank 4 cannot be loaded directly: paging it in at $C000 would page out the loader at $FF00. So SwapBank swaps
; $8000-$A0F8 with bank 4's $C000-$E0F8 before the load and again after it: the game's bytes at $8000 go back, block 6
; ends in bank 4.
;
; TapeWriter $60A5 is a leftover of the mastering tool that wrote the tape: never called, it uses routines and a
; header outside this block.
; --------------------------------------------------------------------------------------------------------------------

; The second stage: the title scroll, the load of the game, then the bootstrap
;
; From LoaderStart `$FFEE` (`JP $609C`). Stage2Title `$61B2`, LoadGame `$612F`,
; `JP $4000` (the bootstrap, block 5).
;
; Witness: L1 2 (c x2).
Stage2:
  CALL Stage2Title
  CALL LoadGame
  JP Bootstrap

; A leftover of the mastering tool: read the blocks, then save the whole tape
; (never run)
;
; Not called from anywhere in the tape's code. HL, DE (pushed twice) are a
; block's address and length (stage 2 itself, by the order). First pass:
; ToolInit `$FE00`, ToolRead `$FE4D` on that block, a wait (Delay `$621F`, E =
; 6), then ToolRead on block 4 (`$6B5C`, `$92A1`), block 5 (`$4000`, `$1191`)
; and, between two SwapBank calls (bank 4), block 6 (`$8000`, `$20F9`). Then
; ToolStep `$5FA9` with A = 1.
;
; Second pass, the tape in its order: a header (ToolSaBytes `$FECE`, flag 0,
; HeaderTemplate `$68A8`, 17 bytes), its data (ToolSaveBlock `$FECC` from
; `$68B9`, length = the header's parameter 2), the first block (the pushed HL,
; DE), block 4, block 5, block 6 (swapped through bank 4 again). The same
; addresses and lengths as LoadGame: this is how the tape was written.
;
; What `$FE00`, `$FE4D`, `$5FA9` do is not known (they are not on the tape);
; the names are guesses from the calls.
;
; Witness: L1 0 (). Not run in the keyed recordings.
TapeWriter:
  PUSH HL
  PUSH DE
  PUSH HL
  PUSH DE
  CALL ToolInit
  POP DE
  POP IX
  CALL ToolRead
  LD E,$06                ; wait about 3 s
  CALL Delay
  LD IX,Block4
  LD DE,$92A1
  CALL ToolRead
  LD IX,Bootstrap
  LD DE,$1191
  CALL ToolRead
  LD A,$14
  CALL SwapBank
  LD IX,Block6Buffer
  LD DE,$20F9
  CALL ToolRead
  LD A,$14
  CALL SwapBank
  LD A,$01                ; the second pass: the header, its data, then the
                          ; blocks
  CALL ToolStep
  XOR A
  LD IX,HeaderTemplate
  LD DE,$0011
  CALL ToolSaBytes
  LD IX,HeaderTemplate
  LD E,(IX+$0F)
  LD D,(IX+$10)
  LD IX,HeaderData
  CALL ToolSaveBlock
  POP DE
  POP IX
  CALL ToolSaveBlock
  LD IX,Block4
  LD DE,$92A1
  CALL ToolSaveBlock
  LD IX,Bootstrap
  LD DE,$1191
  CALL ToolSaveBlock
  LD A,$14
  CALL SwapBank
  LD IX,Block6Buffer
  LD DE,$20F9
  CALL ToolSaveBlock
  LD A,$14
  CALL SwapBank
  RET

; Load block 4 to $6B5C, block 5 to $4000 and, on a 128K, block 6 into bank 4
;
; 1. LoadBlock `$FF00`: IX = `$6B5C`, DE = `$92A1` (block 4, the game from
; `$6B5C` to `$FDFC`: just past stage 2, which ends at `$68A7`, and below the
; tape loader at `$FF00`; the stack is still below `$5D37`).
;
; 2. The attributes cleared to 0 (the screen goes black), LoadBlock IX =
; `$4000`, DE = `$1191` (block 5 into the screen: the bootstrap and glue
; `$4000-$4145`, the resident code `$4146-$5092`, the panel code
; `$5093-$5190`).
;
; 3. Has128K `$618E`: on a 48K return. On a 128K: SwapBank (A = `$14`),
; LoadBlock IX = `$8000`, DE = `$20F9` (block 6), SwapBank again.
;
; Witness: L1 2 (c x2).
LoadGame:
  LD IX,Block4
  LD DE,$92A1
  CALL LoadBlock
  LD HL,Attributes             ; black attributes: block 5 loads into a hidden
                          ; screen
  LD DE,Attributes+1
  LD BC,$02FF
  LD (HL),$00
  LDIR
  LD IX,Bootstrap
  LD DE,$1191
  CALL LoadBlock
  CALL Has128K            ; a 128K: block 6 through $8000 into bank 4
  JR Z,LoadGameEnd
  LD A,$14
  CALL SwapBank
  LD IX,Block6Buffer
  LD DE,$20F9
  CALL LoadBlock
  LD A,$14
  CALL SwapBank
LoadGameEnd:
  RET

; Page bank A, swap $8000-$A0F8 with $C000-$E0F8, page bank 0 and the 48K ROM
; ($10)
;
; A = the `$7FFD` value (`$14`: bank 4, the 48K BASIC ROM). DI first. SwapBlock
; `$617B`, then `$10` to `$7FFD`.
;
; Witness: L1 2 (c x1). Ran only in c1 (the 128K).
SwapBank:
  DI
  LD BC,$7FFD
  OUT (C),A
  CALL SwapBlock
  LD A,$10
  LD BC,$7FFD
  OUT (C),A
  RET

; Swap the $20F9 bytes at $8000 with those at $C000
;
; Witness: L1 2 (c x1). Ran only in c1.
SwapBlock:
  LD HL,Block6Buffer
  LD DE,BankWindow
  LD BC,$20F9
SwapBlockLoop:
  LD A,(DE)
  LDI
  DEC HL
  LD (HL),A
  INC HL
  JP PE,SwapBlockLoop
  RET

; Is there a 128K's paging? Z on a 48K; the answer also goes to the bootstrap
; (BootIs128K $4052)
;
; Takes the byte at `$C000`, pages bank 4 (`$14`), writes its complement, pages
; bank 0 (`$10`) and compares: unchanged means bank 4 is another bank (a 128K,
; E = 1); on a 48K the port does nothing, the byte read back is the complement
; (E = 0). The byte is put back; E is stored at `$4052`, the operand of the
; bootstrap's `LD A,$01` (block 5 was just loaded there), and A = E, Z on a
; 48K.
;
; Witness: L1 2 (c x2).
Has128K:
  LD HL,BankWindow
  LD A,(HL)
  PUSH AF
  CPL
  LD D,$14
  LD BC,$7FFD
  OUT (C),D
  LD (HL),A
  LD D,$10
  LD BC,$7FFD
  OUT (C),D
  CP (HL)
  LD E,$00
  JR Z,Has128KStore
  LD E,$01
Has128KStore:
  POP AF
  LD (HL),A
  LD A,E
  LD (BootIs128K),A
  OR A
  RET

; The loading screen: the logo, then "COPYRIGHT GREMLIN GRAPHICS 1991" scrolls
; out and "LOADING" in
;
; Attributes all `$47` (white on black). Logo `$622B` at `$4803` (26 bytes x 48
; rows, Blit with A = 6 character rows); Blit's source step (`$620B`) = `$1B`,
; so a row of ScrollText (59 bytes) shows 32 bytes; ScrollShow, a wait (Delay E
; = 5, about 2.4 s), then 80 steps: every row of ScrollText is shifted 4 pixels
; left (RLD from its right end, a 0 nibble in) and shown again. After 320
; pixels "LOADING" stands in the window.
;
; Witness: L1 2 (c x2).
Stage2Title:
  LD HL,Attributes
  LD DE,Attributes+1
  LD BC,$02FF
  LD (HL),$47
  LDIR
  LD HL,Logo
  LD DE,ScreenMiddle+3
  LD BC,$081A
  LD A,$06
  CALL Blit
  LD HL,$001B             ; the text window: 32 of the 59 bytes a row
  LD (BlitStep+$0001),HL
  CALL ScrollShow
  LD E,$05
  CALL Delay
  LD B,$50                ; 80 steps of 4 pixels
Stage2TitleStep:
  PUSH BC
  LD HL,ScrollText+$019C
  LD E,$07
Stage2TitleRow:
  LD B,$3B
  XOR A
Stage2TitleShift:
  RLD
  DEC HL
  DJNZ Stage2TitleShift
  DEC E
  JR NZ,Stage2TitleRow
  CALL ScrollShow
  POP BC
  DJNZ Stage2TitleStep
  RET

; Show 32 bytes of each of the 7 rows of ScrollText at $48E0
;
; HL = ScrollText `$670B`, DE = `$48E0`, B = 7 rows, C = 32 bytes, A = 1
; character row; falls into Blit.
;
; Witness: L1 872 (c x2).
ScrollShow:
  LD HL,ScrollText
  LD DE,ScreenMiddle+224
  LD BC,$0720
  LD A,$01

; Copy A character rows of B pixel rows x C bytes from HL to the screen at DE;
; HL += the step at $620B a row
;
; The inner loop copies one pixel row (LDIR), adds the source step (the operand
; at `$620B`, 0 for the logo, `$1B` for the scroll) and goes one pixel row down
; (INC D); after B rows E + 32, the next character row.
;
; Witness: L1 806 (c x2).
Blit:
  PUSH AF
  PUSH DE
  PUSH BC
  LD A,B
  LD B,$00
BlitRow:
  PUSH DE
  PUSH BC
  LDIR
BlitStep:
  LD BC,$0000             ; the operand: the source bytes skipped after each
                          ; row (Stage2Title writes $1B)
  ADD HL,BC
  POP BC
  POP DE
  INC D
  DEC A
  JR NZ,BlitRow
  POP BC
  POP DE
  LD A,E
  ADD A,$20
  LD E,A
  POP AF
  DEC A
  JR NZ,Blit
  RET

; Wait E x 65536 loops (about 0.49 s each at 3.5 MHz)
;
; Witness: L1 48 (c x2).
Delay:
  LD BC,$0000
DelayLoop:
  DEC BC
  LD A,B
  OR C
  JR NZ,DelayLoop
  DEC E
  JR NZ,DelayLoop
  RET

; The SWITCHBLADE logo: 48 pixel rows of 26 bytes, drawn by Blit at $4803
;
; A graphics resource (1248 bytes, plain rows top to bottom; the attribute is
; `$47`).
Logo:
  INCBIN "res/graphics/loader-logo.bin",$0000,1248

; The scroll's text in pixels: 7 rows of 59 bytes, "COPYRIGHT GREMLIN GRAPHICS
; 1991", spaces, "LOADING"
;
; A graphics resource (413 bytes, to `$68A7`, the last byte of the block).
; Stage2Title shifts it in place.
ScrollText:
  INCBIN "res/graphics/loader-scroll.bin",$0000,413
