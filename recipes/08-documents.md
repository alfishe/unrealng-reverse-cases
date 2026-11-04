# 08. Documents

**Answers:** the game's documentation, as its developers would keep it.

1. Write docs 01-10 subsystem by subsystem as the analysis and the source name things; each opens with what it
   covers and the recordings it rests on. Every number from a script; every claim with an address.
2. `kit/refdocs.py --case $C` writes doc 11 (data entries with readers and writers) and doc 12 (routines with runs,
   time, callers, callees, memory, ports, figures) from the source and the recordings.
3. `kit/code_addresses.py` puts addresses in prose into code spans; `kit/check_docs.py` checks links, images, mermaid
   and `$` in prose.
4. The WALKTHROUGH follows the work: a section per question (Asked / Used / Instead, without it / Produced), the
   tool-gap table, a section per review round.

**Done when:** `check_docs.py` says ok and every document's state in `docs/README.md` is "written".
