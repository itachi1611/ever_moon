"""Audit the drawer canvas against the design system: colors, spacing, type, corners, links."""
import re,glob,json,os
import os
DESIGN = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # docs/design
P = os.path.join(DESIGN, 'canvas-drawer') + os.sep
T=json.load(open(os.path.join(DESIGN, 'design-system', 'tokens.json')))
toks={}
for x in T['color']['tokens']:
    for th,v in x['value'].items():
        if v.startswith('#'): toks.setdefault(v.upper(),set()).add(x['name'])
# Theme Builder roles used through ColorScheme but not listed as tokens
EXTRA={'#3B3B94':'onPrimaryFixedVariant (link hover only)','#E1DFFF':'primaryFixed (link hover only)','#D0C5B6':'tertiaryFixedDim (E8 icon)','#ECE1D1':'tertiaryFixed (E8 icon)'}
ARCH={'DrawerB','DrawerBDark','DrawerC','DrawerCDark'}
FS={11,12,14,16,22,24,28,36,45,57}  # M3 scale (+72 hero numeral)
issues=[]; boards=json.load(open(P+'canvas.json'))['boards']
for f in sorted(glob.glob(P+'*.dc.html')):
    n=os.path.basename(f)[:-8]
    if n in ARCH: continue
    s=open(f).read(); body=re.sub(r'<svg.*?</svg>','',s,flags=re.S)
    for c in sorted(set(x.upper() for x in re.findall(r'#[0-9A-Fa-f]{6}\b',body))):
        if c not in toks and c not in EXTRA: issues.append((n,'color',c))
    for m in re.finditer(r'(?:padding|margin|gap|row-gap|column-gap)(?:-\w+)?\s*:\s*([^;"\'{}]+)',body):
        for v in re.findall(r'(?<![-\d.])(\d+)px',m.group(1)):
            if int(v)%4: issues.append((n,'spacing',m.group(0)))
    for v in re.findall(r'font-size:\s*(\d+)px',body):
        if int(v) not in FS|{72,20}: issues.append((n,'font-size',v))
    for v in re.findall(r'border-radius:\s*(\d+)px',body):
        if int(v) not in {0,2,3,4,5,8,12,16,20,24,28,48,56,80,160,999} : issues.append((n,'radius',v))
    for h in re.findall(r'href="([\w]+\.dc\.html)"',s):
        if h not in boards: issues.append((n,'link',h))
    if n+'.dc.html' not in boards: issues.append((n,'board','not in canvas.json'))
for i in issues: print(*i)
print('issues:',len(issues))
