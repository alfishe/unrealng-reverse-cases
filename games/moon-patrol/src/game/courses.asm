; --------------------------------------------------------------------------------------------------------------------
; courses.asm: Courses: the Beginner and Champion course scripts and the two course switches
;
; A course is a script of threaded words run by the interpreter at $9751: each word is the address of a command
; routine, and the command takes its parameters from the bytes after it. A segment runs until its End word ($9760);
; the main loop starts the next one when SegmentWait $B23C runs out. The commands: $976C Wait (a word: passes before
; the next segment), $9775 Point (delay byte, point letter code: the record at $9978 stores the code in PlayerPoint
; and the restart pointers), $97AD Lights (pairs of delay and lights state 0-3, $FF ends; the record at $99A3 stores
; PlayerLights and draws it at $927E), $97C5 Rocks, $97E8 Craters, $97FF Mines (byte AND $7F = delay, bit 7 = the
; other mine kind), $9821 / $9827 / $982D UFOs of kind 1 / 5 / $0B (UfosA, UfosB, Spinners), $98AA UfosLeave (one
; delay byte), $98BE Tanks, $98F3 LowFlyers, $9917 / $991C / $9921 small / medium / big boulders, $9955 Plants: each
; list command takes delay bytes until $FF and writes one object record per byte into ObjectList $BEF8; the delay is
; the record's countdown before the object appears. $A4EE SectorEnd ends a sector: par time (2 BCD bytes), bonus (1
; BCD byte of hundreds), scenery ($FF city, 0 mountains), best time (2 BCD bytes, a word the code rewrites when
; beaten), then the next segment.
;
; Below, each segment is labelled with the point it starts at and the first frame the point letter changes in the
; immune recording (i1 for Beginner, i2 for Champion); the commands are listed with their delay bytes in decimal.
; --------------------------------------------------------------------------------------------------------------------

; The Beginner course script, points A-Z in five sectors (E, J, P, U, Z)
;
; Chosen by the game start ($8F2F LD BC,$B7E8) and by ChampionToBeginner $BED4;
; i1 plays it to Z. The first segment (i1 frame 160): Wait 127; Craters 20 80;
; Rocks 50 110.
;
; BeginnerBestE $B884: the best time for the sector to E, BCD, rewritten when
; beaten
;
; BeginnerAfterE $B886: the segment after the sector end
;
; BeginnerBestJ $B925: the best time for the sector to J, BCD, rewritten when
; beaten
;
; BeginnerAfterJ $B927: the segment after the sector end
;
; BeginnerBestP $B9AE: the best time for the sector to P, BCD, rewritten when
; beaten
;
; BeginnerAfterP $B9B0: the segment after the sector end
;
; BeginnerBestU $BA51: the best time for the sector to U, BCD, rewritten when
; beaten
;
; BeginnerAfterU $BA53: the segment after the sector end
;
; BeginnerBestZ $BB03: the best time for the sector to Z, BCD, rewritten when
; beaten
BeginnerCourse:
  INCBIN "res/courses/BeginnerCourse.bin",$0000,16
BeginnerPointA:
  INCBIN "res/courses/BeginnerCourse.bin",$0010,25
BeginnerPointB:
  INCBIN "res/courses/BeginnerCourse.bin",$0029,28
BeginnerPointC:
  INCBIN "res/courses/BeginnerCourse.bin",$0045,34
BeginnerPointD:
  INCBIN "res/courses/BeginnerCourse.bin",$0067,28
BeginnerPointE:
  INCBIN "res/courses/BeginnerCourse.bin",$0083,19
BeginnerSectorE:
  INCBIN "res/courses/BeginnerCourse.bin",$0096,6
BeginnerBestE:
  INCBIN "res/courses/BeginnerCourse.bin",$009C,2
BeginnerAfterE:
  INCBIN "res/courses/BeginnerCourse.bin",$009E,16
BeginnerPointF:
  INCBIN "res/courses/BeginnerCourse.bin",$00AE,34
BeginnerPointG:
  INCBIN "res/courses/BeginnerCourse.bin",$00D0,30
BeginnerPointH:
  INCBIN "res/courses/BeginnerCourse.bin",$00EE,31
BeginnerPointI:
  INCBIN "res/courses/BeginnerCourse.bin",$010D,32
BeginnerPointJ:
  INCBIN "res/courses/BeginnerCourse.bin",$012D,10
BeginnerSectorJ:
  INCBIN "res/courses/BeginnerCourse.bin",$0137,6
BeginnerBestJ:
  INCBIN "res/courses/BeginnerCourse.bin",$013D,2
BeginnerAfterJ:
  INCBIN "res/courses/BeginnerCourse.bin",$013F,15
BeginnerPointK:
  INCBIN "res/courses/BeginnerCourse.bin",$014E,18
BeginnerPointL:
  INCBIN "res/courses/BeginnerCourse.bin",$0160,20
BeginnerPointM:
  INCBIN "res/courses/BeginnerCourse.bin",$0174,36
BeginnerPointN:
  INCBIN "res/courses/BeginnerCourse.bin",$0198,21
BeginnerPointP:
  INCBIN "res/courses/BeginnerCourse.bin",$01AD,19
BeginnerSectorP:
  INCBIN "res/courses/BeginnerCourse.bin",$01C0,6
BeginnerBestP:
  INCBIN "res/courses/BeginnerCourse.bin",$01C6,2
BeginnerAfterP:
  INCBIN "res/courses/BeginnerCourse.bin",$01C8,17
BeginnerPointQ:
  INCBIN "res/courses/BeginnerCourse.bin",$01D9,36
BeginnerPointR:
  INCBIN "res/courses/BeginnerCourse.bin",$01FD,33
BeginnerPointS:
  INCBIN "res/courses/BeginnerCourse.bin",$021E,27
BeginnerPointT:
  INCBIN "res/courses/BeginnerCourse.bin",$0239,23
BeginnerPointU:
  INCBIN "res/courses/BeginnerCourse.bin",$0250,19
BeginnerSectorU:
  INCBIN "res/courses/BeginnerCourse.bin",$0263,6
BeginnerBestU:
  INCBIN "res/courses/BeginnerCourse.bin",$0269,2
BeginnerAfterU:
  INCBIN "res/courses/BeginnerCourse.bin",$026B,27
BeginnerPointV:
  INCBIN "res/courses/BeginnerCourse.bin",$0286,21
BeginnerPointW:
  INCBIN "res/courses/BeginnerCourse.bin",$029B,21
BeginnerPointX:
  INCBIN "res/courses/BeginnerCourse.bin",$02B0,32
BeginnerPointY:
  INCBIN "res/courses/BeginnerCourse.bin",$02D0,55
BeginnerPointZ:
  INCBIN "res/courses/BeginnerCourse.bin",$0307,14
BeginnerSectorZ:
  INCBIN "res/courses/BeginnerCourse.bin",$0315,6
BeginnerBestZ:
  INCBIN "res/courses/BeginnerCourse.bin",$031B,2
BeginnerSwitch:
  INCBIN "res/courses/BeginnerCourse.bin",$031D,2

; The end of the Beginner course: go on with the Champion course
;
; Run once, in i1 at frames 29659-29663, after point Z: LD A,$20 into
; PlayerPoint (the Champion letters), CALL $93C5 with HL $4000 and C $60, CALL
; $9136, ChampionCourse $BB24 into PlayerCourse, then LD SP,(LoopStack) and JP
; $9696 restart the main loop.
BeginnerToChampion:
  LD A,$20
  LD (PlayerPoint),A
  LD HL,Screen
  LD C,$60
  CALL ClearCells
  CALL HudDraw
  LD HL,ChampionCourse
  LD (PlayerCourse),HL
  LD SP,(LoopStack)
  JP MainLoop

; The Champion course script, points A-Z in five sectors
;
; Chosen by the game start ($8F3A LD BC,$BB24) and by BeginnerToChampion $BB07;
; i2 plays it to Z. The first segment (i2 frame 340): Wait 127; Lights 15:1;
; UfosA 48 48 48; UfosB 48 48 48.
;
; ChampionBestE $BBC7: the best time for the sector to E, BCD, rewritten when
; beaten
;
; ChampionAfterE $BBC9: the segment after the sector end
;
; ChampionBestJ $BC95: the best time for the sector to J, BCD, rewritten when
; beaten
;
; ChampionAfterJ $BC97: the segment after the sector end
;
; ChampionBestP $BD42: the best time for the sector to P, BCD, rewritten when
; beaten
;
; ChampionAfterP $BD44: the segment after the sector end
;
; ChampionBestU $BDF0: the best time for the sector to U, BCD, rewritten when
; beaten
;
; ChampionAfterU $BDF2: the segment after the sector end
;
; ChampionBestZ $BED0: the best time for the sector to Z, BCD, rewritten when
; beaten
ChampionCourse:
  INCBIN "res/courses/ChampionCourse.bin",$0000,23
ChampionPointA:
  INCBIN "res/courses/ChampionCourse.bin",$0017,23
ChampionPointB:
  INCBIN "res/courses/ChampionCourse.bin",$002E,28
ChampionPointC:
  INCBIN "res/courses/ChampionCourse.bin",$004A,33
ChampionPointD:
  INCBIN "res/courses/ChampionCourse.bin",$006B,27
ChampionPointE:
  INCBIN "res/courses/ChampionCourse.bin",$0086,23
ChampionSectorE:
  INCBIN "res/courses/ChampionCourse.bin",$009D,6
ChampionBestE:
  INCBIN "res/courses/ChampionCourse.bin",$00A3,2
ChampionAfterE:
  INCBIN "res/courses/ChampionCourse.bin",$00A5,38
ChampionPointF:
  INCBIN "res/courses/ChampionCourse.bin",$00CB,37
ChampionPointG:
  INCBIN "res/courses/ChampionCourse.bin",$00F0,40
ChampionPointH:
  INCBIN "res/courses/ChampionCourse.bin",$0118,31
ChampionPointI:
  INCBIN "res/courses/ChampionCourse.bin",$0137,33
ChampionPointJ:
  INCBIN "res/courses/ChampionCourse.bin",$0158,19
ChampionSectorJ:
  INCBIN "res/courses/ChampionCourse.bin",$016B,6
ChampionBestJ:
  INCBIN "res/courses/ChampionCourse.bin",$0171,2
ChampionAfterJ:
  INCBIN "res/courses/ChampionCourse.bin",$0173,21
ChampionPointK:
  INCBIN "res/courses/ChampionCourse.bin",$0188,29
ChampionPointL:
  INCBIN "res/courses/ChampionCourse.bin",$01A5,21
ChampionPointM:
  INCBIN "res/courses/ChampionCourse.bin",$01BA,40
ChampionPointN:
  INCBIN "res/courses/ChampionCourse.bin",$01E2,35
ChampionPointP:
  INCBIN "res/courses/ChampionCourse.bin",$0205,19
ChampionSectorP:
  INCBIN "res/courses/ChampionCourse.bin",$0218,6
ChampionBestP:
  INCBIN "res/courses/ChampionCourse.bin",$021E,2
ChampionAfterP:
  INCBIN "res/courses/ChampionCourse.bin",$0220,21
ChampionPointQ:
  INCBIN "res/courses/ChampionCourse.bin",$0235,31
ChampionPointR:
  INCBIN "res/courses/ChampionCourse.bin",$0254,29
ChampionPointS:
  INCBIN "res/courses/ChampionCourse.bin",$0271,24
ChampionPointT:
  INCBIN "res/courses/ChampionCourse.bin",$0289,47
ChampionPointU:
  INCBIN "res/courses/ChampionCourse.bin",$02B8,14
ChampionSectorU:
  INCBIN "res/courses/ChampionCourse.bin",$02C6,6
ChampionBestU:
  INCBIN "res/courses/ChampionCourse.bin",$02CC,2
ChampionAfterU:
  INCBIN "res/courses/ChampionCourse.bin",$02CE,21
ChampionPointV:
  INCBIN "res/courses/ChampionCourse.bin",$02E3,26
ChampionPointW:
  INCBIN "res/courses/ChampionCourse.bin",$02FD,35
ChampionPointX:
  INCBIN "res/courses/ChampionCourse.bin",$0320,47
ChampionPointY:
  INCBIN "res/courses/ChampionCourse.bin",$034F,64
ChampionPointZ:
  INCBIN "res/courses/ChampionCourse.bin",$038F,23
ChampionSectorZ:
  INCBIN "res/courses/ChampionCourse.bin",$03A6,6
ChampionBestZ:
  INCBIN "res/courses/ChampionCourse.bin",$03AC,2
ChampionSwitch:
  INCBIN "res/courses/ChampionCourse.bin",$03AE,2

; The end of the Champion course: start the Beginner course again
;
; Run once, in i2 at frames 30694-30698: XOR A into PlayerPoint, the same two
; calls as BeginnerToChampion, BeginnerCourse $B7E8 into PlayerCourse, the main
; loop restarted.
ChampionToBeginner:
  XOR A
  LD (PlayerPoint),A
  LD HL,Screen
  LD C,$60
  CALL ClearCells
  CALL HudDraw
  LD HL,BeginnerCourse
  LD (PlayerCourse),HL
  LD SP,(LoopStack)
  JP MainLoop

; Leftover: 8 bytes after the scripts ($02 $BB $5A $30 $5F $EE $3D $A8), never
; read
CourseLeftover:
  DEFB $02,$BB,$5A,$30,$5F,$EE,$3D,$A8
