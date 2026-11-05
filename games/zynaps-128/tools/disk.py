#!/usr/bin/env python3
"""TR-DOS media of Zynaps 2 in 1: list an SCL or a TRD, extract its files, compare the two.

  disk.py list IMAGE                 the catalogue: name, type, start, length, sectors, position, md5
  disk.py extract IMAGE OUTDIR       every file's data (its sectors, padded to 256) and its exact length
  disk.py compare SCL TRD            file by file: same bytes or the differences; the TRD's system sector and
                                     the sectors no file holds
"""
import hashlib
import struct
import sys
from pathlib import Path


def read_scl(data):
    if data[:8] != b"SINCLAIR":
        raise SystemExit("not an SCL")
    n = data[8]
    files, pos = [], 9 + 14 * n
    for i in range(n):
        e = data[9 + 14 * i: 9 + 14 * (i + 1)]
        secs = e[13]
        body = data[pos: pos + 256 * secs]
        files.append(entry(e, body, None, None))
        pos += 256 * secs
    tail = data[pos:]
    s = sum(data[:pos]) & 0xFFFFFFFF
    stored = struct.unpack("<I", tail[:4])[0] if len(tail) >= 4 else None
    return files, {"checksum": stored, "computed": s, "extra": len(tail) - 4}


def read_trd(data):
    files = []
    for i in range(128):
        e = data[16 * i: 16 * (i + 1)]
        if e[0] == 0:
            break
        if e[0] == 1:
            files.append(entry(e, b"", e[15], e[14], deleted=True))
            continue
        secs, sec, trk = e[13], e[14], e[15]
        off = (trk * 16 + sec) * 256
        files.append(entry(e, data[off: off + 256 * secs], trk, sec))
    sys9 = data[8 * 256: 9 * 256]
    info = {
        "first_free": (sys9[0xE2], sys9[0xE1]),
        "disk_type": sys9[0xE3],
        "files": sys9[0xE4],
        "free": struct.unpack("<H", sys9[0xE5:0xE7])[0],
        "id": sys9[0xE7],
        "deleted": sys9[0xF4],
        "label": sys9[0xF5:0xFD].decode("latin-1"),
    }
    return files, info


def entry(e, body, trk, sec, deleted=False):
    name = e[0:8].decode("latin-1")
    typ = chr(e[8])
    start, length = struct.unpack("<HH", e[9:13])
    return {"name": name, "type": typ, "start": start, "length": length, "secs": e[13],
            "trk": trk, "sec": sec, "body": body, "raw": bytes(e[:14]), "deleted": deleted}


def load(path):
    data = Path(path).read_bytes()
    return (read_scl(data) if data[:8] == b"SINCLAIR" else read_trd(data)), data


def cmd_list(path):
    (files, info), data = load(path)
    print(f"{path}: {len(data)} bytes, md5 {hashlib.md5(data).hexdigest()}")
    print(info)
    print("name     t  start  length secs  trk:sec  md5(sectors)")
    for f in files:
        pos = f"{f['trk']:3}:{f['sec']:<2}" if f["trk"] is not None else "   -  "
        print(f"{f['name']} {f['type']}  {f['start']:5} {f['length']:6} {f['secs']:4}  {pos}  "
              f"{hashlib.md5(f['body']).hexdigest()}{'  (deleted)' if f['deleted'] else ''}")


def cmd_extract(path, out):
    (files, _), _ = load(path)
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    for i, f in enumerate(files):
        stem = f"{i:02}_{f['name'].rstrip()}.{f['type']}"
        (out / stem).write_bytes(f["body"])
    print(f"{len(files)} files into {out}")


def cmd_compare(scl, trd):
    (sf, sinfo), _ = load(scl)
    (tf, tinfo), tdata = load(trd)
    print("SCL", sinfo)
    print("TRD", tinfo)
    for a, b in zip(sf, tf):
        same_hdr = a["raw"] == b["raw"]
        same = a["body"] == b["body"]
        diffs = [i for i in range(min(len(a["body"]), len(b["body"]))) if a["body"][i] != b["body"][i]]
        print(f"{a['name']}.{a['type']} vs {b['name']}.{b['type']}: header {'same' if same_hdr else 'DIFF'}, "
              f"body {'same' if same else f'{len(diffs)} bytes differ, first {diffs[:8]}'}")
    if len(sf) != len(tf):
        print(f"file count differs: SCL {len(sf)} TRD {len(tf)}")
    # sectors of the TRD that no file holds, beyond track 0
    used = set()
    for f in tf:
        if f["trk"] is None:
            continue
        s0 = f["trk"] * 16 + f["sec"]
        used.update(range(s0, s0 + f["secs"]))
    nz = [s for s in range(16, len(tdata) // 256) if s not in used and any(tdata[s * 256:(s + 1) * 256])]
    print(f"TRD sectors outside files with data: {len(nz)}", nz[:20])
    t0 = [s for s in range(9, 16) if any(tdata[s * 256:(s + 1) * 256])]
    print("TRD track 0 sectors 9-15 non-zero:", t0)
    print("TRD system sector 8 bytes 0-0xE0 non-zero:", any(tdata[8 * 256: 8 * 256 + 0xE1]))


if __name__ == "__main__":
    a = sys.argv[1:]
    if a[:1] == ["list"]:
        cmd_list(a[1])
    elif a[:1] == ["extract"]:
        cmd_extract(a[1], a[2])
    elif a[:1] == ["compare"]:
        cmd_compare(a[1], a[2])
    else:
        print(__doc__)
