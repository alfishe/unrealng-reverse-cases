; driver.asm: neart021, the disk version's GS driver (248 bytes at $C000 of RAM bank 1), Tron 2002.
; docs/09-sound.md 9.4.
;
; The game calls it through GsSound / GsMenuSound (src/game), which page bank 1 at $C000 with interrupts off and
; every register saved, with A = the game's sound id (the value NE's Beep, SoundEffect and NuclearRumble used for
; their tones). GsDriver compares A with each id it knows and plays one GS effect; any other id returns silently.
; Two ids choose among three effects by the R register (RandomFx).
;
; The effect numbers are the handles the loader meant the card to give (src/disk/loader.asm: effects 1-14 in load
; order). On the disk the loader's lost commands leave only 9 effects on the card, so these numbers point at other
; samples or at none (docs/09-sound.md 9.2).
;
;   sjasmplus src/disk/driver.asm   ->  build/disk/driver.bin (248 bytes)

  INCLUDE "gs.inc"

FxNote          EQU $2F         ; the note every play sets: 47

  OUTPUT "build/disk/driver.bin"
  ORG $C000

; GsDriver: A = the game's sound id. The id list, first match wins
GsDriver:
    CP 1
    JR NZ,.not1
    LD A,1                      ; id 1: effect 1
    JP PlayEffect
.not1:
    CP 2
    JR NZ,.not2
    JP RandomFxKill             ; id 2 (a robot destroyed): effect 3, 4 or 2
.not2:
    CP 3
    JR NZ,.not3
    LD A,5                      ; id 3 (the construction menu opens): effect 5
    JP PlayEffect
.not3:
    CP 4
    JR NZ,.not4
    JP RandomFxShot             ; id 4 (a shot fired): effect 6, 7 or 8
.not4:
    CP $78
    JR NZ,.not78
    LD A,9                      ; id $78 (a menu choice): effect 9
    JP PlayEffect
.not78:
    CP $14
    JR NZ,.not14
    LD A,10                     ; id $14 (a menu cursor step): effect 10
    JP PlayEffect
.not14:
    CP $64
    JR NZ,.not64
    LD A,11                     ; id $64: effect 11
    JP PlayEffect
.not64:
    CP $50
    JR NZ,.not50
    LD A,12                     ; id $50: effect 12
    JP PlayEffect
.not50:
    CP $C8
    JR NZ,.notC8
    LD A,1                      ; id $C8 (a robot leaves the factory): effect 1
    JP PlayEffect
.notC8:
    CP $78                      ; never true: $78 was taken above
    JR NZ,.not78b
    LD A,1
    JP PlayEffect
.not78b:
    CP 9
    JR NZ,.not9
    LD A,14                     ; id 9 (a burst of the nuclear blast): effect 14
    JP PlayEffect
.not9:
    CP $0A
    JR NZ,.not0A
    LD A,13                     ; id $0A (a shot ends): effect 13
    JP PlayEffect
.not0A:
    RET                         ; any other id: silent

; RandomFxKill: H = R; three windows of the counter pick the effect. Each window counts C down from its top for B
; steps and stops when C = H: H in $01-$50 -> effect 3, $51-$A0 -> 4, $A1-$FF -> 2, and H = 0 (no window) -> 3.
; R's bit 7 only changes by LD R,A, which neither the game nor the loader does: H stays $00-$7F, so effect 2 is
; never chosen (3 for $00-$50, 4 for $51-$7F)
RandomFxKill:
    LD A,R
    LD B,$50
    LD C,$50
    LD H,A
.low:
    LD A,H
    CP C
    JR Z,.fx3
    DEC B
    DEC C
    LD A,B
    CP 0
    JR NZ,.low
    LD B,$50
    LD C,$A0
.mid:
    LD A,H
    CP C
    JR Z,.fx4
    DEC B
    DEC C
    LD A,B
    CP 0
    JR NZ,.mid
    LD B,$5F
    LD C,$FF
.high:
    LD A,H
    CP C
    JR Z,.fx2
    DEC B
    DEC C
    LD A,B
    CP 0
    JR NZ,.high
.fx3:
    LD A,3
    JP PlayEffect
.fx4:
    LD A,4
    JP PlayEffect
.fx2:
    LD A,2
    JP PlayEffect

; RandomFxShot: the same windows for id 4: effect 6, 7 or 8 (8 never, as 2 above)
RandomFxShot:
    LD A,R
    LD B,$50
    LD C,$50
    LD H,A
.low:
    LD A,H
    CP C
    JR Z,.fx6
    DEC B
    DEC C
    LD A,B
    CP 0
    JR NZ,.low
    LD B,$50
    LD C,$A0
.mid:
    LD A,H
    CP C
    JR Z,.fx7
    DEC B
    DEC C
    LD A,B
    CP 0
    JR NZ,.mid
    LD B,$5F
    LD C,$FF
.high:
    LD A,H
    CP C
    JR Z,.fx8
    DEC B
    DEC C
    LD A,B
    CP 0
    JR NZ,.high
.fx6:
    LD A,6
    JP PlayEffect
.fx7:
    LD A,7
    JP PlayEffect
.fx8:
    LD A,8
    JP PlayEffect

; PlayEffect: A = the GS effect. Sets the note of the current effect to 47 (#40), then plays effect A (#39), with no
; wait for the card. The note goes to the effect played last (CURFX), not to this one: an effect's first play keeps
; the note it was loaded with
PlayEffect:
    LD H,A
    LD A,FxNote
    OUT (GsData),A
    LD A,GsFxNote
    OUT (GsCommand),A
    LD A,H
    OUT (GsData),A
    LD A,GsPlayFx
    OUT (GsCommand),A
    RET
