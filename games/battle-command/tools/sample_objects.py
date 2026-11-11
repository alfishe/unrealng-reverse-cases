"""Sample the object table ($75F0, 24 records of 60 bytes) from the unreal-ng instance that holds a recording
(kit/rs.py open --work W), one line of JSON a sample: the frame and the present records (+2 b7) with type, heading,
X, Y (24 bits, signed), height and +$31-+$33. Read with TTD memory_at at T 0 of each frame.

    python3 tools/sample_objects.py WORK FROM TO STEP OUT.jsonl
"""
import json, os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit')); import kitlib
sys.path.insert(0, os.path.join(kitlib.unreal_root(None), 'tools', 'verification', 'analysis')); import re_session
work, a, b, step, out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), sys.argv[5]
s, _ = re_session.session_of(work)
with open(out, 'w') as f:
    for fr in range(a, b + 1, step):
        r = s.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': fr, 'tinframe': 0,
                                   'offset': 0x75F0, 'length': 1440}, ok=False)
        d = bytes.fromhex((r.structured or {})['hex'])
        recs = []
        for i in range(24):
            q = d[i * 60:(i + 1) * 60]
            if not q[2] & 0x80: continue
            x = int.from_bytes(q[0x23:0x26], 'little'); y = int.from_bytes(q[0x26:0x29], 'little')
            x -= (x & 0x800000) << 1; y -= (y & 0x800000) << 1
            recs.append({'r': i, 'type': q[1], 'h': q[0x22], 'x': x, 'y': y, 'z': q[5] | q[6] << 8, 's31': q[0x31], 's32': q[0x32], 's33': q[0x33]})
        f.write(json.dumps({'frame': fr, 'recs': recs}) + '\n')
print('ok')
