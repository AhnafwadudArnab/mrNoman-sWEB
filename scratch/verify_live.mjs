import http from 'http';
import fs from 'fs';

async function main() {
  const pages = await new Promise((resolve) => {
    http.get('http://127.0.0.1:51338/json', res => {
      let d = ''; res.on('data', c => d += c);
      res.on('end', () => resolve(JSON.parse(d)));
    });
  });
  const page = pages.find(p => p.type === 'page');
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

    await shot('live_01_storefront.png');

    // Click Admin in top nav (around x=940, y=38) or bottom sidebar
    console.log('Clicking Admin at (940, 38)...');
    await click(940, 38, 1500);
    await shot('live_02_admin_dashboard.png');

    // Click Collections at (80, 420)
    console.log('Clicking Collections at (80, 420)...');
    await click(80, 420, 1500);
    await shot('live_03_collections.png');

    // Click Deals at (80, 795)
    console.log('Clicking Deals at (80, 795)...');
    await click(80, 795, 1500);
    await shot('live_04_deals.png');

    // Click Stock Management at (80, 365)
    console.log('Clicking Stock Management at (80, 365)...');
    await click(80, 365, 1500);
    await shot('live_05_stock.png');

    // Scroll sidebar down
    console.log('Scrolling sidebar down...');
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 80, y: 500, deltaX: 0, deltaY: 800 });
    await new Promise(r => setTimeout(r, 800));

    // Click Banners at (80, 580)
    console.log('Clicking Banners at (80, 580)...');
    await click(80, 580, 1500);
    // Scroll right content down to see Sidebar Promo
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 600, y: 500, deltaX: 0, deltaY: 1500 });
    await new Promise(r => setTimeout(r, 800));
    await shot('live_06_sidebar_promo.png');

    // Click Help & Support
    console.log('Clicking Help & Support...');
    await click(80, 800, 1500);
    await shot('live_07_help_support.png');

    // Test search in Help & Support
    console.log('Searching "product upload" in Help & Support...');
    await click(450, 190, 500);
    await typeText('product upload');
    await shot('live_08_help_search_results.png');

    ws.close();
    process.exit(0);
  };
}
main();
