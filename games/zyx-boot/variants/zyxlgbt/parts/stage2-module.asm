; --------------------------------------------------------------------------------------------------------------------
; stage2-module.asm: Decrypt itself, load and run the menu, then load the chosen program and decrypt it with the track's gap byte
;
; The Lotus Group disks hold their programs encrypted. Stage 2 decrypts its own bytes $FE02-$FF01 like the loader (R =
; $DE, then the byte, HL and DE), reads the menu's three pieces from the sectors after it (code, graphics, music),
; runs the menu, loads the BASIC file the menu chose and decrypts it: each byte XOR R (started from TrackKey) XOR the
; first letter of its name. Then it runs the program as RUN would.
; --------------------------------------------------------------------------------------------------------------------

; Decrypt $FE02-$FF01: each byte XOR R XOR H XOR L XOR D XOR E
Stage2:
  DI
  LD HL,Stage2Loop+$000D
  LD DE,$0100
  LD A,$DE
  IM 2
  LD R,A

; One byte
Stage2Loop:
  LD A,R
  XOR (HL)
  XOR H
  XOR L
  XOR D
  XOR E
  LD (HL),A
  INC HL
  DEC DE
  LD A,D
  OR E
  JR NZ,Stage2Loop

; Read 15 sectors to MenuStart, 8 to MenuGraphics, 24 to Music, each from
; TrdosNextSector; run the menu
LoadMenu:
  DI
  IM 1
  LD HL,MenuStart
  LD DE,(TrdosNextSector)
  LD B,$0F
  LD C,$05
  CALL TrdosEntry
  LD HL,MenuGraphics
  LD DE,(TrdosNextSector)
  LD B,$08
  LD C,$05
  CALL TrdosEntry
  LD HL,Music
  LD DE,(TrdosNextSector)
  LD B,$18
  LD C,$05
  CALL TrdosEntry
  CALL MenuStart

; The chosen file's descriptor from LaunchName, load it as "B"
LoadChosen:
  DI
  LD HL,LaunchName
  LD C,$13
  CALL TrdosEntry
  XOR A
  LD (TrdosError),A
  LD HL,TrdosType
  LD (HL),$42
  LD C,$0E
  CALL TrdosEntry

; Decrypt the loaded program: each byte XOR R (from TrackKey) XOR the first
; letter of its name
DecryptProgram:
  LD HL,Prog
  LD BC,(TrdosLength)
  INC B
  DI
  LD C,$00
  LD A,(TrdosDescriptor)
  LD IXH,A
  LD A,(TrackKey)
  IM 2
  LD HL,Prog
  LD R,A
l_FE64:
  LD A,R
  XOR (HL)
  XOR IXH
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,l_FE64

; Put RUN in the edit line, TR-DOS's hook to RET, then the ROM's CL-ALL and
; LINE-RUN
RunProgram:
  IM 1
  EI
  LD HL,(ELine)
  LD (HL),$F7
  INC HL
  LD E,(HL)
  LD (HL),$30
  INC HL
  LD D,(HL)
  LD (HL),$0E
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$0D
  LD A,$C9
  LD (TrdosHook),A
  LD HL,RomStart
  PUSH HL
  LD (ErrSP),SP
  CALL RomClAll
  LD A,$19
  SUB (IY+$4F)
  LD (ScrCt),A
  SET 7,(IY+$01)
  LD (IY+$00),$FF
  LD (IY+$0A),$01
  CALL RomLineRun
  JP RomStart

; leftover code, not run
Stage2Tail:
  DEFB $F3,$DD,$46,$0C,$DD,$7E,$0B,$FE,$00,$00,$00,$04,$C9

; zeros to the sector's end
Stage2Zeros:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
