; --------------------------------------------------------------------------------------------------------------------
; loader-module.asm: Decrypt itself, read track 0 raw and look for its gap bytes, then load the second stage and run it
;
; The loader is a copy-protection check. It decrypts its own 1024 bytes from $9C7D with R, IX, SP and DE (the first
; byte it writes is its JR NZ's offset), reads 4 sectors of track 0 (a decoy: the track read overwrites them), reads
; the whole of track 0 raw with the controller's Read Track command and looks, from TrackTail on, for three bytes
; equal to TrackGapByte: a copy whose track 0 is not formatted as the original's has no such run. Found: the byte goes
; to TrackKey, track 5 sector 0 to Stage2, the loader wipes itself with LDIR in the ROM and returns into Stage2. Not
; found: every port 1-255 is written 0 and the machine restarts.
; --------------------------------------------------------------------------------------------------------------------

; Clear the attributes, keep the BASIC stack, then decrypt $9C7D-$A07C: each
; byte XOR R, IX, SP and DE
Loader:
  DI
  LD HL,Attributes
  LD DE,Attributes+1
  LD BC,$02FF
  LD (HL),L
  LDIR
  LD (SavedSP),SP
  LD SP,KeyStack
  LD IX,DecryptLoop+$001A
  LD DE,$0400
  LD A,$02
  OUT ($FE),A
  IM 2
  LD R,A                  ; R = 2 once: from here every instruction's fetches
                          ; step it

; One byte: A = R XOR the byte XOR IXH XOR IXL XOR H XOR L ($404C, the stack)
; XOR D XOR E
DecryptLoop:
  LD A,R
  XOR (IX+$00)
  XOR IXH
  XOR IXL
  LD HL,$0000
  ADD HL,SP
  XOR H
  XOR L
  XOR D
  XOR E
  LD (IX+$00),A
  INC IX
  DEC DE
  LD A,D
  OR E
  JR NZ,DecryptLoop

; Clear $C000-$FA98, read 4 sectors of track 0 (sector 12) to $C524, the head
; to track 0
Decrypted:
  DI
  IM 1
  XOR A
  OUT ($FE),A
  LD HL,TrackBuffer
  LD DE,TrackBuffer+1
  LD BC,$3A98
  LD (HL),A
  LDIR
  LD HL,DecoyBuffer
  LD DE,$000C
  LD B,$04
  LD C,$05
  CALL TrdosEntry
  LD A,$00
  LD C,$02
  CALL TrdosEntry
  DI                      ; Read Track ($E0 to the controller's command port
                          ; $1F), then the track's bytes from its data port $7F
                          ; to $C000
  LD A,$00
  LD A,$E0
  LD C,$1F
  LD IX,RomWdCommand
  CALL RomCall
  DI
  LD C,$7F
  LD HL,TrackBuffer
  LD IX,RomReadData
  CALL RomCall

; Look in the 254 bytes from TrackTail+1 for three bytes equal to TrackGapByte
FindGap:
  LD IX,TrackTail
  LD D,$FE
l_9CC5:
  LD A,(TrackGapByte)
  INC IX
  CP (IX+$00)
  JR Z,l_9CD7
  DEC D
  LD A,D
  OR A
  JP Z,NoGap
  JR l_9CC5
l_9CD7:
  CP (IX+$01)
  JR NZ,l_9CC5
  CP (IX+$02)
  JR NZ,l_9CC5

; The byte to TrackKey, track 5 sector 0 to Stage2, the BASIC stack back with
; Stage2 as the return, wipe $9C40-$FA98 by the ROM's LDIR
GapFound:
  LD A,(TrackGapByte)
  LD (TrackKey),A
  LD HL,Stage2
  LD DE,$0500
  LD B,$01
  LD C,$05
  CALL TrdosEntry
  LD SP,(SavedSP)
  LD HL,Stage2
  PUSH HL
  LD HL,Loader
  LD DE,Loader+$0001
  LD BC,$5E58
  LD (HL),$00
  JP RomLdirRet

; Write 0 to ports $FF down to $01, then wipe and restart through the ROM
;
; Used by the routine at FindGap.
NoGap:
  DI
  LD C,$FF
l_9D0D:
  XOR A
  OUT (C),A
  DEC C
  LD A,C
  OR A
  JR NZ,l_9D0D
  LD HL,$0000
  PUSH HL
  LD HL,TrdosRet
  PUSH HL
  LD HL,Loader
  LD DE,Loader+$0001
  LD BC,$5E58
  LD (HL),L
  JP RomLdirRet

; Run the routine at IX inside the TR-DOS ROM (PUSH IX, JP TrdosRet)
;
; Used by the routine at Decrypted.
RomCall:
  PUSH IX
  JP TrdosRet

; leftover bytes, not run
LoaderTail:
  DEFB $C1,$EB,$F1,$9B,$A1,$B3,$00,$00

; "SCORPIONS", not read
Signature:
  DEFM "SCORPIONS"
