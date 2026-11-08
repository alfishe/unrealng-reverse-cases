# instructions

**What it is.** The instructions of Elite for the ZX Spectrum, as the Spectrum Game Database (SGD) transcribed them:
the controls, the story, the rating, the screen display, the equipment, hints, the docking procedure, cheats and
POKEs, and the trivia readers sent in. The file is [`orig/Elite.txt`](../../orig/Elite.txt) (492 lines, plain ASCII).
The controls section is the box's "Quick Key Control Guide", word for word. The "Spectrum+ Control Guide" and the
keyboard overlay in the box label the same keys; Z and V carry no label on either, as in the code. The box's own
manual, the "Space Traders Flight Training Manual" for the 48K Spectrum, is [manual.md](manual.md). The scans are in
`work/extras/` and not committed. The Lenslok sheet that came in the Spectrum box is
[lenslok-instructions.md](lenslok-instructions.md).

The text is English, so no translation is needed. Below it is set out as tables, with a **Code** column or note that
says where the game does what the text says, and where it does something else. The addresses are those of this
image ([12-routine-reference.md](../12-routine-reference.md)).

## 1. Controls

### Space flight

| Key | SGD text | Code |
| --- | --- | --- |
| N | anticlockwise roll | KeySteer `$FC09` bit 0, RollControl `$FF08` ([05-controls.md](../05-controls.md)) |
| M | clockwise roll | KeySteer bit 1 |
| S | dive | KeySteer bit 3, PitchControl `$FF0A` |
| X | climb | KeySteer bit 2 |
| SPACE | increase speed | KeySteer bit 4, SpeedControl `$FF0C` (+`$A0` a frame) |
| SYMBOL SHIFT | decrease speed | KeySteer bit 5 |
| 1 2 3 4 | front, back, left, right view | KeyViews `$FC0A` bits 0-3 |

The text writes "jotstick" once; the joystick replaces the four steering bits (ScanJoystick `$FC10`).

### Space combat

| Key | SGD text | Code |
| --- | --- | --- |
| A | fire laser (or the fire button) | KeyCombat `$FC0B` bit 0 |
| T | target missile | bit 1 |
| F | fire missile | bit 2 |
| U | unarm missile | bit 3 |
| E | ECM | bit 4 |
| W | energy bomb | bit 5, EnergyBomb `$7089` |
| Q | escape capsule | bit 6, EscapePod `$9C1C` |
| C | docking computer on and off | bit 7 |

### Navigation

| Key | SGD text | Code |
| --- | --- | --- |
| H | hyperspace | KeyViews bit 4 |
| G then H | intergalactic jump | KeyViews bit 5 arms the galactic jump, H starts it |
| D | distance to system | KeyChart `$FC0C` bit 5 |
| B | cursor cross home | KeyChart bit 4 |
| N M S X | cursor cross left, right, up, down | the steering bits, read by the charts |
| I | galactic chart | KeyScreens `$FC08` bit 5, GalacticChart `$EB7C` |
| O | local cluster chart | KeyScreens bit 4, ShortRangeChart `$EC58` |

### Trading

| Key | SGD text | Code |
| --- | --- | --- |
| 1 | launch from station (docked) | KeyViews bit 0 |
| 2 | buy cargo (docked) | KeyViews bit 1 |
| 3 | sell cargo (docked) | KeyViews bit 2 |
| 4 | equip ship (docked) | KeyViews bit 3 |
| I, O | the charts | as above |
| P | data on system | KeyScreens bit 3, DataScreen `$EDDF` |
| K | market prices | KeyScreens bit 2, MarketPrices `$EF48` |
| L | status page | KeyScreens bit 1, StatusScreen `$EF87` |
| ENTER | inventory | KeyScreens bit 0, Inventory `$F0B8` |
| R | find planet (docked) | KeyChart bit 6 |

### Game

| Key | SGD text | Code |
| --- | --- | --- |
| J | Torus jump drive | KeyViews bit 6 |
| CAPS SHIFT | freeze game | KeyViews bit 7, PauseMenu `$72A3` |
| SPACE | continue game | PauseMenu |
| SYMBOL SHIFT | initiate save (docked) | the commander menu |

The SGD list leaves out one key the code reads: **Y** (KeyScreens bit 7) switches on the cloaking device once the
second mission has given it (CloakOn `$D041`, [10-gameplay-logic.md](../10-gameplay-logic.md)). Z and V set no bit at
all (KeyTable `$FF58`, mask 0).

### Other controls

> Hold a Sinclair port 1/Cursor/Kempston joystick left on the initial screen to select control with that joystick
> port.

The title tests exactly that, once a frame (`$73CF-$73F7`). A Kempston read of port `$1F` with bit 5 clear and bit 1
(left) set picks 1. Then key 5 (the Cursor left, KeyDigits bit 1) picks 2, and key 6 (the Sinclair left, bit 3)
picks 3. The method goes into ControlMethod `$72A2` and Options `$FC0E` bits 0-1.

These keys work only while the game is frozen (PauseMenu `$72A3`):

| Key | SGD text | Code |
| --- | --- | --- |
| R | keyboard recentring toggle | OptionRecentre `$731C`, Options bit 2 |
| D | keyboard damping toggle | OptionDamping `$730A`, bit 3 |
| K | keyboard / joystick toggle | OptionKeyboard `$7331`: between 0 and ControlMethod |
| Y | reverse joystick, Y direction only | OptionReverseY `$732B`, bit 5 |
| B | reverse joystick, both directions | OptionReverse `$7304`, bit 4 |
| Q | sound effects off | OptionSoundOff `$7316`, bit 7 off |
| S | sound effects on | OptionSoundOn `$7322`, bit 7 on |
| 1 | start a new game | PauseQuit `$72FF` |
| F | (not in the list; see the cheats) | OptionBit6 `$7310`, bit 6: the misjump |

> The keyboard recentering toggle R will disable and re-enable the recentering in roll and dive/climb control. When
> recentering is enabled, a small amount of climb (or clockwise roll) cancels any dive (or anticlockwise roll) and
> vice versa.

In the code, a key held against the current roll or pitch takes the step off the magnitude. With recentring on, the
magnitude goes straight to 0 instead (ReadControls `$FE01`).

> The keyboard damping toggle D will disable and re-enable the automatic damping of a roll, dive or climb while in
> keyboard control.

With damping on and no key held, the roll magnitude falls by `$3C` a frame and the pitch by `$24`.

> The B key will reverse both directions of the joystick enabling it to be held either way around. The Y key will
> reverse the Y-direction only so that pushing the joystick forward will result in a climb and pulling it back will
> result in a dive; roll will not be affected. The B and Y keys can be used in conjunction.

Bit 4 swaps left with right and up with down; bit 5 swaps up with down only (`$FC63-$FC88`). For a Kempston joystick
the code flips both bits before it applies them (`XOR $30` at `$FC37`).

## 2. Instructions

> Command your Cobra space ship in a fantastic voyage of discovery and adventure, a supreme test of your combat,
> navigational and entrepreneurial skills.
>
> Trade between countless planets, using the proceeds to equip your ship with heat-seeking missiles, beam lasers and
> other weapons - corporate states can be approached without risk, but unruly anarchies may be swarming with space
> pirates.
>
> Black market trading can be lucrative but could result in skirmishes with local police and a price on your head!
>
> However you make your money, by fair means or foul, you must blast onwards through space annihilating pirate ships
> and hostile aliens as you strive to earn your reputation as one of the Elite!

### Your rating as a combateer

> To become an elite combateer requires great skill and great patience, because expert trading is essential before
> the necessary more powerful armaments and equipment available to the Cobra ship can be bought: beam lasers, more
> missiles, energy bombs, a docking computer, galactic hyperdrive, etc.
>
> As you sail through space between the stars, and as you trade, you will live with your combat rating. You will
> begin as HARMLESS. If you survive your first skirmish you may be reclassified as MOSTLY HARMLESS. But on the slow
> climb to a status level that reflects a growing talent for combat you will have to engage many different ships, in
> many different skirmishes, in the System Space of many different worlds. You will then be classified as POOR, then
> AVERAGE, then ABOVE AVERAGE, then COMPETENT. Then you will become DANGEROUS, then DEADLY. And at last a few will
> become ELITE.
>
> Your kills are photographed and transmitted by TS ComDirect to the nearest GalCop Federal Law Centre. Your rating
> as a combateer will increase in direct proportion.
>
> Fly your Cobra craft wisely and carefully. Remember: other pilots may be attempting to increase their own combat
> rating by attacking either innocent traders, or police Vipers (the ships of the GalCop Police Force). If you resort
> to such tactics (or if you adopt the fast-credit routine and trade in illegal goods) then your combat rating may
> rise, but your legal status: CLEAN -> OFFENDER -> FUGITIVE, will make you Public Enemy Number One with the
> Federation Crime Monitoring Authority and you will not be left alone.

The legal status is LegalStatus `$D05F`: 0 is CLEAN, 1-49 OFFENDER, 50 and up FUGITIVE (StatusScreen `$EF87`). The
rating comes from CombatScore `$D060`, see 9.

### Screen display

| Gauge | Meaning (SGD) |
| --- | --- |
| Front shields, aft shields | |
| Fuel level | |
| Cabin temperature | |
| Laser temperature | |
| Altitude | |
| Missile status | |
| Status | green, all safe; yellow, possible danger; red, immediate danger; flashing, critical |
| Compass | centres on the planet or the space station; when the dot is not solid, the object is behind you |
| ECM detector | ECM activity near |

The compass dots are in [`src/res/dashboard/compass.png`](../../src/res/dashboard/compass.png): a solid dot in front,
an open one behind ([08-hud-and-text.md](../08-hud-and-text.md)).

## 3. Equipment

| Item | Tech level | Price (Cr) | Code |
| --- | --- | --- | --- |
| Fuel | always | varies | Fuel `$D082`, tenths of a light year |
| Missile | always | 30 | Missiles `$D083`, 0-4 |
| Large cargo bay | always | 400 | Equipment `$D084` |
| ECM system | 2 | 600 | Equipment+1 |
| Pulse laser | 3 | 400 | LaserMounts `$D07D`, 1 |
| Beam laser | 4 | 1000 | LaserMounts, 2 |
| Fuel scoops | 5 | 525 | Equipment+4 |
| Escape capsule | 6 | 1000 | Equipment+5 |
| Energy bomb | 7 | 900 | Equipment+6 |
| Extra energy unit | 8 | 1500 | Equipment+7 |
| Docking computers | 9 | 1500 | Equipment+8 |
| Galactic hyperdrive | 10 | 5000 | Equipment+9 |
| Mining lasers | 10 | 800 | LaserMounts, 4 |
| Military lasers | 10 | 6000 | LaserMounts, 3 |

The prices the Equip screen asks are EquipmentPrices `$705F` ([10-gameplay-logic.md](../10-gameplay-logic.md)).

## 4. Hints and tips

> - Agricultural worlds need specialist food and raw materials, but mostly basic machinery and spare parts. If they
>   are rich, they need luxuries and high tech industrial machines. They produce food in quantity, raw materials and
>   specialised 'organic' items, like some textiles.
> - Industrial worlds need agricultural produce, raw materials (for refining), resource exploitation machinery, and
>   (if rich) high tech goods. They produce basic items of need for civilised worlds: beds, seals and gaskets, power
>   storage units, basic weapons, mass produced fertiliser, mass produced medicines, etc.
> - Trade in illegal goods (Slaves, Narcotics and Firearms) is the most profitable, but may harm your Legal Status.
> - Destroying pirate vessels earns a bounty, but attacking innocent traders may harm your Legal Status.
> - Once your Cobra is within automatic-docking and protective range of the Coriolis space station, the scan console
>   will display an S next to the compass.
> - Asteroids (and spacecraft!) can be mined with the appropriate lasers, and the debris collected in fuel scoops.
> - Thargoid (alien) battle-cruisers may 'hover' in Witch-Space (hyperspace) and attack through-coming craft.
> - Using an Escape Capsule effectively resets your legal status to Clean.

The illegal goods raise LegalStatus when they are bought (AddCargoContraband `$D1AD`). The escape pod zeroes
LegalStatus and empties the hold (EscapePod `$9C1C`): the hold's free space becomes 20 t, or 35 t with the large
cargo bay (`$9C5B-$9C68`).

## 5. Docking procedure

> Docking with a Coriolis space station is never easy, unless the ship is equipped with an automatic docking computer
> (in which case C will activate it). The Navy Training Manual recommends the following approach and dock sequence.
>
> Locate the Coriolis station and approach it. The entrance tunnels to all these stations face the mother planet. Fly
> near to the station and then on towards the planet (monitoring altitude carefully). By turning a half circle you
> will now find your ship orientated towards the entrance.
>
> Approach the final moments of docking at DEAD SLOW SPEED. Failure to dock cleanly can be fatal but may simply result
> in your scraping the sides of the aperture, with consequent loss of defensive shield(s) and quite possibly your
> cargo. Manually control the Cobra's roll motion to match the rotation of the Coriolis station. The entry port must
> be nearly as horizontal as possible.
>
> If docking is successful, the protective field across the station entrance is penetrated, and a break pattern
> appears on the screen. Berthing is handled automatically.

The docking test is in [10-gameplay-logic.md](../10-gameplay-logic.md); the "break pattern" is the tunnel of rings
([06-rendering.md](../06-rendering.md)).

## 6. Cheats

> As soon as the game loads, and you're given the option to LOAD a new commander, press "Y", then save your position.
> Go back to the game, and hey presto. Not much easier than that...

Y on the title opens the commander menu (Title `$7366`, KeyCode + 1 = `$5A`). The SGD text does not say what the
saved position gives.

> If you are having trouble docking you can try this cheat. Once you have launched, pick new destination, and fly
> towards the planet a bit. Spin around (and you'll still be dead straight with the station entrance) and fly towards
> the station and hit H for hyperspace. If you docked before the countdown ended you docked at the new station!
>
> There was also a cheat so that you always launched into Witch Space. Pause the game. Press 'f' - you'll hear a beep.
> Un-pause the game, and hyperspace, as normal. You'll now appear in Witchspace, and will continue to do so until you
> pause and press 'f' again. You *will* use a full journey's worth of fuel though, even though your location (on the
> Short-range chart) is halfway between the planets, so make sure you choose a planet that's nearer than 3.5 light
> years, or you'll be stuck! The same sequence gets you out again (assuming the Thargoids don't frag you before you
> can jump!)

F in the pause menu toggles Options bit 6 (OptionBit6 `$7310`). The jump tests that bit at `$DCB2` and, when it is
set, always takes the misjump at `$DCC0`. Without it, the misjump is a chance: the low byte of StarSeed `$7105`, the stardust generator's seed, must be `$F9`, about one jump in 256. The
misjump puts WitchSpace on and puts the ship half way between the two systems
([10-gameplay-logic.md](../10-gameplay-logic.md)). The recording w1 paused, pressed F and jumped into witch space.

> There is a way to stay in Witchspace forever, or at least until you have 35 tonnes of alien items. If your fuel
> scoops are active when you enter witchspace they stay active and your fuel just keeps going up and up.

### POKEs

The SGD list, with the address in hex and what it hits in this image:

| POKE | Value | SGD text | This image |
| --- | --- | --- | --- |
| 43071-43074 (`$A83F-$A842`) | 3 | big lasers | `$D07D-$D080` LaserMounts |
| 43078 (`$A846`) | 1 | large cargo bay | `$D084` Equipment |
| 43079 (`$A847`) | 1 | ECM | `$D085` |
| 43082 (`$A84A`) | 1 | fuel scoops | `$D088` |
| 43083 (`$A84B`) | 1 | escape pod | `$D089` |
| 43084 (`$A84C`) | 1 | energy bomb | `$D08A` |
| 43085 (`$A84D`) | 1 | energy unit | `$D08B` |
| 43086 (`$A84E`) | 1 | docking computer | `$D08C` |
| 43049 (`$A829`) | 200 | lots of money | `$D067`, the cash's third byte (CommanderRest+4) |
| 43122 (`$A872`) | 192 | ECM and cloaking device | `$D0B0` MissionFlags: bits 7 (the jammer) and 6 (the cloak) |
| 43087 (`$A84F`) | 192 | the refugee mission | `$D08D`, the galactic hyperdrive the nova mission needs |
| 43053-43069 (`$A82D-$A83D`) | x | cargo bay | `$D06B-$D07B` CargoHold |
| 43077 (`$A845`) | 4 | missiles | `$D083` Missiles |
| 42428 (`$A5BC`) | 0 | infinite energy | no equivalent found |
| 42870 (`$A776`) | 0 | infinite missiles | `$9C17` `DEC (HL)` in MissileGone |
| 37482 (`$926A`) | 0 | infinite energy bomb | `$7096` `LD (HL),A` in EnergyBomb |
| 42897 (`$A791`) | 0 | infinite escape pods | `$9C48` `LD (Equipment+5),A` (3 bytes) in EscapePod |
| 54682 (`$D59A`) | 0 | infinite galactic jumps | `$DC5F` `LD (Equipment+9),A` (3 bytes) in GalaxyJump |

The list was not written for this image. Here 43071 is inside PlotPixel, and 54682 is inside PrintOtherPair. Every
data POKE lands on the right variable when `$283E` is added, so the commander record of the image the list was made
for sat 10302 bytes lower. The code POKEs follow no single offset. Their targets in this image are taken from the code
that uses the item up, not from a run, and the 3-byte stores need three zeros, not one: known from the code only.

## 7. Sequels and prequels

> There are several versions of Elite on the Spectrum, most notable a 48K and 128K version, although there is very
> little difference between the two.
>
> Elite was followed up with Frontier (written by Elite's original author David Braben), although not on the
> Spectrum. There was also the *original* ELITE Tuner, which was written by the same bloke who wrote the WHAM Music
> Box. I forget his name though.
>
> Elite Tuner had some superb 2-channel music - Waltz of the Blue Danube. (funnily enough!)

## 8. Scores received

> It received a Sinclair User Classic award.

## 9. General facts

> These are the number of kills needed to reach each particular status:

| Kills | Rating | Code (CombatScore `$D060`, middle and top bytes) |
| --- | --- | --- |
| 0-8 | Harmless | top 0, middle at most 8 |
| 9-16 | Mostly harmless | middle at most 16 |
| 17-32 | Poor | at most 32 |
| 33-64 | Average | at most 64 |
| 65-128 | Above average | at most 128 |
| 129-767 | Competent | middle past 128, or top 1-2 |
| 768-2815 | Dangerous | top 3-10 |
| 2816-6655 | Deadly | top 11-25 |
| 6656+ | ELITE | top past 25 |

The thresholds are RatingScores `$F0AE` (8, 16, 32, 64, 128) and RatingHigh `$F0B4` (2, 10, 25). A rating is the
first threshold at or above the byte (StatusScreen `$EF87`), so the table above matches the code exactly, if one kill
adds one to the middle byte. AddCombat `$D1C7` adds a ship's score with a carry into the top byte. It increments the
top byte with no cap.

> If you reached 65535 kills, your rating reverted to 0 - Harmless, which is a useless but interesting fact, 8-bit
> register fans.

The uncapped `INC (HL)` at `$D1D3` makes that true: the two upper bytes wrap from `$FFFF` to 0.

> ELITE is possibly the most well-known computer game ever. When it made it's appearence on the Spectrum, it was
> thanks to Firebird Gold - the full-price range of their software, and programmed by a team called TORUS (who also
> coded the Amstrad version, hence why apart from added colour, the two look & play the same.) All the space trading
> tactics were faithfully translated from the BBC original, and there were new missions for the format - SuperNova,
> Cloaking Device & Thargoid Invasion, and many of the spacecraft made it to the 'humble' Spectrum. Many of the rumours
> also made it across - there was, alas, no space dredger in the ZX ELITE...
>
> ELITE was also one of the first games to be found not compatible with the brand new 128k Spectrum. A patched version
> was released almost immediatly, although it was rather sad that with all the extra memory, nothing new was added to
> the enhanced machine.
>
> Are the Save games compatible throughout all of the different versions? If you saved to tape in the 48k version,
> could I load it back into the 128 one? Yes. That may have been one of the reasons that the 128K version was
> essentially the same as the 48K - so all flags that needed to be set for missions could be preserved, etc.
>
> Another oddity for ELITE - it used the LensLok protection device. Lenslok was a plastic prism, which when viewed
> through, made a jumble on the screen turn into a password. LensLok never caught on, and was only used in a few
> games, including Tomahawk. It was notoriously difficult to use.
>
> ELITE is still a protected program - ie: It is not freely distributable in any type of snapshot image.
>
> When Elite was first released, it was part of a competition to see who the first person was to become elite. The
> winner was supposed to get some prize or other. This was to do with all the secret missions and what have you. In
> fact, this may even have been from the original Beeb release, but I think it was for the Spectrum. Anyway, the
> publishers got cold feet about it because it was alleged that people had hacked in and found it out the 'easy' way,
> so it was cancelled and anyone who entered was fobbed off with a badge or something. It caused quite a bit of
> controversy at the time as I recall.

The image relies on the bus byte `$FF` during the interrupt. Only the vector `$FDFF` and the `$FE` filler
`$FCEA-$FD40` give `$FEFE`; `$FD41-$FDFE` holds tables ([04-game-loop.md](../04-game-loop.md)). Whether this is what
failed on the 128K is not shown here: no recording ran on a 128K model. The Lenslok is described in full
in [lenslok.md](../lenslok.md).

### The missions

> Does the Speccy version include any of the secret missions, such as destroying the secret ship, the rogue
> space-station, etc? Yes. The first mission, is 'Nova' and requires you (to manouvre down this trench... sorry -
> wrong game!) rescue the crew of a Space Station whose sun is about to explode. When you arrive in the system, the
> screen is red, not white, you get a 'Fuel Leak!' warning (A cunning way of making sure you don't chicken out, and
> witchspace outta there,) and you only have a short time to get to the space station. Your reward is 100g of gems,
> and to trigger the mission you need to be ranked competent or above, and have purchased a galactic hyperspace - When
> you activate your space drive, (presumably) the radiation from the Nova bumps you into the next Galaxy.
>
> Mission 2 involves a bunch of ships that flicker in and out of vision. They're quite easy to kill though.
> Eventually, you'll come up against a single ASP II, which when (finally) destroyed will release a single cargo
> canister, as opposed to the 2 alloys normally released as debris. Scoop this cargo, and you'll find yourself
> automagically cloak-capable. Pressing "Y" will activate the cloak - your screen goes blue, and all other ships
> float/drift, power-down, including Thargoids. The Cloak has a pretty hefty drain on the energy units though...
>
> Mission 3 you get to destroy a Space Station! The Space navy equips you with an ECM Jammer, which replaces your
> standard ECM unit, and off you go to have a bish at a Space Station over-run by Thargoids. You can make a fortune on
> this mission by blasting Thargoids, and scooping Tharglets.
>
> ZX Elite only has the one type of energy unit. The reason for the Military Energy unit was from BBC Elite, where a
> mission was to hunt a new type of ship - The Constrictor - which was equipped with the Military Energy unit, and was
> thusly impervious to anything less that Military lasers. Constrictor mission isn't present in ZX Elite, so no
> Military Energy unit.

The code agrees with all three. MissionFlags `$D0B0` bit 0 starts the nova after 32 jumps, bit 1 brings the cloak
ship after 128, and bit 2 the Thargoid MAYDAY after 254. MissionShip `$9CB2` is the cloaked Asp, and CloakOn `$D041`
the blue view and the extra drain. MissionState `$D0AF` follows the Thargoid mission, and bit 7 of MissionFlags is the
jammer the status page names. The details and the witnesses are in [10-gameplay-logic.md](../10-gameplay-logic.md).

### Ship shapes

> The following are approximate shapes drawn based on the cards supplied with the Archimedes version (Darren Salt):

```text
Adder           Anaconda      Asp                   Boa
  __________         /\              _______            /\
 |  ______  |       //\\            /       \          /  \
 | |______| |       //\\          //         \\        /  \
 |          |      //__\\       //             \\     / /\ \
 |__________|     / /  \ \    /_/_             _\_\   / /\ \
||          ||    //    \\    \ \ ----_____---- / /  / /  \ \
||   /||\   ||   / /    \ \    \ \     /|\     / /   / /  \ \
||   \||/   ||  / /      \ \    \\   /  |  \   //   /________\
||__________||  \_/______\_/     \\/____|____\//    |________|

Cobra Mk I     Cobra Mk 3   Fer-de-Lance        Gecko
  ______       __                  /\               _____
 /__==  \     |  \                /  \             /     \
|        \    |\-_ \             /    \           //     \\
|         \   | \ --_\          /      \         //  | |  \\
|          \  |  \   --\       /  /  \  \       / /  | |  \ \
|        _- | |   \   _- \    /  /|  |\  \     / /  /| |\  \ \
|      _- ||| |    \_-   |   /  / |  | \  \   /  /  /| |\  \  \
|       -_||| |    / -_  |  /  /  |  |  \  \ /  /   /| |\   \ \
|         -_| |   /    - / /  /___|  |___\  \ \_/___________\_/
|          /  |  /  _--/  /___            ___\
|         /   | /_-- /    \   ---______---   /
|___     /    |/-  /       \   __--  --__   /
 \__==__/     |__/          \==__________==/

Krait                   Mamba                   Moray
.        .        .         /\                 ________
|       /|\       |        //\\               /        \
|      / | \      |       //  \\            / /        \ \
|    /   |   \    |      / /[]\ \          / /          \ \
|   /    |    \   |     / /    \ \       /   /          \   \
| /      |      \ |    /  /    \  \     /___/____________\___\
|/       |       \|   /  /      \  \     ---____      ____---
 --__    |    __--   /___/______\___\          ---__---
     --__|__--
         -

Orbit Shuttle   Python   .              Sidewinder
    ____                /|\                  _________
 _==----==_            / | \                /\        /\
|    /\    |          /  |  \              /  \      /  \
|    /\    |         /   |   \            /    \    /    \
|   /  \   |        /    |    \          /      \  /      \
|   /  \   |       /     |     \        /________\/________\
|  /    \  |      /     _|_     \
|  /    \  |     /  __--   --__  \      Thargon
| /      \ |    /_==___________==_\       ___
| /      \ |    \                 /      |   |
|/        \|     \\             //       |   |
|/________\|      \ \         / /       | |_| |
                   \__\     /__/        | |_| |
                      --\_/--           --___--

Thargoid                    Transpoter         Viper (Police)
       ________                ___                  /\
     / \      / \          __--\ /--__             //\\
   /    \____/    \      ==_____V_____==          //  \\
 /_    /      \    _\   |       |       |        / /  \ \
|  --/          \--  |  |       |  /|\  |       / / /\ \ \
|   |            |   |  | ====  |       |      /  //  \\  \
|   |            |   |  |  ___  |   .   |     /  //    \\  \
|__--\          /--__|  |  \|/  |  /_\  |    /   /      \   \
 \     \ ____ /     /   |       |       |     --/________\--
   \    /    \    /     |_______|_______|
     \ /______\ /

Worm
    _____
   /|/_\|\
  | |   | |
  | |   | |
 | |     | |
 | |     | |
 | |     | |
|  |     |  |
| |       | |
--|_______|--
```

These are the Archimedes cards, not the Spectrum's ships. The Spectrum flies 19 blueprints with 16 shapes
([07-objects.md](../07-objects.md), [`src/res/ships/ships.txt`](../../src/res/ships/ships.txt)). Of the ships drawn
here it has the Asp, the Cobra Mk III (trader and pirate), the Fer-de-Lance, the Krait, the Python, the Sidewinder,
the Thargoid, the Thargon and the Viper; it has no Adder, Anaconda, Boa, Cobra Mk I, Gecko, Mamba, Moray, Orbit
Shuttle, Transporter or Worm.

> NOTES
> Thats about everything!
