; --------------------------------------------------------------------------------------------------------------------
; intrologo.asm: the ZS logo's cells and the robot box's header
;
; LogoMask is the logo LogoColour paints in attribute cells (src/res/intro98/logo.png); RobotHeader the five bytes in
; front of the robot's code, no code reads them.
; --------------------------------------------------------------------------------------------------------------------

; the ZS logo: 8 x 8 cells, 1 = painted (src/res/intro98/logo.png)
;
; Read by LogoColour every frame: row by row, the cells of the block at column
; 12, row 0 that take the colour.
LogoMask:
  INCBIN "res/intro98/logo-mask.bin",$0000,64

; the robot box: column 13, row 16, 6 x 8 cells, attribute 6
;
; Column 13, row 16, width 6, height 8 cells, attribute 6 (yellow ink on
; black): exactly the box RobotStream draws into (tools/intro98_res.py decodes
; every write of it inside that box) and the colour IntroMain gives the bottom
; third. Nothing reads these bytes (no read in the window): the header the
; picture's packer put in front of its depacker, kept with it.
RobotHeader:
  DEFB $0D,$10,$06,$08,$06
