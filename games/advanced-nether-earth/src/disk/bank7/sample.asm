; --------------------------------------------------------------------------------------------------------------------
; sample.asm: the boot menu's digitised sample
;
; The boot menu's key 3 (the boot program's $6273, in d05) pages bank 7 in and plays $31F6 = 12790 of these bytes from
; $CE09 through AY registers 8, 9 and 10 (the three volumes at once, tone and noise off): one byte every 307 T-states,
; 11401 samples a second at 3.5 MHz, about 1.1 s. Each byte is an AY volume, 0-11 in this sample; the last byte
; ($FFFF) is never played.
; --------------------------------------------------------------------------------------------------------------------

; The sample: 12791 AY volumes, one a byte (src/res/diskmod/sample.wav)
Sample:
  INCBIN "res/diskmod/sample.bin",$0000,12791
