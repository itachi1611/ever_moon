"""Flow: Mở app — animated splash, three image-led intro screens, short permission screen."""
import re
from common import *
import normalize
HEAD='''<!doctype html>
<html lang="vi">
<head>
<meta charset="utf-8">
<title>%TITLE%</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700&amp;family=Lora:wght@400;500;600;700&amp;display=swap" rel="stylesheet">
<style>
body{margin:0}
a{color:#5354AD}a:hover{color:#3B3B94}
</style>
</helmet>
'''
def tail(js_body, init='{}'):
    return '''
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"$preview":{"width":390,"height":844}}'>
class Component extends DCLogic {
  constructor(props) {
    super(props);
    this.state = %INIT%;
  }
%BODY%
}
</script>
</body>
</html>
'''.replace('%INIT%',init).replace('%BODY%',js_body)
ROOT='<div style="width: 390px; height: 844px; box-sizing: border-box; position: relative; display: flex; flex-direction: column; background: #FCF8FF; color: #1B1B21; font-family: \'Be Vietnam Pro\', system-ui, sans-serif; overflow: hidden">'
LINK.update({'Splash':'SplashDark','Intro1':'Intro1Dark','Intro2':'Intro2Dark','Intro3':'Intro3Dark','IntroNotify':'IntroNotifyDark'})
ANIM='''
@keyframes evmPop{0%{transform:scale(.6);opacity:0}22%{transform:scale(1.04);opacity:1}32%{transform:scale(1)}100%{transform:scale(1);opacity:1}}
@keyframes evmMoon{0%,14%{opacity:0;transform:rotate(-120deg) scale(.3)}36%{opacity:1;transform:rotate(0) scale(1.15)}44%,100%{opacity:1;transform:none}}
.evm-icon{animation:evmPop 2.6s cubic-bezier(.2,0,0,1) infinite}
.evm-moon{transform-box:fill-box;transform-origin:center;animation:evmMoon 2.6s cubic-bezier(.2,0,0,1) infinite}
@media (prefers-reduced-motion: reduce){.evm-icon,.evm-moon{animation:none}}
'''
def splash_icon(uid):
    s=e8_icon(160,uid).replace('border-radius: 10px','border-radius: 50%')
    s=s.replace('<svg ','<svg class="evm-icon" ',1)
    s=s.replace('fill="#5354AD"></path>','fill="#5354AD" class="evm-moon"></path>')
    return s
SPLASH=HEAD.replace('%TITLE%','Màn khởi động').replace('</style>',ANIM+'</style>')+ROOT+'''
  <a href="Intro1.dc.html" aria-label="Evermoon đang mở" style="flex: 1; display: flex; align-items: center; justify-content: center; text-decoration: none">
    %%ICON%%
  </a>
</div>'''+tail('''  renderVals() {
    return {};
  }''')
RING='<span style="position: absolute; top: -8px; width: 8px; height: 20px; border-radius: 4px; background: #FFF3E3; border: 2px solid #3B3B94; left: %dpx"></span>'
BELL='<svg width="72" height="72" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M6 16V11a6 6 0 0 1 12 0v5l2 2H4z"></path><path d="M10 20a2 2 0 0 0 4 0"></path></svg>'
MOON='<svg width="%d" height="%d" viewBox="0 0 24 24" aria-hidden="true"><path d="M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z" fill="%s"></path></svg>'
ILL1=f'''<div aria-hidden="true" style="position: relative; width: 220px; height: 260px">
        <div style="position: absolute; left: 28px; top: 20px; width: 190px; height: 230px; border-radius: 16px; background: #E4E1E9; transform: rotate(6deg)"></div>
        <div style="position: absolute; left: 8px; top: 12px; width: 190px; height: 230px; border-radius: 16px; overflow: visible; background: #FFF3E3; box-shadow: 0px 1px 3px 0px rgba(0, 0, 0, 0.3), 0px 4px 8px 3px rgba(0, 0, 0, 0.15); display: flex; flex-direction: column">
          <div style="position: relative; height: 48px; border-radius: 16px 16px 0 0; background: #5354AD; display: flex; align-items: center; justify-content: center; color: #FFFFFF; font-size: 14px; font-weight: 600">{RING%44}{RING%138}Âm lịch</div>
          <div style="flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; color: #201B11">
            <span style="font-family: Lora, Georgia, serif; font-size: 72px; line-height: 80px">27</span>
            <span style="font-size: 16px; line-height: 24px; color: #4D463A">tháng 9</span>
          </div>
          <span style="position: absolute; right: 16px; top: 64px">{MOON%(28,28,'#5354AD')}</span>
        </div>
        <span style="position: absolute; left: -8px; bottom: 0; height: 32px; padding: 0 16px; border-radius: 16px; background: #D5E8E6; color: #576967; font-size: 14px; font-weight: 600; display: flex; align-items: center">Ông nội</span>
      </div>'''
ILL2=f'''<div aria-hidden="true" style="position: relative; width: 280px; height: 260px; display: flex; flex-direction: column; align-items: center">
        <div style="width: 160px; height: 160px; border-radius: 80px; background: #E4E1E9; color: #5354AD; display: flex; align-items: center; justify-content: center">{BELL}</div>
        <div style="position: absolute; left: 0; right: 0; top: 128px; padding: 12px 16px; border-radius: 16px; background: #FCF8FF; box-shadow: 0px 1px 3px 0px rgba(0, 0, 0, 0.3), 0px 4px 8px 3px rgba(0, 0, 0, 0.15); display: flex; gap: 12px; align-items: center">
          %%ICON_SMALL%%
          <div style="display: flex; flex-direction: column"><span style="font-size: 16px; line-height: 24px; font-weight: 600">Mai giỗ Bà nội</span><span style="font-size: 12px; line-height: 16px; color: #464651">Evermoon · 07:00</span></div>
        </div>
        <div style="position: absolute; bottom: 0; display: flex; gap: 8px">
          <span style="height: 32px; padding: 0 12px; border-radius: 8px; background: #D5E8E6; color: #576967; font-size: 14px; font-weight: 600; display: flex; align-items: center">1 ngày</span>
          <span style="height: 32px; padding: 0 12px; border-radius: 8px; border: 1px solid #777683; color: #464651; font-size: 14px; display: flex; align-items: center">3 ngày</span>
          <span style="height: 32px; padding: 0 12px; border-radius: 8px; border: 1px solid #777683; color: #464651; font-size: 14px; display: flex; align-items: center">7 ngày</span>
        </div>
      </div>'''
ILL3='''<div aria-hidden="true" style="width: 280px; padding: 16px; box-sizing: border-box; border-radius: 16px; background: #FCF8FF; box-shadow: 0px 1px 3px 0px rgba(0, 0, 0, 0.3), 0px 4px 8px 3px rgba(0, 0, 0, 0.15); display: flex; flex-direction: column; gap: 8px">
        <div style="display: grid; grid-template-columns: repeat(7, minmax(0, 1fr)); row-gap: 4px">
          <sc-for list="{{cells}}" as="c" hint-placeholder-count="35">
            <div style="height: 40px; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 4px">
              <span style="{{c.numStyle}}">{{c.n}}</span>
              <span style="{{c.dot}}"></span>
            </div>
          </sc-for>
        </div>
        <div style="display: flex; justify-content: center; gap: 16px; font-size: 12px; line-height: 16px; color: #464651">
          <span style="display: flex; align-items: center; gap: 8px"><span style="width: 8px; height: 8px; border-radius: 4px; background: #5354AD"></span>Giỗ</span>
          <span style="display: flex; align-items: center; gap: 8px"><span style="width: 8px; height: 8px; border-radius: 4px; background: #C62828"></span>Lễ</span>
        </div>
      </div>'''
CELLS_JS='''  renderVals() {
    const marks = { 6: 'a', 10: 'h', 18: 'a', 24: 'h' };
    const cells = [];
    for (let i = 1; i <= 35; i++) {
      const d = i <= 30 ? i : 0;
      const m = marks[d];
      cells.push({
        n: d ? String(d) : '',
        numStyle: 'font-size: 12px; line-height: 16px; font-weight: ' + (m ? '700' : '400') + '; color: ' + (m === 'h' ? '#C62828' : (m === 'a' ? '#5354AD' : '#464651')),
        dot: 'width: 6px; height: 6px; border-radius: 3px; background: ' + (m === 'a' ? '#5354AD' : (m === 'h' ? '#C62828' : 'transparent'))
      });
    }
    return { cells };
  }'''
EMPTY_JS='''  renderVals() {
    return {};
  }'''
SCREENS=[('Intro1',ILL1,'Ngày giỗ theo âm lịch','Chỉ cần ngày và tháng âm.','Intro2.dc.html','Tiếp tục',EMPTY_JS),
         ('Intro2',ILL2,'Nhắc đúng lúc','Trước 1, 3 hoặc 7 ngày.','Intro3.dc.html','Tiếp tục',EMPTY_JS),
         ('Intro3',ILL3,'Rằm, mùng 1, lễ Tết','Đánh dấu sẵn trên lịch.','IntroNotify.dc.html','Bắt đầu',CELLS_JS)]
def dots(i):
    return ''.join(f'<span style="height: 8px; border-radius: 4px; width: {24 if k==i else 8}px; background: {"#5354AD" if k==i else "#C7C5D3"}"></span>' for k in range(3))
def intro(i,ill,title,line,nxt,cta):
    return HEAD.replace('%TITLE%',f'Giới thiệu {i+1}/3')+ROOT+f'''
  <header style="height: 64px; flex: none; padding: 0 4px 0 16px; display: flex; align-items: center; justify-content: flex-end">
    <a href="IntroNotify.dc.html" style="height: 48px; padding: 0 12px; border-radius: 24px; color: #5354AD; text-decoration: none; font-size: 14px; font-weight: 600; display: flex; align-items: center">Bỏ qua</a>
  </header>
  <main style="flex: 1; min-height: 0; padding: 0 24px; display: flex; flex-direction: column; align-items: center">
    <div style="flex: 1; width: 100%; display: flex; align-items: center; justify-content: center">
      <div style="width: 320px; height: 320px; border-radius: 160px; background: #F6F2FB; display: flex; align-items: center; justify-content: center">
      {ill}
      </div>
    </div>
    <div style="padding: 24px 0 8px; display: flex; flex-direction: column; align-items: center; gap: 8px; text-align: center">
      <h1 style="margin: 0; font-family: Lora, Georgia, serif; font-size: 28px; line-height: 36px; font-weight: 400">{title}</h1>
      <p style="margin: 0; font-size: 16px; line-height: 24px; color: #464651">{line}</p>
    </div>
  </main>
  <footer style="flex: none; padding: 24px 16px; display: flex; align-items: center; justify-content: space-between">
    <div role="img" aria-label="Trang {i+1} trên 3" style="display: flex; gap: 8px">{dots(i)}</div>
    <a href="{nxt}" style="height: 40px; padding: 0 24px; border-radius: 20px; background: #5354AD; color: #FFFFFF; text-decoration: none; font-size: 14px; font-weight: 600; display: flex; align-items: center">{cta}</a>
  </footer>
</div>'''
NOTIFY=HEAD.replace('%TITLE%','Cho phép thông báo')+ROOT+'''
  <main style="flex: 1; padding: 0 24px; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 24px; text-align: center">
    <div aria-hidden="true" style="width: 320px; height: 320px; border-radius: 160px; background: #F6F2FB; display: flex; align-items: center; justify-content: center">
      <div style="width: 160px; height: 160px; border-radius: 80px; background: #E4E1E9; color: #5354AD; display: flex; align-items: center; justify-content: center">'''+BELL+'''</div>
    </div>
    <div style="display: flex; flex-direction: column; gap: 8px">
      <h1 style="margin: 0; font-family: Lora, Georgia, serif; font-size: 28px; line-height: 36px; font-weight: 400">Bật thông báo</h1>
      <p style="margin: 0; font-size: 16px; line-height: 24px; color: #464651">Để không lỡ ngày giỗ nào.</p>
    </div>
  </main>
  <footer style="flex: none; padding: 16px 16px 24px; display: flex; flex-direction: column; gap: 8px">
    <a href="ListEmpty.dc.html" style="height: 40px; border-radius: 20px; background: #5354AD; color: #FFFFFF; text-decoration: none; font-size: 14px; font-weight: 600; display: flex; align-items: center; justify-content: center">Cho phép</a>
    <a href="ListEmpty.dc.html" style="height: 48px; border-radius: 24px; color: #5354AD; text-decoration: none; font-size: 14px; font-weight: 600; display: flex; align-items: center; justify-content: center">Để sau</a>
  </footer>
</div>'''+tail(EMPTY_JS)
def build(name,html,icons):
    for dark in (False,True):
        s=darken(html) if dark else html
        for ph,fn in icons.items(): s=s.replace(ph,fn(('d' if dark else 'l')))
        n=name+('Dark' if dark else '')
        s=normalize.normalize(n,s)
        # the spec values in the keyframes are not spacing; normalize leaves them alone
        open(P+n+'.dc.html','w').write(s)
build('Splash',SPLASH,{'%%ICON%%':lambda t: splash_icon('sp'+t)})
for i,(n,ill,title,line,nxt,cta,js) in enumerate(SCREENS):
    build(n,intro(i,ill,title,line,nxt,cta)+tail(js),{'%%ICON_SMALL%%':lambda t: e8_icon(32,'in'+t)})
build('IntroNotify',NOTIFY,{})
print('ok')
