; --------------------------------------------------------------------------------------------------------------------
; menu48.asm: One page / tape: the start-up menu's entries in the game (the tape set), run at $C100
;
; The patches block's `$DB15-$DB6F` (91 bytes). Stage 3 copies it to `$C100-$C15A` on every path ($6329); on 128 K
; menu128 then replaces it. Never run in a recording: the code is read from its bytes.
;
; On one page the menu has no page to live in: at each call of $C100 its packed file is read again (from disk or tape)
; to `$E800` and unpacked to `$D800`. The operands are stage 3's: on the one-page disk path ($627D-$62B3) the menu
; file's position (the TR-DOS system variable `$5CF4` after the patches block) and 10 sectors, then the four texts
; that follow the game file by position: 4 NEabout 15 sectors, 1 NEdescri 22, 3 NEgreets 2, 2 NEadvice 22. Stage 3
; writes text 2's count to $C133, the C byte, not to $C134, the B byte: B stays 0 and DiskRead would read 256 sectors.
; On the tape path ($63A8-$63BD) the lengths of texts 1-3 ($155D, $15C4, $0139) go to their BC; text 4's $0EB3 goes to
; $C146, the DE that TapeRead does not use, so its BC stays 0; the menu file's BC ($C119) is not written. Not run:
; read from the code.
; --------------------------------------------------------------------------------------------------------------------

; The menu's jump table: $C100 the menu, $C103-$C10C the four texts, $C10F LOAD
; MAP
MenuTable48:
  JP ShowMenu48           ; Start's CALL $C100: read and unpack the start-up
                          ; menu

; JP LoadText1: text 1 (NEdescri)
LoadText1Jump:
  JP LoadText1

; JP LoadText2: text 2 (NEadvice)
LoadText2Jump:
  JP LoadText2

; JP LoadText3: text 3 (NEgreets)
LoadText3Jump:
  JP LoadText3

; JP LoadText4: text 4 (NEabout)
LoadText4Jump:
  JP LoadText4

; JP LoadMap: LOAD MAP at once (nothing to page)
LoadMapJump48:
  JP LoadMap

; Read the menu's packed file to $E800, unpack it to $D800 and run it
;
; The file's position and length are stage 3's operands; A (the tape flag, the
; digit shown) is what Start's caller left. The menu's last RET (START) goes to
; $A603 behind the CALL at Start; LOAD MAP from tape ends with JP $D800, into
; the menu without a new read.
ShowMenu48:
  LD HL,MenuFile             ; the packed menu's place
  LD DE,$0000             ; its position on disk (stage 3: the TR-DOS position
                          ; after the patches block)
  LD BC,$0000             ; its length (stage 3: 10 sectors on disk; 0 on tape)
  CALL TextEntry              ; read
  CALL MenuFile              ; unpack it to $D800
  JP MenuCode                ; the start-up menu

; Text 1 (NEdescri): DE, BC from stage 3 (disk: the position, 22 sectors; tape:
; $155D bytes)
;
; Used by the routine at LoadText1Jump.
LoadText1:
  LD DE,$0000             ; the position (stage 3)
  LD BC,$0000             ; the length (stage 3)
  LD A,$01                ; file 1
  JP TextEntry

; Text 2 (NEadvice): disk 22 sectors, written into C (B stays 0); tape $15C4
; bytes
;
; Used by the routine at LoadText2Jump.
LoadText2:
  LD DE,$0000             ; the position (stage 3)
  LD BC,$0000             ; the length (stage 3: C = 22 on disk, B 0)
  LD A,$02                ; file 2
  JP TextEntry

; Text 3 (NEgreets): disk 2 sectors; tape $0139 bytes
;
; Used by the routine at LoadText3Jump.
LoadText3:
  LD DE,$0000             ; the position (stage 3)
  LD BC,$0000             ; the length (stage 3)
  LD A,$03                ; file 3
  JP TextEntry

; Text 4 (NEabout): disk 15 sectors; tape: $0EB3 lands in DE, the length stays
; 0
;
; Used by the routine at LoadText4Jump.
LoadText4:
  LD DE,$0000             ; the position (stage 3; the tape length $0EB3 lands
                          ; here)
  LD BC,$0000             ; the length (stage 3: 15 sectors on disk; nothing on
                          ; tape)
  LD A,$04                ; file 4
  JP TextEntry

; Clear the screen, interrupts off, I = $3F, IM 0
QuietScreen:
  CALL ClearScreen              ; a blank screen
  DI                      ; the play interrupt off
  LD A,$3F                ; I points at the ROM
  LD I,A
  IM 0                    ; IM 0
  RET
