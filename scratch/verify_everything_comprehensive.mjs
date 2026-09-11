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
  if (!page) {
    console.error('Target page not found!');
    process.exit(1);
  }

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

    console.log('1. Reloading page...');
    await send('Page.reload');
    await wait(3500);

    // Capture Banners page scrolled down to see Trust Badges
    console.log('2. Scrolling down on Banners page...');
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 600, y: 500, deltaX: 0, deltaY: 800 });
    await wait(1200);
    await shot('verified_banners_trust_badges.png');

    // Click "Product List" in Admin Sidebar
    // Sidebar items are around x: 80, Product List is below Products around y: 150-200
    // Let's click "Dashboard" first around x: 80, y: 100
    console.log('3. Clicking Dashboard in sidebar...');
    await clickAt(80, 100);
    await wait(2000);
    // Hover on chart spots in revenue analytics (around x: 450, y: 450)
    await mouseMoveTo(450, 460);
    await wait(600);
    await shot('verified_dashboard_tooltip.png');

    // Click Abandoned Carts (around x: 80, y: 395)
    console.log('4. Clicking Abandoned Carts in sidebar...');
    await clickAt(80, 395);
    await wait(2000);
    await shot('verified_abandoned_carts.png');

    // Navigate to Storefront Homepage
    console.log('5. Navigating to Storefront Homepage...');
    await send('Page.navigate', { url: 'http://localhost:53703/' });
    await wait(3500);
    await shot('verified_storefront_home.png');

    // Scroll down on Storefront to see sidebar feature badges and discount tags
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 500, y: 400, deltaX: 0, deltaY: 400 });
    await wait(1000);
    await shot('verified_storefront_scrolled.png');

    // Navigate to Wishlist
    console.log('6. Navigating to Wishlist...');
    await send('Page.navigate', { url: 'http://localhost:53703/#/wishlist' });
    await wait(3500);
    await shot('verified_wishlist_grid.png');

    console.log('All verification captures completed successfully!');
    ws.close();
    process.exit(0);
  };
}
main();
