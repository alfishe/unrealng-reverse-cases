; --------------------------------------------------------------------------------------------------------------------
; script.asm: The loading screen's script engine: one item a step, characters printed with the loader's font
;
; The script is a byte stream at ScriptPtr: SerialText $B835 first (from LoadRest), then the fifth load at $998E (from
; LoadFiles, which also sets ScriptWait = 230, so the script starts about 11 s after its load began). A byte of 32 or
; more is a character, printed by PrintGlyph at the print position (PrintRow, PrintColumn) in PrintAttr, after which
; the position moves right and wraps inside the window (WindowLeft-WindowRight, WindowTop-WindowBottom, wrapping to
; the top). A byte below 32 is a control code (ControlCode, the module control); $04 ends the script.
;
; The engine runs only on the hook: ScriptStep does up to 6 items a hook, one pulse pair each, so it never waits for
; the load. The script is read while it loads: the closest it comes in c1 is 260 bytes behind the byte being loaded
; ($A70D against IX = $A811, work/ann/04-loader/reader.py); its pauses ($03) keep it so.
;
; The script's format, every code with its arguments, and the decoded script (work/ann/04-loader/script.py):
; work/ann/04-loader.md.
; --------------------------------------------------------------------------------------------------------------------

; One script item (with EXX: the loader's registers kept), then one pulse pair;
; up to 6 a hook
;
; Entered by HookWork when ScriptWait runs out, and from its own end while the
; marker bit in L has not reached bit 7.
;
; 1. LoadFlags bit 3 (a picture is being drawn): PictureCell, one cell.
;
; 2. Else the byte at ScriptPtr (ScriptPtr + 1): `$04` ends the script
; (LoadFlags bit 1 cleared, then HookPad); below 32 ControlCode; else PrintChar
; `$B7B8`: PrintGlyph at PrintRow + PrintColumn in PrintAttr, then CursorRight
; `$B7CA` (PrintColumn + 1; past WindowRight back to WindowLeft and NextRow
; `$B7D8`: PrintRow + 32, past WindowBottom back to WindowTop).
;
; 3. ScriptPair `$B7F0`: EXX back, one long pair (EdgeNoDelay, EdgeWait), `SLA
; L`: the marker not yet in bit 7, another item. Else one short pair
; (EdgePair), L = `$FF`, B = `$B2`, `JP $B752` (ByteHook: the hook's end, as at
; HookPad).
;
; c1 (work/ann/04-loader/reader.py): 8228 items in 1426 hooks. The two `$04`
; ends: SerialText's at 1.99 s and the script's (`$B325`) at 273.3 s, 17 s
; before the last load.
;
; Witness: L1 8228 (c1).
ScriptStep:
  EXX
  LD HL,(ScriptPtr)
  LD A,(LoadFlags)
  BIT 3,A
  JR NZ,ScriptPicture
  LD A,(HL)               ; the next byte; $04 ends the script
  INC HL
  LD (ScriptPtr),HL
  CP $04
  JR NZ,ScriptCode
ScriptEnd:
  LD HL,LoadFlags             ; the end: the script off, the hook pads
  RES 1,(HL)
  EXX
  JR HookPad
ScriptPicture:
  CALL PictureCell        ; a picture's next cell
  JR ScriptPair
ScriptCode:
  CP $20                  ; below 32: a control code
  JR NC,PrintChar
  CALL ControlCode
  JR ScriptPair
; This entry point is used by the routine at ControlCode.
PrintChar:
  LD HL,(PrintRow)           ; print A at the position (ControlCode's fills enter
                          ; here too)
  LD DE,(PrintColumn)
  LD D,$00
  ADD HL,DE
  EX DE,HL
  LD BC,(AttrPair)
  CALL PrintGlyph
; This entry point is used by the routine at CodeRight.
CursorRight:
  LD HL,PrintColumn             ; the column + 1, wrapping to the window's left and
                          ; the next row ($09 enters here)
  INC (HL)
  LD A,(WindowRight)
  CP (HL)
  JR NC,ScriptPair
  LD A,(WindowLeft)
  LD (HL),A
; This entry point is used by the routine at CodeDown.
NextRow:
  LD HL,(PrintRow)           ; the row + 32, wrapping to the window's top ($0A and
                          ; $0D enter here)
  LD BC,$0020
  ADD HL,BC
  LD B,H
  LD C,L
  LD HL,(WindowBottom)
  SBC HL,BC
  JR NC,SetRow
  LD BC,(WindowTop)
SetRow:
  LD (PrintRow),BC
ScriptPair:
  EXX                     ; one long pair a step; the marker in bit 7 ends the
                          ; hook
  LD B,$B0
  CALL EdgeNoDelay
  JR NC,HookFail
  CALL EdgeWait
  JR NC,HookFail
  SLA L
  BIT 7,L
  JR Z,ScriptStep
ScriptLast:
  LD B,$B0                ; the hook's last pair, a short one
  CALL EdgePair
  JP NC,HookFail
  LD L,$FF
  LD B,$B2
  JP ByteHook

; Print character A at the attribute address DE in attribute B (8 bytes from
; FontPtr + 8 x (A - 32))
;
; The glyph is FontPtr + 8 x A - 256 (character 32 is FontPtr's first). The
; attribute B goes to (DE), then DE becomes the cell's first pixel row (D x 8
; AND `$78`: `$58` to `$40`, `$59` to `$48`, `$5A` to `$50`) and 8 bytes are
; copied down the cell. C is not used.
;
; Called by ScriptStep (characters, from its registers in the other set) and
; CountdownTick (the digits).
;
; Witness: L1 8435 (c1).
PrintGlyph:
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,(FontPtr)
  ADD A,L
  LD L,A
  LD A,(FontPtr+1)
  DEC A
  ADC A,H
  LD H,A
  LD A,B                  ; the attribute, then the cell's pixel address
  LD (DE),A
  LD A,D
  ADD A,A
  ADD A,A
  ADD A,A
  AND $78
  LD D,A
  LD B,$08
PrintGlyphRow:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  DJNZ PrintGlyphRow
  RET

; The first script: "      DEFLEKTOR SERIAL NO-VX3240" and $04, printed on row
; 22
;
; ScriptPtr's first value (the first stage's variables), run from LoadRest,
; while the second and third pieces load: 32 characters at PrintRow `$5AC0`
; (row 22) from column 0 in PrintAttr 7, then the end `$04`. The fifth load's
; script later prints "SECONDS TO LOAD DEFLEKTOR" over its right part (AT 22,5)
; and the countdown takes columns 1-3.
SerialText:
  DEFM "      DEFLEKTOR SERIAL NO-VX3240",$04
