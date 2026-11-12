; --------------------------------------------------------------------------------------------------------------------
; launcher.asm: Running the chosen file: the BASIC's launch line, the bell, the fade, back to the loader
;
; The menu does not load the file itself: it writes a TR-DOS command into line 1 of its own BASIC program (src/basic,
; LaunchLine $5D3B): RUN "name" for a BASIC file, GO TO "name" CODE for a 192-sector CODE file, puts the caller's I,
; HL', IY and SP back, Frames = 0 and CHARS = $3C00 (the ROM font), plays the bell, fades the screen and returns, IM
; 1, to the loader (src/basic, Loader $5D80), which clears its memory and returns to BASIC. Line 10's RUN then starts
; line 1: RANDOMIZE USR 15619: REM : RUN "name" hands the command to TR-DOS.
; --------------------------------------------------------------------------------------------------------------------

  ORG $6A3F

; 5, 0, ENTER: run the file under the cursor (none with no files)
;
; C = "@" + CursorIndex: the letter of the file.
;
; Witness: L1 2 (c x2).
FireKey:
  PUSH AF
  LD A,(ColumnOneCount)
  LD B,A
  LD A,(ColumnTwoCount)
  OR B
  JP Z,KeyDone
  LD A,(CursorIndex)
  ADD A,$40
  LD C,A

; Run the page's file with letter C (A for the first): write the launch line,
; restore the caller's state, bell, fade, return to the loader
;
; Returns at once when C is past the page's last file. Walks the catalogue from
; PagePointer $B3C1 counting the listed files; each entry passed has its first
; byte set to 1 (deleted), so the walk's SkipDeleted steps over it, and the
; chosen one gets its byte back. LaunchToken $5D4C = $F7 (RUN) for a B file,
; $EC (GO TO) for a 192-sector C file; the name's 8 bytes after the quote;
; after the closing quote a space or $AF (CODE). Frames = 0; I, HL', IY and SP
; from Start; Chars = $3C00; PlayBell $6E48; ExitFade $6E72; IM 1; EI; RET to
; the loader's $5DB7 (after its CALL MenuStart at $5DB4).
;
; Witness: L1 3 (c x3).
RunLetter:
  LD A,(FileCount)
  ADD A,$40
  CP C
  RET C
  LD B,$40
  EXX
  LD HL,(PagePointer)
RunNextEntry:
  LD A,(HL)               ; the next catalogue entry
  CALL SkipDeleted
  LD E,$FF
  CALL IsBootFile
  LD D,$EC
  LD A,(HL)
  AND E
  CP $42
  JR Z,RunBasic
  CP $43
  PUSH AF
  LD BC,$0005
  ADD HL,BC
  POP AF
  JR NZ,RunSkipEntry
  LD A,(HL)
  CP $C0                  ; exactly 192 sectors ($C0): a 48K Magic snapshot.
                          ; Vadim's comment reads 'length >= C000'; the test is
                          ; CP $C0 with JR Z, equality only
  JR Z,RunCheckLetter
RunSkipEntry:
  INC HL
  INC HL
  INC HL
  JR RunNextEntry
RunBasic:
  LD BC,$0005             ; a BASIC file: RUN
  ADD HL,BC
  LD D,$F7
RunCheckLetter:
  LD BC,$000D             ; is this the file with the letter?
  AND A
  SBC HL,BC
  EXX
  INC B
  LD A,B
  CP C
  EXX
  LD A,(HL)
  LD (HL),$01
  JR NZ,RunNextEntry
  LD (HL),A
  PUSH DE
  PUSH HL
  LD HL,LaunchToken
  LD (HL),D
  INC HL
  INC HL
  EX DE,HL
  POP HL
  LD BC,$0008
  LDIR
  INC DE
  LD C,$20
  POP HL
  LD A,H
  CP $F7
  JR Z,RunWriteSuffix
  LD C,$AF
RunWriteSuffix:
  LD A,C                  ; the suffix: a space or CODE
  LD (DE),A
  LD HL,$0000
  LD (Frames),HL
  LD A,(SavedI)
  LD I,A
  LD HL,(SavedHLAlt)
  EXX
  LD IY,(SavedIY)
  LD SP,(SavedSP)
  LD HL,$3C00
  LD (Chars),HL
  CALL PlayBell
  CALL ExitFade
  IM 1
  EI
  RET
