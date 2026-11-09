; --------------------------------------------------------------------------------------------------------------------
; variables.asm: Variables: the buggy, the scrolling layers, the course state, the menus and the two player records
;
; All of $B212-$B2C1 is game state; the loaded image holds the values the build had when it was saved, and the code
; sets most of them before use. A variable's readers and writers are given as code sites; the routines there are named
; by their address.
; --------------------------------------------------------------------------------------------------------------------

; The buggy's pixel line (top of its sprite), $92 at each life start
;
; Set with BuggyX at the life start ($90EB LD HL,$3892; $90EE: y $92, x $38)
; and by the jump in the buggy routine at $AA0F ($AA46, $AA79); read as a pair
; with BuggyX by the main loop ($96C5), by the shots ($AD0E) and by every
; object handler that tests a hit against the buggy ($99F0, $9E1F, $9EEA,
; $9FCA, $A0BB, $A1C4, $A34C).
BuggyY:
  DEFB $00

; The buggy's x in pixels (left edge), $38 at each life start
;
; Read by the object handlers to place or aim at the buggy ($9A2F, $9ACA,
; $9B27, $9F29, $9FF7, $A10E).
BuggyX:
  DEFB $00

; The buggy's collision box height, $0D
;
; Read with BuggyBoxWidth by the box test at $A7FE; never written.
BuggyBoxHeight:
  DEFB $0D

; The buggy's collision box width, $1D
;
; Read by the box test at $A7FE; never written.
BuggyBoxWidth:
  DEFB $1D

; $FF while the buggy lives; 0 when hit, then 1-8 through the explosion frames
;
; Set to $FF at the life start ($90E5), to 0 by the routine at $A7DD (a hit).
; The buggy routine at $AA0F counts it up and draws sprite $1E + DeathStep; the
; main loop ($96BE) ends the life when it reaches 8. Every hazard handler reads
; it to stop hitting a dead buggy ($99DE, $9A61, $9A9B ...).
DeathStep:
  DEFB $FF

; The wreck pieces' step after a death
;
; Set to $FF at the life start ($90E8), set at a hit ($A7E5) and by the main
; loop ($96D6); counted by the wreck routine at $AB37 ($AB3C, $AC18, $AC1C).
WreckStep:
  DEFB $FF

; Pointer into the wreck pieces' flight path at $AC31
;
; Set at $AB5C, read through IX at $AB5F, moved on at $AC14.
WreckPath:
  DEFW $0000

; Wreck piece 1's position (low byte y, high byte x)
;
; Set at $AB4A, read and moved at $AB63-$AB92 by the wreck routine at $AB37.
WreckPiece1:
  DEFW $0000

; Wreck piece 2's position
;
; $AB50, $AB9E-$ABCD.
WreckPiece2:
  DEFW $0000

; Wreck piece 3's position
;
; $AB56, $ABD9-$AC08.
WreckPiece3:
  DEFW $0000

; $FF from the buggy's death to the next life start, 0 while it lives
;
; Set by the buggy routine at $AAA1, cleared at the life start ($90F7). While 0
; the shots move with the ground ($AD72, $ADC3 read it).
DeadFlag:
  DEFB $00

; Pointer into the jump arc table at $AF68 during a jump
;
; Set at $AF5E when the jump starts; read each pass by $AA2E.
JumpArc:
  DEFW $0000

; The jump's step, $FF on the ground
;
; Set at the life start ($90E2); read and written by the buggy routine at $AA0F
; ($AA1F-$AA49).
JumpStep:
  DEFB $00

; Passes left to the next 1-pixel scroll of the hills layer
;
; Set at $9568 and $A873, counted at $A84B by the hills scroller at $A846 (one
; scroll every 8 passes).
HillsCountdown:
  DEFB $00

; The hills layer's step, 1; never written
;
; Read by $AF82 (the shots' drift).
HillsSpeed:
  DEFB $01

; Pointer to the next column of HillsStrip $EBC0 to feed in
;
; Set at $956E; read and moved by the scroller at $A851/$A865, wrapping from
; $F000 to $EBC0.
HillsColumn:
  DEFW $0000

; Passes left to the next 2-pixel scroll of the middle layer (mountains or
; city)
;
; Set at $9565 and $A8C8, counted at $A89F by the scroller at $A89A (one scroll
; every 4 passes).
MiddleCountdown:
  DEFB $00

; The middle layer's step, 2; never written
;
; Read by $AF8B and $AFA0.
MiddleSpeed:
  DEFB $02

; Pointer to the next column of the middle strip to feed in
;
; Set at $9561; read and moved at $A8A5/$A8BA.
MiddleColumn:
  DEFW $0000

; The middle strip's first column: MountainsStrip $E340 or MoonBaseStrip $E780
;
; Set by the routine at $9541 ($9559) from the scenery byte; read at $957A and
; $A8B7 (the wrap).
MiddleStart:
  DEFW $0000

; The middle strip's end, compared at $A8AC
;
; Set at $955D.
MiddleEnd:
  DEFW $0000

; Pointer to the scenery's colour set at $9617 or $961C
;
; Set by the routine at $95B0 ($95BC); read through IX by $95F2 and by the
; handlers that colour sprites ($A053, $A12C, $A148, $A165 ...).
ColourScheme:
  DEFW $0000

; Pointer to the ground's current height profile
;
; Set at the life start ($9111) and by the crater handler ($9AB4, $9AC5); read
; by the ground scroller at $A93D.
GroundProfile:
  DEFW $0000

; The ground scroller's pass counter
;
; Set at $90FA; read and written at $A937/$A94B.
GroundCountdown:
  DEFB $00

; The ground's step in pixels a pass, 4; never written
;
; Read by every handler that moves an object with the ground ($99E4, $9A67,
; $9AA2, $9B1E, $9EDE, $9F71 ...).
GroundSpeed:
  DEFB $04

; The UFO wave's state, set by the UFO commands and by the UFO handler
;
; Written at $9833 and $9B84; read at $9862, $987F, $9C0E, $9C52 ...
UfoWave:
  DEFB $00

; $FF: the UFOs fly off (the course command at $98AA); 0 at the life start
;
; Set at $90F4, $9B99 and $9EAF; read by the UFO handler at $9BE6.
UfosLeave:
  DEFB $00

; Nonzero: the main loop does not run the object list
;
; Set at $819E (the demo's start, $80) and $969B; read by $9745.
ObjectsOff:
  DEFB $00

; Nonzero once this second's time is on screen; cleared each second
;
; Cleared by the interrupt routine at $7FAE when FrameCount reaches 50; set at
; $9223 after the time is printed; tested at $922A.
TimeShown:
  DEFB $00

; The key read by the tape menu at $8282, tested at $8309
TapeKey:
  DEFB $00

; A pass counter; its bit 2 blinks the mines
;
; Incremented by the main loop ($96E3); read by the mine handler ($9B42):
; sprite $11 + bit 2.
PassCount:
  DEFB $00

; Passes left before the course script runs its next segment
;
; Set by the script command at $976C ($9770); counted down by the main loop
; ($96E7/$96EB).
SegmentWait:
  DEFW $0000

; The next word of Tune $B4E6
;
; Set at the life start ($9117); read and moved by the interrupt routine
; ($7F52, $7F60), reset to the start at $FFFF ($7F70).
TunePointer:
  DEFW $0000

; Interrupts left before the next note (one note every 3)
;
; Set at $90FD; counted at $7F47 and $7FA1.
TuneDivider:
  DEFB $00

; The sector's par time, 2 BCD digits big-endian (minutes digits), from the
; SectorEnd command
;
; Set at $A4F2; read at $A531 and $A584.
SectorTime:
  DEFW $0000

; The sector's best time so far (BCD), from the SectorEnd command
;
; Set at $A507; read at $A53D, $A632, $A64A.
BestTime:
  DEFW $0000

; The sector's bonus points (BCD hundreds) and the extra byte after it
;
; Set at $A4FA; read at $A54F, $A55B, $A5D0; rewritten at $A5B6. $A5BA reads
; its second byte ($B246).
SectorBonusPoints:
  DEFW $0000

; The copier $AFAB's first line
;
; Set as a pair with BlitBottom ($801B, $802D, $9157); read at $AFAB.
BlitTop:
  DEFB $00

; The copier's line after the last; read at $AFD5
BlitBottom:
  DEFB $00

; The copier's x in pixels (the byte column is BlitX / 8)
;
; Set with BlitWidth ($8021, $8033, $915D); read at $AFB4.
BlitX:
  DEFB $00

; The copier's width in bytes; read at $AFCD
BlitWidth:
  DEFB $00

; The initials entry field: number of characters
;
; The field $B24B-$B24F is filled from a 5-byte block by $8C06 / $8E99 / $8EB9
; (LD DE,$B24B; LDIR) and read at $8CD0, $8D6F, $8D8A.
EntryLength:
  DEFB $00

; The entry field's buffer pointer; read at $8CDA, $8D82, $8D87, $8DAC
EntryBuffer:
  DEFW $0000

; The entry field's pixel line; read at $8C9C, $8CCA
EntryY:
  DEFB $00

; The entry field's x; read at $8CC4
EntryX:
  DEFB $00

; Pointer to the heroes table slot being written
;
; Set at $8C2E, $8C71, $8EE7; read at $8C44, $8C87, $8EEF.
HeroSlot:
  DEFW $0000

; Heroes table work byte; with HeroIndex it is saved as a word
;
; $8EE3 LD ($B252),DE and $8EFB LD DE,($B252) keep DE here across the slot
; search loop $8EEA-$8EFF; $8CD3 reads it through HL.
HeroCount:
  DEFB $00

; The heroes table's index; read at $8CDE, $8D03
HeroIndex:
  DEFB $00

; The entry field's cursor position
;
; Read and written at $8CE1-$8D76.
EntryCursor:
  DEFB $00

; The title frame's colour step, read and moved at $884D/$8853
TitleColour:
  DEFB $00

; The score advance table's row
;
; $8A52, $8A9C, $8AEF, $8B07, $8B50, $8B63.
TableRow:
  DEFB $01

; Number of players, 1 or 2
;
; Set by the options page ($80DF); read at $8083, $80D3, $8F61, $8F8B, $8FB3
; ...
Players:
  DEFB $01

; The course: 1 Beginner, 2 Champion
;
; Set at $80F6; read at $808B, $80EA, $8F32.
Course:
  DEFB $01

; The control type, 1-6 (keys or a joystick)
;
; Set at $810D; read at $8093, $8101, $8231 and by the controls reader at
; $AE1C.
Controls:
  DEFB $06

; Colour of the players option line, moved through the cycle at $8408 by $8349
;
; Set at $8076; read at $80B7 (LD DE,$B25A), $80CF.
OptionColour1:
  DEFB $06

; Colour of the course option line; $807B, $80E6
OptionColour2:
  DEFB $46

; Colour of the controls option line; $8080, $80FD
OptionColour3:
  DEFB $04

; BASIC's stack pointer, saved at the start ($8000)
;
; Restored at $8004, $8240, $8253, $831A ...; $80BA reads it through IX.
BasicStack:
  DEFW $0000

; The main loop's stack pointer, saved at $9696
;
; Restored at $A689 (life end), $BB1D and $BEE9 (the course switches
; BeginnerToChampion and ChampionToBeginner).
LoopStack:
  DEFW $0000

; Where the next object record is written in ObjectList $BEF8
;
; Set at $96A1; moved by the script commands ($96AA/$96B4) and by $9DAD/$9DC6.
ObjectWrite:
  DEFW ObjectList

; The stack pointer saved around a tape load or save
;
; Set at $826B; restored at $827A, $82A4, $82B5, $8304.
TapeStack:
  DEFW $0000

; BASIC's ERR_SP handler, saved around a tape load or save
;
; Set at $8277; read at $82A0, $82B1, $8300.
TapeErrSp:
  DEFW $0000

; Written by the UFO handler ($9C75); never read
;
; The bytes $B267-$B270 are write-only flags, one set by each object kind when
; it first runs; nothing reads them. $B268, $B269 and $B26B are never touched.
UfoSeen:
  DEFB $00

; Never read or written
UnusedFlag1:
  DEFB $00,$00

; Written by the plant handler ($A390); never read
PlantSeen:
  DEFB $00

; Never read or written
UnusedFlag2:
  DEFB $00

; Written by the low flyer handler ($A107); never read
FlyerSeen:
  DEFB $00

; Written by the UFO handler ($9B96); never read
UfoWaveSeen:
  DEFB $00

; Written by the boulder handler ($A213); never read
BoulderSeen:
  DEFB $00

; Written by the rock handler ($9A28); never read
RockSeen:
  DEFB $00

; Written by the tank handler ($9F22); never read
TankSeen:
  DEFB $00

; The current player's record, 27 bytes: number, score, extra-life mark, course
; state, lives, time, flags, initials
;
; The player playing is always here; with two players the routine at $9022
; swaps it with OtherPlayer $B28C through SwapBuffer $B2A7 (three LDIRs of 27
; bytes). +0 is the player's number (1 or 2), printed at $8F80.
Player:
  DEFB $01
PlayerScore:
  DEFB $00                ; +1: the score, 4 BCD bytes big-endian (8 digits)
  DEFB $00
  DEFB $00
  DEFB $00
PlayerNextLife:
  DEFB $00                ; +5: the score of the next extra life, 4 BCD bytes
  DEFB $00                ; (00 01 00 00 = 10000 at the start, +20000 after
  DEFB $00                ; each; none once the score's second byte $B273
  DEFB $00                ; reaches 6)
PlayerCourse:
  DEFB $00                ; +9: the course script pointer (word)
  DEFB $00
PlayerPoint:
  DEFB $00                ; +$0B: the point letter code reached (+$20 on the
                          ; Champion course)
PlayerScenery:
  DEFB $00                ; +$0C: the scenery, 0 mountains, $FF moon base city
PlayerLights:
  DEFB $00                ; +$0D: the warning lights state, drawn by $927E
PlayerRestart:
  DEFB $00                ; +$0E: the script pointer a new life restarts from
  DEFB $00                ; (word)
PlayerSegment:
  DEFB $00                ; +$10: the script pointer of the current point
  DEFB $00                ; (word)
PlayerActive:
  DEFB $00                ; +$12: nonzero while this player still has lives
                          ; (word; $8F6B clears the other player's in a
                          ; one-player game)
PlayerLives:
  DEFB $00                ; +$13: lives left (4 at the start, decremented at
                          ; $8F74)
PlayerTime:
  DEFB $00                ; +$14: the sector time, 2 BCD bytes
  DEFB $00
PlayerFrames:
  DEFB $00                ; +$16: interrupts counted to 50 for each second
PlayerFlags:
  DEFB $00                ; +$17: bit 0 the T key's latch, bit 1 the fire
                          ; latch, bit 3 set by the mine and plant handlers
                          ; ($9B15, $A30B; read by the ground at $A994), bit 4
                          ; hold, bit 7 tune off (the T key toggles it, $AF27;
                          ; the demo sets it, $8199)
PlayerInitials:
  DEFB $4A                ; +$18: three initials ("JAS" in the image)
  DEFB $41
  DEFB $53

; The other player's record, same layout as Player $B271 (player 2, initials
; "MIK" in the image)
OtherPlayer:
  DEFB $02
  DEFB $00                ; score
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00                ; next extra life
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00                ; course state, lights, pointers, active, lives,
  DEFB $00                ; time, flags
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $4D                ; initials
  DEFB $49
  DEFB $4B

; 27 bytes used by the routine at $9022 to swap Player and OtherPlayer
SwapBuffer:
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
