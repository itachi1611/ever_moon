"""Bring the drawer canvas artboards in line with the Evermoon design system (M3 values)."""
import re, glob, os
import os
DESIGN = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # docs/design
P = os.path.join(DESIGN, 'canvas-drawer') + os.sep
ARCHIVE={'DrawerB','DrawerBDark','DrawerC','DrawerCDark'}
SPACING_PROPS=r'(?:padding|margin|gap|row-gap|column-gap)(?:-(?:left|right|top|bottom))?'
SPACE_MAP={2:4,3:4,6:8,10:12,14:16,18:16,20:16,22:24,28:24,26:24}
def fix_spacing(s):
    def val(m):
        prop,v=m.group(1),m.group(2)
        def num(n):
            x=int(n.group(1)); neg=n.group(0).startswith('-')
            if neg: return n.group(0)
            return f'{SPACE_MAP.get(x,x)}px'
        return f'{prop}: '+re.sub(r'-?(\d+)px',num,v)
    return re.sub(rf'({SPACING_PROPS})\s*:\s*([^;"\'{{}}]+)',val,s)
def recolor_block(s, start_pat, fn):
    """Apply fn to every element whose opening tag matches start_pat, through its closing tag."""
    out=[]; i=0
    for m in re.finditer(start_pat,s):
        if m.start()<i: continue
        tag=re.match(r'<(\w+)',s[m.start():]).group(1)
        depth=0; j=m.start()
        for t in re.finditer(rf'<(/?){tag}\b[^>]*>',s[m.start():]):
            depth+= -1 if t.group(1) else 1
            if depth==0: j=m.start()+t.end(); break
        out.append(s[i:m.start()]); out.append(fn(s[m.start():j])); i=j
    out.append(s[i:]); return ''.join(out)
def today_text(block):
    # Text on today-container uses the tertiary "fixed" pair so it reads in both themes.
    block=block.replace('#655D51','#4D463A')
    block=re.sub(r'(background: #(?:FFF3E3|ECE1D1);)(?![^"]*color:)',r'\1 color: #201B11;',block,1)
    block=re.sub(r'; border: 1(?:\.5)?px solid #D0C5B6','',block)
    return block
def normalize(name,s):
    dark=name.endswith('Dark')
    # Colors that are not design-system tokens
    s=s.replace('#0D1E1E','#566866' if dark else '#576967')
    s=s.replace('#46464F','#464651').replace('#FFFFFE','#FFFFFF')
    if dark: s=s.replace('#FFB4AB','#FFB3B0').replace('#690005','#680010')
    s=recolor_block(s,r'<(?:article|div|section)[^>]*background: #(?:FFF3E3|ECE1D1)',today_text)
    # Settings dividers use outline-variant
    s=s.replace("divider: '#E4E1E9'","divider: '#C7C5D3'").replace("divider: '#35343A'","divider: '#464651'")
    # Spacing on the M3 4 dp grid; screen margin 16
    s=fix_spacing(s)
    # Type scale: 13 -> label/body small 12/16, 18 -> title medium 16/24
    s=s.replace('font-size: 13px; line-height: 18px','font-size: 12px; line-height: 16px').replace('font-size: 13px','font-size: 12px')
    s=s.replace('font-size: 18px; line-height: 24px','font-size: 16px; line-height: 24px')
    # Shape: M3 corner scale only
    s=s.replace('border-radius: 14px','border-radius: 12px')
    s=s.replace('grid-auto-rows: 106px','grid-auto-rows: 104px')
    # Date badge token 56 x 64
    s=s.replace('width: 60px; height: 64px','width: 56px; height: 64px')
    # Field-like pickers use the text-field corner (extra small)
    s=s.replace('border: 1px solid #777683; border-radius: 12px; background: #F6F2FB','border: 1px solid #777683; border-radius: 4px; background: #F6F2FB')
    s=s.replace('border: 1px solid #918F9D; border-radius: 12px; background: #1B1B21','border: 1px solid #918F9D; border-radius: 4px; background: #1B1B21')
    s=s.replace('border: 1px solid #777683; border-radius: 12px; background: #FCF8FF','border: 1px solid #777683; border-radius: 4px; background: #FCF8FF')
    s=s.replace('border: 1px solid #918F9D; border-radius: 12px; background: #131318','border: 1px solid #918F9D; border-radius: 4px; background: #131318')
    # Confirm dialog: M3 text buttons, Xoá in error color
    s=re.sub(r'(">Xoá</(?:button|a)>)',r'\1',s)
    s=re.sub(r'style="height: 48px; padding: 0 24px; border: 0; border-radius: 24px; background: (#AB3337|#FFB3B0); color: (?:#FFFFFF|#680010);',r'style="height: 48px; padding: 0 12px; border: 0; border-radius: 24px; background: transparent; color: \1;',s)
    s=re.sub(r'style="height: 48px; padding: 0 24px; border-radius: 24px; background: (#AB3337|#FFB3B0); color: (?:#FFFFFF|#680010);',r'style="height: 48px; padding: 0 12px; border-radius: 24px; background: transparent; color: \1;',s)
    s=s.replace('style="height: 48px; padding: 0 20px; border: 0; border-radius: 24px; background: transparent;','style="height: 48px; padding: 0 12px; border: 0; border-radius: 24px; background: transparent;')
    s=s.replace('style="height: 48px; padding: 0 16px; border: 0; border-radius: 24px; background: transparent;','style="height: 48px; padding: 0 12px; border: 0; border-radius: 24px; background: transparent;')
    # Empty state: 96 dp disc, headline-medium title
    s=s.replace('width: 112px; height: 112px; border-radius: 56px;','width: 96px; height: 96px; border-radius: 48px;').replace('<svg width="56" height="56" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.4"','<svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"')
    s=s.replace('font-family: Lora, Georgia, serif; font-size: 22px; line-height: 28px; font-weight: 400">Chưa có ngày giỗ nào','font-family: Lora, Georgia, serif; font-size: 28px; line-height: 36px; font-weight: 400">Chưa có ngày giỗ nào')
    # View switch = the same M3 outlined segmented button as Settings
    s=s.replace('role="tablist" aria-label="Kiểu xem" style="display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); padding: 4px; border-radius: 12px; background: #E4E1E9"',
                'role="tablist" aria-label="Kiểu xem" style="display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); border: 1px solid #777683; border-radius: 20px; overflow: hidden"')
    s=s.replace('role="tablist" aria-label="Kiểu xem" style="display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); padding: 4px; border-radius: 12px; background: #35343A"',
                'role="tablist" aria-label="Kiểu xem" style="display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); border: 1px solid #918F9D; border-radius: 20px; overflow: hidden"')
    def seg(m):
        st=m.group(2).replace('border-radius: 999px; ','border-radius: 0; ').replace('font-size: 16px','font-size: 14px')
        if m.group(3)!='Tuần': st=st.replace('border: 0;','border: 0; border-right: 1px solid '+('#918F9D' if dark else '#777683')+';')
        return m.group(1)+st+m.group(4)
    s=re.sub(r'(<a href="Calendar\w+\.dc\.html" role="tab" aria-selected="\w+" style=")([^"]*)(?=">(Năm|Tháng|Tuần)</a>)(")',lambda m: m.group(1)+seg2(m.group(2),m.group(3),dark)+m.group(4),s)
    return s
def seg2(st,label,dark):
    st=st.replace('border-radius: 999px; ','border-radius: 0; ').replace('font-size: 16px','font-size: 14px')
    if label!='Tuần' and 'border-right' not in st: st=st.replace('border: 0;','border: 0; border-right: 1px solid '+('#918F9D' if dark else '#777683')+';')
    return st
if __name__=='__main__':
    for f in sorted(glob.glob(P+'*.dc.html')):
        n=os.path.basename(f)[:-8]
        if n in ARCHIVE: continue
        s=open(f).read(); t=normalize(n,s)
        if t!=s: open(f,'w').write(t); print('updated',n)
