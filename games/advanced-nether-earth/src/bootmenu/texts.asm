; --------------------------------------------------------------------------------------------------------------------
; texts.asm: the help menu's names and the 28 pages
;
; The strings PrintString prints (print.asm), 0-terminated, each starting with its font code (1 Latin, 2 Cyrillic).
; src/res/bootmenu/text holds them as UTF-8 (tools/bootmenu_res.py: the glyphs of the font in force, the codes as
; ‹lat› / ‹rus›, the pages in lines of 33). A page's text is one string: the printer wraps it at column 62, so the
; authors padded the lines with spaces to 33.
; --------------------------------------------------------------------------------------------------------------------

; "ОПИСАНИЕ ИГРЫ"
MenuDescription:
  INCBIN "res/text/menu.bin",$0000,15

; "ПРОИЗВОДСТВО РОБОТОВ"
MenuProduction:
  INCBIN "res/text/menu.bin",$000F,22

; "ХАРАКТЕРИСТИКА КОМПОНЕНТОВ"
MenuComponents:
  INCBIN "res/text/menu.bin",$0025,28

; "ПРОГРАММИРОВАНИЕ РОБОТОВ"
MenuProgramming:
  INCBIN "res/text/menu.bin",$0041,26

; "ОСОБЕННОСТИ ИГРЫ"
MenuFeatures:
  INCBIN "res/text/menu.bin",$005B,18

; "CREDITZ"
MenuCredits:
  INCBIN "res/text/menu.bin",$006D,9

; "ВЫХОД"
MenuExit:
  INCBIN "res/text/menu.bin",$0076,7

; "(C) 1998 ETERNITY INDUSTRY. KOVROV COOL CITY."
MenuCopyright:
  INCBIN "res/text/menu.bin",$007D,47

; "TOTAL CREDITZ": the intro's and the help's authors
CreditsPage1:
  INCBIN "res/text/credits.bin",$0000,695

; the intro's testers, the game's authors, the tape version's supplier
CreditsPage2:
  INCBIN "res/text/credits.bin",$02B7,761

; thanks, greetings, Eternity Industry's postal address
CreditsPage3:
  INCBIN "res/text/credits.bin",$05B0,763

; "Описание игры" 1: the Isignians' robots, the planetoid, its four bases
DescriptionPage1:
  INCBIN "res/text/description.bin",$0000,728

; 2: (continues) buying components, capturing factories
DescriptionPage2:
  INCBIN "res/text/description.bin",$02D8,761

; 3: what a captured factory gives, the start over the base
DescriptionPage3:
  INCBIN "res/text/description.bin",$05D1,761

; 4: the craft's shadow and shield, what it can do, the status panel
DescriptionPage4:
  INCBIN "res/text/description.bin",$08CA,761

; 5: resources in cosmodollars, the goal
DescriptionPage5:
  INCBIN "res/text/description.bin",$0BC3,431

; "Производство роботов" 1: landing on the base, choosing components
ProductionPage1:
  INCBIN "res/text/production.bin",$0000,761

; 2: taking a component off, what a robot must have, towers
ProductionPage2:
  INCBIN "res/text/production.bin",$02F9,761

; 3: cheap robots, 'ВЫПУСК' and 'ВЫХОД', releasing three
ProductionPage3:
  INCBIN "res/text/production.bin",$05F2,761

; 4: a released robot does nothing until programmed
ProductionPage4:
  INCBIN "res/text/production.bin",$08EB,134

; "Характеристика компонентов": electronics
ElectronicsPage:
  INCBIN "res/text/components.bin",$0000,563

; the A-bomb
BombPage:
  INCBIN "res/text/components.bin",$0233,365

; phasers
PhasersPage:
  INCBIN "res/text/components.bin",$03A0,200

; missiles
MissilesPage:
  INCBIN "res/text/components.bin",$0468,299

; cannons
CannonsPage:
  INCBIN "res/text/components.bin",$0593,233

; anti-gravs
AntigravPage:
  INCBIN "res/text/components.bin",$067C,233

; tracks
TracksPage:
  INCBIN "res/text/components.bin",$0765,299

; bipods
BipodsPage:
  INCBIN "res/text/components.bin",$0890,365

; "Программирование роботов" 1: landing on a robot, the combat mode, direct
; control
ProgrammingPage1:
  INCBIN "res/text/programming.bin",$0000,761

; 2: giving an order, leaving the robot
ProgrammingPage2:
  INCBIN "res/text/programming.bin",$02F9,761

; 3: when an order is refused, reprogramming
ProgrammingPage3:
  INCBIN "res/text/programming.bin",$05F2,563

; "Особенности игры" 1: wreck heaps, the A-bomb clears them
FeaturesPage1:
  INCBIN "res/text/features.bin",$0000,761

; 2: robots firing through walls, own robots in the line of fire
FeaturesPage2:
  INCBIN "res/text/features.bin",$02F9,761

; 3: friend or foe: the radar
FeaturesPage3:
  INCBIN "res/text/features.bin",$05F2,761

; 4: "ЗАХВАТ ЗАВОДОВ И БАЗ": 45 seconds in the yard, the flags
FeaturesPage4:
  INCBIN "res/text/features.bin",$08EB,761

; 5: capture with two robots, "Удачи !"
FeaturesPage5:
  INCBIN "res/text/features.bin",$0BE4,200
