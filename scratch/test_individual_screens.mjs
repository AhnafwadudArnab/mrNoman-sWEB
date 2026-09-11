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

  async function shot(filename) {
    const ss = await send('Page.captureScreenshot');
    fs.writeFileSync(`C:/Users/ahana/.gemini/antigravity-ide/brain/7bab53eb-7e8e-4858-875c-9b6d9807aa04/scratch/${filename}`, Buffer.from(ss.data, 'base64'));
    console.log(`Saved scratch/${filename}`);
  }

  ws.onopen = async () => {
    await send('Input.enable');
    await send('Page.enable');

    // Scroll sidebar all the way to top first
    console.log('Scrolling sidebar to top...');
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 80, y: 300, deltaX: 0, deltaY: -2000 });
    await new Promise(r => setTimeout(r, 800));

    // In top sidebar:
    // CATALOGUE is at y ~ 260
    // Products is at y ~ 310
    // Stock Management is at y ~ 365
    // Collections is at y ~ 420
    // Brands is at y ~ 480
    // SALES:
    // Orders is at y ~ 575
    // Abandoned Carts is at y ~ 630
    // Payments is at y ~ 685
    // Discounts is at y ~ 740
    // Deals is at y ~ 795
    // Promotions is at y ~ 850

    // 1. Check Collections
    console.log('Clicking Collections at (80, 420)...');
    await click(80, 420, 1500);
    await shot('final_collections_view.png');

    // 2. Check Deals
    console.log('Clicking Deals at (80, 795)...');
    await click(80, 795, 1500);
    await shot('final_deals_view.png');

    // 3. Check Stock Management
    console.log('Clicking Stock Management at (80, 365)...');
    await click(80, 365, 1500);
    await shot('final_stock_view.png');

    // Now scroll sidebar down
    console.log('Scrolling sidebar down...');
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 80, y: 500, deltaX: 0, deltaY: 800 });
    await new Promise(r => setTimeout(r, 800));

    // When scrolled down:
    // Banners is visible (around y ~ 580)
    console.log('Clicking Banners at (80, 580)...');
    await click(80, 580, 1500);
    // Scroll right content down to see Sidebar Promo
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 600, y: 500, deltaX: 0, deltaY: 1500 });
    await new Promise(r => setTimeout(r, 800));
    await shot('final_sidebar_promo_view.png');

    // Help & Support is at the bottom of sidebar (around y ~ 780-820)
    console.log('Clicking Help & Support at (80, 800)...');
    await click(80, 800, 1500);
    await shot('final_help_view.png');

    ws.close();
    process.exit(0);
  };
}
main();
