; --------------------------------------------------------------------------------------------------------------------
; maps.asm: The maps window
;
; The MAPS item: the frame and legend, the layer and area keys, the overview drawn by DrawOverview ($9C57).
; --------------------------------------------------------------------------------------------------------------------

; The maps window: clear, the frame, the legend and the keys 1-9 (inline texts)
;
; L1 5.
DrawMapsFrame:
  CALL ClearForMaps
  CALL PrintInline

; PrintInline codes of the frame and legend
MapsFrameText:
  INCBIN "res/text/inline/MapsFrame.bin",$0000,101

; DrawMapsKeys
DrawMapsKeys:
  CALL PrintInline

; PrintInline codes: the nine map choices
MapsKeysText:
  INCBIN "res/text/inline/MapsKeys.bin",$0000,67

; RET
DrawMapsEnd:
  RET

; Counts the passes of the maps window
MapsCounter:
  DEFB $00

; The MAPS menu item: show the overview map, pick a layer with the digit keys,
; until SPACE
;
; L1 5. The overview draws through $9B60, $9B76 and $9C57.
MapsWindow:
  XOR A
  LD (MapsDue),A
  CALL DrawMapsFrame
MapsWindowLoop:
  CALL HighlightMapKey
  CALL HighlightLayer
  CALL DrawOverview
  CALL HighlightLayer
  CALL HighlightMapKey
  LD A,(BudgetDue)
  AND A
  JR NZ,MapsWindowEnd
  LD A,(KeyRowSpace)
  AND $01
  JR Z,MapsWindowEnd
  CALL MapsKeys
  LD HL,MapsCounter
  INC (HL)
  JR MapsWindowLoop
MapsWindowEnd:
  CALL ClearTopBlack
  CALL DrawStatusPanel
  JP DrawView
