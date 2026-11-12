; --------------------------------------------------------------------------------------------------------------------
; buffers.asm: The work space between the pieces: never loaded, cleared by the loader, filled by Start
;
; $70A8-$A5FF lies between the code (15 sectors from $61A8) and the graphics ($A600): the loader's clear leaves zeros,
; Start builds the rhombus phases there and reads the catalogue into Catalogue $9D00.
; --------------------------------------------------------------------------------------------------------------------

  ORG $70A8

; Not written: SoundOff reads its zeros at $7530
Unused1:
  DEFS $0558

; RombColumnOrder's copy (40)
RombColumns:
  DEFS $5C

; RombPhaseOffsets's copy (9)
RombOffsets:
  DEFS $32

; Phase 8's threshold: $40 for set A, $80 for set B
RombThreshold:
  DEFS $0A

; 40 bytes: 1 for each column the phase keeps
PhaseMask:
  DEFS $28

; The phase's start column
PhaseOffset:
  DEFS $01

; Not used
Unused2:
  DEFS $3F

; The rhombus being turned (200)
RombWork:
  DEFS $C8

; Not used
Unused3:
  DEFS $38

; Set A (turning about the vertical axis): phases 0-8, 256 bytes each
PhasesA:
  DEFS $0900

; Set A: phases 9-16, the mirror images of 0-7
MirrorsA:
  DEFS $0800

; Not used
Unused4:
  DEFS $0100

; Set B (turning about the horizontal axis): phases 0-8
PhasesB:
  DEFS $0900

; Set B: phases 9-16
MirrorsB:
  DEFS $0800

; Not used
Unused5:
  DEFS $0100

; RotateSprite's work (200)
RotateBuffer:
  DEFS $C8

; Not used
Unused6:
  DEFS $38

; The disk's catalogue: track 0 sectors 0-7, 128 entries of 16 bytes
Catalogue:
  DEFS $0800

; Not used: Chars points here (Font - 256)
FontBase:
  DEFS $0100
