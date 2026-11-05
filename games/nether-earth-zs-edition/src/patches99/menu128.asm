; --------------------------------------------------------------------------------------------------------------------
; menu128.asm: 128 K: the start-up menu's entries in the game, the menu copy from page 1 (the disk set), run at $C100
;
; The patches block's `$DA68-$DAE6` (127 bytes). Stage 3 copies it to `$C100-$C17E` when the machine has more than one
; page ($6340), over menu48 that it copied there first and over the game block's MenuPieceRoom (src/game99 mainmenu).
; The game calls it at Start ($A600: CALL $C100); the start-up menu (menu99, running at $D800 in page 0) calls the
; text entries and the LOAD MAP launcher.
;
; The menu itself lives in page 1 at `$D800-$E7FF` (stage 3 unpacks it there) because in page 0 that RAM belongs to
; the game (the radar layers, the robot tables, the map from `$DD00`). ShowMenu128 copies 4 K of it into page 0 each
; time, through the screen and a stub at `$6700`, and the menu runs with the caller's stack: its last RET (START)
; returns to $A603, behind the CALL at Start.
; --------------------------------------------------------------------------------------------------------------------

; The menu's jump table: $C100 the menu, $C103-$C10C the four texts, $C10F LOAD
; MAP
;
; The menu99 code calls these addresses; on one page menu48 holds the same
; table.
MenuTable128:
  JP ShowMenu128          ; Start's CALL $C100: the start-up menu

; MenuText1Jump
MenuText1Jump:
  JP PageText1            ; text 1 (NEdescri)

; MenuText2Jump
MenuText2Jump:
  JP PageText2            ; text 2 (NEadvice)

; MenuText3Jump
MenuText3Jump:
  JP PageText3            ; text 3 (NEgreets)

; MenuText4Jump
MenuText4Jump:
  JP PageText4            ; text 4 (NEabout)

; JP LoadMapLauncher: LOAD MAP (page 0 first)
MenuLoadMapJump:
  JP LoadMapLauncher

; Copy the start-up menu from page 1 into page 0 and run it, with the caller's
; stack
;
; The stack pointer goes into MenuStub's LD SP operand; MenuStub (40 bytes) is
; copied to `$6700` and the copy's own RET (ROM LDIR; RET at $33C3, with $6700
; pushed) runs it. The menu's code RETs at the end to the return address on
; that stack.
ShowMenu128:
  LD (MenuStub+$0021),SP  ; the caller's stack into MenuStub
  LD HL,MenuStub          ; MenuStub...
  LD DE,MenuStubRun             ; ... to $6700, below the game
  LD BC,$0028             ; 40 bytes
  PUSH DE                 ; the copy returns to it
  JP RomLdirRet                ; ROM: LDIR; RET

; Zero: never run
MenuGap128:
  DEFS $01

; Text 1 (NEdescri): DE, BC from stage 3 ($CF00 in page 3, $155D bytes), to the
; caller's HL
;
; Stage 3 writes the operands ($62F7, $62FD on 128 K). A = the text's number,
; used by the one-page reader only.
PageText1:
  LD DE,$0000             ; the text in page 3 (stage 3: $CF00)
  LD BC,$0000             ; its length (stage 3: $155D)
  LD A,$01
  JP TextEntry

; Text 2 (NEadvice): stage 3's operands $E700 in page 3, $15C4 bytes
;
; Used by the routine at MenuText2Jump.
PageText2:
  LD DE,$0000             ; the text in page 3 (stage 3: $E700)
  LD BC,$0000             ; its length (stage 3: $15C4)
  LD A,$02
  JP TextEntry

; Text 3 (NEgreets): stage 3's operands $E500 in page 3, $0139 bytes
;
; Used by the routine at MenuText3Jump.
PageText3:
  LD DE,$0000             ; the text in page 3 (stage 3: $E500)
  LD BC,$0000             ; its length (stage 3: $0139)
  LD A,$03
  JP TextEntry

; Text 4 (NEabout): stage 3's operands $C000 in page 3, $0EB3 bytes
;
; Used by the routine at MenuText4Jump.
PageText4:
  LD DE,$0000             ; the text in page 3 (stage 3: $C000)
  LD BC,$0000             ; its length (stage 3: $0EB3)
  LD A,$04
  JP TextEntry

; LOAD MAP: page 0 in, then (by SetPage's RET) LoadMap at $C1FD
;
; Used by the routine at MenuLoadMapJump.
LoadMapLauncher:
  LD HL,LoadMap             ; the return into LoadMap
  PUSH HL
  XOR A                   ; page 0
  JP SetPage

; Code copied to $6700 and run there (bytes here: the copy reads them): page
; 1's $D800-$E7FF into page 0 through the screen, then RET into the menu
;
; Runs at `$6700` with the stack at `$6780` (below the game block, above the
; stub): page 1 in, 4 K from `$D800` to the screen `$4000-$4FFF` (its pixels:
; the picture on the screen is lost, the menu redraws it), page 0, the 4 K back
; to `$D800`, then the caller's stack (the operand at $C179, written by
; ShowMenu128) with `$D800` pushed and the ROM's LDIR; RET: the menu starts,
; and its last RET goes where ShowMenu128's caller returns. Only absolute
; addresses, so it runs at `$6700` as it is.
MenuStub:
  DEFB $31,$80,$67        ; a stack of its own
  DEFB $3E,$01,$CD,$8A,$A5 ; page 1
  DEFB $21,$00,$D8        ; the menu in page 1...
  DEFB $11,$00,$40        ; ... to the screen...
  DEFB $01,$00,$10,$ED,$B0 ; ... 4 K
  DEFB $AF,$CD,$8A,$A5    ; page 0
  DEFB $21,$00,$40        ; from the screen...
  DEFB $11,$00,$D8        ; ... into page 0
  DEFB $01,$00,$10        ; 4 K
  DEFB $31,$00,$00        ; LD SP,nn: the caller's stack (the operand at $C179,
                          ; ShowMenu128 writes it)
  DEFB $D5                ; the menu's start for the copy's RET
  DEFB $C3,$C3,$33        ; ROM: LDIR; RET
