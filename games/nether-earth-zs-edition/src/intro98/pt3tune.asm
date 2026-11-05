; --------------------------------------------------------------------------------------------------------------------
; pt3tune.asm: "COOL WINTER" by KLIM / OHG '97: the Pro Tracker 3.3 module
;
; The module right after the player (Pt3Init + $E21), the Pro Tracker 3 file as the tracker saves it: "ProTracker 3.3
; compilation of COOL WINTER.......KLIM/OHG/'97", tone table 1, delay 5, 15 positions (loop to position 1), 9
; patterns, 8 samples, 10 ornaments; 2670 bytes, its last ornament ends at $D88E, the byte before the intro's code.
; Every pointer in it is an offset from its start: InitModule adds the address. It is src/res/intro98/cool-winter.pt3
; as it is (tools/intro98_res.py pt3 parses it to its last byte). The window read its header, positions, patterns,
; samples and ornaments ($CE85-$D873) while it played.
; --------------------------------------------------------------------------------------------------------------------

; the module: src/res/intro98/cool-winter.pt3
;
; COOL WINTER by KLIM of OHG (Omega Hackers Group, named in the scroller's
; greetings), 1997, as Pro Tracker 3.3 compiled it. Read only by the player
; (InitModule and the decoders through the pointers it sets up).
Pt3Module:
  INCBIN "res/intro98/cool-winter.pt3",$0000,2670
