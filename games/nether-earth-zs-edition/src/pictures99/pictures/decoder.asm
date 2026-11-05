; --------------------------------------------------------------------------------------------------------------------
; decoder.asm: the RLE screen decoder
;
; DecodeScreen finds its own address (it calls a RET in the ROM and reads the return address back from below the
; stack), so it runs wherever it is loaded: the packed screen starts $6F bytes after the CALL's return address, i.e.
; right after the decoder. Its two LD HL operands are the targets of the pixels and of the attributes; stage 2 patches
; them to $8A87 and $A287 before the call, so the picture lands in a buffer in the screen's layout and is shown by
; stage 2's RollInPicture.
;
; The stream: a byte other than $9A is itself; $9A V N is V N times. The order: column by column (32), each column's
; 192 pixel lines from the top (the third, the character row, the line: INC H, +32, +$800), then the 768 attributes in
; order. The run counter is kept in the alternate B across the pixels and the attributes.
; --------------------------------------------------------------------------------------------------------------------

; Decode the RLE screen that follows the routine into the targets at
; DecodePixels+1 and DecodeAttrs+1
;
; No inputs: the stream is found from the routine's own address (CALL RomRet,
; then the return address read back from below SP, + $6F = PackedScreen). The
; 6144 pixel bytes are written column by column, each column top to bottom, at
; the target as a screen layout; the 768 attributes in order. DI on entry, EI
; on return. Outputs: the screen (or the patched buffer); A, BC, DE, HL and the
; alternate BC, DE changed. Ran once (r99 frames 464-472, called from stage 2's
; IntroMain at $61FE).
DecodeScreen:
  DI
  CALL RomRet              ; the return address ($7D8B) is left below SP ...
DecodeReturn:
  DEC SP                  ; ... and taken back
  DEC SP
  POP HL
  LD DE,PackedScreen-DecodeReturn ; + $6F: the packed screen right after this
                                  ; routine
  ADD HL,DE
  PUSH HL
  EXX                     ; DE' = the stream, B' = 0: no run going
  POP DE
  LD B,$00
  EXX
DecodePixels:
  LD HL,Screen             ; DecodePixels+1: the pixels' target ($4000; stage 2
                          ; writes $8A87 here)
  LD D,$20                ; 32 columns
DecodeColumn:
  PUSH HL
  LD E,$03                ; 3 thirds
DecodeThird:
  PUSH DE
  PUSH HL
  LD C,$08                ; 8 character rows
DecodeRow:
  PUSH HL
  LD B,$08                ; 8 lines
DecodeLine:
  EXX                     ; the next byte of the stream into (HL)
  LD A,B                  ; a run going (B' > 0): its value again
  CP $00
  JR NZ,DecodeRunByte
  LD A,(DE)               ; a new byte: itself, or $9A V N
  CP $9A
  INC DE
  JR NZ,DecodeStore
  LD A,(DE)               ; $9A: C' = the value, B' = the count
  LD C,A
  INC DE
  LD A,(DE)
  LD B,A
  INC DE
DecodeRunByte:
  DEC B
  LD A,C
DecodeStore:
  EXX
  LD (HL),A
  INC H                   ; the next pixel line
  DJNZ DecodeLine
  POP HL
  LD DE,$0020             ; the next character row
  ADD HL,DE
  DEC C
  JR NZ,DecodeRow
  POP HL
  LD DE,$0800             ; the next third
  ADD HL,DE
  POP DE
  DEC E
  JR NZ,DecodeThird
  POP HL
  INC HL                  ; the next column
  DEC D
  JR NZ,DecodeColumn
DecodeAttrs:
  LD HL,Attrs             ; DecodeAttrs+1: the attributes' target ($5800; stage
                          ; 2 writes $A287 here)
  LD BC,$0300             ; 768 attributes in order, the same stream
DecodeAttr:
  EXX
  LD A,B
  CP $00
  JR NZ,DecodeAttrRun
  LD A,(DE)
  CP $9A
  INC DE
  JR NZ,DecodeAttrStore
  LD A,(DE)
  LD C,A
  INC DE
  LD A,(DE)
  LD B,A
  INC DE
DecodeAttrRun:
  DEC B
  LD A,C
DecodeAttrStore:
  EXX
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,DecodeAttr
  EI
  RET
