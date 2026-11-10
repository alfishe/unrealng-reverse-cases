; --------------------------------------------------------------------------------------------------------------------
; random.asm: The random generator
;
; Random: a Lehmer generator modulo 65 537 on RandomSeed, which NewLandscape sets from the gene; every random choice
; of the landscape, the growth, the trips and the disasters comes from it (the tornado sprite alone uses LD A,R).
; --------------------------------------------------------------------------------------------------------------------

; The random seed, 16 bits; NewLandscape sets it to the gene (Gene $6A8C); read
; directly by RandomDisaster, RadiationCell, Poll and NewCityItem (the new
; gene)
RandomSeed:
  DEFW $0000

; The generator: seed' = (254 (seed + 1) - 1) mod 65 537, 254 a primitive root:
; period 65 536; A = the seed's low byte
;
; RandomSeed $5CC4 holds the seed. The arithmetic: H = the seed's low byte, L =
; $FD, so A:HL = 256 seed + 253; two SBC HL,DE take 2 seed off (254 seed + 253
; in 24 bits), then the high byte is subtracted from the low 16 bits, which is
; mod 65537 because 65536 = -1; a borrow adds 1. Registers but A are kept. L1
; 343 327: the noise, the landscape, the simulation's random choices, the
; disasters.
Random:
  PUSH HL
  PUSH DE
  PUSH BC
  LD DE,(RandomSeed)
  LD H,E
  LD L,$FD
  LD A,D
  OR A
  LD B,$00
  SBC HL,DE
  SBC A,B
  SBC HL,DE
  SBC A,B
  LD E,A
  LD D,B
  SBC HL,DE
  JR NC,RandomStore
  INC HL
RandomStore:
  LD (RandomSeed),HL
  LD A,H                  ; LD A,H: dead, the next LD A,(RandomSeed) overwrites
                          ; it
  LD A,(RandomSeed)
  POP BC
  POP DE
  POP HL
  RET
