; --------------------------------------------------------------------------------------------------------------------
; disasters.asm: The disasters
;
; Fire, flood, earthquake (both, with a long noise), the air crash, the tornado and the meltdown: RandomDisaster draws
; one with 1 in 2048 every 16 UI passes unless DISABLE ALL; the DISASTERS menu sets DisasterDue directly.
; --------------------------------------------------------------------------------------------------------------------

; message $16 (FIRES HAVE BEEN DETECTED), the noise, Ignite 1 in 128 cells
;
; Used by the routine at RunDisaster.
FireDisaster:
  LD A,$16
  CALL SetAdvice
  CALL FireNoise

; Every map cell: 1 in 128 Ignite
;
; Used by the routine at Earthquake.
StartFires:
  LD HL,CityMap
  LD BC,$2400
StartFiresLoop:
  CALL Random
  AND $7F
  CALL Z,Ignite
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,StartFiresLoop
  RET

; A flammable cell (flags bit 7) but trees: fire $45
;
; Used by the routines at CrashCell and StartFires.
Ignite:
  LD A,(HL)
  BIT 7,A
  RET NZ
  CALL CellFlagsOf
  BIT 7,A
  RET Z
  LD A,(HL)
  CP $06
  RET Z
  LD (HL),$45
  RET

; message $17 (COASTAL FLOODING DETECTED), the noise, the coast floods
;
; Used by the routine at RunDisaster.
FloodDisaster:
  LD A,$17
  CALL SetAdvice
  CALL FloodNoise

; Every coast cell (1-5): 1 in 32 flood $44; FloodLeft = 50
;
; Used by the routine at Earthquake.
StartFlood:
  LD HL,CityMap
  LD BC,$2400
StartFloodLoop:
  LD A,(HL)
  BIT 7,A
  JR NZ,StartFloodNext
  AND A
  JR Z,StartFloodNext
  CP $02
  JR Z,StartFloodNext
  CP $06
  JR NC,StartFloodNext
  CALL Random
  AND $1F
  JR NZ,StartFloodNext
  LD (HL),$44
StartFloodNext:
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,StartFloodLoop
  LD A,$32
  LD (FloodLeft),A
  RET

; 127 NoiseBursts, gate falling
;
; Used by the routine at FireDisaster.
FireNoise:
  LD B,$7F
FireNoiseLoop:
  PUSH BC
  LD A,B
  AND $3F
  LD E,A
  CALL NoiseBurst
  POP BC
  DJNZ FireNoiseLoop
  RET

; 127 NoiseBursts, gate rising
;
; Used by the routine at FloodDisaster.
FloodNoise:
  LD B,$7F
FloodNoiseLoop:
  PUSH BC
  LD A,B
  CPL
  AND $7F
  LD E,A
  CALL NoiseBurst
  POP BC
  DJNZ FloodNoiseLoop
  RET

; message $18 (MAJOR EARTHQUAKE DETECTED), a long noise, fires and the flood
;
; Used by the routine at RunDisaster.
Earthquake:
  LD A,$18
  CALL SetAdvice
  LD B,$FF
  LD C,$00
EarthquakeNoise:
  PUSH BC
  LD E,C
  SRL E
  SRL E
  SRL E
  SRL E
  CALL NoiseBurst
  POP BC
  INC C
  DJNZ EarthquakeNoise
  CALL StartFires
  JR StartFlood

; Unless disasters are off ($A43D): with 1 in 2048 a disaster 1-6 (the meltdown
; with 1 in 8 of its draws)
;
; Used by the routine at Periodic.
RandomDisaster:
  LD A,(DisastersOff)
  AND A
  RET NZ
  CALL Random
  LD HL,(RandomSeed)
  LD A,H
  AND $07
  OR L
  RET NZ
  CALL Random
  AND $07
  RET Z
  CP $07
  RET Z
  CP $06
  JR NZ,RandomDisasterSet
  CALL Random
  AND $07
  RET NZ
  LD A,$06
RandomDisasterSet:
  LD (DisasterDue),A
  RET

; The disaster RunDisaster starts (0 none)
DisasterDue:
  DEFB $00

; 1 fire, 2 flood, 3 earthquake, 4 air crash, 5 tornado, 6 meltdown
;
; Used by the routine at Periodic.
RunDisaster:
  LD HL,DisasterDue
  LD A,(HL)
  AND A
  RET Z
  LD (HL),$00
  CP $01
  JP Z,FireDisaster
  CP $02
  JP Z,FloodDisaster
  CP $03
  JR Z,Earthquake
  CP $04
  JP Z,AirCrash
  CP $05
  JP Z,StartTornado
  CP $06
  JP Z,NuclearMeltdown
  RET
