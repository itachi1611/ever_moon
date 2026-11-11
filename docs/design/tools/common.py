import re
import os
DESIGN = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # docs/design
P = os.path.join(DESIGN, 'canvas-drawer') + os.sep
DARK={'#FCF8FF':'#131318','#1B1B21':'#E4E1E9','#F6F2FB':'#1B1B21','#464651':'#C7C5D3','#777683':'#918F9D','#5354AD':'#C1C1FF','#FFFFFF':'#24227C','#D5E8E6':'#D3E6E4','#E4E1E9':'#35343A','#FFF3E3':'#ECE1D1','#655D51':'#4D463A','#C7C5D3':'#464651','#3B3B94':'#E1DFFF','#AB3337':'#FFB3B0','#FFFFFE':'#680010','#EAE7EF':'#2A292F','#F0ECF5':'#1F1F25','#576967':'#566866',
      '#C62828':'#FFB4A9','#FFDAD6':'#5C1A16','#410002':'#FFDAD6'}
LINK={'Main':'ListDark','FormNew':'FormDark','DrawerOpen':'DrawerOpenDark','Settings':'SettingsDark','CalendarMonth':'CalendarMonthDark','CalendarWeek':'CalendarWeekDark','CalendarYear':'CalendarYearDark','DeleteDialog':'DeleteDialogDark','FormEdit':'FormEditDark','ListEmpty':'ListEmptyDark'}
def darken(s):
    s=re.sub(r'#[0-9A-Fa-f]{6}\b',lambda m:DARK.get(m.group(0).upper(),m.group(0)),s)
    s=re.sub(r'href="(\w+)\.dc\.html"',lambda m:'href="%s.dc.html"'%LINK.get(m.group(1),m.group(1)),s)
    s=re.sub(r'<title>(.*?)</title>',r'<title>\1 (tối)</title>',s,1)
    s=s.replace('a{color:#C1C1FF}a:hover{color:#E1DFFF}','a{color:#C1C1FF}a:hover{color:#E1DFFF}')
    return s
def e8_icon(size,uid):
    s=open(os.path.join(DESIGN, 'icon', 'evermoon-app-icon.svg')).read()
    s=re.sub(r'<(\w+)([^<>]*?)/>',r'<\1\2></\1>',s)
    s=s.replace('id="c"',f'id="{uid}"').replace('url(#c)',f'url(#{uid})')
    s=s.replace('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108">',f'<svg width="{size}" height="{size}" viewBox="18 18 72 72" aria-hidden="true" style="flex: none; border-radius: 10px">')
    return s
