; --------------------------------------------------------------------------------------------------------------------
; entry.asm: The entry and the new game
;
; LoaderMain jumps to GameEntry $9100 once the game and (on a 128K) the music are in. GameEntry completes the parked
; zone set, builds the IM 2 table and goes to GameStart $CBF9, which runs the menu and then a new game. NewGame $915B
; puts every piece of the world back: Matt, the energy, the mask slots, the pick-ups, the maps, the score.
; --------------------------------------------------------------------------------------------------------------------

  ORG $9100

; The entry from the loader: the parked zone 1, IM 2, the Kempston test, then
; GameStart
;
; Copies Zone1CharsLow $F000 to $5B00 (1280 bytes) and Zone1Attrs $EE00 to
; $6300 (256), so that zone 1 is whole in the first parked slot; sets R = $FF
; (the random generator Random $92C6 reads R), SP = StackTop, I = $FE and fills
; ImTable $FE00-$FF00 with $FF; writes JR (ImJr $FFFF = $18) and JP Interrupt
; $9226 at ImJump $FFF4, then IM 2. Clears the first attribute of each zone set
; ($EF00, $6300, $6C00, $7500). KempstonTest $9F62 sets ControlMethod $A13A to
; 0 (Kempston) when an interface answers. Then JP GameStart $CBF9.
;
; Witness: L1 1 (c1).
GameEntry:
  DI
  LD HL,Zone1CharsLow
  LD DE,ParkedZone1
  LD BC,$0500
  LDIR
  LD HL,Zone1Attrs
  LD DE,Zone1AttrsLeftover
  LD BC,$0100
  LDIR
  LD A,$FF
  LD R,A
  LD SP,StackTop
  LD A,$FE
  LD I,A
  LD HL,ImTable
  LD DE,ImTable+1
  LD BC,$0100
  LD (HL),$FF
  LDIR
  LD A,$18
  LD (ImJr),A
  LD A,$C3
  LD (ImJump),A
  LD HL,Interrupt
  LD (ImJump+1),HL
  IM 2
  XOR A
  LD (ZoneAttrs),A
  LD (Zone1AttrsLeftover),A
  LD (Zone2Attrs),A
  LD (Zone3Attrs),A
  CALL KempstonTest
  JP NZ,GameStart
  XOR A
  LD (ControlMethod),A
  JP GameStart

; A new game: Matt in room 0, full energy, empty masks, the pick-ups and the
; maps restored
;
; Room 0, screen 0 (RoomNumber $950A, RoomScreen $950D); Energy $AEA6 = $FF;
; Matt (Objects $A43F) at x $48, y $28, state $0B, facing right; clears bit 7
; (taken) of every PickupTable $950E record; empties the four MaskSlots $AF2B
; and selects the first; ShowMaskName EMPTY; turns the map blocks $2B back to
; $12 and $47 back to $1B in RoomMaps $7600-$84FF; clears the end-of-level and
; effect flags and the Score $AE41. BuildTables $A860 makes the sprite tables
; first. Ends in DrawRoom $A89D and PasswordPods $ACBC.
;
; Witness: L1 16 (c1, door, play2, rzx- x8).
NewGame:
  DI
  POP HL
  LD SP,StackTop
  PUSH HL
  EI
  CALL BuildTables
  XOR A
  LD (RoomNumber),A
  LD (RoomScreen),A
  OR $FF
  LD (Energy),A
  LD (MapPointer+$0002),A
  LD (Objects+$0002),A
  LD (Objects+$001F),A
  LD A,$48
  LD (Objects+$0003),A
  LD A,$28
  LD (Objects+$0004),A
  LD A,$04
  LD (Objects+$0005),A
  LD HL,MattRun
  LD (Objects+$0016),HL
  LD A,$0B
  LD (Objects),A
  LD A,$01
  LD (Objects+$0002),A
  LD HL,PickupTable
  LD DE,$0004
l_919F:
  LD A,(HL)
  CP $FF
  JR Z,l_91A9
  RES 7,(HL)
  ADD HL,DE
  JR l_919F
l_91A9:
  LD IX,MaskSlots
  LD DE,$0004
  LD B,$04
  XOR A
l_91B3:
  LD (IX+$01),A
  LD (IX+$02),A
  ADD IX,DE
  DJNZ l_91B3
  LD HL,MaskSlots
  LD (CurrentSlot),HL
  CALL DrawAllSlots
  LD A,$01
  LD (MaskNameShown),A
  LD HL,Room0Map
  LD BC,$0F00
l_91D1:
  LD A,(HL)
  CP $2B
  JP NZ,l_91DB
  LD (HL),$12
  JR l_91E2
l_91DB:
  CP $47
  JP NZ,l_91E2
  LD (HL),$1B
l_91E2:
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_91D1
  XOR A
  LD (ChaserState),A
  LD (DeathFlag),A
  LD (DissolveCount),A
  LD (Dying),A
  LD (PenetratorOn),A
  LD HL,Score
  LD B,$04
l_91FE:
  LD (HL),A
  INC HL
  DJNZ l_91FE
  CALL DrawRoom
  JP PasswordPods

; Never run: DI, then flash the border forever (the kind-0 slot of ObjectJumps
; $C326 jumps here)
;
; XOR 7, OUT ($FE), JP HangLoop. Known only from the code.
HangLoop:
  DI
  XOR $07
  OUT ($FE),A
  JP HangLoop

; BorderFlash
BorderFlash:
  DEFB $C5,$F5,$01,$B8,$0B,$3C,$E6,$07 ; never run: flash the border BC times
  DEFB $D3,$FE,$0B,$78,$B1,$20,$F6,$F1
  DEFB $C1,$C9

; The tune to start (1-4; 0 none), read by Interrupt on a 128K
TuneRequest:
  DEFB $00
StopRequest:
  DEFB $FF                ; non-zero: MusicStop $C00A at the next interrupt
FrameCounter:
  DEFB $00                ; counted up by every interrupt
BorderColour:
  DEFB $00                ; sent to $FE by every interrupt
