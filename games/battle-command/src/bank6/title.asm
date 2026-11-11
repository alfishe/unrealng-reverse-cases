; --------------------------------------------------------------------------------------------------------------------
; title.asm: The title menu: the title picture, the turning tank, the three choices
;
; TitleMenu $C409 is the first screen (ScreenList node $74E8, zones TitleZones $C4E9); Entry $68F4 jumps here. It
; unpacks PicTitle ($F4E1 of bank 7), adds three graphics, and runs a 3D window in which the tank turns (Bank4Start
; $72C6, the model run by Bank3Render $72BE) until a zone is clicked: the catalogue, the options or the password.
; --------------------------------------------------------------------------------------------------------------------

  ORG $C409

; The title menu: picture, graphics, pointer, then the turning model until a
; zone is clicked
;
; Sound off (Bank0SoundOff `$72DE`), the shadow screen, the view parameters
; (`$9A6C`, `$9A8E`, `$9AB3`, `$9ABB`), DrawBank7Picture `$74AA` with `$F4E1`,
; CopyGraphic of TitleGraphicA, TitleGraphicB and TitleGraphicC, the attributes
; `$5920-$5A1F` to `$47`, the title's pointer limits, the pointer centred, the
; wide blit (`$83E6` = `$8A41`), SetTitleWindow `$D10E`, Bank4Start `$72C6`,
; TitleBox.
;
; TitleLoop: StartViewPass `$9882`, the model through Bank3Render `$72BE` (IX =
; `$CA8B` of bank 3), RequestViewBlit `$988D`, the turn (`$68E7` += 6),
; PointerZones `$6D42`, until the view flag `$6A6D` is set; then
; ShowWaitPointer, WaitFrameDone, Bank4Call and NextView `$6A91`. Witness: L1
; 19 (c1, m2erbe, menu, missions, play, play2).
TitleMenu:
  CALL $72DE
  CALL $7268
  XOR A
  LD ($83BF),A
  LD ($7256),A
  LD ($9A93),A
  LD HL,$0000
  LD ($9A8E),HL
  LD HL,$FFF1
  LD ($9AB3),HL
  LD HL,$015E
  LD ($9A6C),HL
  LD HL,$0028
  LD ($9ABB),HL
  LD DE,TitleGraphicC+$0055
  CALL $74AA
  LD HL,TitleGraphicA
  LD D,$0B
  LD C,$10
  EXX
  LD C,$00
  LD A,$B0
  CALL $6D7F
  LD HL,TitleGraphicB
  LD D,$0B
  LD C,$10
  EXX
  LD C,$15
  LD A,$B0
  CALL $6D7F
  LD HL,TitleGraphicC
  LD D,$08
  LD C,$10
  EXX
  LD C,$0C
  LD A,$B0
  CALL $6D7F
  LD HL,$5920
  LD BC,$0100
  LD E,$47
TitleAttrLoop:
  LD (HL),E
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,TitleAttrLoop
  LD HL,TitleLimits
  CALL SetPointerLimits
  LD A,$80
  LD ($7DC0),A
  LD ($9715),A
  LD ($7DC1),A
  LD ($9716),A
  CALL $897E
  CALL CataloguePointerLimits
  LD HL,$8A41
  LD ($83E6),HL
  CALL SetTitleWindow
  CALL $988D
  CALL SavePointerBackground
  LD A,$FF
  LD ($83BF),A
  LD ($757A),A
  CALL $72C6
  LD HL,TitleBox
  CALL $6CFB

; TitleLoop
TitleLoop:
  CALL $9882
  LD IX,StoresScreen
  CALL $72BE
  CALL $988D
  LD HL,$68E7
  LD A,(HL)
  ADD A,$06
  LD (HL),A
  CALL $6D42
  CALL $7E7A
  CALL $7256
  LD A,($6A6D)
  AND A
  JR Z,TitleLoop
  CALL ShowWaitPointer
  CALL $7225
  CALL $72E9
  JP $6A91

; Zone table of the mission status screen: x1, x2, y1, y2, routine
;
; Read by PointerZones `$6D42` on MissionStatusScreen (node `$756A`):
; ScreenZero `$705A` (ShowPassword) and ScreenTwo `$705E` (back to the
; catalogue). A 0 ends it.
StatusScreenZones:
  DEFB $9B,$EC,$1B,$24,$5A,$70
  DEFB $9B,$E4,$33,$4C,$5E,$70
  DEFB $00

; Zone table of the title menu
;
; ScreenZero (the catalogue), `$67EE` (ApiVector16, ScreenFour: the options)
; and ScreenTwo (the password entry).
TitleZones:
  DEFB $08,$52,$B4,$B8,$5A,$70
  DEFB $62,$9D,$B4,$B8,$EE,$67
  DEFB $AB,$F7,$B4,$B8,$5E,$70
  DEFB $00
