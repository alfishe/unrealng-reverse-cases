; --------------------------------------------------------------------------------------------------------------------
; launcher-module.asm: The launcher: the flag the menu tests, then find the chosen file in the catalogue and run it through the TR-DOS ROM
;
; Variant zyxboot-01 starts the chosen BASIC file itself instead of returning to the loader's RUN: its loader ends
; with CALL $61A8 (the menu) and JP Launcher. LauncherFlag is 0 on the disk; the menu's Start reads the catalogue only
; while it is 0 (the code switch catalogue-call, tools/variants.py).
; --------------------------------------------------------------------------------------------------------------------

; 0: the menu reads the catalogue itself (Start tests this byte)
LauncherFlag:
  DEFB $00

; Find the name the menu wrote into line 1 in the catalogue copy, load that
; file's header into TR-DOS's descriptor, clear the menu's memory and run the
; file through the TR-DOS ROM
;
; Every catalogue entry whose name differs from LaunchName $5D4E is marked $FD
; (deleted) as it is passed, so the ROM's search stops at the chosen one.
Launcher:
  LD HL,Catalogue
l_FF18:
  LD DE,LaunchName
  LD B,$08
l_FF1D:
  LD A,(DE)
  LD C,A
  LD A,(HL)
  CP C
  JR NZ,l_FF29
  INC HL
  INC DE
  DJNZ l_FF1D
  JR l_FF2E
l_FF29:
  LD (HL),$FD
  INC HL
  JR l_FF18
l_FF2E:
  LD B,$08                ; found: back to the entry's start, its 9 bytes of
                          ; name and type to TrdosDescriptor $5CDD, type "B"
l_FF30:
  DEC HL
  DJNZ l_FF30
  LD DE,TrdosDescriptor
  LD BC,$0009
  LDIR
  LD A,$42
  LD (TrdosStartHigh),A
  LD A,(HL)               ; start, length, sectors, sector and track into
                          ; TR-DOS's variables, each marked $FD in the copy
  LD E,A
  LD (HL),$FD
  INC HL
  LD A,(HL)
  LD D,A
  LD (HL),$FD
  INC HL
  LD (TrdosStart),DE
  LD A,(HL)
  LD E,A
  LD (HL),$FD
  INC HL
  LD A,(HL)
  LD D,A
  LD (HL),$FD
  INC HL
  LD (TrdosLength),DE
  LD A,(HL)
  LD (HL),$FD
  INC HL
  LD (TrdosSectors),A
  LD A,(HL)
  LD (HL),$FD
  INC HL
  LD (TrdosSector),A
  LD A,(HL)
  LD (HL),$FD
  LD (TrdosTrack),A
  LD HL,MenuStart             ; clear the menu's memory $61A8-$FF13 and take the
                          ; BASIC stack back
  LD DE,$61A9
  LD BC,$9D6C
  LD (HL),$00
  LDIR
  LD SP,$FEAE
  LD SP,(ErrSP)
  POP HL
  LD (SavedReturn),HL
  LD HL,LauncherRun
  PUSH HL
  DI                      ; the TR-DOS variables of a LOAD, then the ROM's
                          ; routines at $021D and $294A through TrdosRet
  XOR A
  LD (TrdosFlag10),A
  DEC A
  LD (ErrNr),A
  LD (TrdosFlag15),A
  LD (TrdosFlag1F),A
  LD HL,$0201
  LD (TrdosWord1A),HL
  LD (TrdosSaveSP),SP
  DEC SP
  DEC SP
  LD IX,$021D
  CALL RomCall
  LD IX,$294A
  CALL RomCall
  XOR A
  LD (TrdosFlag10),A
  LD (TrdosFileType),A
  CALL RomRun

; Run the loaded program: the ROM's routine $012A through TrdosRet, with the
; saved return address
LauncherRun:
  LD SP,(ErrSP)
  POP HL
  LD HL,(SavedReturn)
  PUSH HL
  LD IX,$012A

; Run the routine at IX inside the TR-DOS ROM (PUSH IX, JP TrdosRet)
;
; Used by the routines at Launcher and RomRun.
RomCall:
  PUSH IX
  JP TrdosRet

; Run the ROM's $2920 with $01D3 as its return
;
; Used by the routine at Launcher.
RomRun:
  LD HL,$01D3
  PUSH HL
  LD IX,$2920
  JR RomCall

; The return address the launcher takes from the BASIC stack
SavedReturn:
  DEFW $0000

; Seven words $147B-$148D left by the program that saved the file; not read
LauncherWords:
  DEFW $147B,$147E,$1481,$1484,$1487,$148A,$148D

; Leftover bytes of the saving machine's memory (part of an assembler line,
; DEFB and a hex number); not read
LauncherJunk:
  DEFB $00,$00,$00,$00,$44,$45,$46,$42
  DEFB $20,$23,$41,$32,$2C,$00,$42,$42
  DEFB $42,$42,$42,$3C,$00
