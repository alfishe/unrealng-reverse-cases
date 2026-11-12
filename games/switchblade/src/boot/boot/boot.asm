; --------------------------------------------------------------------------------------------------------------------
; boot.asm: The bootstrap: IM 2, the copies of the game's resident parts, the 128K hooks and glue
;
; Run by stage 2's JP $4000 after block 5 is loaded into the screen. It sets the IM 2 vector table, copies the game's
; start code from $4146 to $5C00 and the panel code from $5093 to $FF01 (over the tape loader), and on a 128K patches
; five hook sites in the game and copies the AY glue to $853F. Then JP $5CFA, the game's entry. The 48K and 128K games
; are the same program: only these five sites and the code at $853F differ.
;
; The five hook sites, three bytes each from HookBytes $4095 (LDI x 3 each, in this order): 1. $5CFD (GameEntry's CALL
; $5D4F, the 48K intro) <- 00 00 00: no 48K intro. 2. $A6EF (ShowHighScores, the fire test CD 29 85 = CALL $8529) <-
; CD 9E 85 = CALL $859E, GlueMenuInput. 3. $A76F (TitleSequence, CD 29 85) <- CD 9E 85 = CALL $859E. 4. $A75C
; (TitleSequence after each clear, 00 00 00) <- CD B3 85 = CALL $85B3, GlueSoundIcon. 5. $5C9A (NewGame before the
; globals, 00 00 00) <- CD C5 85 = CALL $85C5, GlueIntro. At sites 2 and 3 only the middle byte differs from the 48K
; game ($A6F0, $A770: $29 -> $9E).
; --------------------------------------------------------------------------------------------------------------------

; Set IM 2, copy the game's resident parts, on a 128K patch the hooks and copy
; the glue, enter the game
;
; 1. DI, SP = `$5C00`, border black.
;
; 2. BootModel `$4051`'s operand (written by stage 2's Has128K: 1 on a 128K)
; chooses: a 128K first runs SetVectors with A = `$14` (bank 4 at `$C000`), so
; bank 4 gets the vector table too (the interrupt can come while the glue has
; it paged in); then on every machine SetVectors with A = `$10` (bank 0, the
; 48K BASIC ROM). I = `$FE`, IM 2: whatever byte is on the bus, the vector read
; from the table is `$FDFD`, which holds `JP $8456` (InterruptHandler).
;
; 3. ResidentSource `$4146` -> `$5C00` (`$F4D` bytes, to `$6B4C`), PanelSource
; `$5093` -> `$FF01` (`$FE` bytes, to `$FFFE`).
;
; 4. 48K: `JP Z,$5CFA`. 128K: the five hooks (see the module header), the glue
; `$40A4` -> `$853F` (`$A2` bytes), `JP $5CFA`.
;
; Interrupts stay off: the game turns them on (the first `EI`: WaitFireFrames
; `$8324` in the 48K story; on a 128K GlueMenuInput `$85A1` on the title).
;
; Witness: L1 2 (c x2).
Bootstrap:
  DI
  LD SP,GlobalsInit
  XOR A
  OUT ($FE),A
  LD A,(BootModel+$0001)  ; stage 2's answer: 1 on a 128K
  OR A
  JR Z,BootVectors0
  LD A,$14
  CALL SetVectors
BootVectors0:
  LD A,$10                ; bank 0 (and the 48K ROM) at $C000: its vector table
  CALL SetVectors
  LD A,$FE                ; I = $FE, IM 2
  LD I,A
  IM 2
  JR BootCopy

; Page A into $7FFD, write JP $8456 at $FDFD and 257 bytes $FD from $FE00
;
; A = the `$7FFD` value. `$C3` at `$FDFD`, the address of InterruptHandler
; `$8456` at `$FDFE`; the table `$FE00-$FF00` (B = 0: 256 bytes, then one more)
; all `$FD`, so any byte on the bus gives the vector `$FDFD`. The byte at
; `$FF00` (the tape loader's first) is overwritten too.
;
; Witness: L1 3 (c x2).
SetVectors:
  LD BC,$7FFD
  OUT (C),A
  LD A,$C3
  LD (Im2Jump),A
  LD HL,InterruptHandler
  LD (Im2Jump+1),HL
  LD HL,Im2Table
  LD BC,$00FD
SetVectorsLoop:
  LD (HL),C
  INC HL
  DJNZ SetVectorsLoop
  LD (HL),C
  RET
; This entry point is used by the routine at Bootstrap.
BootCopy:
  LD HL,ResidentSource             ; the game's start code to $5C00, the panel code to
                          ; $FF01
  LD DE,GlobalsInit
  LD BC,$0F4D
  LDIR
  LD HL,PanelSource
  LD DE,PanelWeapon
  LD BC,$00FE
  LDIR
BootModel:
  LD A,$01                ; LD A,$01: the operand at $4052 is written by stage
                          ; 2 (0 on a 48K)
  OR A
  JP Z,GameEntry
  LD HL,HookBytes         ; 128K: the five hook sites
  LD DE,GameEntryIntro
  LDI
  LDI
  LDI
  LD DE,ShowHighScoresHook             ; site 2: ShowHighScores' fire test
  LDI
  LDI
  LDI
  LD DE,TitleStepHook             ; site 3: TitleSequence's fire test
  LDI
  LDI
  LDI
  LD DE,TitleColourHook             ; site 4: TitleSequence after the clear
  LDI
  LDI
  LDI
  LD DE,NewGameIntroHook             ; site 5: NewGame before the globals
  LDI
  LDI
  LDI
  LD HL,$40A4             ; the glue to $853F
  LD DE,AyGlue
  LD BC,$00A2
  LDIR
  JP GameEntry

; The three bytes written to each hook site, in the order of the LDIs
;
; Not code: the mechanical cut read them as instructions. 15 bytes, five sites.
HookBytes:
  DEFB $00,$00,$00        ; site 1, $5CFD: 00 00 00 over CALL $5D4F (no 48K
                          ; intro)
  DEFB $CD,$9E,$85        ; site 2, $A6EF: CALL $859E (GlueMenuInput)
  DEFB $CD,$9E,$85        ; site 3, $A76F: CALL $859E (GlueMenuInput)
  DEFB $CD,$B3,$85        ; site 4, $A75C: CALL $85B3 (GlueSoundIcon)
  DEFB $CD,$C5,$85        ; site 5, $5C9A: CALL $85C5 (GlueIntro)
