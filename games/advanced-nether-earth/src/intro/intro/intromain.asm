; --------------------------------------------------------------------------------------------------------------------
; intromain.asm: the intro: the Eternity Industry logo, its music and the decorated picture
;
; The first of the boot's three programs at $6600 (HRUM block 1 inside the loader, src/loader.asm: LoaderMain calls
; IntroRun = $6600 once the block has unpacked itself there). Intro runs about 800 frames (tools/intro_trace.py:
; frames 52-859 of the run; the emulator recording work/intro/i1, its screens of script frames 750 and 1250 hold the
; decorated logo in screen 5; recording frame = script frame + about 1602) and returns to LoaderMain, which keeps the
; picture 309 frames more with the tune playing.
;
; What it does in order: the attributes white (IntroWhite), bank 7's screen cleared, the player (New SoundTrack Player
; by Phantom Family with "MAD NIGHT" by Syrus, $7D2D) copied to bank 6 $C000 and initialised, the IM 2 table of $61
; bytes at $6000-$6100 for LoaderInterrupt ($6161), the picture block ($7537, HRUM) copied to bank 7 $C000 and run
; there: it unpacks the plain "ETERNITY industry" logo (src/res/intro/eternity.png) into screen 7. Then screen 7 is
; shown ($7FFD = $18) while LogoPicture unpacks the decorated version of the same logo (src/res/intro/logo.png: the
; logo with lightning, sparks and coloured blobs around it) into screen 5; IM 2 starts the music. After 576 frames,
; 192 frames of IntroAyEnvelope (a bug: it writes $7FFD, not the AY); then screen 5 (the decorated logo) is shown, screen 7 is whitened behind it and shown
; for one white frame, and the decorated logo comes back with a black border: the loader's wait follows.
;
; LogoPicture is the screen depacker of the authors' screen packer, the same code as the title picture's
; (src/intro/title/title.ann, TitlePicture) but for its first byte (EI instead of DI); its stream LogoStream follows
; it. The format is in src/intro/title: tools/intro_screen.py packs src/res/intro/logo.png along
; src/res/intro/logo.parse.
; --------------------------------------------------------------------------------------------------------------------

; the intro: logo, music, decorated logo
;
; Entered from LoaderMain with interrupts off, IM 1, bank 0 paged, screen 5
; shown. Uses the loader's SetPage ($6207: A to $7FFD and BANKM) and WaitFrames
; ($6200); returns with bank 0 paged, screen 5 shown, IM 2 on LoaderInterrupt
; (the music plays on).
Intro:
  LD HL,$5800             ; screen 5's attributes white on white, the border
                          ; white: nothing shows while the logo is set up
  CALL IntroWhite
  DI                      ; interrupts off while the banks are switched
  LD A,$17                ; bank 7 at $C000
  CALL SetPage
  LD HL,$C000             ; bank 7's screen ($C000-$DAFF) zero: screen 7 black
  LD DE,$C001
  LD BC,$1AFF
  LD (HL),L               ; L = 0: the first byte zero, LDIR spreads it
  LDIR
  LD A,$16                ; bank 6 at $C000
  CALL SetPage
  LD HL,NstPlayerImage    ; the player and its tune to bank 6 $C000 ($2681
                          ; bytes: to one byte past the image's end)
  LD DE,$C000
  LD BC,NstPlayerCopyLength
  LDIR
  CALL $C000              ; Init (src/music/stp-player.asm): the tune set up (and the AY silenced)
  LD A,$10                ; bank 0 at $C000 again
  CALL SetPage
  LD HL,$6000             ; the IM 2 table: $6000-$6100 all $61, so any bus
                          ; byte gives the vector $6161, LoaderInterrupt
  LD DE,$6001
  LD (HL),$61
  LD BC,$0100
  LDIR
  EI                      ; still IM 1: this HALT only waits for the frame
  HALT
  LD A,$17                ; bank 7 at $C000
  CALL SetPage
  LD HL,IntroScreenBlock  ; the logo's HRUM block to bank 7 $C000 ...
  LD DE,$C000
  LD BC,IntroScreenBlockLength
  LDIR
  CALL $C000              ; ... and run: it unpacks itself (the depacker at
                          ; $5B89) into screen 7, $C000-$DAFF, then EI; RET
  XOR A                   ; black border
  OUT ($FE),A
  LD A,$18                ; bank 0 at $C000, screen 7 shown: the plain logo
                          ; appears
  CALL SetPage
  CALL LogoPicture        ; the decorated logo into screen 5, unseen
  LD A,$60                ; I = $60: the vector table above
  LD I,A
  IM 2                    ; IM 2: LoaderInterrupt plays the tune from here on
  HALT
  LD BC,$0240             ; 576 frames of the plain logo
  CALL WaitFrames
  LD BC,$00C0             ; then 192 frames ...
IntroEnvelopeLoop:
  PUSH BC
  HALT                    ; ... each after the interrupt (and its music frame)
                          ; ...
  CALL IntroAyEnvelope    ; ... with the (broken) switch of channel A's volume
                          ; 15 to the envelope
  POP BC
  DEC BC
  LD A,B
  OR C
  JR NZ,IntroEnvelopeLoop
  LD A,$17                ; bank 7 paged, screen 5 shown ($17): the decorated
                          ; logo appears
  CALL SetPage
  LD HL,$D800             ; screen 7's attributes white (unseen), the border
                          ; white
  CALL IntroWhite
  LD A,$18                ; screen 7 shown: one white frame
  CALL SetPage
  HALT
  XOR A                   ; black border
  OUT ($FE),A
  LD A,$10                ; bank 0, screen 5 shown: the decorated logo stays
  CALL SetPage
  RET

; the attributes at HL white on white, the border white
;
; 768 bytes of $3F from HL after a frame's HALT, and one more HALT after them
; (interrupts on: the caller's IM). The same as the loader's WhiteScreen
; ($6215) but for its EI.
IntroWhite:
  EI
  HALT
  LD A,$07                ; white border
  OUT ($FE),A
  LD D,H
  LD E,L
  INC E
  LD (HL),$3F             ; paper and ink white
  LD BC,$02FF
  LDIR
  HALT
  RET

; meant to give channel A's volume 15 to the envelope; writes $7FFD instead (bug)
;
; AY register 8 (channel A's volume) read back; if the player has set it to 15,
; 16 is meant to go to the AY data port, so that the envelope generator drives
; channel A's volume this frame. But LD B,$7F leaves C = $FD: the OUT goes to
; $7FFD, not to $BFFD. The envelope never sounds; $10 pages bank 0 and shows
; screen 5 until the next interrupt sets $7FFD again. Called once a frame for
; the 192 frames after the first 576; in recording d1 (frames 2761-2952) the
; write ran 49 times and the only port written was $7FFD (docs/09-sound.md 9.7).
IntroAyEnvelope:
  LD BC,$FFFD             ; AY register select
  LD A,$08
  OUT (C),A
  IN A,(C)                ; the volume as the player left it
  CP $0F
  RET NZ                  ; not 15: kept
  INC A                   ; 16: the envelope's level
  LD B,$7F                ; meant as the AY data port $BFFD, but C = $FD: this
                          ; is $7FFD (bug)
  OUT (C),A
  RET

; never run: the tail of a white-screen fill
;
; LD D,H / LD E,L / INC E / LD (HL),$3F / LD BC,$02FF / LDIR / RET:
; IntroWhite's fill without its HALTs and border, left by the authors'
; assembly. Nothing calls or jumps here (no run of tools/intro_trace.py reaches
; it).
IntroDeadFill:
  LD D,H
  LD E,L
  INC E
  LD (HL),$3F
  LD BC,$02FF
  LDIR
  RET

; the decorated Eternity Industry picture unpacked to screen 5 ($4000)
;
; Called by Intro while screen 7 (the plain logo) is shown, so the picture
; builds up unseen; the 48 ROM is paged ($7FFD = $18: CALL $0052 needs its RET
; there). EI first (where the title picture's copy has DI): the loader's
; interrupt cannot run yet anyway (IM 1 until Intro sets IM 2), and the
; unpacking takes about 1.4 frames. Returns with HL' = $2758, the ROM's value.
LogoPicture:
  EI
  CALL $0052              ; the ROM's RET at $0052 returns at once and leaves
                          ; $66C5 below SP
LogoBase:
  DEC SP                  ; SP - 2 is the return address just left: BC =
                          ; LogoBase, wherever the code was loaded
  DEC SP
  POP BC
  LD HL,LogoPutByte-LogoBase ; DE = LogoPutByte
  ADD HL,BC
  EX DE,HL
  LD HL,LogoCopyCall+$0001-LogoBase ; the CALL of LogoCopy ...
  ADD HL,BC
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,LogoLiteralCall+$0001-LogoBase ; ... the CALL of LogoLiteral ...
  ADD HL,BC
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,LogoRunCall+$0001-LogoBase ; ... and the CALL of LogoRun to LogoPutByte
  ADD HL,BC
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,LogoStream-LogoBase ; HL = LogoStream, the packed screen
  ADD HL,BC
  LD DE,$4000             ; HL' = $4000, the first byte of the shown screen; DE
                          ; = $4000, the count of bytes out (as an address in
                          ; the stream's order)
  PUSH DE
  EXX
  EX AF,AF'
  LD A,$03                ; A' = 3: three thirds of pixels to go, NZ: pixels,
                          ; not attributes
  OR A
  LD B,$08                ; B' = 8 lines of a character row, C' = 8 rows of a
                          ; column
  LD C,B
  POP HL
  EX AF,AF'
  EXX
LogoNextToken:
  LD A,(HL)               ; the next token
  BIT 7,A
  JR NZ,LogoBlock         ; bit 7 set: a literal block, a run or the end
  AND $07                 ; a copy: C = the offset's high bits
  LD C,A
  LD A,(HL)               ; B = the length, bits 3-6 + 3: 3-18 bytes
  RRCA
  RRCA
  RRCA
  AND $0F
  ADD A,$03
  LD B,A
  INC HL                  ; the offset's low byte
  LD A,E                  ; HL = DE - offset: where the copy starts, in the
                          ; stream's order
  SUB (HL)
  INC HL
  PUSH HL
  LD L,A
  LD A,D
  SBC A,C
  LD H,A
LogoCopy:
  PUSH HL                 ; one byte of a copy: its stream position to a screen
                          ; address
  LD A,H                  ; the attributes ($5800-$5AFF) are in screen order
                          ; already
  AND $58
  CP $58
  JR Z,l_6729
  LD C,A                  ; C = $40 + third x 8 + the pixel line (L bits 0-2)
  LD A,L
  AND $07
  OR C
  LD C,A
  ADD HL,HL               ; HL x 4: H bits 0-4 the column, L bits 5-7 the
                          ; character row
  ADD HL,HL
  LD A,H
  AND $1F
  LD H,A
  LD A,L
  AND $E0
  OR H
  LD L,A
  LD H,C                  ; HL = the screen address of that byte
l_6729:
  LD A,(HL)               ; the byte from the screen, written again at the
                          ; current place
LogoCopyCall:
  CALL $74A6              ; operand patched to LogoPutByte
  POP HL
  INC HL                  ; the next source byte
  DJNZ LogoCopy
  POP HL                  ; the token's pointer back
  JR LogoNextToken
LogoBlock:
  AND $7F                 ; bit 7 set: the low 7 bits, 0 the end
  JR Z,LogoDone
  INC HL                  ; the byte after the token
  BIT 6,A                 ; bit 6 set: a run
  JR NZ,LogoRun
LogoLiteral:
  LD B,A                  ; a literal block of B bytes
l_673E:
  LD A,(HL)
LogoLiteralCall:
  CALL $74A6              ; operand patched to LogoPutByte
  INC HL
  DJNZ l_673E
  JR LogoNextToken
LogoRun:
  AND $3F                 ; a run: the next byte (b & $3F) + 3 times
  ADD A,$03
  LD B,A
  LD A,(HL)
LogoRunCall:
  CALL $74A6              ; operand patched to LogoPutByte
  DJNZ LogoRunCall
  INC HL
  JR LogoNextToken
LogoDone:
  EXX                     ; the end: HL' = $2758 as the ROM keeps it,
                          ; interrupts on
  LD HL,$2758
  EXX
  EI
  RET

; write A to the screen at HL' and step HL' in the stream's order
;
; DE counts the bytes out (LogoCopy reads its sources by that count). In the
; alternate set: HL' the screen address, B' the lines left in the character
; row, C' the rows left in the column, A' (with its flags) 3 - third and the
; columns done x 8; Z' set once the pixels are done: then HL' just counts on
; through the attributes.
LogoPutByte:
  INC DE
  EXX
  LD (HL),A
  EX AF,AF'
  JR Z,l_677B             ; Z': the attributes, one after another
  INC H                   ; the next pixel line down
  DJNZ l_6780
  LD DE,$F820             ; a character row done: H - 8 (back to its first
                          ; line), L + $20 (the next row)
  ADD HL,DE
  DEC C                   ; 8 rows: the column is done
  JR NZ,l_677E
  LD DE,$FF01             ; the next column, the third's top row (H - 1 undoes
                          ; the carry of the 8th row)
  ADD HL,DE
  ADD A,$08               ; A' + 8 a column: the 32nd carries
  JR NC,l_677C
  LD DE,$07E0             ; the third is done: on to the next third's first
                          ; column
  ADD HL,DE
  DEC A                   ; one third less: Z after the third third, the
                          ; attributes next
  JR l_677C
l_677B:
  INC HL                  ; an attribute: the next one
l_677C:
  LD C,$08                ; a new column: 8 rows
l_677E:
  LD B,$08                ; a new character row: 8 lines
l_6780:
  EX AF,AF'
  EXX
  RET

; the packed decorated logo, 3508 bytes
;
; Built from src/res/intro/logo.png and src/res/intro/logo.parse by
; tools/intro_screen.py pack. Ends at $7536, right before the picture block.
LogoStream:
  INCBIN "res/logo.lz",$0000,3508
