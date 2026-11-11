; --------------------------------------------------------------------------------------------------------------------
; ending.asm: The game over, the space scene and the ending
; --------------------------------------------------------------------------------------------------------------------

  ORG $916A

; Swap ink and paper in the play window's attributes
;
; XORs every attribute of `$5800-$59FF` (character rows 0-15, the play window)
; with `$3F`: ink 7-ink, paper 7-paper, BRIGHT and FLASH kept. Called twice it
; restores the screen.
;
; The only callers are `JP $916A` at `$B1E8` and `CALL $916A` at `$B1EE`, in
; the ending's code after `$B0B6`: not executed in any recording (rzx50000 runs
; the ending from `$B0B6` to `$B169`); known only from the code.
;
; Witness: L1 0 ().
InvertPlayWindow:
  LD HL,Attributes
  LD B,$00
  LD E,$3F
InvertPlayWindowLoop:
  LD A,(HL)
  XOR E
  LD (HL),A
  INC HL
  LD A,(HL)
  XOR E
  LD (HL),A
  INC HL
  DJNZ InvertPlayWindowLoop
  RET

  ORG $B0B6

; The room handler of room $28: the asteroid falls on the building; deflected
; (the ending) or not (the loss) (SK "warp fanfare", renamed)
;
; IY = object 1 ($5B08). RoomStep $5C41 steps: 0 sets the asteroid (object 1 at
; $A2, $04, frame $75), the building at the bottom (objects 2 and 3 at Y $68,
; frames $72 and $71) and, when $5BFE is set (the deflector), object 4 at $89,
; $5C. 1: the asteroid moves 1 left, 4 down a pass to Y $54. With the
; deflector: object 4's frame + 1, sound 2, step 3: the asteroid goes back 4
; left, 1 up a pass and vanishes at X 4. Without: the asteroid hidden, object 2
; frame $76, then $77 (the strike), sound 1. Then the step counts to $80 and
; GameOver $5BFF = 1.
;
; Evidence: gameover frames 1516-1959 (no deflector, the strike, after the last
; life); rzx50000 frames 194-729 (the deflector, GameOver at 729).
;
; Witness: L1 327 (gameover, rzx).
SpaceScene:
  LD IY,ObjectSlot1
  LD HL,RoomStage
  LD A,(HL)
  OR A
  JR NZ,SpaceAsteroidIn
  INC (HL)
  LD (IY+$00),$A2
  LD (IY+$01),$04
  LD (IY+$02),$75
  LD (IY+$04),$89
  LD (IY+$05),$68
  LD (IY+$06),$72
  LD (IY+$07),$00
  LD (IY+$08),$71
  LD (IY+$09),$68
  LD (IY+$0A),$71
  LD (IY+$0B),$00
  LD A,(GameWon)
  OR A
  RET Z
  LD (IY+$0C),$89
  LD (IY+$0D),$5C
  LD (IY+$0E),$6F
  LD (IY+$0F),$00
  RET
SpaceAsteroidIn:
  DEC A
  JR NZ,SpaceExplode
  DEC (IY+$00)
  LD A,(IY+$01)
  ADD A,$04
  LD (IY+$01),A
  CP $54
  RET NZ
  INC (HL)
  LD A,(GameWon)
  OR A
  JR Z,SpaceStrike
  INC (HL)
  INC (IY+$0E)
  LD A,$02
  JP PlaySound
SpaceStrike:
  LD (IY+$06),$76
  LD (IY+$02),$7F
  RET
SpaceExplode:
  DEC A
  JR NZ,SpaceDeflect
  LD A,(IY+$06)
  CP $77
  JR Z,SpaceExplodeEnd
  INC (IY+$06)
  RET
SpaceExplodeEnd:
  INC (HL)
  INC (HL)
  LD A,$01
  JP PlaySound
SpaceDeflect:
  DEC A
  JR NZ,SpaceWait
  DEC (IY+$01)
  LD A,(IY+$00)
  SUB $04
  LD (IY+$00),A
  CP $04
  RET NC
  LD (IY+$02),$7F
  DEC (IY+$0E)
  INC (HL)
  RET
SpaceWait:
  INC (HL)
  RET P
  LD A,$01
  LD (GameOver),A
  RET
