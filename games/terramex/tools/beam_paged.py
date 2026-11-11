#!/usr/bin/env python3
"""kit/beam_timeline.py with the 128K pages told apart: an instruction at `$C000-$FFFF` that runs while another page
than RAM 0 is paged in (the trace's start page, then every `OUT ($7FFD)`) is named from that page's listing, with
" (RAM n)" after the name. The game's listing alone would give the music player's code in RAM 6 the names of the
RAM 0 data at the same addresses (BackTiles `$C600`).

    python3 tools/beam_paged.py --page 6=build/music.lst --page 1=build/select.lst [beam_timeline arguments]
    python3 tools/beam_paged.py --page-name "6=the music player (RAM 6)" ...    (one name for the whole page)

Every other argument goes to beam_timeline unchanged; --pc should cover `$0000-$FFFF` (the default).

    python3 tools/beam_paged.py --tool routine_anim [routine_anim arguments]

runs kit/routine_anim.py on the same paged trace instead: an instruction in another page than RAM 0 lies above
`$FFFF`, outside every --pc range, so it counts as "other" in the code panel and never shows the RAM 0 listing at its
address (the memory map still shows its accesses).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.join(HERE, '..', '..', '..', 'kit')
sys.path.insert(0, KIT)
import kitlib  # noqa: E402
import beam_timeline  # noqa: E402
import routine_anim  # noqa: E402

PAGED = 0x10000  # an instruction in another page: pc + PAGED x page


def main():
    argv, pages, names, tool = [], {}, {}, beam_timeline
    args = iter(sys.argv[1:])
    for a in args:
        if a == '--page':
            n, _, path = next(args).partition('=')
            pages[int(n)] = kitlib.Listing(path)
        elif a == '--tool':
            tool = {'beam_timeline': beam_timeline, 'routine_anim': routine_anim}[next(args)]
        elif a == '--page-name':
            n, _, name = next(args).partition('=')
            names[int(n)] = name
        else:
            argv.append(a)

    load_trace, listing = kitlib.load_trace, kitlib.listing

    def paged_trace(a):
        trace = load_trace(a)
        page = trace.pages[3] & 7 if trace.pages else 0
        for x in trace.instructions:
            if x.pc >= 0xC000 and page:
                x.pc += PAGED * page
            for c in x.cycles:
                if c.tag == 'O' and c.address & 0x8002 == 0 and c.address & 0x4000:  # $7FFD
                    page = c.value & 7
        return trace

    def paged_listing(path):
        base = listing(path)
        routine = base.routine

        def named(pc):
            if pc < PAGED:
                return routine(pc)
            n, address = pc // PAGED, pc % PAGED
            if n in names:
                return names[n]
            name = pages[n].routine(address) if n in pages else f'${address:04X}'
            return f'{name} (RAM {n})'
        base.routine = named
        return base

    kitlib.load_trace, kitlib.listing = paged_trace, paged_listing
    tool.K.load_trace, tool.K.listing = paged_trace, paged_listing
    if tool is beam_timeline and not any(a.startswith('--pc') for a in argv):
        argv += ['--pc', '0-7FFFF']
    sys.argv = [sys.argv[0]] + argv
    return tool.main()


if __name__ == '__main__':
    sys.exit(main())
