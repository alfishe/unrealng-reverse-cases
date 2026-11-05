; gs.inc: the General Sound ports and the GS ROM commands the loaders and the drivers use (docs/09-sound.md 9.3; the
; firmware's command table COMTABH in TABLES_H.a80 of the GS ROM sources). Shared by src/disk and src/tape.

GsData          EQU $B3         ; write: the data latch (a command's parameter, a load's bytes); read: the card's reply
GsCommand       EQU $BB         ; write: the command latch; read: the status (bit 0 set until the card has taken
                                ; the last command, bit 7 set until it has read the last data byte)

; Commands (written to GsCommand after their parameter went to GsData)
GsReset         EQU $F4         ; COMF4: the card's software restarts cold (JP 0: the RAM test, every object gone)
GsLoadModule    EQU $30         ; COM30: load a module; its bytes follow on GsData between GsOpen and GsClose
GsPlayModule    EQU $31         ; COM31: play a module (data: its handle, 0 = the current one)
GsFxVolume      EQU $2B         ; COM2B: the effects' master volume (data 0-64)
GsModVolume     EQU $2A         ; COM2A: the module's master volume (data 0-64)
GsSelectFx      EQU $2E         ; COM2E: make an effect the current one (data: its handle)
GsLoadFx        EQU $3E         ; COM3E: load an effect; data 1: its samples unsigned (stored as sent), data 0: signed
                                ; (each byte stored + $80)
GsPlayFx        EQU $39         ; COM39: play an effect (data: its handle); it becomes the current effect
GsFxNote        EQU $40         ; COM40: the note of the current effect (data 0-95)
GsOpen          EQU $D1         ; LOAD: open the data stream of the load the last command started
GsClose         EQU $D2         ; LOAD: close it

; The 128K paging port and its values here: bit 4 the 48K ROM, bits 0-2 the RAM bank at $C000
Port7FFD        EQU $7FFD
