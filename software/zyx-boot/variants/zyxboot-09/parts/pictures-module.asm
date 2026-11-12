; --------------------------------------------------------------------------------------------------------------------
; pictures-module.asm: Two run-length packed screens, each with its own unpacker
;
; Each unpacker is position independent (it finds its own address through CALL RomRet) and unpacks the bytes that
; follow it onto the whole screen and its attributes ($1B00 bytes). The packed stream: a byte other than $9D is
; itself; $9D, a byte and a count is that byte count times.
; --------------------------------------------------------------------------------------------------------------------

; Unpack FirstPicture onto Screen $4000-$5AFF
ShowFirstPicture:
  DI
  CALL RomRet
  DEC SP
  DEC SP
  POP HL
  LD DE,$0031
  ADD HL,DE
  PUSH HL
  EXX
  POP DE
  LD B,$00
  EXX
  LD HL,Screen
  LD BC,$1B00
UnpackFirst:
  EXX                     ; the next output byte: the run in progress, or the
                          ; next packed byte ($9D: a new run)
  LD A,B
  CP $00
  JR NZ,l_C379
  LD A,(DE)
  CP $9D
  INC DE
  JR NZ,l_C37B
  LD A,(DE)
  LD C,A
  INC DE
  LD A,(DE)
  LD B,A
  INC DE
l_C379:
  DEC B
  LD A,C
l_C37B:
  EXX
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,UnpackFirst
  EI
  RET

; The first picture, packed ($9D runs; tools/res_screens.py packs it from its
; PNG)
FirstPicture:
  INCBIN "res/graphics/rle-picture-1.bin",$0000,2544

; Unpack SecondPicture onto Screen $4000-$5AFF (the same code as
; ShowFirstPicture)
ShowSecondPicture:
  DI
  CALL RomRet
  DEC SP
  DEC SP
  POP HL
  LD DE,$0031
  ADD HL,DE
  PUSH HL
  EXX
  POP DE
  LD B,$00
  EXX
  LD HL,Screen
  LD BC,$1B00
UnpackSecond:
  EXX                     ; the next output byte
  LD A,B
  CP $00
  JR NZ,l_CD9E
  LD A,(DE)
  CP $9D
  INC DE
  JR NZ,l_CDA0
  LD A,(DE)
  LD C,A
  INC DE
  LD A,(DE)
  LD B,A
  INC DE
l_CD9E:
  DEC B
  LD A,C
l_CDA0:
  EXX
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,UnpackSecond
  EI
  RET

; The second picture, packed
SecondPicture:
  INCBIN "res/graphics/rle-picture-2.bin",$0000,2481

; zeros to the 21st sector's end
PicturesEnd:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00
