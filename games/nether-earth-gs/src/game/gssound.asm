; --------------------------------------------------------------------------------------------------------------------
; gssound.asm: The bridge to the General Sound driver: page the driver in, call it, page bank 0 back
;
; Two routines the conversion put in the 150 zero bytes Nether Earth left between its sprites and Start ($A569-$A5A8;
; the first of them, $A569, was the last graphic byte of the dotted block sprite, see SprBlockDottedRows). Every sound
; of the game goes through them: Beep, SoundEffect and NuclearRumble call GsSound with a sound id in A,
; ConstructionMenu calls GsMenuSound. Neither makes a sound itself: they page the RAM page of the GS driver in at
; $C000 with port $7FFD (bank 1 on the disk, bank 6 on Hood's tape: DriverBank, case.json), call GsDriver ($C000) with
; the id and page bank 0, the game's own $C000-$FFFF, back.
;
; The 48 BASIC ROM stays paged (bit 4 of $7FFD set) so the game's calls into the ROM (the tape save and load) keep
; working. Interrupts are off while bank 0 is out: PlayInterrupt and the IM 2 table live in bank 0 ($D566,
; $FDFD-$FF00), so an interrupt with the driver paged would run the driver's bytes. The driver itself
; (src/disk/driver.asm) maps the id to a GS effect and sends it; an id it does not list is silent.
;
; The GS effect numbers given in the comments are the driver's (src/disk/driver.asm), which is what Hood's tape plays.
; On the disk the loader lost 5 of the 14 effect loads and the card numbers the other 9 in a row, so most ids play
; another sample or none there (docs/09-sound.md 9.2).
; --------------------------------------------------------------------------------------------------------------------

; Construction menu sound: GS id 3, then ConstructionMenu's first instruction
; LD IY,Robots
;
; Called once as the first instruction of ConstructionMenu ($C849), in the
; place of its LD IY,Robots (4 bytes: CALL GsMenuSound and a NOP). Interrupts
; off, the driver page in ($7FFD = PageRom48 + DriverBank), GsDriver with A = 3
; (the construction menu opens: GS effect 5), bank 0 back, then the replaced LD
; IY,Robots, EI and back. Unlike GsSound it keeps no register: A, BC and the
; flags are lost, which ConstructionMenu does not mind (it sets them next). It
; ends with EI where Nether Earth's ConstructionMenu ran with interrupts as
; they were (StartInterrupt is the handler there, EI; RET).
GsMenuSound:
  DI                      ; no interrupt while the driver page is in
  LD A,PageRom48|DriverBank ; the driver's page at $C000, the 48 BASIC ROM
  LD BC,$7FFD
  OUT (C),A               ; page it in
  LD A,$03                ; id 3: the construction menu opens
  CALL GsDriver           ; the driver (in the paged-in RAM page)
  LD A,PageRom48          ; bank 0 back at $C000
  LD BC,$7FFD
  OUT (C),A               ; the game's $C000-$FFFF again
  LD IY,Robots            ; ConstructionMenu's first instruction, moved here:
                          ; IY = the first robot record
  EI                      ; interrupts on
  RET

; Play game sound A through the GS driver; every register kept
;
; The entry of every sound of the game: Beep ($CCAC: the menu clicks and
; confirmations, A the id), SoundEffect ($D5C4: the shots, ids 4, $0A, 2) and
; NuclearRumble ($BAEE: id 9). Interrupts off, HL, DE, BC, AF, IX and IY
; pushed, the id kept in H while A pages the driver in ($7FFD = PageRom48 +
; DriverBank), GsDriver with A = the id, bank 0 back, the registers restored,
; EI. The driver writes the GS ports only; what it does with each id is in
; src/disk/driver.asm.
;
; Called from inside PlayInterrupt (through SoundEffect) as well as from the
; main code: the EI at its end turns interrupts on inside the interrupt
; handler, before PlayInterrupt has restored its registers. A second interrupt
; does not come that soon (the handler ends within the frame), so nothing nests
; in practice.
GsSound:
  DI                      ; no interrupt while the driver page is in
  PUSH HL                 ; keep every register the driver might change
  PUSH DE
  PUSH BC
  PUSH AF
  PUSH IX
  PUSH IY
  LD H,A                  ; the id
  LD A,PageRom48|DriverBank ; the driver's page at $C000, the 48 BASIC ROM
  LD BC,$7FFD
  OUT (C),A               ; page it in
  LD A,H                  ; A = the id
  CALL GsDriver           ; the driver
  LD A,PageRom48          ; bank 0 back at $C000
  LD BC,$7FFD
  OUT (C),A               ; the game's $C000-$FFFF again
  POP IY                  ; the registers back
  POP IX
  POP AF
  POP BC
  POP DE
  POP HL
  EI                      ; interrupts on
  RET

; Free space up to Start (87 zero bytes)
;
; Zero up to Start at $A600: what is left of the 150 bytes Nether Earth kept
; free here after GsMenuSound and GsSound took 64. Never read or written in
; recording r1.
SpriteSpare:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00
