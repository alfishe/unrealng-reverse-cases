; --------------------------------------------------------------------------------------------------------------------
; layouts.asm: The screen table and the 125 screen layouts
; --------------------------------------------------------------------------------------------------------------------

; The 125 screens: the address of each screen's layout, by the screen number
;
; The screen builder BuildScreen reads entry ScreenNumber $8523 ($84D7: BC =
; $C7F4, TableWord HL = the word at BC + 2A). The words point at the layouts in
; ScreenLayouts, in screen order and packed with no gap ($C8EE-$D8DF). The
; round is screens 0-124 (screen 124 walked off ends it, $A867).
ScreenTable:
  DEFW Screen000Layout,Screen001Layout,Screen002Layout,Screen003Layout,Screen004Layout,Screen005Layout,Screen006Layout,Screen007Layout
  DEFW Screen008Layout,Screen009Layout,Screen010Layout,Screen011Layout,Screen012Layout,Screen013Layout,Screen014Layout,Screen015Layout
  DEFW Screen016Layout,Screen017Layout,Screen018Layout,Screen019Layout,Screen020Layout,Screen021Layout,Screen022Layout,Screen023Layout
  DEFW Screen024Layout,Screen025Layout,Screen026Layout,Screen027Layout,Screen028Layout,Screen029Layout,Screen030Layout,Screen031Layout
  DEFW Screen032Layout,Screen033Layout,Screen034Layout,Screen035Layout,Screen036Layout,Screen037Layout,Screen038Layout,Screen039Layout
  DEFW Screen040Layout,Screen041Layout,Screen042Layout,Screen043Layout,Screen044Layout,Screen045Layout,Screen046Layout,Screen047Layout
  DEFW Screen048Layout,Screen049Layout,Screen050Layout,Screen051Layout,Screen052Layout,Screen053Layout,Screen054Layout,Screen055Layout
  DEFW Screen056Layout,Screen057Layout,Screen058Layout,Screen059Layout,Screen060Layout,Screen061Layout,Screen062Layout,Screen063Layout
  DEFW Screen064Layout,Screen065Layout,Screen066Layout,Screen067Layout,Screen068Layout,Screen069Layout,Screen070Layout,Screen071Layout
  DEFW Screen072Layout,Screen073Layout,Screen074Layout,Screen075Layout,Screen076Layout,Screen077Layout,Screen078Layout,Screen079Layout
  DEFW Screen080Layout,Screen081Layout,Screen082Layout,Screen083Layout,Screen084Layout,Screen085Layout,Screen086Layout,Screen087Layout
  DEFW Screen088Layout,Screen089Layout,Screen090Layout,Screen091Layout,Screen092Layout,Screen093Layout,Screen094Layout,Screen095Layout
  DEFW Screen096Layout,Screen097Layout,Screen098Layout,Screen099Layout,Screen100Layout,Screen101Layout,Screen102Layout,Screen103Layout
  DEFW Screen104Layout,Screen105Layout,Screen106Layout,Screen107Layout,Screen108Layout,Screen109Layout,Screen110Layout,Screen111Layout
  DEFW Screen112Layout,Screen113Layout,Screen114Layout,Screen115Layout,Screen116Layout,Screen117Layout,Screen118Layout,Screen119Layout
  DEFW Screen120Layout,Screen121Layout,Screen122Layout,Screen123Layout,Screen124Layout

; The layouts (from screen 0's) of screens 0-124: the objects of each screen, 3
; bytes an object, $FF the end
;
; An object: the row, the column (signed: from $E0 up the object starts off the
; left edge, its glyphs there clipped by PrintChar's bit 5 test), the object
; number. The builder ($84E4-$8507) takes D = row, E = column, the object's
; string from ObjectTable $852E (62 objects, 0-61), $AE1B = 1 (the cells
; solid), $AE21 = 0 (drawn), C = 0, and PrintString draws it; the object's
; string sets its own glyph set ($E6) and colours. Objects per screen: 3-21
; (1319 in all); every one of the 62 objects but [8, 9, 18, 56, 57] is used.
Screen000Layout:
  DEFB $13,$00,$0A
  DEFB $12,$00,$21
  DEFB $02,$00,$02
  DEFB $08,$00,$0B
  DEFB $01,$18,$03
  DEFB $04,$10,$1E
  DEFB $05,$1D,$04
  DEFB $0A,$1D,$0D
  DEFB $0E,$14,$05
  DEFB $FF
Screen001Layout:
  DEFB $13,$00,$0E        ; screen 1: 10 objects
  DEFB $12,$00,$21
  DEFB $0A,$07,$0F
  DEFB $0C,$0E,$10
  DEFB $0C,$12,$10
  DEFB $0C,$16,$10
  DEFB $10,$1C,$14
  DEFB $00,$00,$1E
  DEFB $03,$0F,$03
  DEFB $02,$14,$04
  DEFB $FF
Screen002Layout:
  DEFB $13,$00,$0A        ; screen 2: 11 objects
  DEFB $12,$00,$21
  DEFB $0B,$16,$17
  DEFB $0D,$16,$18
  DEFB $05,$16,$11
  DEFB $0E,$0E,$05
  DEFB $0C,$04,$11
  DEFB $12,$1B,$16
  DEFB $09,$1C,$13
  DEFB $01,$08,$03
  DEFB $02,$02,$04
  DEFB $FF
Screen003Layout:
  DEFB $13,$00,$0E        ; screen 3: 7 objects
  DEFB $12,$00,$21
  DEFB $0B,$E7,$17
  DEFB $0D,$04,$18
  DEFB $0C,$18,$10
  DEFB $0C,$1C,$10
  DEFB $10,$13,$14
  DEFB $FF
Screen004Layout:
  DEFB $13,$00,$0A        ; screen 4: 7 objects
  DEFB $12,$00,$21
  DEFB $01,$04,$04
  DEFB $03,$16,$03
  DEFB $07,$1B,$1E
  DEFB $02,$09,$02
  DEFB $0A,$0D,$0F
  DEFB $FF
Screen005Layout:
  DEFB $13,$F2,$0E        ; screen 5: 8 objects
  DEFB $12,$F2,$21
  DEFB $12,$12,$22
  DEFB $14,$13,$17
  DEFB $0E,$17,$15
  DEFB $03,$0B,$25
  DEFB $00,$01,$23
  DEFB $02,$19,$24
  DEFB $FF
Screen006Layout:
  DEFB $14,$F7,$17        ; screen 6: 13 objects
  DEFB $08,$09,$17
  DEFB $0A,$09,$1C
  DEFB $0A,$13,$1C
  DEFB $02,$09,$11
  DEFB $06,$18,$13
  DEFB $06,$1B,$14
  DEFB $12,$17,$22
  DEFB $12,$18,$21
  DEFB $13,$18,$0E
  DEFB $11,$12,$1A
  DEFB $0C,$19,$11
  DEFB $02,$11,$10
  DEFB $FF
Screen007Layout:
  DEFB $13,$00,$0A        ; screen 7: 13 objects
  DEFB $12,$E6,$21
  DEFB $12,$06,$22
  DEFB $08,$E7,$17
  DEFB $08,$18,$17
  DEFB $08,$0E,$1C
  DEFB $0A,$04,$1C
  DEFB $0A,$18,$1C
  DEFB $04,$0C,$05
  DEFB $0F,$1A,$05
  DEFB $13,$0A,$0C
  DEFB $13,$0F,$0C
  DEFB $13,$14,$0C
  DEFB $FF
Screen008Layout:
  DEFB $13,$F3,$0A        ; screen 8: 11 objects
  DEFB $14,$13,$17
  DEFB $08,$E8,$17
  DEFB $02,$04,$11
  DEFB $0D,$08,$11
  DEFB $0A,$05,$1C
  DEFB $0F,$15,$20
  DEFB $0B,$14,$1F
  DEFB $0E,$1A,$15
  DEFB $00,$11,$03
  DEFB $04,$19,$04
  DEFB $FF
Screen009Layout:
  DEFB $14,$F1,$17        ; screen 9: 13 objects
  DEFB $12,$12,$21
  DEFB $12,$11,$22
  DEFB $13,$12,$0E
  DEFB $0B,$17,$1D
  DEFB $10,$12,$13
  DEFB $10,$1D,$14
  DEFB $0E,$08,$10
  DEFB $14,$04,$16
  DEFB $14,$0C,$16
  DEFB $01,$07,$24
  DEFB $03,$10,$1E
  DEFB $00,$16,$03
  DEFB $FF
Screen010Layout:
  DEFB $08,$00,$0E        ; screen 10: 11 objects
  DEFB $13,$00,$0A
  DEFB $12,$00,$21
  DEFB $0B,$01,$19
  DEFB $0B,$1D,$19
  DEFB $0F,$17,$1A
  DEFB $0C,$06,$11
  DEFB $02,$00,$11
  DEFB $02,$0A,$10
  DEFB $02,$0E,$10
  DEFB $02,$12,$10
  DEFB $FF
Screen011Layout:
  DEFB $14,$0B,$17        ; screen 11: 16 objects
  DEFB $13,$EA,$0E
  DEFB $13,$18,$0E
  DEFB $12,$19,$21
  DEFB $12,$EA,$21
  DEFB $12,$0A,$22
  DEFB $12,$18,$22
  DEFB $0A,$17,$0F
  DEFB $12,$14,$13
  DEFB $10,$1C,$14
  DEFB $0B,$05,$19
  DEFB $08,$E7,$0E
  DEFB $00,$0C,$04
  DEFB $02,$12,$1E
  DEFB $0F,$10,$20
  DEFB $0B,$0F,$1F
  DEFB $FF
Screen012Layout:
  DEFB $08,$00,$0B        ; screen 12: 13 objects
  DEFB $13,$EA,$0A
  DEFB $12,$EA,$21
  DEFB $12,$0A,$22
  DEFB $14,$0B,$26
  DEFB $0E,$0E,$11
  DEFB $06,$14,$11
  DEFB $0C,$14,$0E
  DEFB $0E,$14,$21
  DEFB $10,$1A,$05
  DEFB $0F,$14,$1B
  DEFB $0A,$1E,$14
  DEFB $10,$05,$13
  DEFB $FF
Screen013Layout:
  DEFB $14,$00,$26        ; screen 13: 8 objects
  DEFB $0C,$00,$0E
  DEFB $0E,$00,$21
  DEFB $0F,$0E,$1B
  DEFB $06,$12,$15
  DEFB $11,$1B,$1A
  DEFB $14,$06,$16
  DEFB $00,$03,$24
  DEFB $FF
Screen014Layout:
  DEFB $14,$EE,$26        ; screen 14: 13 objects
  DEFB $14,$0E,$26
  DEFB $0C,$00,$0A
  DEFB $0E,$00,$21
  DEFB $0F,$04,$1B
  DEFB $00,$03,$24
  DEFB $0F,$1A,$1B
  DEFB $06,$05,$11
  DEFB $09,$12,$1A
  DEFB $06,$17,$11
  DEFB $14,$08,$16
  DEFB $14,$0F,$16
  DEFB $14,$16,$16
  DEFB $FF
Screen015Layout:
  DEFB $0C,$E7,$0A        ; screen 15: 8 objects
  DEFB $0E,$E7,$21
  DEFB $0F,$04,$1B
  DEFB $14,$00,$26
  DEFB $0B,$18,$1F
  DEFB $0F,$19,$20
  DEFB $00,$04,$03
  DEFB $02,$19,$1E
  DEFB $FF
Screen016Layout:
  DEFB $0B,$1D,$0D        ; screen 16: 8 objects
  DEFB $13,$09,$0E
  DEFB $14,$E9,$26
  DEFB $13,$0B,$0C
  DEFB $13,$13,$0C
  DEFB $0F,$0D,$05
  DEFB $02,$14,$03
  DEFB $05,$05,$1E
  DEFB $FF
Screen017Layout:
  DEFB $13,$00,$0E        ; screen 17: 9 objects
  DEFB $0D,$06,$11
  DEFB $09,$00,$1C
  DEFB $09,$0D,$1C
  DEFB $08,$F0,$21
  DEFB $02,$00,$11
  DEFB $06,$0A,$13
  DEFB $06,$0E,$14
  DEFB $13,$12,$16
  DEFB $FF
Screen018Layout:
  DEFB $13,$00,$0E        ; screen 18: 13 objects
  DEFB $12,$0F,$22
  DEFB $12,$10,$21
  DEFB $0C,$15,$15
  DEFB $0B,$10,$19
  DEFB $0D,$04,$11
  DEFB $03,$10,$11
  DEFB $04,$16,$18
  DEFB $02,$16,$17
  DEFB $09,$10,$17
  DEFB $13,$0B,$0C
  DEFB $0C,$1C,$10
  DEFB $07,$1B,$13
  DEFB $FF
Screen019Layout:
  DEFB $02,$00,$26        ; screen 19: 9 objects
  DEFB $09,$EF,$26
  DEFB $09,$0F,$26
  DEFB $04,$04,$1B
  DEFB $04,$19,$1B
  DEFB $13,$00,$0A
  DEFB $12,$00,$21
  DEFB $0B,$0F,$19
  DEFB $0E,$13,$05
  DEFB $FF
Screen020Layout:
  DEFB $13,$00,$0E        ; screen 20: 12 objects
  DEFB $12,$00,$21
  DEFB $02,$00,$26
  DEFB $09,$00,$26
  DEFB $04,$0E,$1B
  DEFB $06,$1B,$1A
  DEFB $0B,$01,$19
  DEFB $0B,$1D,$19
  DEFB $0E,$18,$27
  DEFB $0E,$0F,$27
  DEFB $12,$08,$16
  DEFB $12,$15,$16
  DEFB $FF
Screen021Layout:
  DEFB $13,$00,$0A        ; screen 21: 12 objects
  DEFB $12,$00,$21
  DEFB $0C,$18,$10
  DEFB $0C,$1C,$10
  DEFB $10,$04,$13
  DEFB $10,$10,$14
  DEFB $0B,$0A,$19
  DEFB $09,$EC,$26
  DEFB $04,$06,$1B
  DEFB $02,$E9,$26
  DEFB $00,$18,$25
  DEFB $05,$0F,$27
  DEFB $FF
Screen022Layout:
  DEFB $13,$00,$0E        ; screen 22: 8 objects
  DEFB $12,$F4,$21
  DEFB $11,$19,$29
  DEFB $0D,$08,$28
  DEFB $0D,$0E,$28
  DEFB $03,$0E,$25
  DEFB $00,$18,$03
  DEFB $02,$02,$1E
  DEFB $FF
Screen023Layout:
  DEFB $13,$00,$0A        ; screen 23: 10 objects
  DEFB $0F,$1A,$2C
  DEFB $11,$19,$2D
  DEFB $13,$05,$16
  DEFB $09,$0D,$1C
  DEFB $09,$1D,$1C
  DEFB $07,$0D,$26
  DEFB $02,$0E,$28
  DEFB $01,$14,$10
  DEFB $00,$05,$03
  DEFB $FF
Screen024Layout:
  DEFB $13,$00,$0E        ; screen 24: 7 objects
  DEFB $04,$0C,$2A
  DEFB $00,$03,$24
  DEFB $01,$15,$03
  DEFB $0B,$1D,$0D
  DEFB $10,$09,$2B
  DEFB $10,$16,$2B
  DEFB $FF
Screen025Layout:
  DEFB $13,$00,$0A        ; screen 25: 12 objects
  DEFB $00,$00,$0E
  DEFB $0B,$1D,$0D
  DEFB $03,$02,$31
  DEFB $03,$09,$30
  DEFB $03,$13,$31
  DEFB $03,$1A,$30
  DEFB $03,$05,$32
  DEFB $03,$16,$32
  DEFB $0F,$0B,$2E
  DEFB $0F,$10,$2E
  DEFB $03,$0B,$33
  DEFB $FF
Screen026Layout:
  DEFB $13,$00,$0E        ; screen 26: 8 objects
  DEFB $00,$EB,$0A
  DEFB $03,$02,$31
  DEFB $03,$09,$30
  DEFB $03,$05,$32
  DEFB $0E,$0B,$28
  DEFB $0E,$11,$28
  DEFB $13,$1A,$0C
  DEFB $FF
Screen027Layout:
  DEFB $13,$E8,$0A        ; screen 27: 11 objects
  DEFB $11,$09,$1C
  DEFB $10,$0E,$1C
  DEFB $0F,$13,$1C
  DEFB $0E,$18,$1C
  DEFB $0D,$1D,$1C
  DEFB $0D,$13,$13
  DEFB $0B,$1D,$14
  DEFB $02,$1A,$04
  DEFB $00,$0C,$03
  DEFB $03,$04,$25
  DEFB $FF
Screen028Layout:
  DEFB $14,$00,$17        ; screen 28: 6 objects
  DEFB $0D,$02,$1C
  DEFB $0D,$0C,$1C
  DEFB $11,$10,$1A
  DEFB $0E,$1B,$15
  DEFB $02,$09,$02
  DEFB $FF
Screen029Layout:
  DEFB $14,$EC,$17        ; screen 29: 15 objects
  DEFB $13,$0C,$0E
  DEFB $12,$0C,$17
  DEFB $0E,$14,$05
  DEFB $0C,$1B,$11
  DEFB $08,$06,$1C
  DEFB $08,$0F,$1C
  DEFB $08,$18,$1C
  DEFB $06,$00,$26
  DEFB $02,$06,$2F
  DEFB $02,$0F,$2F
  DEFB $02,$18,$2F
  DEFB $00,$01,$11
  DEFB $00,$06,$26
  DEFB $10,$0D,$13
  DEFB $FF
Screen030Layout:
  DEFB $13,$00,$0E        ; screen 30: 12 objects
  DEFB $12,$00,$17
  DEFB $12,$0F,$16
  DEFB $08,$06,$1C
  DEFB $0A,$0A,$1C
  DEFB $0A,$15,$1C
  DEFB $06,$13,$05
  DEFB $06,$E9,$26
  DEFB $02,$06,$2F
  DEFB $00,$E9,$26
  DEFB $0E,$09,$27
  DEFB $0E,$09,$27
  DEFB $FF
Screen031Layout:
  DEFB $13,$00,$0A        ; screen 31: 11 objects
  DEFB $12,$EF,$17
  DEFB $13,$0F,$16
  DEFB $13,$16,$16
  DEFB $13,$1D,$16
  DEFB $11,$13,$13
  DEFB $11,$1A,$14
  DEFB $0A,$05,$0F
  DEFB $0A,$0A,$0F
  DEFB $02,$08,$1E
  DEFB $04,$15,$03
  DEFB $FF
Screen032Layout:
  DEFB $13,$00,$0E        ; screen 32: 10 objects
  DEFB $13,$05,$0C
  DEFB $0F,$0B,$2C
  DEFB $11,$0A,$2D
  DEFB $0D,$12,$11
  DEFB $0B,$18,$2F
  DEFB $0F,$18,$2F
  DEFB $09,$18,$26
  DEFB $03,$18,$11
  DEFB $13,$1D,$0C
  DEFB $FF
Screen033Layout:
  DEFB $13,$00,$0A        ; screen 33: 11 objects
  DEFB $0B,$06,$2F
  DEFB $0F,$06,$2F
  DEFB $0B,$18,$2F
  DEFB $0F,$18,$2F
  DEFB $09,$00,$26
  DEFB $11,$15,$13
  DEFB $07,$03,$14
  DEFB $0D,$1C,$11
  DEFB $03,$06,$11
  DEFB $06,$1B,$1A
  DEFB $FF
Screen034Layout:
  DEFB $13,$00,$0E        ; screen 34: 15 objects
  DEFB $0B,$06,$2F
  DEFB $0F,$06,$2F
  DEFB $0B,$18,$2F
  DEFB $0F,$18,$2F
  DEFB $09,$FB,$26
  DEFB $09,$1B,$26
  DEFB $07,$15,$13
  DEFB $07,$19,$14
  DEFB $02,$0E,$1D
  DEFB $13,$0A,$0C
  DEFB $13,$0F,$0C
  DEFB $13,$14,$0C
  DEFB $0F,$14,$27
  DEFB $0F,$13,$27
  DEFB $FF
Screen035Layout:
  DEFB $13,$00,$0A        ; screen 35: 7 objects
  DEFB $09,$E9,$26
  DEFB $0B,$06,$2F
  DEFB $0F,$06,$2F
  DEFB $00,$12,$01
  DEFB $13,$13,$00
  DEFB $13,$0D,$0C
  DEFB $FF
Screen036Layout:
  DEFB $13,$00,$0E        ; screen 36: 6 objects
  DEFB $12,$05,$22
  DEFB $12,$06,$21
  DEFB $10,$09,$13
  DEFB $02,$05,$1E
  DEFB $00,$10,$03
  DEFB $FF
Screen037Layout:
  DEFB $13,$00,$0A        ; screen 37: 9 objects
  DEFB $12,$00,$21
  DEFB $0D,$06,$28
  DEFB $0D,$0C,$28
  DEFB $0C,$12,$11
  DEFB $0B,$19,$19
  DEFB $08,$12,$0E
  DEFB $0A,$12,$21
  DEFB $02,$12,$11
  DEFB $FF
Screen038Layout:
  DEFB $13,$00,$0E        ; screen 38: 10 objects
  DEFB $12,$00,$21
  DEFB $0C,$04,$11
  DEFB $0C,$0C,$27
  DEFB $10,$0C,$27
  DEFB $0B,$0F,$19
  DEFB $08,$00,$0A
  DEFB $0A,$00,$21
  DEFB $02,$04,$11
  DEFB $05,$1B,$1A
  DEFB $FF
Screen039Layout:
  DEFB $13,$EC,$0A        ; screen 39: 11 objects
  DEFB $12,$EC,$21
  DEFB $12,$0C,$22
  DEFB $14,$0D,$17
  DEFB $0B,$06,$19
  DEFB $08,$E8,$0A
  DEFB $0A,$E8,$21
  DEFB $04,$03,$05
  DEFB $00,$15,$01
  DEFB $12,$16,$00
  DEFB $14,$1D,$16
  DEFB $FF
Screen040Layout:
  DEFB $14,$00,$17        ; screen 40: 9 objects
  DEFB $12,$06,$13
  DEFB $0E,$09,$15
  DEFB $0E,$0E,$15
  DEFB $0E,$14,$10
  DEFB $0E,$18,$10
  DEFB $12,$1C,$14
  DEFB $04,$08,$03
  DEFB $02,$18,$04
  DEFB $FF
Screen041Layout:
  DEFB $14,$EC,$17        ; screen 41: 13 objects
  DEFB $13,$0C,$0A
  DEFB $12,$0C,$17
  DEFB $12,$07,$00
  DEFB $0B,$0D,$19
  DEFB $0C,$14,$15
  DEFB $0C,$1B,$11
  DEFB $08,$0D,$0E
  DEFB $02,$0D,$11
  DEFB $04,$14,$05
  DEFB $06,$1B,$13
  DEFB $06,$1E,$14
  DEFB $00,$06,$01
  DEFB $FF
Screen042Layout:
  DEFB $13,$00,$0E        ; screen 42: 8 objects
  DEFB $12,$E9,$17
  DEFB $12,$09,$22
  DEFB $0B,$07,$19
  DEFB $08,$00,$0A
  DEFB $08,$13,$0C
  DEFB $13,$0E,$16
  DEFB $13,$18,$16
  DEFB $FF
Screen043Layout:
  DEFB $13,$00,$0A        ; screen 43: 10 objects
  DEFB $08,$E6,$0A
  DEFB $0A,$11,$1F
  DEFB $0E,$12,$20
  DEFB $0B,$03,$1C
  DEFB $00,$19,$1E
  DEFB $11,$08,$13
  DEFB $13,$0D,$0C
  DEFB $13,$17,$0C
  DEFB $0F,$1A,$2E
  DEFB $FF
Screen044Layout:
  DEFB $13,$00,$0E        ; screen 44: 5 objects
  DEFB $0D,$06,$10
  DEFB $0D,$16,$10
  DEFB $11,$0E,$14
  DEFB $09,$0A,$0B
  DEFB $FF
Screen045Layout:
  DEFB $13,$E9,$0E        ; screen 45: 12 objects
  DEFB $14,$09,$26
  DEFB $0E,$13,$11
  DEFB $0C,$0C,$2F
  DEFB $10,$0C,$2F
  DEFB $0C,$1B,$2F
  DEFB $10,$1B,$2F
  DEFB $0A,$0C,$26
  DEFB $04,$0C,$11
  DEFB $06,$19,$2C
  DEFB $08,$18,$2D
  DEFB $00,$00,$03
  DEFB $FF
Screen046Layout:
  DEFB $14,$00,$26        ; screen 46: 14 objects
  DEFB $0A,$00,$26
  DEFB $0C,$03,$2F
  DEFB $10,$03,$2F
  DEFB $0C,$1A,$2F
  DEFB $10,$1A,$2F
  DEFB $10,$14,$2C
  DEFB $12,$13,$2D
  DEFB $06,$14,$2C
  DEFB $08,$13,$2D
  DEFB $08,$06,$13
  DEFB $08,$09,$14
  DEFB $12,$0A,$27
  DEFB $10,$0F,$27
  DEFB $FF
Screen047Layout:
  DEFB $14,$00,$26        ; screen 47: 12 objects
  DEFB $0C,$06,$2F
  DEFB $10,$06,$2F
  DEFB $0A,$E9,$26
  DEFB $04,$05,$15
  DEFB $09,$0E,$1C
  DEFB $07,$12,$1C
  DEFB $07,$1C,$1C
  DEFB $03,$10,$05
  DEFB $14,$0B,$16
  DEFB $14,$12,$16
  DEFB $14,$19,$16
  DEFB $FF
Screen048Layout:
  DEFB $14,$E9,$26        ; screen 48: 12 objects
  DEFB $13,$09,$0A
  DEFB $0F,$05,$28
  DEFB $0D,$0F,$11
  DEFB $10,$1C,$1A
  DEFB $0B,$15,$2F
  DEFB $0F,$15,$2F
  DEFB $09,$15,$17
  DEFB $08,$15,$21
  DEFB $02,$15,$11
  DEFB $07,$00,$1C
  DEFB $0A,$04,$1C
  DEFB $FF
Screen049Layout:
  DEFB $13,$00,$0A        ; screen 49: 10 objects
  DEFB $12,$0B,$22
  DEFB $12,$0C,$21
  DEFB $0B,$06,$2F
  DEFB $0F,$06,$2F
  DEFB $0F,$0D,$2B
  DEFB $0F,$1C,$2B
  DEFB $09,$E9,$17
  DEFB $08,$E9,$21
  DEFB $03,$11,$2A
  DEFB $FF
Screen050Layout:
  DEFB $13,$00,$0E        ; screen 50: 14 objects
  DEFB $13,$03,$0C
  DEFB $13,$06,$0C
  DEFB $13,$09,$0C
  DEFB $13,$0C,$0C
  DEFB $13,$0F,$0C
  DEFB $13,$12,$0C
  DEFB $08,$00,$1C
  DEFB $08,$0A,$1C
  DEFB $0E,$14,$1C
  DEFB $0E,$18,$20
  DEFB $0A,$17,$1F
  DEFB $00,$1B,$01
  DEFB $13,$1C,$00
  DEFB $FF
Screen051Layout:
  DEFB $13,$00,$0A        ; screen 51: 7 objects
  DEFB $00,$07,$24
  DEFB $02,$1B,$1E
  DEFB $0E,$0F,$20
  DEFB $0A,$0E,$1F
  DEFB $09,$00,$0B
  DEFB $09,$15,$0B
  DEFB $FF
Screen052Layout:
  DEFB $13,$EA,$0A        ; screen 52: 10 objects
  DEFB $14,$0A,$34
  DEFB $0D,$0B,$34
  DEFB $0D,$06,$11
  DEFB $07,$0B,$11
  DEFB $0F,$0B,$35
  DEFB $0F,$1C,$35
  DEFB $11,$18,$1A
  DEFB $09,$1D,$27
  DEFB $09,$1C,$27
  DEFB $FF
Screen053Layout:
  DEFB $14,$00,$34        ; screen 53: 14 objects
  DEFB $0D,$F2,$34
  DEFB $0D,$17,$34
  DEFB $0F,$06,$35
  DEFB $08,$06,$35
  DEFB $08,$17,$35
  DEFB $0F,$17,$35
  DEFB $05,$06,$0E
  DEFB $12,$0E,$13
  DEFB $12,$1B,$14
  DEFB $09,$0D,$2C
  DEFB $0B,$0C,$2D
  DEFB $01,$0A,$2E
  DEFB $01,$10,$2E
  DEFB $FF
Screen054Layout:
  DEFB $14,$00,$34        ; screen 54: 7 objects
  DEFB $0D,$EF,$34
  DEFB $0F,$06,$35
  DEFB $08,$06,$35
  DEFB $08,$0A,$28
  DEFB $05,$E9,$0E
  DEFB $12,$18,$13
  DEFB $FF
Screen055Layout:
  DEFB $14,$E6,$34        ; screen 55: 10 objects
  DEFB $12,$06,$22
  DEFB $12,$07,$21
  DEFB $13,$07,$0A
  DEFB $0C,$07,$10
  DEFB $0C,$0B,$10
  DEFB $10,$0F,$14
  DEFB $0C,$12,$10
  DEFB $0C,$16,$10
  DEFB $12,$1D,$16
  DEFB $FF
Screen056Layout:
  DEFB $13,$00,$0A        ; screen 56: 10 objects
  DEFB $12,$00,$21
  DEFB $0C,$0E,$11
  DEFB $0D,$14,$35
  DEFB $0B,$14,$34
  DEFB $00,$0E,$34
  DEFB $02,$0E,$1C
  DEFB $02,$1D,$1C
  DEFB $10,$1A,$13
  DEFB $05,$14,$11
  DEFB $FF
Screen057Layout:
  DEFB $13,$00,$0E        ; screen 57: 13 objects
  DEFB $12,$00,$21
  DEFB $0D,$09,$35
  DEFB $0D,$14,$35
  DEFB $0E,$1A,$2C
  DEFB $10,$19,$2D
  DEFB $0B,$EC,$34
  DEFB $0B,$14,$34
  DEFB $09,$17,$14
  DEFB $09,$1A,$13
  DEFB $02,$03,$1C
  DEFB $02,$1B,$1C
  DEFB $00,$00,$34
  DEFB $FF
Screen058Layout:
  DEFB $13,$00,$0A        ; screen 58: 3 objects
  DEFB $12,$00,$21
  DEFB $0B,$E6,$34
  DEFB $FF
Screen059Layout:
  DEFB $14,$F5,$34        ; screen 59: 17 objects
  DEFB $13,$E8,$0A
  DEFB $12,$E8,$21
  DEFB $12,$08,$22
  DEFB $15,$15,$21
  DEFB $0C,$05,$11
  DEFB $09,$00,$1C
  DEFB $09,$03,$1C
  DEFB $03,$00,$11
  DEFB $0F,$0C,$35
  DEFB $0F,$0F,$35
  DEFB $0B,$0C,$2F
  DEFB $0B,$0F,$2F
  DEFB $06,$0E,$20
  DEFB $02,$0D,$1F
  DEFB $00,$18,$03
  DEFB $07,$04,$13
  DEFB $FF
Screen060Layout:
  DEFB $15,$EC,$21        ; screen 60: 12 objects
  DEFB $14,$0C,$34
  DEFB $12,$18,$22
  DEFB $12,$19,$21
  DEFB $13,$19,$0E
  DEFB $0D,$06,$0F
  DEFB $12,$0D,$14
  DEFB $11,$12,$2B
  DEFB $10,$18,$13
  DEFB $0B,$1B,$1D
  DEFB $00,$02,$24
  DEFB $03,$12,$25
  DEFB $FF
Screen061Layout:
  DEFB $13,$00,$0A        ; screen 61: 12 objects
  DEFB $12,$00,$21
  DEFB $0B,$07,$19
  DEFB $0B,$15,$19
  DEFB $0C,$0B,$11
  DEFB $10,$18,$2D
  DEFB $0E,$19,$2C
  DEFB $09,$07,$34
  DEFB $03,$07,$11
  DEFB $06,$0F,$2B
  DEFB $06,$15,$2B
  DEFB $06,$1B,$2B
  DEFB $FF
Screen062Layout:
  DEFB $13,$00,$0E        ; screen 62: 9 objects
  DEFB $12,$00,$21
  DEFB $0B,$07,$19
  DEFB $09,$EA,$34
  DEFB $0A,$16,$0A
  DEFB $0D,$16,$35
  DEFB $0D,$19,$35
  DEFB $00,$0E,$01
  DEFB $10,$0F,$00
  DEFB $FF
Screen063Layout:
  DEFB $13,$00,$0A        ; screen 63: 5 objects
  DEFB $12,$00,$21
  DEFB $0D,$06,$35
  DEFB $0D,$17,$35
  DEFB $0A,$00,$0E
  DEFB $FF
Screen064Layout:
  DEFB $13,$00,$0E        ; screen 64: 9 objects
  DEFB $12,$00,$21
  DEFB $0D,$06,$18
  DEFB $0D,$17,$18
  DEFB $0A,$E9,$0E
  DEFB $0A,$17,$0A
  DEFB $12,$0A,$16
  DEFB $12,$13,$16
  DEFB $00,$05,$1E
  DEFB $FF
Screen065Layout:
  DEFB $13,$F1,$0A        ; screen 65: 9 objects
  DEFB $12,$E9,$21
  DEFB $12,$08,$22
  DEFB $14,$11,$36
  DEFB $0D,$06,$35
  DEFB $0E,$0B,$28
  DEFB $0E,$12,$15
  DEFB $0E,$1B,$15
  DEFB $0A,$E9,$0A
  DEFB $FF
Screen066Layout:
  DEFB $14,$00,$36        ; screen 66: 13 objects
  DEFB $0C,$0F,$2F
  DEFB $10,$0F,$2F
  DEFB $0E,$13,$11
  DEFB $0A,$0F,$36
  DEFB $02,$0F,$2F
  DEFB $06,$0F,$2F
  DEFB $04,$13,$11
  DEFB $04,$1B,$10
  DEFB $00,$06,$36
  DEFB $02,$06,$33
  DEFB $10,$0B,$27
  DEFB $10,$08,$27
  DEFB $FF
Screen067Layout:
  DEFB $14,$00,$36        ; screen 67: 16 objects
  DEFB $0C,$06,$2F
  DEFB $10,$06,$2F
  DEFB $0C,$17,$2F
  DEFB $10,$17,$2F
  DEFB $0C,$0E,$0F
  DEFB $0A,$00,$36
  DEFB $02,$06,$2F
  DEFB $06,$06,$2F
  DEFB $02,$17,$2F
  DEFB $06,$17,$2F
  DEFB $08,$0A,$13
  DEFB $07,$1B,$1A
  DEFB $05,$0E,$27
  DEFB $14,$0A,$16
  DEFB $00,$00,$36
  DEFB $FF
Screen068Layout:
  DEFB $14,$EF,$36        ; screen 68: 15 objects
  DEFB $12,$0F,$22
  DEFB $12,$10,$21
  DEFB $13,$10,$0A
  DEFB $12,$0B,$13
  DEFB $10,$10,$14
  DEFB $12,$13,$16
  DEFB $00,$1B,$01
  DEFB $10,$1C,$00
  DEFB $0C,$06,$2F
  DEFB $10,$06,$2F
  DEFB $0A,$E9,$36
  DEFB $02,$06,$2F
  DEFB $06,$06,$2F
  DEFB $00,$E9,$36
  DEFB $FF
Screen069Layout:
  DEFB $13,$00,$0A        ; screen 69: 19 objects
  DEFB $12,$00,$37
  DEFB $12,$04,$22
  DEFB $12,$08,$22
  DEFB $12,$09,$37
  DEFB $12,$0D,$22
  DEFB $12,$11,$22
  DEFB $12,$12,$37
  DEFB $12,$16,$22
  DEFB $12,$1A,$22
  DEFB $12,$1B,$37
  DEFB $12,$1F,$22
  DEFB $0E,$12,$2E
  DEFB $0C,$1B,$15
  DEFB $13,$05,$16
  DEFB $13,$0E,$16
  DEFB $13,$17,$16
  DEFB $02,$14,$24
  DEFB $00,$05,$03
  DEFB $FF
Screen070Layout:
  DEFB $13,$00,$0E        ; screen 70: 21 objects
  DEFB $12,$00,$37
  DEFB $12,$04,$22
  DEFB $12,$08,$22
  DEFB $12,$09,$37
  DEFB $12,$0D,$22
  DEFB $12,$11,$22
  DEFB $12,$12,$37
  DEFB $12,$16,$22
  DEFB $12,$1A,$22
  DEFB $12,$1B,$37
  DEFB $12,$1F,$22
  DEFB $0C,$11,$11
  DEFB $0B,$1C,$19
  DEFB $09,$1C,$36
  DEFB $03,$1C,$11
  DEFB $13,$06,$0C
  DEFB $13,$0F,$0C
  DEFB $13,$18,$0C
  DEFB $09,$09,$1F
  DEFB $0D,$0A,$20
  DEFB $FF
Screen071Layout:
  DEFB $13,$00,$0A        ; screen 71: 12 objects
  DEFB $12,$00,$21
  DEFB $0B,$0D,$19
  DEFB $0B,$16,$19
  DEFB $09,$EF,$36
  DEFB $09,$16,$36
  DEFB $01,$0B,$0F
  DEFB $01,$15,$0F
  DEFB $0E,$1A,$2C
  DEFB $10,$19,$2D
  DEFB $0C,$12,$27
  DEFB $0B,$12,$27
  DEFB $FF
Screen072Layout:
  DEFB $13,$E9,$0E        ; screen 72: 10 objects
  DEFB $12,$E9,$21
  DEFB $12,$08,$22
  DEFB $14,$09,$34
  DEFB $0B,$05,$19
  DEFB $09,$E7,$36
  DEFB $10,$1A,$05
  DEFB $14,$12,$16
  DEFB $00,$12,$25
  DEFB $03,$1E,$04
  DEFB $FF
Screen073Layout:
  DEFB $14,$00,$34        ; screen 73: 11 objects
  DEFB $12,$06,$22
  DEFB $12,$07,$37
  DEFB $12,$0B,$22
  DEFB $12,$12,$22
  DEFB $12,$13,$37
  DEFB $12,$17,$22
  DEFB $13,$07,$06
  DEFB $13,$13,$07
  DEFB $0E,$12,$2C
  DEFB $10,$11,$2D
  DEFB $FF
Screen074Layout:
  DEFB $14,$00,$36        ; screen 74: 7 objects
  DEFB $05,$0C,$2A
  DEFB $00,$03,$1E
  DEFB $01,$15,$25
  DEFB $0C,$1D,$0D
  DEFB $11,$09,$2B
  DEFB $11,$16,$2B
  DEFB $FF
Screen075Layout:
  DEFB $13,$E8,$3C        ; screen 75: 10 objects
  DEFB $12,$E8,$21
  DEFB $12,$08,$22
  DEFB $0D,$02,$28
  DEFB $11,$10,$2B
  DEFB $0F,$14,$28
  DEFB $0C,$1D,$0D
  DEFB $02,$09,$02
  DEFB $00,$03,$03
  DEFB $14,$09,$34
  DEFB $FF
Screen076Layout:
  DEFB $14,$00,$36        ; screen 76: 16 objects
  DEFB $12,$0C,$22
  DEFB $12,$0D,$37
  DEFB $12,$11,$22
  DEFB $12,$1A,$22
  DEFB $12,$1B,$37
  DEFB $12,$1F,$22
  DEFB $13,$0D,$3B
  DEFB $13,$1B,$3A
  DEFB $0E,$1B,$2F
  DEFB $0A,$1B,$2F
  DEFB $08,$1B,$36
  DEFB $00,$0F,$1E
  DEFB $02,$06,$24
  DEFB $10,$0E,$13
  DEFB $12,$16,$14
  DEFB $FF
Screen077Layout:
  DEFB $13,$00,$3D        ; screen 77: 8 objects
  DEFB $12,$00,$21
  DEFB $0C,$03,$11
  DEFB $0F,$15,$1A
  DEFB $0A,$06,$1C
  DEFB $0A,$18,$1C
  DEFB $08,$00,$36
  DEFB $02,$00,$11
  DEFB $FF
Screen078Layout:
  DEFB $13,$00,$3C        ; screen 78: 19 objects
  DEFB $12,$00,$37
  DEFB $12,$04,$22
  DEFB $12,$09,$22
  DEFB $12,$0A,$37
  DEFB $12,$0E,$22
  DEFB $12,$13,$22
  DEFB $12,$14,$37
  DEFB $12,$18,$22
  DEFB $12,$1D,$22
  DEFB $12,$1E,$37
  DEFB $13,$06,$0C
  DEFB $13,$10,$0C
  DEFB $13,$1A,$0C
  DEFB $0D,$0A,$28
  DEFB $08,$00,$36
  DEFB $06,$0A,$2D
  DEFB $04,$0B,$2C
  DEFB $03,$12,$28
  DEFB $FF
Screen079Layout:
  DEFB $13,$00,$3D        ; screen 79: 9 objects
  DEFB $12,$00,$21
  DEFB $0C,$08,$15
  DEFB $0A,$0E,$2F
  DEFB $0E,$0E,$2F
  DEFB $08,$F1,$36
  DEFB $05,$0F,$2B
  DEFB $10,$02,$13
  DEFB $10,$05,$14
  DEFB $FF
Screen080Layout:
  DEFB $14,$0B,$34        ; screen 80: 10 objects
  DEFB $13,$EA,$3C
  DEFB $13,$16,$3D
  DEFB $12,$0A,$22
  DEFB $12,$15,$22
  DEFB $12,$16,$21
  DEFB $12,$EA,$21
  DEFB $10,$03,$13
  DEFB $0B,$0E,$1F
  DEFB $0F,$0F,$20
  DEFB $FF
Screen081Layout:
  DEFB $13,$00,$3D        ; screen 81: 11 objects
  DEFB $12,$00,$21
  DEFB $0C,$08,$11
  DEFB $04,$12,$11
  DEFB $12,$04,$16
  DEFB $12,$0D,$16
  DEFB $0D,$12,$35
  DEFB $0A,$12,$0A
  DEFB $0A,$1C,$0C
  DEFB $0E,$18,$2C
  DEFB $10,$17,$2D
  DEFB $FF
Screen082Layout:
  DEFB $13,$EC,$3C        ; screen 82: 14 objects
  DEFB $12,$EC,$21
  DEFB $12,$0C,$22
  DEFB $14,$0D,$36
  DEFB $0E,$16,$15
  DEFB $0B,$1B,$1F
  DEFB $0F,$1C,$20
  DEFB $0D,$04,$35
  DEFB $0D,$09,$35
  DEFB $0A,$EC,$0E
  DEFB $00,$15,$03
  DEFB $05,$1A,$1E
  DEFB $12,$0E,$13
  DEFB $12,$11,$14
  DEFB $FF
Screen083Layout:
  DEFB $13,$04,$3D        ; screen 83: 7 objects
  DEFB $14,$E4,$36
  DEFB $10,$07,$2B
  DEFB $10,$18,$2B
  DEFB $00,$05,$1E
  DEFB $03,$11,$03
  DEFB $01,$1D,$04
  DEFB $FF
Screen084Layout:
  DEFB $13,$00,$3C        ; screen 84: 9 objects
  DEFB $12,$10,$21
  DEFB $12,$0F,$22
  DEFB $10,$0C,$2B
  DEFB $11,$04,$13
  DEFB $10,$1C,$14
  DEFB $0C,$12,$10
  DEFB $0C,$18,$10
  DEFB $00,$02,$03
  DEFB $FF
Screen085Layout:
  DEFB $13,$00,$3D        ; screen 85: 5 objects
  DEFB $12,$00,$21
  DEFB $00,$00,$25
  DEFB $04,$09,$1E
  DEFB $00,$19,$1E
  DEFB $FF
Screen086Layout:
  DEFB $13,$00,$3C        ; screen 86: 10 objects
  DEFB $12,$00,$21
  DEFB $10,$04,$13
  DEFB $0C,$07,$11
  DEFB $0A,$0C,$2F
  DEFB $0E,$0C,$2F
  DEFB $08,$0C,$36
  DEFB $0B,$14,$36
  DEFB $0D,$14,$35
  DEFB $02,$0C,$11
  DEFB $FF
Screen087Layout:
  DEFB $13,$00,$3D        ; screen 87: 10 objects
  DEFB $12,$00,$21
  DEFB $10,$04,$13
  DEFB $0B,$EB,$36
  DEFB $0A,$0E,$2F
  DEFB $0E,$0E,$2F
  DEFB $08,$00,$36
  DEFB $0D,$08,$35
  DEFB $05,$1B,$1A
  DEFB $0F,$1A,$1A
  DEFB $FF
Screen088Layout:
  DEFB $13,$00,$3C        ; screen 88: 9 objects
  DEFB $12,$00,$21
  DEFB $08,$EF,$36
  DEFB $00,$16,$03
  DEFB $0A,$0C,$2F
  DEFB $0E,$0C,$2F
  DEFB $12,$12,$16
  DEFB $0D,$1A,$20
  DEFB $09,$19,$1F
  DEFB $FF
Screen089Layout:
  DEFB $13,$00,$3D        ; screen 89: 11 objects
  DEFB $12,$ED,$21
  DEFB $10,$08,$13
  DEFB $10,$0B,$14
  DEFB $12,$0C,$22
  DEFB $13,$12,$0C
  DEFB $13,$16,$0C
  DEFB $13,$1D,$0C
  DEFB $04,$11,$02
  DEFB $02,$03,$1E
  DEFB $00,$09,$04
  DEFB $FF
Screen090Layout:
  DEFB $13,$E6,$3D        ; screen 90: 15 objects
  DEFB $14,$06,$36
  DEFB $11,$04,$13
  DEFB $12,$07,$14
  DEFB $0D,$0C,$1D
  DEFB $0C,$13,$2F
  DEFB $10,$13,$2F
  DEFB $14,$17,$16
  DEFB $14,$1B,$16
  DEFB $0A,$13,$17
  DEFB $05,$13,$18
  DEFB $06,$17,$2E
  DEFB $06,$1C,$2E
  DEFB $03,$13,$17
  DEFB $01,$04,$24
  DEFB $FF
Screen091Layout:
  DEFB $14,$00,$36        ; screen 91: 10 objects
  DEFB $0E,$06,$11
  DEFB $0C,$0F,$2F
  DEFB $10,$0F,$2F
  DEFB $0F,$13,$28
  DEFB $0F,$18,$28
  DEFB $0A,$00,$17
  DEFB $03,$E6,$17
  DEFB $05,$03,$18
  DEFB $04,$07,$11
  DEFB $FF
Screen092Layout:
  DEFB $14,$00,$36        ; screen 92: 8 objects
  DEFB $0A,$EC,$17
  DEFB $0C,$09,$2F
  DEFB $10,$09,$2F
  DEFB $0B,$13,$1F
  DEFB $0F,$14,$20
  DEFB $00,$19,$01
  DEFB $12,$1A,$00
  DEFB $FF
Screen093Layout:
  DEFB $14,$E9,$36        ; screen 93: 12 objects
  DEFB $13,$09,$3D
  DEFB $13,$0B,$0C
  DEFB $13,$10,$0C
  DEFB $11,$0D,$13
  DEFB $12,$13,$22
  DEFB $12,$14,$21
  DEFB $10,$16,$14
  DEFB $0E,$19,$05
  DEFB $05,$1A,$1E
  DEFB $00,$09,$03
  DEFB $02,$00,$04
  DEFB $FF
Screen094Layout:
  DEFB $13,$00,$3D        ; screen 94: 9 objects
  DEFB $12,$00,$21
  DEFB $0D,$06,$28
  DEFB $0D,$0B,$28
  DEFB $0D,$10,$28
  DEFB $0C,$15,$15
  DEFB $0C,$1A,$15
  DEFB $00,$0C,$1E
  DEFB $05,$18,$24
  DEFB $FF
Screen095Layout:
  DEFB $13,$00,$3C        ; screen 95: 10 objects
  DEFB $12,$00,$21
  DEFB $0C,$0C,$11
  DEFB $0F,$1B,$1A
  DEFB $0A,$11,$1C
  DEFB $0A,$1C,$1C
  DEFB $07,$11,$3D
  DEFB $01,$11,$11
  DEFB $05,$17,$13
  DEFB $10,$17,$14
  DEFB $FF
Screen096Layout:
  DEFB $13,$00,$3D        ; screen 96: 12 objects
  DEFB $12,$00,$21
  DEFB $07,$00,$3C
  DEFB $0A,$00,$1C
  DEFB $0A,$1D,$1C
  DEFB $12,$0E,$16
  DEFB $07,$06,$0C
  DEFB $07,$0A,$0C
  DEFB $07,$0F,$0C
  DEFB $07,$15,$0C
  DEFB $07,$1C,$0C
  DEFB $0C,$18,$15
  DEFB $FF
Screen097Layout:
  DEFB $13,$00,$3C        ; screen 97: 11 objects
  DEFB $12,$00,$21
  DEFB $07,$00,$3D
  DEFB $10,$07,$13
  DEFB $05,$0C,$14
  DEFB $0A,$09,$1C
  DEFB $0A,$13,$1C
  DEFB $03,$1A,$2C
  DEFB $05,$19,$2D
  DEFB $0E,$1A,$2C
  DEFB $10,$19,$2D
  DEFB $FF
Screen098Layout:
  DEFB $13,$00,$3D        ; screen 98: 10 objects
  DEFB $12,$EA,$21
  DEFB $12,$0A,$22
  DEFB $13,$0D,$0C
  DEFB $13,$13,$0C
  DEFB $13,$19,$0C
  DEFB $10,$10,$27
  DEFB $10,$17,$27
  DEFB $04,$11,$02
  DEFB $0A,$07,$0F
  DEFB $FF
Screen099Layout:
  DEFB $13,$00,$3D        ; screen 99: 8 objects
  DEFB $04,$0C,$2A
  DEFB $00,$01,$03
  DEFB $01,$17,$1E
  DEFB $0B,$1D,$0D
  DEFB $10,$09,$2B
  DEFB $10,$16,$2B
  DEFB $13,$05,$0C
  DEFB $FF
Screen100Layout:
  DEFB $13,$00,$3D        ; screen 100: 8 objects
  DEFB $12,$EC,$21
  DEFB $12,$0C,$22
  DEFB $02,$00,$02
  DEFB $08,$00,$0B
  DEFB $00,$19,$03
  DEFB $05,$12,$24
  DEFB $0B,$1D,$0D
  DEFB $FF
Screen101Layout:
  DEFB $13,$00,$3C        ; screen 101: 6 objects
  DEFB $0E,$0E,$28
  DEFB $0E,$14,$28
  DEFB $13,$1C,$0C
  DEFB $00,$05,$03
  DEFB $03,$0F,$1E
  DEFB $FF
Screen102Layout:
  DEFB $13,$E8,$3D        ; screen 102: 11 objects
  DEFB $11,$09,$1C
  DEFB $10,$0E,$1C
  DEFB $0F,$13,$1C
  DEFB $0E,$18,$1C
  DEFB $0D,$1D,$1C
  DEFB $0D,$13,$13
  DEFB $0B,$1D,$14
  DEFB $02,$1A,$04
  DEFB $00,$0C,$03
  DEFB $03,$04,$25
  DEFB $FF
Screen103Layout:
  DEFB $14,$00,$17        ; screen 103: 6 objects
  DEFB $0D,$02,$1C
  DEFB $0D,$0C,$1C
  DEFB $11,$10,$1A
  DEFB $0E,$1B,$15
  DEFB $02,$09,$02
  DEFB $FF
Screen104Layout:
  DEFB $14,$EC,$17        ; screen 104: 15 objects
  DEFB $13,$0C,$3C
  DEFB $12,$0C,$17
  DEFB $0E,$14,$05
  DEFB $0C,$1B,$11
  DEFB $08,$06,$1C
  DEFB $08,$0F,$1C
  DEFB $08,$18,$1C
  DEFB $06,$00,$26
  DEFB $02,$06,$2F
  DEFB $02,$0F,$2F
  DEFB $02,$18,$2F
  DEFB $00,$01,$11
  DEFB $00,$06,$26
  DEFB $10,$0D,$13
  DEFB $FF
Screen105Layout:
  DEFB $13,$00,$3C        ; screen 105: 12 objects
  DEFB $12,$00,$17
  DEFB $12,$0F,$16
  DEFB $08,$06,$1C
  DEFB $0A,$0A,$1C
  DEFB $0A,$15,$1C
  DEFB $06,$13,$05
  DEFB $06,$E9,$26
  DEFB $02,$06,$2F
  DEFB $00,$E9,$26
  DEFB $0E,$09,$27
  DEFB $0E,$09,$27
  DEFB $FF
Screen106Layout:
  DEFB $13,$00,$3D        ; screen 106: 11 objects
  DEFB $12,$EF,$17
  DEFB $13,$0F,$16
  DEFB $13,$16,$16
  DEFB $13,$1D,$16
  DEFB $11,$13,$13
  DEFB $11,$1A,$14
  DEFB $0A,$05,$0F
  DEFB $0A,$0A,$0F
  DEFB $02,$08,$1E
  DEFB $04,$15,$03
  DEFB $FF
Screen107Layout:
  DEFB $13,$00,$3C        ; screen 107: 10 objects
  DEFB $13,$05,$0C
  DEFB $0F,$0B,$2C
  DEFB $11,$0A,$2D
  DEFB $0D,$12,$11
  DEFB $0B,$18,$2F
  DEFB $0F,$18,$2F
  DEFB $09,$18,$26
  DEFB $03,$18,$11
  DEFB $13,$1D,$0C
  DEFB $FF
Screen108Layout:
  DEFB $13,$00,$3D        ; screen 108: 11 objects
  DEFB $0B,$06,$2F
  DEFB $0F,$06,$2F
  DEFB $0B,$18,$2F
  DEFB $0F,$18,$2F
  DEFB $09,$00,$26
  DEFB $11,$15,$13
  DEFB $07,$03,$14
  DEFB $0D,$1C,$11
  DEFB $03,$06,$11
  DEFB $06,$1B,$1A
  DEFB $FF
Screen109Layout:
  DEFB $13,$00,$3C        ; screen 109: 15 objects
  DEFB $0B,$06,$2F
  DEFB $0F,$06,$2F
  DEFB $0B,$18,$2F
  DEFB $0F,$18,$2F
  DEFB $09,$FB,$26
  DEFB $09,$1B,$26
  DEFB $07,$15,$13
  DEFB $07,$19,$14
  DEFB $02,$0E,$1D
  DEFB $13,$0A,$0C
  DEFB $13,$0F,$0C
  DEFB $13,$14,$0C
  DEFB $0F,$14,$27
  DEFB $0F,$13,$27
  DEFB $FF
Screen110Layout:
  DEFB $13,$00,$3D        ; screen 110: 7 objects
  DEFB $09,$E9,$26
  DEFB $0B,$06,$2F
  DEFB $0F,$06,$2F
  DEFB $00,$12,$01
  DEFB $13,$13,$00
  DEFB $13,$0D,$0C
  DEFB $FF
Screen111Layout:
  DEFB $13,$00,$3C        ; screen 111: 6 objects
  DEFB $12,$05,$22
  DEFB $12,$06,$21
  DEFB $10,$09,$13
  DEFB $02,$05,$1E
  DEFB $00,$10,$03
  DEFB $FF
Screen112Layout:
  DEFB $13,$00,$3D        ; screen 112: 9 objects
  DEFB $12,$00,$21
  DEFB $0D,$06,$28
  DEFB $0D,$0C,$28
  DEFB $0C,$12,$11
  DEFB $0B,$19,$19
  DEFB $08,$12,$3C
  DEFB $0A,$12,$21
  DEFB $02,$12,$11
  DEFB $FF
Screen113Layout:
  DEFB $13,$00,$3C        ; screen 113: 10 objects
  DEFB $12,$00,$21
  DEFB $0C,$04,$11
  DEFB $0C,$0C,$27
  DEFB $10,$0C,$27
  DEFB $0B,$0F,$19
  DEFB $08,$00,$3D
  DEFB $0A,$00,$21
  DEFB $02,$04,$11
  DEFB $05,$1B,$1A
  DEFB $FF
Screen114Layout:
  DEFB $13,$EC,$3D        ; screen 114: 11 objects
  DEFB $12,$EC,$21
  DEFB $12,$0C,$22
  DEFB $14,$0D,$17
  DEFB $0B,$06,$19
  DEFB $08,$E8,$3D
  DEFB $0A,$E8,$21
  DEFB $04,$03,$05
  DEFB $00,$15,$01
  DEFB $12,$16,$00
  DEFB $14,$1D,$16
  DEFB $FF
Screen115Layout:
  DEFB $14,$00,$17        ; screen 115: 9 objects
  DEFB $12,$06,$13
  DEFB $0E,$09,$15
  DEFB $0E,$0E,$15
  DEFB $0E,$14,$10
  DEFB $0E,$18,$10
  DEFB $12,$1C,$14
  DEFB $04,$08,$03
  DEFB $02,$18,$04
  DEFB $FF
Screen116Layout:
  DEFB $14,$EC,$17        ; screen 116: 13 objects
  DEFB $13,$0C,$3D
  DEFB $12,$0C,$17
  DEFB $12,$07,$00
  DEFB $0B,$0D,$19
  DEFB $0C,$14,$15
  DEFB $0C,$1B,$11
  DEFB $08,$0D,$3C
  DEFB $02,$0D,$11
  DEFB $04,$14,$05
  DEFB $06,$1B,$13
  DEFB $06,$1E,$14
  DEFB $00,$06,$01
  DEFB $FF
Screen117Layout:
  DEFB $13                ; screen 117: 8 objects
FontBase:
  DEFB $00,$3C,$12        ; GlyphBase of the font: glyph n at $D7E0 + 8n, so
  DEFB $E9,$17,$12        ; codes $00-$1F would fall on this layout; the glyphs
  DEFB $09,$22,$0B        ; start at Font $D8E0 (code $20)
  DEFB $07,$19,$08
  DEFB $00,$3D,$08
  DEFB $13,$0C,$13
  DEFB $0E,$16,$13
  DEFB $18,$16,$FF
Screen118Layout:
  DEFB $13,$00,$3D        ; screen 118: 10 objects
  DEFB $08,$E6,$3D
  DEFB $0A,$11,$1F
  DEFB $0E,$12,$20
  DEFB $0B,$03,$1C
  DEFB $00,$19,$1E
  DEFB $11,$08,$13
  DEFB $13,$0D,$0C
  DEFB $13,$17,$0C
  DEFB $0F,$1A,$2E
  DEFB $FF
Screen119Layout:
  DEFB $13,$00,$3C        ; screen 119: 5 objects
  DEFB $0D,$06,$10
  DEFB $0D,$16,$10
  DEFB $11,$0E,$14
  DEFB $09,$0A,$0B
  DEFB $FF
Screen120Layout:
  DEFB $13,$E9,$3C        ; screen 120: 12 objects
  DEFB $14,$09,$26
  DEFB $0E,$13,$11
  DEFB $0C,$0C,$2F
  DEFB $10,$0C,$2F
  DEFB $0C,$1B,$2F
  DEFB $10,$1B,$2F
  DEFB $0A,$0C,$26
  DEFB $04,$0C,$11
  DEFB $06,$19,$2C
  DEFB $08,$18,$2D
  DEFB $00,$00,$03
  DEFB $FF
Screen121Layout:
  DEFB $14,$00,$26        ; screen 121: 14 objects
  DEFB $0A,$00,$26
  DEFB $0C,$03,$2F
  DEFB $10,$03,$2F
  DEFB $0C,$1A,$2F
  DEFB $10,$1A,$2F
  DEFB $10,$14,$2C
  DEFB $12,$13,$2D
  DEFB $06,$14,$2C
  DEFB $08,$13,$2D
  DEFB $08,$06,$13
  DEFB $08,$09,$14
  DEFB $12,$0A,$27
  DEFB $10,$0F,$27
  DEFB $FF
Screen122Layout:
  DEFB $14,$00,$26        ; screen 122: 12 objects
  DEFB $0C,$06,$2F
  DEFB $10,$06,$2F
  DEFB $0A,$E9,$26
  DEFB $04,$05,$15
  DEFB $09,$0E,$1C
  DEFB $07,$12,$1C
  DEFB $07,$1C,$1C
  DEFB $03,$10,$05
  DEFB $14,$0B,$16
  DEFB $14,$12,$16
  DEFB $14,$19,$16
  DEFB $FF
Screen123Layout:
  DEFB $14,$E9,$26        ; screen 123: 12 objects
  DEFB $13,$09,$3D
  DEFB $0F,$05,$28
  DEFB $0D,$0F,$11
  DEFB $10,$1C,$1A
  DEFB $0B,$15,$2F
  DEFB $0F,$15,$2F
  DEFB $09,$15,$17
  DEFB $08,$15,$21
  DEFB $02,$15,$11
  DEFB $07,$00,$1C
  DEFB $0A,$04,$1C
  DEFB $FF
Screen124Layout:
  DEFB $13,$00,$3D        ; screen 124: 10 objects
  DEFB $12,$0B,$22
  DEFB $12,$0C,$21
  DEFB $0B,$06,$2F
  DEFB $0F,$06,$2F
  DEFB $0F,$0D,$2B
  DEFB $0F,$1C,$2B
  DEFB $09,$E9,$17
  DEFB $08,$E9,$21
  DEFB $03,$11,$2A
  DEFB $FF
