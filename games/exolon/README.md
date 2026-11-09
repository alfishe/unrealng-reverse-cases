# Exolon (Hewson Consultants, 1987)

State: complete 2026-11-08: the tape rebuilt bit for bit from the annotated source, the resources and the full map in `src/res`, docs 01-12 (57 mermaid diagrams, 97 figures, 29 MP3), a completeness pass against AGENTS.md and two review rounds (47 and 33 findings) worked.

| | |
| --- | --- |
| Machine | 48K (the tape is labelled for 48K and 128K; the 128K branch is to be checked in the recordings) |
| Authors | Raffaele Cecco (the TZX archive-info block); the music credited to Nick Jones (the zxart.ee AY rips) |
| Original | `orig/Exolon.tzx.zip` (md5 `80d59b4442bdccd02c33b29e9f766a82`, SHA-1 `c8fe331be127e38ab9e8052ad31ff4d80fa9d588`): `Exolon.tzx` (md5 `7ba525e945808b0031f479dfb6fb2fd5`, SHA-1 `8947961a2a7ea27461e6dd1366ee464059d2090f`), the "perfect TZX" sampled from the original cassette by Church of the Latter-Day Speccy |
| Also kept | `orig/Exolon.tap.zip` (md5 `bde53a57755c79d4ee21fe459ffc3ae6`, SHA-1 `64c38d3ac7ea2220a7d7f5ffc3c5cb52c648638e`): `EXOLON.TAP` (md5 `abded3d09e3625073bd1a42a394c017a`, SHA-1 `35abadc49b8fd1aed54036445ae2563a3356280f`), a modified copy: the loader stored already decrypted, a new BASIC that skips the decryption and patches the loader (docs/03-build-and-load.md 3.1) |

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```bash
tools/build.sh [SJASMPLUS]     # builds build/Exolon.tzx and compares it with orig/ byte for byte
```

The game source is `src/game/*.asm`, written by `kit/mkgame.py` from `src/game/game.ann`; the resources are
`src/res/` (`src/res/README.md`).
