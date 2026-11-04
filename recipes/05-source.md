# 05. The source

**Answers:** the game as a source that builds into the original bytes.

1. Start `src/game/game.ann` from the analysis: one line an entry (module, kind, name, title), the description,
   comments on instructions, data shapes (bytes / words per line, text, records), `@res` for resources (recipe 06),
   `@isub` for constants that only look like addresses (`LD HL,-6`, `LD SP,$FFFF`), `@equ $ADDR Name [N]` for the
   variables the game keeps past its loaded bytes (an `EQU`, and every operand that names them).
2. `python3 $K/mkgame.py --case $C --venv SKOOLKIT_VENV --sjasmplus SJASMPLUS --install` writes `src/game/*.asm`
   (one file a module, `game.asm` including them): code is every instruction start the recordings ran, widened by
   a walk along the branches no recording took; address operands inside an entry are `Label+offset`. It installs
   only when sjasmplus gives the original bytes.
3. `tools/build.sh SJASMPLUS` assembles the source, packs it with `tools/pack.py`, writes the medium and compares
   it with `orig/` (it fails on one differing bit).
4. Name every routine and data entry; describe each routine (what, inputs, outputs, side effects) in the
   annotation. A name is checked by a run (an experiment, a breakpoint hit count), not by reading alone.

**Done when:** the medium rebuilds bit for bit from `src/`, no `l_XXXX` label or bare address is left where a name
belongs, and the generated `.asm` was never edited by hand.
