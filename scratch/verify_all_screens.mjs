import http from 'http';
import fs from 'fs';

async function main() {
  const pages = await new Promise((resolve) => {
    http.get('http://127.0.0.1:57676/json', res => {
      let d = ''; res.on('data', c => d += c);
      res.on('end', () => resolve(JSON.parse(d)));
    });
  });
  const page = pages.find(p => p.type === 'page' && p.url.includes('54963'));
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  let id = 1;
  const send = (m, p = {}) => new Promise(r => {
    const i = id++;
    const h = e => { const msg = JSON.parse(e.data); if (msg.id === i) { ws.removeEventListener('message', h); r(msg.result); } };
    ws.addEventListener('message', h);
    ws.send(JSON.stringify({ id: i, method: m, params: p }));
  });

  async function click(x, y, wait = 1200) {
    await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
    await new Promise(r => setTimeout(r, 60));
    await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', buttons: 1, clickCount: 1 });
    await new Promise(r => setTimeout(r, 60));
    await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', buttons: 0, clickCount: 1 });
    await new Promise(r => setTimeout(r, wait));
  }

  async function typeText(text) {
    for (const char of text) {
      await send('Input.dispatchKeyEvent', { type: 'keyDown', text: char, unmodifiedText: char });
      await send('Input.dispatchKeyEvent', { type: 'keyUp' });
      await new Promise(r => setTimeout(r, 30));
    }
    await new Promise(r => setTimeout(r, 600));
  }

  async function shot(filename) {
    const ss = await send('Page.captureScreenshot');
    fs.writeFileSync(`C:/Users/ahana/.gemini/antigravity-ide/brain/7bab53eb-7e8e-4858-875c-9b6d9807aa04/scratch/${filename}`, Buffer.from(ss.data, 'base64'));
    console.log(`Saved scratch/${filename}`);
  }

  ws.onopen = async () => {
    await send('Input.enable');
    await send('Page.enable');

    // 1. Click Deals at (80, 800)
    console.log('Navigating to Deals (80, 800)...');
    await click(80, 800, 1500);
    await shot('check_deals_active_list.png');

    // 2. Click Collections at (80, 420)
    console.log('Navigating to Collections (80, 420)...');
    await click(80, 420, 1500);
    await shot('check_collections_styled.png');

    // 3. Click Stock Management at (80, 365)
    console.log('Navigating to Stock Management (80, 365)...');
    await click(80, 365, 1500);
    await shot('check_stock_management.png');

    // Filter Stock: Low Stock
    console.log('Testing Stock Management Low Stock filter...');
    await click(850, 95, 800); // Click dropdown or filter area
    await shot('check_stock_filter.png');

    // Scroll sidebar down to see Marketing & System items
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 80, y: 500, deltaX: 0, deltaY: 600 });
    await new Promise(r => setTimeout(r, 600));
    await shot('check_sidebar_scrolled.png');

    // Click Banners (after scrolling)
    console.log('Clicking Banners...');
    await click(80, 630, 1500);
    // Scroll page down to see Sidebar Promo section
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 500, y: 500, deltaX: 0, deltaY: 1200 });
    await new Promise(r => setTimeout(r, 800));
    await shot('check_sidebar_promo_card.png');

    // Click Help & Support in sidebar
    console.log('Clicking Help & Support...');
    await click(80, 820, 1500);
    await shot('check_help_support_initial.png');

    // Test Search in Help & Support
    console.log('Searching in Help & Support: "load picture on product uploads"...');
    await click(450, 190, 400); // Click search input
    await typeText('load picture on product uploads');
    await shot('check_help_search_load_picture.png');

    ws.close();
    process.exit(0);
  };
}
main();
