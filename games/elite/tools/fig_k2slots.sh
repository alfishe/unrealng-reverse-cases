#!/bin/bash
# docs/img/objects/fight-slots.gif from work/k2/slots and work/k2/frames (tools/grab_k2slots.sh)
cd "$(dirname "$0")/.."
python3 tools/fig_slots_anim.py k2 2484 4244 8 docs/img/objects/fight-slots.gif \
  --title "k2's fight in the slots: four Thargoids, our missile, a kill, a Thargon and the debris" \
  --event "2484:witch space: four Thargoids (energy 240) in slots 1-4" \
  --event "2544:F: our missile launched into slot 7" \
  --event "2572:a Thargoid's E.C.M.: the missile explodes (slot 7 freed at 2612)" \
  --event "2616:slot 7 free; the Thargoids close in" \
  --event "2700:the military laser (A) on Thargoid 3: its energy falls" \
  --event "3300:W: the energy bomb; the Thargoids are spared" \
  --event "3412:Thargoid 3 launches a Thargon (slot 5)" \
  --event "3624:Thargoid 3 destroyed by the laser: it explodes, a plate in slot 6" \
  --event "3776:the Thargon destroyed; then three Thargoids and the plate"
