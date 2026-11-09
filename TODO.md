# TODO

The owner's plan for this repository: the games to reverse, in order, and the ports planned from them. How a case is
done is in [AGENTS.md](AGENTS.md); this file says only what is next.

## The reverse queue

| # | Game | Notes |
| --- | --- | --- |
| 1 | OCP Video Pool | next; a port to the UKNC is planned (below), so the case gets doc 14 |
| 2 | Chuckie Egg | |
| 3 | Tujad | |
| 4 | SimCity | |
| 5 | Earth Shaker | our own reverse; Bedazzle's disassembly (github.com/Bedazzle/Earth-shaker) is not a source of names, compare with it at the end at most |
| 6 | Battle Command | ZXDB 451 |

## Planned ports

| Game | Target | Document |
| --- | --- | --- |
| OCP Video Pool | UKNC; possibly BK-0010 / BK-0011M and Soyuz-Neon | `games/<case>/docs/14-porting-to-uknc.md` |

The porting document follows AGENTS.md section 4.0 "By port target". What it must address for each target (the machine facts here are leads from memory; the document checks each one against the machine's documentation or an emulator before it relies on it):

| Target | What the document must address |
| --- | --- |
| UKNC (Elektronika MS-0511) | the PDP-11 central CPU (K1801VM2) and the peripheral CPU that owns the video and sound; the three-plane video memory in the peripheral CPU's space, written through its ports or by a peripheral-CPU program; the channels between the two CPUs; which work runs on which CPU, and how they sync per frame |
| BK-0010 / BK-0011M | the K1801VM1 at 3-4 MHz, no multiply; the 256x256 two-bit or 512x256 one-bit screen in main memory; the 32K or paged 128K budget; the beeper or AY add-on; the timer |
| Soyuz-Neon (PK-11/16) | the K1801VM3 class CPU with multiply and the larger memory; its video modes and palette; what of the BK or UKNC plan carries over |
