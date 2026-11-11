# Shared prototype pieces for swipeable anniversary items (Month and Week views).
ITEM_ANNIV='''<div style="position: relative; border-radius: 12px; overflow: hidden; background: #AB3337">
          <div aria-hidden="{{ev.hideActions}}" style="position: absolute; inset: 0; display: flex; justify-content: space-between">
            <button type="button" onClick="{{ev.askDelete}}" style="width: 96px; border: 0; background: #AB3337; color: #FFFFFE; font-family: inherit; font-size: 14px; font-weight: 600; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 2px"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"></path></svg>Xoá</button>
            <a href="FormEdit.dc.html" style="width: 96px; background: #5354AD; color: #FFFFFF; text-decoration: none; font-size: 14px; font-weight: 600; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 2px"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 20h4L19 9l-4-4L4 16z"></path><path d="M13 7l4 4"></path></svg>Sửa</a>
          </div>
          <div onPointerDown="{{ev.down}}" onPointerMove="{{ev.move}}" onPointerUp="{{ev.up}}" onPointerCancel="{{ev.up}}" style="{{ev.face}}">
            <span aria-hidden="true" style="width: 10px; height: 10px; flex: none; border-radius: 5px; background: #5354AD"></span>
            <span style="flex: 1; min-width: 0; display: flex; flex-direction: column"><span style="font-family: Lora, Georgia, serif; font-size: 16px; line-height: 22px; font-weight: 500">{{ev.name}}</span><span style="font-size: 14px; line-height: 20px; color: #464651">{{ev.sub}}</span></span>
            <span style="flex: none; padding: 4px 10px; border-radius: 8px; background: #E4E1E9; color: #1B1B21; font-size: 12px; line-height: 16px; font-weight: 600">Ngày giỗ</span>
          </div>
        </div>'''
ITEM_HOLIDAY='''<div style="min-height: 60px; box-sizing: border-box; padding: 10px 14px; border-radius: 12px; background: #FFDAD6; color: #410002; display: flex; align-items: center; gap: 12px">
          <span aria-hidden="true" style="width: 10px; height: 10px; flex: none; border-radius: 5px; background: #C62828"></span>
          <span style="flex: 1; min-width: 0; display: flex; flex-direction: column"><span style="font-size: 16px; line-height: 22px; font-weight: 600">{{ev.name}}</span><span style="font-size: 14px; line-height: 20px">{{ev.sub}}</span></span>
          <span style="flex: none; padding: 4px 10px; border-radius: 8px; border: 1px solid #C62828; color: #410002; font-size: 12px; line-height: 16px; font-weight: 600">Ngày lễ</span>
        </div>'''
ITEM='''<sc-if value="{{ev.isAnniv}}" hint-placeholder-val="{{ true }}">
        '''+ITEM_ANNIV+'''
      </sc-if>
      <sc-if value="{{ev.isHoliday}}" hint-placeholder-val="{{ false }}">
        '''+ITEM_HOLIDAY+'''
      </sc-if>'''
CONFIRM='''<sc-if value="{{confirmOpen}}" hint-placeholder-val="{{ false }}">
    <div style="position: absolute; inset: 0; background: rgba(0, 0, 0, 0.32); display: flex; align-items: center; justify-content: center; padding: 24px">
      <section role="dialog" aria-modal="true" aria-labelledby="dlg-title" style="width: 100%; box-sizing: border-box; padding: 24px; border-radius: 28px; background: #EAE7EF; display: flex; flex-direction: column; gap: 12px">
        <h2 id="dlg-title" style="margin: 0; font-family: Lora, Georgia, serif; font-size: 22px; line-height: 28px; font-weight: 400">Xoá ngày giỗ của {{confirmName}}?</h2>
        <p style="margin: 0; font-size: 16px; line-height: 24px; color: #464651">Ngày giỗ và lời nhắc sẽ không còn hiện trong ứng dụng. Bạn có thể thêm lại bất cứ lúc nào.</p>
        <div style="margin-top: 12px; display: flex; justify-content: flex-end; gap: 8px">
          <button type="button" onClick="{{cancelDelete}}" style="height: 48px; padding: 0 20px; border: 0; border-radius: 24px; background: transparent; color: #1B1B21; font-family: inherit; font-size: 16px; font-weight: 600">Giữ lại</button>
          <button type="button" onClick="{{confirmDelete}}" style="height: 48px; padding: 0 24px; border: 0; border-radius: 24px; background: #AB3337; color: #FFFFFE; font-family: inherit; font-size: 16px; font-weight: 600">Xoá</button>
        </div>
      </section>
    </div>
  </sc-if>'''
# JS: swipe state machine. Drag left (rtl) reveals Sửa on the right, drag right (ltr) reveals Xoá on the left.
JS='''
  swipeState() {
    return { drag: null, open: {}, deleted: {}, confirm: null };
  }
  decorate(ev, faceBg) {
    const s = this.state;
    const isDrag = s.drag && s.drag.id === ev.id;
    const offset = isDrag ? s.drag.dx : (s.open[ev.id] || 0);
    return Object.assign({}, ev, {
      isAnniv: ev.kind === 'anniv',
      isHoliday: ev.kind === 'holiday',
      hideActions: offset === 0 ? 'true' : 'false',
      face: 'position: relative; min-height: 60px; box-sizing: border-box; padding: 10px 14px; background: ' + faceBg + '; border: 1px solid #C7C5D3; border-radius: 12px; display: flex; align-items: center; gap: 12px; touch-action: pan-y; user-select: none; cursor: grab; transform: translateX(' + offset + 'px); transition: ' + (isDrag ? 'none' : 'transform 180ms ease-out'),
      down: (e) => { if (e.currentTarget.setPointerCapture) e.currentTarget.setPointerCapture(e.pointerId); this.setState({ drag: { id: ev.id, x0: e.clientX - (this.state.open[ev.id] || 0), dx: this.state.open[ev.id] || 0 } }); },
      move: (e) => { const d = this.state.drag; if (!d || d.id !== ev.id) return; const dx = Math.max(-112, Math.min(112, e.clientX - d.x0)); this.setState({ drag: { id: d.id, x0: d.x0, dx: dx } }); },
      up: () => { const d = this.state.drag; if (!d || d.id !== ev.id) return; const open = {}; open[ev.id] = d.dx < -48 ? -96 : (d.dx > 48 ? 96 : 0); this.setState({ drag: null, open: open }); },
      askDelete: () => this.setState({ confirm: ev, open: {} })
    });
  }
  confirmVals() {
    const c = this.state.confirm;
    return {
      confirmOpen: !!c,
      confirmName: c ? c.name : '',
      cancelDelete: () => this.setState({ confirm: null }),
      confirmDelete: () => { const del = Object.assign({}, this.state.deleted); if (c) del[c.id] = true; this.setState({ confirm: null, deleted: del }); }
    };
  }'''
