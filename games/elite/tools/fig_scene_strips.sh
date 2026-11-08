#!/bin/bash
# docs/scenes.md: each recorded scene as a strip of its own screens (tools/fig_scene_strip.py), from work/<rec>/frames
cd "$(dirname "$0")/.." || exit 1
S() { python3 tools/fig_scene_strip.py "$@"; }
O=docs/img/scenes

S $O/dk.png --title "Docking by hand and by the computer: the slot need not be level, and C docks at once with no approach flown" \
  "dk:1212:the ship stopped (SYMBOL SHIFT), the planet ahead" \
  "dk:1584:turned back (X): the station in view, lined up on its nose" \
  "dk:1704:flying in (SPACE) with the slot still tilted" \
  "dk:2220:docked at 2190: the status page" \
  "dk:3000:relaunched; C pressed in the safe zone, no station in sight" \
  "dk:3020:the docking tunnel already running"

S $O/k2.png --cols 3 --title "k2's fight in witch space: a missile locked, fired and lost to a Thargoid's E.C.M., the laser, a bomb that spares Thargoids, a Thargon and a kill" \
  "k2:2488:four Thargoids" \
  "k2:2520:a missile armed (T) and locked: its box green" \
  "k2:2544:fired (F)" \
  "k2:2574:the missile gone to the E.C.M. at 2572: three boxes" \
  "k2:2700:the military laser (A); E: our E.C.M. on" \
  "k2:3308:W: the energy bomb's flash; the Thargoids fly on" \
  "k2:3448:Thargoid 3 at energy 49 launches a Thargon" \
  "k2:3628:Thargoid 3 destroyed by the laser" \
  "k2:4248:the end: three Thargoids left"

S $O/gx.png --cols 3 --title "The galactic hyperdrive: G counts down, the ship comes out at Inoran in galaxy 2, docks with the computer and saves GALAXY2" \
  "gx:1300:G with H (1214): Galactic Hyperspace, the count at 6" \
  "gx:1868:galaxy 2: the arrival near Inoran" \
  "gx:2044:the safe zone after the in-system jump (J)" \
  "gx:2332:docked (2322): the status page, Inoran" \
  "gx:3644:the access menu: GALAXY2 typed, Commander Saved" \
  "gx:3700:the status page of GALAXY2"

S $O/m1.png --cols 3 --title "The nova: a red view on arrival, the plea at the station, the refugees aboard, the escape into galaxy 3 and the thanks" \
  "m1:2536:the 32nd jump: Atrazama, the view red, fuel 0" \
  "m1:3430:at the station: The Sun Is Going Nova! (Y)" \
  "m1:3590:the refugees in the hold" \
  "m1:5000:in flight again by the station (S): still red" \
  "m1:5768:Ceedleon in galaxy 3: the view white again" \
  "m1:9388:selling at Ceedleon: the thanks and the reward"

S $O/m2.png --cols 3 --title "The Thargoid mission: the MAYDAY on the 254th jump, the briefing at Lemaed, and Ausis, the base; the run ended before reaching it" \
  "m2:2484:the 254th jump: Lemaed" \
  "m2:2600:MAYDAY! Ausis Invaded!" \
  "m2:3230:docked: the briefing (Y)" \
  "m2:5592:Ausis, galaxy 2's first system" \
  "m2:8000:on the way to the planet, a missile armed" \
  "m2:8910:the run's end, ships about"

S $O/cs.png --cols 3 --crop 0,0,256,136 --title "The cargo scoop: the pilot brings the plate in just below the centre, and at 910 it is in the hold (Alloys)" \
  "cs:0:the start (the snapshot): the laser on the Thargoid" \
  "cs:100:50.0 Cr, its bounty; the debris ahead" \
  "cs:300:one plate passes close, above the sights" \
  "cs:900:closing on the other: at this range a dot" \
  "cs:912:scooped at 910" \
  "cs:928:the message line: Alloys"

S $O/j1.png --cols 4 --crop 190,128,66,40 --title "The joystick and the keys on the dashboard: the roll (RL) and pitch (DC) markers follow the chosen device only; B reverses the roll, Y the pitch" \
  "j1:1460:nothing pushed" \
  "j1:1500:joystick left: roll -15" \
  "j1:1570:joystick right: +15" \
  "j1:1640:joystick up: pitch +11" \
  "j1:1710:joystick down: -9" \
  "j1:1850:key N with the joystick on: ignored" \
  "j1:2090:K, the keys: N rolls left" \
  "j1:2160:M rolls right" \
  "j1:2230:X: pitch -9" \
  "j1:2300:S: pitch +9" \
  "j1:2370:joystick left with the keys on: ignored" \
  "j1:2840:B: joystick left rolls right" \
  "j1:2910:B: joystick up, pitch -9" \
  "j1:3150:B and Y: up is +9 again"

S $O/fs.png --cols 2 --title "Steering at Diso's sun: in 40000 frames it never comes near (SunNear stays 0), while ships keep coming" \
  "fs:2818:after the jump to Diso" \
  "fs:6250:the sun ahead, a small disc" \
  "fs:14750:the condition yellow: ships about" \
  "fs:39750:the end of the run, the sun out of sight"
