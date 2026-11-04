"""Token use of the case: the lead session and every subagent, from the Claude Code transcripts, in a time window.

    python3 tools/case_tokens.py SESSION_DIR FROM TO OUT.json

SESSION_DIR is the session's transcript without .jsonl (its subagents/ beside it); FROM / TO are ISO UTC times.
Every model call's usage is summed: the lead's, then each agent's (named by the "Your id:" of its brief).
tools/case_cost.py draws OUT.json (WALKTHROUGH 8.1).
"""
import glob, json, os, sys, collections
ROOT, LO, HI, OUT = sys.argv[1:5]
def scan(path):
    t=collections.Counter(); first=last=None; seen=set(); ident=None
    import re
    for line in open(path):
        if ident is None:
            m0=re.search(r'Your id: (\w+)', line)
            if m0: ident=m0.group(1)
        try: d=json.loads(line)
        except Exception: continue
        ts=d.get('timestamp')
        if not ts or not (LO <= ts <= HI): continue
        m=d.get('message') or {}
        u=m.get('usage') if isinstance(m,dict) else None
        if d.get('type')=='assistant' and u:
            mid=m.get('id')
            if mid in seen: continue
            seen.add(mid)
            t['input']+=u.get('input_tokens',0); t['cache_write']+=u.get('cache_creation_input_tokens',0)
            t['cache_read']+=u.get('cache_read_input_tokens',0); t['output']+=u.get('output_tokens',0); t['calls']+=1
            first=first or ts; last=ts
    scan.ident=ident
    return t, first, last
lead,f,l=scan(ROOT+'.jsonl')
subs=collections.Counter(); n=0; rows=[]
for p in glob.glob(ROOT+'/subagents/**/*.jsonl', recursive=True)+glob.glob(ROOT+'/workflows/**/*.jsonl', recursive=True):
    t,a,b=scan(p)
    if t['calls']:
        n+=1; subs+=t; rows.append((a,b,t['output'],t['input']+t['cache_write']+t['cache_read'],scan.ident or os.path.basename(p)))
def show(name,t):
    tot_in=t['input']+t['cache_write']+t['cache_read']
    print(f"{name}: calls {t['calls']}, output {t['output']:,}, input {tot_in:,} (fresh {t['input']:,}, cache write {t['cache_write']:,}, cache read {t['cache_read']:,})")
show('lead',lead); show(f'subagents ({n})',subs); show('all',lead+subs)
print('lead window', f, l)
json.dump({'lead':lead,'subs':subs,'n':n,'rows':sorted(rows)}, open(OUT,'w'), default=str, indent=1)
