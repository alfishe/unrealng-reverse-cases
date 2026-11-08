# manual

**What it is.** "Space Traders Flight Training Manual", the 64-page book in the Firebird box, "for the 48K
SPECTRUM". It is Acornsoft's 1984 BBC manual reworded for the Spectrum keys, with the Spectrum credits. The source is
ZXDB / Spectrum Computing's `Elite(EN).pdf`, a 68-page scan, in `work/extras/` and not committed. The text below
comes from the PDF's text layer (`pdftotext -layout`, `work/elite-manual.txt`), proofread against the scan. The
scanner's misreadings ("w ill", "fig hte r", "Tiade") are corrected, the line breaks of the narrow columns are
joined, and the photograph captions are set apart as *Caption:* lines. The illustrations themselves (photographs of
the BBC screens, the ship drawings) are not reproduced. The four blank Pilot's Log forms at the end are described
once.

The text is English, so no translation is needed. Notes in **Code:** paragraphs say where this image agrees or
disagrees; the addresses are in [12-routine-reference.md](../12-routine-reference.md).

## Title page and credits

```text
ELITE
For the 48K SPECTRUM.

Original programme by IAN BELL and DAVID BRABEN.
Spectrum programming by: R.J.M. PINTO
                          D.M.N. PRIOR
                          M. WIGHTON
                          P. MOCHAN

Title screen by TIM BOONE.

Package Design by the FTF Agency.

Documentation based on original material. (c) Acornsoft Ltd 1984, reproduced by permission of Acornsoft.
Conversion by Torus Ltd. (c) British Telecommunications plc.
Elite is a Trade Mark of Acornsoft Ltd.

Published by FIREBIRD SOFTWARE, Wellington House, Upper St. Martin's Lane, London WC2H 9DL.
```

The warning page above it says the usual: copyright in all Firebird software, no copying or hiring, faulty tapes
replaced free, "Firebird and the Firebird logo are trademarks of British Telecommunications plc".

**Code:** the image carries no credit text. Tim Boone's title screen is the loading screen,
[`src/res/screens/loading.scr`](../../src/res/screens/loading.scr).

## Contents

| Chapter | Page | Sections |
| --- | --- | --- |
| 1. Introductory Data | 4 | tape loading instructions; access instructions for tape |
| 2. Navigation and Flying | 11 | flying and navigational controls; leaving the space station; making for your target world; travelling to other galaxies; docking procedure |
| 3. Interplanetary Travel | 24 | in-flight combat: controls and tactics, likely enemies; equipping the Cobra Mk III: weaponry and non-combative equipment, how to buy equipment for your ship |
| 4. Intergalactic Trading | 38 | how to trade; piracy; bounty hunting |
| 5. Political Profile of the Universe | 47 | consequences for trade; alien races |
| 6. Observer's Guide to Ships in Service | 52 | |
| 7. Pilot's Log | 58 | |

## 1. Introductory Data

Welcome aboard this Cobra Mk III trading and combat craft. The ship has been supplied to you by Faulcon deLacy
Spaceways, by arrangement with the Galactic Co-operative of Worlds whose Space and Interstellar Pilot's Exams you have
just successfully completed. The small flight manual supplied with the craft is designed to familiarise you with all
aspects of space flight, combat and trading, and we hope that it will be of use to you.

*Caption:* The Cobra Mk III incorporates Zieman Deflection Shields, fore and aft, 4 hull mountings for Ingram
'rapid-fire' pulse lasers, a Lance & Ferman 'seek & kill' missile system, a Holodirect & ThruSpace GravDistort
communications system, and provision for a cargo bay extension.

You begin your career, your ship equipped with a single forward-firing pulse laser, three homing missiles, 7 light
years of fuel, and the sum of 100 Credits (CR), ready to embark from a space station in orbit around the planet Lave.

**Code:** DefaultCommander `$D232` says the same: JAMESON, 100.0 Cr, 7.0 light years of fuel, a front pulse laser,
3 missiles, galaxy 1 at Lave. NewGame `$D298` copies it into the commander record `$D054`.

The Cobra Mk III is the best of the medium-range, medium capacity fighter-traders, and is an ideal ship for new traders
intent on building their fortunes, or new combateers who will constantly need to finance the cost of both armaments
and non-combative equipment.

The ship is highly manoeuvrable, has a good C-holding factor during hyperspace transit, can hold sufficient Quirium
H-fuel for a 7-light-year single jump and has full AutoTrading Systems Link for use at space stations. Further, it is
protected by dual Zieman Energy Deflection Shields, powered by four energy banks, and has a powerful, rapid-fire pulse
laser mounted on the forward hull segment. Flight controls are elegant and simple, and the bridge is equipped with
both HoloDirect and ThruSpace GravDistort communications systems. Its life support functions are varied and flexible
to ensure maximum comfort during trading or hunting operations.

Pilot licences are issued only at the planet Lave, and it is likely, therefore, that you are now docked at a Coriolis
station in orbit around that particular world. Lave is a rich, agricultural dictatorship, but is a reasonably safe
world at which to begin your endeavours. GalCop and the Lave Authorities allow practice docking and departure runs to
all their space stations here, and you would be advised to take advantage of this facility.

### Interior of a Cobra Mk III

The Cobra is essentially a single-pilot trade-ship, but has been designed to support a second person, provided that
person is of ordinary human or humanoid dimensions and physiology. The ship itself consists of five main areas:

The cargo hold fills the bulk of the mid-space area, and the cargo bay doors open downwards. The capacity in an
unmodified Cobra is 20 1-tonne canisters. Extra cargo space may be acquired by extending the cargo bay, which does not
affect manoeuvrability. Tonne canisters (TC) attach magnetically to the cargo arms within the bay, and two
AutoShuttles occupy the central space.

The bridge has seats for pilot and co-pilot, a MedStim Centre, entrance to the escape pod, descent well to living
quarters, communications console, special suit locker, Rem Lock supply case, attachment facilities for AutoDock System
and a hand-weapons locker. The main wall is occupied by the scanner screen, astrogation console and main systems
monitors.

The drive sector houses the directional thrusts, the System Space Kruger 'lightfast' motors, and the Irrikon
Thru-Space drives. Also here are the rear laser housings, the ECM capsule, the Zieman shield generators, and energy
banks, and the Witch-Space fuel condensors (Quirium). There are both internal and external access panels. Radiation
level is high.

The living and hygiene section is below the main bridge, and reached through a descending gravity well. Two bunks,
food dispensing facilities, waste disposal (including high-tox copper exudate for Aonians), SynPleasure relaxapads,
and videos.

The equipment level runs throughout the ship, and houses all energy banks for lasers, plus the missile rests, with
dispatch shafts to the lower hull. The communications centre is here, and the escape pod (with a separate entrance
from the bridge) life support systems, cryogen tanks (two) and forty cubic metres of FacsEnvironment for emergency
use.

### Loading

1. Connect the EAR socket of your Spectrum to the EAR socket of your tape recorder.
2. Place the tape in your tape recorder and rewind to the beginning.
3. Type LOAD "" and press ENTER on your Spectrum.
4. Press PLAY/LOAD on your recorder.

The game will now enter LENSLOC mode. Please refer to the enclosed LENSLOC instructions.

**Code:** the load is the BASIC loader, the Softlock turbo blocks and the kickoff
([03-build-and-load.md](../03-build-and-load.md)); "LENSLOC" (sic) is the Lenslok check
([lenslok.md](../lenslok.md), the sheet in [lenslok-instructions.md](lenslok-instructions.md)).

### Getting started

When loading is complete, you will see a rotating space ship.

This is a Cobra Mk III, identical to the ship with which you are equipped. Ignore the 'Load new Commander (Y/N)?'
query for the time being and press the SPACE KEY to move on to the second title page. If you are playing with a
joystick you should now move the joystick left; otherwise press the SPACE KEY again.

The game has now started and the screen shows a page of information describing the current game situation.

**Code:** Title `$7366`. The first loop turns the Cobra until a key: Y opens the commander menu. The second shows
"PRESS SPACE, COMMANDER" with the next title ship each pass and reads the control method from a joystick held left
or SPACE (`$73CF-$73F7`, [instructions.md](instructions.md) 1). The "page of information" is the status page.

### How to access the cassette

While docked at a space station, you can save your game position to cassette. When a position is saved, it
automatically becomes the position from which any new game starts (the default position).

While docked, press the SYMBOL SHIFT key, the cassette menu now will be displayed.

Press 1, 2 or 3

1. Load New Commander
2. Save Commander \<Name\>
3. Exit

This menu will also be displayed if you press the Y key in response to the 'LOAD New Commander (Y/N)?' query on the
first title page.

1. Load New Commander. You will be prompted for a filename. After a successful load the second title page is
   displayed.
2. Save Commander. You will be prompted for a filename. After a successful save the status page is displayed.

The Number displayed during the save is the security code for entry to the Elite competition. See the post card
enclosed in the pack for competition details.

**Code:** CommanderMenu `$D90A`. A commander on tape is one headerless block of the 102 bytes `$D054-$D0B9`. After a
load or a save, KeepCommander `$DA08` copies the record into DefaultCommander, the position a new game and a death
start from. The competition number is SecurityNumber `$D9AC`: two five-digit numbers chained from the combat score,
the galaxy, two mission flags and the cash. The game never reads it back ([10-gameplay-logic.md](../10-gameplay-logic.md)).
Neither tape path ran in the recordings.

### The status page

*Caption:* A new pilot's rating is 'harmless'; his legal status, 'clean'.

The 'Present System' refers to the planetary system which your ship is currently in; while the 'Hyperspace System'
refers to the system onto which the hyperspace is locked.

'Legal Status' refers to your Galactic Police record. If this is CLEAN you have nothing to worry about, but as an
OFFENDER or, still worse, a FUGITIVE you are likely to be attacked by police ships.

The 'Rating' is a dispassionate assessment of your performance in combat so far.

Current cash and fuel are also displayed, along with a list of ship fittings.

L: The status page is always retrievable by pressing L.

*Caption:* Commander Jameson's rating is 'harmless' which is surprising when you consider the equipment and cash he
has managed to amass. In fact as his status suggests, this has been achieved with exceptional business acumen.

**Code:** StatusScreen `$EF87`. Commander Jameson is the BBC manual's example; the default name in this image is
"JAMESON" too (CommanderName `$D054`).

### Your rating as a combateer

To become an elite combateer requires great skill and great patience, because expert trading is essential before the
necessary more powerful armaments and equipment available to the Cobra ship can be bought: beam lasers, more
missiles, energy bombs, a docking computer, galactic hyperdrive, etc.

As you sail through space between the stars, and as you trade, you will live with your combat rating. You will begin
as HARMLESS. If you survive your first skirmish you may be reclassified as MOSTLY HARMLESS. But on the slow climb to a
status level that reflects a growing talent for combat you will have to engage many different ships, in many
different skirmishes, in the System Space of many different worlds. You will be classified as POOR, then AVERAGE,
then ABOVE AVERAGE, then COMPETENT. Then you will become DANGEROUS, then DEADLY. And at last, a few will become ELITE.

Your kills are photographed and transmitted by TS ComDirect to the nearest GalCop Federal Law Centre. Your rating as a
combateer will increase in direct proportion.

Fly your Cobra craft wisely and carefully. Remember: other pilots may be attempting to increase their own combat
rating by attacking either innocent traders, or police Vipers (the ships of the GalCop Police Force). If you resort to
such tactics (or if you adopt the fast-credit routine and trade in illegal goods) then your combat rating may rise,
but your legal status: CLEAN -> OFFENDER -> FUGITIVE, will make you Public Enemy Number One with the Federation Crime
Monitoring Authority and you will not be left alone.

| Key | Function: status |
| --- | --- |
| L | Status page originally accessed by space bar, always recalled by L. |

## 2. Navigation and Flying

### Navigation

The Galactic Co-operative is only one - although the largest - of several planetary federations, and maintains trade
and diplomatic links with over 2000 planets spread throughout 8 galaxies. The political profile of a planet is an
important navigational consideration as many are in a state of anarchy and are unsafe to visit in poorly equipped
ships. Important too is its economic profile, as will be discussed in the section about trading.

Navigational strategy depends of course upon your aims in life. If you think you have what it takes to become elite,
you will need to chart your path through the galaxies with care and great precision. You will wish to equip your ship
as fully and as early as possible. You will, therefore, need to study the trading section of this manual so that you
can work out a profitable trading route in order to be able to afford the weaponry you will require. You will have to
make decisions about how dangerous a life you wish to lead; in general, the more risks you take (travelling to
dangerous planets or trading in contraband goods), the faster you may equip your ship but the quicker you will be
killed. You will discover that life in the 8 galaxies is a question of fine balance. Although it may seem, at first,
that indiscriminate carnage is a soft option (kills improve your rating, after all), as your skills and experience of
living in space mature, you will quickly discover that piracy is a short-lived career.

Success in this context is a mosaic of talents: combative, certainly, but thinking and decision-making talents too.

*Caption:* There are 8 galaxies (of which this is one), and over 250 recognised planets in each galaxy. So massive a
universe contains very little that is completely predictable, and offers infinite opportunities for adventure.

**Code:** 8 galaxies of 256 systems each, made from three 16-bit seeds ([10-gameplay-logic.md](../10-gameplay-logic.md)).
"Over 2000 planets" is 8 x 256 = 2048; the manual's "2040 officially registered worlds" is near it.

Here you are introduced to all the controls which will eventually be useful to you in developing a route through the
8 galaxies.

### Navigational controls

It is important that you do not press the 1 key for the moment.

I: Galactic chart. This chart shows all registered worlds within the galaxy, and indicates your own coordinate
position. The star cursor may be used to scan the shown worlds for potentially favourable trade sites.

Use the joystick or the cursor control keys to move the small cross over to one of the dots, and hit P.

P: Worldata link. The Orbit Space Authority takes no responsibility for the accuracy of the information registered
here, but the trader may gain some idea of the relative wisdom of trading with the world whose data is displayed. The
information shown is distance, type of main life form, degree of agricultural or industrial development, with
industrial and technological level displayed on a scale of 1-12. The government type, ranging from Corporate State to
Anarchy, will be a strong indication of the danger of trading with the system.

*Caption:* P invokes a planetary status card. Whether you choose to amass kills by bounty hunting or take the less
dangerous course of the traditional trader and defensive combateer, the political and economic infrastructure of
planets should influence the route you take through a galaxy (see Interplanetary Travel and Trade).

Use I again to return to the chart and acquire information about some more planets.

The larger of the crosses on the chart shows where your ship is and the circle shows how far it can jump with its
current hyperspace fuel.

B: B returns the small cross to the larger one.

O: Local navigational chart. This is a high power chart of all planets in the immediate vicinity of your docking
world. Since the Cobra ship has a maximum single H-jump range of 7 light years, the target world must be chosen
carefully. The target cursor, used in conjunction with the Worldata link, will indicate dangerous or likely worlds for
trade.

D: If the cross moves off the screen, use the B key to bring it back. Notice also that the D key will tell you how far
away the system nearest the small cross is.

| Key | Function: navigation |
| --- | --- |
| I | Galactic chart |
| O | Local chart |
| D | Distance to system |
| B | Retrieve cursor cross |
| S, N, M, X | Cross-sight cursor for local and galactic systems |
| P | Data on system |

**Code:** GalacticChart `$EB7C` (the fuel circle's radius is the fuel / 4), ShortRangeChart `$EC58` (radius = the
fuel), DataScreen `$EDDF` ([08-hud-and-text.md](../08-hud-and-text.md)). TechLevel `$DEFA` holds 0-14 and the
data screen prints it plus one, so 1-15: the "1-12" of the text is not a limit of the code.

### A Coriolis space station

Every world registered with the Galactic Co-operative has several Coriolis space stations in orbit at various
altitudes. Coriolis stations are 'neutral' territory, controlled equally by GalCop and the Planetary Government.

A new dodecahedral design (the so-called 'Dodo' stations) is replacing the Coriolis design in the more advanced
systems. Coriolis stations are hexagonal in approximate shape. They spin along a single axis running vertically from
the planet below. One side of the station always faces the planet, and it is on this facet that the access tunnel is
located.

Coriolis stations were designed at the GASEC (Galactic Astronautic and Space Exploration Centre) Laboratories on the
planet Vetitice. The first station was in orbit around the world Lave in 2752.

Coriolis stations have powerful defensive shields (against pirate attack and inept docking) and a large fleet of
Viper fighters, and several larger types of ship. The inside of the station is free-space, and on each inner facet of
the station there are berthing and refuelling facilities, as well as cities, hospitals, farmlands and leisurescapes.

Each Coriolis station has a diameter of 1 standard kilometre. They can berth 2000 ships, and support a fair-sized
colonial life development of humanoids.

*Caption:* Space stations are cargo transition points for interplanetary trading vessels and shuttle craft. They also
provide entertainment and lodging facilities for pilots not wishing to go 'planet-side'.

**Code:** the Spectrum has only the Coriolis (ShipCoriolis, [07-objects.md](../07-objects.md)); there is no
dodecahedral station blueprint.

### Leaving the space station

1: On coding for Station Depart the pilot is advised to accept a 10-second MemnSomn to dispense with subjective
experience of the passage from docking bay to Coriolis station egress. The screen will then show a break-pattern,
which is the passage through the protective field over the Coriolis entrance tunnel.

*Caption:* Leaving a Coriolis station and approaching the planet, Lave.

#### Basic manoeuvres

The Cobra trade ship needs practice to fly well, though it is highly manoeuvrable, very fast, and a good combat vessel.
It accelerates and decelerates rapidly using fingertip control:

- N (or joystick left) for anticlockwise roll
- M (or joystick right) for clockwise roll
- X (or joystick back) for climb
- S (or joystick forward) for dive
- SPACE to increase
- SYMBOL SHIFT to decrease your speed

Pitch and yaw manoeuvre requires bi-digital play on keyboard model (X, S, N, M).

**Code:** KeySteer `$FC09`: N bit 0, M bit 1, X bit 2, S bit 3. The joystick's back is the climb, as the manual says;
the cursor joystick's 6 (down) lands on X's bit ([05-controls.md](../05-controls.md)).

Notice the small dot moving around inside the large circle on the dials (just above the large 'S'). This is your
compass; the dot corresponds to the position of the space station. If the dot is not solid then the station is behind
you. When the dot is solid and in the centre of the circle, you should be able to see the space station directly in
front of you.

*Caption:* Looking back at the Coriolis station where your Cobra was berthed.

Practise rotating the space station off the screen and using the compass to find it again.

You might see some Cobra Class ships. These are other traders like yourself, and will not harm you unless you shoot
at them. If you do this they will either attack or, alternatively, run away. Should you use them for combat practice,
do not expect the space station to turn a blind eye to such unruly behaviour. Nothing will attack you while you are
within sight of the space station - unless you make a nuisance of yourself.

It is not possible to land on the planet, and flying into planets or space stations is fatal. The altimeter shows
your height above the planet's surface, and you should not let it fall too low.

(If you are a new pilot, now is your best chance to practise docking manoeuvres with the space station at Lave. The
Lave Orbit Space Authority permits an unlimited number of practice runs by newly appointed pilots, and does not
charge. This facility is suspended during attack, or when the Coriolis station has no free docking space. See the
illustrated section on docking procedure.)

### Console readings

1. Cabin temperature will increase and the console register this when your ship flies too close to a sun.
2. Altimeter. Your altitude above your destination planet can be crucial. Flying too near its surface will be fatal.
3. Forward velocity should be maintained at maximum on planetary approach. Keep it low during space station approach,
   and minimal for final docking.
4. Gyro orient bar indicators show right/left roll and dive/climb status.
5. S refers to the space station and indicates that you are on target for it and within its protective range.
6. Flight grid scanner. This sophisticated instrument displays a three-dimensional view of space in the immediate
   vicinity of your ship, seen from a point behind and above it. The precise position of any ship within its range
   can be pinpointed.
7. Compass. This instrument first picks up a target planet while it remains out of range of the main flight-path
   scanner. When the planet's space station nearest to you comes within range of it, the compass picks up that
   instead. When the dot is not solid the object is behind you; when solid and in the centre of the compass circle, it
   should be visible through your front viewfinder.
8. Fuel level.
9. Status indicator. If this indicator is green, all is safe. Yellow indicates a possible danger. Red is immediate
   danger. Flashing red indicates critical danger. Danger could be enemy craft, getting too close to a sun etc.

**Code:** the dashboard is drawn by the dashboard module ([08-hud-and-text.md](../08-hud-and-text.md)). The status
light is Condition `$7104`: 4 green, 6 yellow, 2 red, `$63` red flashing.

*Caption:* Once you have left a space station, the controls 1, 2, 3 and 4 change their function to produce front,
rear, left and right views respectively.

### Making for your target world

#### Hyperspace and related controls

Having left the space station you will be in low orbit above the planet Lave, moving at low velocity. Decrease your
velocity to absolute minimum before coding the astrogation console for Hyperspace Jump.

1, 2, 3, 4: During space flight only, 1, 2, 3 and 4 provide access to views all around your ship.

H: Use I or O to display a chart (galactic or local, respectively), and move the smaller cross to choose a new planet,
press 1, then hit H. After a short delay, the hyperjump motors will engage.

On arrival in a new planetary system, after transit from hyperspace, you will find yourself at some distance from your
target world. This conforms with GC Flight Law.

J: Even in the safest systems there can be unseen dangers, and you will be well advised to approach orbit space, and
the safety of the space station, as quickly as possible. Increase forward velocity to maximum. At this point you can
take full advantage of the Torus Jump Drive (J). The Torus Jump Drive does not function (because of interference
patterns) if there is another ship, a planet or a sun in the immediate vicinity. If this is the case, a sound signal
will occur.

**Code:** the jump drive (KeyViews bit 6) is refused while SunClose `$81A4`, PlanetClose `$81A5` or ShipsAbout
`$9C94` say so ([04-game-loop.md](../04-game-loop.md)). "Torus" is the conversion team's name on the BBC's "J".

Soon your ship's computer will pick up the beacon signals of the nearest orbital space station and will re-engage the
compass to track that instead of the target planet. Once the Cobra is within scanning and protective range of the
Coriolis station, the flight-grid scanner will begin to track it. Its own defenses are now available for your
protection. The scan console will register the letter 'S' as long as the space station is within range.

#### Hyperdrive across galaxies

G then H: The intergalactic hyperdrive is expensive and can be obtained only from planets at Tech level 10 or higher.
It can only be used once, and will take you to a system in a whole new galaxy (i.e. a new I map). There are 8 such
galaxies and making 8 jumps will return you to your starting galaxy. The Inter-Galactic Hyperdrive is engaged by
pressing G then H.

**Code:** the galactic jump clears Equipment+9 (`$DC5F`), adds one to the galaxy number (1-8, wrapping from 8 to 1)
and rotates each of the six seed bytes left one bit, as BBC Elite does.

### Docking procedure

Docking with a Coriolis space station is never easy, unless the ship is equipped with an automatic docking computer
(in which case C will activate it). The Navy Training Manual recommends the following approach and dock sequence.

Locate the Coriolis station and approach it. The entrance tunnels to all these stations face the mother planet. Fly
near to the station and then on towards the planet (monitoring altitude carefully). By turning a half circle you will
now find your ship orientated towards the entrance.

Approach the final moments of docking at DEAD SLOW SPEED. Failure to dock cleanly can be fatal but may simply result
in your scraping the sides of the aperture, with consequent loss of defensive shield(s) and quite possibly your
cargo. Manually control the Cobra's roll motion to match the rotation of the Coriolis station (see illustration). The
entry port must be as nearly horizontal as possible.

If docking is successful, the protective field across the station entrance is penetrated, and a break pattern appears
on the screen. Berthing is handled automatically.

Docking protocol, and Orbit Space Regulations, are numerous, and are available in the GC Orbit and System Space Code,
published by Federation Planet Bureau.

*Caption:* Docking procedure. Practise docking before hyperspacing to your target world by re-entering a Lave station.

*Caption:* Accelerate towards Lave, then slow down, stop and loop over to face the station.

*Caption:* Set the station in your sights, and make your approach slow and in the final moments dead slow. When just
outside the station egress, 'correct' the gyration of your ship by manipulating the left/right roll controls (N, M)
until the entrance tunnel appears horizontal.

*Caption:* Provided velocity is low, even if you scrape the sides of the tunnel, you will survive, though possibly at
the expense of some of your defensive shields.

| Key | Function: flying |
| --- | --- |
| 1 | Launch |
| SPACE | Increase velocity |
| J | Torus Jump Drive |
| SYMBOL SHIFT | Decrease velocity |
| N | Anti clockwise roll |
| M | Clockwise roll |
| S | Dive |
| X | Climb |
| H | Hyperspace |
| G then H | Inter-galactic hyperdrive |
| C | Docking computer on/off |

## 3. Interplanetary Travel

### In-flight combat

#### Combat protocol

Not all ships in deep space, even small fighters, are pirates. Most ships will respond to hostile action with hostile
action. If you attack a police ship or trade in contraband goods (see Trading), your legal status will be changed to
OFFENDER, or even higher. If you destroy pirate ships, or Thargoid invaders, (or asteroids) you will receive a bounty
payment. If you shoot at the Coriolis space station, its own defensive ships (Viper class fighters) will attack you.

#### Manoeuvring

The Cobra tradeship is fast, and has a very tight turning circle (though less tight at full speed); it is an ideal
combat ship against small packs of enemy vessels. It will outrun many attack craft by speed alone, but it will not
outrun a missile. Spinning, fast-slow, and duck-and-weave manoeuvres are very effective against the larger, less
manoeuvrable ships when they attack. A sudden decrease in speed followed by a tight 180° turn and an increase in
velocity will often give you a big advantage over pursuing enemy craft.

*Caption:* You must be prepared to outwit your enemies tactically. Speed of reaction will not in itself always be
enough.

#### Signs of danger

If you cannot make an interspace quick jump J towards the planet, there is a ship in the vicinity. It could be
dangerous.

If the Status Indicator, during flight, shows YELLOW or RED, prepare to engage in combat.

Flashing streaks on any screen mean laser fire is coming.

Laser fire striking the defensive shields makes a light screeching sound. Listen for laser fire striking the hull
direct. Through damaged screens it makes a low, screeching sound. DANGER.

An incoming missile will be detected, tracked, and a warning message flashed on main screen.

Some star pilots are braver than others and pirate ships may break off and run in the face of stiff resistance. Some
appear to know no fear - in particular Thargoid vessels, whose captains have had their fear glands surgically
removed.

**Code:** the sounds are the request bits of the sound module ([09-sound.md](../09-sound.md)): SoundHit (bit 6) is the
player hit. The incoming missile message is "INCOMING MISSILE" from the token set
([08-hud-and-text.md](../08-hud-and-text.md)).

#### Likely enemies

Lone-wolf traders - such as Cobra pilots - are constantly at risk from other spacefaring types. An understanding of
other loners, packhunters, and bounty killers is essential.

**Bounty hunters.** Unless you have achieved FUGITIVE status, and especially if you are highly ranked as a combateer
as well as being a criminal, bounty hunters will not bother a ship as insignificant as a Cobra Mk 3. In fact, many
bounty hunters favour Cobra trade-ships as they make an excellent disguise. But the real killers star-ride in the
sleek, and highly efficient, Fer-de-Lance Lightspeeder, in which they live for months at a time. Bounty hunters can
always be found outside Orbit Space, especially around worlds classified as 'dangerous'. They are invariably of
combat rating: DEADLY or ELITE. Bounty hunters rarely identify themselves to passing ships, and if pestered too
closely will usually kill.

*Caption:* A Zorgon Petterson Group (Zee Pee Gee) designed vessel, favoured by well-heeled bounty hunters and
freewheeling business corporations, the Fer-de-lance is a sophisticated craft capable of trading, combat, and leisure
function.

**Pirate vessels.** There are several ways of identifying a space-going ship as 'pirate occupied', and this is
essential since pirates and renegades will take any ship for their purpose, from an Asp to a massive Python. Pirates
exist everywhere in the galaxy, but cluster mainly around unstable GalCop worlds, especially worlds run on a feudal or
anarchic system.

Small ships hovering very distant from a planet are pirates. Large ships accompanied by a mixture of small fighter
types are pirates. Ships that refuse to acknowledge identification signals are pirates. Around worlds run by
autocracies, or clans, pirates will very often have been paid to leave trade ships alone. Piracy is a huge, and
complex, business, and any life-respecting trader will learn the tell-tale signs of pirate presence.

*Caption:* A 'shark-teeth' design personalises this Python Class Deep Space Cruiser, which probably belongs to a
galactic freebooter or pirate.

**Police.** In a Co-operative of Worlds as complex as the 2040 planets of the GalCop, the police can be as menacing as
they can be helpful. The typical police vessel is a Viper GH Class PulseShip, which is very fast, and very
manoeuvrable. They are on constant standby on every Coriolis and Dodec space station, and will attack - a pirate, or a
fugitive trader - within seconds. They do not make arrests, they destroy. There are different police departments
serving different purposes - narcotics, space-drunkenness, psychotic shooting, piracy, slave trading etc. - but all
have small fleets of these very fast Viper patrol craft.

*Caption:* The Viper police ship is a highly manoeuvrable short-range 'hunter-killer'.

*Caption:* A clear picture of a Fer-de-Lance Fighter, the pirate's answer to the Viper police ship. Fast and
manoeuvrable, it is large enough to carry two tonnes of cargo and 4 IFS Seek & Hunt missiles.

**Thargoid invasion ships and Thargons.** The Thargoids are humankind's deadly enemy, and throughout the 8 galaxies
there are at least 50 war zones between humanity and Thargoid. This highly technologically advanced insectoid race is
also at war with 17 other space-going life-forms.

All Thargoid combateers are ruthless in combat, and some may be comparable with elite-status human combat pilots.

Though most of the Thargoid Space Fleet is currently engaged by the Galactic Navy in InterGalactic Space, a few of the
smaller battle ships make occasional destructor-raids into human space. These ships are extremely fast for their size
and invariably have anti-missile (ECM) Systems.

*Caption:* The Galactic Banks will pay a handsome bounty for the destruction of a Thargoid invasion ship. Your most
dangerous enemy, a Thargoid may - in addition to its own fire-power - activate remote-controlled killer-craft
('thargons'). Destroy the 8-sided mother ship, however, and the thargons will cease to pose a threat.

Additionally, most Thargoid battle ships carry several small, remote-controlled 'Thargons', killer-craft each equipped
with a single, but highly advanced, pulse-laser. The Galactic Navy are developing their own deep-space RemCraft, and
pay a large bounty for any thargon craft that are brought to them.

(N.B. Bounty on Thargoid invasion craft destroyed is very high. Thargoid battle-cruisers believed to be able to
'hover' in Witch-Space (hyperspace) and destroy through-coming craft).

**Code:** witch space (WitchSpace `$7103`) has no sun, planet or station, and ActionThargoids `$B96B` brings three or
four Thargoids with ECM. A weak Thargoid launches Thargons (ActionLaunch `$B9E7`, kind 3)
([10-gameplay-logic.md](../10-gameplay-logic.md)). SHIP BOARDED BY THARGONS has a page (ArrivalScreens `$7278`), but
no code sets the state that shows it.

#### Other space types

**Rock hermits.** Pirates, ageing bounty hunters, or planetary outcasts, who create living space out of asteroids.
They usually choose large asteroids, and set up signal beacons to warn off miners. GalCop Law protects Rock Hermits,
but since most of the asteroid is hollowed-out, there is little advantage to be gained by 'mining' them anyway.

**Generation ships.** Before the development of the WS Thru-Space drive, in all its various forms, interstellar travel
occurred in large, self-sustaining environment ships - Generation Ships - most of which have now been logged and their
progress monitored. There are more than seventy thousand of these immense vessels ploughing their way through the
galaxy, some of them into their 30th generation. The penalty for interference with such a vessel is marooning.

**Space dredgers.** These immense factory ships are to be found wherever there has been a war, or a Thargoid invasion,
or a natural catastrophe. More than forty miles long, the dredgers are a life-form to themselves. The Dredgers are
huge cities in space, feeding off debris and ruination. Heavily armed, and with fleets of reconditioned fighter
ships, they are to be avoided at all cost.

**Code:** the rock hermit is a blueprint that flies the asteroid's shape (ShipRockHermit,
[07-objects.md](../07-objects.md)). There is no generation ship and no dredger in the image.

#### Combat console

1. Defensive shields take power from two energy bank sources, fore and aft.
2. Missile status depicts the number of missiles on board and whether they are 'targetted' (green) or 'untargetted'
   (black) or 'locked and ready to fire' (red).
3. Energy banks will rapidly drain if defensive shields are taking excessive fire. Using lasers or an ECM System will
   also drain their resources. When the fourth bank is tapped, an ENERGY LOW message will flash onto the screen.
   Eventually, in normal circumstances, the banks will be automatically replenished by surface radiation absorption.
4. Laser temperature will rise during continuous firing of the ship's laser(s). As the central housing overheats, a
   laser will temporarily cut out rather than destroy the system.
5. The 3-dimensional scanner operates in such a way that you can pinpoint a ship above and below yours, as well as to
   the front, behind or to the sides. The vertical bars show this clearly.

**Code:** MissileState `$D047`: 0 off, 1 armed, 2 locked. The missile boxes are coloured by it
([08-hud-and-text.md](../08-hud-and-text.md)).

### Equipping the Cobra Mk III

#### Aggressive weaponry

| Item | Tech level | Price/CR |
| --- | --- | --- |
| Fuel | Always | Varies |
| Missile | Always | 30 |
| Large Cargo Bay | Always | 400 |
| ECM System | 2 | 600 |
| Pulse Laser | 3 | 400 |
| Beam Laser | 4 | 1000 |
| Fuel Scoops | 5 | 525 |
| Escape Capsule | 6 | 1000 |
| Energy Bomb | 7 | 900 |
| Extra Energy Unit | 8 | 1500 |
| Docking Computers | 9 | 1500 |
| Galactic Hyperdrive | 10 | 5000 |
| Mining Lasers | 10 | 800 |
| Military Lasers | 10 | 6000 |

*Caption:* 4 offers weapons and other - non-combative - hardware for sale.

**Code:** EquipmentPrices `$705F` holds the same prices in tenths of a credit
([10-gameplay-logic.md](../10-gameplay-logic.md)).

#### Lasers

Pulse lasers are initially housed only in the front of the ship, and so no sights appear across rear or side views
until such time as you have sufficient credits (from combat and trading) to afford lasers for these mountings. As we
shall see, with sufficient cash you will also be able to upgrade pulse to more powerful beam lasers.

A: The Cobra astrogation console accommodates a single laser-fire key (A). Pilots with joysticks use the fire button,
of course. Even fully equipped only one laser may be fired at a time. If a laser overheats it will not fire (observe
the laser temperature bar).

Lasers are the principal armament of all space fighters.

Pulse lasers will be offered for sale at planets of Tech level 3 or above (see Trading). Beam Lasers will be offered at
Tech level 4 or above. If a beam laser replaces a pulse laser the price of the pulse laser is refunded after the beam
one has been fitted.

Pulse laser specification: Ingram Model 1919A4 Pulse Laser is recommended for all positional laser mountings, but is
especially effective for rear-shooting. Fires intermittent laser 'rods' 610mm in length, with a cycle rate of 1500
RoPM. The barrel is of high grade Allutium fibre, lined with tempered QuQorian Silica. Power provided directly from
inverse energy banks contained in main ship's drive. Each rod is capable of piercing 267mm of Flux-Locked metal.

Beam laser specification: Ingram Model M1928A2 is highly recommended for front shooting. Beam lasers fire continuous
laser strands, up to 150 in parallel. Barrel is Allutium 4- lined with tensioned plastiglass, and as with the 1919A4
Pulse laser, power is provided by main drive link. Beam lasers are capable of slicing through 410mm FL metal.

Military lasers are the very height of sophistication. Costing fifteen times the price of a pulse laser and available
only on planets at Tech level 10, it is an extremely effective piece of hardware.

(See also Mining lasers under Non-combative Equipment.)

Military laser specification: Range and penetration twice as effective as the Ingram model M1928A2 beam laser. This is
Lance & Ferman's entre into the laser market. Hitherto known for their highly effective and relatively cheap missile
systems, in the military laser they have in effect created a whole new laser market. The LF90 is the current
computer-aided model and comes with X4SUSAT sights.

#### Missiles

Missiles are always available, whatever the nature of your destination world, though no more than four may be carried
at any one time. They are extremely effective weapons and are carried by the larger star ships. Your ship's computer
will warn you when one is fired at you with a message on-screen. Unless your ship is fitted with ECM (see below) you
will have to outmanoeuvre the missile, which will home in on you relentlessly. If a missile hits you, it can almost
completely exhaust a fully charged shield and, if your shields and energy are low, may well be fatal.

Before a missile can be fired it must be locked onto a target. When fired, it will home in on that target and destroy
it, unless your enemy successfully takes one of the precautions described above. The missile launch mechanism is very
reliable and hardly ever jams. Missiles can be locked onto targets in any view (1, 2, 3 or 4).

T: The targeting sequence is engaged by hitting the T key. One of the square missile status indicators on the
astrogation console will then turn green. When any possible target enters the cross-hair region the missile will lock
onto it, the missile status block turning red. A beep will sound to inform you of this.

F and U: The F key will then fire the missile. The U key (Unarm) will abort the sequence at any time before firing.

Missile specification: Lance & Ferman Homing Missiles (4x4) are now recommended for all small class trade-combat ships,
but can be fitted as part of a mixed design weapon rack. LF missiles have 2IL-135 guidance systems, and optional
manual directional control overrides. Warhead packed with Terminal 9 explosive, and the 4x4 is invulnerable to all
known counteraction, except ECM systems. Capable of Megazon Destruct Force 7. Prototype first used in 2987, during
Ineran Wars.

*Caption:* Readily available and relatively cheap at 30 Credits, missiles are extremely effective weapons. T targets
a missile when an enemy is in your sights (a bleep confirms this). F will fire it; U will unarm it. In the picture,
this ship's energy banks are about to be substantially reduced.

**Code:** the jam is real. F with a locked missile asks for a new ship (ShipAction, action 2). When no slot is free,
the missile stays on its rest and message 0, MISSILE JAMMED, is raised (`$9C05-$9C0A`).

#### Energy bombs

W: An energy bomb will be offered for sale at a planet of Tech level 7 or higher, and can be used only once. It is
activated by the W key and will destroy all other ships, asteroids, and missiles in the vicinity.

Energy bomb specification: Medusa Pandora Self Homing Energy Bomb (available at Tech Level 7 worlds or higher) is a
tactical weapon capable of Megazon Destruct Force 13. Has heat radius of 9000 km. Developed by Klaus-Kline
laboratories for multi-role combat using 'launch-and-leave' techniques.

**Code:** EnergyBomb `$7089` clears Equipment+6, sets BombKill `$9C95` and flashes the screen 24 times; no recording
fired one.

*Caption:* Once a defensive shield is depleted, enemy missiles and lasers will take energy directly from your ship's
energy banks (1, 2, 3, 4 on your console).

*Caption:* ENERGY LOW appears on-screen when further attacks will very soon spell disaster for your ship.

*Caption:* Spinning away from a pirate ship is an escape capsule which will take the space brigand to a station
nearby.

#### Defensive measures

**Safety zone.** The Orbit Space around any Coriolis Space Station is safe. The Station's own defences will come to
your immediate assistance. Entry to safety zone is signalled below the compass.

**Shields and energy banks.** Your ship comes equipped with fore and aft shields and energy banks. The shields protect
your ship from aggressive fire, and will be recharged from the energy banks. Constant fire will harm the shields.
Once a shield is depleted, enemy lasers and missiles striking that shield will take energy directly from the energy
banks and may even destroy items of cargo or ship fittings. When all your energy banks are empty your ship will be
destroyed. Using lasers or an ECM system will also deplete your energy banks.

The ship's computer will keep you informed of any damage to your ship and will also warn you when energy levels are
dangerously low.

An Extra Energy Unit may be fitted at planets of Tech level 8 or higher, and doubles the energy bank replenishment
rate. This is the energy unit with the copper coloured top. No other unit looks like it, or lasts like it.

Defensive shield specification: The shields consist of hi-tense flux webs of Zieman-charged sub-particles. They are
weakest where the laser and missile tubes pass through the ship's hull, and along the central ship band where the two
shields overlap, and cause a stress zone.

**ECM.** E: An ECM System (literally Electronic Counter Measures System) is offered for sale at Tech level 2, and may
be used any number of times given sufficient energy replacement. When activated by the E key, ECM destroys all
missiles in your vicinity - including any that you have fired. Some enemy ships, especially traders, will have this
and may use it against your missiles. Your ship's computer displays an E on the console when it detects ECM
broadcasts.

Anti-missile (ECM) system specification: Radiant-Magnetic 'wipe-out' using ion-saturation theory developed by Bell
and Braben on Riedquat 359. Electronic Counter Measures Systems use minute charged particles of InterSpac Heavy
Element dust, releasing their radiant energy and setting up expanding nuclear flux chains.

**Escape capsule.** Q: An escape capsule can be fitted in place of your cabin at any world of Tech level 6 or higher.
If Q is then hit during combat the capsule will be jettisoned from the ship, be automatically tracked by the nearest
world and will travel safely to a Coriolis space station. Your cash will be preserved but all your cargo will be lost.

However, this item comes with a widely recognised insurance cover which will guarantee you a new Cobra Class ship,
equipped in like manner. The contents of the cargo hold is exempt from this protection.

Since the unique IR signature of a ship's hull is used to file police records, abandoning your ship in this way will
have the effect (unfortunately exploited as much by galactic brigands as trader victims) of clearing your police
record.

You may see an escape capsule leaving an enemy ship. This will not harm you unless you crash into it.

Escape capsule specification: Recommended model is the Xeeslan FastJet LSC 7, which can support two human life-forms
for seven weeks, in moderate Suspended An.state.

**Code:** EscapePod `$9C1C` does what the text says and a little more: the hold is emptied, LegalStatus zeroed, the
pod itself lost (Equipment+5 = 0), and it is refused in witch space. The rest of the equipment stays.

#### Non-combative equipment

**Fuel.** Fuel is always available. You can refill your tanks to full (7 light-year) capacity - no less is permitted.

**Fuel scoops.** Fuel Scoops may be fitted to the hull at a planet of Tech level 5 or higher. These enable a ship to
obtain free hyperspace fuel by 'skimming the sun' - flying close to it at high velocity.

Since fuel scoops utilise powerful electro-magnetic fields to guide the solar wind into their converters, they may
also be used to pick up miscellaneous space debris. Almost all pirate vessels are fitted with these so that they can
blast their prey apart and sift among the wreckage, rather than attempt to dock with a hostile craft.

Once fuel scoops are installed, you can scoop up an object (such as a cargo canister) by keeping it in the lower half
of the screen view area while flying right up to it.

Fuel scoop specification: Fuel scoops are considered an essential for Deep Space, and dangerous zone trading. They
have a standard design, and a standard fitment. They use powerful electromagnetic fields to guide solar wind or small
space debris into their ReQax convertors.

**Code:** the scoop test wants the object below the centre (y negative) and the scoop fitted
([10-gameplay-logic.md](../10-gameplay-logic.md)).

**Cargo bay extension.** One cargo bay extension can be bought, increasing the hold space from 20 to 35 tonnes.

Cargo bay extension specification: Standard model is the Mariner Freight Chamber.

**Docking computer.** C: This is available from all Tech level 9 planets; they are fitted to the ship's flight control
system and enable it to dock the ship automatically. The auto-docking sequence is toggled on and off by the C key.

Docking computer specification: The SinCorn RemLock D&A System is a sophisticated and expensive piece of gadgetry. It
comes with MemnSomn pilot interaction to induce hi-cram sleep during the manoeuvre.

**Intergalactic hyperdrive.** G then H: The intergalactic hyperdrive is obtainable only from planets at Tech level 10
or higher, and can only be used once. The Inter-Galactic Hyperdrive is engaged by pressing G then H.

IGH specification: Although a number of manufacturers have supported a whole range of IGH motors, it is recommended
you remain loyal to Xexor/Hikan who provide the standard hyperspace transit drives.

**Asteroid mining lasers.** Asteroid mining involves the fitting of fuel scoops and special mining lasers to your
ship. Ships which always carry them are known as 'Belters'. They search for asteroids and, on finding one, use the
laser to fragment it into pieces sufficiently small to be taken into the cargo bay.

Mining lasers specification: Kruger Model ARM64 Sp. Mining laser is highly recommended as both a trade and combat
addition. Uses variable frequency laser rods of 200mm length, fired in wide beam, 100 channels/beam. Automatic
debris-pattern lock ensures no fragments of large size of target asteroid impinge on ship space. Can destroy
asteroids of up to 2KtHH durable Mass. Must be fitted with a fuel and matter scoop.

| Key | Function: combat |
| --- | --- |
| A | Fire laser |
| T | Target missile |
| F | Fire missile |
| U | Unarm missile |
| E | Operate ECM |
| W | Launch energy bomb |
| Q | Launch escape capsule |
| 4 | Buying equipment mode |

## 4. Intergalactic Trading

The Cobra Mk III, designed primarily as a trading ship, combines combat efficiency and manoeuvrability with
substantial cargo space (20 Tonne Canisters) and with scoop attachments for space debris, jettisoned cargo and space
rock.

Most space stations have made the process of trading very simple, in order to facilitate a fast turnover in goods and
ships. Import and export tariffs - which are high on some worlds - are automatically added or deducted and this is
reflected in the prices shown. The auto-trader system, employed by the Cobra, does not allow for more specific trading
deals to be performed.

A selection of the more valuable alien items that are tradeable is given in this manual, but the trader must deal
with them in person.

Once docked you are linked directly with the CorCom Trade System. At your request you can obtain a list of basic trade
items available for purchase.

Slaves are measured by the tonne in galactic trading. This may seem a little strange, but it includes the cryogenic
suspension system necessary to keep them alive during space travel. The slave trade, once almost eliminated by the
Galactic Government is now returning, despite the efforts of the Galactic Police Force to suppress it.

| Item | | Average price/CR |
| --- | --- | --- |
| Food | Simple organic products, see below | 4.4 / tonne |
| Textiles | Unprocessed fabrics | 6.4 |
| Radioactives | Ores and by-products | 21.2 |
| Slaves † | Usually humanoid | 8.0 |
| Liquor/Wines | Exotic spirits from unearthly flora | 25.2 |
| Luxuries | Perfumes, Spices, Coffee | 91.2 |
| Narcotics † | Tobacco, Arcturan Megaweed | 114.8 |
| Computers | Intelligent machinery | 84.0 |
| Machinery | Factory and farm equipment | 56.4 |
| Alloys | Industrial Metals | 32.8 |
| Firearms † | Small-scale artillery, sidearms etc. | 70.4 |
| Furs | Includes leathers, Millennium Wompom Pelts | 56.0 |
| Minerals | Unrefined rock containing trace elements | 8.0 / kg |
| Gold | | 37.2 |
| Platinum | | 65.2 |
| Gem-stones | Includes jewellery | 16.4 / g |
| Alien Items | Artefacts, Weapons etc. | 27.0 / tonne |

† These items are defined as illegal by the Galactic Government, so trading in them is risky.

**Code:** the order is the market table Commodities `$701B` (4 bytes an item, the same bytes as BBC Elite's). The
unit is in bits 5-6 of each item's second byte. It gives tonnes for Minerals, kg for Gold and Platinum, and g for
Gem-stones, so the manual's "8.0 kg" for Minerals and its missing unit for Gold are the manual's slips. The manual's
average prices are not stored anywhere: the price is made per market from the base, the economy and a random
fluctuation ([10-gameplay-logic.md](../10-gameplay-logic.md)).

*Caption:* Shown on this list are the quantities of each item available, and the current market price per unit. Most
CorCom Trade Systems deal exclusively under blanket categories, including FOOD, MACHINERY, MINERALS and GEMSTONES.

*Caption:* K activates a list of basic trade items at current market prices.

The prices shown at the time of trading represent an offer to you and will be guaranteed while you are in Trading
Mode.

The purchasing of items is almost instantaneous. You will be offered each in turn. If you do not wish to buy, merely
indicate your decision by pressing ENTER.

*Caption:* ENTER offers an inventory of cargo, fuel and cash.

*Caption:* 2 puts you in purchase mode. Press ENTER if you do not wish to purchase a particular item.

If you wish to buy, numerically indicate the amount you wish to purchase; autoSCAM modules will immediately load your
purchase into the cargo bay. Your screen will indicate your remaining credit facility.

When all items for sale have been offered to you your cargo hold status will appear to confirm your purchase.

The Cobra trade ship must dock with a Coriolis space station before buying or selling cargo. It has no Free Space
trade facility, apart from routine jettisoning of cannisters.

Once docked, the selling process is automated, although there is no requirement to sell.

*Caption:* 3 puts you in selling mode.

### How to trade

**Buying mode for goods**

| Key | |
| --- | --- |
| K | list of goods available on target planet |
| ENTER | inventory of your cargo |
| K | to see again what is available |
| 2 | you are now being asked (at the bottom of the screen) how much food you want to buy. Choose a number equal to the tonnage of food you wish to purchase, and press ENTER. You will then be asked, in turn, how much you want to buy of each item on the list of goods available. Press ENTER when you do not wish to purchase. You can buy only 20 tonnes in total, and no more of a commodity than there is available. Once you have gone through all the items, the trading computer will print up your inventory. |

**Selling mode**

| Key | |
| --- | --- |
| 3 | enters selling mode. This comprises a series of questions, the answers to which will concern the possible sale of all cargo including that just bought. |

\*(Advanced selling systems permit the sale of precise amounts.)

**Code:** BuyCargo `$E6AE` and SellCargo `$E8AE` ([10-gameplay-logic.md](../10-gameplay-logic.md)). BuyCheck
`$E7DB` refuses with QUANTITY? (more than the stock), CASH? or CARGO?. The "20 tonnes in total" is FreeSpace `$D07C`
(35 with the large cargo bay), which only goods sold by the tonne use up; kg and g goods are limited only by a hold
count of 255.

### Advice to traders

The Cobra trade ship can be fitted with four lasers, four missiles and one energy bomb. This should be sufficient to
make trade possible within the System Space of even heavily piratised worlds. But it is strongly recommended that
pilots achieve a combat of at least 'Deadly' before any worlds designated 'Anarchy' or 'Feudal' are approached,
especially if the cargo is high tech machinery or luxury goods.

To make money as a trader is no easy task. Unless you have backing capital you would be well advised to start with
foodstuffs, textiles, minerals and luxuries.

*Caption:* An artist's impression of a section of the cargo bay of a Python Class Interstellar Freighter. It is the
largest known freighter with a 100 tonne capacity cargo bay and is used mainly on the safer trade routes.

Demand for goods varies widely and prices within planets fluctuate, but GalCop regulations prohibit planets from
advertising their requirements or announcing their market prices beyond their own System Space. Any trader,
therefore, approaches all transactions with a certain financial risk.

Trade depends upon demand, and selling prices depend upon the level of demand on the planet, and its available
money. None of these factors can be assessed before docking.

Agricultural planets invariably have excess produce at reasonable purchase prices, and such food sells well at
industrialised, middle- to high-technology worlds. Raw materials, and ores, will sell well to middle-tech worlds,
which are usually able to refine them, and the refined product can fetch excellent prices at worlds of very high tech
status.

The rules are complex, and anarchy and piracy has its effect on causing the rules to change.

In trading with a planet, consider its economic profile:

Agricultural worlds need specialist food and raw materials, but mostly basic machinery and spare parts. If they are
rich, they need luxuries and high tech industrial machines. They produce food in quantity, raw materials and
specialised 'organic' items, like some textiles.

Industrial worlds need agricultural produce; raw materials (for refining); resource exploitation machinery; (if rich)
high tech goods. They produce basic items of need for civilised worlds: beds, seals and gaskets, power storage units,
basic weapons, mass produced fertiliser, mass produced medicines etc.

Think about a planet's needs.

Think what might make the society function.

Don't trade expensive trivia to a hungry world.

IF THE PROFIT ISN'T WORTH IT, TRADE IT SOMEWHERE ELSE.

### Alternatives to trading

Since the Cobra craft is equipped as a fighter as well as a trader, with in-built capacity for strengthening its
armaments, there are alternative life-styles to trading which may prove profitable, but which are excessively
dangerous.

**Bounty hunting.** Galactic banks, which insure the larger trading convoys, will pay a large bounty for each pirate
ship destroyed. A ship's computer will transmit photographic evidence of any kill to the GalCop Bank Federation
Monitoring Authority. The IR signature of the destroyed ship is then tallied with all known pirate vessels, and the
bounty hunter pilot credited accordingly.

Bounty hunters commonly have Cobra Class ships in order to masquerade as traders. They simply hyperspace into a system
(anarchic and feudal worlds especially) and wait to be attacked, ensuring that they have sufficient hyperspace fuel
(Quirium) for a quick escape.

**Piracy.** Piracy is widespread throughout the 8 galaxies, and many pirates are not hardened criminals at all, but
failed traders who have turned to this way of life in desperation. To survive as a pirate, looting freighter convoys
and small ships, requires a high degree of combat experience, since not just Police Vipers will pursue them, but other
pirate ships and Bounty Hunters, too, will prey upon them.

But the rewards are high. Provided the pirate ship is equipped with a fuel scoop, the jettisoned tonne-cannisters of
attacked cargo ships can be scooped up and traded.

**Asteroid mining.** There is money in rock, but to make the most of it a Cobra ship must be fitted with a fuel scoop
and a MinReduc 15 Mining Laser (or some equivalent type). The mining laser will blast very large asteroids into very
small fragments and the scoop can rapidly swallow this tradeable ore.

*Caption:* Asteroids are large chunks of rock which are mined (for the valuable trace elements that they contain) with
the aid of a mining laser designed to fragment the rock into splinters small enough to be taken into a cargo bay by a
fuel scoop. As they are a navigational hazard, a small bounty is paid for destroying an asteroid, and a kill awarded
(which will help to improve your rating).

**Free space cargo.** Trade ships are often destroyed (by natural catastrophe or enemy action) and their cargo left
ungathered. Using a fuel scoop such 'free bounty' can be collected. The contents of the cannisters will be unknown
until they are taken aboard and examined, and may be worthless or worth a fortune. If their contents are illegal
goods, they cannot be traded or sold without legal risk.

*Caption:* Chromalloy canisters are used to store cargo during space flights. They are extremely resilient and may
survive the demise of their holding vessel. Such canisters can be picked up in space with a fuel scoop fitted to the
bottom of a ship, but pilots beware picking up contraband by mistake since it may harm status and invite attack.

(NB: Pressurised cargo canisters are the Universal means of storing cargo for Interplanetary Space Voyaging. Made of
HiFlux Chromon-alloy, they hold one Gal Tonne of goods, under variable pressure and temperature conditions. Tales have
been told of such barrels being discovered after over five hundred years on barren moons, and such 'Moon salvage' is
a remarkable source of historical artefact material.)

**Code:** a scooped item goes through AddCargo `$D190`, which takes one unit of free space, names the item and
charges contraband: firearms 2, slaves and narcotics 4 on LegalStatus. Buying them costs the same, unit by unit
(AddCargoContraband `$D1AD`).

**Illegal trading.** It is surprising how many planetary systems will allow the purchasing of illegal trade items,
notably firearms, narcotics (especially Arcturan Megaweed) and slaves. Slaves are supplied in cryosuspension in
transporter coffins, and often turn out to be old and sick specimens of vaguely humanoid life forms. Nonetheless, few
systems will allow the selling of these items without taking recriminatory action.

| Key | Function: trade |
| --- | --- |
| K | Market prices |
| ENTER | Inventory |
| 2 | Buying mode/trade goods |
| 3 | Selling mode/trade goods |

## 5. Political Profile of the Universe

### Consequences for trade

To trade successfully, and profitably, will almost certainly require you to fly the Cobra trade ship into politically
unstable planetary systems. Pirate and freebooter activity is high in many solar systems, and adequate ship defences
are essential if the rewards of higher selling prices are to be reaped.

For the benefit of new traders, a brief political summary is given below, but reference should be made to Kroweki &
Carr's PsychoHistory and Economic Theory in the GalFederation, 2845.

Planetary governments, or federations, determine the relative safety of their Solar Space. Ranked in decreasing order
of safety, the 2040 officially registered worlds of the Galactic Federation can be classified as

1. CORPORATE STATES
2. DEMOCRACIES
3. CONFEDERACIES
4. COMMUNIST STATES
5. DICTATORSHIPS
6. MULTI-GOVERNMENTS
7. FEUDAL WORLDS
8. ANARCHIES

**Code:** the system's government is Government `$DEF9`, 0-7, from Anarchy (0) to Corporate State (7). SpawnShip
`$BBBA` uses it to choose between a pirate and a peaceful ship (anarchies always pirates), and PirateChance `$DE39`
to decide whether an arrival finds the station pirate-held ([10-gameplay-logic.md](../10-gameplay-logic.md)). In the code's numbering (Anarchy, Feudal,
Multi-Government, Dictatorship, Communist, Confederacy, Democracy, Corporate State) the order is exactly the manual's
list reversed.

**Corporate states.** Like ENGEMA and ZAATXE, these are well-ordered worlds, which have usually developed from settlers
who practised a free trade form of competition. Taxation is high on such worlds, but the living standards are high
also. Corporate planets wish to protect their trade, so goods are expensive, but luxuries are welcomed. Import
licences are often necessary.

Engema is an agricultural world, run as a single farming co-operative. Farmers receive a fixed payment for their
crops, whether or not the harvest is good, and selling prices do not vary greatly. It is a dependable market, and
customer relations are good. Luxuries, machinery and raw materials sell well here.

Zaatxe is an example of a rich, industrial state (Tech level 12). It produces luxury goods, elaborate and innovative
machine systems, and specialises in Prototype design. Prices fluctuate depending upon the level of inter-state
competition, but it is always a safe bet to buy recently-developed machine items which have not yet spread very far
across the galaxy.

**Dictatorships.** Dictatorships such as the worlds LAVE and ENZAER, are only moderately safe to trade with, but are
well worth the risk (provided the trader is well defended and combat trained). Very often pirate attack will not occur
because of an agreement between pirate fleets and the world itself. A proportion of all incoming trade is 'allowed'
to be stolen by pirates, who will then leave the world alone, and protect its ships from aliens or rogue traders. It
is an uneasy liaison, which often breaks down.

Lave is an agricultural world, and Enzaer an industrial planet, but a similar principle operates on both surfaces.
There are two trading standards, that of the People and that of the Aristocracy. Standards of living are artificially
generated, a veneer of progress, and luxury goods, machinery and textiles sell well - usually. The great demand,
however, is for basic commodities, especially foodstuffs, clothing and raw materials. These will sell well when the
voice of the People has been raised in protest.

**Anarchy planets.** A trader can make his biggest profits here and reach his grave the quickest. Worlds like Onisou
and Xeesenri have vast wreck-yards in far orbit, the dead places of ships that came to trade honestly, and fell prey
to trickery.

These are lawless places, and have usually become so because the original settlers competed too hard when there was
too little resource material. Those worlds which survived holocaust did so because of uneasy and bloody alliances
between clan families. Pirates and mercenaries were hired for protection and assassination purposes. Anarchic worlds
will trade readily in narcotics, slaves, firearms and exotica, and the price will be good ... if you get a price at
all. These worlds are almost always supplying invisible Masters, usually elite trader/combateers who have turned to
crime as the most profitable way of life. Such form loose federations, and trade on the black market extensively
throughout the galaxies.

These worlds pay highly for goods they cannot produce themselves, because they know that traders avoid them. Their
own products need specialised, illegal outlets: weaponry, narcotics, eavesdropping devices ... if it's covert, then
anarchic worlds are producing it. Trade in these items and you will get rich quick, or dead quick, or at least become
a 'Fugitive'.

**Code:** the named systems are galaxy 1's, generated from the same seeds as the BBC's (SystemData `$E08C`).
Lave's data screen in the recording d1 reads DICTATORSHIP and RICH AGRICULTURAL
([08-hud-and-text.md](../08-hud-and-text.md)).

### Alien races

Of the 2040 officially registered planets in the GalCop, all but 45 support human colonies only, that is to say, human
presence elsewhere is restricted to settlements in under-populated parts of the land surface.

Trading at such worlds depends, for its success, very much upon the extant state of co-operation between human and
alien. Humans control the Coriolis stations in orbit, but the availability of items for trade, and their relative
expense, can be affected by the controlling life forms.

Most alien life forms are either too primitive, or too glad of off-World trade, to interfere. Some, such as the
Reptiloid life form of Esanbe or the Amphibioids of Anbeen, can make a trader's life very difficult, by haggling at
the point of a laser.

The available planetary information on all worlds will indicate the nature of the inhabiting life form.

**Bird-forms.** Dealing in alien artefacts on such worlds often involves forming a close liaison with Flight Elders,
or Nest Elders, and this is very much a job for the specialist. Bird-forms are, on the whole, a delight to trade with,
and the highest form of honour (fairly universally) that an off-worlder can receive is an invitation to 'keep the
eggs warm for a moment'.

**Amphibioids** are usually a lot sharper than their wet, sluggish appearance would suggest. They are usually keen to
trade in narcotics, or exotic foodstuffs. Skin creams are always well received. Technologically they tend to be
backward, but will pay high prices for such middle-range items as automated ponds, croak metres, spawn freezers and
swamp purifiers.

**Felines** are dangerous in the extreme. No matter what sort of political structures the world may have, feline
aliens are pack orientated, and feudal, and very unpredictable. All traders are advised to wear body suits, to prevent
secretions of sweat from triggering a feeding response among these hostile and enigmatic life forms.

To win the confidence of a feline alien is almost invariably to be invited to mate, so a certain aloofness is
recommended.

**Insectoids.** The most dangerous insectoidal life form is the Thargoid, which is mentioned in the Combat section.
Insectoidals are usually highly intelligent, often existing as a group mind. There is rarely any individuality among
insectoids, and the trader must beware making deals in such a way. One life form builds earth cities up to four miles
high, and over four million drones live in the middle levels. According to legend, any trader who voluntarily ascends
the earth passageway from ground to upper surface of these immense mounds is honoured with the rare title Ascender of
the Scent City. And then consumed alive. But trading with insectoids can be immensely profitable, as there are so many
of them (to trade in wrist watches, for example, means two to four watches per individual in a clone-group of perhaps
ten thousand).

In dealing with any alien life-form, for the purposes of trade, there are three cardinal rules:

- Learn the body language of the alien race
- Cover up your body scent
- Beware of Carapace concealed weapons.

**Code:** "all but 45" is the manual's number; the species come from the seeds (DataScreen `$EDDF`, as BBC Elite).

## 6. Observer's Guide to Ships in Service

In most trading and combat operations, certain ships are repeatedly encountered. All ships, whether unarmed cargo
shuttles or Navy transporters, are potentially dangerous as pirate and bounty hunting activity spreads. Some ships are
potentially more dangerous than others.

The brief guide given here is just an indication of the range of ship-types plying the trade and space lanes. The
illustrations show top, side and front views of each craft. Dimension data provide the scale. For a fuller account see
Jane's Galactic Ships and Remote Colonial Construction, 5th Edition, 3205 pub. Trantor House.

**Code:** of the nine ships in the guide, the image flies eight. The Adder is not in Side A, which loads the Krait in
its place ("With Krait ship" on the label); Side B loads the Adder ([03-build-and-load.md](../03-build-and-load.md)).
The Viper and the Python are there; the guide has no Thargon, canister, asteroid, missile or Coriolis page.

**ADDER.** Manufactured by Outworld Workshops, a rogue breakaway company from Spalder and Prime Inc. which operates
without a licence from an unknown location, the Adder-class craft has dual atmospheric-spatial capability and is
often used by smugglers. Pregg's 'wingfolding' system permits landing on planetary surfaces. Carries one missile.

| | |
| --- | --- |
| Dimensions | 45/8/30 ft |
| Cargo capacity | 2 TC (Tonne Canisters) |
| Armaments | Ingram 1928AZ beam laser; Geret Starseeker missile |
| Maximum velocity | 0.24 LM (Light Mach) |
| Inservice date | 2914 AD (Outworld Workshop) |
| Crew number | 2 |
| Hull stress factor | TK o 28 |
| Manoeuvrability | CF4 (Curve Factor) |
| Drive motors | AM 18 bi Thrust |
| Hyperspace capability | Yes |

**ASP MK II.** Galactic Navy vessel designed and manufactured in government workshops, incorporating secret
self-destruct devices which are primed to activate when the astrogation controls are used by unfamiliar hands.
Integument has chameleon properties enabling the ship to assume effective camouflage in any type of environment.
Intended for reconnaissance and the transport of high-ranking military personnel from combat it is very fast and
manoeuvrable. Despite its hazardous nature it makes an ideal pirate vessel, primarily because of the speed, camouflage
and high intensity Hassoni-Kruger Burst-lasers. The Asp II has room for powerful shield generators, but only one
missile pod.

| | |
| --- | --- |
| Dimensions | 70/20/65 ft |
| Cargo capacity | None |
| Armaments | Hassoni-Kruger Burst Laser; Geret Starseeker Missile |
| Maximum velocity | 0.40 LM |
| Inservice date | 2878 AD, GalCop Workshops |
| Crew number | 2 |
| Hull stress factor | TT 16 |
| Manoeuvrability | CF4 |
| Drive motors | Voltaire Whiplash HZ Pulsedrive |
| Hyperspace capability | Yes |

**Code:** the "chameleon properties" are the second mission's cloaked Asp (MissionShip `$9CB2`), drawn as its laser
only while it is cloaked.

**COBRA MK III.** Larger, more popular version of the Cobra Mk I (the Mk 2 only reached prototype stage and was
abandoned due to a design fault in the hull). This ship is equipped with several special features, including Zieman
Energy Deflection Shields, fore and aft, and mountings for four Ingram Pulse lasers. The Cobra is much favoured by
lone-wolf traders who wish to combine potential superior combat qualities with adequate cargo space.

| | |
| --- | --- |
| Dimensions | 65/30/130 ft |
| Cargo capacity | 20 TC |
| Armaments | Ingram laser system; Lance & Ferman Seek & Kill missile system |
| Maximum velocity | 0.30 |
| Inservice date | 3100 AD (Cowell & MgRath Shipyards, Lave) |
| Crew number | 1 or 2 |
| Hull stress factor | TJi 18, C-Holding M 18 |
| Manoeuvrability | CF8 |
| Drive motors | Kruger 'Lightfast' motors, Irrikan ThruSpace |
| Hyperspace capability | Yes |

**FER-DE-LANCE.** A Zorgon Petterson Group (Zee Pee Gee) designed vessel favoured by well-heeled bounty hunters and
freewheeling business corporations. A sophisticated craft, capable of both limited trading, combat, and leisure
function. The spacious hull is mainly given over to sophisticated weaponry, defences and navigation equipment at the
expense of cargo capacity. Cabin accommodation is large and luxurious with extensive Owndirt Inc. recycling
facilities, encouraging extended live-in periods (useful whilst pursuing a quarry). Fuel scoop is a standard fitting,
ensuring complete self-sufficiency.

| | |
| --- | --- |
| Dimensions | 85/20/45 ft |
| Cargo capacity | 2 TC |
| Armaments | Ergan Laser System; IFS Seek & Hunt missiles |
| Maximum velocity | 0.30 |
| Inservice date | 3100 AD, Zorgon Petterson |
| Crew number | 12 |
| Hull stress factor | TJi 10 |
| Manoeuvrability | CF5 |
| Drive motors | Titronix Intersun Ionic for LT |
| Hyperspace capability | Yes |

**KRAIT.** Small, reliable one-man fighter, common until the standardised version of the Mamba became available on the
open market. Several of these early Faulcon deLacy designed craft may still be found in service in remote areas, but
spare parts are no longer available and the need to cannibalise has reduced numbers still further in recent years.

| | |
| --- | --- |
| Dimensions | 80/20/90 ft |
| Cargo capacity | 10 TC |
| Armaments | Ergon laser system |
| Maximum velocity | 0.30 Light Mach |
| Inservice date | 3027 AD (deLacy ShipWorks, Inines) |
| Crew number | 1 |
| Hull stress factor | C-Holding A20-B4 |
| Manoeuvrability | CF8 |
| Drive motors | deLacy Spinlonic ZX 14 |
| Hyperspace capability | No |

**PYTHON.** One of the larger trading vessels manufactured in Inera Orbit Space by Whatt and Pritney ShipConstruct.
Cabin accommodation is cramped and spartan in contrast to facilities for cargo and 'alien environment' transport.
Though slow and ponderous, the craft has powerful CC-Voltaire shields and Volt-Variscan Pulse lasers, earning it the
nickname of the 'space porcupine'. Not commonly attacked by pirate ships, but a popular craft for freebooters, usually
used as a way-station and storage hulk.

| | |
| --- | --- |
| Dimensions | 130/40/80 ft |
| Cargo capacity | 100 TC |
| Armaments | Volt-Variscan Pulse Lasers |
| Maximum velocity | 0.20 |
| Inservice date | 2700 AD, Whatt and Pritney ShipConstruct |
| Crew number | 20-30 |
| Hull stress factor | T(ensman) YO 20, C-Holding K21-31 |
| Manoeuvrability | CF3 |
| Drive motors | 4 C40K V Ames Drive, Exlon 76NN Model |
| Hyperspace capability | Yes |

**SIDEWINDER SCOUT SHIP.** Designed by Faulcon de Lacy and built in the Onrira Orbital Shipyards by Spalder and
Starblaze Inc to Galactic Navy specifications for a multi-purpose support craft. Mainly used for atmosphere and
planetary surface scouting, but extensively too for city-strafing, reconnaissance and infantry air support (and by
pirates who favour speed and elusiveness, its primary advantage). Has some interspatial capability, not including
hyperspace, and must be carried through hyperspace by jump-capable vessels. Hull is too small for the installation of
fuel scoops, or more than one missile pod.

| | |
| --- | --- |
| Dimensions | 35/15/65 ft |
| Cargo capacity | None |
| Armaments | Dual 22-18 lasers; Seeker missiles |
| Maximum velocity | 0.37 |
| Inservice date | 2982 (Onrira Orbital / Spalder & Starblaze) |
| Crew number | 1 |
| Hull stress factor | Not available, C-Holding C50 |
| Manoeuvrability | CF9 |
| Drive motors | de Lacy Spin Ionic MV |
| Hyperspace capability | No |

**THARGOID INVASION SHIPS.** Though most of the Thargoid Space Fleet is currently engaged by the Galactic Navy in
Intergalactic Space, a few of the smaller battle ships make occasional sorties into Human Space. These ships are
extremely fast for their size and invariably have ECM Systems (this was originally a Thargoid invention to counter
Navy missiles, subsequently copied by the Navy from captured Thargoid ships).

Additionally, most Thargoid battle ships carry a few small remote-controlled ships, each equipped with a single pulse
laser. It is rumoured that the Galactic Navy are designing their own remote-controlled fighter, and will pay well for
Thargoid ones to study.

| | |
| --- | --- |
| Dimensions | 180/40/180 ft |
| Armaments | Widely varying. Mountings available for most systems |
| Maximum velocity | 0.20 LM |
| Inservice date | Uncertain |
| Crew number | 150 |
| Hull stress factor | Uncertain |
| Manoeuvrability | CF6 |
| Drive motors | Thargoid invention |
| Hyperspace capability | Yes |

**VIPER (POLICE SHIP).** Small, highly manoeuvrable short range 'hunter-killer', the Viper was specifically designed
for GalCop Space Policing purposes by Faulcon Manspace and are built under licence on all Medium Tech worlds. The
Viper is a single pilot craft, but can carry up to ten humanoid passengers. It has no cargo space, but has a 'tug'
capability, and can tow a ship of up to 140,000 MTS mass (including the Cobra Mk 3). This popular ship is also carried
by large freighter convoys, for defensive purposes.

| | |
| --- | --- |
| Dimensions | 55/80/50 ft |
| Cargo capacity | Zero |
| Armaments | Ingram MegaBlast Pulse Laser; Seeker missiles |
| Maximum velocity | 0.32 LM |
| Inservice date | 2762 AD (Faulcon Manspace, Reorte) |
| Crew number | 1 (up to 10) |
| Hull stress factor | Varies |
| Manoeuvrability | High (CF 7.4) |
| Drive motors | de Lacy Super Thrust VC10 |
| Hyperspace capability | No |

## 7. Pilot's Log

GalCop recommends that pilots record all aspects of each journey made on the official Pilot's Log provided with this
training manual.

If you do not want to deface this manual please photocopy the Pilot's Log.

Six identical blank forms follow (pages 59-64), each with the fields:

```text
Pilot's Log
Date                            Filename
Name                            Status Combat/Legal
Planets traversed
Current equipment: purchases and prices paid
Item/Planet         Av. price   Price paid            Quantity ordered
Trading profits
Kills
Credits
SPECIAL NOTES
```

## Back cover

```text
FIREBIRD SOFTWARE  WELLINGTON HOUSE  UPPER ST MARTIN'S LANE  LONDON WC2H 9DL
Elite is a Trade Mark of Acornsoft Ltd. (c) Acornsoft 1984 (c) BT 1985 Firebird is a Trade Mark of British
Telecommunications PLC.
```
