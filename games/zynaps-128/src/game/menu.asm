; --------------------------------------------------------------------------------------------------------------------
; menu.asm: Menu screens: the raster colours, the key definition
;
; The menu screens (the selections, the key definition, the high-score table) colour the text with a raster:
; MenuRasterInterrupt, the interrupt handler while a menu is shown, waits for the beam to reach the top of the screen
; and rewrites 20 attribute cells (columns 6-25) of the current attribute row for each scan line, so each scan line of
; the text can have its own colour.
;
; The colours of the lines come from the colour buffer $FC00 (the table pointer $80AE, the line count $80B0) that
; ExpandColours fills from run-length lists ($82A7, $82CE, $82D7, $82E0). The menu routines animate a highlight by
; expanding a list into the buffer again a line further each frame.
;
; RedefineKeys asks for the five keys (fire, up, down, left, right) into the key table $8188; WaitKeyPress scans the
; six half-rows of $8192 (not 1-5 nor 6-0: those are the joystick and menu keys).
; --------------------------------------------------------------------------------------------------------------------

; Interrupt handler of the menu screens: a colour per scan line
;
; Saves every register and SP (into the LD SP at $A575), sets the border black,
; waits about 77 x 15 DJNZ and 23 more for the beam (61 and 16 in the 48K: the
; Pentagon's interrupt comes at another place in the frame), then for each of
; $80B0 scan lines takes a colour from the table at ($80AE) and PUSHes it into
; 20 attribute cells ending at HL (HL steps a row of 32 every 8 lines: A'
; rotates a single bit). Both paths of a line take the same time; a line is 12
; T-states longer than the 48K's (LD B,(HL) twice, two NOPs and JR NZ where the
; 48K had three NOPs and JP NZ). Then SP back, $80B9 (frames left, counted by
; WaitMenuRasterEnd) down by one unless 0, EI.
;
; Installed by SetMenuRaster in the interrupt handler pointer $FDFE. Evidence:
; 48K c2 L1 has $A512 in frames 690-765 (the selections screen), 26 permille of
; the frame time.
;
; On a 128K: the glue makes the POP BC: POP DE: POP HL at $A581 JP PlayAtA581
; ($5B28): a frame of the engine, then the POPs (src/game/setup.asm, glue.asm;
; docs/09-sound.md 9.2).
MenuRasterInterrupt:
  PUSH AF
  PUSH HL
  PUSH DE
  PUSH BC
  EX AF,AF'
  EXX
  PUSH AF
  PUSH HL
  PUSH DE
  PUSH BC
  LD (MenuRasterSavedSp+$0001),SP ; the stack pointer kept in the LD SP below
  LD DE,(RasterTable)     ; DE' the colour table, C' the lines
  LD A,(RasterLines)
  LD C,A
  EXX
  EX AF,AF'
  LD HL,$57FA             ; one cell above row 0, column 26: the first ADD
                          ; makes it $581A
  LD DE,$0020
  LD A,$01                ; a bit rotating once a line: every 8th line the next
                          ; attribute row
  EX AF,AF'
  EXX
  XOR A                   ; border black
  OUT ($FE),A
  LD A,$4D                ; wait for the beam: $4D passes ($3D in the 48K)
MenuRasterWait:
  LD B,$0F
MenuRasterDelay:
  DJNZ MenuRasterDelay
  AND $FF
  INC HL
  DEC A
  JP NZ,MenuRasterWait
  LD B,$17                ; and a little more: $17 ($10 in the 48K)
MenuRasterAlign:
  DJNZ MenuRasterAlign
  LD A,$00
  OUT ($FE),A
MenuRasterLine:
  LD A,(DE)               ; the colour of this line
  INC E
  EXX
  LD C,A
  EX AF,AF'
  RRCA
  JP NC,MenuRasterSameRow ; every 8th line: the next attribute row
  ADD HL,DE
  JP MenuRasterPush
MenuRasterSameRow:
  LD B,(HL)               ; the same time as the ADD and JP
  LD B,(HL)
  LD B,(HL)
MenuRasterPush:
  LD B,C                  ; 20 cells, columns 6-25, in this line's colour
  LD SP,HL
  PUSH BC
  PUSH BC
  PUSH BC
  PUSH BC
  PUSH BC
  PUSH BC
  PUSH BC
  PUSH BC
  PUSH BC
  PUSH BC
  LD B,(HL)               ; the line's padding: LD B,(HL) twice and two NOPs,
                          ; 22 T (12 in the 48K)
  LD B,(HL)
  NOP
  NOP
  EXX
  EX AF,AF'
  DEC C                   ; the next line
  JR NZ,MenuRasterLine
  LD A,$00
  OUT ($FE),A
MenuRasterSavedSp:
  LD SP,$0000             ; LD SP,nn: the stack pointer saved at the start
  LD HL,RasterFrames      ; the frames left for WaitMenuRasterEnd
  LD A,(HL)
  SUB $01
  JR C,MenuRasterDone
  LD (HL),A
MenuRasterDone:
  POP BC
  POP DE
  POP HL

; l_A584
l_A584:
  POP AF
  EX AF,AF'
  EXX
  POP BC
  POP DE
  POP HL
  POP AF
  EI
  RET

; Install MenuRasterInterrupt as the interrupt handler
;
; Writes $A512 to the handler pointer $FDFE, EI. Callers: MenuScreenSetup,
; SelectPlayers.
SetMenuRaster:
  LD HL,MenuRasterInterrupt
  LD (InterruptHandler),HL
  EI
  RET

; Wait for the menu raster's frames to run out, then the title interrupt
;
; Waits (HALT) until $80B9 is 0, clears the colour buffer, then installs
; TitleInterrupt ($A9E4) in $FDFE. Callers: RedefineKeys, SelectPlayers,
; HighScoreEntry, RoundPlaySetup.
WaitMenuRasterEnd:
  HALT
  LD A,(RasterFrames)
  AND A
  JR NZ,WaitMenuRasterEnd
  CALL ClearColourBuffer
  HALT
  LD HL,TitleInterrupt
  LD (InterruptHandler),HL
  RET

; Clear the raster colour buffer $FC00-$FCFF
;
; Callers: WaitMenuRasterEnd, MenuScreenSetup, SelectPlayers.
ClearColourBuffer:
  LD HL,HitGridX
  XOR A
ClearColourBufferByte:
  LD (HL),A
  INC L
  JR NZ,ClearColourBufferByte
  RET

; Expand the colour list ($80B1) into the buffer at DE
;
; As ExpandColours with HL from $80B1.
ExpandNextColours:
  LD HL,(RasterList)

; Expand a run-length colour list into the buffer
;
; HL: the list; DE: the destination; B: the bytes to write. A byte below $80 is
; a colour, $80+n followed by a colour is n of that colour, $FF starts the list
; again (it repeats until B bytes are written). Returns DE past the bytes, HL
; at the list's start.
;
; Callers: MenuScreenSetup, SelectPlayers, RedefineKeys (by ExpandNextColours).
ExpandColours:
  PUSH HL
ExpandColoursRestart:
  POP HL                  ; $FF: from the list's start again
  PUSH HL
ExpandColoursNext:
  LD A,(HL)
  INC HL
  CP $FF
  JR Z,ExpandColoursRestart
  AND A
  LD C,$02                ; a single colour: C = 2, one store
  JP P,ExpandColoursStore
  AND $7F                 ; $80+n: n of the next byte
  LD C,A
  INC C
  LD A,(HL)
  INC HL
ExpandColoursStore:
  DEC C
  JR Z,ExpandColoursNext
  LD (DE),A
  INC DE
  DJNZ ExpandColoursStore
  POP HL
  RET

; The key definition screen (menu key 3)
;
; MenuScreenSetup, message 13 (KEYBOARD DEFINITION), then for each of the five
; keys of the key table $8188 (fire, up, down, left, right; a half-row port
; high byte and a bit mask each): its prompt (messages 14-18), its current
; name, a new key (WaitKeyPress), the new name, 10 frames, the key stored; the
; line's 8 scan lines get the highlight colours ($82D7 expanded into $FC60 + 24
; a key).
;
; After the last key: 100 frames, WaitMenuRasterEnd, ClearScreen $858B. Used by
; MenuKeys.
;
; On a 128K: the CALL $A685 at $A5D1 becomes CALL HookScreenWipe ($B39C): the
; music off, the wipe, sounds $1E + $1F; the glue makes the CALL $858B at $A61F
; CALL ClearThenMusic ($5B46): the screen cleared, the music on
; (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).
RedefineKeys:
  CALL MenuScreenSetup
  EXX                     ; the highlight colours and their place in the buffer
  LD HL,ColoursHighlight
  LD (RasterList),HL
  LD DE,MenuColours+$0040
  EXX
  LD A,$0D                ; KEYBOARD DEFINITION
  CALL PrintMessage
  LD B,$05
  LD E,A
  LD HL,KeyTable          ; the key table
RedefineKeysNext:
  PUSH BC                 ; the next prompt
  INC E
  LD A,E
  CALL PrintMessage
  LD C,(HL)               ; the current key: C the port, B the mask
  INC HL
  LD B,(HL)
  CALL PrintKeyName
  CALL WaitKeyPress       ; a new key
  CALL PrintKeyName
  LD A,$0A
  CALL WaitFrames
  LD (HL),B               ; stored
  DEC HL
  LD (HL),C
  EXX                     ; the highlight under this line
  PUSH DE
  LD B,$08
  CALL ExpandNextColours
  POP DE
  LD HL,$0018             ; the next line of the buffer, 3 text rows down
  ADD HL,DE
  EX DE,HL
  EXX
  INC HL
  INC HL
  POP BC
  DJNZ RedefineKeysNext
  LD A,$64                ; 2 seconds
  CALL WaitFrames
  CALL WaitMenuRasterEnd
  CALL ClearScreen
  RET

; Print the name of a key and come back to its place
;
; C: the half-row port high byte; B: the bit mask. The key number 5 x the
; half-row (the 0 bit of C) + the bit is looked up in the key names $8198: a
; letter prints as it is, 0-3 print the messages 9-12 (CS, SS, SP, EN). A space
; after it; the print position is put back.
PrintKeyName:
  PUSH AF
  PUSH HL
  PUSH BC
  LD A,$FB                ; 5 x the half-row
PrintKeyNameRow:
  ADD A,$05
  RR C
  JR C,PrintKeyNameRow
  DEC A
PrintKeyNameBit:
  INC A                   ; + the bit
  RR B
  JR NC,PrintKeyNameBit
  LD C,A
  LD B,$00
  LD HL,KeyNames          ; the key names, one per key
  ADD HL,BC
  LD A,(HL)
  LD BC,(PrintPos)
  CP $04                  ; 0-3: the name is a message
  JR NC,PrintKeyNameChar
  ADD A,$09
  CALL PrintMessage
  JR PrintKeyNameDone
PrintKeyNameChar:
  CALL PrintChar
PrintKeyNameDone:
  LD A,$20
  CALL PrintChar
  LD (PrintPos),BC
  POP BC
  POP HL
  POP AF
  RET

; Wait for one key, then for its release
;
; Scans the six half-rows of $8192 ($FE $FD $FB $DF $BF $7F) until exactly one
; key of a half-row is down. Returns C = its half-row port byte, B = its bit
; mask; waits until no key at all is down.
WaitKeyPress:
  PUSH AF
  PUSH HL
  PUSH DE
WaitKeyPressScan:
  LD HL,KeyScanRows
  LD B,$06
WaitKeyPressRow:
  LD A,(HL)
  IN A,($FE)
  CPL
  AND $1F
  JR Z,WaitKeyPressNextRow
  LD C,A                  ; a single bit?
WaitKeyPressBit:
  SRL A
  JR NC,WaitKeyPressBit
  JR Z,WaitKeyPressFound
WaitKeyPressNextRow:
  INC HL
  DJNZ WaitKeyPressRow
  JR WaitKeyPressScan
WaitKeyPressFound:
  LD B,C
  LD C,(HL)
WaitKeyPressRelease:
  XOR A
  IN A,($FE)
  CPL
  AND $1F
  JR NZ,WaitKeyPressRelease
  POP DE
  POP HL
  POP AF
  RET

; Clear the screen and start the menu raster
;
; ClearScreen $858B, ClearColourBuffer, the colours $82A7 (48 lines) into $FC20
; and $82CE (120 lines) into $FC50, 168 raster lines from $FC20, SetMenuRaster.
; Callers: RedefineKeys, HighScoreEntry, LevelStart.
MenuScreenSetup:
  CALL ClearScreen
  CALL ClearColourBuffer
  LD DE,MenuColours
  LD (RasterTable),DE
  LD HL,ColoursTop
  LD B,$30
  CALL ExpandColours
  LD DE,MenuColours+$0030
  LD HL,ColoursMenu
  LD B,$78
  CALL ExpandColours
  LD A,$A8
  LD (RasterLines),A
  CALL SetMenuRaster
  RET

; Wait A frames
;
; A: the frames (HALT A times, interrupts enabled). Callers: RedefineKeys,
; HighScoreEntry, EndOfPlay.
WaitFrames:
  PUSH BC
  LD B,A
  EI
WaitFramesLoop:
  HALT
  DJNZ WaitFramesLoop
  POP BC
  RET
