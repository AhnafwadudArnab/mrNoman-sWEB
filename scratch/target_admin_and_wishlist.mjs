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

  async function mouseMoveTo(x, y) {
    await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
    await wait(300);
  }

  ws.onopen = async () => {
    await send('Page.enable');
    await send('Runtime.enable');
    await send('Input.enable');

    const dimRes = await send('Runtime.evaluate', { expression: '({w: window.innerWidth, h: window.innerHeight})', returnByValue: true });
    const { w, h } = dimRes.result.value;
    console.log('Window dimensions:', w, h);

    // 1. If currently on storefront or other page, click Admin_Panel button at bottom left of sidebar
    console.log('Navigating to homepage first...');
    await send('Page.navigate', { url: 'http://localhost:53703/' });
    await wait(3000);

    // Top header buttons: Wishlist is near (w * 0.74, 38)
    const wishlistX = Math.round(w * 0.74);
    console.log(`Clicking Wishlist at (${wishlistX}, 38)...`);
    await clickAt(wishlistX, 38);
    await wait(2500);
    await shot('verified_wishlist_page_final.png');

    // Return to homepage
    await send('Page.navigate', { url: 'http://localhost:53703/' });
    await wait(2500);

    // Click "Admin_Panel" at bottom of sidebar (around x: 100, y: 795)
    console.log('Clicking Admin_Panel at (100, 795)...');
    await clickAt(100, 795);
    await wait(3000);
    await shot('verified_admin_entry.png');

    // In Admin Panel Sidebar:
    // Catalogue -> Products is around (70, 155), Product List is around (70, 195)
    console.log('Clicking Product List in admin sidebar at (70, 195)...');
    await clickAt(70, 195);
    await wait(2500);
    await shot('verified_admin_product_list_dedicated.png');

    // Click Banners (around 70, 715)
    console.log('Clicking Banners in admin sidebar at (70, 715)...');
    await clickAt(70, 715);
    await wait(2000);
    // Scroll down to see Trust Badges section
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 600, y: 500, deltaX: 0, deltaY: 1500 });
    await wait(1200);
    await shot('verified_admin_banners_trust_badges_live.png');

    // Click Dashboard (around 70, 95)
    console.log('Clicking Dashboard at (70, 95)...');
    await clickAt(70, 95);
    await wait(2000);
    // Hover on spot in revenue analytics chart
    await mouseMoveTo(450, 470);
    await wait(500);
    await shot('verified_admin_dashboard_tooltip_live.png');

    // Click Abandoned Carts (around 70, 395)
    console.log('Clicking Abandoned Carts at (70, 395)...');
    await clickAt(70, 395);
    await wait(2000);
    await shot('verified_admin_abandoned_carts_live.png');

    ws.close();
    process.exit(0);
  };
}
main();
