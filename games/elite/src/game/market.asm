; --------------------------------------------------------------------------------------------------------------------
; market.asm: Buying and selling cargo and equipment: the quantity editor, the checks and the undo, the nova's refugees
;
; The three docked trading screens (keys 2, 3 and 4) walk the 17 commodities or the 14 equipment items with the
; pointers of MarketRow / HoldRow. For each row the player types a quantity (QuantityKeys: one or two digits, ENTER
; skips the row, another key leaves the page); every digit runs the screen's check (BuyCheck, SellCheck, EquipAccept)
; on a copy of the cash, the hold, the stock and the free space (SaveTrade), and a refusal (QUANTITY?, CASH?, CARGO?)
; puts the copy back (RestoreTrade). No recording traded: the module is known from the code only, except the pages'
; headings (d1).
;
; The nova mission's two pages live here too: docking in the nova's system asks THE SUN IS GOING NOVA, WILL YOU SAVE
; US (Y/N)?; Y fits a large cargo bay and fills the hold with refugees (MissionFlags bit 5); docking anywhere else
; with them aboard gives 100 units of gem-stones and the bay (35 tons) back.
; --------------------------------------------------------------------------------------------------------------------

; Key 2: the refugees' question in the nova's system, the inventory with
; refugees aboard, else the buy page
;
; Used by the routine at ScreenBuy.
BuyCargo:
  LD A,(MissionFlags)
  BIT 5,A
  JR NZ,BuyCargoInventory
  LD A,(NovaMission)
  AND A
  JR Z,BuyCargoPage
  LD DE,ScannerSave+$0017
  LD HL,$0201
  CALL ColourPage
  LD A,$B6
  LD (CrossX),A
  LD A,$76
  LD (CrossY),A
  LD A,$3D
  LD (ChartRadius),A
  CALL DrawChartCircleVector
  CALL WaitKey
  CP $59
  JR NZ,BuyCargoInventory
  LD (Equipment),A
  XOR A
  LD (FreeSpace),A
  LD HL,CargoHold
  LD B,$11
BuyCargoLoop:
  LD (HL),A
  INC HL
  DJNZ BuyCargoLoop
  LD HL,MissionFlags
  SET 5,(HL)
BuyCargoInventory:
  CALL Wait36
  JP InventoryScreen

; The trading pages' colour bands: 30 cells and a gap of a row, 30 cells
MarketBands:
  DEFB $F1,$F0

; The firearms' price back to 70.4 Cr ($02C0 tenths) when ZeroFirearms cleared
; it
;
; Used by the routine at MarketPrices.
FirearmsPrice:
  LD HL,Prices+$0015
  LD A,(HL)
  AND A
  RET NZ
  LD (HL),$02
  DEC HL
  LD A,$C0
  LD (HL),A
  RET
; This entry point is used by the routine at BuyCargo.
BuyCargoPage:
  CALL FirearmsPrice      ; UNIT QUANTITY PRODUCT UNIT PRICE FOR SALE (code
                          ; $FF), then each commodity in stock with its prompt
  CALL ClearScreen
  CALL ColumnInline
  DEFB $10
  LD A,$FF
  CALL PrintCodeLine
  LD DE,MarketBands
  CALL ColourBands
  CALL FillAttrRow
  CALL TradePointers
  LD HL,Seeds+$000F
  LD (StockPointer),HL
BuyCargoRow:
  LD HL,(HoldPointer)
  INC HL
  LD (HoldPointer),HL
  CALL MarketRow
  JR C,BuyCargoItem
  CALL SaveCursor
BuyCargoAsk:
  CALL QuantityPrompt
  LD HL,BuyCheck
  CALL QuantityKeys
  JR NC,BuyCargoDone
  CP $01
  JR Z,BuyCargoAsk
  CP $02
  JR Z,BuyCargoNext
  JR BuyCargoEnd
BuyCargoDone:
  CALL ShowCash
BuyCargoNext:
  CALL RestoreCursor
BuyCargoItem:
  LD HL,MarketItem
  INC (HL)
  LD A,(HL)
  CP $11
  JR C,BuyCargoRow
BuyCargoEnd:
  JP InventoryScreen

; All 768 attributes set to A (no code calls it; known from the code only)
FillAllAttrs:
  LD HL,$5800
  CALL FillPage256
  CALL FillPage256

; 256 bytes of A from HL
;
; Used by the routine at FillAllAttrs.
FillPage256:
  LD B,$00
FillPage256Loop:
  LD (HL),A
  INC HL
  DJNZ FillPage256Loop
  RET

; DELETE after the first digit: the digit cleared, the trade undone, start
; again
;
; Used by the routine at QuantityKeys.
QuantityDelete:
  CALL DeleteChar
  CALL RestoreTrade
  JR QuantityFirst

; Read a quantity into Quantity, running the check at HL after each digit;
; carry: A = 1 again, 2 the next row, else leave
;
; The first key: ENTER is "next row" (A = 2), 1-9 a digit, any other key but
; DELETE ends the page; the second: ENTER accepts, 0-9 makes Quantity ten times
; more plus the digit (AddDigit) after the trade is undone and checked again,
; DELETE starts again. The check returns carry to refuse.
QuantityKeys:
  LD (QuantityCheck),HL
; This entry point is used by the routine at QuantityDelete.
QuantityFirst:
  XOR A
  LD (Quantity),A
QuantityFirstKey:
  CALL WaitKey
  CP $0D
  JR Z,QuantitySkip
  CP $31
  JR C,QuantityFirstKey
  CP $FE
  JR Z,QuantityFirstKey
  CP $3A
  JR NC,QuantityRefused
  LD B,A
  SUB $30
  LD (Quantity),A
  LD A,B
  CALL PrintCode
  LD HL,(QuantityCheck)
  CALL CallCheck
  JR C,QuantityRefused
QuantitySecond:
  CALL WaitKey
  CP $0D
  RET Z
  CP $30
  JR C,QuantitySecond
  CP $FE
  JR Z,QuantityDelete
  CP $3A
  JR NC,QuantityRefused
  LD D,A
  SUB $30
  LD B,A
  LD HL,Quantity
  CALL AddDigitVector
  CALL RestoreTrade
  LD HL,(QuantityCheck)
  CALL CallCheck
  JR C,QuantityRefused
  AND A
  RET
QuantitySkip:
  LD A,$02
QuantityRefused:
  SCF
  RET

; Column 3 on the input row: CASH: and the cash (standard control 7), a click
; and a wait
;
; Used by the routines at FirearmsPrice, ClearPageText and EquipShip.
ShowCash:
  CALL ColumnInline
  DEFB $03
  CALL PrintInline
  DEFB $07
  JP ClickWait

; JP (HL): the quantity check
;
; Used by the routine at QuantityKeys.
CallCheck:
  JP (HL)

; Buy Quantity of MarketItem: the stock, the price Quantity times, the free
; space (tonnes only), the hold, the legal cost
;
; Refused with QUANTITY? (more than the stock), CASH? (TakeCredits short) or
; CARGO? (no free space, or a hold count past 255). A unit of slaves, narcotics
; or firearms bought costs legal status as a scooped one does (AddCargo's tail
; at $D1AD).
BuyCheck:
  CALL SaveTrade
  LD A,(Quantity)
  LD B,A
  LD HL,(StockPointer)
  LD A,(HL)
  SUB B
  JR C,NoQuantity
  LD (HL),A
BuyCheckPay:
  LD HL,(PricePointer)
  LD E,(HL)
  INC HL
  LD D,(HL)
  CALL TakeCredits
  JR C,NoCash
  DJNZ BuyCheckPay
  CALL IsTonnes
  LD A,(Quantity)
  LD B,A
  JR NC,BuyCheckHold
  LD HL,FreeSpace
  LD A,(HL)
  SUB B
  JR C,NoRoom
  LD (HL),A
BuyCheckHold:
  LD HL,(HoldPointer)
  LD A,(HL)
  ADD A,B
  JR C,NoRoom
  LD (HL),A
  LD A,(MarketItem)
  CALL AddCargoContraband
  AND A
  RET

; QUANTITY? (code $B0)
;
; Used by the routines at BuyCheck and SellCheck.
NoQuantity:
  LD A,$B0
  JR RefuseTrade

; CASH? (code $C5)
;
; Used by the routines at BuyCheck and EquipShip.
NoCash:
  LD A,$C5
  JR RefuseTrade

; CARGO? (code $CE)
;
; Used by the routine at BuyCheck.
NoRoom:
  LD A,$CE
; This entry point is used by the routines at NoQuantity and NoCash.
RefuseTrade:
  PUSH AF                 ; Column 3, the code and "?", the trade undone
                          ; (RestoreTrade), a click, 36 frames, A = 1 with
                          ; carry
  CALL ColumnInline
  DEFB $03
  POP AF
  CALL PrintCode
  CALL PrintInline
  DEFB $3F
  CALL RestoreTrade

; A click, 36 frames, A = 1 and carry (the row asked again)
;
; Used by the routines at CommanderMenu, ShowCash and EquipFitted.
ClickWait:
  CALL Click
  CALL Wait36
  LD A,$01
  SCF
  RET

; The cash, the stock byte, the hold byte and the free space copied
;
; Used by the routines at BuyCheck, SellCheck and EquipShip.
SaveTrade:
  LD HL,(CommanderRest+$0003)
  LD (SavedThousands),HL
  LD HL,(CommanderRest+$0005)
  LD (SavedTenths),HL
  LD HL,(StockPointer)
  LD A,(HL)
  LD (SavedStock),A
  LD HL,(HoldPointer)
  LD A,(HL)
  LD (SavedHold),A
  LD A,(FreeSpace)
  LD (SavedSpace),A
  RET

; The copy put back
;
; Used by the routines at QuantityDelete, QuantityKeys, NoRoom, EquipShip and
; EquipFitted.
RestoreTrade:
  LD HL,(SavedThousands)
  LD (CommanderRest+$0003),HL
  LD HL,(SavedTenths)
  LD (CommanderRest+$0005),HL
  LD HL,(StockPointer)
  LD A,(SavedStock)
  LD (HL),A
  LD HL,(HoldPointer)
  LD A,(SavedHold)
  LD (HL),A
  LD A,(SavedSpace)
  LD (FreeSpace),A
  RET

; QUANTITY OF <name>/<unit> ? on the cleared input rows
;
; Used by the routines at FirearmsPrice and ClearPageText.
QuantityPrompt:
  CALL ClearInputRows
  LD A,$01
  LD (PrintCapital),A
  CALL PrintInline
  DEFB $CC
  LD A,$D0
  LD B,A
  LD A,(MarketItem)
  ADD A,B
  CALL PrintCode
  CALL PrintInline
  DEFB $2F
  CALL PrintUnit
  CALL PrintInline
  DEFB $20
  LD A,$3F
  JP PrintCodeLine

; SaveTrade's copy of the cash's tenths ($D068)
SavedTenths:
  DEFW $0000

; Its copy of the thousands ($D066)
SavedThousands:
  DEFW $0000

; The hold byte
SavedHold:
  DEFB $00

; The stock byte
SavedStock:
  DEFB $00

; The free space
SavedSpace:
  DEFB $00

; The quantity typed (or the equipment item, the laser's view)
Quantity:
  DEFB $00

; The check QuantityKeys runs (CallCheck)
QuantityCheck:
  DEFW $0000

; Key 3: with refugees aboard outside the nova's system the reward, else the
; sell page
;
; The reward: MissionFlags bit 5 cleared, the combat score's high byte one
; more, 100 units of gem-stones ($D07A) in the hold, the free space 35, YOU
; HAVE SAVED OUR LIVES! THANK YOU, COMMANDER... (other $0F) and the inventory.
SellCargo:
  LD A,(NovaMission)
  AND A
  JR NZ,SellCargoPage
  LD HL,MissionFlags
  LD A,(HL)
  BIT 5,A
  JR Z,SellCargoPage
  RES 5,(HL)
  LD HL,CombatScore+$0002
  INC (HL)
  LD A,$64
  LD (CargoHold+$000F),A
  LD A,$23
  LD (FreeSpace),A
  LD DE,$0F0F
  LD HL,$0700
  CALL MissionText
  JP InventoryScreen

; 30 cells to the end
SellBands:
  DEFB $F0

; ClearPageText, SellBands and the message row's colour
;
; Used by the routines at ClearPageText and EquipShip.
TradePage:
  CALL ClearPageText
  LD DE,SellBands
  CALL ColourBands
  JP FillAttrRow

; Other $96: the page cleared, the rule, capitals, the tab
;
; Used by the routines at TradePage, DataScreen, MarketPrices, StatusScreen and
; InventoryScreen.
ClearPageText:
  LD A,$96
  JP PrintOther
; This entry point is used by the routine at SellCargo.
SellCargoPage:
  CALL TradePage          ; SELL CARGO (codes $CD $CE), each commodity in the
                          ; hold with its prompt
  CALL PrintInline
  DEFB $CD
  LD A,$CE
  CALL PageTitle
  CALL TradePointers
SellCargoRow:
  LD HL,(PricePointer)
  INC HL
  INC HL
  LD (PricePointer),HL
  CALL HoldRow
  JR C,SellCargoNext
  CALL SaveCursor
SellCargoAsk:
  CALL QuantityPrompt
  LD HL,SellCheck
  CALL QuantityKeys
  JR C,SellCargoKey
  CALL ShowCash
SellCargoDone:
  CALL RestoreCursor
  CALL NewLine
SellCargoNext:
  LD HL,MarketItem
  INC (HL)
  LD A,(HL)
  CP $11
  JP C,SellCargoRow
  CALL Wait36
  JR SellCargoEnd
SellCargoKey:
  DEC A
  JR Z,SellCargoAsk
  DEC A
  JR Z,SellCargoDone
SellCargoEnd:
  JP InventoryScreen

; Sell Quantity: the hold less it (QUANTITY? if short), the free space back
; (tonnes), the price paid Quantity times
SellCheck:
  CALL SaveTrade
  LD A,(Quantity)
  LD B,A
  LD HL,(HoldPointer)
  LD A,(HL)
  SUB B
  JP C,NoQuantity
  LD (HL),A
  PUSH BC
  CALL IsTonnes
  POP BC
  JR NC,SellCheckLoop
  LD A,(FreeSpace)
  ADD A,B
  LD (FreeSpace),A
SellCheckLoop:
  PUSH BC
  LD HL,(PricePointer)
  LD E,(HL)
  INC HL
  LD D,(HL)
  CALL AddCredits
  POP BC
  DJNZ SellCheckLoop
  AND A
  RET

; MarketItem 0, HoldPointer one before the hold, PricePointer at PriceBase
;
; Used by the routines at FirearmsPrice and ClearPageText.
TradePointers:
  LD HL,CommanderRest+$0007
  LD (HoldPointer),HL
  LD HL,PriceBase
  LD (PricePointer),HL
  XOR A
  LD (MarketItem),A
  RET

; Key 4: EQUIP SHIP, the items the tech level allows with their prices, the
; cash, then the item's number
;
; The list has tech level + 3 items, all 14 from tech level 9 on (the count 12
; or more becomes 14). EquipPrices $705F holds each item's price (a thousands
; byte, a tenths word): fuel (its price written by the jump), missile 30, large
; cargo bay 400, E.C.M. 600, pulse laser 400, beam laser 1000, fuel scoops 525,
; escape pod 1000, energy bomb 900, energy unit 1500, docking computers 1500,
; galactic hyperdrive 5000, military laser 6000, mining laser 800 Cr. The
; number typed picks the item (0 or past the list: the status page); the price
; is taken (CASH? when short).
;
; A page of the four views (0-3, tokens $60-$63 and VIEW), the key 0-3 picks
; the mount at LaserMounts $D07D; the laser that was there is paid back at its
; full price (LaserItems $FD89 gives its item). Another key: the trade undone
; and the status page.
EquipShip:
  CALL TradePage
  CALL PrintInline
  DEFB $06
  LD A,$CF
  CALL PrintCodeSpace
  CALL PrintInline
  DEFB $B9
  CALL PrintInline
  DEFB $08
  CALL NewLineGap
  LD HL,EquipmentPrices
  LD (EquipPointer),HL
  LD A,(Seeds+$000E)
  ADD A,$03
  CP $0C
  JR C,EquipShipSetEquipCount
  LD A,$0E
EquipShipSetEquipCount:
  LD (EquipCount),A
  XOR A
EquipShipRow:
  LD (EquipRow),A
  LD A,$03
  LD (Messages+$0011),A
  LD A,(EquipRow)
  INC A
  CALL PrintByte
  CALL ColumnInline
  DEFB $04
  LD B,$69
  LD A,(EquipRow)
  ADD A,B
  CALL PrintCode
  CALL ColumnInline
  DEFB $16
  LD HL,(EquipPointer)
  LD A,(HL)
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (EquipPointer),HL
  LD H,$00
  LD L,A
  CALL PrintCashNow
  CALL NewLine
  LD A,(EquipCount)
  LD B,A
  LD A,(EquipRow)
  INC A
  CP B
  JR NZ,EquipShipRow
EquipShipAsk:
  CALL ClearInputRows
  CALL PrintInline
  DEFB $7F
  LD A,$3F
  CALL PrintCodeSpace
  CALL SaveTrade
  LD HL,EquipAccept
  CALL QuantityKeys
  JR C,EquipShipLeave
  CALL NewLine
  LD A,(Quantity)
  AND A
  JP Z,StatusScreen
  LD B,A
  LD A,(EquipCount)
  CP B
EquipShipLeave:
  JP C,StatusScreen
EquipShipPay:
  CALL SaveTrade
  LD A,(Quantity)
  CALL EquipPrice
  LD D,$00
  LD E,(HL)
  PUSH HL
  CALL TakeThousands
  POP HL
  JR C,EquipShipPaid
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  CALL TakeCredits
EquipShipPaid:
  JP C,EquipShipShort
  LD A,(Quantity)
  CP $01
  JR NZ,EquipMissile
EquipFuel:
  XOR A                   ; 1: the tank filled (SetFuel 70), the fuel's price 0
  LD (EquipmentPrices+$0001),A
  CALL ShowCash
  LD A,$46
  CALL SetFuel
  JP EquipShip
EquipMissile:
  CP $02                  ; 2: a missile, at most 4 (ALL PRESENT otherwise)
  JR NZ,EquipCargoBay
  LD HL,Missiles
  LD A,(HL)
  CP $04
  JP NC,EquipFull
  INC A
  LD (HL),A
  JR EquipDone
EquipCargoBay:
  CP $03                  ; 3: the large cargo bay, 15 more tons of free space
  JR NZ,EquipItem
  LD A,(Equipment)
  AND A
  JP NZ,EquipFitted
  LD HL,FreeSpace
  LD A,(HL)
  ADD A,$0F
  LD (HL),A
  JR EquipItemFit
EquipItem:
  CP $04                  ; 4 and 7-12: the flag in the equipment bytes ($D081
                          ; + item) set to $FF, refused when already fitted
  JR Z,EquipShipCallEquipFlag
  CP $07
  JR C,EquipLaser
  CP $0D
  JR NC,EquipLaser
EquipShipCallEquipFlag:
  CALL EquipFlag
  LD A,(HL)
  AND A
  JP NZ,EquipFitted
EquipItemFit:
  CALL EquipFlag
  LD (HL),$FF
EquipDone:
  CALL ShowCash
  JP EquipShipAsk
EquipLaser:
  LD B,$01                ; 5, 6, 13, 14: the laser kind (1 pulse, 2 beam, 3
                          ; military, 4 mining), then the view to mount it on
  CP $05
  JR Z,EquipLaserKind
  INC B
  CP $06
  JR Z,EquipLaserKind
  INC B
  CP $0D
  JR Z,EquipLaserKind
  INC B
EquipLaserKind:
  LD A,B
  LD (FitLaserKind),A
  PUSH BC
  CALL ClearScreen
  CALL FillAttrRow
  POP BC
  LD A,$04
  ADD A,B
  CALL SetColumn
  LD A,$0E
  CALL SetRow
  LD A,(Quantity)
  LD B,$68
  ADD A,B
  CALL PrintCode
  LD A,$10
  CALL SetRow
  XOR A
EquipLaserView:
  LD (EquipRow),A
  CALL ColumnInline
  DEFB $0A
  LD A,(EquipRow)
  ADD A,$30
  CALL PrintCodeSpace
  LD A,(EquipRow)
  ADD A,$60
  CALL PrintCodeLine
  LD A,(EquipRow)
  INC A
  CP $04
  JR C,EquipLaserView
  CALL ClearInputRows
  CALL PrintInline
  DEFB $AF
  CALL PrintInline
  DEFB $3F
  CALL WaitKey
  CP $30
  JP C,EquipLaserNone
  CP $34
  JP NC,EquipLaserNone
  PUSH AF
  CALL PrintCodeLine
  POP AF
  SUB $30
  LD HL,LaserMounts
  CALL AddAToHL
  LD B,(HL)
  LD A,(FitLaserKind)
  LD (HL),A
  LD A,B
  AND A
  JR Z,EquipLaserDone
  LD HL,LaserItems-$0001
  CALL AddAToHL
  LD A,(HL)
  CALL EquipPrice
  LD D,$00
  LD E,(HL)
  PUSH HL
  CALL AddThousands
  POP HL
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  CALL AddCredits
EquipLaserDone:
  CALL ShowCash
  JP EquipShip
EquipLaserNone:
  CALL RestoreTrade
  JR EquipToStatus
EquipShipShort:
  CALL NoCash
  JP EquipShipAsk

; The equipment's quantity check: always accepted
EquipAccept:
  AND A
  RET

; HL = EquipPrices + 3 (A - 1): item A's price
;
; Used by the routine at EquipShip.
EquipPrice:
  DEC A
  LD B,A
  ADD A,A
  ADD A,B
  LD HL,EquipmentPrices
  JR AddAToHL

; HL = $D081 + Quantity: the item's equipment byte
;
; Used by the routine at EquipShip.
EquipFlag:
  LD HL,NovaMission
  LD A,(Quantity)

; HL = HL + A
;
; Used by the routines at DamageItem, EquipShip, EquipPrice and PrintIfRowFree.
AddAToHL:
  LD D,$00
  LD E,A
  ADD HL,DE
  RET

; ALL PRESENT (missiles)
;
; Used by the routine at EquipShip.
EquipFull:
  LD A,$7C
  JR EquipRefused

; <item> PRESENT
;
; Used by the routine at EquipShip.
EquipFitted:
  LD A,$68
  LD B,A
  LD A,(Quantity)
  ADD A,B
; This entry point is used by the routine at EquipFull.
EquipRefused:
  CALL PrintCodeSpace     ; The code, a space and PRESENT (code $1E), a click,
                          ; the trade undone, the status page
  CALL PrintInline
  DEFB $1E
  CALL ClickWait
  CALL RestoreTrade
; This entry point is used by the routine at EquipShip.
EquipToStatus:
  JP StatusScreen

; The items listed
EquipCount:
  DEFB $00

; The item being listed (or the view)
EquipRow:
  DEFB $00

; The next price in EquipPrices
EquipPointer:
  DEFW $0000

; The laser being fitted
FitLaserKind:
  DEFB $00

; Column 6, the page title A (PageTitle), then MenuTop with $17
;
; Used by the routines at GalacticChart and ShortRangeChart.
ScreenHeading:
  PUSH AF
  CALL ColumnInline
  DEFB $06
  POP AF
  CALL PageTitle
ScreenHeadingTop:
  LD A,$17

; The top three rows' attributes A and a rule at $4740
;
; Used by the routine at CommanderMenu.
MenuTop:
  LD HL,$5800
  LD B,$60
  CALL FillBytes
  LD HL,$4740
  JP FillRule
