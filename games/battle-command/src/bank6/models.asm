; --------------------------------------------------------------------------------------------------------------------
; models.asm: The model scripts of the maps (RunScript $990F format) and the markers' points
;
; RunScript scripts: an opcode byte and its operands, $FF the end (the opcodes in the description of OpcodeTable
; $98E1).
; --------------------------------------------------------------------------------------------------------------------

  ORG $E512

; The scripts of the map objects
;
; Run by DrawMapObjects. `$E54F` is read by nothing.
MapModels:
  DEFB $02,$04,$00,$0E,$01,$04,$04,$00,$04,$08,$0C,$FF
MapModelNegative:
  DEFB $02,$04,$00,$0E,$01,$04,$01,$00,$04,$08,$0C,$FF
MapModelOther:
  DEFB $02,$04,$00,$03,$80,$01,$82,$03,$C0,$FF
MapModelKind6:
  DEFB $01,$03,$82,$4B,$00,$81,$4A,$8B,$4C,$8A,$8C,$44
  DEFB $0C,$8B,$8C,$47,$02,$81,$4E,$81,$8E,$45,$0E,$82
  DEFB $8E,$46,$FF
MapModelSpare:
  DEFB $02,$08,$00,$13,$02,$04,$01,$00,$04,$08,$0C,$04
  DEFB $00,$10,$14,$18,$1C,$FF

  ORG $E5D5

; The scripts of the markers
;
; Run by DrawMarkerModel.
MarkerModels:
  DEFB $02,$04,$00,$03,$80,$01,$82,$03,$C0,$FF
MarkerModelB:
  DEFB $02,$07,$00,$03,$80,$01,$02,$03,$04,$05
  DEFB $80,$06,$C0,$FF
MarkerModelC:
  DEFB $02,$04,$00,$03,$80,$02,$81,$03,$C0,$FF
MarkerModelD:
  DEFB $02,$04,$00,$0E,$01,$04,$07,$00,$04,$08
  DEFB $0C,$FF

; The markers' points: a count, then X, Y byte pairs
;
; Read by DrawMarkerModel.
MarkerPoints:
  DEFB $04,$B0,$50,$50,$50,$00,$50,$00,$B0
MarkerPointsB:
  DEFB $07,$B0,$50,$32,$50,$3C,$46,$3C,$1E
  DEFB $32,$00,$B0,$00,$B0,$B0
MarkerPointsC:
  DEFB $04,$B0,$50,$50,$50,$50,$B0,$B0,$B0
