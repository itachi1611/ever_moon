import re
from common import *
from swipe import ITEM, CONFIRM, JS
def head_block(name):
    s=open(P+name+'.dc.html').read()
    return s[:s.index('</header>')+len('</header>')]
HINT='<p style="margin: 0 4px; font-size: 12px; line-height: 16px; color: #464651">Vuốt sang trái để sửa, sang phải để xoá ngày giỗ. Ngày lễ không sửa được.</p>'
LEGEND='''<div aria-hidden="true" style="display: flex; gap: 16px; padding: 0 4px; font-size: 12px; line-height: 16px; color: #464651">
      <span style="display: flex; align-items: center; gap: 6px"><span style="width: 8px; height: 8px; border-radius: 4px; background: #5354AD"></span>Ngày giỗ</span>
      <span style="display: flex; align-items: center; gap: 6px"><span style="width: 8px; height: 8px; border-radius: 4px; background: #C62828"></span>Mùng 1, rằm, lễ Tết</span>
    </div>'''
FAB='''  <a href="FormNew.dc.html" aria-label="Thêm ngày giỗ vào ngày đang chọn" style="position: absolute; right: 20px; bottom: 24px; height: 56px; padding: 0 22px 0 18px; border-radius: 16px; background: #5354AD; color: #FFFFFF; text-decoration: none; font-size: 16px; font-weight: 600; display: flex; align-items: center; gap: 8px; box-shadow: 0px 1px 3px 0px rgba(0, 0, 0, 0.3), 0px 4px 8px 3px rgba(0, 0, 0, 0.15)">
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" aria-hidden="true"><path d="M12 5v14M5 12h14"></path></svg>
    Thêm
  </a>'''
TAIL='''
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"$preview":{"width":390,"height":844}}'>
class Component extends DCLogic {
  constructor(props) {
    super(props);
    this.state = Object.assign(this.swipeState(), %INIT%);
  }%JS%
%BODY%
}
</script>
</body>
</html>
'''
# Illustrative data. The lunar numbers are placeholders, not computed dates.
EVENTS_JS='''
  events() {
    return {
      6: [{ id: 'a1', kind: 'anniv', name: 'Ông nội', sub: 'Nhắc trước 1 ngày, lúc 07:00' }],
      10: [{ id: 'h1', kind: 'holiday', name: 'Mùng 1 tháng 10', sub: 'Ngày lễ hằng tháng' }],
      18: [{ id: 'a2', kind: 'anniv', name: 'Bà nội', sub: 'Nhắc đúng ngày, lúc 07:00' }],
      24: [{ id: 'h2', kind: 'holiday', name: 'Rằm tháng 10', sub: 'Ngày lễ hằng tháng' }, { id: 'a3', kind: 'anniv', name: 'Cô Ba', sub: 'Nhắc trước 3 ngày, lúc 19:00' }]
    };
  }'''
MONTH_BODY='''  renderVals() {
    const lead = 6, days = 30, today = 6;
    const evs = this.events();
    const sel = this.state.selected;
    const weekdays = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
    const lunarOf = (d) => ((d + 20) % 30) + 1;
    const cells = [];
    for (let i = 0; i < 42; i++) {
      const d = i - lead + 1;
      const inMonth = d >= 1 && d <= days;
      const list = (inMonth && evs[d] ? evs[d] : []).filter((e) => !this.state.deleted[e.id]);
      const hasAnniv = list.some((e) => e.kind === 'anniv');
      const hasHoliday = list.some((e) => e.kind === 'holiday');
      const isToday = d === today, isSel = d === sel;
      const ln = lunarOf(d);
      cells.push({
        solar: inMonth ? String(d) : '',
        lunar: inMonth ? (ln === 1 ? '1/10' : String(ln)) : '',
        label: inMonth ? ('Ngày ' + d + ', ' + ln + ' âm lịch' + (hasAnniv ? ', có ngày giỗ' : '') + (hasHoliday ? ', ngày lễ' : '')) : 'Trống',
        pick: () => { if (inMonth) this.setState({ selected: d, open: {} }); },
        box: 'height: 52px; padding: 0; border: ' + (isSel && !isToday ? '2px solid #5354AD' : '0') + '; box-sizing: border-box; border-radius: 12px; font-family: inherit; display: flex; flex-direction: column; align-items: center; justify-content: center; background: ' + (isToday ? '#5354AD' : 'transparent'),
        solarStyle: 'font-size: 16px; line-height: 22px; font-weight: ' + (isToday ? '700' : '500') + '; color: ' + (isToday ? '#FFFFFF' : (i % 7 === 6 ? '#5354AD' : '#1B1B21')),
        lunarStyle: 'font-size: 11px; line-height: 14px; font-weight: ' + (ln === 1 || ln === 15 ? '700' : '400') + '; color: ' + (isToday ? '#FFFFFF' : (inMonth && (ln === 1 || ln === 15) ? '#C62828' : '#777683')),
        dotA: 'width: 6px; height: 6px; border-radius: 3px; background: ' + (hasAnniv ? (isToday ? '#FFFFFF' : '#5354AD') : 'transparent'),
        dotH: 'width: 6px; height: 6px; border-radius: 3px; display: ' + (hasHoliday ? 'block' : 'none') + '; background: #C62828'
      });
    }
    const wd = weekdays[(sel + lead - 1) % 7];
    const list = (evs[sel] || []).filter((e) => !this.state.deleted[e.id]).map((e) => this.decorate(e, '#F6F2FB'));
    return Object.assign({
      cells,
      dayTitle: wd + ', ' + String(sel).padStart(2, '0') + '/11 · ' + lunarOf(sel) + ' tháng ' + (sel >= 10 ? '10' : '9') + ' âm lịch',
      dayEvents: list,
      hasEvents: list.length > 0,
      noEvents: list.length === 0
    }, this.confirmVals());
  }'''
def month():
    h=head_block('CalendarMonth')
    body=f'''
  <section style="padding: 0 16px; display: flex; flex-direction: column; gap: 2px">
    <div style="display: grid; grid-template-columns: repeat(7, minmax(0, 1fr)); text-align: center; font-size: 13px; line-height: 24px; font-weight: 600; color: #464651">
      <span>T2</span><span>T3</span><span>T4</span><span>T5</span><span>T6</span><span>T7</span><span style="color: #5354AD">CN</span>
    </div>
    <div style="display: grid; grid-template-columns: repeat(7, minmax(0, 1fr)); row-gap: 2px">
      <sc-for list="{{{{cells}}}}" as="c" hint-placeholder-count="42">
        <button type="button" aria-label="{{{{c.label}}}}" onClick="{{{{c.pick}}}}" style="{{{{c.box}}}}">
          <span style="{{{{c.solarStyle}}}}">{{{{c.solar}}}}</span>
          <span style="{{{{c.lunarStyle}}}}">{{{{c.lunar}}}}</span>
          <span style="height: 6px; margin-top: 2px; display: flex; gap: 3px"><span style="{{{{c.dotA}}}}"></span><span style="{{{{c.dotH}}}}"></span></span>
        </button>
      </sc-for>
    </div>
    {LEGEND}
  </section>

  <section style="flex: 1; min-height: 0; overflow-y: auto; margin-top: 8px; padding: 0 16px 88px; display: flex; flex-direction: column; gap: 8px">
    <h2 style="margin: 0 4px; font-size: 14px; line-height: 20px; font-family: Lora, Georgia, serif; font-weight: 500; color: #1B1B21">{{{{dayTitle}}}}</h2>
    <sc-for list="{{{{dayEvents}}}}" as="ev" hint-placeholder-count="1">
      {ITEM}
    </sc-for>
    <sc-if value="{{{{noEvents}}}}" hint-placeholder-val="{{{{ false }}}}">
      <p style="margin: 4px; font-size: 14px; line-height: 20px; color: #464651">Không có sự kiện trong ngày này.</p>
    </sc-if>
    <sc-if value="{{{{hasEvents}}}}" hint-placeholder-val="{{{{ true }}}}">
      {HINT}
    </sc-if>
  </section>

{FAB}
  {CONFIRM}'''
    js=TAIL.replace('%INIT%',"{ selected: 24 }").replace('%JS%',JS+EVENTS_JS).replace('%BODY%',MONTH_BODY)
    return h+body+js
WEEK_BODY='''  renderVals() {
    const evs = this.events();
    const rows = [
      ['T2', 23, 14], ['T3', 24, 15], ['T4', 25, 16], ['T5', 26, 17], ['T6', 27, 18], ['T7', 28, 19], ['CN', 29, 20]
    ];
    const days = rows.map((r) => {
      const list = (evs[r[1]] || []).filter((e) => !this.state.deleted[e.id]).map((e) => this.decorate(e, '#FCF8FF'));
      const special = r[2] === 1 || r[2] === 15;
      return {
        weekday: r[0], date: String(r[1]), lunar: r[2] + ' tháng 10 âm lịch' + (special ? ' · Rằm' : ''),
        events: list, hasEvents: list.length > 0,
        weekdayStyle: 'font-size: 13px; line-height: 18px; font-weight: 600; color: ' + (r[0] === 'CN' ? '#5354AD' : '#464651'),
        lunarStyle: 'font-size: 14px; line-height: 20px; font-weight: ' + (special ? '700' : '400') + '; color: ' + (special ? '#C62828' : '#464651')
      };
    });
    return Object.assign({ days }, this.confirmVals());
  }'''
def week():
    h=head_block('CalendarWeek')
    h=re.sub(r'<span style="font-family: Lora, Georgia, serif; font-size: 16px; line-height: 24px; font-weight: 500">[^<]*</span>','<span style="font-family: Lora, Georgia, serif; font-size: 16px; line-height: 24px; font-weight: 500">23 – 29/11/2026</span>',h,1)
    body=f'''
  <main style="flex: 1; min-height: 0; overflow-y: auto; padding: 0 16px 96px; display: flex; flex-direction: column; gap: 8px">
    {LEGEND}
    <sc-for list="{{{{days}}}}" as="d" hint-placeholder-count="7">
      <article style="padding: 8px 12px 8px 6px; border-radius: 14px; background: #F6F2FB; border: 1px solid #C7C5D3; display: flex; flex-direction: column; gap: 8px">
        <div style="display: flex; align-items: center; gap: 8px">
          <div style="width: 52px; flex: none; display: flex; flex-direction: column; align-items: center">
            <span style="{{{{d.weekdayStyle}}}}">{{{{d.weekday}}}}</span>
            <span style="font-size: 20px; line-height: 26px; font-weight: 700">{{{{d.date}}}}</span>
          </div>
          <span style="{{{{d.lunarStyle}}}}">{{{{d.lunar}}}}</span>
        </div>
        <sc-if value="{{{{d.hasEvents}}}}" hint-placeholder-val="{{{{ false }}}}">
          <div style="padding-left: 6px; display: flex; flex-direction: column; gap: 6px">
            <sc-for list="{{{{d.events}}}}" as="ev" hint-placeholder-count="1">
              {ITEM}
            </sc-for>
          </div>
        </sc-if>
      </article>
    </sc-for>
    {HINT}
  </main>

{FAB}
  {CONFIRM}'''
    js=TAIL.replace('%INIT%',"{}").replace('%JS%',JS+EVENTS_JS).replace('%BODY%',WEEK_BODY)
    return h+body+js
YEAR_BODY='''  renderVals() {
    // Illustrative counts per solar month. Holidays are named festivals only; plain mùng 1 and rằm are not counted.
    const anniv = [1, 0, 1, 0, 2, 0, 0, 1, 0, 0, 3, 1];
    const holiday = [1, 2, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0];
    const current = 10;
    const months = anniv.map((n, i) => {
      const h = holiday[i];
      const dots = [];
      for (let k = 0; k < Math.min(n, 3); k++) dots.push({ style: 'width: 8px; height: 8px; border-radius: 4px; background: #5354AD' });
      for (let k = 0; k < Math.min(h, 3); k++) dots.push({ style: 'width: 8px; height: 8px; border-radius: 4px; background: #C62828' });
      return {
        name: 'Tháng ' + (i + 1),
        line1: n === 0 ? 'Không có giỗ' : n + ' ngày giỗ',
        line2: h === 0 ? '' : h + ' ngày lễ',
        label: 'Tháng ' + (i + 1) + ': ' + (n === 0 ? 'không có giỗ' : n + ' ngày giỗ') + (h ? ', ' + h + ' ngày lễ' : '') + '. Mở lịch tháng.',
        dots,
        box: 'box-sizing: border-box; height: 100%; padding: 10px 12px; border-radius: 14px; text-decoration: none; color: #1B1B21; display: grid; grid-template-rows: 22px 18px 18px 1fr; row-gap: 2px; ' + (i === current ? 'background: #F6F2FB; border: 2px solid #5354AD;' : 'background: #F6F2FB; border: 1px solid #C7C5D3;'),
        line1Style: 'font-size: 13px; line-height: 18px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; color: ' + (n === 0 ? '#777683' : '#464651'),
      };
    });
    return { months };
  }'''
def year():
    h=head_block('CalendarYear')
    h=h.replace('8 ngày giỗ trong năm','9 ngày giỗ · 9 ngày lễ trong năm')
    body=f'''
  <main style="flex: 1; min-height: 0; padding: 4px 16px 96px; display: flex; flex-direction: column; gap: 10px">
    {LEGEND}
    <div style="display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); grid-auto-rows: 106px; gap: 10px">
      <sc-for list="{{{{months}}}}" as="m" hint-placeholder-count="12">
        <a href="CalendarMonth.dc.html" aria-label="{{{{m.label}}}}" style="{{{{m.box}}}}">
          <span style="font-size: 16px; line-height: 22px; font-weight: 600">{{{{m.name}}}}</span>
          <span style="{{{{m.line1Style}}}}">{{{{m.line1}}}}</span>
          <span style="font-size: 13px; line-height: 18px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; color: #C62828">{{{{m.line2}}}}</span>
          <span style="align-self: end; display: flex; gap: 4px; height: 8px">
            <sc-for list="{{{{m.dots}}}}" as="dot" hint-placeholder-count="2">
              <span style="{{{{dot.style}}}}"></span>
            </sc-for>
          </span>
        </a>
      </sc-for>
    </div>
    <p style="margin: 0 4px; font-size: 12px; line-height: 16px; color: #464651">Chạm vào một tháng để mở lịch tháng đó và xem, sửa hoặc xoá từng ngày giỗ.</p>
  </main>

{FAB}'''
    js=TAIL.replace('%INIT%',"{}").replace('%JS%','').replace('%BODY%',YEAR_BODY).replace("Object.assign(this.swipeState(), {})","{}")
    return h+body+js
for n,f in (('CalendarMonth',month),('CalendarWeek',week),('CalendarYear',year)):
    s=f()
    open(P+n+'.dc.html','w').write(s)
    open(P+n+'Dark.dc.html','w').write(darken(s))
print('ok')
