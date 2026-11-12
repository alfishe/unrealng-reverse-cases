# Variant zyxlgbt

From `work/candidates/owner-boots_zyx/zyxlgbt.trd`, file `boot` (B, start 376, length 357, 2 sectors). Built by `tools/build.sh --variant zyxlgbt`: **identical**.

- Its loader (`basic.txt`, the BASIC as text, `tools/res_basic.py`) reads 2 sectors of BASIC, then: `$61A8` x 15, `$A600` x 8, `$C0B7` x 24.
- The music piece at `$C0B7`, 24 sectors, init `$C0B7`; play `$C0BD`.
- Code of its own, described in `parts/loader.ann` (built by kit/mkgame.py from `parts/loader.json`, placed at `$9C40`).
- Code of its own, described in `parts/stage2.ann` (built by kit/mkgame.py from `parts/stage2.json`, placed at `$FDE8`).
- Files that differ from the original: `basic.txt`, `files/stale.bin`, `graphics/logo.png`, `graphics/rhombus.png`, `music/player.txt`, `music/stc.txt`, `tables/logo-attrs.txt`.
- The Lotus Group boot, a whole TRD (`trd` in variant.json, built by tools/lotus.py): its catalogue (the boot, then a stale 16-byte entry `ROT4+` after the end mark), the information sector, the boot file at track 0 sector 9, and the sectors the loader reads by track and sector: stage 2 (track 5 sector 0, `$FDE8`), the menu code (`$61A8` x 15), its graphics (`$A600` x 8) and the music (`$C0B7` x 24). The menu is the ZYX menu's code, layout A, with the stack at `$BF68`; its logo, logo colours and rhombus are Lotus Group's.
- The cipher: two layers decrypt themselves with the refresh register R (set once by LD R,A, stepped by every fetch). The loader (`parts/loader.ann`, copied by line 1's REM from `$5D84` to `$9C40`) XORs each byte of `$9C7D-$A07C` with R (from 2), IX, SP (`$404C`) and DE (the count); its first byte decrypted is its own JR NZ's offset. Stage 2 (`parts/stage2.ann`) does the same over `$FE02-$FF01` with R from `$DE`, HL and DE. The sources hold the plain code; the build encrypts it by running each loop in SkoolKit's simulator in lockstep (`basic.txt` has `fill 256` where the encrypted loader goes).
- The protection: the loader reads track 0 raw (the controller's Read Track) and needs three equal bytes of the last gap from the track's offset `$1783` on; the byte found (`$4E` on a standard format) becomes the R start that stage 2 decrypts the chosen program with (XOR R and the first letter of its name). The programs of a Lotus disk are encrypted; this disk holds only the boot.
- The tune: "E.S.I." by Ziutek (compiled Sound Tracker, init `$C0B7`, play `$C0BD`; the music index matches its AY stream exactly), as zyxarbt and zyxrusbt; `music/stc.txt`.
- `files/stale.bin`: track 0 sectors 15 to track 4 sector 15, the bytes a deleted file left (the stale catalogue entry `ROT4+` points at track 1), kept as they are; the decoy read of track 0 sectors 12-15 lands in them.
