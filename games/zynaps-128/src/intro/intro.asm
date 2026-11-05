; --------------------------------------------------------------------------------------------------------------------
; intro.asm: the intro: the engine to page 4, the tune, three pictures, the options
;
; Block 1's code. The loader calls IntroStart after the unpack and comes back when the Hewson picture is up; the
; picture stays on the screen while block 2 loads. On a 48K (Is128 = 0) the copies to page 4 and to $8000 and the tune
; are skipped; the pictures and the options are the same.
;
; Each picture appears through ShowPicture: the pixels at once under black attributes, then one attribute row a frame
; in a random order (Random), 24 frames. The options screen runs two colour bars (CycleColours) while it waits: the
; top eight rows and rows 8-16 from the bottom up, taking their colours from the yellow / white table CycleTable.
; --------------------------------------------------------------------------------------------------------------------

; the options off, the engine to page 4, the title, the tune, the options
; screen, the Hewson picture
;
; Called by the loader (LoaderBody) after block 1's unpack; returns to it with
; the Hewson picture shown (48K: RET Z; 128K: through StarkosStop's RET after
; IM 1). On 128K: page 4 in, EngineRun ($3BB bytes) and EngineDataRun ($2028)
; copied from the block, page 0 back; after the title, the player and its song
; ($10C5 bytes) to $8000, the IM 2 table at $FC00 (I = $FC, every vector $FDFD,
; JP IntroInterrupt there) and StarkosInit with the song: the tune runs from
; the title on.
;
; The options screen: keys 1 and 2 toggle InfLives and KMouse (ToggleOption,
; the option's attributes inverted), 0 goes on. The keys are read only when no
; key was down the frame before (OptionsRelease).
IntroStart:
  LD HL,$0000             ; both options off (they lie over the loader's first
                          ; two bytes)
  LD (InfLives),HL
  LD A,(Is128)            ; 48K: no engine, no tune
  OR A
  JR Z,ShowTitle
  LD A,PAGE4              ; page 4: the engine and its data copied there
  LD BC,PORT_7FFD
  OUT (C),A
  LD HL,EngineImage
  LD DE,EngineRun
  LD BC,$03BB
  LDIR
  LD DE,EngineDataRun
  LD BC,$2028
  LDIR
  LD A,PAGE0              ; page 0 back
  LD BC,PORT_7FFD
  OUT (C),A
ShowTitle:
  LD HL,TitlePicture      ; the title picture (RVS / M. Stawicki)
  CALL ShowPicture
  LD A,(Is128)            ; 48K: no tune
  OR A
  JR Z,TitleWait
  LD HL,StarkosImage      ; the STarKos player and its song to $8000
  LD DE,StarkosInit
  LD BC,$10C5
  LDIR
  DI                      ; the IM 2 table $FC00-$FDFD filled with $FD, JP
                          ; IntroInterrupt at $FDFD, I = $FC
  LD HL,Im2Table
  LD DE,Im2Table+1
  LD BC,$01FD
  LD A,H
  LD (HL),C
  LDIR
  LD (HL),$C3
  LD HL,IntroInterrupt
  LD (Im2Jump+1),HL
  LD I,A
  IM 2
  LD DE,Sk10Song          ; the tune starts: StarkosInit with DE = the SK10
                          ; song
  CALL StarkosInit
  EI
TitleWait:
  HALT                    ; a frame; until a key
  XOR A
  IN A,($FE)
  CPL
  AND $1F
  JR Z,TitleWait
  LD HL,OptionsPicture    ; the options screen
  CALL ShowPicture
  LD IXL,$00              ; IXL, the colour bars' step, from 0
; This entry point is used by the routine at ToggleOption.
OptionsRelease:
  HALT                    ; a frame of colour bars; until no key is down
  CALL CycleColours
  XOR A
  IN A,($FE)
  CPL
  AND $1F
  JR NZ,OptionsRelease
OptionsKeys:
  HALT                    ; a frame of colour bars, then 1, 2 or 0
  CALL CycleColours
  LD BC,$F7FE             ; the row 1-5
  IN A,(C)
  LD IXH,$09              ; key 1: INF.LIVES, its 9 attributes from $5AEB
  LD HL,OptionLives
  LD DE,InfLives
  RRA
  JR NC,ToggleOption
  LD IXH,$07              ; key 2: K-MOUSE, its 7 attributes from $5AF8
  LD L,$F8
  INC DE
  RRA
  JR NC,ToggleOption
  LD B,$EF                ; key 0 (the row 6-0): go on; else the next frame
  IN A,(C)
  RRA
  JR C,OptionsKeys
ShowHewson:
  LD HL,HewsonPicture     ; the Hewson picture
  CALL ShowPicture
  LD A,(Is128)            ; 48K: back to the loader
  OR A
  RET Z
  DI                      ; 128K: IM 1 (I = $3F as the ROM wants), the tune
                          ; stopped; the player's RET returns to the loader
  LD A,$3F
  LD I,A
  IM 1
  JP StarkosStop

; XOR $2D over IXH attributes from HL: an option shown on / off
;
; Input: HL = the first attribute, IXH = the count. XOR $2D swaps the text's
; colours between the off and the on look (applied twice it gives them back).
; Output: HL past them, B = 0.
InvertAttrs:
  LD B,IXH
InvertAttr:
  LD A,(HL)
  XOR $2D
  LD (HL),A
  INC HL
  DJNZ InvertAttr
  RET

; an option key: its attributes inverted, its flag (DE) XOR 1, back to
; OptionsRelease
;
; Input: HL, IXH = the option's attributes (InvertAttrs), DE = its flag
; (InfLives or KMouse).
ToggleOption:
  CALL InvertAttrs
  LD A,(DE)
  XOR $01
  LD (DE),A
  JR OptionsRelease

; the intro's IM 2 handler: every register saved, one frame of the tune
; (StarkosPlay), EI
;
; Reached through the vector table at $FC00 and Im2Jump at $FDFD, once a frame
; from the title to the Hewson picture.
IntroInterrupt:
  DI
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH IX
  PUSH IY
  EXX
  EX AF,AF'
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  CALL StarkosPlay
  POP HL
  POP DE
  POP BC
  POP AF
  EX AF,AF'
  EXX
  POP IY
  POP IX
  POP HL
  POP DE
  POP BC
  POP AF
  EI
  RET

; every fourth call: the two colour bars one step on
;
; The counter is the operand of the first LD A (self-modifying: $60F3 = 3, 0,
; 1, 2, ...); at 0 the bars move. The upper bar: TopBar's operand ($60FC) steps
; on through CycleTable, IXL counts 0-31 and sends it back to CycleTable's
; start when it wraps; rows 0-7 of the attributes ($5800-$58FF) are filled with
; eight consecutive table bytes, one a row. The lower bar: BottomBar's operand
; ($6159) steps back through the table; from AttrsRow16End back, nine rows of
; 32 attributes take one table byte a row, only where the screen's attribute is
; $46 or more (the bar shows through the picture's bright yellow and white, the
; darker cells stay). Uses A, B, C, DE, HL, IXL.
CycleColours:
  LD A,$03
  INC A
  AND $03
  LD (CycleColours+$0001),A
  RET NZ
TopBar:
  LD HL,CycleTable-1      ; the upper bar's pointer (the operand,
                          ; self-modifying; CycleTable - 1 at the start): one
                          ; byte on
  INC HL
  INC IXL                 ; IXL + 1, mod 32: at 0 the pointer goes back to the
                          ; table's start
  LD A,IXL
  AND $1F
  LD IXL,A
  JR NZ,TopBarKeep
  LD HL,CycleTable
TopBarKeep:
  LD (TopBar+$0001),HL    ; the pointer kept in the instruction
  LD DE,Attrs             ; rows 0-7: 32 cells a row, one table byte a row
  LD B,$08
TopBarRow:
  LD A,(HL)
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  INC HL
  DJNZ TopBarRow
BottomBar:
  LD HL,BottomBarStart    ; the lower bar's pointer (the operand,
                          ; self-modifying; BottomBarStart at the start): one
                          ; byte back
  DEC HL
  LD A,IXL                ; at IXL = 0 back to BottomBarWrap
  AND $1F
  JR NZ,BottomBarKeep
  LD HL,BottomBarWrap
BottomBarKeep:
  LD (BottomBar+$0001),HL ; the pointer kept in the instruction
  LD DE,AttrsRow16End             ; nine rows from row 16's end back, one table byte a
                          ; row, only over attributes of $46 and more
  LD B,$09
BottomBarRow:
  LD C,(HL)
  LD A,(DE)
  CP $46
  JR C,BottomBarCell2
  LD A,C
  LD (DE),A
BottomBarCell2:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell3
  LD A,C
  LD (DE),A
BottomBarCell3:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell4
  LD A,C
  LD (DE),A
BottomBarCell4:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell5
  LD A,C
  LD (DE),A
BottomBarCell5:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell6
  LD A,C
  LD (DE),A
BottomBarCell6:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell7
  LD A,C
  LD (DE),A
BottomBarCell7:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell8
  LD A,C
  LD (DE),A
BottomBarCell8:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell9
  LD A,C
  LD (DE),A
BottomBarCell9:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell10
  LD A,C
  LD (DE),A
BottomBarCell10:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell11
  LD A,C
  LD (DE),A
BottomBarCell11:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell12
  LD A,C
  LD (DE),A
BottomBarCell12:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell13
  LD A,C
  LD (DE),A
BottomBarCell13:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell14
  LD A,C
  LD (DE),A
BottomBarCell14:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell15
  LD A,C
  LD (DE),A
BottomBarCell15:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell16
  LD A,C
  LD (DE),A
BottomBarCell16:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell17
  LD A,C
  LD (DE),A
BottomBarCell17:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell18
  LD A,C
  LD (DE),A
BottomBarCell18:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell19
  LD A,C
  LD (DE),A
BottomBarCell19:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell20
  LD A,C
  LD (DE),A
BottomBarCell20:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell21
  LD A,C
  LD (DE),A
BottomBarCell21:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell22
  LD A,C
  LD (DE),A
BottomBarCell22:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell23
  LD A,C
  LD (DE),A
BottomBarCell23:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell24
  LD A,C
  LD (DE),A
BottomBarCell24:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell25
  LD A,C
  LD (DE),A
BottomBarCell25:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell26
  LD A,C
  LD (DE),A
BottomBarCell26:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell27
  LD A,C
  LD (DE),A
BottomBarCell27:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell28
  LD A,C
  LD (DE),A
BottomBarCell28:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell29
  LD A,C
  LD (DE),A
BottomBarCell29:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell30
  LD A,C
  LD (DE),A
BottomBarCell30:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell31
  LD A,C
  LD (DE),A
BottomBarCell31:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarCell32
  LD A,C
  LD (DE),A
BottomBarCell32:
  DEC DE
  LD A,(DE)
  CP $46
  JR C,BottomBarNext
  LD A,C
  LD (DE),A
BottomBarNext:
  DEC DE
  DEC HL
  DEC B
  JP NZ,BottomBarRow
CycleDone:
  RET                     ; (the byte before CycleTable)

; the colour bars' colours: $46 (bright yellow on black) and $47 (bright white
; on black), 48 bytes
;
; The upper bar reads eight bytes from TopBar's pointer, one byte on a step
; from $6274 and back there every 32 steps; the lower bar reads nine bytes back
; from BottomBar's, which runs from BottomBarStart down to $627E and back to
; BottomBarWrap.
CycleTable:
  DEFB $47,$46,$46,$47,$47,$46,$46,$47
  DEFB $46,$46,$47,$47,$46,$46,$47,$47
  DEFB $46,$47,$47,$46,$46,$47,$47,$46
  DEFB $47,$47,$46,$46,$47,$47,$46,$46
  DEFB $47,$46,$46,$47,$47,$46,$46,$47
BottomBarWrap:
  DEFB $46                ; the lower bar's pointer after each wrap
BottomBarStart:
  DEFB $46,$47,$47,$46,$46,$47,$47 ; the lower bar's first pointer

; a 6912-byte picture at HL: the pixels at once, the attributes one random row
; a frame
;
; Input: HL = the picture (6144 pixel bytes, 768 attributes). Clears RowShown,
; waits a frame (EI, HALT), the border and every attribute black, copies the
; pixels to Screen; then each frame (HALT) a row not yet shown, picked by
; Random (0-23, again until a free one), gets its 32 attributes from the
; picture. Returns after the 24th row. IXL counts the rows; the attributes'
; address is the operand of the LD HL at $62F4 (self-modifying).
ShowPicture:
  PUSH HL
  LD HL,RowShown          ; RowShown cleared: 24 zeros (the picture kept on the
                          ; stack)
  LD DE,RowShown+$0001
  LD BC,$0017
  LD (HL),B
  LDIR
  EI                      ; a frame, border black, attributes black
  HALT
  XOR A
  OUT ($FE),A
  LD HL,Attrs
  LD DE,Attrs+1
  LD BC,$02FF
  LD (HL),A
  LDIR
  POP HL                  ; the pixels
  LD DE,Screen
  LD B,$18
  LDIR
  LD (PictureAttrs+$0001),HL ; the picture's attributes kept in PictureAttrs;
                             ; IXL, the rows shown, from 0
  LD IXL,B
RevealRow:
  INC IXL                 ; the next row, until 24
  HALT
  LD A,IXL
  CP $19
  RET Z
PickRow:
  CALL Random             ; a random row 0-23 not shown yet
  AND $1F
  CP $18
  JR NC,PickRow
  LD HL,RowShown          ; RowShown + the row: 0 free, 1 shown
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,(HL)
  OR A
  JR NZ,PickRow
  LD (HL),$01
  EX DE,HL                ; the row * 32
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  EX DE,HL
PictureAttrs:
  LD HL,$0000             ; HL = the picture's attributes (the operand, written
                          ; at $62CA) + the row * 32
  ADD HL,DE
  PUSH HL
  LD HL,Attrs             ; the row's 32 attributes to the screen
  ADD HL,DE
  EX DE,HL
  POP HL
  LD C,$20
  LDIR
  JR RevealRow

; a random byte: the seed doubled (XOR $33 on a carry), XOR R
;
; The seed is the operand of the first LD A ($6306, self-modifying), written
; back each call. Output: A, C changed.
Random:
  LD A,$35
  ADD A,A
  JR NC,RandomMix
  LD C,$33
  XOR C
RandomMix:
  LD C,A
  LD A,R
  XOR C
  LD (Random+$0001),A
  RET

; one byte a row: 1 when ShowPicture has revealed it
RowShown:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; the page-4 sound engine, copied to EngineRun ($3BB bytes;
; src/sound/engine.asm)
EngineImage:
  INCBIN "sound/engine-c968.bin",$0000,955

; the engine's music and effect data, copied to EngineDataRun ($2028 bytes;
; src/res/sound)
EngineDataImage:
  INCBIN "sound/engine-data-de48.bin",$0000,8232

; the title: the ZYNAPS logo, RVS.M.STAWICKI (6912 bytes)
TitlePicture:
  INCBIN "screens/title.scr",$0000,6912

; the options screen: WITH AY, 48/128K MUSIC & SFX, the credits, the keys,
; 0.START 1.INF.LIVES 2.K-MOUSE
OptionsPicture:
  INCBIN "screens/options.scr",$0000,6912

; the Hewson picture: ZYNAPS, By Dominic Robinson, the HEWSON plate
HewsonPicture:
  INCBIN "screens/hewson.scr",$0000,6912

; the STarKos player and the SK10 song, copied to $8000 ($10C5 bytes;
; src/sound/starkos.asm)
StarkosImage:
  INCBIN "sound/starkos-8000.bin",$0000,4293
