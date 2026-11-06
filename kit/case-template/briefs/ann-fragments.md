# <Case>: annotation brief (shared by all region agents)

R = the repository, C = R/games/<case>. Goal: a real reverse of the addresses in your range. Every routine and data
block gets a meaningful PascalCase name, a title, a description (what it does, inputs in registers and memory,
outputs, side effects, callers), comments on the key instructions, labels for the inner points (loops, branches);
data blocks get their real shape (records, tables, rows of N, text). Bar: R/games/<base>/src/game/game.ann (read
150 lines of it first).

## Read first

- C/src/game/*.asm: the current mechanical cut (labels with the address in them).
- C/src/game/game.ann: the annotations so far (do NOT edit it). Format: R/docs/ann-format.md.
- C/work/mkgame/game.ctl: entry kinds per address as the recordings decided.
- C/WALKTHROUGH.md and the case's bot: the known variables, records, menus.

## Known facts (verified)

The lead lists here what is proved: the interrupt set-up, the main tables and records with their fields, the named
variables and routines with their addresses.

## Evidence

- C/work/<build>/l1.json: the analysis of each recording (routines, call counts, blocks).
- A live instance holding the recording may be shared READ ONLY (MCP at its port; `time_travel memory_at`): never
  seek, resume or modify it.
- For experiments (breakpoints, pokes) start YOUR OWN instance at your port base, muted; stop only that pid.

## Output (write only these two files)

1. C/work/ann/<you>.ann: `.ann` lines for addresses in your range only: `$ADDR c Name ; title` at code entry starts
   (only where game.ctl has an entry or a call target), `> description` lines, `$ADDR Name ; comment` for inner
   labels and comments (instruction starts only), `$ADDR b Name N ; title` for data (`b` bytes N a row, `w` words,
   `t` text). Do not repeat entries already in game.ann (improved titles go to your notes). No `@module`, `@equ`,
   `@res`, `@isub`: the lead adds them in the merge. A name needs evidence (code reading plus a recording or an
   experiment); if unsure, say so in the description.
2. C/work/ann/<you>.md: findings for the documents (mechanics, formats, tables, algorithms, timings) with addresses,
   plus the variables past the image you identified (address, name, size, meaning) for `@equ`.

No commits. Report: counts, the key mechanics,
the open questions.
