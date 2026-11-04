; The game edition on the editor tape (data blocks 0-5): a snapshot of the original Nether Earth taken at its main
; menu, put on tape by a snapshot loader. docs/03-build-and-load.md 3.2-3.5.
;
; Assembled with sjasmplus from the case's build folder after Nether Earth's own image has been assembled there
; (game.bin, $5B00-$FCE8, from ../nether-earth/src/game/game.asm) and its loader N1 (loader.bin):
;
;   basic.bin   the BASIC "NetherEart" (146 bytes, LINE 20): line 10 holds the loader's code in a REM
;   block2.bin  6916 bytes at $4000: the menu screen, the trampoline, the register frame, then 4 bytes at $5B00
;   block3.bin  20000 bytes at $61A8 (25000)
;   block4.bin  20536 bytes at $AFC8 (45000) to $FFFF
;   block5.bin  1704 bytes at $5B00, loaded last over the BASIC that loads it
;
; The memory image is Nether Earth's own, byte for byte, plus the state the machine had at the menu: the menu tune's
; self-modified operands, the variables the start-up and the menu wrote, the IM 2 table, N1's code above the game
; block, and what the ROM and N1 left on their stacks. Each such byte is set below with its reason.

  DEVICE ZXSPECTRUM48

; ---------------------------------------------------------------------------------------------------------------
; The BASIC, two lines. Line 20 runs first (the autostart): CLEAR 24999 puts RAMTOP below block 3, and
; RANDOMIZE USR (PEEK 23635 + 256 * PEEK 23636 + 5) enters the code of line 10: PROG + 5, the byte after the
; line number, the length and the REM token.

T_REM       EQU $EA
T_CLEAR     EQU $FD
T_BORDER    EQU $E7
T_PAPER     EQU $DA
T_INK       EQU $D9
T_CLS       EQU $FB
T_RANDOMIZE EQU $F9
T_USR       EQU $C0
T_PEEK      EQU $BE
T_VAL       EQU $B0

LD_BYTES    EQU $0556         ; ROM: load a block, IX start, DE length, A flag, carry set
SNAP_SP     EQU $5B00         ; block 2's last 4 bytes: the SP of the register frame and the resume address
SNAP_RESUME EQU $5B02

  ORG $5CCB
Basic:
  DB 0, 10                      ; line 10
  DW Line10End - Line10Text
Line10Text:
  DB T_REM
Loader:                         ; $5CD0, PROG + 5
  DI
  LD IX,$4000                   ; block 2: the screen and 4 bytes past it
  LD DE,6916
  LD A,$FF
  SCF
  CALL LD_BYTES
  LD IX,25000                   ; block 3: $61A8-$AFC7, just above RAMTOP
  LD DE,20000
  LD A,$FF
  SCF
  CALL LD_BYTES
  LD IX,45000                   ; block 4: $AFC8-$FFFF
  LD DE,20536
  LD A,$FF
  SCF
  CALL LD_BYTES
  LD SP,(SNAP_SP)               ; SP = $410E: the register frame in the screen
  POP AF
  LD I,A                        ; I = $FE, the game's IM 2 page
  POP DE                        ; the alternate set ...
  POP HL
  POP BC
  EXX                           ; ... DE', HL', BC'
  POP IY                        ; IY = $5C3A
  LD HL,(SNAP_RESUME)           ; $4002, the trampoline
  LD IX,$5B00                   ; block 5: $5B00-$61A7, over the printer buffer, the system variables and this
  LD DE,1704                    ; BASIC; the code runs on in the ROM: LD-BYTES returns into its SA/LD-RET, and
                                ; that returns to the trampoline pushed here
  LD A,$FF
  SCF
  PUSH HL
  JP LD_BYTES
  DB $0D
Line10End:


  DB 0, 20                      ; line 20
  DW Line20End - Line20Text
Line20Text:
  DB T_CLEAR, T_VAL, '"24999":'
  DB T_BORDER, T_VAL, '"0":', T_PAPER, T_VAL, '"0":', T_INK, T_VAL, '"0":', T_CLS, ':'
  DB T_RANDOMIZE, T_USR, '(', T_PEEK, T_VAL, '"23635"+', T_VAL, '"256"*', T_PEEK, T_VAL, '"23636"+'
  DB T_VAL, '"5")', $0D
Line20End:
  SAVEBIN "basic.bin",Basic,$-Basic

; ---------------------------------------------------------------------------------------------------------------
; The memory image

  ORG $4000
  INCBIN "../res/edition/menu-screen.scr"   ; the menu as it was on the screen, the bytes below zeroed in the file

; The trampoline, in the top pixel line (attributes black): entered by LD-BYTES' return with SP = $4118
  ORG $4002
Trampoline:
  POP AF
  POP IX                        ; IX = $D92B
  EX AF,AF'                     ; AF' = $0021
  POP HL
  LD SP,HL                      ; SP = $FFF0: the game's stack, 10 bytes below the PC the snapshot pushed
  POP DE
  POP BC
  POP HL
  POP AF
  LD R,A                        ; R = $B3
  POP AF
  IM 2
  EI
  RET                           ; PC = $C4C3 (BassIdlePad, the menu tune's tone loop), SP = $FFFC

; The register frame the BASIC and the trampoline pop, in pixel line 1
  ORG $410E
RegisterFrame:
  DW $FEAD                      ; AF: A = $FE goes to I
  DW $C78B, $C6BF, $0F0F        ; DE', HL', BC'
  DW $5C3A                      ; IY
  DW $0021                      ; AF', popped by the trampoline first
  DW $D92B                      ; IX
  DW $FFF0                      ; SP for the last pops

; Nether Earth's image, $5B00-$FCE8, assembled from its source
  ORG $5B00
  INCBIN "game.bin"

; The menu tune's operands, written by its note readers (LeadNextEvent $C540, $C547 ...): the notes playing
  ORG $C4D0 : DB $37            ; the lead's period
  ORG $C4D6 : DB $0D            ; its pulse width, period / 4
  ORG $C4ED : DB $7C            ; the bass's period
  ORG $C4EF : DB $00            ; the bass voice off
  ORG $C4F3 : DB $1F            ; its pulse width

; N1, Nether Earth's loader at $FCDA: the game block's last 15 bytes covered $FCDA-$FCE8, the rest stayed
  ORG $FCE9
  INCBIN "loader.bin",15

; The variables the start-up and the menu wrote over N1's code
  ORG $FD00 : DB $39,$30,$39,$30   ; RandomSeed, as Start seeds it
  ORG $FD04 : DW $50DA             ; PrintAddr
  ORG $FD08 : DW $FFFC             ; SavedSP: the menu tune's SP
  ORG $FD13 : DB $46               ; PrintAttr
  ORG $FD14 : DW $5ADA             ; PrintAttrAddr
  ORG $FD16 : DB 0, 0              ; PrintHeight, PrintWidth
  ORG $FD31 : DB 8, $16, 5         ; PrintColumn, PrintRow, TitleColourPhase
  ORG $FD54 : DW $C67D, $C704      ; BassReturnPos, LeadReturnPos

; The IM 2 table Start builds, its JP and Handler = MenuInterrupt
  ORG $FDFD
  DB $C3
  DW $C4FD
  DS 257,$FD                    ; $FE00-$FF00

; $FF01-$FFFF: no game state yet (Buildings is built by NewGameSetup); what power-on, BASIC and N1 left
  ORG $FF01
  DS $FF18-$FF01, 0
  DW $0DF3,$0BCE,$50E3,$0BCE,$50E4,$171D,$0ADC,$0BCE   ; $FF18: the ROM's machine stack under the power-on
  DW $50E7,$171A,$0ADC,$18D7,$0038,$0038,$190D,$02DB   ; RAMTOP $FF57 (ROM return addresses)
  DW $02DB,$004D,$52C9,$0037,$52C8,$020C,$0E5C,$57C0
  DW $0E71,$0DF3,$1721,$1EC6,$FFFF,$1B76,$1303         ; ... STMT-RET $1B76, MAIN-4 $1303
  DB $00,$3E                    ; $FF56: the GO SUB stack's end marker $3E at the power-on RAMTOP
UDG:                            ; $FF58: the user graphics A-U as the ROM copies them at power-on ($3E08 on)
  INCBIN "48.rom",$3E08,$FFDA-$FF58
  DW $FD6C,$FD54               ; $FFDA: N1's stack (SP $FFE0): returns into its edge loop
  DW $A600                      ; $FFDE: N1's PUSH of the game's entry, Start
  DB $B7,$2D,$4E,$5E,$49,$5E,$9F,$0C,$9F,$0C,$50,$31,$CC,$00,$FE,$01 ; $FFE0: older stack bytes (BASIC, ROM)
  DW $265F,$001F,$C665,$B3A4,$001A ; $FFF0: DE, BC, HL, R (A), AF: the snapshot loader's frame, popped last
  DW $C4C3                      ; $FFFA: the PC the snapshot pushed (BassIdlePad)
  DW $C1A1                      ; $FFFC: MenuMusic's return into MainMenu
  DW $A62D                      ; $FFFE: MainMenu's return into Start (NewGameSetup)

; The four blocks. Block 5 first, with the game's own $5B00-$5B03; then block 2's tail gets the two words the
; BASIC reads, SP and the resume address, which block 5 overwrites at the end of the load.
  SAVEBIN "block5.bin",$5B00,1704
  SAVEBIN "block3.bin",25000,20000
  SAVEBIN "block4.bin",45000,20536
  ORG $5B00
  DW RegisterFrame, Trampoline
  SAVEBIN "block2.bin",$4000,6916
