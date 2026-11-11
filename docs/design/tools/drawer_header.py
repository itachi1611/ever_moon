import re
from common import *
HEAD='''<div style="padding: 16px 4px 12px; display: flex; flex-direction: column; gap: 16px">
      <div style="display: flex; align-items: center; gap: 12px; padding: 0 12px">%%ICON%%<span style="font-family: Lora, Georgia, serif; font-size: 22px; line-height: 28px; color: #1B1B21">Evermoon</span></div>
      <section aria-label="Hôm nay" style="padding: 12px 14px; border-radius: 16px; background: #EAE7EF; display: flex; align-items: center; gap: 14px">
        <div aria-hidden="true" style="width: 52px; height: 56px; flex: none; border-radius: 12px; background: #5354AD; color: #FFFFFF; display: flex; flex-direction: column; align-items: center; justify-content: center">
          <span style="font-size: 22px; line-height: 26px; font-weight: 700">27</span>
          <span style="font-size: 11px; line-height: 14px; font-weight: 500">th. 9</span>
        </div>
        <div style="flex: 1; min-width: 0; display: flex; flex-direction: column">
          <span style="font-size: 12px; line-height: 16px; font-weight: 600; letter-spacing: 0.5px; color: #464651">HÔM NAY</span>
          <span style="font-family: Lora, Georgia, serif; font-size: 16px; line-height: 24px; font-weight: 500; color: #1B1B21">27 tháng 9 âm lịch</span>
          <span style="font-size: 14px; line-height: 20px; color: #464651">Thứ Sáu, 06/11/2026</span>
        </div>
      </section>
    </div>'''
pat=re.compile(r'<div style="padding: 20px 16px 16px; display: flex; flex-direction: column; gap: 2px">.*?</div>',re.S)
for name,dark in (('DrawerOpen',False),('DrawerOpenDark',True)):
    s=open(P+name+'.dc.html').read()
    h=darken(HEAD) if dark else HEAD
    h=h.replace('%%ICON%%',e8_icon(40,'e8'+('d' if dark else 'l')))
    s,k=pat.subn(lambda m:h,s); assert k==1,name
    open(P+name+'.dc.html','w').write(s)
print('ok')
