; --------------------------------------------------------------------------------------------------------------------
; definekeys.asm: DEFINE KEYS: a prompt for each of UP, DOWN, LEFT, RIGHT, FIRE, the key scanned, the resident's reader patched
;
; DefineKeys $971A prints PRESS THE KEY FOR on line 84, then for each of the five readers (KeyUp $FC90 to KeyFire
; $FCCC, 15 bytes apart) the name from KeyNames $97B5 on line 100, waits for a key with ScanKeyboard $9916 (one half
; row every two frames, the 8 rows of KeyRowPorts in turn), shows the key's character after the name, waits 40 frames,
; and writes the key's port into the reader (reader+4) and BIT n,A for its bit (reader+13). Then the lines are wiped
; and the menu is drawn again. KeyXorMask $FCFA is not touched: after SELECT JOYSTICK's KEMPSTON ($FF there) the
; defined keys would read inverted (known only from the code: no write to $FCFA in $971A-$97A4).
;
; The menu recording (frames 71-1354) defines UP = X, DOWN = K, LEFT = L, RIGHT = P, FIRE = SPACE: the readers in
; end.szx hold $FEFE bit 2, $BFFE bit 2, $BFFE bit 1, $DFFE bit 0, $7FFE bit 0 (they held I, J, Q, W, O in menu.szx),
; and the key name slot ends as "FIRE  /". Its script's Z (frame 70) came before the first scan (frame 104) and its M
; while a name was revealed: neither was taken.
; --------------------------------------------------------------------------------------------------------------------

  ORG $971A

; DEFINE KEYS: the prompt line, then the five keys
;
; Reached from Menu $99A8 (JP Z at $99D2) with the text lines wiped. MenuHook
; $980A, then PRESS THE KEY FOR (small font, line 84), then DefineKeysLoop
; $9736.
;
; menu: entered once at frame 71 (SPACE on DEFINE KEYS at frame 6).
;
; Witness: L1 2 (menu, rzx-r0).
DefineKeys:
  CALL MenuHook
  CALL PrintText

; PrintText: small font, byte 9, shift 5, line 84: PRESS THE KEY FOR
TextPressTheKeyFor:
  INCBIN "res/front-texts/press-the-key-for.bin",$0000,22

; For the five readers: show the name, scan a key, show it, wait, patch the
; reader's port and bit
;
; IY = KeyUp $FC90 (the reader), IX = KeyNames $97B5 (its name), C = 0-4. For
; each: the 7-byte name into KeyNameSlot $97AC, PrintKeyName $97A5;
; ScanKeyboard $9916 (A = the key's character, ScanBit and ScanPort set); the
; character into KeyNameChar $97B2 and PrintKeyName again (UP    X);
; WaitOrSpace $9BA5 with BC = 20 (40 frames); reader+13 := $47 OR ScanBit x 8
; (BIT ScanBit,A), reader+4/+5 := ScanPort. Then IY + 15, IX + 7. After the
; five: ClearTextLine with the lines 68, 84, 100, 116 and back to Menu
; (BackToMenu $9807).
;
; SPACE as a key works if it is let go within the 16 frames of the second
; PrintKeyName (the menu recording's FIRE). Held longer, the WaitOrSpace after
; it sees SPACE, drops its own return and RETs to the next word on the stack,
; IY (pushed at $9745): the reader runs and its RET goes to IX, the name text,
; as code. Known only from the code.
;
; menu: 5 passes (frames 88-1354).
;
; Witness: L1 2 (menu, rzx-r0).
DefineKeysLoop:
  LD IY,KeyUp
  LD IX,KeyNames
  LD B,$05
  LD C,$00
DefineKeyNext:
  PUSH BC                 ; one key: the name into the slot
  PUSH IX
  PUSH IY
  PUSH IX
  POP HL
  LD DE,KeyNameSlot
  LD BC,$0007
  LDIR
DefineKeyScan:
  CALL PrintKeyName       ; the name, the scan, the name with the key
  CALL ScanKeyboard
  LD (KeyNameChar),A
  CALL PrintKeyName
  LD BC,$0014
  CALL WaitOrSpace
DefineKeyPatch:
  POP IY                  ; BIT n,A from ScanBit, then the port
  LD A,(ScanBit)
  SLA A
  SLA A
  SLA A
  OR $47
  LD (IY+$0D),A
  LD BC,(ScanPort)
  LD (IY+$04),C
  LD (IY+$05),B
  LD BC,$000F
  ADD IY,BC
  POP IX
  LD BC,$0007
  ADD IX,BC
  POP BC
  INC C
  DJNZ DefineKeyNext
DefineKeysDone:
  LD A,$44                ; five done: wipe the four lines, back to the menu
  CALL ClearTextLine
  LD A,$54
  CALL ClearTextLine
  LD A,$64
  CALL ClearTextLine
  LD A,$74
  CALL ClearTextLine
  JP BackToMenu

; Print KeyNameText (the key's name and the key) in the large font on line 100
;
; PrintText $9D72 with KeyNameText's parameters. menu: 10 runs (two a key,
; frames 88-1234).
;
; Witness: L1 20 (menu, rzx-r0).
PrintKeyName:
  CALL PrintText

; PrintText: large font, byte 13, line 100: a 7-byte slot for the name ("RIGHT
; " on the tape) whose last byte gets the key
KeyNameText:
  INCBIN "res/front-texts/key-name.bin",$0000,4
KeyNameSlot:
  INCBIN "res/front-texts/key-name.bin",$0004,6
KeyNameChar:
  INCBIN "res/front-texts/key-name.bin",$000A,2

; PrintKeyName's RET after its string
;
; menu: 10 runs (frames 104-1250).
;
; Witness: L1 20 (menu, rzx-r0).
PrintKeyNameDone:
  RET

; The five names, 7 bytes each, no end mark: UP, DOWN, LEFT, RIGHT, FIRE (the
; order of the readers KeyUp to KeyFire)
;
; Read 7 bytes at a time by DefineKeysLoop $9736 (LDIR to KeyNameSlot $97AC).
; menu: all 35 bytes read.
KeyNames:
  INCBIN "res/front-texts/key-names.bin",$0000,35

  ORG $9916

; Wait for a key: one half row every two frames; A = its character, ScanBit =
; its bit, ScanPort = its port
;
; IX = KeyRowPorts $9970, IY = KeyRowChars $9980. For each of the 8 half rows:
; HALT, HALT, ShimmerFrame, PaintBoxColours, IN of the row's port, then the 5
; bits from bit 0: the first at 0 (pressed) gives E = the bit. None: the next
; row (IX + 2, IY + 5); after the 8th row, start again. Found: ScanBit $996D =
; E, ScanPort $996E = the port, A = KeyRowChars[row x 5 + E]. A key is seen
; only if it is held while its row is read, once in 16 frames; with two keys
; held the first row in the order wins. No wait for the key's release.
;
; menu: 55 entries (5 calls, 50 restarts after the 8th row), 421 rows read, 5
; keys found (frames 104-1234).
;
; Witness: L1 70 (menu, rzx-r0).
ScanKeyboard:
  LD IX,KeyRowPorts
  LD IY,KeyRowChars
  LD B,$08
ScanRow:
  PUSH BC                 ; two frames, the effects, then this half row
  PUSH DE
  PUSH IX
  PUSH IY
  HALT
  HALT
  CALL ShimmerFrame
  CALL PaintBoxColours
  POP IY
  POP IX
  POP DE
  LD C,(IX+$00)
  LD B,(IX+$01)
  IN A,(C)
  LD B,$05
  LD E,$00
  LD D,A
ScanBitLoop:
  RRCA                    ; the five bits, bit 0 first
  JP NC,ScanFound
  INC E
  DJNZ ScanBitLoop
  POP BC
  INC IX
  INC IX
  LD DE,$0005
  ADD IY,DE
  DJNZ ScanRow
  JP ScanKeyboard
ScanFound:
  LD A,E                  ; E = the bit
  LD (ScanBit),A
  LD C,(IX+$00)
  LD B,(IX+$01)
  LD (ScanPort),BC
  POP BC
  LD D,$00
  ADD IY,DE
  LD A,(IY+$00)
  RET

; The bit (0-4) of the key ScanKeyboard found
;
; Written at $9957, read by DefineKeysLoop at $9766 (menu: 5 each).
ScanBit:
  DEFB $00

; The port of the key's half row
;
; Written at $9960, read at $9774 (menu: 5 each).
ScanPort:
  DEFW $0000

; The 8 half rows ScanKeyboard reads, in its order: $FEFE, $FDFE, $FBFE, $DFFE,
; $BFFE, $7FFE, $EFFE, $F7FE
;
; Read by ScanKeyboard $9916 (LD C,(IX); LD B,(IX+1)). menu: all 16 bytes read.
KeyRowPorts:
  INCBIN "res/front/keyboard.bin",$0000,16

; The character of each key, 5 a half row, bit 0 first: "-" CAPS SHIFT, "+"
; ENTER, "/" SPACE, "." SYMBOL SHIFT
;
; Read by ScanKeyboard (A = (IY + bit)). menu: the characters of the five keys
; found read (X, K, L, P, "/"). PrintText has no glyph for "-", "+", "/" or
; ".": its mapping (byte - $30 + $5C for a byte under "A" that is not a space)
; shows them as the glyphs of Y, W, the space and Z; the digits become glyphs
; 27-36, which the large font that KeyNameText uses does not have (it ends with
; the space, glyph 26): a digit key would show the bytes of PixelShift and the
; code after them. Known only from the code (the recording took no digit and
; showed "/" as a space).
KeyRowChars:
  INCBIN "res/front/keyboard.bin",$0010,40
