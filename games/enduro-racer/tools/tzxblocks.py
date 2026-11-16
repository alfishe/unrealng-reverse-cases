#!/usr/bin/env python3
"""The blocks of a TZX file: list them with their timings, or write the data of one (kit/tapblocks.py's TZX walk,
under the names the case's tools import).

    python3 tzxblocks.py list FILE.tzx            # every block: id, timings, length, flag, checksum, header fields
    python3 tzxblocks.py FILE.tzx INDEX OUT.bin   # the data of block INDEX (flag and checksum included)

The same as `python3 ../../kit/tapblocks.py list FILE.tzx` / `tapblocks.py FILE.tzx INDEX OUT.bin`.
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import tapblocks  # noqa: E402

KINDS, STD = tapblocks.KINDS, tapblocks.STD
parse = tapblocks.parse_tzx
seconds = tapblocks.tzx_seconds
describe = tapblocks.tzx_describe

if __name__ == '__main__':
    sys.exit(tapblocks.main())
