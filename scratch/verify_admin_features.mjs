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

    console.log('Clicking Admin at (930, 38)...');
    await click(930, 38, 1500);
    await shot('verify_admin_dashboard.png');

    // Click PROMOTIONS in sidebar (around y=350)
    console.log('Expanding PROMOTIONS / Deals...');
    await click(80, 350, 1000);
    // Click Deals
    await click(80, 385, 1500);
    await shot('verify_deals_page.png');

    // Click Collections (around y=420)
    console.log('Clicking Collections...');
    await click(80, 420, 1500);
    await shot('verify_collections_page.png');

    // Click Stock Management (under PRODUCTS)
    console.log('Clicking Products...');
    await click(80, 240, 1000);
    console.log('Clicking Stock Management...');
    await click(80, 310, 1500);
    await shot('verify_stock_page.png');

    // Click Banners (under PROMOTIONS)
    console.log('Clicking Banners...');
    await click(80, 420, 1500);
    await shot('verify_banners_page.png');

    // Click Help & Support
    console.log('Clicking Help & Support...');
    await click(80, 745, 1500);
    await shot('verify_help_page.png');

    ws.close();
    process.exit(0);
  };
}
main();
