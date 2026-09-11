import http from 'http';
import fs from 'fs';

async function main() {
  const pages = await new Promise((resolve) => {
    http.get('http://127.0.0.1:51338/json', res => {
      let d = ''; res.on('data', c => d += c);
      res.on('end', () => resolve(JSON.parse(d)));
    });
  });

  const page = pages.find(p => p.type === 'page' && p.url.includes('53703'));
  if (!page) process.exit(1);

  const ws = new WebSocket(page.webSocketDebuggerUrl);
  let id = 1;
  const send = (m, p = {}) => new Promise(r => {
    const i = id++;
    const h = e => { const msg = JSON.parse(e.data); if (msg.id === i) { ws.removeEventListener('message', h); r(msg.result); } };
    ws.addEventListener('message', h);
    ws.send(JSON.stringify({ id: i, method: m, params: p }));
  });

  async function shot(filename) {
    const ss = await send('Page.captureScreenshot', { format: 'png' });
    const targetPath = `C:/Users/ahana/.gemini/antigravity-ide/brain/7bab53eb-7e8e-4858-875c-9b6d9807aa04/${filename}`;
    fs.writeFileSync(targetPath, Buffer.from(ss.data, 'base64'));
    console.log(`Saved screenshot: ${filename}`);
  }

  const wait = ms => new Promise(r => setTimeout(r, ms));

  async function clickAt(x, y) {
    await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', buttons: 1, clickCount: 1 });
    await wait(80);
    await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', buttons: 0, clickCount: 1 });
    await wait(800);
  }

  ws.onopen = async () => {
    await send('Page.enable');
    await send('Runtime.enable');
    await send('Input.enable');

    // 1. Click "Wishlist" button in top header (approx x: 740, y: 38)
    console.log('Clicking Wishlist in top header...');
    await clickAt(740, 38);
    await wait(2500);
    await shot('verified_wishlist_page_live.png');

    // 2. Click "Admin" button in top header (approx x: 935, y: 38) or left sidebar bottom "Admin_Panel"
    console.log('Clicking Admin...');
    await clickAt(935, 38);
    await wait(2500);
    await shot('verified_admin_landing.png');

    // 3. In Admin Sidebar: Click "Product List" (Dedicated sidebar item in Catalogue)
    // Products is around y: 155, Product List is right below around y: 195
    console.log('Clicking Product List in admin sidebar...');
    await clickAt(80, 195);
    await wait(2000);
    await shot('verified_admin_product_list.png');

    // 4. Click Banners in marketing section (around y: 720) and scroll down to Feature / Trust Badges editor
    console.log('Clicking Banners in admin sidebar...');
    await clickAt(80, 720);
    await wait(2000);
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 600, y: 500, deltaX: 0, deltaY: 1200 });
    await wait(1000);
    await shot('verified_admin_banners_trust_editor.png');

    ws.close();
    process.exit(0);
  };
}
main();
