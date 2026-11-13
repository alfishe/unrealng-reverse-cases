# Loader resources

Two pages of tape group 1 that are no code of a part: src/tape/tape.txt puts them on the tape, tools/mktape.py frames
them (tools/bleepload.py has the block format). Both are kept as the tape holds them.

| File | Address | What | Read by |
| --- | --- | --- | --- |
| keypage.bin | `$C900` (group 1, block 0) | The key page as the tape holds it, 256 bytes. The second stage's MakeKey (`$5D12`) XORs it in place with Rick1's two pages (`$CD00`, `$CE00`): key[i] = keypage[i] XOR Rick1[i] XOR Rick1[`$100` + i]. The key deciphers `$5D40-$5DFF` and `$CF00-$FBFF`. Bytes: their own, the source of the key (tools/bleepload.py `tape_page` makes the page back for another key or another Rick1) | MakeKey `$5D12` (src/loader/stage2.asm) |
| lastblock.bin | `$FF0E` (group 1, block 47, never stored) | The payload of group 1's last block. The second stage loads the block into the buffer `$FE00` and reads three pointers of it: `$FEE7` = `$C900` (the key page), `$FEE9` = `$CF00` (the first keyed address), `$FEEC` = `$FC` (the high byte after the last). 247 of its 256 bytes equal the second stage's page as the tape holds it (enciphered from byte `$40`): only bytes `$E6-$EE` differ, the three pointers and a `JP $AB4D`. The block's address `$FF0E` and its tail's `JP $5D94` are never used: a decoy | Stage2Start `$5D00` (src/loader/stage2.asm) |

Leftovers: lastblock.bin's 247 copied bytes are a copy of the enciphered second stage made when the tape was mastered;
they are kept as bytes, not rebuilt from src/loader/stage2.asm (no code reads them).
