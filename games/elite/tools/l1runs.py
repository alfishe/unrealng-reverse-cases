"""entries of named routines (L1 'routines' entry points) per recording: python3 tools/l1runs.py Name..."""
import json, sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import shipsim
L = shipsim.labels()
RECS = ['d1', 'f1', 'w1', 't1', 'dk', 'k2', 'gx', 'm1', 'm2', 'cs', 'j1', 'fs']
data = {}
for r in RECS:
    d = json.load(open(os.path.join(HERE, '..', 'work', r, 'l1.json')))
    data[r] = {int(e['entry'][1:], 16): e['profile'] for e in d['routines']}
print('%-22s' % 'routine' + ''.join('%14s' % r for r in RECS))
for n in sys.argv[1:]:
    a = L.get(n)
    if a is None:
        print(n, '?'); continue
    row = []
    for r in RECS:
        p = data[r].get(a)
        row.append('%d@%d' % (p['entries'], p['first_frame']) if p else '-')
    print('%-22s' % n + ''.join('%14s' % x for x in row))
