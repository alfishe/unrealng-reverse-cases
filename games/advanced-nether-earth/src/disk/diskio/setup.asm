; --------------------------------------------------------------------------------------------------------------------
; setup.asm: the set-up, run in bank 4 at $C000
;
; The game's GameSave ($6905) and GameLoad ($A56A) page bank 4 in at $C000, set FLAGS, LAST_K and CAPS LOCK as the
; ROM's key reading wants, put the module's entry in IX ($4000 load, $4033 save) and jump to $C000. The set-up makes
; the 48 K state TR-DOS expects: a black, cleared screen, the stack at $5000, IM 1 with the ROM's I, IY and HL', a
; silent AY, cyan text rows 16-21 and yellow rows 22-23; then it copies the module ($C065-$CD2B) to $4000 and jumps to
; IX.
;
; The module runs in the screen's first two thirds (just cleared); its texts print in the last third, which its code
; and stack never reach.
; --------------------------------------------------------------------------------------------------------------------

; Set up the 48 K state TR-DOS needs, copy the module to $4000 and run it at IX
;
; In: IX = the module's entry ($4000 load, $4033 save), bank 4 at $C000
; (GameSave, GameLoad). The screen ($4000-$5AFF) is cleared with an LDDR down
; from $5AFF, the border black; the stack goes to $5000, in the screen's second
; third, below the rows the module prints on; SetRomState; the 3271 bytes of
; the module go to $4000 and the CPU jumps to IX. Never returns: the module
; leaves through the game's SaveReturn, LoadReturn or Restart.
Setup:
  DI
  XOR A                   ; A = 0
  OUT ($FE),A             ; border black
  LD HL,$5AFF             ; the screen's last attribute byte
  LD D,H
  LD E,L
  DEC E                   ; DE = HL - 1
  LD (HL),A               ; that byte 0 ...
  LD BC,$1AFF             ; ... and the 6911 below it
  LDDR                    ; $4000-$5AFF all 0
  LD SP,$5000             ; the stack in the screen, below the text rows 16-23
                          ; ($5000)
  CALL SetRomState        ; IM 1, the ROM's registers, the AY quiet, the
                          ; colours
  LD HL,ModuleImage             ; the module from bank 4 ...
  LD DE,LoadEntry             ; ... to $4000 (where it was assembled)
  LD BC,$0CC7             ; 3271 bytes: $C065-$CD2B
  LDIR
  JP (IX)                 ; IX: $4000 load, $4033 save

; The ROM's interrupt state and registers, a silent AY, the text colours, the
; TR-DOS hook
;
; Interrupts off; I = $3F (the ROM's), IM 1, IY = $5C3A and HL' = $2758 as the
; 48 K ROM's IM 1 handler and TR-DOS expect. One EI / HALT so the IM 1 handler
; runs once (the keyboard and FRAMES as the ROM keeps them), then interrupts
; off again. AY registers 0-14 are written 0 (silence: the game's tune stops).
; Attributes: rows 16-21 (192 bytes) 5, cyan on black, for the texts; rows
; 22-23 (64 bytes) 6, yellow, for the status line. TrdosHook ($5CC2) gets $F1
; $C9: POP AF / RET.
SetRomState:
  DI
  LD A,$3F
  LD I,A
  IM 1
  LD IY,RomIY
  EXX
  LD HL,RomHLx             ; HL' = the ROM's
  EXX
  XOR A                   ; A = 0: the first AY register
  EI                      ; one frame with the ROM's IM 1 handler (key scan,
                          ; FRAMES)
  HALT
  DI
SilenceAy:
  LD BC,$FFFD             ; the AY register port
  OUT (C),A               ; select register A
  PUSH AF
  XOR A                   ; the value 0
  LD B,$BF                ; the AY data port ($BFFD)
  OUT (C),A               ; register A = 0
  POP AF
  INC A                   ; the next register
  CP $0F                  ; registers 0-14
  JR NZ,SilenceAy
  LD HL,$5A00             ; row 16's attributes
  LD D,H
  LD E,L
  INC E
  LD (HL),$05             ; cyan ink on black
  LD BC,$00BF             ; 191 more: rows 16-21
  LDIR
  LD L,E                  ; rows 22-23 ...
  INC E
  LD (HL),$06             ; ... yellow on black
  LD BC,$003F             ; 63 more
  LDIR
  LD HL,$C9F1             ; the bytes $F1 $C9: POP AF / RET
  LD (TrdosHook),HL           ; at TrdosHook
  RET
