; --------------------------------------------------------------------------------------------------------------------
; missionload.asm: The mission load: the header, the block, the play state it sets
; --------------------------------------------------------------------------------------------------------------------

  ORG $84C1

; The mission load: the same mission again from bank 3's copy, or the tape's
; next mission block
;
; Pages bank 0, `$CC1E` with IX = `$75F0`; clears `$BA27`, `$CEA8`, `$87FD`,
; `$C4DC`. If the mission asked for (`$757D`) is the one loaded last (`$7E2E`),
; the bank-3 copy of `$DBDA`... is copied back to bank 0 (no tape). Else
; `$8551`: load the 17-byte header with "MISSHDR:" (`$84FE`), then the block of
; the header's length to `$DBC5`; SPACE stops. Then `$85F5` and `$8598` set the
; play state from the block. Witness: L1 16 (m10, m2erbe, m2ocean, missions).
LoadMission:
  CALL PageBank0
  LD IX,ObjectTable
  CALL ResetPlayerHandler
  XOR A
  LD (l_BA1F+$0008),A
  LD (ToggleBinoculars+$0001),A
  LD (NightKey+$0001),A
  LD (l_C4DB+$0001),A
  LD A,(LastLoadedMission)
  LD C,A
  LD A,(ScreenOfMission+$0001)
  CP C
  JR NZ,LoadMissionTape
  LD HL,(MissionHeader+$0015)
  LD DE,$0000
RestoreFromBank3:
  CALL PageBank3
  LD A,(HL)
  EX AF,AF'
  CALL PageBank0
  EX AF,AF'
  LD (HL),A
  INC HL
  DEC DE
  LD A,D
  OR E
  JR NZ,RestoreFromBank3
  CALL MissionTimeSetup
  JP MissionSetup

; Load 17-byte headers until one is "MISSHDR:"; its length to $855C, its digit
; - "1" to $757D, the mark on the clipboard
;
; Witness: L1 21 (m10, m2erbe, m2ocean, missions, search).
LoadMissionHeader:
  DI
  CALL Delay
l_8502:
  LD IX,BackBuffer
  LD DE,$0011
  LD A,$FF
  SCF
  CALL LoadBlock
  JR C,l_8516
  JR Z,l_8502
  JP PageBank6
l_8516:
  CALL IsMissionHeader
  JR NZ,l_8502
  LD DE,(BackBuffer+$000B)
  LD (LoadMissionBlock+$0001),DE
  LD A,(BackBuffer+$0009)
  SUB $31
  LD (ScreenOfMission+$0001),A
  LD (HeaderMission),A
  LD HL,$58E3
  LD (HL),$4D
  LD C,$C4

; The attribute C on the catalogue line of mission A ($5902 + 32A)
;
; Witness: L1 24 (m10, m2erbe, m2ocean, missions, search).
MarkMission:
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  LD H,$00
  LD L,A
  ADD HL,HL
  LD DE,$5902
  ADD HL,DE
  LD (HL),C
  LD (l_8516+$0019),HL
  EI
  RET

; HeaderMission
HeaderMission:
  DEFB $FF                ; the mission of the last header (a byte, $FF none)

; Mark the last header's mission again ($C4) unless none
;
; Witness: L1 32 (menu, missions, search).
RemarkMission:
  LD A,(HeaderMission)
  AND A
  RET M
  LD C,$C4
  JR MarkMission
; This entry point is used by the routine at LoadMission.
LoadMissionTape:
  DI
  CALL PageBank6
  CALL Delay
  CALL PageBank0
LoadMissionBlock:
  LD DE,$0000             ; LD DE,n: n ($855C) the header's length
  LD IX,MissionHeader
  LD A,$FF
  SCF
  CALL LoadBlock
  JR C,MissionBlockLoaded
  CALL SpacePressed
  JR C,LoadMissionBlock
  RET
MissionBlockLoaded:
  LD A,(MissionHeader)
  LD (AwolState+$0003),A
  CALL MissionTimeSetup
  LD DE,(MissionHeader+$0015)
  LD HL,(MissionHeader+$0028)
  AND A
  SBC HL,DE
  EX DE,HL
  LD (LoadMission+$0025),DE
l_8588:
  LD A,(HL)
  EX AF,AF'
  CALL PageBank3
  EX AF,AF'
  LD (HL),A
  INC HL
  CALL PageBank0
  DEC DE
  LD A,D
  OR E
  JR NZ,l_8588

; From the loaded block: 12 bytes to $7E82, $DBFD to $CAAF, the object count to
; bank 6, the objects copied to bank 3
;
; Witness: L1 3 (m2erbe, missions).
MissionSetup:
  XOR A
  LD (WeaponVars+$0002),A
  LD HL,MissionHeader+$002C
  LD DE,MissionParams
  LD BC,$000C
  LDIR
  XOR A
  LD (PlaceHelicarrier),A
  LD A,$C9
  LD (StartMission+$0007),A
  LD A,(MissionHeader+$0038)
  LD (PlayerHit+$000A),A
  LD A,(MissionHeader+$0017)
  LD E,A
  CALL PageBank6
  LD HL,MissionHeader+$002E
  LD (HL),E
  CALL PageBank0
  LD L,E
  LD H,$00
  ADD HL,HL
  LD B,H
  LD C,L
  ADD HL,HL
  ADD HL,BC
  LD BC,$0080
  ADD HL,BC
  EX DE,HL
  LD HL,MissionHeader+$003B
l_85D4:
  LD A,(HL)
  EX AF,AF'
  CALL PageBank6
  EX AF,AF'
  LD (HL),A
  INC HL
  CALL PageBank0
  DEC DE
  LD A,D
  OR E
  JR NZ,l_85D4
  LD A,(ScreenOfMission+$0001)
  LD (LastLoadedMission),A
  CALL PageBank6
  SCF
  RET

; NC when SPACE is held (port $7FFE bit 0)
;
; Witness: L1 8 (m2ocean, missions).
SpacePressed:
  LD A,$7F
  IN A,($FE)
  RRA
  RET

; From the header: $DBE1 to $6A67, 8 bytes $DBE3 to $7611, the time limit $DBFE
; to $68EB, the clock stopped
;
; Witness: L1 15 (m10, m2erbe, m2ocean, missions).
MissionTimeSetup:
  LD HL,(MissionHeader+$001C)
  LD (PlayLoopTail+$0010),HL
  LD HL,MissionHeader+$001E
  LD DE,PlayerHandler+$0009
  LD BC,$0008
  LDIR
  LD HL,(MissionHeader+$0039)
  LD (MissionClock+$0001),HL
  XOR A
  LD (MissionClock),A
  LD A,$C9
  LD (ClockTick),A
  SCF
  RET
