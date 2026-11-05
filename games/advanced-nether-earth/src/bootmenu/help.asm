; --------------------------------------------------------------------------------------------------------------------
; help.asm: the help items: pictures and typed pages
;
; Each of the six help items (ItemRoutines) clears the screen, sets TypeAtOnce = 0 (the typewriter) and shows its
; pages: per page the picture is unpacked again (ScreenDepack), the text cursor set to row 1 (rows 5-9 for the parts
; of item 3), column 30, and ShowPage types the page's string into the right half (columns 30-62 of 64 four-pixel
; cells, 33 a line) and waits: ENTER or 0 the next page, SPACE the help menu (also while it types). After the last
; page JP HelpMenu. Items 3, 5 and 6 wait one more frame (HALT) between their pages.
;
; Typing takes about a quarter of a frame a character (PrintString's delay): a full page of 759 characters about 200
; frames. Items: 1 "Описание игры" 5 pages, 2 "Производство роботов" 4, 3 "Характеристика компонентов" 8 (a part and
; its picture a page: electronics, A-bomb, phasers, missiles, cannons, anti-gravs, tracks, bipods), 4
; "Программирование роботов" 3, 5 "Особенности игры" 5, 6 "CREDITZ" 3. The texts are in texts.asm
; (src/res/bootmenu/text).
; --------------------------------------------------------------------------------------------------------------------

; help item 6 "CREDITZ": CreditsPicture, 3 pages
HelpCredits:
  CALL ClearScreen
  XOR A                   ; the typewriter
  LD (TypeAtOnce),A
  LD HL,CreditsPicture    ; page 1: the picture
  CALL ScreenDepack
  LD DE,1*256+30          ; at row 1, column 30
  LD (PrintAt),DE
  LD HL,CreditsPage1      ; the text
  CALL ShowPage
  HALT                    ; a frame between the pages (items 3, 5 and 6 only)
  LD HL,CreditsPicture
  CALL ScreenDepack
  LD DE,1*256+30
  LD (PrintAt),DE
  LD HL,CreditsPage2
  CALL ShowPage
  HALT
  LD HL,CreditsPicture
  CALL ScreenDepack
  LD DE,1*256+30
  LD (PrintAt),DE
  LD HL,CreditsPage3
  CALL ShowPage
  HALT
  JP HelpMenu

; help item 5 "Особенности игры": FeaturesPicture, 5 pages
HelpFeatures:
  CALL ClearScreen
  XOR A
  LD (TypeAtOnce),A
  LD HL,FeaturesPicture
  CALL ScreenDepack
  LD DE,1*256+30
  LD (PrintAt),DE
  LD HL,FeaturesPage1
  CALL ShowPage
  HALT
  LD HL,FeaturesPicture
  CALL ScreenDepack
  LD DE,1*256+30
  LD (PrintAt),DE
  LD HL,FeaturesPage2
  CALL ShowPage
  HALT
  LD HL,FeaturesPicture
  CALL ScreenDepack
  LD DE,1*256+30
  LD (PrintAt),DE
  LD HL,FeaturesPage3
  CALL ShowPage
  HALT
  LD HL,FeaturesPicture
  CALL ScreenDepack
  LD DE,1*256+30
  LD (PrintAt),DE
  LD HL,FeaturesPage4
  CALL ShowPage
  HALT
  LD HL,FeaturesPicture
  CALL ScreenDepack
  LD DE,1*256+30
  LD (PrintAt),DE
  LD HL,FeaturesPage5
  CALL ShowPage
  HALT
  JP HelpMenu

; type the string at HL, then wait for ENTER / 0 (back) or SPACE (the help
; menu)
;
; Used by the routines at HelpCredits, HelpFeatures, HelpDescription,
; HelpProduction, HelpProgramming and HelpComponents.
ShowPage:
  CALL PrintString
  JP WaitPageKey

; help item 1 "Описание игры": DescriptionPicture, 5 pages
HelpDescription:
  XOR A
  LD (TypeAtOnce),A
  CALL ClearScreen
  LD HL,DescriptionPicture
  CALL ScreenDepack
  LD DE,1*256+30
  LD (PrintAt),DE
  LD HL,DescriptionPage1
  CALL ShowPage
  LD HL,DescriptionPicture
  CALL ScreenDepack
  LD DE,1*256+30
  LD (PrintAt),DE
  LD HL,DescriptionPage2
  CALL ShowPage
  LD HL,DescriptionPicture
  CALL ScreenDepack
  LD DE,1*256+30
  LD (PrintAt),DE
  LD HL,DescriptionPage3
  CALL ShowPage
  LD HL,DescriptionPicture
  CALL ScreenDepack
  LD DE,1*256+30
  LD (PrintAt),DE
  LD HL,DescriptionPage4
  CALL ShowPage
  LD HL,DescriptionPicture
  CALL ScreenDepack
  LD DE,1*256+30
  LD (PrintAt),DE
  LD HL,DescriptionPage5
  CALL ShowPage
  JP HelpMenu

; help item 2 "Производство роботов": ProductionPicture, 4 pages
HelpProduction:
  XOR A
  LD (TypeAtOnce),A
  CALL ClearScreen
  LD HL,ProductionPicture
  CALL ScreenDepack
  LD DE,1*256+30
  LD (PrintAt),DE
  LD HL,ProductionPage1
  CALL ShowPage
  LD HL,ProductionPicture
  CALL ScreenDepack
  LD DE,1*256+30
  LD (PrintAt),DE
  LD HL,ProductionPage2
  CALL ShowPage
  LD HL,ProductionPicture
  CALL ScreenDepack
  LD DE,1*256+30
  LD (PrintAt),DE
  LD HL,ProductionPage3
  CALL ShowPage
  LD HL,ProductionPicture
  CALL ScreenDepack
  LD DE,1*256+30
  LD (PrintAt),DE
  LD HL,ProductionPage4
  CALL ShowPage
  JP HelpMenu

; help item 4 "Программирование роботов": ProgrammingPicture, 3 pages
HelpProgramming:
  CALL ClearScreen
  XOR A
  LD (TypeAtOnce),A
  LD HL,ProgrammingPicture
  CALL ScreenDepack
  LD DE,1*256+30
  LD (PrintAt),DE
  LD HL,ProgrammingPage1
  CALL ShowPage
  LD HL,ProgrammingPicture
  CALL ScreenDepack
  LD DE,1*256+30
  LD (PrintAt),DE
  LD HL,ProgrammingPage2
  CALL ShowPage
  LD HL,ProgrammingPicture
  CALL ScreenDepack
  LD DE,1*256+30
  LD (PrintAt),DE
  LD HL,ProgrammingPage3
  CALL ShowPage
  JP HelpMenu

; help item 3 "Характеристика компонентов": a part a page, its picture each
;
; Electronics, A-bomb, phasers, missiles, cannons, anti-gravs, tracks, bipods;
; the text starts at row 5, 7, 9, 8, 9, 8, 8, 7 (under the part's name in the
; picture).
HelpComponents:
  XOR A
  LD (TypeAtOnce),A
  CALL ClearScreen
  LD HL,ElectronicsPicture
  CALL ScreenDepack
  LD DE,5*256+30
  LD (PrintAt),DE
  LD HL,ElectronicsPage
  CALL ShowPage
  HALT
  LD HL,BombPicture
  CALL ScreenDepack
  LD DE,7*256+30
  LD (PrintAt),DE
  LD HL,BombPage
  CALL ShowPage
  HALT
  LD HL,PhasersPicture
  CALL ScreenDepack
  LD DE,9*256+30
  LD (PrintAt),DE
  LD HL,PhasersPage
  CALL ShowPage
  HALT
  LD HL,MissilesPicture
  CALL ScreenDepack
  LD DE,8*256+30
  LD (PrintAt),DE
  LD HL,MissilesPage
  CALL ShowPage
  HALT
  LD HL,CannonsPicture
  CALL ScreenDepack
  LD DE,9*256+30
  LD (PrintAt),DE
  LD HL,CannonsPage
  CALL ShowPage
  HALT
  LD HL,AntigravPicture
  CALL ScreenDepack
  LD DE,8*256+30
  LD (PrintAt),DE
  LD HL,AntigravPage
  CALL ShowPage
  HALT
  LD HL,TracksPicture
  CALL ScreenDepack
  LD DE,8*256+30
  LD (PrintAt),DE
  LD HL,TracksPage
  CALL ShowPage
  HALT
  LD HL,BipodsPicture
  CALL ScreenDepack
  LD DE,7*256+30
  LD (PrintAt),DE
  LD HL,BipodsPage
  CALL ShowPage
  JP HelpMenu
